--[[
================================================================================
KOSMICMAZER — EnginesUI
================================================================================

Purpose:
Engine control UI panel for "Seat Engines".
Retro IBM PC EGA CRT terminal style.
Displays ship energy status, engine state, and power consumption info.

Version:
0.3

Features:
- CRT monitor bezel with IBM PC EGA 16-color palette
- Energy bar with color-coded status
- Engine status indicator (ONLINE/STANDBY)
- Power consumption table for key actions
- Context-aware (Orbit: full panel, Surface: standby mode)
- CRT power-on/off animation via CanvasGroup

API:
- Initialize() — Create UI elements
- Show() — Display the UI with CRT power-on effect
- Hide() — Hide the UI with CRT power-off effect
- SetContext(context) — Set Orbit/Surface context

Calls to:
- SpaceShipConfig (ReplicatedStorage/Game)
- TransitionConfig (ReplicatedStorage/Game)

Called from:
- SeatUIManager.lua

Events:
- (none — read-only display, no server interaction yet)

Dependencies:
- TweenService
- SpaceShipConfig
- TransitionConfig

ChangeLog:
- 0.3: Retro CRT redesign — IBM PC EGA theme, centered layout, power-on animation (2026-02-06)
- 0.2: Functional UI with energy display, engine status, consumption table (2026-02-06)
- 0.1: Initial EnginesUI stub (2026-01-16)
================================================================================
]]

local EnginesUI = {}

local VERSION = "0.3"
local MODULE_NAME = "EnginesUI"

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

-- ============================================================================
-- IBM PC EGA 16-COLOR PALETTE
-- ============================================================================

local COLORS = {
	bezel = Color3.fromRGB(40, 40, 48),
	screenBg = Color3.fromRGB(0, 0, 40),
	cyan = Color3.fromRGB(85, 255, 255),
	darkCyan = Color3.fromRGB(0, 170, 170),
	yellow = Color3.fromRGB(255, 255, 85),
	green = Color3.fromRGB(85, 255, 85),
	darkGreen = Color3.fromRGB(0, 170, 0),
	red = Color3.fromRGB(255, 85, 85),
	brown = Color3.fromRGB(170, 85, 0),
	darkGray = Color3.fromRGB(85, 85, 85),
	lightGray = Color3.fromRGB(170, 170, 170),
	white = Color3.fromRGB(255, 255, 255),
	blue = Color3.fromRGB(0, 0, 170),
	rowBg = Color3.fromRGB(0, 0, 60),
	barBg = Color3.fromRGB(0, 0, 55),
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
local statusDot = nil
local statusLabel = nil
local energyBar = nil
local energyLabel = nil
local consumptionFrame = nil
local contextMsg = nil

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

local function CreateDivider(parent, yPos)
	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, -32, 0, 1)
	line.Position = UDim2.new(0, 16, 0, yPos)
	line.BackgroundColor3 = COLORS.darkGray
	line.BackgroundTransparency = 0.4
	line.BorderSizePixel = 0
	line.Parent = parent
end

