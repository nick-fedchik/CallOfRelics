--[[
================================================================================
KOSMICMAZER — ScreenSaverUI
================================================================================

Purpose:
Manages the ScreenSaver UI with 4-stage progressive boot sequence.
Implements ScreenSaver UI from TDD Section 7.2.

Version:
0.2

Features:
- Stage 0: Initial "Press to Enter" prompt
- Stage 1: Display game configuration (name, version)
- Stage 2: Display player avatar and name
- Stage 3: Loading animation with profile status
- Stage 4: Ready state with "Почати гру" button
- Smooth transitions between stages
- Handles player input to initiate LogOn and confirm game start

API:
- Initialize() — Setup ScreenSaver UI
- Show() — Display ScreenSaver (Stage 0)
- Hide() — Hide ScreenSaver
- ShowStage(stageNum, data) — Display specific boot stage
- RequestLogOn() — Send LogOnRequest to server

Calls to:
- RemoteEvents (LogOnRequest, ConfirmGameStart)

Called from:
- ClientBootstrap

Events:
- Listens: BootStageUpdate (Server → Client)

Dependencies:
- ReplicatedStorage.RemoteEvents

ChangeLog:
- 0.2: Complete 4-stage boot sequence implementation (2026-01-11)
- 0.1: Initial ScreenSaver implementation (2026-01-11)
================================================================================
]]

local ScreenSaverUI = {}

local VERSION = "0.2"
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
local currentStage = 0

local stageContainers = {} -- [stageNum] = Frame

-- ============================================================================
-- UI CREATION - STAGE 0 (Initial ScreenSaver)
-- ============================================================================

local function CreateStage0()
	local container = Instance.new("Frame")
	container.Name = "Stage0"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	container.BorderSizePixel = 0
	container.Visible = false

	-- Title
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
	title.Parent = container

	-- Subtitle
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
	subtitle.Parent = container

	-- Prompt (pulsing)
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
	prompt.Parent = container

	-- Pulsing animation
	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = TweenService:Create(prompt, tweenInfo, {TextTransparency = 0.8})
	tween:Play()

	return container
end

-- ============================================================================
-- UI CREATION - STAGE 1 (Game Configuration)
-- ============================================================================

local function CreateStage1()
	local container = Instance.new("Frame")
	container.Name = "Stage1"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	container.BorderSizePixel = 0
	container.Visible = false

	-- Game Name (Large)
	local gameName = Instance.new("TextLabel")
	gameName.Name = "GameName"
	gameName.Size = UDim2.new(0, 800, 0, 120)
	gameName.Position = UDim2.new(0.5, 0, 0.35, 0)
	gameName.AnchorPoint = Vector2.new(0.5, 0.5)
	gameName.BackgroundTransparency = 1
	gameName.Text = "CALL OF RELICS"
	gameName.TextColor3 = Color3.fromRGB(220, 220, 240)
	gameName.TextSize = 56
	gameName.Font = Enum.Font.GothamBold
	gameName.Parent = container

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(0, 400, 0, 50)
	subtitle.Position = UDim2.new(0.5, 0, 0.45, 0)
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Orbital Silence"
	subtitle.TextColor3 = Color3.fromRGB(150, 150, 170)
	subtitle.TextSize = 28
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = container

	-- Version (Bottom Right)
	local version = Instance.new("TextLabel")
	version.Name = "Version"
	version.Size = UDim2.new(0, 200, 0, 40)
	version.Position = UDim2.new(1, -20, 1, -20)
	version.AnchorPoint = Vector2.new(1, 1)
	version.BackgroundTransparency = 1
	version.Text = "v0.1 - EPIC 1"
	version.TextColor3 = Color3.fromRGB(100, 100, 120)
	version.TextSize = 16
	version.Font = Enum.Font.Gotham
	version.TextXAlignment = Enum.TextXAlignment.Right
	version.Parent = container

	return container
end

-- ============================================================================
-- UI CREATION - STAGE 2 (Player Information)
-- ============================================================================

local function CreateStage2()
	local container = Instance.new("Frame")
	container.Name = "Stage2"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	container.BorderSizePixel = 0
	container.Visible = false

	-- Avatar placeholder
	local avatarFrame = Instance.new("Frame")
	avatarFrame.Name = "AvatarFrame"
	avatarFrame.Size = UDim2.new(0, 150, 0, 150)
	avatarFrame.Position = UDim2.new(0.5, 0, 0.35, 0)
	avatarFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	avatarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	avatarFrame.BorderSizePixel = 0
	avatarFrame.Parent = container

	-- Avatar image
	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(1, 0, 1, 0)
	avatar.BackgroundTransparency = 1
	avatar.Image = ""
	avatar.Parent = avatarFrame

	-- Player name
	local playerName = Instance.new("TextLabel")
	playerName.Name = "PlayerName"
	playerName.Size = UDim2.new(0, 400, 0, 50)
	playerName.Position = UDim2.new(0.5, 0, 0.55, 0)
	playerName.AnchorPoint = Vector2.new(0.5, 0.5)
	playerName.BackgroundTransparency = 1
	playerName.Text = "PlayerName"
	playerName.TextColor3 = Color3.fromRGB(200, 200, 220)
	playerName.TextSize = 32
	playerName.Font = Enum.Font.GothamBold
	playerName.Parent = container

	return container
