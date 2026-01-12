--[[
================================================================================
KOSMICMAZER — ScreenSaverUI (Dev Version - Phase 2 & 3)
================================================================================

Purpose:
Progressive boot sequence screen saver with server-driven progress tracking.
Each stage ADDS new elements, not replaces them.

Version:
0.5-dev

Architecture:
- Single container with all UI elements
- Elements are hidden initially
- Each stage shows additional elements with fade-in
- Stage 1: Game name, subtitle, version + PROGRESS BAR (25%)
- Stage 2: + Player avatar and name + progress update (50%)
- Stage 3: + Loading text (no spinner) + progress update (75%) OR error state
- Stage 4: + Progress 100% → 1 sec pause → hide progress → Start button

Key Changes (Phase 2 & 3):
- Progress bar starts at Stage 1 (1200px wide, bottom position)
- Dynamic progress calculation from server (25%, 50%, 75%, 100%)
- Removed spinning dots - only loading text remains
- Removed "Готовність 100%" text - button is self-explanatory
- Error state with retry button for Stage 3 failures
- 1 second pause after 100% before showing start button

State Management:
- LoggedOff: ScreenSaver visible, ready for boot sequence
- Initializing: Boot sequence running (Stages 1-4)
- InGame: ScreenSaver hidden

Called from:
- ClientBootstrap (Initialize, Show)
- Server BootStageUpdate events

Events:
- BootStageUpdate (Server → Client): Show stage elements with progress data
- ConfirmGameStart (Client → Server): Player clicked "Почати гру"
- RetryBootStage (Client → Server): Player clicked retry after error

ChangeLog:
- 0.5-dev: Phase 2 & 3 - Progress bar + error state + stage handler updates (2026-01-12)
- 0.4: Complete rewrite with cumulative/progressive UI (2026-01-11)
- 0.3: Crossfade transitions (2026-01-11)
- 0.2: Multi-stage boot sequence (2026-01-11)
- 0.1: Initial simple screensaver (2026-01-11)
================================================================================
]]

local ScreenSaverUI = {}

local VERSION = "0.5-dev"
local MODULE_NAME = "ScreenSaverUI"

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
local canInteract = false
local currentStage = 0

-- Main container
local mainContainer = nil

-- Stage 1 elements (Game info)
local gameNameLabel = nil
local gameSubtitleLabel = nil
local versionLabel = nil

-- Stage 2 elements (Player info)
local avatarFrame = nil
local avatarImage = nil
local playerNameLabel = nil

-- Progress bar elements (shown from Stage 1)
local progressBarContainer = nil
local progressBarBg = nil
local progressBarFill = nil
local progressPercentLabel = nil

-- Stage 3 elements (Loading text only, no spinner)
local loadingContainer = nil
local loadingText = nil

-- Error state elements
local errorContainer = nil
local errorText = nil
local retryButton = nil

-- Stage 4 elements (Button only, no ready text)
local startButton = nil

-- ============================================================================
-- UI CREATION - MAIN CONTAINER
-- ============================================================================

local function CreateMainContainer()
	local container = Instance.new("Frame")
	container.Name = "ScreenSaverContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	container.BorderSizePixel = 0
	container.ZIndex = 1

	return container
end

-- ============================================================================
-- UI CREATION - STAGE 1 ELEMENTS (Game Name)
-- ============================================================================

