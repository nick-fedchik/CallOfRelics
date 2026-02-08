--[[
================================================================================
KOSMICMAZER — LocationService
================================================================================

Purpose:
Manages loading and unloading of game locations (Planet Orbits, Surface Locations).
Implements Init/Fini system for proper content lifecycle management.
Handles workspace cleanup, content copying, and player spawning.
Enforces TDD 5.6 "Complete Context Cleanup" principle.

Version:
0.7

Features:
- Load location from ServerStorage.Planets structure
- Unload current location with complete cleanup
- Init/Fini system for Planet, Orbit, and Location levels
- Copy scripts, models, and lighting with registry tracking
- LevelController pattern: single entry point per level (orbit/location/planet)
- Folder-based script copying (preserves hierarchy, scripts see siblings)
- Spawn player in PilotSeat or SpawnLocation
- Track current active location per player
- Support for Orbit and Surface location types
- Preserve SpaceShip and Player Characters across location transitions

Init/Fini Hierarchy:
- Enter Game → Planet Init → Orbit Init
- Landing    → Orbit Fini → Location Init
- Launch     → Location Fini → Orbit Init
- Leave Planet → Location/Orbit Fini → Planet Fini

API:
- Initialize() — Initialize service, must be called during boot
- LoadLocation(player, planetId, locationName) — Load location for player
- UnloadLocation(player) — Unload current location and cleanup workspace
- GetCurrentLocation(player) — Returns current location info or nil
- SpawnPlayerInLocation(player, spawnType) — Spawn player in loaded location

Init/Fini API:
- InitPlanet(player, planetId) — Initialize planet context
- FiniPlanet(player) — Cleanup planet context
- InitOrbit(player, planetId) — Initialize orbit context
- FiniOrbit(player) — Cleanup orbit context
- InitLocation(player, planetId, locationId) — Initialize surface location
- FiniLocation(player) — Cleanup surface location

Calls to:
- ServerStorage.Planets (location configs and content)
- ContextRegistryService (track copied content)
- Workspace (clearing and copying content)

Called from:
- BootSequence (Stage 4: load initial location)
- TransitionService (location transitions)
- GameStateManager (future: state-driven location changes)

Events:
- None yet (future: LocationLoaded, LocationUnloaded)

Dependencies:
- ServerStorage.Planets structure
- Location Config.luau files
- ContextRegistryService

ChangeLog:
- 0.7: LevelController pattern — folder-based copy, single entry point per level (2026-02-08)
- 0.6: ModuleScript levelInit/levelFini framework, rename CopyScriptsToService (2026-02-08)
- 0.5: Init/Fini system with ContextRegistryService integration (EPIC 4) (2026-01-16)
- 0.4: Apply animationData positions to models after copying (EPIC 3) (2026-01-16)
- 0.3: Unanchor character before spawning (fix for silent boot spawn) (2026-01-15)
- 0.2: Preserve SpaceShip and Player Characters in ClearWorkspace (2026-01-15)
- 0.1: Initial LocationService with Load/Unload/Spawn (2026-01-12)
================================================================================
]]

local MODULE_NAME = "LocationService"
local VERSION = "0.7"

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

-- ============================================================================
-- DEPENDENCIES (Lazy-loaded)
-- ============================================================================

local ContextRegistryService

local function GetContextRegistryService()
	if not ContextRegistryService then
		ContextRegistryService = require(script.Parent.ContextRegistryService)
	end
	return ContextRegistryService
end

-- ============================================================================
-- STATE
-- ============================================================================

local LocationService = {}
local isInitialized = false

-- Track current location per player
-- Structure: {[player] = {planetId = "Planet_1", locationName = "Orbit", config = {...}}}
local currentLocations = {}

-- Track current context level per player
-- Structure: {[player] = {planet = true/false, orbit = true/false, location = true/false}}
local activeContexts = {}

