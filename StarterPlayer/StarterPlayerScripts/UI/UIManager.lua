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
local StatusBarUI = nil -- Will be set during Initialize

-- ============================================================================
-- STATE
-- ============================================================================

local currentState = "LoggedOff"

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function UIManager.Initialize(screenSaverModule, statusBarModule)
	ScreenSaverUI = screenSaverModule
	StatusBarUI = statusBarModule

	-- Setup state change listener
	UIManager.SetupStateListener()

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
end

-- ============================================================================
-- STATE CHANGE HANDLER
-- ============================================================================

function UIManager.OnStateChanged(oldState, newState)
	currentState = newState

	-- Handle UI transitions based on state
	if newState == "LoggedOff" then
		-- Show ScreenSaver, hide StatusBar
		if ScreenSaverUI then
			ScreenSaverUI.Reset() -- Reset to initial state
			ScreenSaverUI.Show()
		end
		if StatusBarUI then
			StatusBarUI.Hide()
		end

	elseif newState == "Initializing" then
		-- Boot sequence is running (Stages 1-4)
		-- ScreenSaver stays visible and shows boot stages
		-- StatusBar stays hidden

	elseif newState == "InGame" then
		-- Hide ScreenSaver, show StatusBar
		if ScreenSaverUI then
			ScreenSaverUI.Hide()
		end
		if StatusBarUI then
			StatusBarUI.Show()
		end
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
