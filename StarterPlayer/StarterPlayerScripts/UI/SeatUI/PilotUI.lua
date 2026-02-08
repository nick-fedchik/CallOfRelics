--[[
================================================================================
KOSMICMAZER — PilotUI
================================================================================

Purpose:
Navigation UI panel for pilot seat. Shows landing/launch options.
Context-aware: shows landing options on Orbit, launch option on Surface.

Version:
0.8

Features:
- Planet name and abbreviated characteristics at top
- Navigation menu (renamed from "Пілотське крісло")
- Context detection (Orbit/Surface)
- Landing menu with available locations (Orbit)
- Launch button (Surface)
- Integration with TransitionService
- DisplayName localization for locations

API:
- Initialize() — Create UI elements
- Show() — Display the UI
- Hide() — Hide the UI
- SetContext(context) — Set Orbit/Surface context
- UpdateLocations(locations) — Update location list

Calls to:
- TransitionConfig (ReplicatedStorage/Game)
- PlanetConfig (ReplicatedStorage/Game)
- GameConfig (ReplicatedStorage/Game)
- RequestLanding RemoteEvent
- RequestLaunch RemoteEvent
- RequestAvailableLocations RemoteEvent

Called from:
- SeatUIManager.lua

Events:
- Fires: RequestLanding (Client → Server)
- Fires: RequestLaunch (Client → Server)
- Fires: RequestAvailableLocations (Client → Server)
- Listens: AvailableLocationsResponse (Server → Client)
- Listens: TransitionUpdate (Server → Client)

Dependencies:
- TweenService
- TransitionConfig
- PlanetConfig
- GameConfig
- RemoteEvents

ChangeLog:
- 0.8: Added planet name and abbreviated characteristics at top (2026-02-06)
- 0.7: Rename Liftoff → Launch (RequestLaunch, launchButton) (2026-01-15)
- 0.6: Renamed to "Навігація", removed status text on Surface (2026-01-15)
- 0.5: Added displayName support for locations (2026-01-14)
- 0.4: Fixed context detection on Show() (2026-01-14)
- 0.3: Added location list from server (2026-01-14)
- 0.2: Added context-aware menus for landing/liftoff (2026-01-14)
- 0.1: Initial PilotUI (2026-01-13)
================================================================================
]]

local PilotUI = {}

local VERSION = "0.8"
local MODULE_NAME = "PilotUI"

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
local TransitionConfig = require(Game:WaitForChild("TransitionConfig"))
local PlanetConfig = require(Game:WaitForChild("PlanetConfig"))
local GameConfig = require(Game:WaitForChild("GameConfig"))

-- ============================================================================
-- STATE
-- ============================================================================

local screenGui = nil
local isVisible = false
local isInitialized = false
local currentContext = nil -- "Orbit" or "Surface"
local availableLocations = {}

-- UI Elements
local mainFrame = nil
local titleLabel = nil
local statusLabel = nil
local locationsContainer = nil
local launchButton = nil
local locationButtons = {}
local currentPlanetId = nil
local planetNameLabel = nil
local charLine1 = nil
local charLine2 = nil

-- RemoteEvents
local remoteEvents = nil
local requestLanding = nil
local requestLaunch = nil
local requestLocations = nil
local locationsAvailable = nil
local transitionUpdate = nil

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

local function ClearLocationButtons()
	for _, button in ipairs(locationButtons) do
		if button and button.Parent then
			button:Destroy()
		end
	end
	locationButtons = {}
end

