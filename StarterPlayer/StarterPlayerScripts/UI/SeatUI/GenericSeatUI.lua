--[[
================================================================================
KOSMICMAZER -- GenericSeatUI
================================================================================

Purpose:
Generic UI panel for seats without specialized functionality.
Shows seat name and basic status.

Version:
0.1

Features:
- Displays seat name
- Basic status info
- Same layout as PilotUI

API:
- Initialize() -- Create UI elements
- Show(seatConfig) -- Display the UI
- Hide() -- Hide the UI

ChangeLog:
- 0.1: Initial GenericSeatUI (2026-01-13)
================================================================================
]]

local GenericSeatUI = {}

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================================
-- STATE
-- ============================================================================

local screenGui = nil
local isVisible = false
local isInitialized = false

-- UI Elements
local mainFrame = nil
local titleLabel = nil
local statusLabel = nil

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

local function CreateUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GenericSeatUI"
	gui.DisplayOrder = 60
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- Main panel (top-left corner)
	local frame = Instance.new("Frame")
	frame.Name = "SeatPanel"
	frame.Size = UDim2.new(0, 300, 0, 120)
	frame.Position = UDim2.new(0, 20, 0, 100)
	frame.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = gui
	mainFrame = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 100, 140)
	stroke.Thickness = 1
	stroke.Parent = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "КРІСЛО"
	title.TextColor3 = Color3.fromRGB(100, 180, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame
	titleLabel = title

	-- Status
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -20, 0, 60)
	status.Position = UDim2.new(0, 10, 0, 45)
	status.BackgroundTransparency = 1
	status.Text = "Корабель на орбіті\nСистеми в нормі"
	status.TextColor3 = Color3.fromRGB(180, 200, 220)
	status.TextSize = 14
	status.Font = Enum.Font.Gotham
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextYAlignment = Enum.TextYAlignment.Top
	status.Parent = frame
	statusLabel = status

	return gui
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function GenericSeatUI.Initialize()
	if isInitialized then return true end

	screenGui = CreateUI()
	screenGui.Parent = playerGui
	screenGui.Enabled = false

	isInitialized = true
	return true
end

function GenericSeatUI.Show(seatConfig)
	if not screenGui then return end

	-- Update title with display name
	if seatConfig and seatConfig.displayName then
		titleLabel.Text = string.upper(seatConfig.displayName)
	end

	screenGui.Enabled = true
	isVisible = true

	-- Animate in
	mainFrame.Position = UDim2.new(0, -300, 0, 100)
	TweenService:Create(
		mainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = UDim2.new(0, 20, 0, 100)}
	):Play()
end

function GenericSeatUI.Hide()
	if not screenGui then return end

	-- Animate out
	TweenService:Create(
		mainFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(0, -300, 0, 100)}
	):Play()

	task.delay(0.2, function()
		if screenGui then
			screenGui.Enabled = false
		end
	end)

	isVisible = false
end

function GenericSeatUI.IsVisible()
	return isVisible
end

-- ============================================================================
-- RETURN
-- ============================================================================

return GenericSeatUI
