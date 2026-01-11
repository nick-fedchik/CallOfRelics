--[[
================================================================================
KOSMICMAZER — ServerBootstrap
================================================================================

Purpose:
Main server initialization script. Boots the game in controlled sequence.
Implements Boot phase from TDD Section 4.3.

Version:
0.1

Features:
- Initializes core services in correct order
- Sets initial game state to LoggedOff
- Prepares ScreenSaver environment
- Handles boot failures safely

API:
- None (auto-executes on server start)

Calls to:
- GameStateManager
- PlayerService

Called from:
- Roblox Server (auto-run)

Events:
- None

Dependencies:
- GameStateManager
- PlayerService

ChangeLog:
- 0.1: Initial boot sequence implementation (2026-01-11)
================================================================================
]]

local VERSION = "0.1"
local MODULE_NAME = "ServerBootstrap"

print("================================================================================")
print("CALL OF RELICS: ORBITAL SILENCE")
print("Server Boot Sequence Started")
print(string.format("[%s %s] Initializing...", MODULE_NAME, VERSION))
print("================================================================================")

-- ============================================================================
-- CORE SERVICES
-- ============================================================================

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ============================================================================
-- LOAD CORE MODULES
-- ============================================================================

local GameStateManager = require(ServerScriptService:WaitForChild("GameStateManager"))
local PlayerService = require(ServerScriptService:WaitForChild("PlayerService"))

-- ============================================================================
-- BOOT SEQUENCE (TDD Section 4.3)
-- ============================================================================

local function Boot()
	print(string.format("[%s %s][Boot] Phase 1: Initializing GameStateManager", MODULE_NAME, VERSION))

	local success = GameStateManager.Initialize()
	if not success then
		error("[ServerBootstrap] CRITICAL: GameStateManager initialization failed!")
	end

	-- Verify we're in LoggedOff state
	local currentState = GameStateManager.GetCurrentState()
	print(string.format("[%s %s][Boot] Current state: %s", MODULE_NAME, VERSION, currentState))

	if currentState ~= GameStateManager.States.LoggedOff then
		warn("[ServerBootstrap] WARNING: Expected LoggedOff state!")
	end

	print(string.format("[%s %s][Boot] Phase 2: Initializing PlayerService", MODULE_NAME, VERSION))

	success = PlayerService.Initialize()
	if not success then
		error("[ServerBootstrap] CRITICAL: PlayerService initialization failed!")
	end

	print(string.format("[%s %s][Boot] Phase 3: Core systems ready", MODULE_NAME, VERSION))
	print(string.format("[%s %s][Boot] Phase 4: ScreenSaver active", MODULE_NAME, VERSION))

	print("================================================================================")
	print("BOOT COMPLETE")
	print("Game State: LoggedOff (ScreenSaver)")
	print("Waiting for player login...")
	print("================================================================================")
end

-- ============================================================================
-- ERROR HANDLING (TDD Section 10)
-- ============================================================================

local bootSuccess, bootError = pcall(Boot)

if not bootSuccess then
	warn("================================================================================")
	warn("BOOT FAILED!")
	warn("Error: " .. tostring(bootError))
	warn("Game cannot start. Check logs for details.")
	warn("================================================================================")
	error("Boot sequence failed. Game cannot continue.")
end
