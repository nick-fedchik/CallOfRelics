--[[
================================================================================
KOSMICMAZER — LocationService
================================================================================

Purpose:
Manages loading and unloading of game locations (Planet Orbits, Surface Locations).
Handles workspace cleanup, content copying, and player spawning.
Enforces TDD 5.6 "Complete Context Cleanup" principle.

Version:
0.3

Features:
- Load location from ServerStorage.Planets structure
- Unload current location with complete cleanup
- Copy scripts, models, and lighting between locations and workspace
- Spawn player in PilotSeat or SpawnLocation
- Track current active location per player
- Support for Orbit and Surface location types
- Preserve SpaceShip and Player Characters across location transitions

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
- 0.3: Unanchor character before spawning (fix for silent boot spawn) (2026-01-15)
- 0.2: Preserve SpaceShip and Player Characters in ClearWorkspace (2026-01-15)
- 0.1: Initial LocationService with Load/Unload/Spawn (2026-01-12)
================================================================================
]]

local MODULE_NAME = "LocationService"
local VERSION = "0.3"

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

local function IsPlayerCharacter(model)
	-- Check if model is a player's character
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character == model then
			return true
		end
	end
	return false
end

local function ClearWorkspace()
	-- Clear workspace (keep Terrain, Camera, SpaceShip, Player Characters)
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") or child:IsA("Part") or child:IsA("Folder") then
			local shouldKeep = child.Name == "Terrain"
				or child.Name == "Camera"
				or child.Name == "SpaceShip"
				or IsPlayerCharacter(child)

			if not shouldKeep then
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
end

local function CopyModelsToWorkspace(locationWorkspaceFolder)
	if not locationWorkspaceFolder then
		warn(string.format("[%s %s][CopyModels] No Workspace folder in location", MODULE_NAME, VERSION))
		return {}
	end

	local copiedModels = {}

	for _, child in ipairs(locationWorkspaceFolder:GetChildren()) do
		if child.Name ~= "Lighting" then -- Lighting handled separately

			-- Special handling for SpaceShip - reuse existing if present
			if child.Name == "SpaceShip" then
				local existingShip = Workspace:FindFirstChild("SpaceShip")
				if existingShip then
					local templateCFrame = child:GetPivot()
					existingShip:PivotTo(templateCFrame)
					table.insert(copiedModels, existingShip)
					continue -- Skip cloning
				end
			end

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
			end

			clone.Parent = Workspace
			table.insert(copiedModels, clone)
		end
	end

	return copiedModels
end

local function CopyLightingObjects(locationLightingFolder)
	if not locationLightingFolder then
		return {}
	end

	local Lighting = game:GetService("Lighting")
	local copiedObjects = {}

	for _, child in ipairs(locationLightingFolder:GetChildren()) do
		local clone = child:Clone()
		clone.Parent = Lighting
		table.insert(copiedObjects, clone)
	end

	return copiedObjects
end

local function FindSpawnPoint()
	-- Try to find SpaceShip.PilotSeat first (for Orbit)
	local spaceShip = Workspace:FindFirstChild("SpaceShip")
	if spaceShip then
		local pilotSeat = spaceShip:FindFirstChild("PilotSeat", true)
		if pilotSeat and pilotSeat:IsA("VehicleSeat") then
			return pilotSeat, "PilotSeat"
		end
	end

	-- Try to find SpawnLocation (for Surface)
	local spawnLocation = Workspace:FindFirstChild("SpawnLocation", true)
	if spawnLocation and spawnLocation:IsA("SpawnLocation") then
		return spawnLocation, "SpawnLocation"
	end

	warn(string.format("[%s %s][FindSpawn] No spawn point found!", MODULE_NAME, VERSION))
	return nil, "Default"
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function LocationService.Initialize()
	if isInitialized then
		return true
	end

	local planetsFolder = ServerStorage:FindFirstChild("Planets")
	if not planetsFolder then
		error(string.format("[%s %s] ServerStorage.Planets not found!", MODULE_NAME, VERSION))
	end

	isInitialized = true
	print(string.format("[%s %s] ✓ LocationService ready", MODULE_NAME, VERSION))
	return true
end

