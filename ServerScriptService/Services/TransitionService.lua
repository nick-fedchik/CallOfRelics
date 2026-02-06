--[[
================================================================================
KOSMICMAZER — TransitionService
================================================================================

Purpose:
Coordinates location transitions between Orbit and Surface locations.
Manages landing and launch sequences with client-server synchronization.

Version:
0.11

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
- 0.11: Fix ship orientation on Orbit - always face planet using CFrame.lookAt (2026-01-24)
- 0.10: Increase streaming delay before Arrival animation (1.5s instead of 0.5s) (2026-01-21)
- 0.9: Ship arrival animation on orbit (cockpit view, player sees planet approach) (2026-01-21)
- 0.8: Ramp system integration - SetShipLanded after landing, RetractRamp before launch (2026-01-19)
- 0.7: EPIC 3 - SpaceShipService integration, spawn from ServerStorage/Actors (2026-01-16)
- 0.6: Add RestoreCharacterSounds after GameStart (2026-01-15)
- 0.5: Rename Liftoff → Launch (StartLaunchSequence, States.Launch/Ascent) (2026-01-15)
- 0.4: Two-phase landing animation, remove unused AnimateShipLanding (2026-01-15)
- 0.3: Preserve SpaceShip across transitions, skip respawn if seated (2026-01-15)
- 0.2: EPIC 8 - ProfileService integration for progression tracking (2026-01-15)
- 0.1: Initial TransitionService (2026-01-14)
================================================================================
]]

local MODULE_NAME = "TransitionService"
local VERSION = "0.11"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- ============================================================================
-- DEPENDENCIES
-- ============================================================================

local TransitionConfig = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("TransitionConfig"))

-- Lazy-loaded to avoid circular dependencies
local LocationService
local ProfileService
local SpaceShipService

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

local function GetSpaceShipService()
	if not SpaceShipService then
		SpaceShipService = require(script.Parent.SpaceShipService)
	end
	return SpaceShipService
end

-- ============================================================================
-- STATE
-- ============================================================================

local TransitionService = {}
local isInitialized = false

-- Track transition state per player
-- Structure: {[player] = {state = "idle", locationId = nil, startTime = nil}}
local playerTransitions = {}


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

local function RestoreCharacterSounds(character)
	-- Restore default volumes for character sounds
	-- Note: Roblox default volumes vary by sound type
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Sound") then
			-- Restore to reasonable defaults based on sound name
			if descendant.Name == "Running" then
				descendant.Volume = 0.65
			elseif descendant.Name == "Climbing" then
				descendant.Volume = 0.7
			elseif descendant.Name == "Jumping" then
				descendant.Volume = 0.5
			elseif descendant.Name == "GettingUp" then
				descendant.Volume = 0.65
			elseif descendant.Name == "FreeFalling" then
				descendant.Volume = 0.5
			elseif descendant.Name == "Landing" then
				descendant.Volume = 0.5
			elseif descendant.Name == "Splash" then
				descendant.Volume = 0.5
			elseif descendant.Name == "Swimming" then
				descendant.Volume = 0.5
			else
				-- Default volume for unknown sounds
				descendant.Volume = 0.5
			end
		end
	end
end

local function LoadCharacterSilently(player)
	local connection
	connection = player.CharacterAdded:Connect(function(character)
		connection:Disconnect()
		MuteCharacterSounds(character)
		task.delay(0.1, function()
			MuteCharacterSounds(character)
		end)
	end)
	player:LoadCharacter()
end

local function SetTransitionState(player, state, locationId)
	playerTransitions[player] = {
		state = state,
		locationId = locationId,
		startTime = os.clock()
	}

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

local function SpawnShipAboveLandingPad(player)
	local landingPad = Workspace:FindFirstChild("SpaceShipLandingPad", true)

	if not landingPad then
		warn(string.format("[%s %s] Landing pad not found!", MODULE_NAME, VERSION))
		return nil
	end

	local padWorldPosition = landingPad.CFrame.Position
	local spawnHeight = TransitionConfig.ShipSpawnHeight
	local startPosition = padWorldPosition + Vector3.new(0, spawnHeight, 0)

	-- Use SpaceShipService (EPIC 3)
	local spaceShipService = GetSpaceShipService()
	local ship = spaceShipService.SpawnShip(player, startPosition)

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