end

-- ============================================================================
-- UI CREATION - STAGE 3 (Profile Loading)
-- ============================================================================

local function CreateStage3()
	local container = Instance.new("Frame")
	container.Name = "Stage3"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	container.BorderSizePixel = 0
	container.Visible = false

	-- Loading spinner (4 rotating dots)
	local spinnerFrame = Instance.new("Frame")
	spinnerFrame.Name = "SpinnerFrame"
	spinnerFrame.Size = UDim2.new(0, 100, 0, 100)
	spinnerFrame.Position = UDim2.new(0.5, 0, 0.35, 0)
	spinnerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	spinnerFrame.BackgroundTransparency = 1
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
		dot.Parent = spinnerFrame

		-- Rounded corners
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = dot
	end

	-- Rotate spinner continuously
	task.spawn(function()
		while spinnerFrame and spinnerFrame.Parent do
			spinnerFrame.Rotation = (spinnerFrame.Rotation + 2) % 360
			task.wait(0.03)
		end
	end)

	-- Status text
	local statusText = Instance.new("TextLabel")
	statusText.Name = "StatusText"
	statusText.Size = UDim2.new(0, 500, 0, 50)
	statusText.Position = UDim2.new(0.5, 0, 0.5, 0)
	statusText.AnchorPoint = Vector2.new(0.5, 0.5)
	statusText.BackgroundTransparency = 1
	statusText.Text = "Ініціалізація експедиції..."
	statusText.TextColor3 = Color3.fromRGB(200, 200, 220)
	statusText.TextSize = 24
	statusText.Font = Enum.Font.Gotham
	statusText.Parent = container

	-- Progress bar background
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(0, 400, 0, 8)
	progressBg.Position = UDim2.new(0.5, 0, 0.6, 0)
	progressBg.AnchorPoint = Vector2.new(0.5, 0.5)
	progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = container

	-- Progress bar fill
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0.75, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg

	-- Animate progress bar
	task.spawn(function()
		while progressFill and progressFill.Parent do
			local tween = TweenService:Create(
				progressFill,
				TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Size = UDim2.new(0.95, 0, 1, 0)}
			)
			tween:Play()
			task.wait(1.5)
		end
	end)

	return container
end

-- ============================================================================
-- UI CREATION - STAGE 4 (Ready State)
-- ============================================================================

local function CreateStage4()
	local container = Instance.new("Frame")
	container.Name = "Stage4"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	container.BorderSizePixel = 0
	container.Visible = false

	-- Ready text
	local readyText = Instance.new("TextLabel")
	readyText.Name = "ReadyText"
	readyText.Size = UDim2.new(0, 500, 0, 80)
	readyText.Position = UDim2.new(0.5, 0, 0.35, 0)
	readyText.AnchorPoint = Vector2.new(0.5, 0.5)
	readyText.BackgroundTransparency = 1
	readyText.Text = "Готовність 100%"
	readyText.TextColor3 = Color3.fromRGB(100, 200, 150)
	readyText.TextSize = 48
	readyText.Font = Enum.Font.GothamBold
	readyText.Parent = container

	-- Start button
	local startButton = Instance.new("TextButton")
	startButton.Name = "StartButton"
	startButton.Size = UDim2.new(0, 300, 0, 60)
	startButton.Position = UDim2.new(0.5, 0, 0.55, 0)
	startButton.AnchorPoint = Vector2.new(0.5, 0.5)
	startButton.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
	startButton.BorderSizePixel = 0
	startButton.Text = "Почати гру"
	startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	startButton.TextSize = 28
	startButton.Font = Enum.Font.GothamBold
	startButton.AutoButtonColor = false
	startButton.Parent = container

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = startButton

	-- Hover effect
	startButton.MouseEnter:Connect(function()
		local tween = TweenService:Create(
			startButton,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(70, 120, 170)}
		)
		tween:Play()
	end)

	startButton.MouseLeave:Connect(function()
		local tween = TweenService:Create(
			startButton,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(50, 100, 150)}
		)
		tween:Play()
	end)

	-- Click handler
	startButton.MouseButton1Click:Connect(function()
		if not canInteract then return end

		canInteract = false
		print(string.format("[%s %s][Stage4] Player clicked 'Почати гру'", MODULE_NAME, VERSION))

		-- Send confirmation to server
		local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
		local confirmGameStart = remoteEvents:WaitForChild("ConfirmGameStart")
		confirmGameStart:FireServer()
	end)

	return container
