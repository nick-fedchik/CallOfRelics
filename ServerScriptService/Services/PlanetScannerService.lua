--[[
================================================================================
KOSMICMAZER — PlanetScannerService
================================================================================

Purpose:
Server-side management of planet surface scanning.
Handles scan requests, progress, and location discovery.

Version:
0.3

Features:
- Process scan requests from clients
- Validate scanner context (must be on Orbit)
- Determine undiscovered locations
- Send progress updates to client
- Mark locations as discovered in ProfileService
- Cooldown between scans
- Wear-based accuracy (degrades with use)
- Scanner battery system (own power source)
- Power consumption per scan

API:
- Initialize() — Initialize service
- RequestScan(player) — Start scan for player
- GetScanCooldown(player) — Get remaining cooldown
- GetDiscoverableLocations(player, planetId) — Get locations that can be discovered
- GetScannerState(player) — Get scanner battery and wear state
- RepairScanner(player) — Repair scanner (restore accuracy)
- RechargeScanner(player, amount) — Recharge scanner battery

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
- ServerStorage/Planets
- SpaceShipConfig
- TransitionConfig

ChangeLog:
- 0.5: Scanner state persistence via ProfileService (battery, wear saved to profile) (2026-01-16)
- 0.4: Added location visibility support, new discovery formula (2026-01-16)
- 0.3: New scanner model: battery system, wear-based accuracy (2026-01-16)
- 0.2: Added accuracy-based discovery, energy consumption, use SpaceShipConfig (2026-01-16)
- 0.1: Initial PlanetScannerService (2026-01-16)
================================================================================
]]

local PlanetScannerService = {}

local VERSION = "0.5"
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
local TransitionConfig
local SpaceShipConfig

-- ============================================================================
-- STATE
-- ============================================================================

local isInitialized = false
local activeScans = {} -- [player] = {startTime, coroutine}
local lastScanTime = {} -- [player] = timestamp

-- Scanner state is now stored in ProfileService (shipState.modules.scanner)
-- No longer using local scannerState table

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

-- Get scanner state from ProfileService (persistent)
local function GetScannerState(player)
	return ProfileService.GetScannerState(player)
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
				visibility = 100, -- Default visibility (100% = always visible)
			}

			if configModule then
				local success, config = pcall(require, configModule)
				if success and config then
					locationData.displayName = config.displayName or config.name or locationFolder.Name
					locationData.biome = config.biome
					locationData.difficulty = config.difficulty
					locationData.visibility = config.visibility or 100
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

	local cooldown = SpaceShipConfig.GetScanCooldown()
	return (os.clock() - lastScan) < cooldown
end

local function GetCooldownRemaining(player)
	local lastScan = lastScanTime[player]
	if not lastScan then return 0 end

	local cooldown = SpaceShipConfig.GetScanCooldown()
	local remaining = cooldown - (os.clock() - lastScan)
	return math.max(0, remaining)
end

