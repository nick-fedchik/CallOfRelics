--[[
================================================================================
KOSMICMAZER — PlanetLocatorService
================================================================================

Purpose:
Server-side management of planet discovery and navigation.
Handles planet scanning and target setting.

Version:
0.1

Features:
- Track discovered planets per player
- Handle planet scanning requests
- Set navigation targets

API:
- Initialize() — Initialize service

Calls to:
- ProfileService
- SpaceShipService

Called from:
- ServerBootstrap (initialization)

Events:
- (TBD)

Dependencies:
- ProfileService
- SpaceShipService

ChangeLog:
- 0.1: Initial PlanetLocatorService stub (2026-01-16)
================================================================================
]]

local PlanetLocatorService = {}

local VERSION = "0.1"
local MODULE_NAME = "PlanetLocatorService"

-- ============================================================================
-- SERVICES
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ============================================================================
-- MODULES
-- ============================================================================

local ProfileService
local SpaceShipService

-- ============================================================================
-- STATE
-- ============================================================================

local isInitialized = false

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function PlanetLocatorService.Initialize()
	if isInitialized then return true end

	-- Load modules
	local Services = game:GetService("ServerScriptService"):WaitForChild("Services")
	ProfileService = require(Services:WaitForChild("ProfileService"))
	SpaceShipService = require(script.Parent:WaitForChild("SpaceShipService"))

	-- TODO: Setup RemoteEvents when implemented

	isInitialized = true
	print(string.format("[%s %s] Initialized (stub)", MODULE_NAME, VERSION))
	return true
end

-- ============================================================================
-- RETURN
-- ============================================================================

return PlanetLocatorService
