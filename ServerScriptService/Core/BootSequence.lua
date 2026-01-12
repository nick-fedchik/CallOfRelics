--[[
================================================================================
KOSMICMAZER — BootSequence
================================================================================

Purpose:
Orchestrates the 4-stage boot sequence for players entering the game.
Sends stage updates to client via BootStageUpdate RemoteEvent.
Integrates LocationService to load player's initial location (Orbit).

Version:
0.4

Features:
- Stage 1: Send game configuration (name, version)
- Stage 2: Send player information (avatar, name)
- Stage 3: Load/create player profile via ProfileService
- Stage 4: Load initial location (Orbit) and prepare game space
- Spawn player in PilotSeat when "Почати гру" clicked
- Handles stage timing based on GameConfig
- Waits for ConfirmGameStart before transitioning to InGame

API:
- StartBoot(player) — Begin 4-stage boot sequence

Calls to:
- GameConfig (ReplicatedStorage)
- ProfileService
- LocationService
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
- LocationService
- GameStateManager
- RemoteEvents folder

ChangeLog:
- 0.4: Integrated LocationService - load Orbit and spawn player (2026-01-12)
- 0.3: Enhanced boot sequence with dynamic progress (2026-01-12)
- 0.2: Added ProfileService integration (2026-01-11)
- 0.1: Initial 4-stage boot sequence implementation (2026-01-11)
================================================================================
]]

local BootSequence = {}

local VERSION = "0.4"
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
local LocationService = require(Services:WaitForChild("LocationService"))

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
-- PROGRESS CALCULATION
-- ============================================================================

local function CalculateStageProgress(stageNumber)
	local totalStages = #GameConfig.BootStages
	local progress = math.floor((stageNumber / totalStages) * 100)

	return {
		stageNumber = stageNumber,
		totalStages = totalStages,
		progressPercent = progress,
	}
end

-- ============================================================================
-- STAGE FUNCTIONS
-- ============================================================================

local function Stage1_GameConfiguration(player)
	print(string.format("[%s %s][Stage1] Sending game configuration to %s", MODULE_NAME, VERSION, player.Name))

	local progressData = CalculateStageProgress(1)

	local stageData = {
		gameName = GameConfig.GameName,
		gameSubtitle = GameConfig.GameSubtitle,
		version = GameConfig.Version,
		versionTag = GameConfig.VersionTag,
		-- Progress data for client
		progress = progressData.progressPercent,
		totalStages = progressData.totalStages,
		stageNumber = progressData.stageNumber,
	}

	BootStageUpdate:FireClient(player, 1, stageData)

	task.wait(GameConfig.BootStages[1].duration)
end

local function Stage2_PlayerInformation(player)
	print(string.format("[%s %s][Stage2] Player connected: %s (UserId: %d, DisplayName: %s)",
		MODULE_NAME, VERSION, player.Name, player.UserId, player.DisplayName))

	local progressData = CalculateStageProgress(2)

	local stageData = {
		playerName = player.Name,
		displayName = player.DisplayName,
		userId = player.UserId,
		-- Progress data
		progress = progressData.progressPercent,
		totalStages = progressData.totalStages,
		stageNumber = progressData.stageNumber,
	}

	BootStageUpdate:FireClient(player, 2, stageData)

	task.wait(GameConfig.BootStages[2].duration)
end