local function CreateLocationButton(location, index)
	local button = Instance.new("TextButton")
	button.Name = "Location_" .. location.id
	button.Size = UDim2.new(1, -20, 0, 36)
	button.Position = UDim2.new(0, 10, 0, 5 + (index - 1) * 42)
	button.BackgroundColor3 = Color3.fromRGB(40, 60, 90)
	button.BackgroundTransparency = 0.3
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = locationsContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 30, 1, 0)
	icon.Position = UDim2.new(0, 5, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "📍"
	icon.TextSize = 18
	icon.Parent = button

	-- Location name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -80, 0, 20)
	nameLabel.Position = UDim2.new(0, 35, 0, 3)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = location.displayName or location.name or location.id
	nameLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = button

	-- Biome label
	local biomeLabel = Instance.new("TextLabel")
	biomeLabel.Name = "Biome"
	biomeLabel.Size = UDim2.new(1, -80, 0, 14)
	biomeLabel.Position = UDim2.new(0, 35, 0, 20)
	biomeLabel.BackgroundTransparency = 1
	biomeLabel.Text = location.biome or "Unknown"
	biomeLabel.TextColor3 = Color3.fromRGB(140, 160, 180)
	biomeLabel.TextSize = 11
	biomeLabel.Font = Enum.Font.Gotham
	biomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	biomeLabel.Parent = button

	-- Hover effects
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(60, 90, 130)
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(40, 60, 90)
		}):Play()
	end)

	-- Click handler
	button.MouseButton1Click:Connect(function()
		if requestLanding then
			requestLanding:FireServer(location.id)
		end
	end)

	return button
end

local function UpdatePlanetInfo(planetId)
	if not planetId then return end
	currentPlanetId = planetId

	local planet = PlanetConfig.GetPlanet(planetId)
	if not planet then return end

	if planetNameLabel then
		planetNameLabel.Text = string.upper(planet.name)
	end

	local abbreviated = PlanetConfig.GetAbbreviated(planetId)
	if abbreviated and charLine1 then
		charLine1.Text = string.format("%s: %s  |  %s: %s",
			abbreviated[1].label, abbreviated[1].value,
			abbreviated[2].label, abbreviated[2].value)
	end
	if abbreviated and charLine2 then
		charLine2.Text = string.format("%s: %s  |  %s: %s",
			abbreviated[3].label, abbreviated[3].value,
			abbreviated[5].label, abbreviated[5].value)
	end
end

local function UpdateLocationsList()
	ClearLocationButtons()

	if #availableLocations == 0 then
		statusLabel.Text = "Немає доступних локацій\nПроскануйте поверхню планети"
		statusLabel.Visible = true
		locationsContainer.Visible = false
		mainFrame.Size = UDim2.new(0, 320, 0, 164)
		return
	end

	statusLabel.Text = ""
	statusLabel.Visible = false
	locationsContainer.Visible = true

	-- Resize container based on locations count
	local containerHeight = 5 + #availableLocations * 42 + 10
	locationsContainer.Size = UDim2.new(1, 0, 0, containerHeight)
	mainFrame.Size = UDim2.new(0, 320, 0, 104 + containerHeight)

	for i, location in ipairs(availableLocations) do
		local button = CreateLocationButton(location, i)
		table.insert(locationButtons, button)
	end
end

local function ShowOrbitUI()
	statusLabel.Visible = true
	locationsContainer.Visible = true
	launchButton.Visible = false

	-- Request locations from server
	if requestLocations then
		requestLocations:FireServer()
	end

	-- Update status while loading
	statusLabel.Text = "Завантаження локацій..."
end

local function ShowSurfaceUI()
	statusLabel.Visible = false
	locationsContainer.Visible = false
	launchButton.Visible = true

	-- Compact panel size for Surface (planet info + title + button)
	mainFrame.Size = UDim2.new(0, 320, 0, 164)
end

