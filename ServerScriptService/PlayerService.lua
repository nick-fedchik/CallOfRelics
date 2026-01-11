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

local GameStateManager = require(ServerScriptService:WaitForChild("GameStateManager"))

-- ============================================================================
-- STATE
-- ============================================================================

local currentPlayer = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function PlayerService.Initialize()
	print(string.format("[%s %s][Initialize] PlayerService initialized", MODULE_NAME, VERSION))

	-- Listen to player connections
	Players.PlayerAdded:Connect(function(player)
		PlayerService.OnPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerService.OnPlayerRemoving(player)
	end)

	-- Setup RemoteEvent handlers
	PlayerService.SetupRemoteEvents()

	return true
end

-- ============================================================================
-- REMOTE EVENT HANDLERS
-- ============================================================================

function PlayerService.SetupRemoteEvents()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- LogOn Request
	local logOnRequest = remoteEvents:WaitForChild("LogOnRequest")
	logOnRequest.OnServerEvent:Connect(function(player)
		print(string.format("[%s %s][LogOnRequest] Received from %s", MODULE_NAME, VERSION, player.Name))
		PlayerService.LogOnPlayer(player)
	end)

	-- LogOff Request
	local logOffRequest = remoteEvents:WaitForChild("LogOffRequest")
	logOffRequest.OnServerEvent:Connect(function(player)
		print(string.format("[%s %s][LogOffRequest] Received from %s", MODULE_NAME, VERSION, player.Name))
		PlayerService.LogOffPlayer(player)
	end)

	print(string.format("[%s %s][SetupRemoteEvents] RemoteEvent handlers connected", MODULE_NAME, VERSION))
end

-- ============================================================================
-- PLAYER LIFECYCLE
-- ============================================================================

function PlayerService.OnPlayerAdded(player)
	print(string.format("[%s %s][OnPlayerAdded] Player joined: %s", MODULE_NAME, VERSION, player.Name))

	-- Single-player game: only one player allowed
	if currentPlayer then
		warn(string.format("[%s %s][OnPlayerAdded] Game already occupied by %s. Rejecting %s",
			MODULE_NAME, VERSION, currentPlayer.Name, player.Name))
		player:Kick("Game is already in use. This is a single-player game.")
		return
	end

	currentPlayer = player

	-- Player is connected but not logged in yet (still in ScreenSaver)
	print(string.format("[%s %s][OnPlayerAdded] Player %s connected. Awaiting LogOn request.",
		MODULE_NAME, VERSION, player.Name))
end

function PlayerService.OnPlayerRemoving(player)
	print(string.format("[%s %s][OnPlayerRemoving] Player leaving: %s", MODULE_NAME, VERSION, player.Name))

	if currentPlayer == player then
		PlayerService.LogOffPlayer(player)
	end
end

-- ============================================================================
-- LOGON / LOGOFF (EPIC 1 Stories)
-- ============================================================================

function PlayerService.LogOnPlayer(player)
	if player ~= currentPlayer then
		warn(string.format("[%s %s][LogOnPlayer] Player %s is not the current player",
			MODULE_NAME, VERSION, player.Name))
		return false
	end

	-- Request state change: LoggedOff → Initializing
	local success = GameStateManager.RequestStateChange(
		GameStateManager.States.Initializing,
		{ player = player }
	)

	if not success then
		warn(string.format("[%s %s][LogOnPlayer] Cannot start session for %s",
			MODULE_NAME, VERSION, player.Name))
		return false
	end

	print(string.format("[%s %s][LogOnPlayer] Starting session for %s",
		MODULE_NAME, VERSION, player.Name))

	-- Boot player into game (will be implemented in next phase)
	-- For now, just transition to InGame
	task.wait(1) -- Simulate boot time

	success = GameStateManager.RequestStateChange(
		GameStateManager.States.InGame,
		{ player = player }
	)

	if success then
		print(string.format("[%s %s][LogOnPlayer] Player %s is now in game",
			MODULE_NAME, VERSION, player.Name))
	end

	return success
end

function PlayerService.LogOffPlayer(player)
	print(string.format("[%s %s][LogOffPlayer] Logging off player %s",
		MODULE_NAME, VERSION, player.Name))

	-- Request state change: InGame → LoggedOff
	local success = GameStateManager.RequestStateChange(
		GameStateManager.States.LoggedOff,
		{ player = player }
	)

	if success then
		print(string.format("[%s %s][LogOffPlayer] Player %s logged off. Returning to ScreenSaver.",
			MODULE_NAME, VERSION, player.Name))
		currentPlayer = nil
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
