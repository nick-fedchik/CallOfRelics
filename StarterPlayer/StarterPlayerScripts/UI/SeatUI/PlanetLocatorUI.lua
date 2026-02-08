--[[
================================================================================
KOSMICMAZER — PlanetLocatorUI
================================================================================

Purpose:
Planet locator UI panel for "Seat Planet Locator".
Retro ZX Spectrum CRT terminal style.
Displays known planets, current planet, and discovery status.

Version:
0.4

Features:
- CRT monitor bezel with ZX Spectrum 8-color Sinclair palette
- Planet list with status badges (ПОТОЧНА/ВIДКРИТА/ЗАКРИТА)
- Current planet highlighted in bright cyan
- Planet info: name, type, locations count
- Context-aware (Orbit: full panel, Surface: limited info)
- Energy cost display for interplanetary travel
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
- PlanetConfig (ReplicatedStorage/Game)

Called from:
- SeatUIManager.lua

Events:
- (none — read-only display, no server interaction yet)

Dependencies:
- TweenService
- SpaceShipConfig
- TransitionConfig
- GameConfig
- PlanetConfig

ChangeLog:
- 0.4: Use PlanetConfig instead of hardcoded PLANETS table (2026-02-06)
- 0.3: Retro CRT redesign — ZX Spectrum theme, centered layout, power-on animation (2026-02-06)
- 0.2: Functional UI with planet list, status badges, travel cost (2026-02-06)
- 0.1: Initial PlanetLocatorUI stub (2026-01-16)
================================================================================
]]

local PlanetLocatorUI = {}

local VERSION = "0.4"
local MODULE_NAME = "PlanetLocatorUI"

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
local PlanetConfig = require(Game:WaitForChild("PlanetConfig"))

-- ============================================================================
-- ZX SPECTRUM SINCLAIR PALETTE
-- ============================================================================

local COLORS = {
	bezel = Color3.fromRGB(38, 38, 38),
	screenBg = Color3.fromRGB(0, 0, 0),
	white = Color3.fromRGB(215, 215, 215),
	brightWhite = Color3.fromRGB(255, 255, 255),
	cyan = Color3.fromRGB(0, 215, 215),
	brightCyan = Color3.fromRGB(0, 255, 255),
	yellow = Color3.fromRGB(215, 215, 0),
	brightYellow = Color3.fromRGB(255, 255, 0),
	green = Color3.fromRGB(0, 215, 0),
	brightGreen = Color3.fromRGB(0, 255, 0),
	magenta = Color3.fromRGB(215, 0, 215),
	brightMagenta = Color3.fromRGB(255, 0, 255),
	red = Color3.fromRGB(215, 0, 0),
	blue = Color3.fromRGB(0, 0, 215),
	brightBlue = Color3.fromRGB(0, 0, 255),
	border = Color3.fromRGB(0, 0, 180),
	rowBg = Color3.fromRGB(0, 0, 48),
	rowCurrentBg = Color3.fromRGB(0, 48, 48),
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
-- PLANET REGISTRY
-- ============================================================================

local PLANETS = PlanetConfig.GetAllPlanets()

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
local contextMsg = nil
local planetListFrame = nil

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

local function CreateDivider(parent, yPos)
	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, -32, 0, 1)
	line.Position = UDim2.new(0, 16, 0, yPos)
	line.BackgroundColor3 = COLORS.blue
	line.BackgroundTransparency = 0.3
	line.BorderSizePixel = 0
	line.Parent = parent
end

local function GetStatusBadge(status)
	if status == "current" then
		return "ПОТОЧНА", COLORS.brightCyan
	elseif status == "discovered" then
		return "ВIДКРИТА", COLORS.brightGreen
	else
		return "ЗАКРИТА", COLORS.magenta
	end
end

