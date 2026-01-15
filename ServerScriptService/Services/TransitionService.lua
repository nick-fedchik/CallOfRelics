--[[
================================================================================
KOSMICMAZER — TransitionService
================================================================================

Purpose:
Coordinates location transitions between Orbit and Surface locations.
Manages landing and launch sequences with client-server synchronization.

Version:
0.3

Features:
- StartLandingSequence(player, locationId) — Orbit → Surface transition
- StartLaunchSequence(player) — Surface → Orbit transition
- GetAvailableLocations(player) — Get explored locations from profile
- GetCurrentContext(player) — Returns "Orbit" or "Surface"
- GetTransitionState(player) — Returns current transition state
- Server-driven animation coordination via RemoteEvents
- Preserves SpaceShip across location transitions (reuses instead of respawning)

API:
- Initialize() — Setup event handlers
- StartLandingSequence(player, locationId) → boolean
- StartLaunchSequence(player) → boolean
- GetAvailableLocations(player) → {locations}
- GetCurrentContext(player) → "Orbit" | "Surface" | nil
- GetTransitionState(player) → state | nil

Calls to:
- LocationService (Load/Unload locations)
- ProfileService (Get explored locations)
- TransitionConfig (Timing parameters)

Called from:
- RemoteEvents: RequestLanding, RequestLaunch, RequestLocations

Events:
- Fires: TransitionUpdate, LocationsAvailable

Dependencies:
- LocationService
- ProfileService
- TransitionConfig
- ServerStorage.Planets structure

ChangeLog:
- 0.5: Rename Liftoff → Launch (StartLaunchSequence, States.Launch/Ascent) (2026-01-15)
- 0.4: Two-phase landing animation, remove unused AnimateShipLanding (2026-01-15)
- 0.3: Preserve SpaceShip across transitions, skip respawn if seated (2026-01-15)
- 0.2: EPIC 8 - ProfileService integration for progression tracking (2026-01-15)
- 0.1: Initial TransitionService (2026-01-14)
================================================================================
]]

