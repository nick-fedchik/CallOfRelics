--[[
================================================================================
KOSMICMAZER — StatusBarUI
================================================================================

Purpose:
Top status bar UI for InGame state (like Windows 95 taskbar).
Shows current planet, location, and Exit button.

Version:
0.3

Layout:
┌──────────────────────────────────────────────────────────────────────────┐
│                    [Планета: Planet_1] [Локація: Космічний Корабель] [Вихід] │
└──────────────────────────────────────────────────────────────────────────┘

Features:
- Planet name (right side, before location)
- Location name (right side, before exit button)
- Exit button (right side, furthest right)
- Always created, shown/hidden by state

State Management:
- LoggedOff: Hidden
- Initializing: Hidden
- InGame: Visible

Called from:
- ClientBootstrap (Initialize)
- UIManager (Show/Hide based on state)

Events:
- LogOffRequest (Client → Server): Player clicked "Вихід"

ChangeLog:
- 0.2: Exit button moved to right side (away from Roblox UI) (2026-01-11)
- 0.1: Initial status bar (2026-01-11)
================================================================================
]]

local StatusBarUI = {}

local VERSION = "0.2"
local MODULE_NAME = "StatusBarUI"

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- STATE
-- ============================================================================

local screenGui = nil
local isVisible = false

-- UI Elements (references for future updates)
local planetLabel = nil
local locationLabel = nil

-- ============================================================================
-- UI CREATION
-- ============================================================================

local function CreateStatusBarUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "StatusBarUI"
	gui.DisplayOrder = 50
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- Main status bar container (top of screen)
	local bar = Instance.new("Frame")
	bar.Name = "StatusBar"
	bar.Size = UDim2.new(1, 0, 0, 50)
	bar.Position = UDim2.new(0, 0, 0, 0)
	bar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	bar.BorderSizePixel = 0
	bar.ZIndex = 10
	bar.Parent = gui

	-- Bottom border line
	local borderLine = Instance.new("Frame")
	borderLine.Name = "BorderLine"
	borderLine.Size = UDim2.new(1, 0, 0, 1)
	borderLine.Position = UDim2.new(0, 0, 1, -1)
	borderLine.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
	borderLine.BorderSizePixel = 0
	borderLine.ZIndex = 11
	borderLine.Parent = bar

	-- Exit button (right side, after location)
	local exit = Instance.new("TextButton")
	exit.Name = "ExitButton"
	exit.Size = UDim2.new(0, 100, 0, 35)
	exit.Position = UDim2.new(1, -10, 0.5, 0)
	exit.AnchorPoint = Vector2.new(1, 0.5)
	exit.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	exit.BorderSizePixel = 0
	exit.Text = "Вихід"
	exit.TextColor3 = Color3.fromRGB(255, 255, 255)
	exit.TextSize = 18
	exit.Font = Enum.Font.GothamBold
	exit.AutoButtonColor = false
	exit.ZIndex = 11
	exit.Parent = bar

	-- Rounded corners for button
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = exit

	-- Planet label (right side, before location)
	local planet = Instance.new("TextLabel")
	planet.Name = "PlanetLabel"
	planet.Size = UDim2.new(0, 200, 0, 35)
	planet.Position = UDim2.new(1, -550, 0.5, 0)
	planet.AnchorPoint = Vector2.new(1, 0.5)
	planet.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	planet.BorderSizePixel = 0
	planet.Text = "Планета: Planet_1"
	planet.TextColor3 = Color3.fromRGB(200, 200, 220)
	planet.TextSize = 16
	planet.Font = Enum.Font.Gotham
	planet.TextXAlignment = Enum.TextXAlignment.Center
	planet.ZIndex = 11
	planet.Parent = bar

	local cornerPlanet = Instance.new("UICorner")
	cornerPlanet.CornerRadius = UDim.new(0, 4)
	cornerPlanet.Parent = planet

	-- Location label (right side, before exit button)
	local location = Instance.new("TextLabel")
	location.Name = "LocationLabel"
	location.Size = UDim2.new(0, 220, 0, 35)
	location.Position = UDim2.new(1, -340, 0.5, 0)
	location.AnchorPoint = Vector2.new(1, 0.5)
	location.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	location.BorderSizePixel = 0
	location.Text = "Локація: Космічний Корабель"
	location.TextColor3 = Color3.fromRGB(200, 200, 220)
	location.TextSize = 16
	location.Font = Enum.Font.Gotham
	location.TextXAlignment = Enum.TextXAlignment.Center
	location.ZIndex = 11
	location.Parent = bar

	local cornerLocation = Instance.new("UICorner")
	cornerLocation.CornerRadius = UDim.new(0, 4)
	cornerLocation.Parent = location

	-- Hover effect for exit button
	exit.MouseEnter:Connect(function()
		TweenService:Create(
			exit,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(180, 60, 60)}
		):Play()
	end)

	exit.MouseLeave:Connect(function()
		TweenService:Create(
			exit,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(150, 50, 50)}
		):Play()
	end)

	-- Click handler for exit button
	exit.MouseButton1Click:Connect(function()
		print(string.format("[%s %s][ExitButton] Player clicked 'Вихід'", MODULE_NAME, VERSION))

		-- Send LogOff request to server
		local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
		local logOffRequest = remoteEvents:WaitForChild("LogOffRequest")
		logOffRequest:FireServer()

		print(string.format("[%s %s][ExitButton] LogOff request sent to server", MODULE_NAME, VERSION))
	end)

	return gui, bar, exit, planet, location
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function StatusBarUI.Initialize()
	print(string.format("[%s %s][Initialize] Creating StatusBar UI", MODULE_NAME, VERSION))

	local bar, exit, planet, location
	screenGui, bar, exit, planet, location = CreateStatusBarUI()
	screenGui.Parent = playerGui

	-- Store references for SetPlanet/SetLocation
	planetLabel = planet
	locationLabel = location

	print(string.format("[%s %s][Initialize] StatusBar UI ready", MODULE_NAME, VERSION))
	return true
end

function StatusBarUI.Show()
	if not screenGui then
		warn(string.format("[%s %s][Show] StatusBar not initialized!", MODULE_NAME, VERSION))
		return
	end

	screenGui.Enabled = true
	isVisible = true

	print(string.format("[%s %s][Show] StatusBar visible", MODULE_NAME, VERSION))
end

function StatusBarUI.Hide()
	if not screenGui then return end

	screenGui.Enabled = false
	isVisible = false

	print(string.format("[%s %s][Hide] StatusBar hidden", MODULE_NAME, VERSION))
end

function StatusBarUI.SetPlanet(planetName)
	if planetLabel then
		planetLabel.Text = string.format("Планета: %s", planetName)
	end
end

function StatusBarUI.SetLocation(locationName)
	if locationLabel then
		locationLabel.Text = string.format("Локація: %s", locationName)
	end
end

function StatusBarUI.IsVisible()
	return isVisible
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

return StatusBarUI
