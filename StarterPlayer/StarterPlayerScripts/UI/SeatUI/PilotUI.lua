--[[
================================================================================
KOSMICMAZER — PilotUI
================================================================================

Purpose:
UI panel for pilot seat. Shows ship status and navigation options.
Context-aware: shows landing options on Orbit, liftoff option on Surface.

Version:
0.5

Features:
- Ship status display
- Context detection (Orbit/Surface)
- Landing menu with available locations (Orbit)
- Liftoff button (Surface)
- Integration with TransitionService
- DisplayName localization for locations

API:
- Initialize() — Create UI elements
- Show(seatConfig) — Display the UI
- Hide() — Hide the UI
- SetContext(context) — Set Orbit/Surface context
- UpdateLocations(locations) — Update location list

Calls to:
- TransitionConfig (ReplicatedStorage/Game)
- RequestLanding RemoteEvent
- RequestLiftoff RemoteEvent
- RequestAvailableLocations RemoteEvent

Called from:
- SeatUIManager.lua

Events:
- Fires: RequestLanding (Client → Server)
- Fires: RequestLiftoff (Client → Server)
- Fires: RequestAvailableLocations (Client → Server)
- Listens: AvailableLocationsResponse (Server → Client)

Dependencies:
- TweenService
- TransitionConfig
- RemoteEvents (RequestLanding, RequestLiftoff, AvailableLocationsResponse)

ChangeLog:
- 0.5: Added displayName support for locations (2026-01-14)
- 0.4: Fixed context detection on Show() (2026-01-14)
- 0.3: Added location list from server (2026-01-14)
- 0.2: Added context-aware menus for landing/liftoff (2026-01-14)
- 0.1: Initial PilotUI (2026-01-13)
================================================================================
]]

local PilotUI = {}

local VERSION = "0.5"
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

local TransitionConfig = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("TransitionConfig"))

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
local liftoffButton = nil
local locationButtons = {}

-- RemoteEvents
local remoteEvents = nil
local requestLanding = nil
local requestLiftoff = nil
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
		print(string.format("[%s %s] Landing requested: %s", MODULE_NAME, VERSION, location.id))
		if requestLanding then
			requestLanding:FireServer(location.id)
		end
	end)

	return button
end

local function UpdateLocationsList()
	ClearLocationButtons()

	if #availableLocations == 0 then
		statusLabel.Text = "Немає доступних локацій\nПроскануйте поверхню планети"
		locationsContainer.Visible = false
		return
	end

	statusLabel.Text = ""
	statusLabel.Visible = false
	locationsContainer.Visible = true

	-- Resize container based on locations count
	local containerHeight = 5 + #availableLocations * 42 + 10
	locationsContainer.Size = UDim2.new(1, 0, 0, containerHeight)
	mainFrame.Size = UDim2.new(0, 320, 0, 50 + containerHeight)

	for i, location in ipairs(availableLocations) do
		local button = CreateLocationButton(location, i)
		table.insert(locationButtons, button)
	end
end

local function ShowOrbitUI()
	statusLabel.Visible = true
	locationsContainer.Visible = true
	liftoffButton.Visible = false

	-- Request locations from server
	if requestLocations then
		requestLocations:FireServer()
	end

	-- Update status while loading
	statusLabel.Text = "Завантаження локацій..."
end

local function ShowSurfaceUI()
	statusLabel.Visible = true
	locationsContainer.Visible = false
	liftoffButton.Visible = true

	statusLabel.Text = "Корабель на поверхні\nДвигуну готові до запуску"
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
	frame.Size = UDim2.new(0, 320, 0, 280)
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

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "ПІЛОТСЬКЕ КРІСЛО"
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
	status.Position = UDim2.new(0, 10, 0, 45)
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
	locContainer.Position = UDim2.new(0, 0, 0, 45)
	locContainer.BackgroundTransparency = 1
	locContainer.Parent = frame
	locationsContainer = locContainer

	-- Liftoff button (for Surface context)
	local liftoff = Instance.new("TextButton")
	liftoff.Name = "LiftoffButton"
	liftoff.Size = UDim2.new(1, -20, 0, 50)
	liftoff.Position = UDim2.new(0, 10, 0, 95)
	liftoff.BackgroundColor3 = Color3.fromRGB(80, 140, 200)
	liftoff.BorderSizePixel = 0
	liftoff.Text = "🚀  Піднятися на орбіту"
	liftoff.TextColor3 = Color3.fromRGB(255, 255, 255)
	liftoff.TextSize = 16
	liftoff.Font = Enum.Font.GothamBold
	liftoff.AutoButtonColor = false
	liftoff.Visible = false
	liftoff.Parent = frame
	liftoffButton = liftoff

	local liftoffCorner = Instance.new("UICorner")
	liftoffCorner.CornerRadius = UDim.new(0, 8)
	liftoffCorner.Parent = liftoff

	-- Liftoff hover effects
	liftoff.MouseEnter:Connect(function()
		TweenService:Create(liftoff, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(100, 170, 240)
		}):Play()
	end)

	liftoff.MouseLeave:Connect(function()
		TweenService:Create(liftoff, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(80, 140, 200)
		}):Play()
	end)

	-- Liftoff click handler
	liftoff.MouseButton1Click:Connect(function()
		print(string.format("[%s %s] Liftoff requested", MODULE_NAME, VERSION))
		if requestLiftoff then
			requestLiftoff:FireServer()
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
	requestLiftoff = remoteEvents:FindFirstChild("RequestLiftoff")
	requestLocations = remoteEvents:FindFirstChild("RequestLocations")
	locationsAvailable = remoteEvents:FindFirstChild("LocationsAvailable")
	transitionUpdate = remoteEvents:FindFirstChild("TransitionUpdate")

	-- Listen for locations response
	if locationsAvailable then
		locationsAvailable.OnClientEvent:Connect(function(locations)
			print(string.format("[%s %s] Received %d locations", MODULE_NAME, VERSION, #locations))
			availableLocations = locations
			if isVisible and currentContext == TransitionConfig.Contexts.Orbit then
				UpdateLocationsList()
			end
		end)
	end

	-- Listen for transition updates (to update context)
	if transitionUpdate then
		transitionUpdate.OnClientEvent:Connect(function(state, data)
			if state == TransitionConfig.States.Complete and data and data.context then
				print(string.format("[%s %s] Context changed to: %s", MODULE_NAME, VERSION, data.context))
				PilotUI.SetContext(data.context)
			end
		end)
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function PilotUI.Initialize()
	if isInitialized then return true end

	print(string.format("[%s %s] Initializing...", MODULE_NAME, VERSION))

	screenGui = CreateUI()
	screenGui.Parent = playerGui
	screenGui.Enabled = false

	SetupRemoteEvents()

	isInitialized = true
	print(string.format("[%s %s] ✓ Initialized", MODULE_NAME, VERSION))
	return true
end

function PilotUI.Show(seatConfig)
	if not screenGui then return end

	print(string.format("[%s %s] Show called, context: %s", MODULE_NAME, VERSION, currentContext or "nil"))

	if seatConfig and seatConfig.displayName then
		titleLabel.Text = string.upper(seatConfig.displayName)
	end

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
	print(string.format("[%s %s] Context set to: %s", MODULE_NAME, VERSION, context))

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
