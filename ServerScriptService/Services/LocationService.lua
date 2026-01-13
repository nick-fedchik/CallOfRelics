--[[
================================================================================
KOSMICMAZER — LocationService
================================================================================

Purpose:
Manages loading and unloading of game locations (Planet Orbits, Surface Locations).
Handles workspace cleanup, content copying, and player spawning.
Enforces TDD 5.6 "Complete Context Cleanup" principle.

Version:
0.1

Features:
- Load location from ServerStorage.Planets structure
- Unload current location with complete cleanup
- Copy scripts, models, and lighting between locations and workspace
- Spawn player in PilotSeat or SpawnLocation
- Track current active location per player
- Support for Orbit and Surface location types

API:
- Initialize() — Initialize service, must be called during boot
- LoadLocation(player, planetId, locationName) — Load location for player
- UnloadLocation(player) — Unload current location and cleanup workspace
- GetCurrentLocation(player) — Returns current location info or nil
- SpawnPlayerInLocation(player, spawnType) — Spawn player in loaded location

Calls to:
- ServerStorage.Planets (location configs and content)
- GameConfig (future: spawn settings)
- Workspace (clearing and copying content)

Called from:
- BootSequence (Stage 4: load initial location)
- TeleportService (future: location transitions)
- GameStateManager (future: state-driven location changes)

Events:
- None yet (future: LocationLoaded, LocationUnloaded)

Dependencies:
- ServerStorage.Planets structure
- Location Config.luau files

ChangeLog:
- 0.1: Initial LocationService with Load/Unload/Spawn (2026-01-12)
================================================================================
]]

local MODULE_NAME = "LocationService"
local VERSION = "0.1"

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- ============================================================================
-- STATE
-- ============================================================================

local LocationService = {}
local isInitialized = false

-- Track current location per player
-- Structure: {[player] = {planetId = "Planet_1", locationName = "Orbit", config = {...}}}
local currentLocations = {}

-- Track spawned content for cleanup
-- Structure: {[player] = {models = {}, scripts = {}, lightingObjects = {}}}
local spawnedContent = {}

-- ============================================================================
-- PRIVATE HELPERS
-- ============================================================================

local function ClearWorkspace()
	print(string.format("[%s %s][ClearWorkspace] Clearing Workspace and Lighting", MODULE_NAME, VERSION))

	-- Clear workspace (keep Terrain, Camera)
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") or child:IsA("Part") or child:IsA("Folder") then
			if child.Name ~= "Terrain" and child.Name ~= "Camera" then
				child:Destroy()
			end
		end
	end

	-- Clear Lighting effects
	local Lighting = game:GetService("Lighting")
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("BloomEffect")
			or child:IsA("DepthOfFieldEffect") or child:IsA("SunRaysEffect") then
			child:Destroy()
		end
	end

	print(string.format("[%s %s][ClearWorkspace] ✓ Workspace cleared", MODULE_NAME, VERSION))
end

local function CopyModelsToWorkspace(locationWorkspaceFolder)
	if not locationWorkspaceFolder then
		warn(string.format("[%s %s][CopyModels] No Workspace folder in location", MODULE_NAME, VERSION))
		return {}
	end

	local copiedModels = {}

	for _, child in ipairs(locationWorkspaceFolder:GetChildren()) do
		if child.Name ~= "Lighting" then -- Lighting handled separately
			local clone = child:Clone()

			-- Set ModelStreamingMode to Persistent to prevent streaming from removing models
			if clone:IsA("Model") then
				clone.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

				-- Anchor all parts in the model to prevent falling (except seats)
				for _, part in ipairs(clone:GetDescendants()) do
					if part:IsA("BasePart") and not part:IsA("Seat") and not part:IsA("VehicleSeat") then
						part.Anchored = true
					end
				end
				print(string.format("[%s %s][CopyModels] Copied & Anchored: %s (%s) [Persistent]",
					MODULE_NAME, VERSION, child.Name, child.ClassName))
			else
				print(string.format("[%s %s][CopyModels] Copied: %s (%s)",
					MODULE_NAME, VERSION, child.Name, child.ClassName))
			end

			clone.Parent = Workspace
			table.insert(copiedModels, clone)
		end
	end

	return copiedModels
end

local function CopyLightingObjects(locationLightingFolder)
	if not locationLightingFolder then
		warn(string.format("[%s %s][CopyLighting] No Lighting folder in location", MODULE_NAME, VERSION))
		return {}
	end

	local Lighting = game:GetService("Lighting")
	local copiedObjects = {}

	for _, child in ipairs(locationLightingFolder:GetChildren()) do
		local clone = child:Clone()
		clone.Parent = Lighting
		table.insert(copiedObjects, clone)
		print(string.format("[%s %s][CopyLighting] Copied: %s (%s)",
			MODULE_NAME, VERSION, child.Name, child.ClassName))
	end

	return copiedObjects
end