local function CreateStage1Elements(parent)
	-- Game Name (large, centered top)
	local gameName = Instance.new("TextLabel")
	gameName.Name = "GameName"
	gameName.Size = UDim2.new(0, 700, 0, 80)
	gameName.Position = UDim2.new(0.5, 0, 0.25, 0)
	gameName.AnchorPoint = Vector2.new(0.5, 0.5)
	gameName.BackgroundTransparency = 1
	gameName.Text = "CALL OF RELICS"
	gameName.TextColor3 = Color3.fromRGB(220, 220, 240)
	gameName.TextSize = 56
	gameName.Font = Enum.Font.GothamBold
	gameName.TextTransparency = 1 -- Hidden initially
	gameName.ZIndex = 2
	gameName.Parent = parent

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(0, 500, 0, 40)
	subtitle.Position = UDim2.new(0.5, 0, 0.32, 0)
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Orbital Silence"
	subtitle.TextColor3 = Color3.fromRGB(180, 180, 200)
	subtitle.TextSize = 28
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextTransparency = 1 -- Hidden initially
	subtitle.ZIndex = 2
	subtitle.Parent = parent

	-- Version (bottom-right corner)
	local version = Instance.new("TextLabel")
	version.Name = "Version"
	version.Size = UDim2.new(0, 200, 0, 30)
	version.Position = UDim2.new(1, -20, 1, -20)
	version.AnchorPoint = Vector2.new(1, 1)
	version.BackgroundTransparency = 1
	version.Text = "v0.1 - EPIC 1"
	version.TextColor3 = Color3.fromRGB(120, 120, 140)
	version.TextSize = 16
	version.Font = Enum.Font.Gotham
	version.TextTransparency = 1 -- Hidden initially
	version.TextXAlignment = Enum.TextXAlignment.Right
	version.ZIndex = 2
	version.Parent = parent

	return gameName, subtitle, version
end

-- ============================================================================
-- UI CREATION - STAGE 2 ELEMENTS (Player Info)
-- ============================================================================

local function CreateStage2Elements(parent)
	-- Avatar frame
	local frame = Instance.new("Frame")
	frame.Name = "AvatarFrame"
	frame.Size = UDim2.new(0, 150, 0, 150)
	frame.Position = UDim2.new(0.5, 0, 0.5, -20)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.BorderSizePixel = 0
	frame.BackgroundTransparency = 1 -- Hidden initially
	frame.ZIndex = 2
	frame.Parent = parent

	-- Avatar image
	local image = Instance.new("ImageLabel")
	image.Name = "Avatar"
	image.Size = UDim2.new(1, 0, 1, 0)
	image.BackgroundTransparency = 1
	image.Image = ""
	image.ImageTransparency = 1 -- Hidden initially
	image.ZIndex = 3
	image.Parent = frame

	-- Player name
	local name = Instance.new("TextLabel")
	name.Name = "PlayerName"
	name.Size = UDim2.new(0, 400, 0, 50)
	name.Position = UDim2.new(0.5, 0, 0.5, 100)
	name.AnchorPoint = Vector2.new(0.5, 0.5)
	name.BackgroundTransparency = 1
	name.Text = "PlayerName"
	name.TextColor3 = Color3.fromRGB(200, 200, 220)
	name.TextSize = 32
	name.Font = Enum.Font.GothamBold
	name.TextTransparency = 1 -- Hidden initially
	name.ZIndex = 2
	name.Parent = parent

	return frame, image, name
end

-- ============================================================================
-- UI CREATION - PROGRESS BAR ELEMENTS (Shown from Stage 1)
-- ============================================================================

local function CreateProgressBarElements(parent)
	-- Container for progress bar (1200px wide, 3x original)
	local container = Instance.new("Frame")
	container.Name = "ProgressBarContainer"
	container.Size = UDim2.new(0, 1200, 0, 60)
	container.Position = UDim2.new(0.5, 0, 0.85, 0) -- Bottom center
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.ZIndex = 2
	container.Parent = parent

	-- Progress bar background (BOLD - 16px height, 2x original)
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, 0, 0, 16) -- Doubled from 8 to 16
	progressBg.Position = UDim2.new(0.5, 0, 0.5, 0)
	progressBg.AnchorPoint = Vector2.new(0.5, 0.5)
	progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	progressBg.BorderSizePixel = 0
	progressBg.BackgroundTransparency = 1 -- Hidden initially
	progressBg.ZIndex = 3
	progressBg.Parent = container

	-- Add corner radius for smoother look
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 8)
	bgCorner.Parent = progressBg

	-- Progress bar fill (BOLD - brighter color)
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0) -- Start at 0%
	progressFill.BackgroundColor3 = Color3.fromRGB(120, 180, 255) -- Brighter blue
	progressFill.BorderSizePixel = 0
	progressFill.BackgroundTransparency = 1 -- Hidden initially
	progressFill.ZIndex = 4
	progressFill.Parent = progressBg

	-- Add corner radius for fill
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 8)
	fillCorner.Parent = progressFill

	-- Percent label
	local percentLabel = Instance.new("TextLabel")
	percentLabel.Name = "PercentLabel"
	percentLabel.Size = UDim2.new(1, 0, 0, 30)
	percentLabel.Position = UDim2.new(0.5, 0, 1, 10)
	percentLabel.AnchorPoint = Vector2.new(0.5, 0)
	percentLabel.BackgroundTransparency = 1
	percentLabel.Text = "0%"
	percentLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
	percentLabel.TextSize = 18
	percentLabel.Font = Enum.Font.Gotham
	percentLabel.TextTransparency = 1 -- Hidden initially
	percentLabel.ZIndex = 3
	percentLabel.Parent = container

	return container, progressBg, progressFill, percentLabel
