--[[
================================================================================
KOSMICMAZER — CameraController
================================================================================

Purpose:
Manages camera behavior for player, especially when seated in vehicles.
Ensures camera follows player character when in PilotSeat.

Version:
0.1

Features:
- Follow camera when player is seated in VehicleSeat
- Smooth camera transitions
- Listen for humanoid seat changes

API:
- None (auto-executes on client)

Calls to:
- Workspace.CurrentCamera
- LocalPlayer.Character

Called from:
- Roblox Client (auto-run)

Events:
- Humanoid.Seated

Dependencies:
- None

ChangeLog:
- 0.1: Initial camera controller for vehicle seats (2026-01-13)
================================================================================
]]

-- ============================================================================
-- PREVENT DOUBLE EXECUTION
-- ============================================================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer

if player:GetAttribute("CameraControllerInitialized") then
	return
end
player:SetAttribute("CameraControllerInitialized", true)

-- ============================================================================
-- SERVICES
-- ============================================================================

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================================
-- MODULES
-- ============================================================================

local SeatConfig

-- ============================================================================
-- STATE
-- ============================================================================

local LocalPlayer = player
local camera = Workspace.CurrentCamera

-- ============================================================================
-- CAMERA SETUP
-- ============================================================================

local function SetupVehicleCamera(seat)
	-- Get camera settings from SeatConfig
	local cameraSettings = nil
	if SeatConfig then
		cameraSettings = SeatConfig.GetCameraSettings(seat.Name)
	end

	-- Ensure camera is in Custom mode for full control
	camera.CameraType = Enum.CameraType.Custom

	-- Apply FOV from config if available
	if cameraSettings and cameraSettings.fov then
		camera.FieldOfView = cameraSettings.fov
	end

	-- Set camera subject to player's humanoid (standard behavior)
	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

local function ResetCamera()
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70 -- Default FOV

	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

-- ============================================================================
-- SEAT DETECTION
-- ============================================================================

local function OnSeated(isSeated, seat)
	if isSeated and seat then
		-- Small delay to ensure everything is loaded
		task.wait(0.1)

		-- Setup camera for any seat type (VehicleSeat or regular Seat)
		if seat:IsA("VehicleSeat") or seat:IsA("Seat") then
			SetupVehicleCamera(seat)
		end
	else
		ResetCamera()
	end
end

local function SetupCharacter(character)
	if not character then return end

	local humanoid = character:WaitForChild("Humanoid", 10)

	if humanoid then
		-- Listen for seat changes
		humanoid.Seated:Connect(OnSeated)

		-- Check if already seated
		if humanoid.SeatPart then
			OnSeated(true, humanoid.SeatPart)
		end
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function Initialize()
	-- Load SeatConfig
	local Game = ReplicatedStorage:WaitForChild("Game", 5)
	if Game then
		local seatConfigModule = Game:FindFirstChild("SeatConfig")
		if seatConfigModule then
			SeatConfig = require(seatConfigModule)
		end
	end

	-- Setup current character if exists
	if LocalPlayer.Character then
		SetupCharacter(LocalPlayer.Character)
	end

	-- Setup future characters
	LocalPlayer.CharacterAdded:Connect(SetupCharacter)
end

-- Run initialization
Initialize()
