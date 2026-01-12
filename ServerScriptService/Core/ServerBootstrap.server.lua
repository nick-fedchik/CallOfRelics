--[[
================================================================================
KOSMICMAZER — ServerBootstrap
================================================================================

Purpose:
Main server initialization script. Boots the game in controlled sequence.
Implements Boot phase from TDD Section 4.3.

Version:
0.2

Features:
- Initializes core services in correct order
- Initializes LocationService for level loading
- Sets initial game state to LoggedOff
- Prepares ScreenSaver environment
- Handles boot failures safely

API:
- None (auto-executes on server start)

Calls to:
- GameStateManager
- ProfileService
- LocationService
- PlayerService

Called from:
- Roblox Server (auto-run)

Events:
- None

Dependencies:
- GameStateManager
- ProfileService
- LocationService
- PlayerService

ChangeLog:
- 0.2: Added LocationService initialization (2026-01-12)
- 0.1: Initial boot sequence implementation (2026-01-11)
================================================================================
]]

local VERSION = "0.2"
local MODULE_NAME = "ServerBootstrap"


print("SERVER BOOT SEQUENCE STARTED")
print(string.format("[%s %s] Initializing...", MODULE_NAME, VERSION))


-- ============================================================================
-- CORE SERVICES
-- ============================================================================

local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================================
-- LOAD CORE MODULES
-- ============================================================================

-- Core modules (same folder)
local Core = script.Parent
local GameStateManager = require(Core:WaitForChild("GameStateManager"))

-- Services
local Services = ServerScriptService:WaitForChild("Services")
local PlayerService = require(Services:WaitForChild("PlayerService"))

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

	print(string.format("[%s %s][Boot] Phase 2: Initializing ProfileService", MODULE_NAME, VERSION))

	local ProfileService = require(Services:WaitForChild("ProfileService"))
	success = ProfileService.Initialize()
	if not success then
		error("[ServerBootstrap] CRITICAL: ProfileService initialization failed!")
	end

	print(string.format("[%s %s][Boot] Phase 3: Initializing LocationService", MODULE_NAME, VERSION))

	local LocationService = require(Services:WaitForChild("LocationService"))
	success = LocationService.Initialize()
	if not success then
		error("[ServerBootstrap] CRITICAL: LocationService initialization failed!")
	end

	print(string.format("[%s %s][Boot] Phase 4: Initializing PlayerService", MODULE_NAME, VERSION))

	success = PlayerService.Initialize()
	if not success then
		error("[ServerBootstrap] CRITICAL: PlayerService initialization failed!")
	end

	print(string.format("[%s %s][Boot] Phase 5: Core systems ready", MODULE_NAME, VERSION))
	print(string.format("[%s %s][Boot] Phase 6: ScreenSaver active", MODULE_NAME, VERSION))


	print("BOOT COMPLETE")
	print("Game State: LoggedOff (ScreenSaver)")
	print("Waiting for player login...")

end

-- ============================================================================
-- ERROR HANDLING (TDD Section 10)
-- ============================================================================

local bootSuccess, bootError = pcall(Boot)

if not bootSuccess then
	warn("BOOT FAILED!")
	warn("Error: " .. tostring(bootError))
	warn("Game cannot start. Check logs for details.")
	error("Boot sequence failed. Game cannot continue.")
end