-- Track initialized ModuleScript modules for levelFini cleanup
-- Structure: {[player] = {planet = {}, orbit = {}, location = {}}}
local initializedModules = {}

-- ============================================================================
-- PRIVATE HELPERS
-- ============================================================================

local function IsPlayerCharacter(model)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character == model then
			return true
		end
	end
	return false
end

local function ClearWorkspaceObjects()
	-- Clear generated terrain (procedural terrain from TerrainGenerator)
	Workspace.Terrain:Clear()

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
end

local function ClearLightingEffects()
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("BloomEffect")
			or child:IsA("DepthOfFieldEffect") or child:IsA("SunRaysEffect") then
			child:Destroy()
		end
	end
end

local function EnsureModuleTracking(player)
	if not initializedModules[player] then
		initializedModules[player] = { planet = {}, orbit = {}, location = {} }
	end
	return initializedModules[player]
end

local function CopyScriptsToReplicatedStorage(sourceFolder, player, registerFunc)
	if not sourceFolder then return end

	local registry = GetContextRegistryService()

	for _, child in ipairs(sourceFolder:GetChildren()) do
		if child:IsA("ModuleScript") or child:IsA("Script") or child:IsA("LocalScript") then
			local clone = child:Clone()
			clone.Parent = ReplicatedStorage
			registerFunc(registry, player, clone)
		end
	end
end

local function CopyScriptsToServerScriptService(sourceFolder, player, registerFunc, contextLevel)
	if not sourceFolder then return end

	-- Skip empty folders (no scripts to copy)
	local hasScripts = false
	for _, child in ipairs(sourceFolder:GetChildren()) do
		if child:IsA("ModuleScript") or child:IsA("Script") or child:IsA("LocalScript") then
			hasScripts = true
			break
		end
	end
	if not hasScripts then return end

	local registry = GetContextRegistryService()
	local modules = EnsureModuleTracking(player)

	-- Clone entire folder to preserve hierarchy (LevelController can find siblings)
	local clone = sourceFolder:Clone()
	clone.Name = sourceFolder.Parent.Name .. "_Scripts"
	clone.Parent = ServerScriptService
	registerFunc(registry, player, clone)

	-- Find and initialize LevelController (single entry point for the level)
	local controller = clone:FindFirstChild("LevelController")
	if controller and controller:IsA("ModuleScript") then
		local ok, mod = pcall(require, controller)
		if ok and type(mod) == "table" and type(mod.levelInit) == "function" then
			local initOk, err = pcall(mod.levelInit)
			if initOk then
				table.insert(modules[contextLevel], mod)
			else
				warn(string.format("[%s %s] levelInit failed for %s/LevelController: %s",
					MODULE_NAME, VERSION, sourceFolder.Parent.Name, tostring(err)))
			end
		elseif not ok then
			warn(string.format("[%s %s] Failed to require %s/LevelController: %s",
				MODULE_NAME, VERSION, sourceFolder.Parent.Name, tostring(mod)))
		end
	end
end

local function FiniModules(player, contextLevel)
	local modules = initializedModules[player]
	if not modules or not modules[contextLevel] then return end

	for _, mod in ipairs(modules[contextLevel]) do
		if type(mod.levelFini) == "function" then
			local ok, err = pcall(mod.levelFini)
			if not ok then
				warn(string.format("[%s %s] levelFini failed: %s", MODULE_NAME, VERSION, tostring(err)))
			end
		end
	end
	modules[contextLevel] = {}
end

