--[[
================================================================================
KOSMICMAZER -- SeatController
================================================================================

Purpose:
Client-side seat detection and coordination.
Detects when player sits/stands, identifies seat type, coordinates UI and camera.

Version:
0.3

Features:
- Detects Humanoid.Seated events
- Identifies seat type from SpaceShipConfig
- Coordinates with SeatUIManager for UI
- Notifies server of seat state changes
- Logs seat events for debugging

API:
- Initialize(seatUIManager) -- Start the controller
- GetCurrentSeat() -- Returns current seat name or nil
- GetCurrentSeatConfig() -- Returns config for current seat
- IsInSeat() -- Returns true if player is in a known seat

Calls to:
- ReplicatedStorage.Game.SpaceShipConfig
- ReplicatedStorage.RemoteEvents
- SeatUIManager

Called from:
- ClientBootstrap

Events:
- Humanoid.Seated

Dependencies:
- SpaceShipConfig
- SeatUIManager

ChangeLog:
- 0.4: Add diagnostic logs for debugging seat detection (2026-01-16)
- 0.3: Fix API calls, add seat logging (2026-01-16)
- 0.2: Use SpaceShipConfig instead of SeatConfig (2026-01-16)
- 0.1: Initial SeatController (2026-01-13)
================================================================================
]]

local SeatController = {}

local VERSION = "0.4"
local MODULE_NAME = "SeatController"

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================================
-- STATE
-- ============================================================================

local LocalPlayer = Players.LocalPlayer
local currentSeat = nil
local currentSeatName = nil
local isInitialized = false

-- Modules (set during Initialize)
local SpaceShipConfig
local SeatUIManager

-- RemoteEvents
local SeatOccupied
local SeatVacated

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

local function OnSeated(isSeated, seat)
	if isSeated and seat then
		local seatName = seat.Name
		local seatConfig = SpaceShipConfig.GetSeatConfig(seatName)

		if seatConfig then
			currentSeat = seat
			currentSeatName = seatName

			print(string.format("[%s %s] Player sat in: %s (%s)",
				MODULE_NAME, VERSION, seatName, seatConfig.displayName or seatName))

			SeatOccupied:FireServer(seatName)

			if SeatUIManager then
				SeatUIManager.ShowSeatUI(seatName, seatConfig)
			end
		else
			currentSeat = seat
			currentSeatName = seatName
			print(string.format("[%s %s] Player sat in unknown seat: %s", MODULE_NAME, VERSION, seatName))
		end
	else
		if currentSeatName then
			print(string.format("[%s %s] Player left seat: %s", MODULE_NAME, VERSION, currentSeatName))

			SeatVacated:FireServer(currentSeatName)

			if SeatUIManager then
				SeatUIManager.HideSeatUI(currentSeatName)
			end
		end

		currentSeat = nil
		currentSeatName = nil
	end
end

local function SetupCharacter(character)
	if not character then
		print(string.format("[%s %s] SetupCharacter: character is nil!", MODULE_NAME, VERSION))
		return
	end

	print(string.format("[%s %s] SetupCharacter: waiting for Humanoid...", MODULE_NAME, VERSION))

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		print(string.format("[%s %s] SetupCharacter: Humanoid not found!", MODULE_NAME, VERSION))
		return
	end

	print(string.format("[%s %s] SetupCharacter: connecting Humanoid.Seated", MODULE_NAME, VERSION))
	humanoid.Seated:Connect(OnSeated)

	-- Check if already seated (e.g., spawned in seat)
	if humanoid.SeatPart then
		print(string.format("[%s %s] SetupCharacter: already seated in %s",
			MODULE_NAME, VERSION, humanoid.SeatPart.Name))
		task.wait(0.2)
		OnSeated(true, humanoid.SeatPart)
	else
		print(string.format("[%s %s] SetupCharacter: not seated, ready for seat detection",
			MODULE_NAME, VERSION))
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function SeatController.Initialize(seatUIManagerModule)
	if isInitialized then return true end

	local Game = ReplicatedStorage:WaitForChild("Game")
	SpaceShipConfig = require(Game:WaitForChild("SpaceShipConfig"))
	SeatUIManager = seatUIManagerModule

	local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	SeatOccupied = RemoteEvents:WaitForChild("SeatOccupied")
	SeatVacated = RemoteEvents:WaitForChild("SeatVacated")

	print(string.format("[%s %s] Initializing, Character exists: %s",
		MODULE_NAME, VERSION, tostring(LocalPlayer.Character ~= nil)))

	if LocalPlayer.Character then
		SetupCharacter(LocalPlayer.Character)
	end

	LocalPlayer.CharacterAdded:Connect(function(character)
		print(string.format("[%s %s] CharacterAdded fired", MODULE_NAME, VERSION))
		SetupCharacter(character)
	end)

	isInitialized = true
	print(string.format("[%s %s] ✓ Initialized", MODULE_NAME, VERSION))
	return true
end

function SeatController.GetCurrentSeat()
	return currentSeatName
end

function SeatController.GetCurrentSeatInstance()
	return currentSeat
end

function SeatController.GetCurrentSeatConfig()
	if currentSeatName then
		return SpaceShipConfig.GetSeatConfig(currentSeatName)
	end
	return nil
end

function SeatController.IsInSeat()
	return currentSeatName ~= nil
end

function SeatController.IsInKnownSeat()
	return currentSeatName ~= nil and SpaceShipConfig.IsSeatKnown(currentSeatName)
end

-- ============================================================================
-- RETURN
-- ============================================================================

return SeatController