local function CreateConsumptionRow(parent, label, value, yPos)
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
	lbl.Size = UDim2.new(0.65, 0, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = COLORS.darkCyan
	lbl.TextSize = 13
	lbl.Font = Enum.Font.RobotoMono
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local val = Instance.new("TextLabel")
	val.Size = UDim2.new(0.3, 0, 1, 0)
	val.Position = UDim2.new(0.68, 0, 0, 0)
	val.BackgroundTransparency = 1
	val.Text = tostring(value)
	val.TextColor3 = COLORS.cyan
	val.TextSize = 13
	val.Font = Enum.Font.RobotoMono
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.Parent = row
end

local function GetEnergyColor(ratio)
	if ratio > 0.5 then return COLORS.darkGreen end
	if ratio > 0.2 then return COLORS.brown end
	return COLORS.red
end

local function UpdateEnergyDisplay()
	local energy = SpaceShipConfig.GetEnergy()
	local current = energy.currentEnergy
	local max = energy.maxEnergy
	local ratio = current / max

	if energyBar then
		TweenService:Create(energyBar, TweenInfo.new(0.3), {
			Size = UDim2.new(ratio, 0, 1, 0),
			BackgroundColor3 = GetEnergyColor(ratio),
		}):Play()
	end

	if energyLabel then
		energyLabel.Text = string.format("%d / %d", current, max)
	end
end

local function ShowOrbitContent()
	if statusDot then statusDot.BackgroundColor3 = COLORS.green end
	if statusLabel then
		statusLabel.Text = "ONLINE"
		statusLabel.TextColor3 = COLORS.green
	end
	if contextMsg then contextMsg.Visible = false end
	if consumptionFrame then consumptionFrame.Visible = true end
	UpdateEnergyDisplay()
end

local function ShowSurfaceContent()
	if statusDot then statusDot.BackgroundColor3 = COLORS.brown end
	if statusLabel then
		statusLabel.Text = "STANDBY"
		statusLabel.TextColor3 = COLORS.brown
	end
	if contextMsg then contextMsg.Visible = true end
	if consumptionFrame then consumptionFrame.Visible = false end
	UpdateEnergyDisplay()
end

local function CreateUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "EnginesUI"
	gui.DisplayOrder = 61
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- ========== CRT BEZEL ==========

	local bezel = Instance.new("CanvasGroup")
	bezel.Name = "EnginesPanel"
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
	bezelStroke.Color = COLORS.darkGray
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
	termId.Text = "KM-DV/01"
	termId.TextColor3 = COLORS.darkGray
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
	screenStroke.Color = COLORS.blue
	screenStroke.Thickness = 1
	screenStroke.Transparency = 0.5
	screenStroke.Parent = screen

	-- ========== CONTENT ==========

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.55, 0, 0, 28)
	title.Position = UDim2.new(0, 16, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "ДВИГУНИ"
	title.TextColor3 = COLORS.yellow
	title.TextSize = 18
	title.Font = Enum.Font.RobotoMono
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = screen

	-- Status dot
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 8, 0, 8)
	dot.Position = UDim2.new(1, -118, 0, 20)
	dot.BackgroundColor3 = COLORS.green
	dot.BorderSizePixel = 0
	dot.Parent = screen
	statusDot = dot

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = dot

	-- Status label
	local sLabel = Instance.new("TextLabel")
	sLabel.Size = UDim2.new(0, 100, 0, 22)
	sLabel.Position = UDim2.new(1, -106, 0, 14)
	sLabel.BackgroundTransparency = 1
	sLabel.Text = "ONLINE"
	sLabel.TextColor3 = COLORS.green
	sLabel.TextSize = 14
	sLabel.Font = Enum.Font.RobotoMono
	sLabel.TextXAlignment = Enum.TextXAlignment.Left
	sLabel.Parent = screen
	statusLabel = sLabel

	CreateDivider(screen, 42)

	-- Energy header
	local energyTitle = Instance.new("TextLabel")
	energyTitle.Size = UDim2.new(0.45, 0, 0, 20)
	energyTitle.Position = UDim2.new(0, 16, 0, 50)
	energyTitle.BackgroundTransparency = 1
	energyTitle.Text = "ЕНЕРГIЯ"
	energyTitle.TextColor3 = COLORS.darkCyan
	energyTitle.TextSize = 13
	energyTitle.Font = Enum.Font.RobotoMono
	energyTitle.TextXAlignment = Enum.TextXAlignment.Left
	energyTitle.Parent = screen

	-- Energy value
	local eLbl = Instance.new("TextLabel")
	eLbl.Size = UDim2.new(0.5, 0, 0, 20)
	eLbl.Position = UDim2.new(0.48, 0, 0, 50)
	eLbl.BackgroundTransparency = 1
	eLbl.Text = "1000 / 1000"
	eLbl.TextColor3 = COLORS.cyan
	eLbl.TextSize = 14
	eLbl.Font = Enum.Font.RobotoMono
	eLbl.TextXAlignment = Enum.TextXAlignment.Right
	eLbl.Parent = screen
	energyLabel = eLbl

	-- Energy bar
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -32, 0, 14)
	barBg.Position = UDim2.new(0, 16, 0, 74)
	barBg.BackgroundColor3 = COLORS.barBg
	barBg.BorderSizePixel = 0
	barBg.Parent = screen

	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(0, 4)
	barBgCorner.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = COLORS.darkGreen
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	energyBar = barFill

	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(0, 4)
	barFillCorner.Parent = barFill

	CreateDivider(screen, 96)

	-- Context message (surface only)
	local cMsg = Instance.new("TextLabel")
	cMsg.Size = UDim2.new(1, -32, 0, 120)
	cMsg.Position = UDim2.new(0, 16, 0, 120)
	cMsg.BackgroundTransparency = 1
	cMsg.Text = "ДВИГУНИ В РЕЖИМI\nОЧIКУВАННЯ"
	cMsg.TextColor3 = COLORS.brown
	cMsg.TextSize = 18
	cMsg.Font = Enum.Font.RobotoMono
	cMsg.TextWrapped = true
	cMsg.TextYAlignment = Enum.TextYAlignment.Center
	cMsg.Visible = false
	cMsg.Parent = screen
	contextMsg = cMsg

	-- ========== CONSUMPTION SECTION ==========

	local cFrame = Instance.new("Frame")
	cFrame.Name = "ConsumptionFrame"
	cFrame.Size = UDim2.new(1, 0, 0, 280)
	cFrame.Position = UDim2.new(0, 0, 0, 104)
	cFrame.BackgroundTransparency = 1
	cFrame.Parent = screen
	consumptionFrame = cFrame

	local cTitle = Instance.new("TextLabel")
	cTitle.Size = UDim2.new(1, -32, 0, 20)
	cTitle.Position = UDim2.new(0, 16, 0, 4)
	cTitle.BackgroundTransparency = 1
	cTitle.Text = "ВИТРАТИ ЕНЕРГII"
	cTitle.TextColor3 = COLORS.yellow
	cTitle.TextSize = 13
	cTitle.Font = Enum.Font.RobotoMono
	cTitle.TextXAlignment = Enum.TextXAlignment.Left
	cTitle.Parent = cFrame

	local consumption = SpaceShipConfig.GetEnergy().consumption
	CreateConsumptionRow(cFrame, "Рух", consumption.moving .. "/с", 30)
	CreateConsumptionRow(cFrame, "Прискорення", consumption.boost .. "/с", 58)
	CreateConsumptionRow(cFrame, "Сканування", tostring(consumption.scan), 86)
	CreateConsumptionRow(cFrame, "Посадка", tostring(consumption.landing), 114)
	CreateConsumptionRow(cFrame, "Злiт", tostring(consumption.launch), 142)
	CreateConsumptionRow(cFrame, "Мiжпланетний", tostring(consumption.interplanetary), 170)

	CreateDivider(cFrame, 202)

	local energy = SpaceShipConfig.GetEnergy()
	local regenInfo = Instance.new("TextLabel")
	regenInfo.Size = UDim2.new(1, -32, 0, 20)
	regenInfo.Position = UDim2.new(0, 16, 0, 212)
	regenInfo.BackgroundTransparency = 1
	regenInfo.Text = string.format("Регенерацiя: %d/с (затр. %.1fс)", energy.regenRate, energy.regenDelay)
	regenInfo.TextColor3 = COLORS.darkCyan
	regenInfo.TextSize = 12
	regenInfo.Font = Enum.Font.RobotoMono
	regenInfo.TextXAlignment = Enum.TextXAlignment.Left
	regenInfo.Parent = cFrame

	return gui
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function EnginesUI.Initialize()
	if isInitialized then return true end

	screenGui = CreateUI()
	screenGui.Parent = playerGui
	screenGui.Enabled = false

	isInitialized = true
	print(string.format("[%s %s] Initialized", MODULE_NAME, VERSION))
	return true
end

function EnginesUI.Show()
	if not screenGui then return end

	screenGui.Enabled = true
	isVisible = true

	if not currentContext then
		currentContext = TransitionConfig.Contexts.Orbit
	end

	if currentContext == TransitionConfig.Contexts.Orbit then
		ShowOrbitContent()
	else
		ShowSurfaceContent()
	end

	-- CRT Power On
	mainFrame.GroupTransparency = 1
	TweenService:Create(
		mainFrame,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{GroupTransparency = 0}
	):Play()
end

function EnginesUI.Hide()
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

function EnginesUI.IsVisible()
	return isVisible
end

function EnginesUI.SetContext(context)
	currentContext = context
	if isVisible then
		if context == TransitionConfig.Contexts.Orbit then
			ShowOrbitContent()
		else
			ShowSurfaceContent()
		end
	end
end

-- ============================================================================
-- RETURN
-- ============================================================================

return EnginesUI
