--[[
================================================================================
KOSMICMAZER — GameStateManager
================================================================================

Purpose:
Single coordinator for all game state transitions.
Implements the state-driven architecture from TDD Section 2.5.

Version:
0.1

Features:
- Manages global game states (LoggedOff, Initializing, InGame)
- Enforces state transition rules
- Notifies systems of state changes
- Prevents unauthorized state modifications

API:
- Initialize() — Boots the state manager
- RequestStateChange(newState, player) — Request state transition
- GetCurrentState() — Returns current global state
- CanTransition(fromState, toState) — Validates transition

Calls to:
- None (core system)

Called from:
- ServerBootstrap
- PlayerService
- UI Systems (via RemoteEvents)

Events:
- StateChanged(oldState, newState) — Fired when state changes

Dependencies:
- None (foundation module)

ChangeLog:
- 0.1: Initial implementation with basic state machine (2026-01-11)
================================================================================
]]

local GameStateManager = {}

-- Module version for logging
local VERSION = "0.1"
local MODULE_NAME = "GameStateManager"

-- ============================================================================
-- SERVICES
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================================
-- GLOBAL GAME STATES (TDD Section 2.2)
-- ============================================================================
local GlobalStates = {
	LoggedOff = "LoggedOff",      -- Player not in game (ScreenSaver active)
	Initializing = "Initializing", -- Boot sequence in progress
	InGame = "InGame"              -- Active game session
}

-- Current state (default: LoggedOff)
local currentState = GlobalStates.LoggedOff

-- State transition rules (TDD Section 2.4 - Forbidden Transitions)
local allowedTransitions = {
	[GlobalStates.LoggedOff] = {
		[GlobalStates.Initializing] = true -- Can start boot sequence
	},
	[GlobalStates.Initializing] = {
		[GlobalStates.InGame] = true,      -- Can complete boot
		[GlobalStates.LoggedOff] = true    -- Can fail and return
	},
	[GlobalStates.InGame] = {
		[GlobalStates.LoggedOff] = true    -- Can log off
	}
}

-- State change listeners
local stateChangedEvent = Instance.new("BindableEvent")

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function GameStateManager.Initialize()
	print(string.format("[%s %s][Initialize] State manager initialized. Current state: %s",
		MODULE_NAME, VERSION, currentState))

	return true
end

-- ============================================================================
-- STATE QUERIES
-- ============================================================================

function GameStateManager.GetCurrentState()
	return currentState
end

function GameStateManager.GetStates()
	return GlobalStates
end

-- ============================================================================
-- STATE VALIDATION
-- ============================================================================

function GameStateManager.CanTransition(fromState, toState)
	if not fromState or not toState then
		return false
	end

	local transitions = allowedTransitions[fromState]
	if not transitions then
		return false
	end

	return transitions[toState] == true
end

-- ============================================================================
-- STATE TRANSITIONS (TDD Section 3.4 - Request → Verification → Permission)
-- ============================================================================

function GameStateManager.RequestStateChange(newState, context)
	-- 1. Validation
	if not GlobalStates[newState] then
		warn(string.format("[%s %s][RequestStateChange] Invalid state requested: %s",
			MODULE_NAME, VERSION, tostring(newState)))
		return false
	end

	-- 2. Check if transition is allowed
	if not GameStateManager.CanTransition(currentState, newState) then
		warn(string.format("[%s %s][RequestStateChange] Forbidden transition: %s → %s",
			MODULE_NAME, VERSION, currentState, newState))
		return false
	end

	-- 3. Execute transition
	local oldState = currentState
	currentState = newState

	print(string.format("[%s %s][RequestStateChange] State transition: %s → %s",
		MODULE_NAME, VERSION, oldState, newState))

	-- 4. Notify systems (server-side)
	stateChangedEvent:Fire(oldState, newState, context)

	-- 5. Notify client (if player context exists)
	-- Context can be either a Player object or a table with .player field
	local player = nil
	if context then
		if typeof(context) == "Instance" and context:IsA("Player") then
			player = context
		elseif type(context) == "table" and context.player then
			player = context.player
		end
	end

	if player then
		local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if remoteEvents then
			local stateChangedRemote = remoteEvents:FindFirstChild("StateChanged")
			if stateChangedRemote then
				stateChangedRemote:FireClient(player, oldState, newState)
				print(string.format("[%s %s][RequestStateChange] State change sent to client: %s",
					MODULE_NAME, VERSION, player.Name))
			end
		end
	end

	return true
end

-- ============================================================================
-- EVENT SUBSCRIPTION
-- ============================================================================

function GameStateManager.OnStateChanged(callback)
	return stateChangedEvent.Event:Connect(callback)
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

GameStateManager.States = GlobalStates

return GameStateManager
