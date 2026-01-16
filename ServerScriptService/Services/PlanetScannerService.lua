--[[
================================================================================
KOSMICMAZER — PlanetScannerService
================================================================================

Purpose:
Server-side management of planet surface scanning.
Handles scan requests, progress, and location discovery.

Version:
0.1

Features:
- Process scan requests from clients
- Validate scanner context (must be on Orbit)
- Determine undiscovered locations
- Send progress updates to client
- Mark locations as discovered in ProfileService
- Cooldown between scans

API:
- Initialize() — Initialize service
- RequestScan(player) — Start scan for player
- GetScanCooldown(player) — Get remaining cooldown
- GetDiscoverableLocations(player, planetId) — Get locations that can be discovered

Calls to:
- ProfileService
- LocationService
- ReplicatedStorage.RemoteEvents

Called from:
- ServerBootstrap (initialization)
- Client via RequestScan RemoteEvent

Events:
- Listens: RequestScan (Client → Server)
- Fires: ScanProgress (Server → Client)
- Fires: ScanComplete (Server → Client)

Dependencies:
- ProfileService
- LocationService
- ServerStorage/Planets

ChangeLog:
- 0.1: Initial PlanetScannerService (2026-01-16)
================================================================================
]]

local PlanetScannerService = {}

local VERSION = "0.1"
local MODULE_NAME = "PlanetScannerService"

-- ============================================================================
-- SERVICES
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- ============================================================================
-- MODULES
-- ============================================================================

local ProfileService
local LocationService
local TransitionConfig

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local SCAN_DURATION = 5.0 -- seconds
local SCAN_COOLDOWN = 10.0 -- seconds between scans
local SCAN_STEPS = 10 -- number of progress updates

-- ============================================================================
-- STATE
-- ============================================================================

local isInitialized = false
local activeScans = {} -- [player] = {startTime, coroutine}
local lastScanTime = {} -- [player] = timestamp

-- RemoteEvents
local remoteEvents = nil
local requestScan = nil
local scanProgress = nil
local scanComplete = nil

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

local function GetPlanetsFolder()
	return ServerStorage:FindFirstChild("Planets")
end

local function GetAllLocationsForPlanet(planetId)
	local planetsFolder = GetPlanetsFolder()
	if not planetsFolder then return {} end

	local planetFolder = planetsFolder:FindFirstChild(planetId)
	if not planetFolder then return {} end

	local surfaceFolder = planetFolder:FindFirstChild("Surface")
	if not surfaceFolder then return {} end

	local locations = {}
	for _, locationFolder in ipairs(surfaceFolder:GetChildren()) do
		if locationFolder:IsA("Folder") then
			local configModule = locationFolder:FindFirstChild("Config")
			local locationData = {
				id = locationFolder.Name,
				name = locationFolder.Name,
				displayName = locationFolder.Name,
			}

			if configModule then
				local success, config = pcall(require, configModule)
				if success and config then
					locationData.displayName = config.displayName or config.name or locationFolder.Name
					locationData.biome = config.biome
					locationData.difficulty = config.difficulty
				end
			end

			table.insert(locations, locationData)
		end
	end

	return locations
end

local function GetDiscoverableLocations(player, planetId)
	local profile = ProfileService.GetProfile(player)
	if not profile then return {} end

	local allLocations = GetAllLocationsForPlanet(planetId)
	local exploredLocations = profile.exploredLocations[planetId] or {}

	local discoverable = {}
	for _, location in ipairs(allLocations) do
		if not exploredLocations[location.id] then
			table.insert(discoverable, location)
		end
	end

	return discoverable
end

local function GetCurrentPlanetId(player)
	local profile = ProfileService.GetProfile(player)
	if profile and profile.currentPlanet then
		return profile.currentPlanet
	end
	return "Planet_1" -- Default
end

local function GetCurrentContext(player)
	local profile = ProfileService.GetProfile(player)
	if profile and profile.currentLocation then
		if profile.currentLocation == "Orbit" then
			return TransitionConfig.Contexts.Orbit
		else
			return TransitionConfig.Contexts.Surface
		end
	end
	return TransitionConfig.Contexts.Orbit
end

local function IsOnCooldown(player)
	local lastScan = lastScanTime[player]
	if not lastScan then return false end

	return (os.clock() - lastScan) < SCAN_COOLDOWN
end

local function GetCooldownRemaining(player)
	local lastScan = lastScanTime[player]
	if not lastScan then return 0 end

	local remaining = SCAN_COOLDOWN - (os.clock() - lastScan)
	return math.max(0, remaining)
end