end

-- ============================================================================
-- UI CREATION - STAGE 3 ELEMENTS (Loading)
-- ============================================================================

local function CreateStage3Elements(parent)
	-- Loading container (simplified - text only, no spinner)
	local container = Instance.new("Frame")
	container.Name = "LoadingContainer"
	container.Size = UDim2.new(0, 700, 0, 80)
	container.Position = UDim2.new(0.5, 0, 0.7, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Visible = false -- Hidden initially
	container.ZIndex = 2
	container.Parent = parent

	-- Loading text
	local text = Instance.new("TextLabel")
	text.Name = "LoadingText"
	text.Size = UDim2.new(1, 0, 1, 0)
	text.Position = UDim2.new(0.5, 0, 0.5, 0)
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.BackgroundTransparency = 1
	text.Text = "Ініціалізація експедиції..."
	text.TextColor3 = Color3.fromRGB(200, 200, 220)
	text.TextSize = 24
	text.Font = Enum.Font.Gotham
	text.TextTransparency = 1 -- Hidden initially
	text.ZIndex = 3
	text.Parent = container

	return container, text
end

-- ============================================================================
-- UI CREATION - ERROR STATE ELEMENTS
-- ============================================================================

local function CreateErrorStateElements(parent)
	-- Error container
	local container = Instance.new("Frame")
	container.Name = "ErrorContainer"
	container.Size = UDim2.new(0, 800, 0, 250)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	container.BorderSizePixel = 2
	container.BorderColor3 = Color3.fromRGB(200, 50, 50)
	container.BackgroundTransparency = 1 -- Hidden initially
	container.Visible = false
	container.ZIndex = 5
	container.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = container

	-- Error icon
	local errorIcon = Instance.new("TextLabel")
	errorIcon.Name = "ErrorIcon"
	errorIcon.Size = UDim2.new(0, 80, 0, 80)
	errorIcon.Position = UDim2.new(0.5, 0, 0, 30)
	errorIcon.AnchorPoint = Vector2.new(0.5, 0)
	errorIcon.BackgroundTransparency = 1
	errorIcon.Text = "⚠"
	errorIcon.TextColor3 = Color3.fromRGB(255, 100, 100)
	errorIcon.TextSize = 64
	errorIcon.Font = Enum.Font.GothamBold
	errorIcon.ZIndex = 6
	errorIcon.Parent = container

	-- Error text
	local text = Instance.new("TextLabel")
	text.Name = "ErrorText"
	text.Size = UDim2.new(1, -40, 0, 60)
	text.Position = UDim2.new(0.5, 0, 0, 120)
	text.AnchorPoint = Vector2.new(0.5, 0)
	text.BackgroundTransparency = 1
	text.Text = "Помилка завантаження"
	text.TextColor3 = Color3.fromRGB(255, 200, 200)
	text.TextSize = 22
	text.Font = Enum.Font.Gotham
	text.TextWrapped = true
	text.ZIndex = 6
	text.Parent = container

	-- Retry button
	local button = Instance.new("TextButton")
	button.Name = "RetryButton"
	button.Size = UDim2.new(0, 250, 0, 50)
	button.Position = UDim2.new(0.5, 0, 1, -70)
	button.AnchorPoint = Vector2.new(0.5, 0)
	button.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	button.Text = "Спробувати знову"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 20
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.ZIndex = 6
	button.BorderSizePixel = 0
	button.Parent = container

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	-- Hover effects
	button.MouseEnter:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(180, 70, 70)}
		):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(150, 50, 50)}
		):Play()
	end)

	return container, text, button
