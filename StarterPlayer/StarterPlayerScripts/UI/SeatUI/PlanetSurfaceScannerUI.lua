--[[
================================================================================
KOSMICMAZER — PlanetSurfaceScannerUI
================================================================================

Purpose:
Planet surface scanning UI panel for "Seat Planet Surface Scanner".
Retro Atari 800 CRT terminal style.
Allows player to scan planet surface and discover new locations.

Version:
0.2

Features:
- CRT monitor bezel with Atari 800 warm color palette
- Scan button to start planet surface scan
- Progress bar during scanning
- List of discovered locations
- Context-aware (only active on Orbit)
- CRT power-on/off animation via CanvasGroup

API:
- Initialize() — Create UI elements
- Show() — Display the UI with CRT power-on effect
- Hide() — Hide the UI with CRT power-off effect
- SetContext(context) — Set Orbit/Surface context
- GetContext() — Get current context
- UpdateDiscovered(locations) — Update discovered locations list

Calls to:
- TransitionConfig (ReplicatedStorage/Game)
- RequestScan RemoteEvent
- ScanProgress RemoteEvent
- ScanComplete RemoteEvent

Called from:
- SeatUIManager.lua

Events:
- Fires: RequestScan (Client -> Server)
- Listens: ScanProgress (Server -> Client)
- Listens: ScanComplete (Server -> Client)

Dependencies:
- TweenService
- TransitionConfig
- RemoteEvents

ChangeLog:
- 0.2: Retro CRT redesign — Atari 800 theme, centered layout, power-on animation (2026-02-06)
- 0.1: Initial PlanetSurfaceScannerUI (2026-01-16)
================================================================================
]]

local PlanetSurfaceScannerUI = {}

local VERSION = "0.2"
local MODULE_NAME = "PlanetSurfaceScannerUI"

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local TransitionConfig = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("TransitionConfig"))

-- ============================================================================
-- ATARI 800 WARM PALETTE
-- ============================================================================

local COLORS = {
	bezel = Color3.fromRGB(35, 30, 42),
	screenBg = Color3.fromRGB(16, 12, 40),
	gold = Color3.fromRGB(220, 170, 50),
	orange = Color3.fromRGB(200, 120, 40),
	dimOrange = Color3.fromRGB(120, 80, 30),
	text = Color3.fromRGB(200, 200, 220),
	textDim = Color3.fromRGB(120, 115, 140),
	scanReady = Color3.fromRGB(80, 200, 100),
	scanActive = Color3.fromRGB(220, 170, 50),
	barBg = Color3.fromRGB(30, 25, 55),
	barFill = Color3.fromRGB(200, 120, 40),
	border = Color3.fromRGB(100, 70, 140),
	rowBg = Color3.fromRGB(25, 20, 50),
	buttonBg = Color3.fromRGB(140, 80, 30),
	buttonHover = Color3.fromRGB(180, 110, 40),
	successGreen = Color3.fromRGB(80, 200, 100),
	warnYellow = Color3.fromRGB(200, 180, 80),
}

-- ============================================================================
-- CRT DIMENSIONS
-- ============================================================================

local CRT = {
	width = 540,
	height = 504,
	padTop = 14,
	padSide = 14,
	padBottom = 28,
	cornerOuter = 16,
	cornerInner = 8,
}

-- ============================================================================
-- STATE
-- ============================================================================

local screenGui = nil
local isVisible = false
local isInitialized = false
local isScanning = false
local currentContext = nil

local mainFrame = nil
local statusDot = nil
local statusLabel = nil
local scanButton = nil
local progressFrame = nil
local progressBar = nil
local progressLabel = nil
local spinnerLabel = nil
local spinnerConnection = nil
local discoveredContainer = nil
local discoveredItems = {}
local contextMsg = nil
local orbitContent = nil

-- RemoteEvents
local remoteEvents = nil
local requestScan = nil
local scanProgress = nil
local scanComplete = nil

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