-- Animate ship arrival on orbit (cockpit view)
-- Ship flies from startOffset towards finalPosition, decelerating
-- Ship maintains orientation facing the planet throughout animation
local function AnimateShipArrival(ship, finalPosition, arrivalPath, duration, planetPosition)
	if not ship or not arrivalPath then return end

	-- Calculate positions from offsets
	local startPos = finalPosition + arrivalPath.startOffset  -- e.g., (0, 100, -400)
	local midPos = finalPosition + arrivalPath.midOffset      -- e.g., (0, 100, -100)
	
	-- Planet position for look-at calculation
	local targetPos = planetPosition or Vector3.new(0, 100, 600)

	-- Phase 1: Fast approach (startPos → midPos)
	local phase1Duration = duration * 0.5
	local phase1StartCFrame = CFrame.lookAt(startPos, targetPos)
	local phase1EndCFrame = CFrame.lookAt(midPos, targetPos)

	local startTime = os.clock()
	while os.clock() - startTime < phase1Duration do
		local alpha = (os.clock() - startTime) / phase1Duration
		alpha = alpha * alpha  -- Quad ease-in (accelerating)
		local currentCFrame = phase1StartCFrame:Lerp(phase1EndCFrame, alpha)
		ship:PivotTo(currentCFrame)
		task.wait()
	end
	ship:PivotTo(phase1EndCFrame)

	-- Phase 2: Deceleration (midPos → finalPos)
	local phase2Duration = duration * 0.5
	local phase2StartCFrame = CFrame.lookAt(midPos, targetPos)
	local phase2EndCFrame = CFrame.lookAt(finalPosition, targetPos)

	startTime = os.clock()
	while os.clock() - startTime < phase2Duration do
		local alpha = (os.clock() - startTime) / phase2Duration
		alpha = 1 - (1 - alpha) ^ 2  -- Quad ease-out (decelerating)
		local currentCFrame = phase2StartCFrame:Lerp(phase2EndCFrame, alpha)
		ship:PivotTo(currentCFrame)
		task.wait()
	end
	ship:PivotTo(phase2EndCFrame)
end

local function SitPlayerInShip(player, ship)
	if not ship then
		return false
	end

	local pilotSeat = ship:FindFirstChild("PilotSeat", true)
	if not pilotSeat then
		return false
	end

	local character = player.Character
	if not character then
		character = player.CharacterAdded:Wait()
		task.wait(0.5)
	end

	if not character then
		return false
	end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then
		return false
	end

	if humanoid:GetState() == Enum.HumanoidStateType.Dead then
		character = player.CharacterAdded:Wait()
		task.wait(0.5)
		humanoid = character:WaitForChild("Humanoid", 5)
		if not humanoid then
			return false
		end
	end

	if pilotSeat:IsA("VehicleSeat") then
		pilotSeat.Disabled = false
		pilotSeat.MaxSpeed = 0
		pilotSeat.TurnSpeed = 0
	end

	pilotSeat:Sit(humanoid)
	task.wait(0.3)

	return true
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function TransitionService.Initialize()
	if isInitialized then
		return true
	end

	remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not remoteEvents then
		error(string.format("[%s %s] RemoteEvents not found!", MODULE_NAME, VERSION))
	end

	transitionUpdate = remoteEvents:WaitForChild("TransitionUpdate", 5)
	locationsAvailable = remoteEvents:WaitForChild("LocationsAvailable", 5)
	requestLanding = remoteEvents:WaitForChild("RequestLanding", 5)
	requestLaunch = remoteEvents:WaitForChild("RequestLaunch", 5)
	requestLocations = remoteEvents:WaitForChild("RequestLocations", 5)

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

	Players.PlayerRemoving:Connect(function(player)
		ClearTransitionState(player)
	end)

	isInitialized = true
	print(string.format("[%s %s] ✓ TransitionService ready", MODULE_NAME, VERSION))
	return true
