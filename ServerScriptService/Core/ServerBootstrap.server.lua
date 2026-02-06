--[[
================================================================================
CALL OF RELICS — ServerBootstrap
================================================================================

Purpose:
Main server initialization script. Boots the game in controlled sequence.
Implements Boot phase from TDD Section 4.3.

Version:
0.3

Features:
- Initializes core services in correct order
- Initializes LocationService for level loading
- Sets initial game state to LoggedOff
- Prepares ScreenSaver environment
- Handles boot failures safely
- DebugLogger hooks print/warn for MCP-accessible logs

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
- DebugLogger

ChangeLog:
- 0.3: Added DebugLogger hook for MCP-readable logs (2026-01-24)
- 0.2: Added LocationService initialization (2026-01-12)
- 0.1: Initial boot sequence implementation (2026-01-11)
================================================================================
]]

local VERSION = "0.3"
local MODULE_NAME = "ServerBootstrap"

-- ============================================================================
-- CORE SERVICES
-- ============================================================================

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================================
-- DEBUG LOGGER (перехоплення print/warn для MCP)
-- ============================================================================

local Game = ReplicatedStorage:WaitForChild("Game")
local Logger = require(Game:WaitForChild("DebugLogger"))
Logger:HookGlobalOutput()  -- Тепер ВСІ print/warn автоматично логуються

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
	local success = GameStateManager.Initialize()
	if not success then
		error("[ServerBootstrap] GameStateManager initialization failed!")
	end

	local ProfileService = require(Services:WaitForChild("ProfileService"))
	success = ProfileService.Initialize()
	if not success then
		error("[ServerBootstrap] ProfileService initialization failed!")
	end

	local LocationService = require(Services:WaitForChild("LocationService"))
	success = LocationService.Initialize()
	if not success then
		error("[ServerBootstrap] LocationService initialization failed!")
	end

	success = PlayerService.Initialize()
	if not success then
		error("[ServerBootstrap] PlayerService initialization failed!")
	end

	-- SpaceShipService now includes seat management (merged from SeatService)
	local SpaceShipService = require(Services:WaitForChild("SpaceShipService"))
	success = SpaceShipService.Initialize()
	if not success then
		error("[ServerBootstrap] SpaceShipService initialization failed!")
	end

	local TransitionService = require(Services:WaitForChild("TransitionService"))
	success = TransitionService.Initialize()
	if not success then
		error("[ServerBootstrap] TransitionService initialization failed!")
	end

	local PlanetScannerService = require(Services:WaitForChild("PlanetScannerService"))
	success = PlanetScannerService.Initialize()
	if not success then
		error("[ServerBootstrap] PlanetScannerService initialization failed!")
	end

	print(string.format("[%s %s] ✓ Server ready, state: %s", MODULE_NAME, VERSION, GameStateManager.GetCurrentState()))
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
