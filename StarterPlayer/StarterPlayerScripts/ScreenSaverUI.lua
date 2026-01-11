--[[
================================================================================
KOSMICMAZER — ScreenSaverUI
================================================================================

Purpose:
Manages the ScreenSaver UI state (LoggedOff global state).
Implements ScreenSaver UI from TDD Section 7.2.

Version:
0.1

Features:
- Displays visual screensaver
- Shows "Press to Enter" prompt
- Handles player input to initiate LogOn
- Hides when player enters game

API:
- Show() — Display the ScreenSaver
- Hide() — Hide the ScreenSaver
- IsVisible() — Check visibility state

Calls to:
- RemoteEvents (LogOnRequest)

Called from:
- ClientBootstrap
- UIManager

Events:
- None

Dependencies:
- ReplicatedStorage.RemoteEvents

ChangeLog:
- 0.1: Initial ScreenSaver implementation (2026-01-11)
================================================================================
]]

local ScreenSaverUI = {}

local VERSION = "0.1"
local MODULE_NAME = "ScreenSaverUI"

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- STATE
-- ============================================================================

local screenGui = nil
local isVisible = false
local canInteract = true

-- ============================================================================
-- UI CREATION
-- ============================================================================

local function CreateScreenSaverUI()
	-- Create ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "ScreenSaverUI"
	gui.DisplayOrder = 100
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- Background Frame (full screen, dark)
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	background.BorderSizePixel = 0
	background.Parent = gui

	-- Title Label
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0, 600, 0, 100)
	title.Position = UDim2.new(0.5, 0, 0.35, 0)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.BackgroundTransparency = 1
	title.Text = "CALL OF RELICS"
	title.TextColor3 = Color3.fromRGB(200, 200, 220)
	title.TextSize = 48
	title.Font = Enum.Font.GothamBold
	title.Parent = background

	-- Subtitle Label
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(0, 400, 0, 40)
	subtitle.Position = UDim2.new(0.5, 0, 0.45, 0)
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Orbital Silence"
	subtitle.TextColor3 = Color3.fromRGB(150, 150, 170)
	subtitle.TextSize = 24
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = background

	-- Prompt Label (pulsing)
	local prompt = Instance.new("TextLabel")
	prompt.Name = "Prompt"
	prompt.Size = UDim2.new(0, 400, 0, 50)
	prompt.Position = UDim2.new(0.5, 0, 0.65, 0)
	prompt.AnchorPoint = Vector2.new(0.5, 0.5)
	prompt.BackgroundTransparency = 1
	prompt.Text = "Press SPACE or Click to Enter"
	prompt.TextColor3 = Color3.fromRGB(255, 255, 255)
	prompt.TextSize = 20
	prompt.Font = Enum.Font.GothamMedium
	prompt.TextTransparency = 0.3
	prompt.Parent = background

	-- Pulsing animation for prompt
	local tweenInfo = TweenInfo.new(
		1.5,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1,
		true
	)
	local tween = TweenService:Create(prompt, tweenInfo, {TextTransparency = 0.8})
	tween:Play()

	-- Version Label
	local versionLabel = Instance.new("TextLabel")
	versionLabel.Name = "Version"
	versionLabel.Size = UDim2.new(0, 200, 0, 30)
	versionLabel.Position = UDim2.new(1, -10, 1, -10)
	versionLabel.AnchorPoint = Vector2.new(1, 1)
	versionLabel.BackgroundTransparency = 1
	versionLabel.Text = "v0.1 - EPIC 1"
	versionLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
	versionLabel.TextSize = 14
	versionLabel.Font = Enum.Font.Gotham
	versionLabel.TextXAlignment = Enum.TextXAlignment.Right
	versionLabel.Parent = background

	return gui
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

local function OnInputBegan(input, gameProcessed)
	if gameProcessed then return end
	if not isVisible then return end
	if not canInteract then return end

	-- Accept Space key or Mouse click
	if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
		ScreenSaverUI.RequestLogOn()
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function ScreenSaverUI.Initialize()
	print(string.format("[%s %s][Initialize] Creating ScreenSaver UI", MODULE_NAME, VERSION))

	screenGui = CreateScreenSaverUI()
	screenGui.Parent = playerGui

	-- Connect input handler
	UserInputService.InputBegan:Connect(OnInputBegan)

	print(string.format("[%s %s][Initialize] ScreenSaver UI ready", MODULE_NAME, VERSION))
	return true
end

function ScreenSaverUI.Show()
	if not screenGui then
		warn(string.format("[%s %s][Show] ScreenSaver not initialized!", MODULE_NAME, VERSION))
		return
	end

	screenGui.Enabled = true
	isVisible = true
	canInteract = true

	print(string.format("[%s %s][Show] ScreenSaver visible", MODULE_NAME, VERSION))
end

function ScreenSaverUI.Hide()
	if not screenGui then return end

	screenGui.Enabled = false
	isVisible = false
	canInteract = false

	print(string.format("[%s %s][Hide] ScreenSaver hidden", MODULE_NAME, VERSION))
end

function ScreenSaverUI.IsVisible()
	return isVisible
end

function ScreenSaverUI.RequestLogOn()
	print(string.format("[%s %s][RequestLogOn] Player requesting to enter game", MODULE_NAME, VERSION))

	canInteract = false -- Prevent double-clicks

	-- Wait for RemoteEvents to be created
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
	if not remoteEvents then
		warn(string.format("[%s %s][RequestLogOn] RemoteEvents folder not found!", MODULE_NAME, VERSION))
		canInteract = true
		return
	end

	local logOnEvent = remoteEvents:WaitForChild("LogOnRequest", 5)
	if not logOnEvent then
		warn(string.format("[%s %s][RequestLogOn] LogOnRequest event not found!", MODULE_NAME, VERSION))
		canInteract = true
		return
	end

	-- Send request to server
	logOnEvent:FireServer()
	print(string.format("[%s %s][RequestLogOn] LogOn request sent to server", MODULE_NAME, VERSION))
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

return ScreenSaverUI