end

function TransitionService.GetAvailableLocations(player)
	local profileService = GetProfileService()
	local profile = profileService.GetProfile(player)
	if not profile then
		return {}
	end

	local planetId = profile.currentPlanet or "Planet_1"

	-- Use new per-planet location structure (EPIC 8)
	-- Returns only discovered locations (via Scanner system)
	local exploredLocations = profileService.GetExploredLocationsForPlanet(player, planetId)

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
	end

	if needsRespawn then
		LoadCharacterSilently(player)
		task.wait(1.0)
	end

	-- Phase 4: Spawn ship above landing pad (EPIC 3)
	local ship, landingPad = SpawnShipAboveLandingPad(player)
	if not ship then
		warn(string.format("[%s %s] Failed to spawn ship!", MODULE_NAME, VERSION))
	end

	local padWorldPosition = landingPad and landingPad.CFrame.Position or Vector3.new(0, 0, 0)

	task.wait(1.0)

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

	task.wait(0.5)
	SitPlayerInShip(player, ship)
	task.wait(0.3)

	-- Phase 1: Ship descends from high to intermediate height
	if ship and landingPad then
		local startCFrame = ship:GetPivot()
		local intermediateHeight = 80
		local phase1EndPosition = padWorldPosition + Vector3.new(0, intermediateHeight, 0)
		local phase1EndCFrame = CFrame.new(phase1EndPosition) * startCFrame.Rotation

		local startTime = os.clock()
		while os.clock() - startTime < phase1Duration do
			local alpha = (os.clock() - startTime) / phase1Duration
			alpha = 1 - (1 - alpha) ^ 2
			local currentCFrame = startCFrame:Lerp(phase1EndCFrame, alpha)
			ship:PivotTo(currentCFrame)
			task.wait()
		end
		ship:PivotTo(phase1EndCFrame)

		-- Phase 2: Cockpit view
		SetTransitionState(player, TransitionConfig.States.Landing, locationId)
		transitionUpdate:FireClient(player, TransitionConfig.States.Landing, {
			phase = 2,
			duration = phase2Duration
		})

		local phase2StartCFrame = ship:GetPivot()
		local landingHeight = TransitionConfig.ShipLandingHeight
		local finalPosition = padWorldPosition + Vector3.new(0, landingHeight, 0)
		local phase2EndCFrame = CFrame.new(finalPosition) * startCFrame.Rotation

		startTime = os.clock()
		while os.clock() - startTime < phase2Duration do
			local alpha = (os.clock() - startTime) / phase2Duration
			alpha = 1 - (1 - alpha) ^ 3
			local currentCFrame = phase2StartCFrame:Lerp(phase2EndCFrame, alpha)
			ship:PivotTo(currentCFrame)
			task.wait()
		end
		ship:PivotTo(phase2EndCFrame)
	end

	-- Brief pause after landing
	task.wait(0.5)

	-- === RAMP SYSTEM: Enable ramp after landing ===
	GetSpaceShipService().SetShipLanded(player, true)
	-- === END RAMP SYSTEM ===

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

	-- === DEBUG: Log positions after landing ===
	local spaceShipService = GetSpaceShipService()
	local shipAfterLanding = spaceShipService.GetShip(player)
	local planetAfterLanding = Workspace:FindFirstChild("Planet")
	if shipAfterLanding then
		local shipCF = shipAfterLanding:GetPivot()
		print(string.format("[%s %s][DEBUG] Landing complete - Ship: pos=(%.1f, %.1f, %.1f), lookVector=(%.2f, %.2f, %.2f)",
			MODULE_NAME, VERSION,
			shipCF.Position.X, shipCF.Position.Y, shipCF.Position.Z,
			shipCF.LookVector.X, shipCF.LookVector.Y, shipCF.LookVector.Z))
	end
	if planetAfterLanding then
		local planetCF = planetAfterLanding:GetPivot()
		print(string.format("[%s %s][DEBUG] Landing complete - Planet: pos=(%.1f, %.1f, %.1f)",
			MODULE_NAME, VERSION,
			planetCF.Position.X, planetCF.Position.Y, planetCF.Position.Z))
	end
	-- === END DEBUG ===

	print(string.format("[%s %s] ✓ Landing complete for %s", MODULE_NAME, VERSION, player.Name))

	return true
