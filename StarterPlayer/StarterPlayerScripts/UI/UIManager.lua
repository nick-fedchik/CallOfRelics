--[[
================================================================================
KOSMICMAZER — UIManager
================================================================================

Purpose:
Manages UI state transitions based on game state.
Coordinates between different UI systems (ScreenSaver, InGame UI, etc.)

Version:
0.1

Features:
- Listens to server state changes
- Shows/hides UI based on game state
- Coordinates UI modules

API:
- Initialize() — Start the UI manager
- OnStateChanged(oldState, newState) — Handle state changes

Calls to:
- ScreenSaverUI

Called from:
- ClientBootstrap

Events:
- StateChanged (from server)

Dependencies:
- ReplicatedStorage.RemoteEvents
- ScreenSaverUI

ChangeLog:
- 0.1: Initial UI state management (2026-01-11)
================================================================================
]]

local UIManager = {}

local VERSION = "0.1"
local MODULE_NAME = "UIManager"

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- ============================================================================
-- DEPENDENCIES
-- ============================================================================

local ScreenSaverUI = nil -- Will be set during Initialize

-- ============================================================================
-- STATE
-- ============================================================================

local currentState = "LoggedOff"

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function UIManager.Initialize(screenSaverModule)
	print(string.format("[%s %s][Initialize] UIManager initializing", MODULE_NAME, VERSION))

	ScreenSaverUI = screenSaverModule

	-- Setup state change listener
	UIManager.SetupStateListener()

	print(string.format("[%s %s][Initialize] UIManager ready", MODULE_NAME, VERSION))
	return true
end

-- ============================================================================
-- STATE LISTENER
-- ============================================================================

function UIManager.SetupStateListener()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	local stateChanged = remoteEvents:WaitForChild("StateChanged")

	stateChanged.OnClientEvent:Connect(function(oldState, newState)
		UIManager.OnStateChanged(oldState, newState)
	end)

	print(string.format("[%s %s][SetupStateListener] Listening for state changes", MODULE_NAME, VERSION))
end

-- ============================================================================
-- STATE CHANGE HANDLER
-- ============================================================================

function UIManager.OnStateChanged(oldState, newState)
	print(string.format("[%s %s][OnStateChanged] State transition: %s → %s",
		MODULE_NAME, VERSION, tostring(oldState), tostring(newState)))

	currentState = newState

	-- Handle UI transitions based on state
	if newState == "LoggedOff" then
		-- Show ScreenSaver
		if ScreenSaverUI then
			ScreenSaverUI.Show()
		end

	elseif newState == "Initializing" then
		-- Hide ScreenSaver, show loading (future)
		if ScreenSaverUI then
			ScreenSaverUI.Hide()
		end
		print(string.format("[%s %s][OnStateChanged] Loading game...", MODULE_NAME, VERSION))

	elseif newState == "InGame" then
		-- Show InGame UI (future)
		print(string.format("[%s %s][OnStateChanged] Player is now in game!", MODULE_NAME, VERSION))
	end
end

-- ============================================================================
-- GETTERS
-- ============================================================================

function UIManager.GetCurrentState()
	return currentState
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

return UIManager