local function CreateUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PilotUI"
	gui.DisplayOrder = 60
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- Main panel (top-left corner)
	local frame = Instance.new("Frame")
	frame.Name = "PilotPanel"
	frame.Size = UDim2.new(0, 320, 0, 334)
	frame.Position = UDim2.new(0, 20, 0, 100)
	frame.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = gui
	mainFrame = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 100, 140)
	stroke.Thickness = 2
	stroke.Parent = frame

	-- ========== PLANET INFO SECTION ==========

	-- Planet name
	local pName = Instance.new("TextLabel")
	pName.Name = "PlanetName"
	pName.Size = UDim2.new(1, -20, 0, 20)
	pName.Position = UDim2.new(0, 10, 0, 8)
	pName.BackgroundTransparency = 1
	pName.Text = "---"
	pName.TextColor3 = Color3.fromRGB(100, 200, 255)
	pName.TextSize = 16
	pName.Font = Enum.Font.GothamBold
	pName.TextXAlignment = Enum.TextXAlignment.Left
	pName.Parent = frame
	planetNameLabel = pName

	-- Characteristics line 1
	local cLine1 = Instance.new("TextLabel")
	cLine1.Name = "CharLine1"
	cLine1.Size = UDim2.new(1, -20, 0, 14)
	cLine1.Position = UDim2.new(0, 10, 0, 28)
	cLine1.BackgroundTransparency = 1
	cLine1.Text = ""
	cLine1.TextColor3 = Color3.fromRGB(140, 170, 200)
	cLine1.TextSize = 12
	cLine1.Font = Enum.Font.Gotham
	cLine1.TextXAlignment = Enum.TextXAlignment.Left
	cLine1.Parent = frame
	charLine1 = cLine1

	-- Characteristics line 2
	local cLine2 = Instance.new("TextLabel")
	cLine2.Name = "CharLine2"
	cLine2.Size = UDim2.new(1, -20, 0, 14)
	cLine2.Position = UDim2.new(0, 10, 0, 42)
	cLine2.BackgroundTransparency = 1
	cLine2.Text = ""
	cLine2.TextColor3 = Color3.fromRGB(140, 170, 200)
	cLine2.TextSize = 12
	cLine2.Font = Enum.Font.Gotham
	cLine2.TextXAlignment = Enum.TextXAlignment.Left
	cLine2.Parent = frame
	charLine2 = cLine2

	-- Divider
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, -20, 0, 1)
	divider.Position = UDim2.new(0, 10, 0, 58)
	divider.BackgroundColor3 = Color3.fromRGB(60, 100, 140)
	divider.BackgroundTransparency = 0.5
	divider.BorderSizePixel = 0
	divider.Parent = frame

	-- ========== NAVIGATION SECTION ==========

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.new(0, 10, 0, 64)
	title.BackgroundTransparency = 1
	title.Text = "НАВІГАЦІЯ"
	title.TextColor3 = Color3.fromRGB(100, 180, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame
	titleLabel = title

	-- Status
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -20, 0, 40)
	status.Position = UDim2.new(0, 10, 0, 99)
	status.BackgroundTransparency = 1
	status.Text = "Корабель на орбіті"
	status.TextColor3 = Color3.fromRGB(180, 200, 220)
	status.TextSize = 14
	status.Font = Enum.Font.Gotham
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextYAlignment = Enum.TextYAlignment.Top
	status.Parent = frame
	statusLabel = status

	-- Locations container (for Orbit context)
	local locContainer = Instance.new("Frame")
	locContainer.Name = "LocationsContainer"
	locContainer.Size = UDim2.new(1, 0, 0, 180)
	locContainer.Position = UDim2.new(0, 0, 0, 99)
	locContainer.BackgroundTransparency = 1
	locContainer.Parent = frame
	locationsContainer = locContainer

	-- Launch button (for Surface context)
	local launch = Instance.new("TextButton")
	launch.Name = "LaunchButton"
	launch.Size = UDim2.new(1, -20, 0, 50)
	launch.Position = UDim2.new(0, 10, 0, 99)
	launch.BackgroundColor3 = Color3.fromRGB(80, 140, 200)
	launch.BorderSizePixel = 0
	launch.Text = "🚀  Зліт на орбіту"
	launch.TextColor3 = Color3.fromRGB(255, 255, 255)
	launch.TextSize = 16
	launch.Font = Enum.Font.GothamBold
	launch.AutoButtonColor = false
	launch.Visible = false
	launch.Parent = frame
	launchButton = launch

	local launchCorner = Instance.new("UICorner")
	launchCorner.CornerRadius = UDim.new(0, 8)
	launchCorner.Parent = launch

	-- Launch hover effects
	launch.MouseEnter:Connect(function()
		TweenService:Create(launch, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(100, 170, 240)
		}):Play()
	end)

	launch.MouseLeave:Connect(function()
		TweenService:Create(launch, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(80, 140, 200)
		}):Play()
	end)

	-- Launch click handler
	launch.MouseButton1Click:Connect(function()
		if requestLaunch then
			requestLaunch:FireServer()
		end
	end)

	return gui