function LocationService.LoadLocation(player, planetId, locationName)
	if not isInitialized then
		error(string.format("[%s %s][LoadLocation] Service not initialized!", MODULE_NAME, VERSION))
	end

	-- Unload current location if any
	if currentLocations[player] then
		LocationService.UnloadLocation(player)
	end

	-- Load Planet Config
	local planetFolder = ServerStorage.Planets:FindFirstChild(planetId)
	if not planetFolder then
		error(string.format("[%s %s][LoadLocation] Planet not found: %s", MODULE_NAME, VERSION, planetId))
	end

	local planetConfig = require(planetFolder:WaitForChild("Config"))

	-- Load Location Config
	local locationFolder
	if locationName == "Orbit" then
		locationFolder = planetFolder:FindFirstChild("Orbit")
	else
		local surfaceFolder = planetFolder:FindFirstChild("Surface")
		if surfaceFolder then
			locationFolder = surfaceFolder:FindFirstChild(locationName)
		end
	end

	if not locationFolder then
		error(string.format("[%s %s][LoadLocation] Location not found: %s/%s", MODULE_NAME, VERSION, planetId, locationName))
	end

	local locationConfig = require(locationFolder:WaitForChild("Config"))

	-- Clear Workspace
	ClearWorkspace()

	-- Copy Location Content
	local workspaceFolder = locationFolder:FindFirstChild("Workspace")
	local lightingFolder = workspaceFolder and workspaceFolder:FindFirstChild("Lighting")

	local copiedModels = CopyModelsToWorkspace(workspaceFolder)
	local copiedLighting = CopyLightingObjects(lightingFolder)

	-- Track spawned content
	spawnedContent[player] = {
		models = copiedModels,
		lightingObjects = copiedLighting,
		scripts = {}
	}

	-- Apply location settings
	local settings = locationConfig.getSettings()
	if settings and settings.gravity then
		Workspace.Gravity = math.abs(settings.gravity.Y)
	end

	-- Track current location
	currentLocations[player] = {
		planetId = planetId,
		locationName = locationName,
		config = locationConfig,
		planetConfig = planetConfig
	}

	print(string.format("[%s %s] ✓ Location loaded: %s/%s", MODULE_NAME, VERSION, planetId, locationName))

	return true
end

function LocationService.UnloadLocation(player)
	if not currentLocations[player] then
		return
	end

	-- Cleanup spawned content (but preserve SpaceShip)
	if spawnedContent[player] then
		for _, model in ipairs(spawnedContent[player].models) do
			if model and model.Parent and model.Name ~= "SpaceShip" then
				model:Destroy()
			end
		end

		for _, lightingObj in ipairs(spawnedContent[player].lightingObjects) do
			if lightingObj and lightingObj.Parent then
				lightingObj:Destroy()
			end
		end

		spawnedContent[player] = nil
	end

	currentLocations[player] = nil
	ClearWorkspace()
end

function LocationService.GetCurrentLocation(player)
	return currentLocations[player]
end

function LocationService.SpawnPlayerInLocation(player, spawnType)
	local character = player.Character
	if not character then
		warn(string.format("[%s %s][SpawnPlayer] No character for %s", MODULE_NAME, VERSION, player.Name))
		return false
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not humanoidRootPart then
		warn(string.format("[%s %s][SpawnPlayer] Character missing Humanoid/HRP", MODULE_NAME, VERSION))
		return false
	end

	-- CRITICAL: Unanchor character (may have been anchored during boot for silent spawn)
	if humanoidRootPart.Anchored then
		humanoidRootPart.Anchored = false
	end

	-- Find spawn point
	local spawnPoint, foundSpawnType = FindSpawnPoint()

	-- Override with specific spawn type if requested
	if spawnType == "PilotSeat" then
		local spaceShip = Workspace:FindFirstChild("SpaceShip")
		if spaceShip then
			local pilotSeat = spaceShip:FindFirstChild("PilotSeat", true)
			if pilotSeat then
				spawnPoint = pilotSeat
				foundSpawnType = "PilotSeat"
			end
		end
	elseif spawnType == "SpawnLocation" then
		local sl = Workspace:FindFirstChild("SpawnLocation", true)
		if sl then
			spawnPoint = sl
			foundSpawnType = "SpawnLocation"
		end
	end

	if foundSpawnType == "PilotSeat" and spawnPoint then
		-- Check if player is already sitting
		if humanoid.SeatPart == spawnPoint then
			return true
		end

		task.wait(0.2)

		if spawnPoint:IsA("VehicleSeat") then
			spawnPoint.Disabled = false
			spawnPoint.MaxSpeed = 0
			spawnPoint.TurnSpeed = 0
		end

		if spawnPoint:IsA("Seat") or spawnPoint:IsA("VehicleSeat") then
			spawnPoint:Sit(humanoid)
			task.wait(0.3)
			print(string.format("[%s %s] ✓ %s spawned in PilotSeat", MODULE_NAME, VERSION, player.Name))
		end

		return true

	elseif foundSpawnType == "SpawnLocation" and spawnPoint then
		humanoidRootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 3, 0)
		print(string.format("[%s %s] ✓ %s spawned at SpawnLocation", MODULE_NAME, VERSION, player.Name))
		return true

	else
		humanoidRootPart.CFrame = CFrame.new(0, 5, 0)
		print(string.format("[%s %s] ✓ %s spawned at default", MODULE_NAME, VERSION, player.Name))
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
