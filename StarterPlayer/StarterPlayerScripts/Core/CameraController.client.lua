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

local VERSION = "0.1"
local MODULE_NAME = "CameraController"

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- ============================================================================
-- STATE
-- ============================================================================

local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local currentSeat = nil
local cameraConnection = nil

-- ============================================================================
-- CAMERA SETUP
-- ============================================================================

local function SetupVehicleCamera(seat)
	print(string.format("[%s %s] Setting up vehicle camera for seat: %s", MODULE_NAME, VERSION, seat.Name))

	-- Ensure camera is in Custom mode for full control
	camera.CameraType = Enum.CameraType.Custom

	-- Set camera subject to player's humanoid (standard behavior)
	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
			print(string.format("[%s %s] Camera subject set to humanoid", MODULE_NAME, VERSION))
		end
	end
end

local function ResetCamera()
	print(string.format("[%s %s] Resetting camera to default", MODULE_NAME, VERSION))

	camera.CameraType = Enum.CameraType.Custom

	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end

	currentSeat = nil
end

-- ============================================================================
-- SEAT DETECTION
-- ============================================================================

local function OnSeated(isSeated, seat)
	print(string.format("[%s %s] Seated event: isSeated=%s, seat=%s",
		MODULE_NAME, VERSION, tostring(isSeated), seat and seat.Name or "nil"))

	if isSeated and seat then
		currentSeat = seat

		-- Small delay to ensure everything is loaded
		task.wait(0.1)

		if seat:IsA("VehicleSeat") then
			SetupVehicleCamera(seat)
		end
	else
		ResetCamera()
	end
end

local function SetupCharacter(character)
	if not character then return end

	print(string.format("[%s %s] Setting up character: %s", MODULE_NAME, VERSION, character.Name))

	local humanoid = character:WaitForChild("Humanoid", 10)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)

	if humanoid then
		-- Listen for seat changes
		humanoid.Seated:Connect(OnSeated)

		-- Check if already seated
		if humanoid.SeatPart then
			OnSeated(true, humanoid.SeatPart)
		end

		-- DEBUG: Log when humanoid dies
		humanoid.Died:Connect(function()
			local pos = hrp and hrp.Position or Vector3.new(0,0,0)
			print(string.format("[%s %s] DEBUG: Humanoid DIED! Last position: %.1f, %.1f, %.1f",
				MODULE_NAME, VERSION, pos.X, pos.Y, pos.Z))
		end)

		-- DEBUG: Log humanoid state changes
		humanoid.StateChanged:Connect(function(oldState, newState)
			local pos = hrp and hrp.Position or Vector3.new(0,0,0)
			print(string.format("[%s %s] DEBUG: State %s → %s at position: %.1f, %.1f, %.1f",
				MODULE_NAME, VERSION, oldState.Name, newState.Name, pos.X, pos.Y, pos.Z))
		end)

		print(string.format("[%s %s] Character setup complete", MODULE_NAME, VERSION))
	end

	-- DEBUG: Log position every 2 seconds when walking
	if hrp then
		task.spawn(function()
			while character and character.Parent do
				if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Seated then
					local pos = hrp.Position
					print(string.format("[%s %s] DEBUG: Position: %.1f, %.1f, %.1f",
						MODULE_NAME, VERSION, pos.X, pos.Y, pos.Z))
				end
				task.wait(2)
			end
		end)
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function Initialize()
	print(string.format("[%s %s] Initializing CameraController...", MODULE_NAME, VERSION))

	-- Setup current character if exists
	if LocalPlayer.Character then
		SetupCharacter(LocalPlayer.Character)
	end

	-- Setup future characters
	LocalPlayer.CharacterAdded:Connect(SetupCharacter)

	print(string.format("[%s %s] CameraController ready", MODULE_NAME, VERSION))
end

-- Run initialization
Initialize()
