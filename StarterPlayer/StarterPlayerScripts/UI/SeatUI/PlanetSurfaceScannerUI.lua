--[[
================================================================================
KOSMICMAZER — PlanetSurfaceScannerUI
================================================================================

Purpose:
Planet surface scanning UI panel for "Seat Planet Surface Scanner".
Allows player to scan planet surface and discover new locations.

Version:
0.1

Features:
- Scan button to start planet surface scan
- Progress bar during scanning
- List of discovered locations
- Context-aware (only active on Orbit)

API:
- Initialize() — Create UI elements
- Show() — Display the UI
- Hide() — Hide the UI
- SetContext(context) — Set Orbit/Surface context

Calls to:
- TransitionConfig (ReplicatedStorage/Game)
- RequestScan RemoteEvent
- ScanProgress RemoteEvent
- ScanComplete RemoteEvent

Called from:
- SeatUIManager.lua

Events:
- Fires: RequestScan (Client → Server)
- Listens: ScanProgress (Server → Client)
- Listens: ScanComplete (Server → Client)

Dependencies:
- TweenService
- TransitionConfig
- RemoteEvents

ChangeLog:
- 0.1: Initial PlanetSurfaceScannerUI (2026-01-16)
================================================================================
]]

local PlanetSurfaceScannerUI = {}

local VERSION = "0.1"
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
-- STATE
-- ============================================================================

local screenGui = nil
local isVisible = false
local isInitialized = false
local isScanning = false
local currentContext = nil -- "Orbit" or "Surface"

-- UI Elements
local mainFrame = nil
local titleLabel = nil
local statusLabel = nil
local scanButton = nil
local progressFrame = nil
local progressBar = nil
local progressLabel = nil
local discoveredContainer = nil
local discoveredItems = {}

