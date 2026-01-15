--[[
================================================================================
KOSMICMAZER — TransitionUI
================================================================================

Purpose:
UI for location transitions. Handles departure animation, loading screen,
and landing sequence visualization.

Version:
0.6

Features:
- Departure animation (ship scale down, planet scale up, fade to black)
- Loading screen with message
- Landing camera sequence (POV from landing pad)
- Cockpit view after landing (camera behind player, looking through window)
- Two-phase launch animation (Phase 1: cockpit/liftoff, Phase 2: external/ascent)
- Two-phase landing animation (Phase 1: external view, Phase 2: cockpit view)
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
- 0.9: Rename Liftoff → Launch (ShowLaunchPhase1/2, States.Launch/Ascent) (2026-01-15)
- 0.8: Fix Launch Phase 1 camera tracking, add delay before GameStart cockpit setup (2026-01-15)
- 0.7: Two-phase landing (external view + cockpit view for final approach) (2026-01-15)
- 0.6: Two-phase launch (cockpit view + external view watching ship) (2026-01-15)
- 0.5: Added cockpit view after landing (camera behind player) (2026-01-15)
- 0.4: Added StatusBarUI integration for displayName (2026-01-14)
- 0.3: Added ShowLandingCamera with server-provided data (2026-01-14)
- 0.2: Enhanced loading screen, camera restore (2026-01-14)
- 0.1: Initial TransitionUI (2026-01-14)
================================================================================
]]

local TransitionUI = {}

local VERSION = "0.9"
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

-- Track if cockpit view is already set (to avoid double-setting)
local cockpitViewActive = false

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

