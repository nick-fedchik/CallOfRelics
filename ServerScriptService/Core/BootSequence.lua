--[[
================================================================================
KOSMICMAZER — BootSequence
================================================================================

Purpose:
Orchestrates the 4-stage boot sequence for players entering the game.
Sends stage updates to client via BootStageUpdate RemoteEvent.

Version:
0.1

Features:
- Stage 1: Send game configuration (name, version)
- Stage 2: Send player information (avatar, name)
- Stage 3: Load/create player profile via ProfileService
- Stage 4: Prepare game space, wait for player confirmation
- Handles stage timing based on GameConfig
- Waits for ConfirmGameStart before transitioning to InGame

API:
- StartBoot(player) — Begin 4-stage boot sequence

Calls to:
- GameConfig (ReplicatedStorage)
- ProfileService
- GameStateManager
- RemoteEvents (BootStageUpdate)

Called from:
- PlayerService.LogOnPlayer()

Events:
- Sends: BootStageUpdate (Server → Client)
- Listens: ConfirmGameStart (Client → Server)

Dependencies:
- GameConfig
- ProfileService
- GameStateManager
- RemoteEvents folder

ChangeLog:
- 0.1: Initial 4-stage boot sequence implementation (2026-01-11)
================================================================================
]]

local BootSequence = {}

local VERSION = "0.1"
local MODULE_NAME = "BootSequence"

-- ============================================================================
-- SERVICES
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================================
-- MODULES
-- ============================================================================

local GameConfig = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("GameConfig"))

local Services = ServerScriptService:WaitForChild("Services")
local ProfileService = require(Services:WaitForChild("ProfileService"))

local Core = ServerScriptService:WaitForChild("Core")
local GameStateManager = require(Core:WaitForChild("GameStateManager"))

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BootStageUpdate = RemoteEvents:WaitForChild("BootStageUpdate")
local ConfirmGameStart = RemoteEvents:WaitForChild("ConfirmGameStart")

-- ============================================================================
-- STATE
-- ============================================================================

local activeBootSessions = {} -- [player.UserId] = {stage, profile, waitingForConfirm}

-- ============================================================================
-- STAGE FUNCTIONS
-- ============================================================================

local function Stage1_GameConfiguration(player)
	print(string.format("[%s %s][Stage1] Sending game configuration to %s", MODULE_NAME, VERSION, player.Name))

	local stageData = {
		gameName = GameConfig.GameName,
		gameSubtitle = GameConfig.GameSubtitle,
		version = GameConfig.Version,
		versionTag = GameConfig.VersionTag
	}

	BootStageUpdate:FireClient(player, 1, stageData)

	task.wait(GameConfig.Stage1Duration)
end

local function Stage2_PlayerInformation(player)
	print(string.format("[%s %s][Stage2] Player connected: %s (UserId: %d, DisplayName: %s)",
		MODULE_NAME, VERSION, player.Name, player.UserId, player.DisplayName))

	local stageData = {
		playerName = player.Name,
		displayName = player.DisplayName,
		userId = player.UserId
	}

	BootStageUpdate:FireClient(player, 2, stageData)

	task.wait(GameConfig.Stage2Duration)
end

local function Stage3_ProfileLoading(player)
	print(string.format("[%s %s][Stage3] Loading profile for %s", MODULE_NAME, VERSION, player.Name))

	-- Load or create profile
	local success, profile, isNewPlayer = ProfileService.LoadProfile(player)

	if not success then
		warn(string.format("[%s %s][Stage3] Profile loading failed for %s", MODULE_NAME, VERSION, player.Name))

		BootStageUpdate:FireClient(player, 3, {
			success = false,
			isNewPlayer = false,
			error = "Failed to load profile"
		})

		return false, nil
	end

	-- Log player status
	if isNewPlayer then
		print(string.format("[%s %s][Stage3] NEW PLAYER: %s — Profile created with planet %s",
			MODULE_NAME, VERSION, player.Name, profile.currentPlanet))
	else
		print(string.format("[%s %s][Stage3] RETURNING PLAYER: %s — Last login: %s, Current planet: %s",
			MODULE_NAME, VERSION, player.Name,
			os.date("%Y-%m-%d %H:%M:%S", profile.lastLogin),
			profile.currentPlanet))
	end

	-- Send to client
	local stageData = {
		success = true,
		isNewPlayer = isNewPlayer,
		currentPlanet = profile.currentPlanet
	}

	BootStageUpdate:FireClient(player, 3, stageData)

	task.wait(GameConfig.Stage3Duration)

	return true, profile