-- RemoteEvents
local remoteEvents = nil
local requestScan = nil
local scanProgress = nil
local scanComplete = nil

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

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
	item.Size = UDim2.new(1, -20, 0, 30)
	item.Position = UDim2.new(0, 10, 0, (index - 1) * 35)
	item.BackgroundColor3 = Color3.fromRGB(30, 50, 40)
	item.BackgroundTransparency = 0.3
	item.BorderSizePixel = 0
	item.Parent = discoveredContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = item

	-- Check icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 25, 1, 0)
	icon.Position = UDim2.new(0, 5, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "✓"
	icon.TextColor3 = Color3.fromRGB(100, 200, 100)
	icon.TextSize = 16
	icon.Font = Enum.Font.GothamBold
	icon.Parent = item

	-- Location name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -35, 1, 0)
	nameLabel.Position = UDim2.new(0, 30, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = location.displayName or location.name or location.id
	nameLabel.TextColor3 = Color3.fromRGB(180, 220, 180)
	nameLabel.TextSize = 13
	nameLabel.Font = Enum.Font.Gotham
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

	-- Resize container based on locations count
	local containerHeight = #locations * 35
	discoveredContainer.Size = UDim2.new(1, 0, 0, containerHeight)

	for i, location in ipairs(locations) do
		local item = CreateDiscoveredItem(location, i)
		table.insert(discoveredItems, item)
	end
end

local function SetScanningState(scanning)
	isScanning = scanning

	if scanning then
		scanButton.Visible = false
		progressFrame.Visible = true
		statusLabel.Text = "Сканування поверхні..."
	else
		scanButton.Visible = true
		progressFrame.Visible = false
	end
end

local function UpdateProgress(progress, message)
	if progressBar then
		-- Animate progress bar
		TweenService:Create(progressBar, TweenInfo.new(0.2), {
			Size = UDim2.new(progress, 0, 1, 0)
		}):Play()
	end

	if progressLabel then
		progressLabel.Text = message or string.format("%.0f%%", progress * 100)
	end
end

local function ShowOrbitUI()
	scanButton.Visible = not isScanning
	progressFrame.Visible = isScanning
	discoveredContainer.Visible = true
	statusLabel.Text = "Готовий до сканування"
	statusLabel.Visible = true

	-- Resize panel
	mainFrame.Size = UDim2.new(0, 300, 0, 280)
end

local function ShowSurfaceUI()
	-- Scanner not available on surface
	scanButton.Visible = false
	progressFrame.Visible = false
	discoveredContainer.Visible = false
	statusLabel.Text = "Сканер доступний лише з орбіти"
	statusLabel.Visible = true

	-- Compact panel
	mainFrame.Size = UDim2.new(0, 300, 0, 100)
end

local function CreateUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PlanetSurfaceScannerUI"
	gui.DisplayOrder = 61
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- Main panel (right side)
	local frame = Instance.new("Frame")
	frame.Name = "ScannerPanel"
	frame.Size = UDim2.new(0, 300, 0, 280)
	frame.Position = UDim2.new(1, -320, 0, 100)
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.BackgroundColor3 = Color3.fromRGB(25, 35, 30)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = gui
	mainFrame = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 120, 80)
	stroke.Thickness = 2
	stroke.Parent = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "СКАНЕР ПОВЕРХНІ"
	title.TextColor3 = Color3.fromRGB(100, 200, 120)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame
	titleLabel = title

	-- Status
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -20, 0, 20)
	status.Position = UDim2.new(0, 10, 0, 40)
	status.BackgroundTransparency = 1
	status.Text = "Готовий до сканування"
	status.TextColor3 = Color3.fromRGB(160, 180, 170)
	status.TextSize = 12
	status.Font = Enum.Font.Gotham
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = frame
	statusLabel = status

	-- Scan button
	local scan = Instance.new("TextButton")
	scan.Name = "ScanButton"
	scan.Size = UDim2.new(1, -20, 0, 45)
	scan.Position = UDim2.new(0, 10, 0, 65)
	scan.BackgroundColor3 = Color3.fromRGB(50, 120, 70)
	scan.BorderSizePixel = 0
	scan.Text = "🔍  Сканувати поверхню"
	scan.TextColor3 = Color3.fromRGB(255, 255, 255)
	scan.TextSize = 15
	scan.Font = Enum.Font.GothamBold
	scan.AutoButtonColor = false
	scan.Parent = frame
	scanButton = scan

	local scanCorner = Instance.new("UICorner")
	scanCorner.CornerRadius = UDim.new(0, 8)
	scanCorner.Parent = scan

	-- Scan hover effects
	scan.MouseEnter:Connect(function()
		if not isScanning then
			TweenService:Create(scan, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(70, 150, 90)
			}):Play()
		end
	end)

	scan.MouseLeave:Connect(function()
		TweenService:Create(scan, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(50, 120, 70)
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
	progress.Size = UDim2.new(1, -20, 0, 45)
	progress.Position = UDim2.new(0, 10, 0, 65)
	progress.BackgroundColor3 = Color3.fromRGB(30, 40, 35)
	progress.BorderSizePixel = 0
	progress.Visible = false
	progress.Parent = frame
	progressFrame = progress

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 8)
	progressCorner.Parent = progress

	-- Progress bar background
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBackground"
	progressBg.Size = UDim2.new(1, -20, 0, 12)
	progressBg.Position = UDim2.new(0, 10, 0, 10)
	progressBg.BackgroundColor3 = Color3.fromRGB(40, 50, 45)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = progress

	local progressBgCorner = Instance.new("UICorner")
	progressBgCorner.CornerRadius = UDim.new(0, 6)
	progressBgCorner.Parent = progressBg

	-- Progress bar fill
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.Position = UDim2.new(0, 0, 0, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg
	progressBar = progressFill

	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(0, 6)
	progressFillCorner.Parent = progressFill

	-- Progress label
	local progressText = Instance.new("TextLabel")
	progressText.Name = "ProgressLabel"
	progressText.Size = UDim2.new(1, -20, 0, 18)
	progressText.Position = UDim2.new(0, 10, 0, 25)
	progressText.BackgroundTransparency = 1
	progressText.Text = "0%"
	progressText.TextColor3 = Color3.fromRGB(180, 200, 180)
	progressText.TextSize = 12
	progressText.Font = Enum.Font.Gotham
	progressText.Parent = progress
	progressLabel = progressText

	-- Discovered locations section
	local discoveredTitle = Instance.new("TextLabel")
	discoveredTitle.Name = "DiscoveredTitle"
	discoveredTitle.Size = UDim2.new(1, -20, 0, 20)
	discoveredTitle.Position = UDim2.new(0, 10, 0, 120)
	discoveredTitle.BackgroundTransparency = 1
	discoveredTitle.Text = "Виявлені локації:"
	discoveredTitle.TextColor3 = Color3.fromRGB(140, 160, 150)
	discoveredTitle.TextSize = 12
	discoveredTitle.Font = Enum.Font.GothamBold
	discoveredTitle.TextXAlignment = Enum.TextXAlignment.Left
	discoveredTitle.Parent = frame

	-- Discovered container
	local discovered = Instance.new("ScrollingFrame")
	discovered.Name = "DiscoveredContainer"
	discovered.Size = UDim2.new(1, 0, 0, 130)
	discovered.Position = UDim2.new(0, 0, 0, 145)
	discovered.BackgroundTransparency = 1
	discovered.BorderSizePixel = 0
	discovered.ScrollBarThickness = 4
	discovered.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 90)
	discovered.CanvasSize = UDim2.new(0, 0, 0, 0)
	discovered.AutomaticCanvasSize = Enum.AutomaticSize.Y
	discovered.Parent = frame
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

	-- Listen for scan progress
	if scanProgress then
		scanProgress.OnClientEvent:Connect(function(progress, message)
			SetScanningState(true)
			UpdateProgress(progress, message)
		end)
	end

	-- Listen for scan complete
	if scanComplete then
		scanComplete.OnClientEvent:Connect(function(success, discoveredLocations, message)
			SetScanningState(false)

			if success then
				statusLabel.Text = message or "Сканування завершено!"
				statusLabel.TextColor3 = Color3.fromRGB(100, 200, 120)

				if discoveredLocations then
					UpdateDiscoveredList(discoveredLocations)
				end
			else
				statusLabel.Text = message or "Нічого не знайдено"
				statusLabel.TextColor3 = Color3.fromRGB(200, 160, 100)
			end

			-- Reset status color after delay
			task.delay(3, function()
				if statusLabel then
					statusLabel.TextColor3 = Color3.fromRGB(160, 180, 170)
					statusLabel.Text = "Готовий до сканування"
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
	return true
end

function PlanetSurfaceScannerUI.Show()
	if not screenGui then return end

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

	-- Animate in (from right)
	mainFrame.Position = UDim2.new(1, 50, 0, 100)
	TweenService:Create(
		mainFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = UDim2.new(1, -320, 0, 100)}
	):Play()
end

function PlanetSurfaceScannerUI.Hide()
	if not screenGui then return end

	TweenService:Create(
		mainFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(1, 50, 0, 100)}
	):Play()

	task.delay(0.2, function()
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