end

-- ============================================================================
-- UI CREATION - STAGE 4 ELEMENTS (Ready)
-- ============================================================================

local function CreateStage4Elements(parent)
	-- NO "Готовність 100%" - only button (enlarged to 350x70)
	local button = Instance.new("TextButton")
	button.Name = "StartButton"
	button.Size = UDim2.new(0, 350, 0, 70)
	button.Position = UDim2.new(0.5, 0, 0.7, 0)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
	button.BorderSizePixel = 0
	button.Text = "Почати гру"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 32
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.BackgroundTransparency = 1 -- Hidden initially
	button.TextTransparency = 1 -- Hidden initially
	button.ZIndex = 2
	button.Parent = parent

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	-- Hover effect
	button.MouseEnter:Connect(function()
		if not canInteract then return end
		TweenService:Create(
			button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(70, 120, 170)}
		):Play()
	end)

	button.MouseLeave:Connect(function()
		if not canInteract then return end
		TweenService:Create(
			button,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(50, 100, 150)}
		):Play()
	end)

	-- Click handler
	button.MouseButton1Click:Connect(function()
		if not canInteract then return end

		canInteract = false
		print(string.format("[%s %s][StartButton] Player clicked 'Почати гру'", MODULE_NAME, VERSION))

		-- Send confirmation to server
		local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
		local confirmGameStart = remoteEvents:WaitForChild("ConfirmGameStart")
		confirmGameStart:FireServer()
	end)

	return button -- No ready text
end

-- ============================================================================
-- UI CREATION - FULL SCREEN SAVER
-- ============================================================================

local function CreateScreenSaverUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ScreenSaverUI"
	gui.DisplayOrder = 100
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- Create main container
	mainContainer = CreateMainContainer()
	mainContainer.Parent = gui

	-- Create all stage elements (updated function signatures)
	gameNameLabel, gameSubtitleLabel, versionLabel = CreateStage1Elements(mainContainer)
	avatarFrame, avatarImage, playerNameLabel = CreateStage2Elements(mainContainer)
	progressBarContainer, progressBarBg, progressBarFill, progressPercentLabel = CreateProgressBarElements(mainContainer)
	loadingContainer, loadingText = CreateStage3Elements(mainContainer)
	errorContainer, errorText, retryButton = CreateErrorStateElements(mainContainer)
	startButton = CreateStage4Elements(mainContainer)

	-- Wire up retry button
	retryButton.MouseButton1Click:Connect(function()
		print(string.format("[%s %s][RetryButton] Player clicked retry", MODULE_NAME, VERSION))

		-- Hide error container
		errorContainer.Visible = false

		-- Send retry request to server
		local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
		local retryBootStage = remoteEvents:WaitForChild("RetryBootStage")
		retryBootStage:FireServer(3) -- Retry Stage 3
	end)

	return gui
end

-- ============================================================================
-- ANIMATION HELPERS
-- ============================================================================

local function FadeIn(element, duration, property)
	property = property or "TextTransparency"
	duration = duration or 0.5

	local tween = TweenService:Create(
		element,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{[property] = 0}
	)
	tween:Play()
	return tween
end

local function FadeOut(element, duration, property)
	property = property or "TextTransparency"
	duration = duration or 0.5

	local tween = TweenService:Create(
		element,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{[property] = 1}
	)
	tween:Play()
	return tween
end

-- ============================================================================
-- PROGRESS BAR HELPERS
-- ============================================================================

local function UpdateProgressBar(progressPercent, duration)
	duration = duration or 0.8

	-- Animate progress fill
	TweenService:Create(
		progressBarFill,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(progressPercent / 100, 0, 1, 0)}
	):Play()

	-- Update percent label
	progressPercentLabel.Text = string.format("%d%%", progressPercent)
end