local function CopyScriptsToService(locationFolder, targetServiceName)
	-- Future implementation: copy scripts from location to ReplicatedStorage/ServerScriptService
	-- For now, scripts stay in location folders and are required directly
	print(string.format("[%s %s][CopyScripts] Script copying not yet implemented (future feature)",
		MODULE_NAME, VERSION))
	return {}
end

local function FindSpawnPoint(locationName)
	-- Find SpawnLocation or PilotSeat in Workspace

	-- DEBUG: List all Workspace children
	print(string.format("[%s %s][FindSpawn] DEBUG: Workspace children:", MODULE_NAME, VERSION))
	for _, child in ipairs(Workspace:GetChildren()) do
		print(string.format("  - %s (%s)", child.Name, child.ClassName))
	end

	-- Try to find SpaceShip.PilotSeat first (for Orbit)
	local spaceShip = Workspace:FindFirstChild("SpaceShip")
	if spaceShip then
		local pilotSeat = spaceShip:FindFirstChild("PilotSeat", true) -- recursive
		if pilotSeat and pilotSeat:IsA("VehicleSeat") then
			print(string.format("[%s %s][FindSpawn] Found PilotSeat in SpaceShip", MODULE_NAME, VERSION))
			return pilotSeat, "PilotSeat"
		end
	end

	-- Try to find SpawnLocation (for Surface)
	local spawnLocation = Workspace:FindFirstChild("SpawnLocation", true)
	if spawnLocation and spawnLocation:IsA("SpawnLocation") then
		print(string.format("[%s %s][FindSpawn] Found SpawnLocation", MODULE_NAME, VERSION))
		return spawnLocation, "SpawnLocation"
	end

	warn(string.format("[%s %s][FindSpawn] No spawn point found! Using default (0,5,0)",
		MODULE_NAME, VERSION))
	return nil, "Default"
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function LocationService.Initialize()
	if isInitialized then
		warn(string.format("[%s %s][Initialize] Already initialized", MODULE_NAME, VERSION))
		return true
	end

	print(string.format("[%s %s] 🚀 Initializing LocationService...", MODULE_NAME, VERSION))

	-- Verify ServerStorage.Planets exists
	local planetsFolder = ServerStorage:FindFirstChild("Planets")
	if not planetsFolder then
		error(string.format("[%s %s][Initialize] ❌ ServerStorage.Planets folder not found!",
			MODULE_NAME, VERSION))
	end

	isInitialized = true
	print(string.format("[%s %s] ✓ LocationService initialized", MODULE_NAME, VERSION))
	return true
end

function LocationService.LoadLocation(player, planetId, locationName)
	if not isInitialized then
		error(string.format("[%s %s][LoadLocation] Service not initialized!", MODULE_NAME, VERSION))
	end

	print(string.format("[%s %s][LoadLocation] Loading %s/%s for %s",
		MODULE_NAME, VERSION, planetId, locationName, player.Name))

	-- Step 1: Unload current location if any
	if currentLocations[player] then
		LocationService.UnloadLocation(player)
	end

	-- Step 2: Load Planet Config
	local planetFolder = ServerStorage.Planets:FindFirstChild(planetId)
	if not planetFolder then
		error(string.format("[%s %s][LoadLocation] Planet not found: %s",
			MODULE_NAME, VERSION, planetId))
	end

	local planetConfig = require(planetFolder:WaitForChild("Config"))
	print(string.format("[%s %s][LoadLocation] Loaded planet config: %s",
		MODULE_NAME, VERSION, planetConfig.name))

	-- Step 3: Load Location Config
	local locationFolder
	if locationName == "Orbit" then
		locationFolder = planetFolder:FindFirstChild("Orbit")
	else
		-- Surface location
		local surfaceFolder = planetFolder:FindFirstChild("Surface")
		if surfaceFolder then
			locationFolder = surfaceFolder:FindFirstChild(locationName)
		end
	end

	if not locationFolder then
		error(string.format("[%s %s][LoadLocation] Location not found: %s/%s",
			MODULE_NAME, VERSION, planetId, locationName))
	end

	local locationConfig = require(locationFolder:WaitForChild("Config"))
	print(string.format("[%s %s][LoadLocation] Loaded location config: %s (type: %s)",
		MODULE_NAME, VERSION, locationConfig.name, locationConfig.type))

	-- Step 4: Clear Workspace
	ClearWorkspace()

	-- Step 5: Copy Location Content
	local workspaceFolder = locationFolder:FindFirstChild("Workspace")
	local lightingFolder = workspaceFolder and workspaceFolder:FindFirstChild("Lighting")

	local copiedModels = CopyModelsToWorkspace(workspaceFolder)
	local copiedLighting = CopyLightingObjects(lightingFolder)

	-- DEBUG: Verify models are in Workspace after copy
	print(string.format("[%s %s][LoadLocation] DEBUG: After copy, Workspace children:", MODULE_NAME, VERSION))
	for _, child in ipairs(Workspace:GetChildren()) do
		print(string.format("  - %s (%s)", child.Name, child.ClassName))
	end

	-- Track spawned content
	spawnedContent[player] = {
		models = copiedModels,
		lightingObjects = copiedLighting,
		scripts = {} -- Future: track copied scripts
	}

	-- Step 6: Apply location settings
	local settings = locationConfig.getSettings()
	if settings then
		-- Apply gravity (use absolute value, Workspace.Gravity expects positive number)
		if settings.gravity then
			Workspace.Gravity = math.abs(settings.gravity.Y)
			print(string.format("[%s %s][LoadLocation] Set gravity: %s",
				MODULE_NAME, VERSION, tostring(Workspace.Gravity)))
		end
	end

	-- Step 7: Track current location
	currentLocations[player] = {
		planetId = planetId,
		locationName = locationName,
		config = locationConfig,
		planetConfig = planetConfig
	}

	print(string.format("[%s %s][LoadLocation] ✓ Location loaded: %s/%s",
		MODULE_NAME, VERSION, planetId, locationName))

	return true