local function SetCockpitView(finalTransition)
	-- Skip if cockpit view is already active (avoid double-setting and flickering)
	-- But allow if this is the final transition (Hide() call)
	if cockpitViewActive and not finalTransition then
		return true
	end

	-- Position camera behind player looking through cockpit window
	local camera = Workspace.CurrentCamera
	local character = LocalPlayer.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not humanoidRootPart then return false end

	-- Get the ship to determine forward direction
	local ship = Workspace:FindFirstChild("SpaceShip")
	if not ship then
		-- Fallback to standard camera
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
		return false
	end

	-- Get ship's forward direction (LookVector of PrimaryPart or first BasePart)
	local shipPart = ship.PrimaryPart or ship:FindFirstChildWhichIsA("BasePart")
	if not shipPart then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
		return false
	end

	-- Mark cockpit view as active (only during transition, not final)
	if not finalTransition then
		cockpitViewActive = true
	end

	-- Calculate camera position: behind and slightly above player's head
	local playerPos = humanoidRootPart.Position
	local shipLookVector = shipPart.CFrame.LookVector
	local shipUpVector = shipPart.CFrame.UpVector

	-- Position camera behind player (opposite of ship's forward direction)
	-- Offset: 3 studs behind, 1.5 studs up from head level
	local cameraOffset = -shipLookVector * 3 + shipUpVector * 2.5
	local cameraPos = playerPos + cameraOffset

	-- Look at a point in front of the player (through the cockpit window)
	local lookAtPos = playerPos + shipLookVector * 50

	-- Set camera to Scriptable first, then immediately to Custom
	-- This gives a brief cockpit view before player takes control
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(cameraPos, lookAtPos)
	camera.FieldOfView = 70

	-- Immediately switch to Custom camera - player takes control from cockpit position
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid

	return true
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

	if not planet then return end

	-- Planet scale animation - get CURRENT scale, don't reset to 1.0
	local originalScale = planet:GetScale()
	local targetScale = originalScale * 2.5 -- Planet appears 2.5x larger as we approach

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
end

local function HandleTransitionUpdate(state, data)
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
		-- Phase 1: External view watching ship descend
		local padPosition = data and data.landingPadPosition
		local duration = data and data.duration or TransitionConfig.LandingPhase1Duration
		TransitionUI.ShowLandingPhase1(padPosition, duration)

	elseif state == TransitionConfig.States.Landing then
		-- Phase 2: Cockpit view for final approach
		local duration = data and data.duration or TransitionConfig.LandingPhase2Duration
		TransitionUI.ShowLandingPhase2(duration)

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

	elseif state == TransitionConfig.States.Launch then
		-- Phase 1: Cockpit view during liftoff
		local duration = data and data.duration or 3.0
		TransitionUI.ShowLaunchPhase1(duration)

	elseif state == TransitionConfig.States.Ascent then
		-- Phase 2: External view watching ship ascend
		local duration = data and data.duration or 4.0
		local padPosition = data and data.padPosition
		local shipPosition = data and data.shipPosition
		TransitionUI.ShowLaunchPhase2(duration, padPosition, shipPosition)

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
	return true
end

function TransitionUI.ShowDepartureAnimation()
	if isActive then return end
	isActive = true

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
	-- Legacy function - redirect to Phase 1
	TransitionUI.ShowLandingPhase1(padPosition, TransitionConfig.LandingPhase1Duration or 4.0)
end

function TransitionUI.ShowLandingPhase1(padPosition, duration)
	if not isActive then
		isActive = true
		SaveCameraState()
	end

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

		-- Track the ship as it descends
		local ship = Workspace:FindFirstChild("SpaceShip")
		if ship then
			local startTime = os.clock()
			task.spawn(function()
				while os.clock() - startTime < duration - 0.5 do
					local shipPart = ship.PrimaryPart or ship:FindFirstChildWhichIsA("BasePart")
					if shipPart then
						-- Keep looking at the ship as it descends
						camera.CFrame = CFrame.lookAt(cameraPos, shipPart.Position)
					end
					task.wait()
				end
			end)
		end
	else
		print(string.format("[%s %s] WARNING: No pad position provided for camera", MODULE_NAME, VERSION))
	end
end

function TransitionUI.ShowLandingPhase2(duration)
	-- Quick fade to black before camera switch
	FadeIn(0.25)

	-- Wait for fade, then switch camera and fade out
	task.delay(0.25, function()
		-- Set cockpit view directly (without the delayed Custom switch)
		local camera = Workspace.CurrentCamera
		local character = LocalPlayer.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			local ship = Workspace:FindFirstChild("SpaceShip")

			if humanoid and humanoidRootPart and ship then
				local shipPart = ship.PrimaryPart or ship:FindFirstChildWhichIsA("BasePart")
				if shipPart then
					local playerPos = humanoidRootPart.Position
					local shipLookVector = shipPart.CFrame.LookVector
					local shipUpVector = shipPart.CFrame.UpVector
					local cameraOffset = -shipLookVector * 3 + shipUpVector * 2.5
					local cameraPos = playerPos + cameraOffset
					local lookAtPos = playerPos + shipLookVector * 50

					camera.CameraType = Enum.CameraType.Scriptable
					camera.CFrame = CFrame.lookAt(cameraPos, lookAtPos)
					camera.FieldOfView = 70

					-- Mark cockpit view as active for Hide() to know
					cockpitViewActive = true
				end
			end
		end

		-- Fade back out to reveal cockpit view
		task.delay(0.1, function()
			FadeOut(0.25)
		end)
	end)

	-- Player now watches final descent from inside the cockpit
	-- Camera is behind player, looking through the cockpit window
end

function TransitionUI.ShowLaunchPhase1(duration)
	-- Don't check isActive - launch can start right after landing complete
	-- Reset isActive and cockpitViewActive for fresh launch sequence
	isActive = true
	cockpitViewActive = false

	SaveCameraState()

	-- Set cockpit view - player watches through cockpit window
	-- Camera follows player as ship rises
	local camera = Workspace.CurrentCamera
	local character = LocalPlayer.Character
	local ship = Workspace:FindFirstChild("SpaceShip")

	if character and ship then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		local shipPart = ship.PrimaryPart or ship:FindFirstChildWhichIsA("BasePart")

		if humanoidRootPart and shipPart then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.FieldOfView = 70

			-- Track the player throughout phase 1 (camera follows as ship rises)
			local startTime = os.clock()
			task.spawn(function()
				while os.clock() - startTime < duration do
					local playerPos = humanoidRootPart.Position
					local shipLookVector = shipPart.CFrame.LookVector
					local shipUpVector = shipPart.CFrame.UpVector
					local cameraOffset = -shipLookVector * 3 + shipUpVector * 2.5
					local cameraPos = playerPos + cameraOffset
					local lookAtPos = playerPos + shipLookVector * 50

					camera.CFrame = CFrame.lookAt(cameraPos, lookAtPos)
					task.wait()
				end
			end)
		end
	end
end

function TransitionUI.ShowLaunchPhase2(duration, padPosition, shipPosition)
	-- Quick fade to black before camera switch
	FadeIn(0.25)

	-- Wait for fade, then switch camera and fade out
	task.delay(0.25, function()
		local camera = Workspace.CurrentCamera

		-- Position camera on ground looking up at the ascending ship
		if padPosition then
			-- Camera offset from landing pad (similar to landing camera but looking UP)
			local cameraOffset = TransitionConfig.LandingCameraOffset
			local cameraPos = padPosition + cameraOffset

			-- Look at ship's current position (will track ship as it rises)
			local lookAtPos = shipPosition or (padPosition + Vector3.new(0, 100, 0))

			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = CFrame.lookAt(cameraPos, lookAtPos)
			camera.FieldOfView = 70

			-- Fade back out to reveal external view
			task.delay(0.1, function()
				FadeOut(0.25)
			end)

			-- Track the ship as it ascends
			local ship = Workspace:FindFirstChild("SpaceShip")
			if ship then
				local startTime = os.clock()
				task.spawn(function()
					-- Adjust duration to account for fade time
					while os.clock() - startTime < duration - 1.5 do
						local shipPart = ship.PrimaryPart or ship:FindFirstChildWhichIsA("BasePart")
						if shipPart then
							-- Keep looking at the ship as it rises
							camera.CFrame = CFrame.lookAt(cameraPos, shipPart.Position)
						end
						task.wait()
					end
				end)
			end
		end

		-- Start fading to black near the end of phase 2 (adjusted for initial fade)
		task.delay(duration - 1.5, function()
			FadeIn(1.0) -- 1 second fade to black
		end)
	end)
end

-- Legacy function for compatibility
function TransitionUI.ShowLaunchAnimation()
	-- Redirect to Phase 1 with default duration
	TransitionUI.ShowLaunchPhase1(TransitionConfig.LaunchPhase1Duration or 3.0)
end

function TransitionUI.Hide(forceRestoreCamera)
	local camera = Workspace.CurrentCamera
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	-- If cockpit view was set during phase 2, just switch to Custom camera smoothly
	-- Don't reset the camera position - it's already correct
	if cockpitViewActive then
		-- Cockpit view already set in phase 2, just transition to player control
		task.delay(0.3, function()
			if humanoid then
				camera.CameraType = Enum.CameraType.Custom
				camera.CameraSubject = humanoid
			end
		end)
		cockpitViewActive = false
	else
		-- No cockpit view was set (e.g., GameStart or orbit return after launch)
		-- Wait briefly for character/ship to be fully positioned before setting camera
		task.delay(0.2, function()
			-- Re-get character and humanoid in case they changed
			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if not SetCockpitView(true) then
				-- Fallback to standard camera if cockpit view fails
				camera.CameraType = Enum.CameraType.Custom
				if hum then
					camera.CameraSubject = hum
				end
				camera.FieldOfView = 70
			end
		end)
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