local function ShowProgressBar()
	FadeIn(progressBarBg, 0.5, "BackgroundTransparency")
	FadeIn(progressBarFill, 0.5, "BackgroundTransparency")
	FadeIn(progressPercentLabel, 0.5)
end

local function HideProgressBar()
	FadeOut(progressBarBg, 0.5, "BackgroundTransparency")
	FadeOut(progressBarFill, 0.5, "BackgroundTransparency")
	FadeOut(progressPercentLabel, 0.5)
end

-- ============================================================================
-- STAGE HANDLERS (Progressive/Cumulative)
-- ============================================================================

local function ShowStage1(stageData)
	print(string.format("[%s %s][ShowStage1] Showing game configuration", MODULE_NAME, VERSION))

	-- Update data
	if stageData then
		gameNameLabel.Text = stageData.gameName or "CALL OF RELICS"
		gameSubtitleLabel.Text = stageData.gameSubtitle or "Orbital Silence"
		versionLabel.Text = string.format("v%s - %s", stageData.version or "0.1", stageData.versionTag or "EPIC 1")
	end

	-- Fade in Stage 1 elements
	FadeIn(gameNameLabel, 0.6)
	FadeIn(gameSubtitleLabel, 0.6)
	FadeIn(versionLabel, 0.6)

	-- Show progress bar
	ShowProgressBar()
	if stageData and stageData.progress then
		UpdateProgressBar(stageData.progress, 1.0)
	end
end

local function ShowStage2(stageData)
	print(string.format("[%s %s][ShowStage2] Adding player information", MODULE_NAME, VERSION))

	-- Update player name
	if stageData then
		playerNameLabel.Text = stageData.displayName or stageData.playerName or "Player"
		print(string.format("[%s %s][ShowStage2] Player name: %s", MODULE_NAME, VERSION, playerNameLabel.Text))

		-- Load avatar asynchronously
		task.spawn(function()
			print(string.format("[%s %s][ShowStage2] Loading avatar for UserId: %d", MODULE_NAME, VERSION, stageData.userId))

			local success, thumbnail = pcall(function()
				return Players:GetUserThumbnailAsync(
					stageData.userId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size150x150
				)
			end)

			if success and thumbnail then
				avatarImage.Image = thumbnail
				print(string.format("[%s %s][ShowStage2] Avatar loaded: %s", MODULE_NAME, VERSION, thumbnail))
			else
				warn(string.format("[%s %s][ShowStage2] Failed to load avatar: %s", MODULE_NAME, VERSION, tostring(thumbnail)))
			end
		end)
	end

	-- Fade in Stage 2 elements (Stage 1 stays visible!)
	FadeIn(avatarFrame, 0.6, "BackgroundTransparency")
	FadeIn(avatarImage, 0.6, "ImageTransparency")
	FadeIn(playerNameLabel, 0.6)

	-- Update progress bar
	if stageData and stageData.progress then
		UpdateProgressBar(stageData.progress, 1.0)
	end
end

local function ShowStage3(stageData)
	print(string.format("[%s %s][ShowStage3] Stage 3 - Profile loading", MODULE_NAME, VERSION))

	-- Check for error state
	if stageData and stageData.success == false then
		print(string.format("[%s %s][ShowStage3] ERROR: %s", MODULE_NAME, VERSION, stageData.errorMessage or "Unknown error"))

		-- Show error container
		errorText.Text = stageData.errorMessage or "Невідома помилка"
		errorContainer.Visible = true
		TweenService:Create(
			errorContainer,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 0.1}
		):Play()

		-- Show or hide retry button based on canRetry
		if stageData.canRetry then
			retryButton.Visible = true
		else
			retryButton.Visible = false
		end

		return
	end

	-- Success case - show loading text
	if stageData and stageData.isNewPlayer then
		loadingText.Text = "Ініціалізація експедиції..."
	else
		loadingText.Text = "Відновлення експедиції..."
	end

	loadingContainer.Visible = true
	FadeIn(loadingText, 0.5)

	-- Update progress bar
	if stageData and stageData.progress then
		UpdateProgressBar(stageData.progress, 1.5)
	end
end