local function CreatePlanetRow(parent, planet, yPos)
	local badgeText, badgeColor = GetStatusBadge(planet.status)
	local isCurrent = planet.status == "current"

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -32, 0, 52)
	row.Position = UDim2.new(0, 16, 0, yPos)
	row.BackgroundColor3 = isCurrent and COLORS.rowCurrentBg or COLORS.rowBg
	row.BackgroundTransparency = 0.3
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = row

	if isCurrent then
		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = COLORS.cyan
		rowStroke.Thickness = 1
		rowStroke.Transparency = 0.5
		rowStroke.Parent = row
	end

	-- Planet name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, 0, 0, 22)
	nameLabel.Position = UDim2.new(0, 10, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = planet.name
	nameLabel.TextColor3 = isCurrent and COLORS.brightCyan or COLORS.white
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.Code
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	-- Status badge
	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.new(0, 80, 0, 16)
	badge.Position = UDim2.new(1, -90, 0, 7)
	badge.BackgroundColor3 = badgeColor
	badge.BackgroundTransparency = 0.75
	badge.Text = badgeText
	badge.TextColor3 = badgeColor
	badge.TextSize = 10
	badge.Font = Enum.Font.Code
	badge.Parent = row

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 3)
	badgeCorner.Parent = badge

	-- Planet info
	local infoText = string.format("%s  |  %s  |  Лок: %d", planet.type, planet.physical.gravity, planet.locations)
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, -20, 0, 16)
	infoLabel.Position = UDim2.new(0, 10, 0, 30)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = infoText
	infoLabel.TextColor3 = COLORS.cyan
	infoLabel.TextSize = 11
	infoLabel.Font = Enum.Font.Code
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = row
end

local function ShowOrbitUI()
	if statusDot then statusDot.BackgroundColor3 = COLORS.brightGreen end
	if statusLabel then
		statusLabel.Text = "АКТИВНИЙ"
		statusLabel.TextColor3 = COLORS.brightGreen
	end
	if contextMsg then contextMsg.Visible = false end
	if planetListFrame then planetListFrame.Visible = true end
end

local function ShowSurfaceUI()
	if statusDot then statusDot.BackgroundColor3 = COLORS.yellow end
	if statusLabel then
		statusLabel.Text = "ОБМЕЖЕНИЙ"
		statusLabel.TextColor3 = COLORS.yellow
	end
	if contextMsg then
		contextMsg.Text = "Повний доступ лише на орбiтi"
		contextMsg.Visible = true
	end
	if planetListFrame then planetListFrame.Visible = false end
end