local function CopyModelsToWorkspace(locationWorkspaceFolder, animationData, player, registerFunc)
	if not locationWorkspaceFolder then
		warn(string.format("[%s %s][CopyModels] No Workspace folder in location", MODULE_NAME, VERSION))
		return
	end

	local registry = GetContextRegistryService()

	for _, child in ipairs(locationWorkspaceFolder:GetChildren()) do
		if child.Name ~= "Lighting" then -- Lighting handled separately

			-- Skip SpaceShip - managed by SpaceShipService (EPIC 3)
			if child.Name == "SpaceShip" then
				continue
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

			-- Apply position from animationData if available (EPIC 3)
			if animationData and clone:IsA("Model") then
				local modelKey = string.lower(clone.Name)
				if animationData[modelKey] and animationData[modelKey].finalPosition then
					clone:PivotTo(CFrame.new(animationData[modelKey].finalPosition))
				end
			end

			registerFunc(registry, player, clone)
		end
	end
end

local function CopyLightingObjects(locationLightingFolder, player, registerFunc)
	if not locationLightingFolder then return end

	local registry = GetContextRegistryService()

	for _, child in ipairs(locationLightingFolder:GetChildren()) do
		local clone = child:Clone()
		clone.Parent = Lighting
		registerFunc(registry, player, clone)
	end
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

local function EnsureActiveContexts(player)
	if not activeContexts[player] then
		activeContexts[player] = {
			planet = false,
			orbit = false,
			location = false
		}
	end
	return activeContexts[player]
end

-- ============================================================================
-- INIT/FINI — PLANET LEVEL
-- ============================================================================

function LocationService.InitPlanet(player, planetId)
	local contexts = EnsureActiveContexts(player)
	if contexts.planet then
		return true -- Already initialized
	end

	local planetFolder = ServerStorage.Planets:FindFirstChild(planetId)
	if not planetFolder then
		warn(string.format("[%s %s][InitPlanet] Planet not found: %s", MODULE_NAME, VERSION, planetId))
		return false
	end

	local registry = GetContextRegistryService()

	-- Set current planet path
	registry.SetCurrentPlanetPath("ServerStorage.Planets." .. planetId)

	-- Copy Planet-level scripts
	local planetReplicatedStorage = planetFolder:FindFirstChild("ReplicatedStorage")
	local planetServerScriptService = planetFolder:FindFirstChild("ServerScriptService")

	CopyScriptsToReplicatedStorage(planetReplicatedStorage, player, registry.RegisterPlanetScript)
	CopyScriptsToServerScriptService(planetServerScriptService, player, registry.RegisterPlanetScript, "planet")

	contexts.planet = true
	return true
end

function LocationService.FiniPlanet(player)
	local contexts = activeContexts[player]
	if not contexts or not contexts.planet then
		return
	end

	-- First cleanup any active orbit or location
	if contexts.location then
		LocationService.FiniLocation(player)
	end
	if contexts.orbit then
		LocationService.FiniOrbit(player)
	end

	-- Call levelFini on planet modules before destroying
	FiniModules(player, "planet")

	-- Clear planet registry
	local registry = GetContextRegistryService()
	registry.ClearPlanetRegistry(player)

	registry.SetCurrentPlanetPath(nil)
	contexts.planet = false
end

-- ============================================================================
-- INIT/FINI — ORBIT LEVEL
-- ============================================================================

