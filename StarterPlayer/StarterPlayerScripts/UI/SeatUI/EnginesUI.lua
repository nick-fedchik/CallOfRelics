--[[
================================================================================
KOSMICMAZER — EnginesUI
================================================================================

Purpose:
Engine control UI panel for "Seat Engines".
Allows player to monitor and control ship engines.

Version:
0.1

Features:
- Display engine status
- Monitor fuel/energy levels
- Adjust engine power distribution

API:
- Initialize() — Create UI elements
- Show() — Display the UI
- Hide() — Hide the UI

Calls to:
- SpaceShipConfig (ReplicatedStorage/Game)

Called from:
- SeatUIManager.lua

Dependencies:
- TweenService
- SpaceShipConfig

ChangeLog:
- 0.1: Initial EnginesUI stub (2026-01-16)
================================================================================
]]

local EnginesUI = {}

local VERSION = "0.1"
local MODULE_NAME = "EnginesUI"

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================================
-- VARIABLES
-- ============================================================================

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local isInitialized = false
local isVisible = false
local mainGui = nil

-- ============================================================================
-- UI CREATION
-- ============================================================================

local function CreateUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "EnginesUI"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = PlayerGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 120, 180)
	stroke.Thickness = 2
	stroke.Parent = mainFrame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 50)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "КЕРУВАННЯ ДВИГУНАМИ"
	titleLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
	titleLabel.TextSize = 24
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = mainFrame

	-- Not Working message
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Size = UDim2.new(1, -40, 0, 100)
	messageLabel.Position = UDim2.new(0, 20, 0.5, -50)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = "NOT WORKING\n\nСистема керування двигунами\nв розробці"
	messageLabel.TextColor3 = Color3.fromRGB(255, 180, 100)
	messageLabel.TextSize = 18
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextWrapped = true
	messageLabel.Parent = mainFrame

	return gui
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function EnginesUI.Initialize()
	if isInitialized then return true end

	mainGui = CreateUI()

	isInitialized = true
	print(string.format("[%s %s] Initialized", MODULE_NAME, VERSION))
	return true
end

function EnginesUI.Show()
	if not isInitialized then
		EnginesUI.Initialize()
	end

	if mainGui then
		mainGui.Enabled = true
		isVisible = true
	end
end

function EnginesUI.Hide()
	if mainGui then
		mainGui.Enabled = false
		isVisible = false
	end
end

function EnginesUI.IsVisible()
	return isVisible
end

return EnginesUI