end

local function Stage4_ReadyState(player, profile)
	print(string.format("[%s %s][Stage4] Preparing game space for %s", MODULE_NAME, VERSION, player.Name))

	-- Log current game state
	local exploredCount = 0
	for _ in pairs(profile.exploredLocations) do
		exploredCount = exploredCount + 1
	end

	print(string.format("[%s %s][Stage4] Game state for %s:", MODULE_NAME, VERSION, player.Name))
	print(string.format("  - Current Planet: %s", profile.currentPlanet))
	print(string.format("  - Explored Locations: %d", exploredCount))
	print(string.format("  - Ship Energy: %d", profile.shipState.energyLevel))

	-- Send ready state to client
	local stageData = {
		ready = true,
		currentPlanet = profile.currentPlanet,
		exploredLocations = exploredCount,
		shipEnergy = profile.shipState.energyLevel
	}

	BootStageUpdate:FireClient(player, 4, stageData)

	print(string.format("[%s %s][Stage4] Ready — Waiting for player to click 'Почати гру'", MODULE_NAME, VERSION))

	-- Mark session as waiting for confirmation
	activeBootSessions[player.UserId] = {
		stage = 4,
		profile = profile,
		waitingForConfirm = true
	}
end

-- ============================================================================
-- BOOT SEQUENCE
-- ============================================================================

function BootSequence.StartBoot(player)
	print(string.format("[%s %s][StartBoot] Beginning boot sequence for %s", MODULE_NAME, VERSION, player.Name))

	-- Initialize session
	activeBootSessions[player.UserId] = { stage = 1 }

	-- Stage 1: Game Configuration
	Stage1_GameConfiguration(player)

	-- Stage 2: Player Information
	Stage2_PlayerInformation(player)

	-- Stage 3: Profile Loading
	local profileSuccess, profile = Stage3_ProfileLoading(player)

	if not profileSuccess then
		warn(string.format("[%s %s][StartBoot] Boot sequence failed at Stage 3 for %s", MODULE_NAME, VERSION, player.Name))
		activeBootSessions[player.UserId] = nil
		return false
	end

	-- Stage 4: Ready State (waits for user confirmation)
	Stage4_ReadyState(player, profile)

	print(string.format("[%s %s][StartBoot] Boot sequence Stages 1-4 complete for %s", MODULE_NAME, VERSION, player.Name))
	return true
end

-- ============================================================================
-- CONFIRMATION HANDLER
-- ============================================================================

ConfirmGameStart.OnServerEvent:Connect(function(player)
	local session = activeBootSessions[player.UserId]

	if not session then
		warn(string.format("[%s %s][ConfirmGameStart] No active boot session for %s", MODULE_NAME, VERSION, player.Name))
		return
	end

	if not session.waitingForConfirm then
		warn(string.format("[%s %s][ConfirmGameStart] Session not waiting for confirmation: %s", MODULE_NAME, VERSION, player.Name))
		return
	end

	print(string.format("[%s %s][ConfirmGameStart] Player %s confirmed game start — transitioning to InGame", MODULE_NAME, VERSION, player.Name))

	-- Transition to InGame state
	local success = GameStateManager.RequestStateChange(
		GameStateManager.States.InGame,
		{ player = player }
	)

	if success then
		print(string.format("[%s %s][ConfirmGameStart] Successfully transitioned %s to InGame", MODULE_NAME, VERSION, player.Name))
	else
		warn(string.format("[%s %s][ConfirmGameStart] Failed to transition %s to InGame", MODULE_NAME, VERSION, player.Name))
	end

	-- Clean up session
	activeBootSessions[player.UserId] = nil
end)

-- ============================================================================
-- CLEANUP
-- ============================================================================

game.Players.PlayerRemoving:Connect(function(player)
	if activeBootSessions[player.UserId] then
		print(string.format("[%s %s][Cleanup] Removing boot session for %s", MODULE_NAME, VERSION, player.Name))
		activeBootSessions[player.UserId] = nil
	end
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

return BootSequence
