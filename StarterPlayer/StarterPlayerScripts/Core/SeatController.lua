--[[
================================================================================
KOSMICMAZER -- SeatController
================================================================================

Purpose:
Client-side seat detection and coordination.
Detects when player sits/stands, identifies seat type, coordinates UI and camera.

Version:
0.1

Features:
- Detects Humanoid.Seated events
- Identifies seat type from SeatConfig
- Coordinates with SeatUIManager for UI
- Notifies server of seat state changes

API:
- Initialize(seatUIManager) -- Start the controller
- GetCurrentSeat() -- Returns current seat name or nil
- GetCurrentSeatConfig() -- Returns config for current seat
- IsInSeat() -- Returns true if player is in a known seat

Calls to:
- ReplicatedStorage.Game.SeatConfig
- ReplicatedStorage.RemoteEvents
- SeatUIManager

Called from:
- ClientBootstrap

Events:
- Humanoid.Seated

Dependencies:
- SeatConfig
- SeatUIManager

ChangeLog:
- 0.1: Initial SeatController (2026-01-13)
================================================================================
]]

local SeatController = {}

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
local SeatConfig
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
		local seatConfig = SeatConfig.GetSeatConfig(seatName)

		if seatConfig then
			currentSeat = seat
			currentSeatName = seatName

			SeatOccupied:FireServer(seatName)

			if SeatUIManager then
				SeatUIManager.ShowSeatUI(seatName, seatConfig)
			end
		else
			currentSeat = seat
			currentSeatName = nil
		end
	else
		if currentSeatName then
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
	if not character then return end

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end

	humanoid.Seated:Connect(OnSeated)

	-- Check if already seated (e.g., spawned in seat)
	if humanoid.SeatPart then
		task.wait(0.2)
		OnSeated(true, humanoid.SeatPart)
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function SeatController.Initialize(seatUIManagerModule)
	if isInitialized then return true end

	local Game = ReplicatedStorage:WaitForChild("Game")
	SeatConfig = require(Game:WaitForChild("SeatConfig"))
	SeatUIManager = seatUIManagerModule

	local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	SeatOccupied = RemoteEvents:WaitForChild("SeatOccupied")
	SeatVacated = RemoteEvents:WaitForChild("SeatVacated")

	if LocalPlayer.Character then
		SetupCharacter(LocalPlayer.Character)
	end

	LocalPlayer.CharacterAdded:Connect(SetupCharacter)

	isInitialized = true
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
		return SeatConfig.GetSeatConfig(currentSeatName)
	end
	return nil
end

function SeatController.IsInSeat()
	return currentSeatName ~= nil
end

function SeatController.IsInKnownSeat()
	return currentSeatName ~= nil and SeatConfig.IsSeatKnown(currentSeatName)
end

-- ============================================================================
-- RETURN
-- ============================================================================

return SeatController