function LocationService.InitOrbit(player, planetId)
	local contexts = EnsureActiveContexts(player)

	-- Ensure planet is initialized
	if not contexts.planet then
		LocationService.InitPlanet(player, planetId)
	end

	-- Cleanup any active location first
	if contexts.location then
		LocationService.FiniLocation(player)
	end

	if contexts.orbit then
		return true -- Already initialized
	end

	local planetFolder = ServerStorage.Planets:FindFirstChild(planetId)
	if not planetFolder then return false end

	local orbitFolder = planetFolder:FindFirstChild("Orbit")
	if not orbitFolder then
		warn(string.format("[%s %s][InitOrbit] Orbit folder not found: %s", MODULE_NAME, VERSION, planetId))
		return false
	end

	local orbitConfig = require(orbitFolder:WaitForChild("Config"))
	local registry = GetContextRegistryService()

	-- Clear previous workspace content
	ClearWorkspaceObjects()
	ClearLightingEffects()

	-- Get animation data for model positioning
	local animationData = nil
	if orbitConfig.getAnimationData then
		animationData = orbitConfig.getAnimationData()
	end

	-- Copy Orbit workspace objects
	local workspaceFolder = orbitFolder:FindFirstChild("Workspace")
	if workspaceFolder then
		CopyModelsToWorkspace(workspaceFolder, animationData, player, registry.RegisterOrbitObject)

		-- Copy Lighting
		local lightingFolder = workspaceFolder:FindFirstChild("Lighting")
		if lightingFolder then
			CopyLightingObjects(lightingFolder, player, registry.RegisterOrbitLighting)
		end
	end

	-- Copy Orbit scripts
	local orbitReplicatedStorage = orbitFolder:FindFirstChild("ReplicatedStorage")
	local orbitServerScriptService = orbitFolder:FindFirstChild("ServerScriptService")

	CopyScriptsToReplicatedStorage(orbitReplicatedStorage, player, registry.RegisterOrbitScript)
	CopyScriptsToServerScriptService(orbitServerScriptService, player, registry.RegisterOrbitScript, "orbit")

	-- Apply Orbit settings
	local settings = orbitConfig.getSettings and orbitConfig.getSettings()
	if settings and settings.gravity then
		Workspace.Gravity = math.abs(settings.gravity.Y)
	end

	-- Track current location
	currentLocations[player] = {
		planetId = planetId,
		locationName = "Orbit",
		config = orbitConfig,
		planetConfig = require(planetFolder:WaitForChild("Config"))
	}

	contexts.orbit = true
	return true
end

function LocationService.FiniOrbit(player)
	local contexts = activeContexts[player]
	if not contexts or not contexts.orbit then
		return
	end

	-- Call levelFini on orbit modules before destroying
	FiniModules(player, "orbit")

	-- Clear orbit registry (destroys all tracked objects/scripts/lighting)
	local registry = GetContextRegistryService()
	registry.ClearOrbitRegistry(player)

	-- Clear workspace (in case anything was missed)
	ClearWorkspaceObjects()
	ClearLightingEffects()

	contexts.orbit = false
end

-- ============================================================================
-- INIT/FINI — LOCATION LEVEL
-- ============================================================================

function LocationService.InitLocation(player, planetId, locationId)
	local contexts = EnsureActiveContexts(player)

	-- Ensure planet is initialized
	if not contexts.planet then
		LocationService.InitPlanet(player, planetId)
	end

	-- Cleanup orbit if active (mutually exclusive with location)
	if contexts.orbit then
		LocationService.FiniOrbit(player)
	end

	-- Cleanup previous location if any
	if contexts.location then
		LocationService.FiniLocation(player)
	end

	local planetFolder = ServerStorage.Planets:FindFirstChild(planetId)
	if not planetFolder then return false end

	local surfaceFolder = planetFolder:FindFirstChild("Surface")
	if not surfaceFolder then
		warn(string.format("[%s %s][InitLocation] Surface folder not found: %s", MODULE_NAME, VERSION, planetId))
		return false
	end

	local locationFolder = surfaceFolder:FindFirstChild(locationId)
	if not locationFolder then
		warn(string.format("[%s %s][InitLocation] Location not found: %s/%s", MODULE_NAME, VERSION, planetId, locationId))
		return false
	end

	local locationConfig = require(locationFolder:WaitForChild("Config"))
	local registry = GetContextRegistryService()

	-- Clear previous workspace content
	ClearWorkspaceObjects()
	ClearLightingEffects()

	-- Get animation data if available
	local animationData = nil
	if locationConfig.getAnimationData then
		animationData = locationConfig.getAnimationData()
	end

	-- Copy Location workspace objects
	local workspaceFolder = locationFolder:FindFirstChild("Workspace")
	if workspaceFolder then
		CopyModelsToWorkspace(workspaceFolder, animationData, player, registry.RegisterLocationObject)

		-- Copy Lighting
		local lightingFolder = workspaceFolder:FindFirstChild("Lighting")
		if lightingFolder then
			CopyLightingObjects(lightingFolder, player, registry.RegisterLocationLighting)
		end
	end

	-- Copy Location scripts
	local locationReplicatedStorage = locationFolder:FindFirstChild("ReplicatedStorage")
	local locationServerScriptService = locationFolder:FindFirstChild("ServerScriptService")

	CopyScriptsToReplicatedStorage(locationReplicatedStorage, player, registry.RegisterLocationScript)
	CopyScriptsToServerScriptService(locationServerScriptService, player, registry.RegisterLocationScript, "location")

	-- Apply Location settings
	local settings = locationConfig.getSettings and locationConfig.getSettings()
	if settings and settings.gravity then
		Workspace.Gravity = math.abs(settings.gravity.Y)
	end

	-- Track current location
	currentLocations[player] = {
		planetId = planetId,
		locationName = locationId,
		config = locationConfig,
		planetConfig = require(planetFolder:WaitForChild("Config"))
	}

	contexts.location = true
	return true
