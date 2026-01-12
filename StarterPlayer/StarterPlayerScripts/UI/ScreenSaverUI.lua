--[[
================================================================================
KOSMICMAZER — ScreenSaverUI (Накопичувальна версія)
================================================================================

Purpose:
Progressive boot sequence screen saver that accumulates UI elements stage by stage.
Each stage ADDS new elements, not replaces them.

Version:
0.4

Architecture:
- Single container with all UI elements
- Elements are hidden initially
- Each stage shows additional elements with fade-in
- Stage 1: Game name, subtitle, version
- Stage 2: + Player avatar and name
- Stage 3: + Loading spinner and text
- Stage 4: + Ready text and Start button (hides spinner)

State Management:
- LoggedOff: ScreenSaver visible, ready for boot sequence
- Initializing: Boot sequence running (Stages 1-4)
- InGame: ScreenSaver hidden

Called from:
- ClientBootstrap (Initialize, Show)
- Server BootStageUpdate events

Events:
- BootStageUpdate (Server → Client): Show stage elements
- ConfirmGameStart (Client → Server): Player clicked "Почати гру"

ChangeLog:
- 0.4: Complete rewrite with cumulative/progressive UI (2026-01-11)
- 0.3: Crossfade transitions (2026-01-11)
- 0.2: Multi-stage boot sequence (2026-01-11)
- 0.1: Initial simple screensaver (2026-01-11)
================================================================================
]]

local ScreenSaverUI = {}

local VERSION = "0.4"
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
-- UI CREATION - STAGE 3 ELEMENTS (Loading)
-- ============================================================================

