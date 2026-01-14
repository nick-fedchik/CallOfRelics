--[[
================================================================================
KOSMICMAZER — TransitionService
================================================================================

Purpose:
Coordinates location transitions between Orbit and Surface locations.
Manages landing and liftoff sequences with client-server synchronization.

Version:
0.1

Features:
- StartLandingSequence(player, locationId) — Orbit → Surface transition
- StartLiftoffSequence(player) — Surface → Orbit transition
- GetAvailableLocations(player) — Get explored locations from profile
- GetCurrentContext(player) — Returns "Orbit" or "Surface"
- GetTransitionState(player) — Returns current transition state
- Server-driven animation coordination via RemoteEvents

API:
- Initialize() — Setup event handlers
- StartLandingSequence(player, locationId) → boolean
- StartLiftoffSequence(player) → boolean
- GetAvailableLocations(player) → {locations}
- GetCurrentContext(player) → "Orbit" | "Surface" | nil
- GetTransitionState(player) → state | nil

Calls to:
- LocationService (Load/Unload locations)
- ProfileService (Get explored locations)
- TransitionConfig (Timing parameters)

Called from:
- RemoteEvents: RequestLanding, RequestLiftoff, RequestLocations

Events:
- Fires: TransitionUpdate, LocationsAvailable

Dependencies:
- LocationService
- ProfileService
- TransitionConfig
- ServerStorage.Planets structure

ChangeLog:
- 0.1: Initial TransitionService (2026-01-14)
================================================================================
]]

local MODULE_NAME = "TransitionService"
local VERSION = "0.1"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- ============================================================================
-- DEPENDENCIES
-- ============================================================================

local TransitionConfig = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("TransitionConfig"))

-- Lazy-loaded to avoid circular dependencies
local LocationService
local ProfileService

local function GetLocationService()
	if not LocationService then
		LocationService = require(script.Parent.LocationService)
	end
	return LocationService
end

local function GetProfileService()
	if not ProfileService then
		ProfileService = require(script.Parent.ProfileService)
	end
	return ProfileService
end

-- ============================================================================
-- STATE
-- ============================================================================

local TransitionService = {}
local isInitialized = false

-- Track transition state per player
-- Structure: {[player] = {state = "idle", locationId = nil, startTime = nil}}
local playerTransitions = {}

-- Track silent spawn state (to disable spawn sound during transitions)
local silentSpawnPlayers = {}

-- RemoteEvents references
local remoteEvents
local transitionUpdate
local locationsAvailable
local requestLanding
local requestLiftoff
local requestLocations

-- ============================================================================
-- PRIVATE HELPERS
-- ============================================================================

local function MuteCharacterSounds(character)
	-- Mute all sounds in character (spawn sound, footsteps, etc.)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Sound") then
			descendant.Volume = 0
		end
	end

	-- Also check for HumanoidRootPart sounds specifically (where spawn sound usually is)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		for _, sound in ipairs(hrp:GetChildren()) do
			if sound:IsA("Sound") then
				sound.Volume = 0
			end
		end
	end
end

local function LoadCharacterSilently(player)
	-- Mark player for silent spawn
	silentSpawnPlayers[player] = true

	-- Setup one-time connection to mute sounds when character loads
	local connection
	connection = player.CharacterAdded:Connect(function(character)
		-- Disconnect immediately (one-time)
		connection:Disconnect()

		-- Mute sounds immediately
		MuteCharacterSounds(character)

		-- Also mute any sounds that get added shortly after (Roblox adds them with delay)
		task.delay(0.1, function()
			MuteCharacterSounds(character)
		end)

		-- Clear silent spawn flag after a short delay
		task.delay(0.5, function()
			silentSpawnPlayers[player] = nil
		end)
	end)

	-- Load character
	player:LoadCharacter()
end

local function SetTransitionState(player, state, locationId)
	playerTransitions[player] = {
		state = state,
		locationId = locationId,
		startTime = os.clock()
	}

	print(string.format("[%s %s][SetState] %s -> %s (location: %s)",
		MODULE_NAME, VERSION, player.Name, state, locationId or "nil"))