end

function LocationService.FiniLocation(player)
	local contexts = activeContexts[player]
	if not contexts or not contexts.location then
		return
	end

	-- Call levelFini on location modules before destroying
	FiniModules(player, "location")

	-- Clear location registry
	local registry = GetContextRegistryService()
	registry.ClearLocationRegistry(player)

	-- Clear workspace
	ClearWorkspaceObjects()
	ClearLightingEffects()

	contexts.location = false
end

-- ============================================================================
-- PUBLIC API — LEGACY COMPATIBILITY
-- ============================================================================

function LocationService.Initialize()
	if isInitialized then
		return true
	end

	local planetsFolder = ServerStorage:FindFirstChild("Planets")
	if not planetsFolder then
		error(string.format("[%s %s] ServerStorage.Planets not found!", MODULE_NAME, VERSION))
	end

	-- Initialize ContextRegistryService
	GetContextRegistryService().Initialize()

	isInitialized = true
	print(string.format("[%s %s] ✓ LocationService ready", MODULE_NAME, VERSION))
	return true
end

function LocationService.LoadLocation(player, planetId, locationName)
	if not isInitialized then
		error(string.format("[%s %s][LoadLocation] Service not initialized!", MODULE_NAME, VERSION))
	end

	-- Use Init/Fini system
	if locationName == "Orbit" then
		return LocationService.InitOrbit(player, planetId)
	else
		return LocationService.InitLocation(player, planetId, locationName)
	end
end

function LocationService.UnloadLocation(player)
	local contexts = activeContexts[player]
	if not contexts then return end

	if contexts.location then
		LocationService.FiniLocation(player)
	elseif contexts.orbit then
		LocationService.FiniOrbit(player)
	end

	currentLocations[player] = nil
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
		end

		return true

	elseif foundSpawnType == "SpawnLocation" and spawnPoint then
		humanoidRootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 3, 0)
		return true

	else
		humanoidRootPart.CFrame = CFrame.new(0, 5, 0)
		return true
	end
end

-- ============================================================================
-- UTILITY
-- ============================================================================

function LocationService.GetActiveContexts(player)
	return activeContexts[player]
end

function LocationService.GetRegistrySummary(player)
	return GetContextRegistryService().GetRegistrySummary(player)
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

Players.PlayerRemoving:Connect(function(player)
	-- Full cleanup when player leaves
	local contexts = activeContexts[player]
	if contexts then
		if contexts.location then
			LocationService.FiniLocation(player)
		end
		if contexts.orbit then
			LocationService.FiniOrbit(player)
		end
		if contexts.planet then
			LocationService.FiniPlanet(player)
		end
	end

	activeContexts[player] = nil
	currentLocations[player] = nil
	initializedModules[player] = nil
end)

-- ============================================================================
-- RETURN
-- ============================================================================

return LocationService