local function CreateDivider(parent, yPos)
	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, -32, 0, 1)
	line.Position = UDim2.new(0, 16, 0, yPos)
	line.BackgroundColor3 = COLORS.border
	line.BackgroundTransparency = 0.4
	line.BorderSizePixel = 0
	line.Parent = parent
end

local function ClearDiscoveredItems()
	for _, item in ipairs(discoveredItems) do
		if item and item.Parent then
			item:Destroy()
		end
	end
	discoveredItems = {}
end

local function CreateDiscoveredItem(location, index)
	local item = Instance.new("Frame")
	item.Name = "Discovered_" .. (location.id or index)
	item.Size = UDim2.new(1, -32, 0, 30)
	item.Position = UDim2.new(0, 16, 0, (index - 1) * 35)
	item.BackgroundColor3 = COLORS.rowBg
	item.BackgroundTransparency = 0.3
	item.BorderSizePixel = 0
	item.Parent = discoveredContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = item

	-- Check icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 25, 1, 0)
	icon.Position = UDim2.new(0, 5, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = ">"
	icon.TextColor3 = COLORS.scanReady
	icon.TextSize = 14
	icon.Font = Enum.Font.RobotoMono
	icon.Parent = item

	-- Location name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -35, 1, 0)
	nameLabel.Position = UDim2.new(0, 30, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = location.displayName or location.name or location.id
	nameLabel.TextColor3 = COLORS.text
	nameLabel.TextSize = 13
	nameLabel.Font = Enum.Font.RobotoMono
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = item

	return item
end

local function UpdateDiscoveredList(locations)
	ClearDiscoveredItems()

	if not locations or #locations == 0 then
		return
	end

	local containerHeight = #locations * 35
	discoveredContainer.Size = UDim2.new(1, 0, 0, containerHeight)

	for i, location in ipairs(locations) do
		local item = CreateDiscoveredItem(location, i)
		table.insert(discoveredItems, item)
	end
end

local SPINNER_FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function StartSpinner()
	if spinnerConnection then return end
	local frameIndex = 1
	spinnerConnection = game:GetService("RunService").Heartbeat:Connect(function()
		frameIndex = (frameIndex % #SPINNER_FRAMES) + 1
		if spinnerLabel then
			spinnerLabel.Text = SPINNER_FRAMES[frameIndex]
		end
	end)
end

local function StopSpinner()
	if spinnerConnection then
		spinnerConnection:Disconnect()
		spinnerConnection = nil
	end
	if spinnerLabel then
		spinnerLabel.Text = ""
	end
end

local function SetScanningState(scanning)
	isScanning = scanning

	if scanning then
		scanButton.Visible = false
		progressFrame.Visible = true
		statusLabel.Text = "СКАНУВАННЯ..."
		statusLabel.TextColor3 = COLORS.scanActive
		if statusDot then statusDot.BackgroundColor3 = COLORS.scanActive end
		StartSpinner()
	else
		scanButton.Visible = true
		progressFrame.Visible = false
		StopSpinner()
	end
end

local function UpdateProgress(progress, message)
	if progressBar then
		TweenService:Create(progressBar, TweenInfo.new(0.2), {
			Size = UDim2.new(progress, 0, 1, 0)
		}):Play()
	end

	if progressLabel then
		progressLabel.Text = message or string.format("%.0f%%", progress * 100)
	end
end

local function ShowOrbitUI()
	if statusDot then statusDot.BackgroundColor3 = COLORS.scanReady end
	if statusLabel then
		statusLabel.Text = "ГОТОВИЙ"
		statusLabel.TextColor3 = COLORS.scanReady
	end
	if contextMsg then contextMsg.Visible = false end
	if orbitContent then orbitContent.Visible = true end

	-- Restore scanning state if was scanning
	if isScanning then
		scanButton.Visible = false
		progressFrame.Visible = true
		statusLabel.Text = "СКАНУВАННЯ..."
		statusLabel.TextColor3 = COLORS.scanActive
		if statusDot then statusDot.BackgroundColor3 = COLORS.scanActive end
	else
		scanButton.Visible = true
		progressFrame.Visible = false
	end
end

local function ShowSurfaceUI()
	if statusDot then statusDot.BackgroundColor3 = COLORS.warnYellow end
	if statusLabel then
		statusLabel.Text = "НЕДОСТУПНИЙ"
		statusLabel.TextColor3 = COLORS.warnYellow
	end
	if contextMsg then contextMsg.Visible = true end
	if orbitContent then orbitContent.Visible = false end
end

local function CreateUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PlanetSurfaceScannerUI"
	gui.DisplayOrder = 61
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- ========== CRT BEZEL ==========

	local bezel = Instance.new("CanvasGroup")
	bezel.Name = "ScannerPanel"
	bezel.Size = UDim2.new(0, CRT.width, 0, CRT.height)
	bezel.AnchorPoint = Vector2.new(0.5, 0.5)
	bezel.Position = UDim2.new(0.5, 0, 0.5, 0)
	bezel.BackgroundColor3 = COLORS.bezel
	bezel.BackgroundTransparency = 0.05
	bezel.GroupTransparency = 1
	bezel.Parent = gui
	mainFrame = bezel

	local bezelCorner = Instance.new("UICorner")
	bezelCorner.CornerRadius = UDim.new(0, CRT.cornerOuter)
	bezelCorner.Parent = bezel

	local bezelStroke = Instance.new("UIStroke")
	bezelStroke.Color = COLORS.border
	bezelStroke.Thickness = 2
	bezelStroke.Parent = bezel

	-- Power LED
	local led = Instance.new("Frame")
	led.Size = UDim2.new(0, 6, 0, 6)
	led.Position = UDim2.new(0, 18, 1, -16)
	led.BackgroundColor3 = COLORS.gold
	led.BorderSizePixel = 0
	led.Parent = bezel

	local ledCorner = Instance.new("UICorner")
	ledCorner.CornerRadius = UDim.new(1, 0)
	ledCorner.Parent = led

	-- Terminal ID
	local termId = Instance.new("TextLabel")
	termId.Size = UDim2.new(0, 100, 0, 12)
	termId.Position = UDim2.new(1, -112, 1, -17)
	termId.BackgroundTransparency = 1
	termId.Text = "KM-SK/01"
	termId.TextColor3 = COLORS.border
	termId.TextSize = 9
	termId.Font = Enum.Font.RobotoMono
	termId.TextXAlignment = Enum.TextXAlignment.Right
	termId.Parent = bezel

	-- ========== CRT SCREEN ==========

	local screenH = CRT.height - CRT.padTop - CRT.padBottom
	local screen = Instance.new("Frame")
	screen.Name = "Screen"
	screen.Size = UDim2.new(1, -CRT.padSide * 2, 0, screenH)
	screen.Position = UDim2.new(0, CRT.padSide, 0, CRT.padTop)
	screen.BackgroundColor3 = COLORS.screenBg
	screen.BorderSizePixel = 0
	screen.ClipsDescendants = true
	screen.Parent = bezel

	local screenCorner = Instance.new("UICorner")
	screenCorner.CornerRadius = UDim.new(0, CRT.cornerInner)
	screenCorner.Parent = screen

	local screenStroke = Instance.new("UIStroke")
	screenStroke.Color = COLORS.border
	screenStroke.Thickness = 1
	screenStroke.Transparency = 0.5
	screenStroke.Parent = screen

	-- ========== CONTENT ==========

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.55, 0, 0, 28)
	title.Position = UDim2.new(0, 16, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "СКАНЕР ПОВЕРХНI"
	title.TextColor3 = COLORS.gold
	title.TextSize = 18
	title.Font = Enum.Font.RobotoMono
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = screen

	-- Status dot
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 8, 0, 8)
	dot.Position = UDim2.new(1, -118, 0, 20)
	dot.BackgroundColor3 = COLORS.scanReady
	dot.BorderSizePixel = 0
	dot.Parent = screen
	statusDot = dot

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = dot

	-- Status label
	local sLabel = Instance.new("TextLabel")
	sLabel.Size = UDim2.new(0, 110, 0, 22)
	sLabel.Position = UDim2.new(1, -106, 0, 14)
	sLabel.BackgroundTransparency = 1
	sLabel.Text = "ГОТОВИЙ"
	sLabel.TextColor3 = COLORS.scanReady
	sLabel.TextSize = 14
	sLabel.Font = Enum.Font.RobotoMono
	sLabel.TextXAlignment = Enum.TextXAlignment.Left
	sLabel.Parent = screen
	statusLabel = sLabel

	CreateDivider(screen, 42)

	-- Context message (surface only)
	local cMsg = Instance.new("TextLabel")
	cMsg.Size = UDim2.new(1, -32, 0, 120)
	cMsg.Position = UDim2.new(0, 16, 0, 120)
	cMsg.BackgroundTransparency = 1
	cMsg.Text = "СКАНЕР ДОСТУПНИЙ\nЛИШЕ З ОРБIТИ"
	cMsg.TextColor3 = COLORS.warnYellow
	cMsg.TextSize = 18
	cMsg.Font = Enum.Font.RobotoMono
	cMsg.TextWrapped = true
	cMsg.TextYAlignment = Enum.TextYAlignment.Center
	cMsg.Visible = false
	cMsg.Parent = screen
	contextMsg = cMsg

	-- ========== ORBIT CONTENT ==========

	local oContent = Instance.new("Frame")
	oContent.Name = "OrbitContent"
	oContent.Size = UDim2.new(1, 0, 1, -48)
	oContent.Position = UDim2.new(0, 0, 0, 48)
	oContent.BackgroundTransparency = 1
	oContent.Parent = screen
	orbitContent = oContent

	-- Scan status text
	local scanStatus = Instance.new("TextLabel")
	scanStatus.Size = UDim2.new(1, -32, 0, 20)
	scanStatus.Position = UDim2.new(0, 16, 0, 4)
	scanStatus.BackgroundTransparency = 1
	scanStatus.Text = "Готовий до сканування"
	scanStatus.TextColor3 = COLORS.textDim
	scanStatus.TextSize = 12
	scanStatus.Font = Enum.Font.RobotoMono
	scanStatus.TextXAlignment = Enum.TextXAlignment.Left
	scanStatus.Parent = oContent

	-- Scan button
	local scan = Instance.new("TextButton")
	scan.Name = "ScanButton"
	scan.Size = UDim2.new(1, -32, 0, 44)
	scan.Position = UDim2.new(0, 16, 0, 30)
	scan.BackgroundColor3 = COLORS.buttonBg
	scan.BorderSizePixel = 0
	scan.Text = "> СКАНУВАТИ ПОВЕРХНЮ"
	scan.TextColor3 = COLORS.text
	scan.TextSize = 15
	scan.Font = Enum.Font.RobotoMono
	scan.AutoButtonColor = false
	scan.Parent = oContent
	scanButton = scan

	local scanCorner = Instance.new("UICorner")
	scanCorner.CornerRadius = UDim.new(0, 6)
	scanCorner.Parent = scan

	local scanStroke = Instance.new("UIStroke")
	scanStroke.Color = COLORS.orange
	scanStroke.Thickness = 1
	scanStroke.Transparency = 0.5
	scanStroke.Parent = scan

	-- Scan hover effects
	scan.MouseEnter:Connect(function()
		if not isScanning then
			TweenService:Create(scan, TweenInfo.new(0.15), {
				BackgroundColor3 = COLORS.buttonHover
			}):Play()
		end
	end)

	scan.MouseLeave:Connect(function()
		TweenService:Create(scan, TweenInfo.new(0.15), {
			BackgroundColor3 = COLORS.buttonBg
		}):Play()
	end)

	-- Scan click handler
	scan.MouseButton1Click:Connect(function()
		if not isScanning and requestScan then
			requestScan:FireServer()
		end
	end)

	-- Progress frame (hidden by default)
	local progress = Instance.new("Frame")
	progress.Name = "ProgressFrame"
	progress.Size = UDim2.new(1, -32, 0, 44)
	progress.Position = UDim2.new(0, 16, 0, 30)
	progress.BackgroundColor3 = COLORS.rowBg
	progress.BackgroundTransparency = 0.3
	progress.BorderSizePixel = 0
	progress.Visible = false
	progress.Parent = oContent
	progressFrame = progress

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 6)
	progressCorner.Parent = progress

	-- Progress bar background
	local progressBg = Instance.new("Frame")
	progressBg.Size = UDim2.new(1, -20, 0, 12)
	progressBg.Position = UDim2.new(0, 10, 0, 8)
	progressBg.BackgroundColor3 = COLORS.barBg
	progressBg.BorderSizePixel = 0
	progressBg.Parent = progress

	local progressBgCorner = Instance.new("UICorner")
	progressBgCorner.CornerRadius = UDim.new(0, 4)
	progressBgCorner.Parent = progressBg

	-- Progress bar fill
	local progressFill = Instance.new("Frame")
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = COLORS.barFill
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg
	progressBar = progressFill

	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(0, 4)
	progressFillCorner.Parent = progressFill

	-- Spinner label (left side of progress area)
	local spinner = Instance.new("TextLabel")
	spinner.Size = UDim2.new(0, 24, 0, 16)
	spinner.Position = UDim2.new(0, 10, 0, 24)
	spinner.BackgroundTransparency = 1
	spinner.Text = ""
	spinner.TextColor3 = COLORS.scanActive
	spinner.TextSize = 14
	spinner.Font = Enum.Font.RobotoMono
	spinner.Parent = progress
	spinnerLabel = spinner

	-- Progress label (right of spinner)
	local progressText = Instance.new("TextLabel")
	progressText.Size = UDim2.new(1, -44, 0, 16)
	progressText.Position = UDim2.new(0, 34, 0, 24)
	progressText.BackgroundTransparency = 1
	progressText.Text = "0%"
	progressText.TextColor3 = COLORS.text
	progressText.TextSize = 12
	progressText.Font = Enum.Font.RobotoMono
	progressText.TextXAlignment = Enum.TextXAlignment.Left
	progressText.Parent = progress
	progressLabel = progressText

	CreateDivider(oContent, 82)

	-- Discovered title
	local dTitle = Instance.new("TextLabel")
	dTitle.Size = UDim2.new(1, -32, 0, 20)
	dTitle.Position = UDim2.new(0, 16, 0, 90)
	dTitle.BackgroundTransparency = 1
	dTitle.Text = "ВИЯВЛЕНI ЛОКАЦII"
	dTitle.TextColor3 = COLORS.gold
	dTitle.TextSize = 13
	dTitle.Font = Enum.Font.RobotoMono
	dTitle.TextXAlignment = Enum.TextXAlignment.Left
	dTitle.Parent = oContent
	discoveredTitle = dTitle

	-- Discovered container
	local discovered = Instance.new("ScrollingFrame")
	discovered.Name = "DiscoveredContainer"
	discovered.Size = UDim2.new(1, 0, 0, 200)
	discovered.Position = UDim2.new(0, 0, 0, 115)
	discovered.BackgroundTransparency = 1
	discovered.BorderSizePixel = 0
	discovered.ScrollBarThickness = 4
	discovered.ScrollBarImageColor3 = COLORS.border
	discovered.CanvasSize = UDim2.new(0, 0, 0, 0)
	discovered.AutomaticCanvasSize = Enum.AutomaticSize.Y
	discovered.Parent = oContent
	discoveredContainer = discovered

	return gui