local MODULE_NAME = "TransitionService"
local VERSION = "0.5"

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
local requestLaunch
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

	-- Check if SpaceShip already exists in Workspace (preserved from Orbit)
	local existingShip = Workspace:FindFirstChild("SpaceShip")
	if existingShip then
		print(string.format("[%s %s][SpawnShip] SpaceShip already exists, repositioning for landing",
			MODULE_NAME, VERSION))

		-- Reposition existing ship above landing pad
		local spawnHeight = TransitionConfig.ShipSpawnHeight
		local startPosition = padWorldPosition + Vector3.new(0, spawnHeight, 0)
		existingShip:PivotTo(CFrame.new(startPosition) * CFrame.Angles(0, 0, 0))

		print(string.format("[%s %s][SpawnShip] Ship repositioned to %s (height %d above pad)",
			MODULE_NAME, VERSION, tostring(startPosition), spawnHeight))

		return existingShip, landingPad
	end

	-- Get SpaceShip from Orbit location (fallback if not preserved)
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
	requestLaunch = remoteEvents:WaitForChild("RequestLaunch", 5)
	requestLocations = remoteEvents:WaitForChild("RequestLocations", 5)

	-- Setup event handlers
	requestLanding.OnServerEvent:Connect(function(player, locationId)
		TransitionService.StartLandingSequence(player, locationId)
	end)

	requestLaunch.OnServerEvent:Connect(function(player)
		TransitionService.StartLaunchSequence(player)
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
	local profileService = GetProfileService()
	local profile = profileService.GetProfile(player)
	if not profile then
		warn(string.format("[%s %s][GetLocations] No profile for %s", MODULE_NAME, VERSION, player.Name))
		return {}
	end

	local planetId = profile.currentPlanet or "Planet_1"

	-- Use new per-planet location structure (EPIC 8)
	local exploredLocations = profileService.GetExploredLocationsForPlanet(player, planetId)

	-- If no explored locations, use default for debug
	if #exploredLocations == 0 then
		exploredLocations = {"Location1"}
	end

	local locations = {}
	for _, locationId in ipairs(exploredLocations) do
		-- Skip Orbit - it's not a landable location
		if locationId ~= "Orbit" then
			local metadata = GetLocationMetadata(planetId, locationId)
			if metadata then
				table.insert(locations, metadata)
			end
		end
	end

	print(string.format("[%s %s][GetLocations] Found %d locations for %s on %s",
		MODULE_NAME, VERSION, #locations, player.Name, planetId))

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
	-- Note: If player is sitting in ship (preserved), skip respawn
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local needsRespawn = not character or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead

	-- If player is sitting (in preserved SpaceShip), don't respawn
	if humanoid and humanoid.SeatPart then
		needsRespawn = false
		print(string.format("[%s %s][Landing] Player still seated, skipping respawn", MODULE_NAME, VERSION))
	end

	if needsRespawn then
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

	-- Phase durations for landing
	local phase1Duration = TransitionConfig.LandingPhase1Duration -- 4 sec external view
	local phase2Duration = TransitionConfig.LandingPhase2Duration -- 3 sec cockpit view

	-- Phase 5: External view - camera watches ship descend from ground POV
	SetTransitionState(player, TransitionConfig.States.Approach, locationId)
	transitionUpdate:FireClient(player, TransitionConfig.States.Approach, {
		landingPadPosition = padWorldPosition,
		phase = 1,
		duration = phase1Duration
	})

	-- Brief wait for client to setup camera
	task.wait(0.5)

	-- Sit player in ship before animation starts
	print(string.format("[%s %s][Landing] Seating player in ship", MODULE_NAME, VERSION))
	SitPlayerInShip(player, ship)
	task.wait(0.3)

	-- Phase 1: Ship descends from high to intermediate height (fast approach with braking)
	if ship and landingPad then
		local startCFrame = ship:GetPivot()
		local startPosition = startCFrame.Position

		-- Intermediate position: 80 studs above pad (where phase 2 starts)
		local intermediateHeight = 80
		local phase1EndPosition = padWorldPosition + Vector3.new(0, intermediateHeight, 0)
		local phase1EndCFrame = CFrame.new(phase1EndPosition) * startCFrame.Rotation

		print(string.format("[%s %s][Landing] Phase 1: Descending from %s to %s",
			MODULE_NAME, VERSION, tostring(startPosition), tostring(phase1EndPosition)))

		local startTime = os.clock()
		while os.clock() - startTime < phase1Duration do
			local alpha = (os.clock() - startTime) / phase1Duration
			alpha = 1 - (1 - alpha) ^ 2 -- Quad easing out (fast start, slowing down)
			local currentCFrame = startCFrame:Lerp(phase1EndCFrame, alpha)
			ship:PivotTo(currentCFrame)
			task.wait()
		end
		ship:PivotTo(phase1EndCFrame)

		print(string.format("[%s %s][Landing] Phase 1 complete, switching to cockpit view",
			MODULE_NAME, VERSION))

		-- Phase 6: Cockpit view - switch camera to inside ship
		SetTransitionState(player, TransitionConfig.States.Landing, locationId)
		transitionUpdate:FireClient(player, TransitionConfig.States.Landing, {
			phase = 2,
			duration = phase2Duration
		})

		-- Phase 2: Final approach from intermediate to landing pad (slow, controlled)
		local phase2StartCFrame = ship:GetPivot()
		local landingHeight = TransitionConfig.ShipLandingHeight
		local finalPosition = padWorldPosition + Vector3.new(0, landingHeight, 0)
		local phase2EndCFrame = CFrame.new(finalPosition) * startCFrame.Rotation

		print(string.format("[%s %s][Landing] Phase 2: Final approach to %s",
			MODULE_NAME, VERSION, tostring(finalPosition)))

		startTime = os.clock()
		while os.clock() - startTime < phase2Duration do
			local alpha = (os.clock() - startTime) / phase2Duration
			alpha = 1 - (1 - alpha) ^ 3 -- Cubic easing out (very smooth landing)
			local currentCFrame = phase2StartCFrame:Lerp(phase2EndCFrame, alpha)
			ship:PivotTo(currentCFrame)
			task.wait()
		end
		ship:PivotTo(phase2EndCFrame)

		print(string.format("[%s %s][Landing] Phase 2 complete, ship landed", MODULE_NAME, VERSION))
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

	-- === EPIC 8: Update profile with location discovery ===
	local profileService = GetProfileService()
	profileService.MarkLocationDiscovered(player, planetId, locationId)
	profileService.UpdateCurrentState(player, planetId, locationId)
	profileService.TriggerEventSave(player, "Landing")
	profileService.NotifyClient(player, "locationDiscovered", {
		planetId = planetId,
		locationId = locationId,
		locationDisplayName = locationMetadata.displayName
	})
	-- === END EPIC 8 ===

	ClearTransitionState(player)

	print(string.format("[%s %s][Landing] ✓ Landing sequence complete for %s",
		MODULE_NAME, VERSION, player.Name))

	return true
end

function TransitionService.StartLaunchSequence(player)
	print(string.format("[%s %s][Launch] Starting launch sequence for %s",
		MODULE_NAME, VERSION, player.Name))

	-- Validation
	local currentContext = TransitionService.GetCurrentContext(player)
	if currentContext ~= TransitionConfig.Contexts.Surface then
		warn(string.format("[%s %s][Launch] Player not on Surface!", MODULE_NAME, VERSION))
		transitionUpdate:FireClient(player, "error", {
			message = TransitionConfig.Messages.NotInPilotSeat
		})
		return false
	end

	if playerTransitions[player] then
		warn(string.format("[%s %s][Launch] Transition already in progress!", MODULE_NAME, VERSION))
		return false
	end

	local profile = GetProfileService().GetProfile(player)
	local planetId = profile and profile.currentPlanet or "Planet_1"
	local planetDisplayName = GetPlanetDisplayName(planetId)

	-- Find ship in workspace for launch animation
	local ship = Workspace:FindFirstChild("SpaceShip")

	-- Get landing pad position for external camera view
	local landingPad = Workspace:FindFirstChild("SpaceShipLandingPad", true)
	local padPosition = landingPad and landingPad.CFrame.Position or Vector3.new(0, 0, 0)

	-- Phase durations
	local phase1Duration = TransitionConfig.LaunchPhase1Duration -- 3 sec cockpit view (liftoff)
	local phase2Duration = TransitionConfig.LaunchPhase2Duration -- 4 sec external view (ascent)

	-- Start transition
	SetTransitionState(player, TransitionConfig.States.Launch, nil)

	-- Phase 1: Cockpit view - player watches through cockpit window during liftoff
	transitionUpdate:FireClient(player, TransitionConfig.States.Launch, {
		planetName = planetDisplayName,
		phase = 1,
		duration = phase1Duration
	})

	if ship then
		local startCFrame = ship:GetPivot()
		local startPosition = startCFrame.Position

		-- Phase 1: Slow start, rise 100 studs
		local phase1Height = 100
		local phase1EndPosition = startPosition + Vector3.new(0, phase1Height, 0)
		local phase1EndCFrame = CFrame.new(phase1EndPosition) * startCFrame.Rotation

		local startTime = os.clock()
		while os.clock() - startTime < phase1Duration do
			local alpha = (os.clock() - startTime) / phase1Duration
			alpha = alpha * alpha -- Quad easing in (slow start)
			local currentCFrame = startCFrame:Lerp(phase1EndCFrame, alpha)
			ship:PivotTo(currentCFrame)
			task.wait()
		end
		ship:PivotTo(phase1EndCFrame)

		print(string.format("[%s %s][Launch] Phase 1 (liftoff) complete, ship at %s",
			MODULE_NAME, VERSION, tostring(phase1EndPosition)))

		-- Phase 2: External view - camera switches to ground POV for ascent
		SetTransitionState(player, TransitionConfig.States.Ascent, nil)
		transitionUpdate:FireClient(player, TransitionConfig.States.Ascent, {
			planetName = planetDisplayName,
			phase = 2,
			duration = phase2Duration,
			padPosition = padPosition,
			shipPosition = phase1EndPosition
		})

		-- Continue ship ascent with stronger acceleration
		local phase2StartCFrame = ship:GetPivot()
		local finalHeight = TransitionConfig.ShipSpawnHeight
		local phase2EndPosition = startPosition + Vector3.new(0, finalHeight, 0)
		local phase2EndCFrame = CFrame.new(phase2EndPosition) * startCFrame.Rotation

		startTime = os.clock()
		while os.clock() - startTime < phase2Duration do
			local alpha = (os.clock() - startTime) / phase2Duration
			alpha = alpha * alpha * alpha -- Cubic easing in (faster acceleration)
			local currentCFrame = phase2StartCFrame:Lerp(phase2EndCFrame, alpha)
			ship:PivotTo(currentCFrame)
			task.wait()
		end
		ship:PivotTo(phase2EndCFrame)

		print(string.format("[%s %s][Launch] Phase 2 (ascent) complete, ship at %s",
			MODULE_NAME, VERSION, tostring(phase2EndPosition)))
	else
		task.wait(phase1Duration + phase2Duration)
	end

	-- Phase 3: Loading screen with planet name
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
		warn(string.format("[%s %s][Launch] Failed to load Orbit!", MODULE_NAME, VERSION))
		ClearTransitionState(player)
		return false
	end

	task.wait(TransitionConfig.LoadingMinDuration)

	-- Respawn player character if needed (may have died or missing during transition)
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not character or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		print(string.format("[%s %s][Launch] Respawning player character (silent)...", MODULE_NAME, VERSION))
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

	-- === EPIC 8: Update profile state after launch ===
	local profileService = GetProfileService()
	profileService.UpdateCurrentState(player, planetId, "Orbit")
	profileService.TriggerEventSave(player, "Launch")
	profileService.NotifyClient(player, "stateUpdate", {
		planetId = planetId,
		locationId = "Orbit"
	})
	-- === END EPIC 8 ===

	ClearTransitionState(player)

	print(string.format("[%s %s][Launch] ✓ Launch sequence complete for %s",
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

	-- === EPIC 8: Update profile with initial state ===
	local profileService = GetProfileService()
	profileService.UpdateCurrentState(player, planetId, "Orbit")
	profileService.MarkLocationDiscovered(player, planetId, "Orbit")
	-- === END EPIC 8 ===

	ClearTransitionState(player)

	print(string.format("[%s %s][GameStart] ✓ Game start sequence complete for %s",
		MODULE_NAME, VERSION, player.Name))

	return true
end

-- ============================================================================
-- RETURN
-- ============================================================================

return TransitionService