end

function TransitionService.StartLaunchSequence(player)
	local currentContext = TransitionService.GetCurrentContext(player)
	if currentContext ~= TransitionConfig.Contexts.Surface then
		transitionUpdate:FireClient(player, "error", {
			message = TransitionConfig.Messages.NotInPilotSeat
		})
		return false
	end

	if playerTransitions[player] then
		return false
	end

	local profile = GetProfileService().GetProfile(player)
	local planetId = profile and profile.currentPlanet or "Planet_1"
	local planetDisplayName = GetPlanetDisplayName(planetId)

	-- === RAMP SYSTEM: Retract ramp before launch ===
	local spaceShipService = GetSpaceShipService()
	if spaceShipService.IsRampDeployed(player) then
		spaceShipService.RetractRamp(player)
		task.wait(1.5) -- Wait for retract animation
	end
	spaceShipService.SetShipLanded(player, false)
	-- === END RAMP SYSTEM ===

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

		-- Phase 2: External view
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
		ClearTransitionState(player)
		return false
	end

	-- === DEBUG: Log positions after Orbit load ===
	local shipAfterLoad = spaceShipService.GetShip(player)
	local planetAfterLoad = Workspace:FindFirstChild("Planet")
	if shipAfterLoad then
		local shipCF = shipAfterLoad:GetPivot()
		print(string.format("[%s %s][DEBUG] Ship after Orbit load: pos=(%.1f, %.1f, %.1f), lookVector=(%.2f, %.2f, %.2f)",
			MODULE_NAME, VERSION,
			shipCF.Position.X, shipCF.Position.Y, shipCF.Position.Z,
			shipCF.LookVector.X, shipCF.LookVector.Y, shipCF.LookVector.Z))
	end
	if planetAfterLoad then
		local planetCF = planetAfterLoad:GetPivot()
		print(string.format("[%s %s][DEBUG] Planet after Orbit load: pos=(%.1f, %.1f, %.1f)",
			MODULE_NAME, VERSION,
			planetCF.Position.X, planetCF.Position.Y, planetCF.Position.Z))
	end
	-- === END DEBUG ===

	-- === REPOSITION SHIP: Reset to Orbit start position for arrival animation ===
	local orbitSpawnPos = Vector3.new(0, 50, 0) -- Default final position
	local orbitSpawnRotation = CFrame.Angles(0, 0, 0) -- Default: looking forward (+Z)
	local orbitConfig = nil -- Will hold config for arrival animation
	local planetFolder = ServerStorage.Planets:FindFirstChild(planetId)
	if planetFolder then
		local orbitFolder = planetFolder:FindFirstChild("Orbit")
		if orbitFolder then
			local orbitConfigModule = orbitFolder:FindFirstChild("Config")
			if orbitConfigModule then
				local success, loadedConfig = pcall(require, orbitConfigModule)
				if success then
					orbitConfig = loadedConfig
					if orbitConfig.animationData and orbitConfig.animationData.spaceShip then
						orbitSpawnPos = orbitConfig.animationData.spaceShip.finalPosition or orbitSpawnPos
						-- Check for rotation in config
						if orbitConfig.animationData.spaceShip.rotation then
							local rot = orbitConfig.animationData.spaceShip.rotation
							orbitSpawnRotation = CFrame.Angles(math.rad(rot.X or 0), math.rad(rot.Y or 0), math.rad(rot.Z or 0))
						end
					end
				end
			end
		end
	end

	-- Position ship at arrival start (or final if no animation)
	local arrivalPath = orbitConfig and orbitConfig.animationData and orbitConfig.animationData.arrivalPath
	if shipAfterLoad then
		local startPos = arrivalPath and (orbitSpawnPos + arrivalPath.startOffset) or orbitSpawnPos
		
		-- Calculate rotation to face planet (planet is at +Z relative to ship)
		local planetPos = orbitConfig and orbitConfig.animationData and orbitConfig.animationData.planet 
			and orbitConfig.animationData.planet.finalPosition or Vector3.new(0, 100, 600)
		local shipLookAtPlanet = CFrame.lookAt(startPos, planetPos)
		
		shipAfterLoad:PivotTo(shipLookAtPlanet)
		print(string.format("[%s %s][DEBUG] Ship positioned at arrival start: pos=(%.1f, %.1f, %.1f), facing planet",
			MODULE_NAME, VERSION, startPos.X, startPos.Y, startPos.Z))
	end
	-- === END REPOSITION ===

	task.wait(TransitionConfig.LoadingMinDuration)

	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not character or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		LoadCharacterSilently(player)
		task.wait(1.0)
	end

	-- Spawn player in PilotSeat
	locService.SpawnPlayerInLocation(player, "PilotSeat")

	-- Brief wait for spawn to complete
	task.wait(0.5)

	-- === SHIP ARRIVAL ANIMATION ===
	if shipAfterLoad and arrivalPath then
		-- Wait for client to fully receive/stream planet model
		-- Launch returns to orbit where planet is newly loaded, needs streaming time
		task.wait(1.5)

		-- Notify client about arrival animation (cockpit view, planet approaches)
		SetTransitionState(player, TransitionConfig.States.Arrival, nil)
		transitionUpdate:FireClient(player, TransitionConfig.States.Arrival, {
			duration = TransitionConfig.ShipArrivalDuration,
			message = TransitionConfig.Messages.GameStartArrival
		})

		-- Get planet position for animation
		local planetPos = orbitConfig and orbitConfig.animationData and orbitConfig.animationData.planet 
			and orbitConfig.animationData.planet.finalPosition or Vector3.new(0, 100, 600)
		
		-- Animate ship from start position to final orbit position
		AnimateShipArrival(shipAfterLoad, orbitSpawnPos, arrivalPath, TransitionConfig.ShipArrivalDuration, planetPos)

		print(string.format("[%s %s][DEBUG] Launch - Arrival animation complete, ship at final position",
			MODULE_NAME, VERSION))
	end
	-- === END ARRIVAL ANIMATION ===

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

	print(string.format("[%s %s] ✓ Launch complete for %s", MODULE_NAME, VERSION, player.Name))

	return true