local function Stage3_ProfileLoading(player)
	print(string.format("[%s %s][Stage3] Loading profile for %s", MODULE_NAME, VERSION, player.Name))

	local progressData = CalculateStageProgress(3)

	-- Load or create profile
	local success, profile, isNewPlayer = ProfileService.LoadProfile(player)

	if not success then
		warn(string.format("[%s %s][Stage3] Profile loading failed for %s", MODULE_NAME, VERSION, player.Name))

		-- Send error state to client
		BootStageUpdate:FireClient(player, 3, {
			success = false,
			isNewPlayer = false,
			error = "ProfileLoadFailed",
			errorMessage = GameConfig.ErrorMessages.ProfileLoadFailed,
			canRetry = GameConfig.ErrorRetryEnabled,
			-- Still include progress for UI consistency
			progress = progressData.progressPercent,
			totalStages = progressData.totalStages,
			stageNumber = progressData.stageNumber,
		})

		return false, nil
	end

	-- Log player status
	if isNewPlayer then
		print(string.format("[%s %s][Stage3] NEW PLAYER: %s — Profile created with planet %s",
			MODULE_NAME, VERSION, player.Name, profile.currentPlanet))
	else
		local lastLoginStr = profile.lastLogin and os.date("%Y-%m-%d %H:%M:%S", profile.lastLogin) or "Unknown"
		print(string.format("[%s %s][Stage3] RETURNING PLAYER: %s — Last login: %s, Current planet: %s",
			MODULE_NAME, VERSION, player.Name, lastLoginStr, profile.currentPlanet))
	end

	-- Send success to client
	local stageData = {
		success = true,
		isNewPlayer = isNewPlayer,
		currentPlanet = profile.currentPlanet,
		-- Progress data
		progress = progressData.progressPercent,
		totalStages = progressData.totalStages,
		stageNumber = progressData.stageNumber,
	}

	BootStageUpdate:FireClient(player, 3, stageData)

	task.wait(GameConfig.BootStages[3].duration)

	return true, profile
end

local function Stage4_ReadyState(player, profile)
	print(string.format("[%s %s][Stage4] Preparing game space for %s", MODULE_NAME, VERSION, player.Name))

	local progressData = CalculateStageProgress(4)

	-- Log current game state
	local exploredCount = 0
	for _ in pairs(profile.exploredLocations) do
		exploredCount = exploredCount + 1
	end

	print(string.format("[%s %s][Stage4] Game state for %s:", MODULE_NAME, VERSION, player.Name))
	print(string.format("  - Current Planet: %s", profile.currentPlanet))
	print(string.format("  - Explored Locations: %d", exploredCount))
	print(string.format("  - Ship Energy: %d", profile.shipState.energyLevel))

	-- CRITICAL: Load initial location (Orbit of current planet)
	print(string.format("[%s %s][Stage4] Loading initial location: %s/Orbit",
		MODULE_NAME, VERSION, profile.currentPlanet))

	local loadSuccess = LocationService.LoadLocation(player, profile.currentPlanet, "Orbit")

	if not loadSuccess then
		warn(string.format("[%s %s][Stage4] Failed to load location for %s",
			MODULE_NAME, VERSION, player.Name))
		-- TODO: Handle location load failure (return to ScreenSaver or retry)
	end

	-- Send ready state to client
	local stageData = {
		ready = true,
		currentPlanet = profile.currentPlanet,
		exploredLocations = exploredCount,
		shipEnergy = profile.shipState.energyLevel,
		-- Progress data (100%)
		progress = progressData.progressPercent,
		totalStages = progressData.totalStages,
		stageNumber = progressData.stageNumber,
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

	-- CRITICAL: Spawn player in loaded location
	LocationService.SpawnPlayerInLocation(player, "auto")

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
-- RETRY HANDLER
-- ============================================================================

local RetryBootStage = RemoteEvents:WaitForChild("RetryBootStage")

RetryBootStage.OnServerEvent:Connect(function(player, stageNumber)
	print(string.format("[%s %s][RetryBootStage] Player %s requested retry for stage %d",
		MODULE_NAME, VERSION, player.Name, stageNumber))

	local session = activeBootSessions[player.UserId]

	if not session then
		warn(string.format("[%s %s][RetryBootStage] No active session for %s", MODULE_NAME, VERSION, player.Name))
		return
	end

	-- Only allow retry for Stage 3 (profile loading)
	if stageNumber ~= 3 then
		warn(string.format("[%s %s][RetryBootStage] Invalid retry stage %d for %s",
			MODULE_NAME, VERSION, stageNumber, player.Name))
		return
	end

	-- Retry Stage 3
	print(string.format("[%s %s][RetryBootStage] Retrying Stage 3 for %s", MODULE_NAME, VERSION, player.Name))

	local profileSuccess, profile = Stage3_ProfileLoading(player)

	if profileSuccess then
		-- Continue to Stage 4
		Stage4_ReadyState(player, profile)
	else
		-- Stage 3 will send error state to client
		warn(string.format("[%s %s][RetryBootStage] Retry failed for %s", MODULE_NAME, VERSION, player.Name))
	end
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