end

local function ClearTransitionState(player)
	playerTransitions[player] = nil
end

local function GetLocationMetadata(planetId, locationId)
	local planetFolder = ServerStorage.Planets:FindFirstChild(planetId)
	if not planetFolder then return nil end

	local surfaceFolder = planetFolder:FindFirstChild("Surface")
	if not surfaceFolder then return nil end

	local locationFolder = surfaceFolder:FindFirstChild(locationId)
	if not locationFolder then return nil end

	local configModule = locationFolder:FindFirstChild("Config")
	if not configModule then return nil end

	local success, config = pcall(require, configModule)
	if not success then return nil end

	local metadata = config.getMetadata and config.getMetadata() or {}

	return {
		id = locationId,
		name = metadata.description or locationId,
		biome = metadata.biome or "Unknown",
		displayName = config.displayName or config.name or locationId
	}
end

local function SpawnShipAboveLandingPad(player, locationId)
	-- Find landing pad in Workspace (recursive search since it's inside Baseplate)
	local landingPad = Workspace:FindFirstChild("SpaceShipLandingPad", true)

	if not landingPad then
		warn(string.format("[%s %s][SpawnShip] Landing pad not found!", MODULE_NAME, VERSION))
		-- List workspace contents for debugging
		print(string.format("[%s %s][SpawnShip] DEBUG Workspace contents:", MODULE_NAME, VERSION))
		for _, child in ipairs(Workspace:GetChildren()) do
			print(string.format("  - %s (%s)", child.Name, child.ClassName))
			if child:IsA("BasePart") then
				for _, subChild in ipairs(child:GetChildren()) do
					print(string.format("    - %s (%s)", subChild.Name, subChild.ClassName))
				end
			end
		end
		return nil
	end

	-- Get WORLD position of landing pad (not local position)
	local padWorldPosition = landingPad.CFrame.Position
	print(string.format("[%s %s][SpawnShip] Found landing pad: %s at WORLD pos %s (local: %s)",
		MODULE_NAME, VERSION, landingPad.Name, tostring(padWorldPosition), tostring(landingPad.Position)))

	-- Get SpaceShip from Orbit location
	local planetFolder = ServerStorage.Planets:FindFirstChild("Planet_1")
	if not planetFolder then return nil end

	local orbitWorkspace = planetFolder.Orbit.Workspace
	local shipTemplate = orbitWorkspace:FindFirstChild("SpaceShip")
	if not shipTemplate then
		warn(string.format("[%s %s][SpawnShip] SpaceShip template not found!", MODULE_NAME, VERSION))
		return nil
	end

	-- Clone ship
	local ship = shipTemplate:Clone()
	ship.Name = "SpaceShip"
	ship.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	-- Anchor all parts
	for _, part in ipairs(ship:GetDescendants()) do
		if part:IsA("BasePart") and not part:IsA("Seat") and not part:IsA("VehicleSeat") then
			part.Anchored = true
		end
	end

	-- Position above landing pad using WORLD position
	local spawnHeight = TransitionConfig.ShipSpawnHeight
	local startPosition = padWorldPosition + Vector3.new(0, spawnHeight, 0)

	-- Set ship position
	ship:PivotTo(CFrame.new(startPosition) * CFrame.Angles(0, 0, 0))
	ship.Parent = Workspace

	print(string.format("[%s %s][SpawnShip] Ship spawned at %s (height %d above pad)",
		MODULE_NAME, VERSION, tostring(startPosition), spawnHeight))

	return ship, landingPad
end

local function AnimateShipLanding(ship, landingPad, duration)
	if not ship or not landingPad then return end

	local primaryPart = ship.PrimaryPart or ship:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then return end

	-- Calculate end position using WORLD position of landing pad
	local padWorldPosition = landingPad.CFrame.Position
	local landingHeight = TransitionConfig.ShipLandingHeight
	local endPosition = padWorldPosition + Vector3.new(0, landingHeight, 0)

	print(string.format("[%s %s][AnimateLanding] Landing to WORLD pos %s",
		MODULE_NAME, VERSION, tostring(endPosition)))

	-- Create tween for ship descent
	local tweenInfo = TweenInfo.new(
		duration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	-- We need to move the entire model, so we'll use PivotTo in a loop
	local startCFrame = ship:GetPivot()
	local endCFrame = CFrame.new(endPosition) * startCFrame.Rotation

	local startTime = os.clock()

	while os.clock() - startTime < duration do
		local alpha = (os.clock() - startTime) / duration
		alpha = 1 - (1 - alpha) ^ 2 -- Quad easing out

		local currentCFrame = startCFrame:Lerp(endCFrame, alpha)
		ship:PivotTo(currentCFrame)

		task.wait()
	end

	-- Final position
	ship:PivotTo(endCFrame)

	print(string.format("[%s %s][AnimateLanding] Ship landed on pad", MODULE_NAME, VERSION))
end

local function AnimateShipLiftoff(ship, duration)
	if not ship then return end

	local primaryPart = ship.PrimaryPart or ship:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then return end

	-- Current position (on landing pad)
	local startCFrame = ship:GetPivot()
	local startPosition = startCFrame.Position

	-- End position (high above, out of view)
	local liftoffHeight = TransitionConfig.ShipSpawnHeight -- Same height as spawn
	local endPosition = startPosition + Vector3.new(0, liftoffHeight, 0)
	local endCFrame = CFrame.new(endPosition) * startCFrame.Rotation

	print(string.format("[%s %s][AnimateLiftoff] Lifting from %s to %s",
		MODULE_NAME, VERSION, tostring(startPosition), tostring(endPosition)))

	local startTime = os.clock()

	while os.clock() - startTime < duration do
		local alpha = (os.clock() - startTime) / duration
		alpha = alpha * alpha -- Quad easing in (accelerating ascent)

		local currentCFrame = startCFrame:Lerp(endCFrame, alpha)
		ship:PivotTo(currentCFrame)

		task.wait()
	end

	-- Final position
	ship:PivotTo(endCFrame)

	print(string.format("[%s %s][AnimateLiftoff] Ship ascended", MODULE_NAME, VERSION))
end

local function GetPlanetDisplayName(planetId)
	local planetFolder = ServerStorage.Planets:FindFirstChild(planetId)
	if not planetFolder then return planetId end

	local configModule = planetFolder:FindFirstChild("Config")
	if not configModule then return planetId end

	local success, config = pcall(require, configModule)
	if not success then return planetId end

	return config.displayName or config.name or planetId
end

local function SitPlayerInShip(player, ship)
	print(string.format("[%s %s][SitPlayer] Attempting to seat %s", MODULE_NAME, VERSION, player.Name))

	if not ship then
		warn(string.format("[%s %s][SitPlayer] Ship is nil!", MODULE_NAME, VERSION))
		return false
	end

	print(string.format("[%s %s][SitPlayer] Ship found: %s", MODULE_NAME, VERSION, ship.Name))

	local pilotSeat = ship:FindFirstChild("PilotSeat", true)
	if not pilotSeat then
		warn(string.format("[%s %s][SitPlayer] PilotSeat not found in ship!", MODULE_NAME, VERSION))
		return false
	end

	print(string.format("[%s %s][SitPlayer] PilotSeat found: %s", MODULE_NAME, VERSION, pilotSeat.Name))

	-- Wait for character if not present (may have respawned during transition)
	local character = player.Character
	if not character then
		print(string.format("[%s %s][SitPlayer] Waiting for character to load...", MODULE_NAME, VERSION))
		character = player.CharacterAdded:Wait()
		task.wait(0.5) -- Wait for character to fully initialize
	end

	if not character then
		warn(string.format("[%s %s][SitPlayer] Character not found for %s!", MODULE_NAME, VERSION, player.Name))
		return false
	end

	print(string.format("[%s %s][SitPlayer] Character found: %s", MODULE_NAME, VERSION, character.Name))

	-- Use WaitForChild with timeout for Humanoid
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then
		warn(string.format("[%s %s][SitPlayer] Humanoid not found after waiting!", MODULE_NAME, VERSION))
		return false
	end

	print(string.format("[%s %s][SitPlayer] Humanoid found, state: %s", MODULE_NAME, VERSION, tostring(humanoid:GetState())))

	-- Wait for humanoid to be ready (not dead)
	if humanoid:GetState() == Enum.HumanoidStateType.Dead then
		print(string.format("[%s %s][SitPlayer] Humanoid is dead, waiting for respawn...", MODULE_NAME, VERSION))
		character = player.CharacterAdded:Wait()
		task.wait(0.5)
		humanoid = character:WaitForChild("Humanoid", 5)
		if not humanoid then
			warn(string.format("[%s %s][SitPlayer] Humanoid not found after respawn!", MODULE_NAME, VERSION))
			return false
		end
	end

	-- Configure seat
	if pilotSeat:IsA("VehicleSeat") then
		pilotSeat.Disabled = false
		pilotSeat.MaxSpeed = 0
		pilotSeat.TurnSpeed = 0
	end

	-- Sit player
	pilotSeat:Sit(humanoid)
	task.wait(0.3) -- Wait for sit to complete

	print(string.format("[%s %s][SitPlayer] ✓ %s seated in PilotSeat", MODULE_NAME, VERSION, player.Name))
	return true
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function TransitionService.Initialize()
	if isInitialized then
		warn(string.format("[%s %s][Initialize] Already initialized", MODULE_NAME, VERSION))
		return true
	end

	print(string.format("[%s %s] 🚀 Initializing TransitionService...", MODULE_NAME, VERSION))

	-- Get RemoteEvents
	remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not remoteEvents then
		error(string.format("[%s %s][Initialize] RemoteEvents folder not found!", MODULE_NAME, VERSION))
	end

	transitionUpdate = remoteEvents:WaitForChild("TransitionUpdate", 5)
	locationsAvailable = remoteEvents:WaitForChild("LocationsAvailable", 5)
	requestLanding = remoteEvents:WaitForChild("RequestLanding", 5)
	requestLiftoff = remoteEvents:WaitForChild("RequestLiftoff", 5)
	requestLocations = remoteEvents:WaitForChild("RequestLocations", 5)

	-- Setup event handlers
	requestLanding.OnServerEvent:Connect(function(player, locationId)
		TransitionService.StartLandingSequence(player, locationId)
	end)

	requestLiftoff.OnServerEvent:Connect(function(player)
		TransitionService.StartLiftoffSequence(player)
	end)

	requestLocations.OnServerEvent:Connect(function(player)
		local locations = TransitionService.GetAvailableLocations(player)
		locationsAvailable:FireClient(player, locations)
	end)

	-- Cleanup on player leave
	Players.PlayerRemoving:Connect(function(player)
		ClearTransitionState(player)
	end)

	isInitialized = true
	print(string.format("[%s %s] ✓ TransitionService initialized", MODULE_NAME, VERSION))
	return true
end

function TransitionService.GetAvailableLocations(player)
	local profile = GetProfileService().GetProfile(player)
	if not profile then
		warn(string.format("[%s %s][GetLocations] No profile for %s", MODULE_NAME, VERSION, player.Name))
		return {}
	end

	local exploredLocations = profile.exploredLocations or {}
	local planetId = profile.currentPlanet or "Planet_1"

	-- If no explored locations, use default for debug
	if #exploredLocations == 0 then
		exploredLocations = {"Location1"}
	end

	local locations = {}
	for _, locationId in ipairs(exploredLocations) do
		local metadata = GetLocationMetadata(planetId, locationId)
		if metadata then
			table.insert(locations, metadata)
		end
	end

	print(string.format("[%s %s][GetLocations] Found %d locations for %s",
		MODULE_NAME, VERSION, #locations, player.Name))

	return locations
end

function TransitionService.GetCurrentContext(player)
	local locService = GetLocationService()
	local currentLocation = locService.GetCurrentLocation(player)

	if not currentLocation then
		return nil
	end

	if currentLocation.locationName == "Orbit" then
		return TransitionConfig.Contexts.Orbit
	else
		return TransitionConfig.Contexts.Surface
	end
end

function TransitionService.GetTransitionState(player)
	local transition = playerTransitions[player]
	return transition and transition.state or nil
end

function TransitionService.StartLandingSequence(player, locationId)
	print(string.format("[%s %s][Landing] Starting landing sequence for %s -> %s",
		MODULE_NAME, VERSION, player.Name, locationId))

	-- Validation
	local currentContext = TransitionService.GetCurrentContext(player)
	if currentContext ~= TransitionConfig.Contexts.Orbit then
		warn(string.format("[%s %s][Landing] Player not in Orbit!", MODULE_NAME, VERSION))
		transitionUpdate:FireClient(player, "error", {
			message = TransitionConfig.Messages.NotInPilotSeat
		})
		return false
	end

	if playerTransitions[player] then
		warn(string.format("[%s %s][Landing] Transition already in progress!", MODULE_NAME, VERSION))
		transitionUpdate:FireClient(player, "error", {
			message = TransitionConfig.Messages.TransitionInProgress
		})
		return false
	end

	-- Get location metadata for display
	local profile = GetProfileService().GetProfile(player)
	local planetId = profile and profile.currentPlanet or "Planet_1"
	local locationMetadata = GetLocationMetadata(planetId, locationId)

	if not locationMetadata then
		warn(string.format("[%s %s][Landing] Location not found: %s", MODULE_NAME, VERSION, locationId))
		transitionUpdate:FireClient(player, "error", {
			message = TransitionConfig.Messages.InvalidLocation
		})
		return false
	end

	-- Start transition
	SetTransitionState(player, TransitionConfig.States.Departure, locationId)

	-- Phase 1: Departure animation (client-side)
	transitionUpdate:FireClient(player, TransitionConfig.States.Departure, {
		locationId = locationId,
		locationName = locationMetadata.displayName
	})

	-- Wait for departure animation to complete
	-- DepartureDuration = 3 sec, DepartureFadeStart = 2 sec
	-- So fade to black takes 1 sec (from 2 to 3)
	task.wait(TransitionConfig.DepartureDuration)

	-- Phase 2: Loading screen - screen should be black now
	SetTransitionState(player, TransitionConfig.States.Loading, locationId)
	transitionUpdate:FireClient(player, TransitionConfig.States.Loading, {
		message = string.format(TransitionConfig.Messages.Landing, locationMetadata.displayName)
	})

	-- Wait for loading screen to be fully visible AND fade complete before unloading
	-- Client needs time to: receive Loading state + fade in loading screen
	-- This ensures the planet disappears behind the black screen
	task.wait(TransitionConfig.LoadingFadeDuration + 0.3)

	-- Unload Orbit, Load Surface location (now hidden by loading screen)
	local locService = GetLocationService()
	locService.UnloadLocation(player)

	local loadSuccess = locService.LoadLocation(player, planetId, locationId)
	if not loadSuccess then
		warn(string.format("[%s %s][Landing] Failed to load location!", MODULE_NAME, VERSION))
		ClearTransitionState(player)
		transitionUpdate:FireClient(player, "error", {
			message = TransitionConfig.Messages.InvalidLocation
		})
		return false
	end

	-- Minimum loading time (also allows replication to client)
	task.wait(TransitionConfig.LoadingMinDuration)

	-- Phase 3: Respawn player character if needed (may have died during transition)
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not character or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		print(string.format("[%s %s][Landing] Respawning player character (silent)...", MODULE_NAME, VERSION))
		LoadCharacterSilently(player)
		task.wait(1.0) -- Wait for character to load
	end

	-- Phase 4: Spawn ship above landing pad
	local ship, landingPad = SpawnShipAboveLandingPad(player, locationId)
	if not ship then
		warn(string.format("[%s %s][Landing] Failed to spawn ship!", MODULE_NAME, VERSION))
	end

	-- Get WORLD position of landing pad for client camera
	local padWorldPosition = landingPad and landingPad.CFrame.Position or Vector3.new(0, 0, 0)

	-- Wait for replication to complete (ship and location must be visible on client)
	task.wait(1.0)
	print(string.format("[%s %s][Landing] Replication wait complete", MODULE_NAME, VERSION))

	-- Phase 5: Approach animation - send camera position to client first
	SetTransitionState(player, TransitionConfig.States.Approach, locationId)
	transitionUpdate:FireClient(player, TransitionConfig.States.Approach, {
		landingPadPosition = padWorldPosition  -- WORLD position for camera
	})

	-- Brief wait for client to setup camera
	task.wait(0.5)

	-- Phase 6: Sit player in ship (player "controls" the landing)
	print(string.format("[%s %s][Landing] Seating player in ship", MODULE_NAME, VERSION))
	SitPlayerInShip(player, ship)
	task.wait(0.3) -- Brief pause for sit to complete

	-- Animate ship landing - uses unified duration with deceleration easing (starts fast, slows down)
	if ship and landingPad then
		AnimateShipLanding(ship, landingPad, TransitionConfig.TransitionAnimationDuration)
	end

	-- Brief pause after landing
	task.wait(0.5)

	-- Transition complete
	SetTransitionState(player, TransitionConfig.States.Complete, locationId)
	local planetDisplayName = GetPlanetDisplayName(planetId)
	transitionUpdate:FireClient(player, TransitionConfig.States.Complete, {
		context = TransitionConfig.Contexts.Surface,
		locationId = locationId,
		locationDisplayName = locationMetadata.displayName,
		planetDisplayName = planetDisplayName
	})

	ClearTransitionState(player)

	print(string.format("[%s %s][Landing] ✓ Landing sequence complete for %s",
		MODULE_NAME, VERSION, player.Name))

	return true
end

function TransitionService.StartLiftoffSequence(player)
	print(string.format("[%s %s][Liftoff] Starting liftoff sequence for %s",
		MODULE_NAME, VERSION, player.Name))

	-- Validation
	local currentContext = TransitionService.GetCurrentContext(player)
	if currentContext ~= TransitionConfig.Contexts.Surface then
		warn(string.format("[%s %s][Liftoff] Player not on Surface!", MODULE_NAME, VERSION))
		transitionUpdate:FireClient(player, "error", {
			message = TransitionConfig.Messages.NotInPilotSeat
		})
		return false
	end

	if playerTransitions[player] then
		warn(string.format("[%s %s][Liftoff] Transition already in progress!", MODULE_NAME, VERSION))
		return false
	end

	local profile = GetProfileService().GetProfile(player)
	local planetId = profile and profile.currentPlanet or "Planet_1"
	local planetDisplayName = GetPlanetDisplayName(planetId)

	-- Find ship in workspace for liftoff animation
	local ship = Workspace:FindFirstChild("SpaceShip")

	-- Start transition
	SetTransitionState(player, TransitionConfig.States.Liftoff, nil)

	-- Phase 1: Liftoff animation - notify client and animate ship ascent
	transitionUpdate:FireClient(player, TransitionConfig.States.Liftoff, {
		planetName = planetDisplayName
	})

	-- Animate ship rising (server-side, player stays seated watching through cockpit)
	-- Uses unified duration with acceleration easing (starts slow, speeds up)
	local liftoffDuration = TransitionConfig.TransitionAnimationDuration
	if ship then
		AnimateShipLiftoff(ship, liftoffDuration)
	else
		task.wait(liftoffDuration)
	end

	-- Phase 2: Loading screen with planet name
	SetTransitionState(player, TransitionConfig.States.Loading, nil)
	transitionUpdate:FireClient(player, TransitionConfig.States.Loading, {
		message = string.format(TransitionConfig.Messages.OrbitLoading, planetDisplayName)
	})

	-- Wait for loading screen to be fully visible before unloading
	task.wait(TransitionConfig.LoadingFadeDuration + 0.3)

	-- Unload Surface, Load Orbit
	local locService = GetLocationService()
	locService.UnloadLocation(player)

	local loadSuccess = locService.LoadLocation(player, planetId, "Orbit")
	if not loadSuccess then
		warn(string.format("[%s %s][Liftoff] Failed to load Orbit!", MODULE_NAME, VERSION))
		ClearTransitionState(player)
		return false
	end

	task.wait(TransitionConfig.LoadingMinDuration)

	-- Respawn player character if needed (may have died or missing during transition)
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not character or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		print(string.format("[%s %s][Liftoff] Respawning player character (silent)...", MODULE_NAME, VERSION))
		LoadCharacterSilently(player)
		task.wait(1.0) -- Wait for character to load
	end

	-- Spawn player in PilotSeat
	locService.SpawnPlayerInLocation(player, "PilotSeat")

	-- Brief wait for spawn to complete
	task.wait(0.5)

	-- Transition complete - tell client to restore camera to follow player
	SetTransitionState(player, TransitionConfig.States.Complete, nil)
	transitionUpdate:FireClient(player, TransitionConfig.States.Complete, {
		context = TransitionConfig.Contexts.Orbit,
		restoreCamera = true,
		locationDisplayName = "Орбіта",
		planetDisplayName = planetDisplayName
	})

	ClearTransitionState(player)

	print(string.format("[%s %s][Liftoff] ✓ Liftoff sequence complete for %s",
		MODULE_NAME, VERSION, player.Name))

	return true
end

-- ============================================================================
-- INITIAL GAME START SEQUENCE
-- ============================================================================

function TransitionService.StartGameSequence(player)
	print(string.format("[%s %s][GameStart] Starting initial game sequence for %s",
		MODULE_NAME, VERSION, player.Name))

	-- Get player profile for planet info
	local profile = GetProfileService().GetProfile(player)
	if not profile then
		warn(string.format("[%s %s][GameStart] No profile for %s!", MODULE_NAME, VERSION, player.Name))
		return false
	end

	local planetId = profile.currentPlanet or "Planet_1"
	local planetDisplayName = GetPlanetDisplayName(planetId)

	-- Check for existing transition
	if playerTransitions[player] then
		warn(string.format("[%s %s][GameStart] Transition already in progress!", MODULE_NAME, VERSION))
		return false
	end

	-- Start transition - notify client to show loading screen
	SetTransitionState(player, TransitionConfig.States.GameStart, nil)
	transitionUpdate:FireClient(player, TransitionConfig.States.GameStart, {
		message = string.format(TransitionConfig.Messages.GameStart, planetDisplayName),
		planetName = planetDisplayName
	})

	-- Wait for client to show loading screen (ScreenSaver will hide)
	task.wait(TransitionConfig.LoadingFadeDuration + 0.3)

	-- Load Orbit location
	local locService = GetLocationService()
	local loadSuccess = locService.LoadLocation(player, planetId, "Orbit")

	if not loadSuccess then
		warn(string.format("[%s %s][GameStart] Failed to load Orbit!", MODULE_NAME, VERSION))
		ClearTransitionState(player)
		transitionUpdate:FireClient(player, "error", {
			message = TransitionConfig.Messages.InvalidLocation
		})
		return false
	end

	-- Minimum loading time
	task.wait(TransitionConfig.LoadingMinDuration)

	-- Spawn player character (silent)
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not character or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		print(string.format("[%s %s][GameStart] Spawning player character...", MODULE_NAME, VERSION))
		LoadCharacterSilently(player)
		task.wait(1.0)
	end

	-- Spawn player in PilotSeat
	locService.SpawnPlayerInLocation(player, "PilotSeat")
	task.wait(0.5)

	-- Transition complete
	SetTransitionState(player, TransitionConfig.States.Complete, nil)
	transitionUpdate:FireClient(player, TransitionConfig.States.Complete, {
		context = TransitionConfig.Contexts.Orbit,
		restoreCamera = true,
		locationDisplayName = "Орбіта",
		planetDisplayName = planetDisplayName
	})

	ClearTransitionState(player)

	print(string.format("[%s %s][GameStart] ✓ Game start sequence complete for %s",
		MODULE_NAME, VERSION, player.Name))

	return true
end

-- ============================================================================
-- RETURN
-- ============================================================================

return TransitionService