end

local function SetupRemoteEvents()
	remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not remoteEvents then
		warn(string.format("[%s %s] RemoteEvents not found!", MODULE_NAME, VERSION))
		return
	end

	requestScan = remoteEvents:FindFirstChild("RequestScan")
	scanProgress = remoteEvents:FindFirstChild("ScanProgress")
	scanComplete = remoteEvents:FindFirstChild("ScanComplete")

	if scanProgress then
		scanProgress.OnClientEvent:Connect(function(progress, message)
			SetScanningState(true)
			UpdateProgress(progress, message)
		end)
	end

	if scanComplete then
		scanComplete.OnClientEvent:Connect(function(success, resultData, message)
			SetScanningState(false)

			if success then
				statusLabel.Text = "ЗНАЙДЕНО"
				statusLabel.TextColor3 = COLORS.successGreen
				if statusDot then statusDot.BackgroundColor3 = COLORS.successGreen end

				-- Parse discovered list from resultData
				if resultData and resultData.discovered then
					UpdateDiscoveredList(resultData.discovered)
				end
			else
				statusLabel.Text = "ПОРОЖНЬО"
				statusLabel.TextColor3 = COLORS.warnYellow
				if statusDot then statusDot.BackgroundColor3 = COLORS.warnYellow end
			end

			-- Show server message in scan status area
			if message and progressLabel then
				progressFrame.Visible = true
				progressBar.Size = UDim2.new(0, 0, 1, 0)
				progressLabel.Text = message
				progressLabel.TextColor3 = success and COLORS.successGreen or COLORS.warnYellow
			end

			task.delay(5, function()
				if statusLabel and not isScanning then
					statusLabel.Text = "ГОТОВИЙ"
					statusLabel.TextColor3 = COLORS.scanReady
					if statusDot then statusDot.BackgroundColor3 = COLORS.scanReady end
					if progressFrame then progressFrame.Visible = false end
				end
			end)
		end)
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function PlanetSurfaceScannerUI.Initialize()
	if isInitialized then return true end

	screenGui = CreateUI()
	screenGui.Parent = playerGui
	screenGui.Enabled = false

	SetupRemoteEvents()

	isInitialized = true
	print(string.format("[%s %s] Initialized", MODULE_NAME, VERSION))
	return true