end

-- ============================================================================
-- INITIAL GAME START SEQUENCE
-- ============================================================================

function TransitionService.StartGameSequence(player)
	local profile = GetProfileService().GetProfile(player)
	if not profile then
		return false
	end

	local planetId = profile.currentPlanet or "Planet_1"
	local planetDisplayName = GetPlanetDisplayName(planetId)

	if playerTransitions[player] then
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
		ClearTransitionState(player)
		transitionUpdate:FireClient(player, "error", {
			message = TransitionConfig.Messages.InvalidLocation
		})
		return false
	end

	-- === EPIC 3: Spawn SpaceShip from ServerStorage/Actors ===
	local spaceShipService = GetSpaceShipService()
	local orbitSpawnPos = Vector3.new(0, 50, 0) -- Default orbit position
	local orbitConfig = nil -- Will hold config for arrival animation

	-- Get SpaceShip position from Orbit Config animation data
	local planetFolder = ServerStorage.Planets:FindFirstChild(planetId)
	if planetFolder then
		local orbitFolder = planetFolder:FindFirstChild("Orbit")
		if orbitFolder then
			local orbitConfigModule = orbitFolder:FindFirstChild("Config")
			if orbitConfigModule then
				local success, loadedConfig = pcall(require, orbitConfigModule)
				if success then
					orbitConfig = loadedConfig
					if orbitConfig.animationData and orbitConfig.animationData.spaceShip then
						orbitSpawnPos = orbitConfig.animationData.spaceShip.finalPosition or orbitSpawnPos
					end
				end
			end
		end
	end

	-- Spawn ship at start position for arrival animation (or final if no animation)
	local arrivalPath = orbitConfig and orbitConfig.animationData and orbitConfig.animationData.arrivalPath
	local shipStartPos = arrivalPath and (orbitSpawnPos + arrivalPath.startOffset) or orbitSpawnPos
	
	-- Calculate rotation to face planet (planet is at +Z relative to ship)
	local planetPos = orbitConfig and orbitConfig.animationData and orbitConfig.animationData.planet 
		and orbitConfig.animationData.planet.finalPosition or Vector3.new(0, 100, 600)
	local shipLookAtPlanet = CFrame.lookAt(shipStartPos, planetPos)
	local shipRotation = shipLookAtPlanet - shipLookAtPlanet.Position -- Extract rotation only
	
	spaceShipService.SpawnShip(player, shipStartPos, shipRotation)

	-- === DEBUG: Log initial positions ===
	local shipInitial = spaceShipService.GetShip(player)
	local planetInitial = Workspace:FindFirstChild("Planet")
	if shipInitial then
		local shipCF = shipInitial:GetPivot()
		print(string.format("[%s %s][DEBUG] GameStart - Ship spawned: pos=(%.1f, %.1f, %.1f), lookVector=(%.2f, %.2f, %.2f)",
			MODULE_NAME, VERSION,
			shipCF.Position.X, shipCF.Position.Y, shipCF.Position.Z,
			shipCF.LookVector.X, shipCF.LookVector.Y, shipCF.LookVector.Z))
	end
	if planetInitial then
		local planetCF = planetInitial:GetPivot()
		print(string.format("[%s %s][DEBUG] GameStart - Planet: pos=(%.1f, %.1f, %.1f)",
			MODULE_NAME, VERSION,
			planetCF.Position.X, planetCF.Position.Y, planetCF.Position.Z))
	end
	-- === END DEBUG ===
	-- === END EPIC 3 ===

	task.wait(TransitionConfig.LoadingMinDuration)

	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not character or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		LoadCharacterSilently(player)
		task.wait(1.0)
	end

	-- Spawn player in PilotSeat
	locService.SpawnPlayerInLocation(player, "PilotSeat")
	task.wait(0.5)

	-- Restore character sounds (were muted during boot sequence)
	if player.Character then
		RestoreCharacterSounds(player.Character)
	end

	-- === SHIP ARRIVAL ANIMATION ===
	local ship = spaceShipService.GetShip(player)
	if ship and arrivalPath then
		-- Wait for client to fully receive/stream planet model
		-- First load requires more time for streaming than subsequent loads
		-- Planet model is large (~1600 radius) and may take time to stream
		task.wait(1.5)

		-- Notify client about arrival animation (cockpit view, planet approaches)
		SetTransitionState(player, TransitionConfig.States.Arrival, nil)
		transitionUpdate:FireClient(player, TransitionConfig.States.Arrival, {
			duration = TransitionConfig.ShipArrivalDuration,
			message = TransitionConfig.Messages.GameStartArrival
		})

		-- Animate ship from start position to final orbit position (planetPos already defined above)
		AnimateShipArrival(ship, orbitSpawnPos, arrivalPath, TransitionConfig.ShipArrivalDuration, planetPos)

		print(string.format("[%s %s][DEBUG] GameStart - Arrival animation complete, ship at final position",
			MODULE_NAME, VERSION))
	end
	-- === END ARRIVAL ANIMATION ===

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

	print(string.format("[%s %s] ✓ GameStart complete for %s", MODULE_NAME, VERSION, player.Name))

	return true
end

-- ============================================================================
-- RETURN
-- ============================================================================

return TransitionService