end

function LocationService.UnloadLocation(player)
	if not currentLocations[player] then
		print(string.format("[%s %s][UnloadLocation] No location to unload for %s",
			MODULE_NAME, VERSION, player.Name))
		return
	end

	local locationInfo = currentLocations[player]
	print(string.format("[%s %s][UnloadLocation] Unloading %s/%s for %s",
		MODULE_NAME, VERSION, locationInfo.planetId, locationInfo.locationName, player.Name))

	-- Cleanup spawned content
	if spawnedContent[player] then
		-- Destroy models
		for _, model in ipairs(spawnedContent[player].models) do
			if model and model.Parent then
				model:Destroy()
			end
		end

		-- Destroy lighting objects
		for _, lightingObj in ipairs(spawnedContent[player].lightingObjects) do
			if lightingObj and lightingObj.Parent then
				lightingObj:Destroy()
			end
		end

		-- Future: cleanup scripts

		spawnedContent[player] = nil
	end

	-- Clear current location tracking
	currentLocations[player] = nil

	-- Clear workspace completely
	ClearWorkspace()

	print(string.format("[%s %s][UnloadLocation] ✓ Location unloaded for %s",
		MODULE_NAME, VERSION, player.Name))
end

function LocationService.GetCurrentLocation(player)
	return currentLocations[player]
end

function LocationService.SpawnPlayerInLocation(player, spawnType)
	print(string.format("[%s %s][SpawnPlayer] Spawning %s (type: %s)",
		MODULE_NAME, VERSION, player.Name, spawnType or "auto"))

	local character = player.Character
	if not character then
		warn(string.format("[%s %s][SpawnPlayer] No character found for %s",
			MODULE_NAME, VERSION, player.Name))
		return false
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not humanoidRootPart then
		warn(string.format("[%s %s][SpawnPlayer] Character missing Humanoid or HRP",
			MODULE_NAME, VERSION))
		return false
	end

	-- Find spawn point
	local spawnPoint, foundSpawnType = FindSpawnPoint()

	if foundSpawnType == "PilotSeat" and spawnPoint then
		-- Spawn IN PilotSeat (sitting)
		task.wait(0.2) -- Wait for character to fully load

		-- Configure seat - disable movement but allow sitting/standing
		if spawnPoint:IsA("VehicleSeat") then
			spawnPoint.Disabled = false
			spawnPoint.MaxSpeed = 0  -- Prevent ship from moving (ship is parked in orbit)
			spawnPoint.TurnSpeed = 0 -- Prevent ship from turning
			print(string.format("[%s %s][SpawnPlayer] PilotSeat configured: Disabled=%s, MaxSpeed=%d, TurnSpeed=%d",
				MODULE_NAME, VERSION, tostring(spawnPoint.Disabled), spawnPoint.MaxSpeed, spawnPoint.TurnSpeed))
		end

		-- Sit player in seat
		if spawnPoint:IsA("Seat") or spawnPoint:IsA("VehicleSeat") then
			spawnPoint:Sit(humanoid)
			task.wait(0.3)

			print(string.format("[%s %s][SpawnPlayer] ✓ %s spawned in PilotSeat",
				MODULE_NAME, VERSION, player.Name))
		else
			warn(string.format("[%s %s][SpawnPlayer] PilotSeat is not a Seat or VehicleSeat!",
				MODULE_NAME, VERSION))
		end

		return true

	elseif foundSpawnType == "SpawnLocation" and spawnPoint then
		-- Spawn at SpawnLocation
		humanoidRootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 3, 0)

		print(string.format("[%s %s][SpawnPlayer] ✓ %s spawned at SpawnLocation",
			MODULE_NAME, VERSION, player.Name))
		return true

	else
		-- Default spawn
		humanoidRootPart.CFrame = CFrame.new(0, 5, 0)

		print(string.format("[%s %s][SpawnPlayer] ✓ %s spawned at default position",
			MODULE_NAME, VERSION, player.Name))
		return true
	end
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(player)
	if currentLocations[player] then
		LocationService.UnloadLocation(player)
	end
end)

-- ============================================================================
-- RETURN
-- ============================================================================

return LocationService