end

local function SetupRemoteEvents()
	remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not remoteEvents then
		warn(string.format("[%s %s] RemoteEvents not found!", MODULE_NAME, VERSION))
		return
	end

	requestLanding = remoteEvents:FindFirstChild("RequestLanding")
	requestLaunch = remoteEvents:FindFirstChild("RequestLaunch")
	requestLocations = remoteEvents:FindFirstChild("RequestLocations")
	locationsAvailable = remoteEvents:FindFirstChild("LocationsAvailable")
	transitionUpdate = remoteEvents:FindFirstChild("TransitionUpdate")

	-- Listen for locations response
	if locationsAvailable then
		locationsAvailable.OnClientEvent:Connect(function(locations)
			availableLocations = locations
			if isVisible and currentContext == TransitionConfig.Contexts.Orbit then
				UpdateLocationsList()
			end
		end)
	end

	-- Listen for transition updates (to update context and planet info)
	if transitionUpdate then
		transitionUpdate.OnClientEvent:Connect(function(state, data)
			if state == TransitionConfig.States.Complete and data and data.context then
				PilotUI.SetContext(data.context)
				if data.planetId then
					UpdatePlanetInfo(data.planetId)
				end
			end
		end)
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function PilotUI.Initialize()
	if isInitialized then return true end

	screenGui = CreateUI()
	screenGui.Parent = playerGui
	screenGui.Enabled = false

	SetupRemoteEvents()

	isInitialized = true
	return true
end

function PilotUI.Show()
	if not screenGui then return end

	-- Always show "НАВІГАЦІЯ" title
	titleLabel.Text = "НАВІГАЦІЯ"

	-- Initialize planet info
	UpdatePlanetInfo(currentPlanetId or GameConfig.StartPlanet)

	screenGui.Enabled = true
	isVisible = true

	-- Default to Orbit if context not set
	if not currentContext then
		currentContext = TransitionConfig.Contexts.Orbit
	end

	-- Show appropriate UI based on context
	if currentContext == TransitionConfig.Contexts.Orbit then
		ShowOrbitUI()
	else
		ShowSurfaceUI()
	end

	-- Animate in
	mainFrame.Position = UDim2.new(0, -350, 0, 100)
	TweenService:Create(
		mainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = UDim2.new(0, 20, 0, 100)}
	):Play()
end

function PilotUI.Hide()
	if not screenGui then return end

	TweenService:Create(
		mainFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(0, -350, 0, 100)}
	):Play()

	task.delay(0.2, function()
		if screenGui then
			screenGui.Enabled = false
		end
	end)

	isVisible = false
end

function PilotUI.IsVisible()
	return isVisible
end

function PilotUI.SetContext(context)
	currentContext = context

	if isVisible then
		if context == TransitionConfig.Contexts.Orbit then
			ShowOrbitUI()
		else
			ShowSurfaceUI()
		end
	end
end

function PilotUI.UpdateLocations(locations)
	availableLocations = locations
	if isVisible and currentContext == TransitionConfig.Contexts.Orbit then
		UpdateLocationsList()
	end
end

function PilotUI.GetContext()
	return currentContext
end

-- ============================================================================
-- RETURN
-- ============================================================================

return PilotUI
