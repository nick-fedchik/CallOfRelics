--[[
================================================================================
KOSMICMAZER — TransitionUI
================================================================================

Purpose:
UI for location transitions. Handles departure animation, loading screen,
and landing sequence visualization.

Version:
0.4

Features:
- Departure animation (ship scale down, planet scale up, fade to black)
- Loading screen with message
- Landing camera sequence (POV from landing pad)
- Smooth transitions between states
- StatusBar integration for displayName updates

API:
- Initialize() — Create UI elements and setup event handlers
- ShowDepartureAnimation() — Start departure sequence
- ShowLoadingScreen(message) — Show loading with message
- ShowLandingCamera(data) — Setup landing camera with server data
- Hide(restoreCamera) — Hide all transition UI
- IsActive() — Check if transition is active

Calls to:
- TransitionConfig (ReplicatedStorage/Game)
- StatusBarUI (lazy-loaded, for displayName updates)

Called from:
- SeatUIManager (event handlers)
- TransitionUpdate RemoteEvent

Events:
- Listens: TransitionUpdate (Server → Client)
- Listens: TransitionLandingCamera (Server → Client)

Dependencies:
- TweenService
- TransitionConfig
- RemoteEvents (TransitionUpdate, TransitionLandingCamera)

ChangeLog:
- 0.4: Added StatusBarUI integration for displayName (2026-01-14)
- 0.3: Added ShowLandingCamera with server-provided data (2026-01-14)
- 0.2: Enhanced loading screen, camera restore (2026-01-14)
- 0.1: Initial TransitionUI (2026-01-14)
================================================================================
]]

local TransitionUI = {}

local VERSION = "0.4"
local MODULE_NAME = "TransitionUI"

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local TransitionConfig = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("TransitionConfig"))

-- Lazy-loaded StatusBarUI reference
local StatusBarUI = nil

local function GetStatusBarUI()
	if not StatusBarUI then
		local UI = script.Parent
		local statusBarModule = UI:FindFirstChild("StatusBarUI")
		if statusBarModule then
			StatusBarUI = require(statusBarModule)
		end
	end
	return StatusBarUI
end

-- ============================================================================
-- STATE
-- ============================================================================

local screenGui = nil
local isInitialized = false
local isActive = false

-- UI Elements
local fadeOverlay = nil
local loadingContainer = nil
local loadingText = nil

-- Camera state
local originalCameraType = nil
local originalCameraSubject = nil
local originalCameraFOV = nil

-- RemoteEvents
local remoteEvents = nil
local transitionUpdate = nil

-- Character sound muting connection
local characterAddedConnection = nil

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

local function MuteCharacterSounds(character)
	-- Mute all sounds in character immediately to prevent spawn sound
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Sound") then
			descendant.Volume = 0
			descendant:Stop()
		end
	end

	-- Also check HumanoidRootPart specifically
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		for _, child in ipairs(hrp:GetChildren()) do
			if child:IsA("Sound") then
				child.Volume = 0
				child:Stop()
			end
		end
	end
end

local function SetupCharacterSoundMuting()
	-- Disconnect existing connection if any
	if characterAddedConnection then
		characterAddedConnection:Disconnect()
		characterAddedConnection = nil
	end

	-- Setup listener to mute sounds when character spawns during transition
	characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(character)
		if isActive then
			-- Immediately mute all sounds
			MuteCharacterSounds(character)

			-- Also mute after a short delay (Roblox adds sounds with delay)
			task.delay(0.05, function()
				MuteCharacterSounds(character)
			end)
			task.delay(0.1, function()
				MuteCharacterSounds(character)
			end)

			print(string.format("[%s %s] Muted character sounds during transition", MODULE_NAME, VERSION))
		end
	end)
end

local function DisconnectCharacterSoundMuting()
	if characterAddedConnection then
		characterAddedConnection:Disconnect()
		characterAddedConnection = nil
	end
end

local function CreateUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "TransitionUI"
	gui.DisplayOrder = 100 -- On top of everything
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- Full screen fade overlay
	local fade = Instance.new("Frame")
	fade.Name = "FadeOverlay"
	fade.Size = UDim2.new(1, 0, 1, 0)
	fade.Position = UDim2.new(0, 0, 0, 0)
	fade.BackgroundColor3 = TransitionConfig.FadeColor
	fade.BackgroundTransparency = 1 -- Start invisible
	fade.BorderSizePixel = 0
	fade.ZIndex = 1
	fade.Parent = gui
	fadeOverlay = fade

	-- Loading container (centered)
	local loadingCont = Instance.new("Frame")
	loadingCont.Name = "LoadingContainer"
	loadingCont.Size = UDim2.new(0, 600, 0, 100)
	loadingCont.Position = UDim2.new(0.5, 0, 0.5, 0)
	loadingCont.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingCont.BackgroundTransparency = 1
	loadingCont.ZIndex = 2
	loadingCont.Visible = false
	loadingCont.Parent = gui
	loadingContainer = loadingCont

	-- Loading text
	local text = Instance.new("TextLabel")
	text.Name = "LoadingText"
	text.Size = UDim2.new(1, 0, 1, 0)
	text.Position = UDim2.new(0, 0, 0, 0)
	text.BackgroundTransparency = 1
	text.Text = "Завантаження..."
	text.TextColor3 = TransitionConfig.LoadingTextColor
	text.TextSize = TransitionConfig.LoadingTextSize
	text.Font = TransitionConfig.LoadingFont
	text.TextTransparency = 0
	text.Parent = loadingCont
	loadingText = text

	return gui