-- Calculate discovery success for a specific location
-- Uses the new formula: discoveryChance = effectiveAccuracy × (locationVisibility / 100)
-- Where effectiveAccuracy = wearAccuracy × chargeRatio
local function CalculateDiscoverySuccess(player, locationVisibility)
	local state = GetScannerState(player)
	if not state then return false end

	local scannerConfig = SpaceShipConfig.GetScannerConfig()

	-- First scan is guaranteed (ignores wear and visibility)
	if scannerConfig.guaranteedFirstScan and (state.scanCount or 0) == 0 then
		return true
	end

	-- Calculate discovery chance using the full formula
	local discoveryChance = SpaceShipConfig.CalculateDiscoveryChance(
		state.scanCount or 0,
		state.batteryCharge or 0,
		locationVisibility or 100
	)

	-- If discovery chance is 0, always fail
	if discoveryChance <= 0 then
		return false
	end

	return math.random() <= discoveryChance
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

	-- Get scanner state from profile
	local state = GetScannerState(player)
	if not state then
		return false, "Помилка профілю гравця"
	end

	local scannerConfig = SpaceShipConfig.GetScannerConfig()
	local powerConsumption = scannerConfig.powerConsumption

	-- Check battery charge
	local batteryCharge = state.batteryCharge or 0
	if batteryCharge < powerConsumption then
		return false, string.format("Недостатньо заряду батареї (%.0f/%.0f)",
			batteryCharge, powerConsumption)
	end

	-- Check scanner wear (accuracy)
	local currentAccuracy = SpaceShipConfig.CalculateScanAccuracy(state.scanCount or 0)
	if currentAccuracy <= 0 then
		return false, "Сканер зношений. Потребує ремонту."
	end

	-- Get planet and discoverable locations
	local planetId = GetCurrentPlanetId(player)
	local discoverable = GetDiscoverableLocations(player, planetId)

	if #discoverable == 0 then
		return false, "Всі локації вже відкриті"
	end

	-- Consume battery power (update in ProfileService)
	local newCharge = batteryCharge - powerConsumption
	ProfileService.UpdateScannerBattery(player, newCharge)

	-- Mark scan as active
	activeScans[player] = {
		startTime = os.clock(),
		planetId = planetId,
		discoverable = discoverable
	}

	-- Run scan in coroutine
	task.spawn(function()
		local scanDuration = scannerConfig.scanDuration
		local scanSteps = scannerConfig.scanSteps
		local stepDuration = scanDuration / scanSteps

		for step = 1, scanSteps do
			-- Check if player still exists and scan still active
			if not player.Parent or not activeScans[player] then
				break
			end

			local progress = step / scanSteps
			local message = string.format("Сканування... %d%%", progress * 100)

			-- Send progress to client
			if scanProgress then
				scanProgress:FireClient(player, progress, message)
			end

			task.wait(stepDuration)
		end

		-- Scan complete - check if discovery succeeds (visibility-based)
		if player.Parent and activeScans[player] then
			local scanData = activeScans[player]

			-- Try to discover each location based on its visibility
			-- NOTE: Wear is incremented AFTER discovery check so guaranteedFirstScan works
			-- Shuffle locations to randomize discovery order
			local shuffledLocations = {}
			for _, loc in ipairs(scanData.discoverable) do
				table.insert(shuffledLocations, loc)
			end
			for i = #shuffledLocations, 2, -1 do
				local j = math.random(1, i)
				shuffledLocations[i], shuffledLocations[j] = shuffledLocations[j], shuffledLocations[i]
			end

			-- Try to discover one location (first successful)
			local discovered = nil
			for _, location in ipairs(shuffledLocations) do
				if CalculateDiscoverySuccess(player, location.visibility) then
					discovered = location
					-- Mark as discovered in ProfileService
					ProfileService.MarkLocationDiscovered(player, scanData.planetId, discovered.id)
					break
				end
			end

			-- Increment scan count (wear) AFTER discovery check
			ProfileService.IncrementScannerWear(player)

			-- Update last scan time
			lastScanTime[player] = os.clock()

			-- Clear active scan
			activeScans[player] = nil

			-- Get updated scanner state from profile
			local updatedState = GetScannerState(player)
			local currentScanCount = updatedState and updatedState.scanCount or 0
			local currentBatteryCharge = updatedState and updatedState.batteryCharge or 0

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

			-- Calculate current accuracy for UI feedback
			local newAccuracy = SpaceShipConfig.CalculateScanAccuracy(currentScanCount)

			-- Send completion to client
			if scanComplete then
				local resultData = {
					discovered = discoveredList,
					batteryCharge = currentBatteryCharge,
					batteryMax = scannerConfig.battery.maxCapacity,
					accuracy = newAccuracy,
					scanCount = currentScanCount,
				}

				if discovered then
					scanComplete:FireClient(player, true, resultData,
						string.format("Знайдено: %s", discovered.displayName))
				else
					scanComplete:FireClient(player, false, resultData,
						"Нічого не знайдено (точність: " .. math.floor(newAccuracy * 100) .. "%)")
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

	local Game = ReplicatedStorage:WaitForChild("Game")
	TransitionConfig = require(Game:WaitForChild("TransitionConfig"))
	SpaceShipConfig = require(Game:WaitForChild("SpaceShipConfig"))

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
		-- Scanner state is now in ProfileService, no local cleanup needed
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
			local state = GetScannerState(player)
			local scannerConfig = SpaceShipConfig.GetScannerConfig()
			local scanCount = state and state.scanCount or 0
			local batteryCharge = state and state.batteryCharge or 0
			local resultData = {
				batteryCharge = batteryCharge,
				batteryMax = scannerConfig.battery.maxCapacity,
				accuracy = SpaceShipConfig.CalculateScanAccuracy(scanCount),
				scanCount = scanCount,
			}
			scanComplete:FireClient(player, false, resultData, message)
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

-- Get scanner state (battery, wear) from ProfileService
function PlanetScannerService.GetScannerState(player)
	local state = GetScannerState(player)
	if not state then return nil end

	local scannerConfig = SpaceShipConfig.GetScannerConfig()
	local scanCount = state.scanCount or 0
	local batteryCharge = state.batteryCharge or 0

	return {
		batteryCharge = batteryCharge,
		batteryMax = scannerConfig.battery.maxCapacity,
		accuracy = SpaceShipConfig.CalculateScanAccuracy(scanCount),
		scanCount = scanCount,
		scansUntilWornOut = SpaceShipConfig.GetScansUntilWornOut() - scanCount,
	}
end

-- Repair scanner (restore accuracy by resetting scan count)
function PlanetScannerService.RepairScanner(player)
	local state = GetScannerState(player)
	if not state then return false, "Помилка профілю гравця" end

	-- Check if repair is needed
	if (state.scanCount or 0) == 0 then
		return false, "Сканер не потребує ремонту"
	end

	-- TODO: Check if player has enough resources/energy for repair
	-- Reset scan count via ProfileService
	local success = ProfileService.RepairScanner(player)
	if success then
		return true, "Сканер відремонтовано. Точність: 100%"
	else
		return false, "Помилка ремонту"
	end
end

-- Recharge scanner battery
function PlanetScannerService.RechargeScanner(player, amount)
	local batteryConfig = SpaceShipConfig.GetScannerBatteryConfig()

	local success, actualCharge = ProfileService.RechargeScannerBattery(player, amount, batteryConfig.maxCapacity)
	if not success then
		return false, "Помилка підзарядки"
	end

	local state = GetScannerState(player)
	local newCharge = state and state.batteryCharge or 0

	return true, string.format("Заряджено: +%.0f (%.0f/%.0f)",
		actualCharge, newCharge, batteryConfig.maxCapacity)
end

-- ============================================================================
-- RETURN
-- ============================================================================

return PlanetScannerService