local function PerformScan(player)
	-- Check if already scanning
	if activeScans[player] then
		return false, "Сканування вже виконується"
	end

	-- Check cooldown
	if IsOnCooldown(player) then
		local remaining = GetCooldownRemaining(player)
		return false, string.format("Зачекайте %.0f сек.", remaining)
	end

	-- Check context (must be on Orbit)
	local context = GetCurrentContext(player)
	if context ~= TransitionConfig.Contexts.Orbit then
		return false, "Сканер доступний лише з орбіти"
	end

	-- Get planet and discoverable locations
	local planetId = GetCurrentPlanetId(player)
	local discoverable = GetDiscoverableLocations(player, planetId)

	if #discoverable == 0 then
		return false, "Всі локації вже відкриті"
	end

	-- Mark scan as active
	activeScans[player] = {
		startTime = os.clock(),
		planetId = planetId,
		discoverable = discoverable
	}

	-- Run scan in coroutine
	task.spawn(function()
		local stepDuration = SCAN_DURATION / SCAN_STEPS

		for step = 1, SCAN_STEPS do
			-- Check if player still exists and scan still active
			if not player.Parent or not activeScans[player] then
				break
			end

			local progress = step / SCAN_STEPS
			local message = string.format("Сканування... %d%%", progress * 100)

			-- Send progress to client
			if scanProgress then
				scanProgress:FireClient(player, progress, message)
			end

			task.wait(stepDuration)
		end

		-- Scan complete - discover a random location
		if player.Parent and activeScans[player] then
			local scanData = activeScans[player]

			-- Pick random location to discover
			local discovered = nil
			if #scanData.discoverable > 0 then
				local randomIndex = math.random(1, #scanData.discoverable)
				discovered = scanData.discoverable[randomIndex]

				-- Mark as discovered in ProfileService
				ProfileService.MarkLocationDiscovered(player, scanData.planetId, discovered.id)
			end

			-- Update last scan time
			lastScanTime[player] = os.clock()

			-- Clear active scan
			activeScans[player] = nil

			-- Get updated list of discovered locations
			local profile = ProfileService.GetProfile(player)
			local exploredLocations = profile and profile.exploredLocations[scanData.planetId] or {}

			local discoveredList = {}
			for locationId, locationData in pairs(exploredLocations) do
				local allLocations = GetAllLocationsForPlanet(scanData.planetId)
				for _, loc in ipairs(allLocations) do
					if loc.id == locationId then
						table.insert(discoveredList, {
							id = locationId,
							displayName = loc.displayName,
							discoveredAt = locationData.discoveredAt,
						})
						break
					end
				end
			end

			-- Send completion to client
			if scanComplete then
				if discovered then
					scanComplete:FireClient(player, true, discoveredList,
						string.format("Знайдено: %s", discovered.displayName))
				else
					scanComplete:FireClient(player, false, discoveredList, "Нічого не знайдено")
				end
			end
		end
	end)

	return true, "Сканування розпочато"
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function PlanetScannerService.Initialize()
	if isInitialized then return true end

	-- Load modules
	local servicesFolder = script.Parent
	ProfileService = require(servicesFolder:WaitForChild("ProfileService"))
	LocationService = require(servicesFolder:WaitForChild("LocationService"))

	local Game = ReplicatedStorage:WaitForChild("Game")
	TransitionConfig = require(Game:WaitForChild("TransitionConfig"))

	-- Setup RemoteEvents
	remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if remoteEvents then
		requestScan = remoteEvents:FindFirstChild("RequestScan")
		scanProgress = remoteEvents:FindFirstChild("ScanProgress")
		scanComplete = remoteEvents:FindFirstChild("ScanComplete")

		if requestScan then
			requestScan.OnServerEvent:Connect(function(player)
				PlanetScannerService.RequestScan(player)
			end)
		end
	end

	-- Cleanup on player leaving
	Players.PlayerRemoving:Connect(function(player)
		activeScans[player] = nil
		lastScanTime[player] = nil
	end)

	isInitialized = true
	print(string.format("[%s %s] ✓ PlanetScannerService ready", MODULE_NAME, VERSION))
	return true
end

function PlanetScannerService.RequestScan(player)
	local success, message = PerformScan(player)

	if not success then
		-- Send failure to client
		if scanComplete then
			scanComplete:FireClient(player, false, nil, message)
		end
	end

	return success, message
end

function PlanetScannerService.GetScanCooldown(player)
	return GetCooldownRemaining(player)
end

function PlanetScannerService.GetDiscoverableLocations(player, planetId)
	return GetDiscoverableLocations(player, planetId)
end

function PlanetScannerService.IsScanning(player)
	return activeScans[player] ~= nil
end

function PlanetScannerService.CancelScan(player)
	if activeScans[player] then
		activeScans[player] = nil
		return true
	end
	return false
end

-- ============================================================================
-- RETURN
-- ============================================================================

return PlanetScannerService