end

function PlanetSurfaceScannerUI.Show()
	if not screenGui then return end

	screenGui.Enabled = true
	isVisible = true

	if not currentContext then
		currentContext = TransitionConfig.Contexts.Orbit
	end

	if currentContext == TransitionConfig.Contexts.Orbit then
		ShowOrbitUI()
	else
		ShowSurfaceUI()
	end

	-- CRT Power On
	mainFrame.GroupTransparency = 1
	TweenService:Create(
		mainFrame,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{GroupTransparency = 0}
	):Play()
end

function PlanetSurfaceScannerUI.Hide()
	if not screenGui then return end

	-- CRT Power Off
	TweenService:Create(
		mainFrame,
		TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{GroupTransparency = 1}
	):Play()

	task.delay(0.12, function()
		if screenGui then
			screenGui.Enabled = false
		end
	end)

	isVisible = false
end

function PlanetSurfaceScannerUI.IsVisible()
	return isVisible
end

function PlanetSurfaceScannerUI.SetContext(context)
	currentContext = context

	if isVisible then
		if context == TransitionConfig.Contexts.Orbit then
			ShowOrbitUI()
		else
			ShowSurfaceUI()
		end
	end
end

function PlanetSurfaceScannerUI.GetContext()
	return currentContext
end

function PlanetSurfaceScannerUI.UpdateDiscovered(locations)
	UpdateDiscoveredList(locations)
end

-- ============================================================================
-- RETURN
-- ============================================================================

return PlanetSurfaceScannerUI
