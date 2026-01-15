--[[
================================================================================
KOSMICMAZER — PlayerService
================================================================================

Purpose:
Manages player lifecycle: connection, authentication, disconnection.
Handles LogOn/LogOff flow from EPIC 1.

Version:
0.1

Features:
- Handles player join (LogOn request)
- Handles player leave (LogOff)
- Manages safe disconnects
- One player at a time (single-player game)

API:
- Initialize() — Starts the service
- LogOnPlayer(player) — Initiates player session
- LogOffPlayer(player) — Ends player session

Calls to:
- GameStateManager

Called from:
- ServerBootstrap
- RemoteEvents (client requests)

Events:
- PlayerAdded
- PlayerRemoving

Dependencies:
- GameStateManager

ChangeLog:
- 0.1: Initial player lifecycle management (2026-01-11)
================================================================================
]]

local PlayerService = {}

local VERSION = "0.1"
local MODULE_NAME = "PlayerService"

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================================
-- DEPENDENCIES
-- ============================================================================

local Core = ServerScriptService:WaitForChild("Core")
local GameStateManager = require(Core:WaitForChild("GameStateManager"))

-- ============================================================================
-- STATE
-- ============================================================================

local currentPlayer = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function PlayerService.Initialize()
	-- Disable auto character loading to prevent spawn sound during boot
	Players.CharacterAutoLoads = false

	Players.PlayerAdded:Connect(function(player)
		PlayerService.OnPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerService.OnPlayerRemoving(player)
	end)

	PlayerService.SetupRemoteEvents()

	print(string.format("[%s %s] ✓ PlayerService ready", MODULE_NAME, VERSION))
	return true
end

-- ============================================================================
-- REMOTE EVENT HANDLERS
-- ============================================================================

function PlayerService.SetupRemoteEvents()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	local logOffRequest = remoteEvents:WaitForChild("LogOffRequest")
	logOffRequest.OnServerEvent:Connect(function(player)
		PlayerService.LogOffPlayer(player)
	end)
end

-- ============================================================================
-- PLAYER LIFECYCLE
-- ============================================================================

function PlayerService.OnPlayerAdded(player)
	-- Single-player game: only one player allowed
	if currentPlayer then
		player:Kick("Game is already in use. This is a single-player game.")
		return
	end

	currentPlayer = player
	print(string.format("[%s %s] Player joined: %s", MODULE_NAME, VERSION, player.Name))
	PlayerService.LogOnPlayer(player)
end

function PlayerService.OnPlayerRemoving(player)
	if currentPlayer == player then
		print(string.format("[%s %s] Player leaving: %s", MODULE_NAME, VERSION, player.Name))
		PlayerService.LogOffPlayer(player)
	end
end

-- ============================================================================
-- LOGON / LOGOFF (EPIC 1 Stories)
-- ============================================================================

function PlayerService.LogOnPlayer(player)
	if player ~= currentPlayer then
		return false
	end

	local success = GameStateManager.RequestStateChange(
		GameStateManager.States.Initializing,
		player
	)

	if not success then
		return false
	end

	local BootSequence = require(Core:WaitForChild("BootSequence"))
	local bootSuccess = BootSequence.StartBoot(player)

	if not bootSuccess then
		warn(string.format("[%s %s] Boot failed for %s", MODULE_NAME, VERSION, player.Name))
		GameStateManager.RequestStateChange(GameStateManager.States.LoggedOff, player)
		return false
	end

	return true
end

function PlayerService.LogOffPlayer(player)
	local success = GameStateManager.RequestStateChange(
		GameStateManager.States.LoggedOff,
		player
	)

	if success then
		task.wait(0.5)
		PlayerService.LogOnPlayer(player)
	end

	return success
end

-- ============================================================================
-- GETTERS
-- ============================================================================

function PlayerService.GetCurrentPlayer()
	return currentPlayer
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

return PlayerService
