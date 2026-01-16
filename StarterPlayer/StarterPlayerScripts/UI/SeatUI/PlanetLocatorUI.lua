--[[
================================================================================
KOSMICMAZER — PlanetLocatorUI
================================================================================

Purpose:
Planet locator UI panel for "Seat Locator".
Allows player to discover and navigate to planets.

Version:
0.1

Features:
- Display known planets
- Scan for undiscovered planets
- Set navigation target

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
- 0.1: Initial PlanetLocatorUI stub (2026-01-16)
================================================================================
]]

local PlanetLocatorUI = {}

local VERSION = "0.1"
local MODULE_NAME = "PlanetLocatorUI"

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
	gui.Name = "PlanetLocatorUI"
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
	stroke.Color = Color3.fromRGB(180, 100, 255)
	stroke.Thickness = 2
	stroke.Parent = mainFrame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 50)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "ПЛАНЕТНИЙ ЛОКАТОР"
	titleLabel.TextColor3 = Color3.fromRGB(180, 100, 255)
	titleLabel.TextSize = 24
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = mainFrame

	-- Not Working message
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Size = UDim2.new(1, -40, 0, 100)
	messageLabel.Position = UDim2.new(0, 20, 0.5, -50)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = "NOT WORKING\n\nСистема планетного локатора\nв розробці"
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

function PlanetLocatorUI.Initialize()
	if isInitialized then return true end

	mainGui = CreateUI()

	isInitialized = true
	print(string.format("[%s %s] Initialized", MODULE_NAME, VERSION))
	return true
end

function PlanetLocatorUI.Show()
	if not isInitialized then
		PlanetLocatorUI.Initialize()
	end

	if mainGui then
		mainGui.Enabled = true
		isVisible = true
	end
end

function PlanetLocatorUI.Hide()
	if mainGui then
		mainGui.Enabled = false
		isVisible = false
	end
end

function PlanetLocatorUI.IsVisible()
	return isVisible
end

return PlanetLocatorUI
