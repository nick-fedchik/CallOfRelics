--[[
================================================================================
KOSMICMAZER — PersonalComputerUI
================================================================================

Purpose:
Personal computer UI panel for "Seat Personal Computer".
Retro Apple II green phosphor CRT terminal style.
Displays operator profile, knowledge base stats, and mission overview.

Version:
0.3

Features:
- CRT monitor bezel with Apple II green phosphor monochrome palette
- Operator profile (callsign, ship name, class)
- Knowledge base counters (planets, locations, relics)
- Ship status summary (hull, shield bars)
- Mission overview section
- Context-aware badge (ОРБIТА/ПОВЕРХНЯ)
- CRT power-on/off animation via CanvasGroup

API:
- Initialize() — Create UI elements
- Show() — Display the UI with CRT power-on effect
- Hide() — Hide the UI with CRT power-off effect
- SetContext(context) — Set Orbit/Surface context

Calls to:
- SpaceShipConfig (ReplicatedStorage/Game)
- TransitionConfig (ReplicatedStorage/Game)
- GameConfig (ReplicatedStorage/Game)

Called from:
- SeatUIManager.lua

Events:
- (none — read-only display, no server interaction yet)

Dependencies:
- TweenService
- SpaceShipConfig
- TransitionConfig
- GameConfig

ChangeLog:
- 0.3: Retro CRT redesign — Apple II green phosphor theme, centered layout, power-on animation (2026-02-06)
- 0.2: Functional UI with operator info, knowledge stats, ship summary (2026-02-06)
- 0.1: Initial PersonalComputerUI stub (2026-01-16)
================================================================================
]]

local PersonalComputerUI = {}

local VERSION = "0.3"
local MODULE_NAME = "PersonalComputerUI"

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

local Game = ReplicatedStorage:WaitForChild("Game")
local SpaceShipConfig = require(Game:WaitForChild("SpaceShipConfig"))
local TransitionConfig = require(Game:WaitForChild("TransitionConfig"))
local GameConfig = require(Game:WaitForChild("GameConfig"))

-- ============================================================================
-- APPLE II GREEN PHOSPHOR PALETTE
-- ============================================================================

local COLORS = {
	bezel = Color3.fromRGB(36, 38, 36),
	screenBg = Color3.fromRGB(0, 8, 0),
	green = Color3.fromRGB(51, 255, 0),
	greenMid = Color3.fromRGB(35, 180, 0),
	greenDim = Color3.fromRGB(25, 120, 0),
	greenDark = Color3.fromRGB(12, 60, 0),
	barBg = Color3.fromRGB(8, 30, 0),
	rowBg = Color3.fromRGB(5, 20, 0),
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
local currentContext = nil

local mainFrame = nil
local contextLabel = nil

-- Dynamic stat labels (updated from profile)
local statLocations = nil
local statScans = nil
local statPlanets = nil
local statRelics = nil

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

local function CreateDivider(parent, yPos)
	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, -32, 0, 1)
	line.Position = UDim2.new(0, 16, 0, yPos)
	line.BackgroundColor3 = COLORS.greenDark
	line.BackgroundTransparency = 0.3
	line.BorderSizePixel = 0
	line.Parent = parent
end

local function CreateStatRow(parent, label, value, yPos)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -32, 0, 24)
	row.Position = UDim2.new(0, 16, 0, yPos)
	row.BackgroundColor3 = COLORS.rowBg
	row.BackgroundTransparency = 0.4
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.6, 0, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = COLORS.greenDim
	lbl.TextSize = 12
	lbl.Font = Enum.Font.Code
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local val = Instance.new("TextLabel")
	val.Name = "Value"
	val.Size = UDim2.new(0.35, 0, 1, 0)
	val.Position = UDim2.new(0.63, 0, 0, 0)
	val.BackgroundTransparency = 1
	val.Text = tostring(value)
	val.TextColor3 = COLORS.green
	val.TextSize = 12
	val.Font = Enum.Font.Code
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.Parent = row

	return val
end

local function CreateMiniBar(parent, label, ratio, yPos)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -32, 0, 28)
	row.Position = UDim2.new(0, 16, 0, yPos)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 60, 0, 14)
	lbl.Position = UDim2.new(0, 0, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = COLORS.greenDim
	lbl.TextSize = 11
	lbl.Font = Enum.Font.Code
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local pctLabel = Instance.new("TextLabel")
	pctLabel.Size = UDim2.new(0, 40, 0, 14)
	pctLabel.Position = UDim2.new(1, -40, 0, 0)
	pctLabel.BackgroundTransparency = 1
	pctLabel.Text = string.format("%d%%", ratio * 100)
	pctLabel.TextColor3 = COLORS.green
	pctLabel.TextSize = 11
	pctLabel.Font = Enum.Font.Code
	pctLabel.TextXAlignment = Enum.TextXAlignment.Right
	pctLabel.Parent = row

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, 0, 0, 8)
	barBg.Position = UDim2.new(0, 0, 0, 17)
	barBg.BackgroundColor3 = COLORS.barBg
	barBg.BorderSizePixel = 0
	barBg.Parent = row

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 4)
	bgCorner.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(ratio, 0, 1, 0)
	barFill.BackgroundColor3 = COLORS.green
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = barFill
end

