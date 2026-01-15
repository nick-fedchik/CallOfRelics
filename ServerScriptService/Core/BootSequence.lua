--[[
================================================================================
KOSMICMAZER — BootSequence
================================================================================

Purpose:
Orchestrates the 4-stage boot sequence for players entering the game.
Sends stage updates to client via BootStageUpdate RemoteEvent.
Integrates LocationService to load player's initial location (Orbit).

Version:
0.5

Features:
- Stage 1: Send game configuration (name, version)
- Stage 2: Send player information (avatar, name) + create temp spawn
- Stage 3: Load/create player profile via ProfileService
- Stage 4: Load initial location (Orbit) and prepare game space
- Spawn player in PilotSeat when "Почати гру" clicked
- Handles stage timing based on GameConfig
- Waits for ConfirmGameStart before transitioning to InGame
- Temporary SpawnLocation prevents respawn loops during boot

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
- 0.5: Add temp SpawnLocation to prevent respawn loops during boot (2026-01-15)
- 0.4: Integrated LocationService - load Orbit and spawn player (2026-01-12)
- 0.3: Enhanced boot sequence with dynamic progress (2026-01-12)
- 0.2: Added ProfileService integration (2026-01-11)
- 0.1: Initial 4-stage boot sequence implementation (2026-01-11)
================================================================================
]]

local BootSequence = {}

local VERSION = "0.5"
local MODULE_NAME = "BootSequence"

-- ============================================================================
-- SERVICES
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

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
local tempSpawnLocation = nil -- Temporary SpawnLocation for boot sequence

-- ============================================================================
-- TEMPORARY SPAWN LOCATION
-- ============================================================================

local function CreateTempSpawnLocation()
	if tempSpawnLocation and tempSpawnLocation.Parent then
		return tempSpawnLocation
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "TempBootSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, -500, 0)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Transparency = 1
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = Workspace

	tempSpawnLocation = spawn
	return spawn
end

local function RemoveTempSpawnLocation()
	if tempSpawnLocation and tempSpawnLocation.Parent then
		tempSpawnLocation:Destroy()
		tempSpawnLocation = nil
	end
end

local function SpawnPlayerAtTempLocation(player)
	CreateTempSpawnLocation()
	player:LoadCharacter()

	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if hrp then
		hrp.Anchored = true
		hrp.CFrame = CFrame.new(0, -495, 0)
	end
end

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
	local progressData = CalculateStageProgress(2)
	SpawnPlayerAtTempLocation(player)

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
	local progressData = CalculateStageProgress(3)
	local success, profile, isNewPlayer = ProfileService.LoadProfile(player)

	if not success then
		warn(string.format("[%s %s] Profile loading failed for %s", MODULE_NAME, VERSION, player.Name))
		BootStageUpdate:FireClient(player, 3, {
			success = false,
			isNewPlayer = false,
			error = "ProfileLoadFailed",
			errorMessage = GameConfig.ErrorMessages.ProfileLoadFailed,
			canRetry = GameConfig.ErrorRetryEnabled,
			progress = progressData.progressPercent,
			totalStages = progressData.totalStages,
			stageNumber = progressData.stageNumber,
		})
		return false, nil
	end

	-- Log player status (key info only)
	if isNewPlayer then
		print(string.format("[%s %s] NEW PLAYER: %s", MODULE_NAME, VERSION, player.Name))
	else
		print(string.format("[%s %s] RETURNING PLAYER: %s", MODULE_NAME, VERSION, player.Name))
	end

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
	local progressData = CalculateStageProgress(4)

	local exploredCount = 0
	for _ in pairs(profile.exploredLocations) do
		exploredCount = exploredCount + 1
	end

	-- Validate assets
	local ServerStorage = game:GetService("ServerStorage")
	local planetFolder = ServerStorage.Planets:FindFirstChild(profile.currentPlanet)

	if not planetFolder then
		warn(string.format("[%s %s] Planet not found: %s", MODULE_NAME, VERSION, profile.currentPlanet))
	elseif not planetFolder:FindFirstChild("Orbit") then
		warn(string.format("[%s %s] Orbit not found for %s", MODULE_NAME, VERSION, profile.currentPlanet))
	end

	local stageData = {
		ready = true,
		currentPlanet = profile.currentPlanet,
		exploredLocations = exploredCount,
		shipEnergy = profile.shipState.energyLevel,
		progress = progressData.progressPercent,
		totalStages = progressData.totalStages,
		stageNumber = progressData.stageNumber,
	}

	BootStageUpdate:FireClient(player, 4, stageData)

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
	print(string.format("[%s %s] Boot sequence started for %s", MODULE_NAME, VERSION, player.Name))

	activeBootSessions[player.UserId] = { stage = 1 }

	Stage1_GameConfiguration(player)
	Stage2_PlayerInformation(player)

	local profileSuccess, profile = Stage3_ProfileLoading(player)
	if not profileSuccess then
		activeBootSessions[player.UserId] = nil
		return false
	end

	Stage4_ReadyState(player, profile)
	return true
end

-- ============================================================================
-- CONFIRMATION HANDLER
-- ============================================================================

ConfirmGameStart.OnServerEvent:Connect(function(player)
	local session = activeBootSessions[player.UserId]

	if not session or not session.waitingForConfirm then
		return
	end

	RemoveTempSpawnLocation()
	activeBootSessions[player.UserId] = nil

	local stateSuccess = GameStateManager.RequestStateChange(
		GameStateManager.States.InGame,
		{ player = player }
	)

	if not stateSuccess then
		warn(string.format("[%s %s] Failed to transition %s to InGame", MODULE_NAME, VERSION, player.Name))
		return
	end

	local TransitionService = require(Services:WaitForChild("TransitionService"))
	local transitionSuccess = TransitionService.StartGameSequence(player)

	if transitionSuccess then
		print(string.format("[%s %s] ✓ Game started for %s", MODULE_NAME, VERSION, player.Name))
	else
		warn(string.format("[%s %s] Transition failed for %s", MODULE_NAME, VERSION, player.Name))
	end
end)

-- ============================================================================
-- RETRY HANDLER
-- ============================================================================

local RetryBootStage = RemoteEvents:WaitForChild("RetryBootStage")

RetryBootStage.OnServerEvent:Connect(function(player, stageNumber)
	local session = activeBootSessions[player.UserId]
	if not session or stageNumber ~= 3 then
		return
	end

	local profileSuccess, profile = Stage3_ProfileLoading(player)
	if profileSuccess then
		Stage4_ReadyState(player, profile)
	end
end)

-- ============================================================================
-- CLEANUP
-- ============================================================================

game.Players.PlayerRemoving:Connect(function(player)
	activeBootSessions[player.UserId] = nil
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

return BootSequence