local function ShowStage4(stageData)
	print(string.format("[%s %s][ShowStage4] Showing ready state", MODULE_NAME, VERSION))

	-- Update progress to 100%
	if stageData and stageData.progress then
		UpdateProgressBar(stageData.progress, 1.0)
	end

	-- Hide loading text
	if loadingContainer.Visible then
		FadeOut(loadingText, 0.4)
		task.wait(0.5)
		loadingContainer.Visible = false
	end

	-- CRITICAL: 1 second pause after reaching 100%
	print(string.format("[%s %s][ShowStage4] Pausing 1 second after 100%%", MODULE_NAME, VERSION))
	task.wait(1.0)

	-- Hide progress bar
	HideProgressBar()
	task.wait(0.5)

	-- Show start button (no ready text)
	FadeIn(startButton, 0.6, "BackgroundTransparency")
	FadeIn(startButton, 0.6, "TextTransparency")

	-- Enable interaction
	canInteract = true
	print(string.format("[%s %s][ShowStage4] Player can now click 'Почати гру'", MODULE_NAME, VERSION))
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function ScreenSaverUI.Initialize()
	print(string.format("[%s %s][Initialize] Creating ScreenSaver UI", MODULE_NAME, VERSION))

	screenGui = CreateScreenSaverUI()
	screenGui.Parent = playerGui

	-- Listen to BootStageUpdate from server
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	local bootStageUpdate = remoteEvents:WaitForChild("BootStageUpdate")

	bootStageUpdate.OnClientEvent:Connect(function(stageNum, stageData)
		ScreenSaverUI.ShowStage(stageNum, stageData)
	end)

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
	canInteract = false

	print(string.format("[%s %s][Show] ScreenSaver visible - waiting for boot sequence", MODULE_NAME, VERSION))
end

function ScreenSaverUI.Hide()
	if not screenGui then return end

	screenGui.Enabled = false
	isVisible = false
	canInteract = false

	print(string.format("[%s %s][Hide] ScreenSaver hidden", MODULE_NAME, VERSION))
end

function ScreenSaverUI.Reset()
	-- Reset all elements to initial state (for LoggedOff return)
	print(string.format("[%s %s][Reset] Resetting ScreenSaver to initial state", MODULE_NAME, VERSION))

	currentStage = 0
	canInteract = false

	-- Hide Stage 1 elements
	gameNameLabel.TextTransparency = 1
	gameSubtitleLabel.TextTransparency = 1
	versionLabel.TextTransparency = 1

	-- Hide Stage 2 elements
	avatarFrame.BackgroundTransparency = 1
	avatarImage.ImageTransparency = 1
	avatarImage.Image = ""
	playerNameLabel.TextTransparency = 1

	-- Reset progress bar
	progressBarBg.BackgroundTransparency = 1
	progressBarFill.BackgroundTransparency = 1
	progressBarFill.Size = UDim2.new(0, 0, 1, 0)
	progressPercentLabel.TextTransparency = 1
	progressPercentLabel.Text = "0%"

	-- Hide Stage 3 elements
	loadingContainer.Visible = false

	-- Hide error state
	errorContainer.Visible = false

	-- Hide Stage 4 elements
	startButton.BackgroundTransparency = 1
	startButton.TextTransparency = 1
end

function ScreenSaverUI.ShowStage(stageNum, stageData)
	print(string.format("[%s %s][ShowStage] Stage %d received", MODULE_NAME, VERSION, stageNum))

	-- Log progress data
	if stageData and stageData.progress then
		print(string.format("[%s %s][ShowStage] Progress: %d%% (Stage %d/%d)",
			MODULE_NAME, VERSION, stageData.progress, stageData.stageNumber, stageData.totalStages))
	end

	if stageNum == 1 then
		ShowStage1(stageData)
	elseif stageNum == 2 then
		ShowStage2(stageData)
	elseif stageNum == 3 then
		ShowStage3(stageData)
	elseif stageNum == 4 then
		ShowStage4(stageData) -- Pass stageData
	end

	currentStage = stageNum
end

function ScreenSaverUI.IsVisible()
	return isVisible
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

return ScreenSaverUI