local function CreateStage3Elements(parent)
	-- Loading container
	local container = Instance.new("Frame")
	container.Name = "LoadingContainer"
	container.Size = UDim2.new(0, 500, 0, 200)
	container.Position = UDim2.new(0.5, 0, 0.7, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.ZIndex = 2
	container.Parent = parent

	-- Spinner frame
	local spinnerFrame = Instance.new("Frame")
	spinnerFrame.Name = "SpinnerFrame"
	spinnerFrame.Size = UDim2.new(0, 100, 0, 100)
	spinnerFrame.Position = UDim2.new(0.5, 0, 0, 0)
	spinnerFrame.AnchorPoint = Vector2.new(0.5, 0)
	spinnerFrame.BackgroundTransparency = 1
	spinnerFrame.ZIndex = 3
	spinnerFrame.Parent = container

	-- Create 4 dots in circle
	for i = 1, 4 do
		local angle = (i - 1) * (math.pi / 2)
		local x = math.cos(angle) * 30
		local y = math.sin(angle) * 30

		local dot = Instance.new("Frame")
		dot.Name = "Dot" .. i
		dot.Size = UDim2.new(0, 12, 0, 12)
		dot.Position = UDim2.new(0.5, x, 0.5, y)
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.BackgroundColor3 = Color3.fromRGB(150, 150, 200)
		dot.BorderSizePixel = 0
		dot.BackgroundTransparency = 1 -- Hidden initially
		dot.ZIndex = 4
		dot.Parent = spinnerFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = dot
	end

	-- Loading text
	local text = Instance.new("TextLabel")
	text.Name = "LoadingText"
	text.Size = UDim2.new(1, 0, 0, 50)
	text.Position = UDim2.new(0.5, 0, 0, 120)
	text.AnchorPoint = Vector2.new(0.5, 0)
	text.BackgroundTransparency = 1
	text.Text = "Ініціалізація експедиції..."
	text.TextColor3 = Color3.fromRGB(200, 200, 220)
	text.TextSize = 24
	text.Font = Enum.Font.Gotham
	text.TextTransparency = 1 -- Hidden initially
	text.ZIndex = 3
	text.Parent = container

	-- Progress bar background
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(0, 400, 0, 8)
	progressBg.Position = UDim2.new(0.5, 0, 1, -20)
	progressBg.AnchorPoint = Vector2.new(0.5, 0)
	progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	progressBg.BorderSizePixel = 0
	progressBg.BackgroundTransparency = 1 -- Hidden initially
	progressBg.ZIndex = 3
	progressBg.Parent = container

	-- Progress bar fill
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0.75, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
	progressFill.BorderSizePixel = 0
	progressFill.BackgroundTransparency = 1 -- Hidden initially
	progressFill.ZIndex = 4
	progressFill.Parent = progressBg

	container.Visible = false -- Hidden initially

	return container, spinnerFrame, text, progressBg, progressFill
end

-- ============================================================================
-- UI CREATION - STAGE 4 ELEMENTS (Ready)
-- ============================================================================

local function CreateStage4Elements(parent)
	-- Ready text
	local ready = Instance.new("TextLabel")
	ready.Name = "ReadyText"
	ready.Size = UDim2.new(0, 500, 0, 80)
	ready.Position = UDim2.new(0.5, 0, 0.65, 0)
	ready.AnchorPoint = Vector2.new(0.5, 0.5)
	ready.BackgroundTransparency = 1
	ready.Text = "Готовність 100%"
	ready.TextColor3 = Color3.fromRGB(100, 200, 150)
	ready.TextSize = 48
	ready.Font = Enum.Font.GothamBold
	ready.TextTransparency = 1 -- Hidden initially
	ready.ZIndex = 2
	ready.Parent = parent

	-- Start button
	local button = Instance.new("TextButton")
	button.Name = "StartButton"
	button.Size = UDim2.new(0, 300, 0, 60)
	button.Position = UDim2.new(0.5, 0, 0.75, 0)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
	button.BorderSizePixel = 0
	button.Text = "Почати гру"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 28
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

	return ready, button
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

	-- Create all stage elements
	gameNameLabel, gameSubtitleLabel, versionLabel = CreateStage1Elements(mainContainer)
	avatarFrame, avatarImage, playerNameLabel = CreateStage2Elements(mainContainer)
	loadingContainer, loadingSpinner, loadingText, progressBarBg, progressBarFill = CreateStage3Elements(mainContainer)
	readyText, startButton = CreateStage4Elements(mainContainer)

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
end

local function ShowStage3(stageData)
	print(string.format("[%s %s][ShowStage3] Adding loading indicators", MODULE_NAME, VERSION))

	-- Update loading text
	if stageData and stageData.success then
		if stageData.isNewPlayer then
			loadingText.Text = "Ініціалізація експедиції..."
		else
			loadingText.Text = "Відновлення експедиції..."
		end
	else
		loadingText.Text = "Помилка завантаження профілю"
		loadingText.TextColor3 = Color3.fromRGB(200, 100, 100)
	end

	-- Show loading container
	loadingContainer.Visible = true

	-- Fade in Stage 3 elements (Stages 1+2 stay visible!)
	FadeIn(loadingText, 0.5)
	FadeIn(progressBarBg, 0.5, "BackgroundTransparency")
	FadeIn(progressBarFill, 0.5, "BackgroundTransparency")

	-- Fade in spinner dots
	for _, dot in ipairs(loadingSpinner:GetChildren()) do
		if dot:IsA("Frame") then
			FadeIn(dot, 0.5, "BackgroundTransparency")
		end
	end

	-- Start spinner rotation
	task.spawn(function()
		while loadingContainer.Visible and loadingSpinner do
			loadingSpinner.Rotation = (loadingSpinner.Rotation + 2) % 360
			task.wait(0.03)
		end
	end)

	-- Animate progress bar
	task.spawn(function()
		while loadingContainer.Visible and progressBarFill do
			TweenService:Create(
				progressBarFill,
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Size = UDim2.new(0.95, 0, 1, 0)}
			):Play()
			task.wait(1.5)
		end
	end)
end

local function ShowStage4()
	print(string.format("[%s %s][ShowStage4] Showing ready state", MODULE_NAME, VERSION))

	-- Hide loading elements
	FadeOut(loadingText, 0.4)
	task.wait(0.2)
	for _, dot in ipairs(loadingSpinner:GetChildren()) do
		if dot:IsA("Frame") then
			FadeOut(dot, 0.4, "BackgroundTransparency")
		end
	end
	task.wait(0.4)
	loadingContainer.Visible = false

	-- Fade in Stage 4 elements (Stages 1+2 stay visible!)
	FadeIn(readyText, 0.6)
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

	-- Hide all elements instantly
	gameNameLabel.TextTransparency = 1
	gameSubtitleLabel.TextTransparency = 1
	versionLabel.TextTransparency = 1

	avatarFrame.BackgroundTransparency = 1
	avatarImage.ImageTransparency = 1
	avatarImage.Image = ""
	playerNameLabel.TextTransparency = 1

	loadingContainer.Visible = false

	readyText.TextTransparency = 1
	startButton.BackgroundTransparency = 1
	startButton.TextTransparency = 1
end

function ScreenSaverUI.ShowStage(stageNum, stageData)
	print(string.format("[%s %s][ShowStage] Stage %d received", MODULE_NAME, VERSION, stageNum))

	if stageNum == 1 then
		ShowStage1(stageData)
	elseif stageNum == 2 then
		ShowStage2(stageData)
	elseif stageNum == 3 then
		ShowStage3(stageData)
	elseif stageNum == 4 then
		ShowStage4()
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
