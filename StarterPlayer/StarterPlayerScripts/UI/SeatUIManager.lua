--[[
================================================================================
KOSMICMAZER -- SeatUIManager
================================================================================

Purpose:
Manages seat-specific UI panels. Shows/hides UI based on seat occupancy.
Loads and caches seat UI modules dynamically.

Version:
0.1

Features:
- Dynamic loading of seat UI modules
- Show/hide coordination
- UI module caching
- Transition animations

API:
- Initialize() -- Initialize the manager
- ShowSeatUI(seatName, seatConfig) -- Show UI for seat
- HideSeatUI(seatName) -- Hide UI for seat
- HideAllSeatUI() -- Hide all seat UIs
- GetActiveUI() -- Returns current active UI name

Calls to:
- SeatUI modules (PilotUI, SurfaceScannerUI, etc.)
- ReplicatedStorage.Game.SeatConfig

Called from:
- SeatController
- ClientBootstrap

Dependencies:
- SeatConfig
- Individual UI modules in SeatUI folder

ChangeLog:
- 0.1: Initial SeatUIManager (2026-01-13)
================================================================================
]]

local SeatUIManager = {}

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- ============================================================================
-- STATE
-- ============================================================================

local isInitialized = false
local loadedModules = {} -- {[moduleName] = module}
local activeUI = nil -- Currently shown UI name

-- Module references
local SeatUIFolder
local SeatConfig

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

local function LoadUIModule(moduleName)
	if loadedModules[moduleName] then
		return loadedModules[moduleName]
	end

	local moduleScript = SeatUIFolder:FindFirstChild(moduleName)
	if not moduleScript then
		return nil
	end

	local success, result = pcall(require, moduleScript)
	if not success then
		return nil
	end

	local module = result

	if module.Initialize then
		local initSuccess = module.Initialize()
		if not initSuccess then
			return nil
		end
	end

	loadedModules[moduleName] = module
	return module
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function SeatUIManager.Initialize()
	if isInitialized then return true end

	local Game = ReplicatedStorage:WaitForChild("Game")
	SeatConfig = require(Game:WaitForChild("SeatConfig"))

	local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
	local UI = PlayerScripts:WaitForChild("UI")
	SeatUIFolder = UI:WaitForChild("SeatUI")

	isInitialized = true
	return true
end

function SeatUIManager.ShowSeatUI(seatName, seatConfig)
	if activeUI and activeUI ~= seatName then
		SeatUIManager.HideSeatUI(activeUI)
	end

	local moduleName = seatConfig.uiModule
	local module = LoadUIModule(moduleName)

	if module and module.Show then
		module.Show(seatConfig)
		activeUI = seatName
	end
end

function SeatUIManager.HideSeatUI(seatName)
	local seatConfig = SeatConfig.GetSeatConfig(seatName)

	if seatConfig then
		local moduleName = seatConfig.uiModule
		local module = loadedModules[moduleName]

		if module and module.Hide then
			module.Hide()
		end
	end

	if activeUI == seatName then
		activeUI = nil
	end
end

function SeatUIManager.HideAllSeatUI()
	for _, module in pairs(loadedModules) do
		if module.Hide then
			module.Hide()
		end
	end

	activeUI = nil
end

function SeatUIManager.GetActiveUI()
	return activeUI
end

function SeatUIManager.IsUIActive()
	return activeUI ~= nil
end

-- ============================================================================
-- RETURN
-- ============================================================================

return SeatUIManager