end

local function SaveCameraState()
	local camera = Workspace.CurrentCamera
	originalCameraType = camera.CameraType
	originalCameraSubject = camera.CameraSubject
	originalCameraFOV = camera.FieldOfView
end

local function RestoreCameraState()
	local camera = Workspace.CurrentCamera

	-- Reset to default camera following player
	camera.CameraType = Enum.CameraType.Custom

	-- Find current player's humanoid (may be different after location change)
	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
			print(string.format("[%s %s] Camera restored to player humanoid", MODULE_NAME, VERSION))
		end
	end

	-- Restore FOV if saved
	if originalCameraFOV then
		camera.FieldOfView = originalCameraFOV
	end

	-- Clear saved state
	originalCameraType = nil
	originalCameraSubject = nil
	originalCameraFOV = nil
end

local function FadeIn(duration)
	fadeOverlay.BackgroundTransparency = 1
	TweenService:Create(
		fadeOverlay,
		TweenInfo.new(duration or TransitionConfig.LoadingFadeDuration, Enum.EasingStyle.Quad),
		{BackgroundTransparency = 0}
	):Play()
end

local function FadeOut(duration)
	TweenService:Create(
		fadeOverlay,
		TweenInfo.new(duration or TransitionConfig.LoadingFadeDuration, Enum.EasingStyle.Quad),
		{BackgroundTransparency = 1}
	):Play()
end

local function AnimateDeparture(planet, duration)
	-- Simple departure effect: planet grows larger (ship flying toward it)
	-- Player stays seated, looking through cockpit window at the planet

	if not planet then
		print(string.format("[%s %s] No planet found for departure animation", MODULE_NAME, VERSION))
		return
	end

	-- Planet scale animation - get CURRENT scale, don't reset to 1.0
	local originalScale = planet:GetScale()
	local targetScale = originalScale * 2.5 -- Planet appears 2.5x larger as we approach

	print(string.format("[%s %s] Starting planet scale animation (from %.2f to %.2f)",
		MODULE_NAME, VERSION, originalScale, targetScale))

	local startTime = os.clock()
	while os.clock() - startTime < duration do
		local alpha = (os.clock() - startTime) / duration
		local easedAlpha = alpha * alpha -- Quad ease in (accelerating approach)

		-- Scale up planet (appears to get closer)
		local currentScale = originalScale + (targetScale - originalScale) * easedAlpha
		planet:ScaleTo(currentScale)

		task.wait()
	end

	-- Final scale
	planet:ScaleTo(targetScale)
	print(string.format("[%s %s] Departure animation complete", MODULE_NAME, VERSION))
end

local function HandleTransitionUpdate(state, data)
	print(string.format("[%s %s] TransitionUpdate: %s", MODULE_NAME, VERSION, state))

	if state == TransitionConfig.States.GameStart then
		-- Initial game start - show loading screen (ScreenSaver already hidden by GameStateManager)
		local message = data and data.message or "Завантаження..."
		TransitionUI.ShowLoadingScreen(message)

	elseif state == TransitionConfig.States.Departure then
		TransitionUI.ShowDepartureAnimation()

	elseif state == TransitionConfig.States.Loading then
		local message = data and data.message or "Завантаження..."
		TransitionUI.ShowLoadingScreen(message)

	elseif state == TransitionConfig.States.Approach then
		local padPosition = data and data.landingPadPosition
		TransitionUI.ShowLandingSequence(padPosition)

	elseif state == TransitionConfig.States.Landing then
		-- Keep watching landing, camera already set

	elseif state == TransitionConfig.States.Complete then
		local shouldRestoreCamera = data and data.restoreCamera
		TransitionUI.Hide(shouldRestoreCamera)

		-- Update StatusBarUI with displayName values
		local statusBar = GetStatusBarUI()
		if statusBar and data then
			if data.planetDisplayName then
				statusBar.SetPlanet(data.planetDisplayName)
			end
			if data.locationDisplayName then
				statusBar.SetLocation(data.locationDisplayName)
			end
		end

	elseif state == TransitionConfig.States.Liftoff then
		TransitionUI.ShowLiftoffAnimation()

	elseif state == "error" then
		TransitionUI.Hide()
		warn(string.format("[%s %s] Transition error: %s",
			MODULE_NAME, VERSION, data and data.message or "Unknown"))
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function TransitionUI.Initialize()
	if isInitialized then return true end

	print(string.format("[%s %s] Initializing...", MODULE_NAME, VERSION))

	screenGui = CreateUI()
	screenGui.Parent = playerGui
	screenGui.Enabled = true

	-- Setup RemoteEvent listener
	remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if remoteEvents then
		transitionUpdate = remoteEvents:FindFirstChild("TransitionUpdate")
		if transitionUpdate then
			transitionUpdate.OnClientEvent:Connect(HandleTransitionUpdate)
		end
	end

	-- Setup client-side character sound muting for transitions
	SetupCharacterSoundMuting()

	isInitialized = true
	print(string.format("[%s %s] ✓ Initialized", MODULE_NAME, VERSION))
	return true
