--[[
================================================================================
KOSMICMAZER — ClientBootstrap
================================================================================

Purpose:
Main client initialization script. Boots client-side systems.
Implements client lifecycle from TDD Section 4.

Version:
0.1

Features:
- Initializes client-side services
- Sets up UI systems
- Manages ScreenSaver state
- Handles server state synchronization

API:
- None (auto-executes on client start)

Calls to:
- UIManager
- ScreenSaverUI

Called from:
- Roblox Client (auto-run)

Events:
- None

Dependencies:
- ReplicatedStorage events

ChangeLog:
- 0.1: Initial client boot sequence (2026-01-11)
================================================================================
]]

local VERSION = "0.1"
local MODULE_NAME = "ClientBootstrap"

print("================================================================================")
print("CALL OF RELICS: ORBITAL SILENCE - CLIENT")
print("Client Boot Sequence Started")
print(string.format("[%s %s] Initializing...", MODULE_NAME, VERSION))
print("================================================================================")

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

-- Disable default Roblox UI elements
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- ============================================================================
-- WAIT FOR DEPENDENCIES
-- ============================================================================

local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- LOAD CLIENT MODULES
-- ============================================================================

local StarterPlayerScripts = script.Parent.Parent
local UI = StarterPlayerScripts:WaitForChild("UI")

local ScreenSaverUI = require(UI:WaitForChild("ScreenSaverUI"))
local UIManager = require(UI:WaitForChild("UIManager"))

-- ============================================================================
-- BOOT SEQUENCE
-- ============================================================================

local function Boot()
	print(string.format("[%s %s][Boot] Client initializing for player: %s",
		MODULE_NAME, VERSION, player.Name))

	print(string.format("[%s %s][Boot] Phase 1: Initializing ScreenSaver UI", MODULE_NAME, VERSION))

	local success = ScreenSaverUI.Initialize()
	if not success then
		error("[ClientBootstrap] CRITICAL: ScreenSaverUI initialization failed!")
	end

	print(string.format("[%s %s][Boot] Phase 2: Initializing UIManager", MODULE_NAME, VERSION))

	success = UIManager.Initialize(ScreenSaverUI)
	if not success then
		error("[ClientBootstrap] CRITICAL: UIManager initialization failed!")
	end

	print(string.format("[%s %s][Boot] Phase 3: UI systems ready", MODULE_NAME, VERSION))
	print(string.format("[%s %s][Boot] Phase 4: Showing ScreenSaver", MODULE_NAME, VERSION))

	ScreenSaverUI.Show()

	print("================================================================================")
	print("CLIENT BOOT COMPLETE")
	print("ScreenSaver Active - Waiting for player input")
	print("================================================================================")
end

-- ============================================================================
-- ERROR HANDLING
-- ============================================================================

local bootSuccess, bootError = pcall(Boot)

if not bootSuccess then
	warn("================================================================================")
	warn("CLIENT BOOT FAILED!")
	warn("Error: " .. tostring(bootError))
	warn("================================================================================")
	error("Client boot sequence failed.")
end
