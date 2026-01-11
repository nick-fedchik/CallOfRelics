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

	-- LogOff Request (LogOn is now automatic on PlayerAdded)
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

	-- Automatically start boot sequence when player connects
	print(string.format("[%s %s][OnPlayerAdded] Player %s connected. Starting boot sequence...",
		MODULE_NAME, VERSION, player.Name))

	-- Start boot sequence (it will handle state transition internally)
	PlayerService.LogOnPlayer(player)
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
		player
	)

	if not success then
		warn(string.format("[%s %s][LogOnPlayer] Cannot start session for %s",
			MODULE_NAME, VERSION, player.Name))
		return false
	end

	print(string.format("[%s %s][LogOnPlayer] Starting session for %s",
		MODULE_NAME, VERSION, player.Name))

	-- Start 4-stage boot sequence
	local BootSequence = require(Core:WaitForChild("BootSequence"))
	local bootSuccess = BootSequence.StartBoot(player)

	if not bootSuccess then
		warn(string.format("[%s %s][LogOnPlayer] Boot sequence failed for %s", MODULE_NAME, VERSION, player.Name))

		-- Revert to LoggedOff state
		GameStateManager.RequestStateChange(
			GameStateManager.States.LoggedOff,
			player
		)

		return false
	end

	-- Boot sequence handles InGame transition when Stage 4 completes (after player clicks "Почати гру")
	print(string.format("[%s %s][LogOnPlayer] Boot sequence initiated for %s", MODULE_NAME, VERSION, player.Name))
	return true
end

function PlayerService.LogOffPlayer(player)
	print(string.format("[%s %s][LogOffPlayer] Logging off player %s",
		MODULE_NAME, VERSION, player.Name))

	-- Request state change: InGame → LoggedOff
	local success = GameStateManager.RequestStateChange(
		GameStateManager.States.LoggedOff,
		player
	)

	if success then
		print(string.format("[%s %s][LogOffPlayer] Player %s logged off. Returning to ScreenSaver.",
			MODULE_NAME, VERSION, player.Name))

		-- DON'T clear currentPlayer - player is still connected!
		-- Just restart Boot Sequence for re-login

		-- Wait a brief moment for UI to reset
		task.wait(0.5)

		-- Restart boot sequence automatically
		print(string.format("[%s %s][LogOffPlayer] Restarting boot sequence for %s",
			MODULE_NAME, VERSION, player.Name))
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