end

function TransitionUI.ShowDepartureAnimation()
	if isActive then return end
	isActive = true

	print(string.format("[%s %s] Starting departure animation (planet scale)", MODULE_NAME, VERSION))

	SaveCameraState()

	-- Find planet in workspace (player stays seated, looking at planet through cockpit)
	local planet = Workspace:FindFirstChild("Planet")

	-- Start fading to black after delay
	task.delay(TransitionConfig.DepartureFadeStart, function()
		FadeIn(TransitionConfig.DepartureDuration - TransitionConfig.DepartureFadeStart)
	end)

	-- Animate planet getting larger (ship approaching)
	task.spawn(function()
		AnimateDeparture(planet, TransitionConfig.DepartureDuration)
	end)
end

function TransitionUI.ShowLoadingScreen(message)
	print(string.format("[%s %s] Showing loading screen: %s", MODULE_NAME, VERSION, message))

	isActive = true
	fadeOverlay.BackgroundTransparency = 0
	loadingText.Text = message
	loadingContainer.Visible = true

	-- Fade in text
	loadingText.TextTransparency = 1
	TweenService:Create(
		loadingText,
		TweenInfo.new(0.3),
		{TextTransparency = 0}
	):Play()
end

function TransitionUI.ShowLandingSequence(padPosition)
	print(string.format("[%s %s] Starting landing sequence with overhead camera", MODULE_NAME, VERSION))

	-- Hide loading text
	loadingContainer.Visible = false

	-- Fade out overlay to see landing
	FadeOut(0.5)

	-- Setup overhead camera for landing view
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable

	if padPosition then
		-- Position camera above and to the left of the pad, looking down at landing area
		local cameraPos = padPosition + TransitionConfig.LandingCameraOffset
		local lookAtPos = padPosition + TransitionConfig.LandingCameraLookAt

		camera.CFrame = CFrame.lookAt(cameraPos, lookAtPos)
		camera.FieldOfView = 70 -- Wider FOV to see more of the scene

		print(string.format("[%s %s] Camera positioned at %s, looking at %s",
			MODULE_NAME, VERSION, tostring(cameraPos), tostring(lookAtPos)))
	else
		print(string.format("[%s %s] WARNING: No pad position provided for camera", MODULE_NAME, VERSION))
	end
end

function TransitionUI.ShowLiftoffAnimation()
	if isActive then return end
	isActive = true

	print(string.format("[%s %s] Starting liftoff animation (fade to black)", MODULE_NAME, VERSION))

	-- Player stays seated in cockpit watching the ascent
	-- Server animates the ship rising, client just fades to black at the end
	-- Uses unified transition duration
	local totalDuration = TransitionConfig.TransitionAnimationDuration

	-- Start fading to black near the end of ascent
	task.delay(totalDuration - 1.0, function()
		FadeIn(1.0) -- 1 second fade to black
	end)
end

function TransitionUI.Hide(forceRestoreCamera)
	print(string.format("[%s %s] Hiding transition UI (restoreCamera: %s)",
		MODULE_NAME, VERSION, tostring(forceRestoreCamera or false)))

	-- Restore camera to follow player
	if forceRestoreCamera then
		-- Force camera back to player (important after orbit return)
		local camera = Workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Custom

		local character = LocalPlayer.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				camera.CameraSubject = humanoid
				print(string.format("[%s %s] Camera forced to follow player humanoid", MODULE_NAME, VERSION))
			end
		end

		-- Restore FOV
		camera.FieldOfView = 70
	else
		-- Normal restore
		RestoreCameraState()
	end

	-- Fade out overlay
	FadeOut(TransitionConfig.LoadingFadeDuration)

	-- Hide loading container
	loadingContainer.Visible = false

	-- Delay clearing active state
	task.delay(TransitionConfig.LoadingFadeDuration + 0.1, function()
		isActive = false
	end)
end

function TransitionUI.IsActive()
	return isActive
end

function TransitionUI.ForceHide()
	-- Immediate hide without animations
	fadeOverlay.BackgroundTransparency = 1
	loadingContainer.Visible = false
	RestoreCameraState()
	isActive = false
end

-- ============================================================================
-- RETURN
-- ============================================================================

return TransitionUI