local function CreateUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PlanetLocatorUI"
	gui.DisplayOrder = 62
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- ========== CRT BEZEL ==========

	local bezel = Instance.new("CanvasGroup")
	bezel.Name = "LocatorPanel"
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
	led.BackgroundColor3 = COLORS.brightCyan
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
	termId.Text = "KM-NV/01"
	termId.TextColor3 = COLORS.border
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
	screenStroke.Color = COLORS.border
	screenStroke.Thickness = 1
	screenStroke.Transparency = 0.5
	screenStroke.Parent = screen

	-- ========== CONTENT ==========

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.5, 0, 0, 28)
	title.Position = UDim2.new(0, 16, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "ЛОКАТОР"
	title.TextColor3 = COLORS.brightWhite
	title.TextSize = 18
	title.Font = Enum.Font.Code
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = screen

	-- Status dot
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 8, 0, 8)
	dot.Position = UDim2.new(1, -128, 0, 20)
	dot.BackgroundColor3 = COLORS.brightGreen
	dot.BorderSizePixel = 0
	dot.Parent = screen
	statusDot = dot

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = dot

	-- Status label
	local sLabel = Instance.new("TextLabel")
	sLabel.Size = UDim2.new(0, 110, 0, 22)
	sLabel.Position = UDim2.new(1, -116, 0, 14)
	sLabel.BackgroundTransparency = 1
	sLabel.Text = "АКТИВНИЙ"
	sLabel.TextColor3 = COLORS.brightGreen
	sLabel.TextSize = 14
	sLabel.Font = Enum.Font.Code
	sLabel.TextXAlignment = Enum.TextXAlignment.Left
	sLabel.Parent = screen
	statusLabel = sLabel

	CreateDivider(screen, 42)

	-- Current planet header
	local currentTitle = Instance.new("TextLabel")
	currentTitle.Size = UDim2.new(0.55, 0, 0, 20)
	currentTitle.Position = UDim2.new(0, 16, 0, 50)
	currentTitle.BackgroundTransparency = 1
	currentTitle.Text = "ПОТОЧНА ПЛАНЕТА"
	currentTitle.TextColor3 = COLORS.cyan
	currentTitle.TextSize = 13
	currentTitle.Font = Enum.Font.Code
	currentTitle.TextXAlignment = Enum.TextXAlignment.Left
	currentTitle.Parent = screen

	-- Current planet name
	local currentPlanet = nil
	for _, p in ipairs(PLANETS) do
		if p.status == "current" then
			currentPlanet = p
			break
		end
	end

	local planetName = Instance.new("TextLabel")
	planetName.Size = UDim2.new(0.45, 0, 0, 22)
	planetName.Position = UDim2.new(0.53, 0, 0, 49)
	planetName.BackgroundTransparency = 1
	planetName.Text = currentPlanet and currentPlanet.name or "---"
	planetName.TextColor3 = COLORS.brightCyan
	planetName.TextSize = 14
	planetName.Font = Enum.Font.Code
	planetName.TextXAlignment = Enum.TextXAlignment.Right
	planetName.Parent = screen

	CreateDivider(screen, 74)

	-- Context message (surface only)
	local cMsg = Instance.new("TextLabel")
	cMsg.Size = UDim2.new(1, -32, 0, 120)
	cMsg.Position = UDim2.new(0, 16, 0, 100)
	cMsg.BackgroundTransparency = 1
	cMsg.Text = "Повний доступ\nлише на орбiтi"
	cMsg.TextColor3 = COLORS.yellow
	cMsg.TextSize = 18
	cMsg.Font = Enum.Font.Code
	cMsg.TextWrapped = true
	cMsg.TextYAlignment = Enum.TextYAlignment.Center
	cMsg.Visible = false
	cMsg.Parent = screen
	contextMsg = cMsg

	-- ========== PLANET LIST SECTION ==========

	local pFrame = Instance.new("Frame")
	pFrame.Name = "PlanetListFrame"
	pFrame.Size = UDim2.new(1, 0, 0, 300)
	pFrame.Position = UDim2.new(0, 0, 0, 82)
	pFrame.BackgroundTransparency = 1
	pFrame.Parent = screen
	planetListFrame = pFrame

	local listTitle = Instance.new("TextLabel")
	listTitle.Size = UDim2.new(1, -32, 0, 20)
	listTitle.Position = UDim2.new(0, 16, 0, 0)
	listTitle.BackgroundTransparency = 1
	listTitle.Text = "ЗIРКОВI СИСТЕМИ"
	listTitle.TextColor3 = COLORS.brightYellow
	listTitle.TextSize = 13
	listTitle.Font = Enum.Font.Code
	listTitle.TextXAlignment = Enum.TextXAlignment.Left
	listTitle.Parent = pFrame

	-- Planet rows
	local yOffset = 26
	for _, planet in ipairs(PLANETS) do
		CreatePlanetRow(pFrame, planet, yOffset)
		yOffset = yOffset + 58
	end

	-- Travel cost
	local travelCost = SpaceShipConfig.GetEnergy().consumption.interplanetary
	local costInfo = Instance.new("TextLabel")
	costInfo.Size = UDim2.new(1, -32, 0, 18)
	costInfo.Position = UDim2.new(0, 16, 0, yOffset + 6)
	costInfo.BackgroundTransparency = 1
	costInfo.Text = string.format("Мiжпланетний перелiт: %d енергii", travelCost)
	costInfo.TextColor3 = COLORS.cyan
	costInfo.TextSize = 11
	costInfo.Font = Enum.Font.Code
	costInfo.TextXAlignment = Enum.TextXAlignment.Left
	costInfo.Parent = pFrame

	return gui
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function PlanetLocatorUI.Initialize()
	if isInitialized then return true end

	screenGui = CreateUI()
	screenGui.Parent = playerGui
	screenGui.Enabled = false

	isInitialized = true
	print(string.format("[%s %s] Initialized", MODULE_NAME, VERSION))
	return true
end

function PlanetLocatorUI.Show()
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

function PlanetLocatorUI.Hide()
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

function PlanetLocatorUI.IsVisible()
	return isVisible
end

function PlanetLocatorUI.SetContext(context)
	currentContext = context
	if isVisible then
		if context == TransitionConfig.Contexts.Orbit then
			ShowOrbitUI()
		else
			ShowSurfaceUI()
		end
	end
end

-- ============================================================================
-- RETURN
-- ============================================================================

return PlanetLocatorUI