local function UpdateContext()
	if not contextLabel then return end
	if currentContext == TransitionConfig.Contexts.Orbit then
		contextLabel.Text = "ОРБIТА"
	else
		contextLabel.Text = "ПОВЕРХНЯ"
	end
end

local function UpdateStats(profileData)
	if not profileData then return end

	local scanCount = 0
	if profileData.shipState and profileData.shipState.modules and profileData.shipState.modules.scanner then
		scanCount = profileData.shipState.modules.scanner.scanCount or 0
	end

	if statPlanets then statPlanets.Text = tostring(profileData.discoveredPlanetsCount or 1) end
	if statLocations then statLocations.Text = tostring(profileData.exploredCount or 0) end
	if statRelics then statRelics.Text = tostring(profileData.stats and profileData.stats.knowledgeDiscovered or 0) end
	if statScans then statScans.Text = tostring(scanCount) end
end

local function CreateUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PersonalComputerUI"
	gui.DisplayOrder = 63
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- ========== CRT BEZEL ==========

	local bezel = Instance.new("CanvasGroup")
	bezel.Name = "ComputerPanel"
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
	bezelStroke.Color = COLORS.greenDark
	bezelStroke.Thickness = 2
	bezelStroke.Parent = bezel

	-- Power LED
	local led = Instance.new("Frame")
	led.Size = UDim2.new(0, 6, 0, 6)
	led.Position = UDim2.new(0, 18, 1, -16)
	led.BackgroundColor3 = COLORS.green
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
	termId.Text = "KM-OP/01"
	termId.TextColor3 = COLORS.greenDark
	termId.TextSize = 9
	termId.Font = Enum.Font.Code
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
	screenStroke.Color = COLORS.greenDark
	screenStroke.Thickness = 1
	screenStroke.Transparency = 0.5
	screenStroke.Parent = screen

	-- ========== CONTENT ==========

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.55, 0, 0, 28)
	title.Position = UDim2.new(0, 16, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "ТЕРМIНАЛ"
	title.TextColor3 = COLORS.green
	title.TextSize = 18
	title.Font = Enum.Font.Code
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = screen

	-- Context badge
	local ctxLabel = Instance.new("TextLabel")
	ctxLabel.Size = UDim2.new(0, 90, 0, 18)
	ctxLabel.Position = UDim2.new(1, -100, 0, 15)
	ctxLabel.BackgroundColor3 = COLORS.greenDark
	ctxLabel.BackgroundTransparency = 0.5
	ctxLabel.Text = "ОРБIТА"
	ctxLabel.TextColor3 = COLORS.green
	ctxLabel.TextSize = 11
	ctxLabel.Font = Enum.Font.Code
	ctxLabel.Parent = screen
	contextLabel = ctxLabel

	local ctxCorner = Instance.new("UICorner")
	ctxCorner.CornerRadius = UDim.new(0, 3)
	ctxCorner.Parent = ctxLabel

	CreateDivider(screen, 42)

	-- ========== OPERATOR SECTION ==========

	local operatorTitle = Instance.new("TextLabel")
	operatorTitle.Size = UDim2.new(0.45, 0, 0, 20)
	operatorTitle.Position = UDim2.new(0, 16, 0, 50)
	operatorTitle.BackgroundTransparency = 1
	operatorTitle.Text = "ОПЕРАТОР"
	operatorTitle.TextColor3 = COLORS.greenDim
	operatorTitle.TextSize = 13
	operatorTitle.Font = Enum.Font.Code
	operatorTitle.TextXAlignment = Enum.TextXAlignment.Left
	operatorTitle.Parent = screen

	local operatorName = Instance.new("TextLabel")
	operatorName.Size = UDim2.new(0.5, 0, 0, 22)
	operatorName.Position = UDim2.new(0.48, 0, 0, 49)
	operatorName.BackgroundTransparency = 1
	operatorName.Text = LocalPlayer.DisplayName
	operatorName.TextColor3 = COLORS.green
	operatorName.TextSize = 14
	operatorName.Font = Enum.Font.Code
	operatorName.TextXAlignment = Enum.TextXAlignment.Right
	operatorName.Parent = screen

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(1, -32, 0, 16)
	rankLabel.Position = UDim2.new(0, 16, 0, 70)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = string.format("Корабель: %s  |  Клас: Дослiдник", GameConfig.ShipName)
	rankLabel.TextColor3 = COLORS.greenDim
	rankLabel.TextSize = 11
	rankLabel.Font = Enum.Font.Code
	rankLabel.TextXAlignment = Enum.TextXAlignment.Left
	rankLabel.Parent = screen

	CreateDivider(screen, 92)

	-- ========== KNOWLEDGE SECTION ==========

	local knowledgeTitle = Instance.new("TextLabel")
	knowledgeTitle.Size = UDim2.new(1, -32, 0, 20)
	knowledgeTitle.Position = UDim2.new(0, 16, 0, 100)
	knowledgeTitle.BackgroundTransparency = 1
	knowledgeTitle.Text = "БАЗА ЗНАНЬ"
	knowledgeTitle.TextColor3 = COLORS.greenDim
	knowledgeTitle.TextSize = 13
	knowledgeTitle.Font = Enum.Font.Code
	knowledgeTitle.TextXAlignment = Enum.TextXAlignment.Left
	knowledgeTitle.Parent = screen

	statPlanets = CreateStatRow(screen, "Планети вiдкритi", "...", 122)
	statLocations = CreateStatRow(screen, "Локацii дослiдженi", "...", 150)
	statRelics = CreateStatRow(screen, "Релiквii знайденi", "...", 178)
	statScans = CreateStatRow(screen, "Сканувань проведено", "...", 206)

	CreateDivider(screen, 238)

	-- ========== SHIP STATUS SECTION ==========

	local shipTitle = Instance.new("TextLabel")
	shipTitle.Size = UDim2.new(1, -32, 0, 20)
	shipTitle.Position = UDim2.new(0, 16, 0, 246)
	shipTitle.BackgroundTransparency = 1
	shipTitle.Text = "СТАН КОРАБЛЯ"
	shipTitle.TextColor3 = COLORS.greenDim
	shipTitle.TextSize = 13
	shipTitle.Font = Enum.Font.Code
	shipTitle.TextXAlignment = Enum.TextXAlignment.Left
	shipTitle.Parent = screen

	CreateMiniBar(screen, "КОРПУС", 1.0, 268)
	CreateMiniBar(screen, "ЩИТ", 1.0, 300)

	-- Ship specs
	local defense = SpaceShipConfig.GetDefense()
	local specsLabel = Instance.new("TextLabel")
	specsLabel.Size = UDim2.new(1, -32, 0, 16)
	specsLabel.Position = UDim2.new(0, 16, 0, 334)
	specsLabel.BackgroundTransparency = 1
	specsLabel.Text = string.format(
		"Корпус: %d  |  Щит: %d  |  Швидкiсть: %d",
		defense.maxHull,
		defense.maxShield,
		SpaceShipConfig.GetSpeed().maxSpeed
	)
	specsLabel.TextColor3 = COLORS.greenDim
	specsLabel.TextSize = 11
	specsLabel.Font = Enum.Font.Code
	specsLabel.TextXAlignment = Enum.TextXAlignment.Left
	specsLabel.Parent = screen

	CreateDivider(screen, 356)

	-- Mission status
	local missionLabel = Instance.new("TextLabel")
	missionLabel.Size = UDim2.new(1, -32, 0, 20)
	missionLabel.Position = UDim2.new(0, 16, 0, 362)
	missionLabel.BackgroundTransparency = 1
	missionLabel.Text = "Мiсiя: Дослiдження планети Бiллi Рубiн"
	missionLabel.TextColor3 = COLORS.green
	missionLabel.TextSize = 11
	missionLabel.Font = Enum.Font.Code
	missionLabel.TextXAlignment = Enum.TextXAlignment.Left
	missionLabel.TextWrapped = true
	missionLabel.Parent = screen

	return gui
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function PersonalComputerUI.Initialize()
	if isInitialized then return true end

	screenGui = CreateUI()
	screenGui.Parent = playerGui
	screenGui.Enabled = false

	-- Listen for profile updates from server
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if remoteEvents then
		local profileUpdate = remoteEvents:FindFirstChild("ProfileUpdate")
		if profileUpdate then
			profileUpdate.OnClientEvent:Connect(function(data)
				if data and data.type == "fullSync" and data.profile then
					UpdateStats(data.profile)
				end
			end)
		end
	end

	isInitialized = true
	print(string.format("[%s %s] Initialized", MODULE_NAME, VERSION))
	return true
end

function PersonalComputerUI.Show()
	if not screenGui then return end

	screenGui.Enabled = true
	isVisible = true

	if not currentContext then
		currentContext = TransitionConfig.Contexts.Orbit
	end

	UpdateContext()

	-- Request fresh profile data from server
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local requestSync = remoteEvents:FindFirstChild("RequestProfileSync")
		if requestSync then
			requestSync:FireServer()
		end
	end

	-- CRT Power On
	mainFrame.GroupTransparency = 1
	TweenService:Create(
		mainFrame,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{GroupTransparency = 0}
	):Play()
end

function PersonalComputerUI.Hide()
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

function PersonalComputerUI.IsVisible()
	return isVisible
end

function PersonalComputerUI.SetContext(context)
	currentContext = context
	if isVisible then
		UpdateContext()
	end
end

-- ============================================================================
-- RETURN
-- ============================================================================

return PersonalComputerUI