end

-- ============================================================================
-- MAIN UI CREATION
-- ============================================================================

local function CreateScreenSaverUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "ScreenSaverUI"
	gui.DisplayOrder = 100
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- Create all stage containers
	stageContainers[0] = CreateStage0()
	stageContainers[1] = CreateStage1()
	stageContainers[2] = CreateStage2()
	stageContainers[3] = CreateStage3()
	stageContainers[4] = CreateStage4()

	for _, container in pairs(stageContainers) do
		container.Parent = gui
	end

	return gui
end

-- ============================================================================
-- INPUT HANDLING (Stage 0 only)
-- ============================================================================

local function OnInputBegan(input, gameProcessed)
	if gameProcessed then return end
	if not isVisible then return end
	if not canInteract then return end
	if currentStage ~= 0 then return end -- Only accept input on Stage 0

	if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
		ScreenSaverUI.RequestLogOn()
	end
end

-- ============================================================================
-- STAGE TRANSITIONS
-- ============================================================================

local function HideAllStages()
	for _, container in pairs(stageContainers) do
		container.Visible = false
	end
end

local function ShowStageWithTransition(stageNum)
	print(string.format("[%s %s][ShowStageWithTransition] Transitioning to Stage %d", MODULE_NAME, VERSION, stageNum))

	-- Fade out current stage
	if stageContainers[currentStage] then
		local fadeOut = TweenService:Create(
			stageContainers[currentStage],
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundTransparency = 1}
		)
		fadeOut:Play()
		fadeOut.Completed:Wait()
		stageContainers[currentStage].Visible = false
	end

	-- Show new stage
	if stageContainers[stageNum] then
		stageContainers[stageNum].BackgroundTransparency = 1
		stageContainers[stageNum].Visible = true

		local fadeIn = TweenService:Create(
			stageContainers[stageNum],
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{BackgroundTransparency = 0}
		)
		fadeIn:Play()
		fadeIn.Completed:Wait()
	end

	currentStage = stageNum
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
	canInteract = true

	-- Show Stage 0 by default
	HideAllStages()
	stageContainers[0].Visible = true
	currentStage = 0

	print(string.format("[%s %s][Show] ScreenSaver visible (Stage 0)", MODULE_NAME, VERSION))
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

function ScreenSaverUI.ShowStage(stageNum, stageData)
	print(string.format("[%s %s][ShowStage] Stage %d received with data", MODULE_NAME, VERSION, stageNum))

	-- Update stage-specific data
	if stageNum == 1 and stageData then
		local container = stageContainers[1]
		container:FindFirstChild("GameName").Text = stageData.gameName or "CALL OF RELICS"
		container:FindFirstChild("Subtitle").Text = stageData.gameSubtitle or "Orbital Silence"
		container:FindFirstChild("Version").Text = string.format("v%s - %s", stageData.version or "0.1", stageData.versionTag or "EPIC 1")
	end

	if stageNum == 2 and stageData then
		local container = stageContainers[2]
		container:FindFirstChild("PlayerName").Text = stageData.displayName or stageData.playerName or "Player"

		-- Load avatar asynchronously
		task.spawn(function()
			local success, thumbnail = pcall(function()
				return Players:GetUserThumbnailAsync(
					stageData.userId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size150x150
				)
			end)

			if success and thumbnail then
				container:FindFirstChild("AvatarFrame"):FindFirstChild("Avatar").Image = thumbnail
			else
				warn(string.format("[%s %s][ShowStage] Failed to load avatar thumbnail", MODULE_NAME, VERSION))
			end
		end)
	end

	if stageNum == 3 and stageData then
		local container = stageContainers[3]
		local statusText = container:FindFirstChild("StatusText")

		if stageData.success then
			if stageData.isNewPlayer then
				statusText.Text = "Ініціалізація експедиції..."
			else
				statusText.Text = "Відновлення експедиції..."
			end
		else
			statusText.Text = "Помилка завантаження профілю"
			statusText.TextColor3 = Color3.fromRGB(200, 100, 100)
		end
	end

	-- Transition to new stage
	ShowStageWithTransition(stageNum)
end

function ScreenSaverUI.RequestLogOn()
	print(string.format("[%s %s][RequestLogOn] Player requesting to enter game", MODULE_NAME, VERSION))

	canInteract = false -- Prevent double-clicks

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

	logOnEvent:FireServer()
	print(string.format("[%s %s][RequestLogOn] LogOn request sent to server", MODULE_NAME, VERSION))
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

return ScreenSaverUI
