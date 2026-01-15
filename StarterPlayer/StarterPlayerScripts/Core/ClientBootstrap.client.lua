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
- 0.2: Added silent boot mute system (2026-01-15)
- 0.1: Initial client boot sequence (2026-01-11)
================================================================================
]]

local VERSION = "0.2"
local MODULE_NAME = "ClientBootstrap"

-- ============================================================================
-- PREVENT DOUBLE EXECUTION
-- ============================================================================

-- Check if already initialized (prevents double-run in StarterPlayerScripts)
local RunService = game:GetService("RunService")
if not RunService:IsClient() then return end

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Use a unique attribute to prevent double initialization
if player:GetAttribute("ClientBootstrapInitialized") then
	return
end
player:SetAttribute("ClientBootstrapInitialized", true)


-- ============================================================================
-- MUTE SPAWN SOUNDS DURING BOOT
-- ============================================================================

-- Must be set up BEFORE server spawns character (during boot sequence)
local bootMuteActive = true

local function muteSound(sound)
	sound.Volume = 0
	if sound.IsPlaying then
		sound:Stop()
	end
end

local function processCharacter(character)
	-- Mute existing sounds
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("Sound") and bootMuteActive then
			muteSound(desc)
		end
	end
	-- Catch sounds added async (Roblox adds them after character creation)
	character.DescendantAdded:Connect(function(desc)
		if desc:IsA("Sound") and bootMuteActive then
			muteSound(desc)
		end
	end)
end

player.CharacterAdded:Connect(function(character)
	if bootMuteActive then
		processCharacter(character)
	end
end)

-- Listen for InGame state to unmute
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local stateChanged = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StateChanged")
stateChanged.OnClientEvent:Connect(function(newState)
	if newState == "InGame" then
		bootMuteActive = false
		-- Restore default volumes
		if player.Character then
			for _, desc in ipairs(player.Character:GetDescendants()) do
				if desc:IsA("Sound") then
					local defaults = {Running=0.65, Climbing=0.7, Died=1, FreeFalling=0.5, Jumping=0.5, Landing=1, Splash=0.7, Swimming=0.7}
					desc.Volume = defaults[desc.Name] or 0.5
				end
			end
		end
	elseif newState == "LoggedOff" then
		bootMuteActive = true -- Re-enable for next boot
	end
end)

-- ============================================================================
-- SERVICES
-- ============================================================================

local StarterGui = game:GetService("StarterGui")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

-- Disable default Roblox UI elements
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- ============================================================================
-- LOAD CLIENT MODULES
-- ============================================================================

local StarterPlayerScripts = script.Parent.Parent
local UI = StarterPlayerScripts:WaitForChild("UI")
local Core = StarterPlayerScripts:WaitForChild("Core")

local ScreenSaverUI = require(UI:WaitForChild("ScreenSaverUI"))
local StatusBarUI = require(UI:WaitForChild("StatusBarUI"))
local UIManager = require(UI:WaitForChild("UIManager"))
local SeatUIManager = require(UI:WaitForChild("SeatUIManager"))
local SeatController = require(Core:WaitForChild("SeatController"))
local TransitionUI = require(UI:WaitForChild("TransitionUI"))

-- ============================================================================
-- BOOT SEQUENCE
-- ============================================================================

local function Boot()
	local success = ScreenSaverUI.Initialize()
	if not success then
		error("[ClientBootstrap] ScreenSaverUI initialization failed!")
	end

	success = StatusBarUI.Initialize()
	if not success then
		error("[ClientBootstrap] StatusBarUI initialization failed!")
	end

	StatusBarUI.SetupProfileSync()

	success = UIManager.Initialize(ScreenSaverUI, StatusBarUI)
	if not success then
		error("[ClientBootstrap] UIManager initialization failed!")
	end

	success = SeatUIManager.Initialize()
	if not success then
		error("[ClientBootstrap] SeatUIManager initialization failed!")
	end

	success = SeatController.Initialize(SeatUIManager)
	if not success then
		error("[ClientBootstrap] SeatController initialization failed!")
	end

	success = TransitionUI.Initialize()
	if not success then
		error("[ClientBootstrap] TransitionUI initialization failed!")
	end

	ScreenSaverUI.Show()

	print(string.format("[%s %s] ✓ Client ready for %s", MODULE_NAME, VERSION, player.Name))
end

-- ============================================================================
-- ERROR HANDLING
-- ============================================================================

local bootSuccess, bootError = pcall(Boot)

if not bootSuccess then
	warn("[ClientBootstrap] BOOT FAILED: " .. tostring(bootError))
	error("Client boot sequence failed.")
end
