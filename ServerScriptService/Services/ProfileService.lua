--[[
================================================================================
KOSMICMAZER — ProfileService
================================================================================

Purpose:
Manages player profiles with DataStore persistence.
Handles profile loading, creation, and saving with retry logic.

Version:
0.1

Features:
- LoadProfile(player) — Load existing profile or create new
- CreateNewProfile(player) — Create fresh profile for new players
- SaveProfile(player, profileData) — Save profile to DataStore
- GetProfile(player) — Get cached profile
- Retry logic with exponential backoff (3 attempts)
- Temporary in-memory fallback on DataStore failure
- Auto-save on PlayerRemoving

API:
- Initialize() — Setup DataStore connection
- LoadProfile(player) → {success, profile, isNewPlayer}
- CreateNewProfile(player) → {success, profile}
- SaveProfile(player, profileData) → {success}
- GetProfile(player) → profile or nil

Calls to:
- None (DataStore direct access)

Called from:
- BootSequence
- ServerBootstrap (Initialize)

Events:
- None

Dependencies:
- DataStoreService
- ReplicatedStorage/Game/GameConfig

ChangeLog:
- 0.1: Initial ProfileService with DataStore integration (2026-01-11)
================================================================================
]]

local ProfileService = {}

local VERSION = "0.1"
local MODULE_NAME = "ProfileService"

-- ============================================================================
-- SERVICES
-- ============================================================================

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local GameConfig = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("GameConfig"))

local DATASTORE_NAME = "PlayerProfiles"
local PROFILE_VERSION = 1
local MAX_RETRIES = 3
local RETRY_DELAY = 1 -- seconds (will use exponential backoff)

-- ============================================================================
-- STATE
-- ============================================================================

local profileStore = nil
local profileCache = {} -- [player.UserId] = profileData
local isInitialized = false

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

local function GetProfileKey(player)
	return "Player_" .. tostring(player.UserId)
end

local function CreateDefaultProfile(player)
	local timestamp = os.time()

	return {
		userId = player.UserId,
		createdAt = timestamp,
		lastLogin = timestamp,
		profileVersion = PROFILE_VERSION,

		-- Game State
		currentPlanet = GameConfig.StartPlanet,
		exploredLocations = {"Location1"}, -- Default for debug (scanner bypassed)

		-- Ship State
		shipState = {
			energyLevel = 100
		},

		-- Resources & Knowledge
		resources = {},
		knowledge = {}
	}
end

local function RetryOperation(operation, operationName, maxRetries)
	for attempt = 1, maxRetries do
		local success, result = pcall(operation)

		if success then
			return true, result
		else
			warn(string.format(
				"[%s %s][%s] Attempt %d/%d failed: %s",
				MODULE_NAME, VERSION, operationName, attempt, maxRetries, tostring(result)
			))

			if attempt < maxRetries then
				local delay = RETRY_DELAY * (2 ^ (attempt - 1)) -- Exponential backoff
				task.wait(delay)
			end
		end
	end

	return false, "Max retries exceeded"
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function ProfileService.Initialize()
	print(string.format("[%s %s][Initialize] Initializing ProfileService", MODULE_NAME, VERSION))

	local success, result = pcall(function()
		profileStore = DataStoreService:GetDataStore(DATASTORE_NAME)
	end)

	if not success then
		warn(string.format("[%s %s][Initialize] Failed to get DataStore: %s", MODULE_NAME, VERSION, tostring(result)))
		warn(string.format("[%s %s][Initialize] Will use temporary in-memory profiles", MODULE_NAME, VERSION))
		profileStore = nil
	else
		print(string.format("[%s %s][Initialize] DataStore connected: %s", MODULE_NAME, VERSION, DATASTORE_NAME))
	end

	-- Setup auto-save on player leaving
	Players.PlayerRemoving:Connect(function(player)
		local profile = profileCache[player.UserId]
		if profile then
			ProfileService.SaveProfile(player, profile)
			profileCache[player.UserId] = nil
		end
	end)

	isInitialized = true
	print(string.format("[%s %s][Initialize] ProfileService ready", MODULE_NAME, VERSION))
	return true
end

function ProfileService.LoadProfile(player)
	if not isInitialized then
		warn(string.format("[%s %s][LoadProfile] Service not initialized!", MODULE_NAME, VERSION))
		return false, nil, false
	end

	print(string.format("[%s %s][LoadProfile] Loading profile for %s (UserId: %d)",
		MODULE_NAME, VERSION, player.Name, player.UserId))

	local key = GetProfileKey(player)

	-- If DataStore unavailable, create temporary profile
	if not profileStore then
		warn(string.format("[%s %s][LoadProfile] DataStore unavailable, creating temporary profile", MODULE_NAME, VERSION))
		local tempProfile = CreateDefaultProfile(player)
		profileCache[player.UserId] = tempProfile
		return true, tempProfile, true
	end

	-- Try to load from DataStore
	local success, profileData = RetryOperation(function()
		return profileStore:GetAsync(key)
	end, "LoadProfile", MAX_RETRIES)

	if not success then
		warn(string.format("[%s %s][LoadProfile] Failed to load profile, creating temporary", MODULE_NAME, VERSION))
		local tempProfile = CreateDefaultProfile(player)
		profileCache[player.UserId] = tempProfile
		return true, tempProfile, true
	end

	-- Profile exists - returning player
	if profileData then
		print(string.format("[%s %s][LoadProfile] Existing profile found for %s", MODULE_NAME, VERSION, player.Name))

		-- Update last login
		profileData.lastLogin = os.time()

		profileCache[player.UserId] = profileData
		return true, profileData, false
	end

	-- No profile found - new player
	print(string.format("[%s %s][LoadProfile] No profile found for %s, will create new", MODULE_NAME, VERSION, player.Name))
	return ProfileService.CreateNewProfile(player)
end

function ProfileService.CreateNewProfile(player)
	print(string.format("[%s %s][CreateNewProfile] Creating new profile for %s", MODULE_NAME, VERSION, player.Name))

	local newProfile = CreateDefaultProfile(player)
	profileCache[player.UserId] = newProfile

	-- Save to DataStore immediately
	local saveSuccess = ProfileService.SaveProfile(player, newProfile)

	if saveSuccess then
		print(string.format("[%s %s][CreateNewProfile] New profile created and saved for %s", MODULE_NAME, VERSION, player.Name))
	else
		warn(string.format("[%s %s][CreateNewProfile] New profile created but save failed (temporary)", MODULE_NAME, VERSION))
	end

	return true, newProfile, true -- isNewPlayer = true
end

function ProfileService.SaveProfile(player, profileData)
	if not profileStore then
		warn(string.format("[%s %s][SaveProfile] DataStore unavailable, cannot save profile", MODULE_NAME, VERSION))
		return false
	end

	local key = GetProfileKey(player)

	local success, result = RetryOperation(function()
		return profileStore:SetAsync(key, profileData)
	end, "SaveProfile", MAX_RETRIES)

	if success then
		print(string.format("[%s %s][SaveProfile] Profile saved for %s", MODULE_NAME, VERSION, player.Name))
		return true
	else
		warn(string.format("[%s %s][SaveProfile] Failed to save profile for %s: %s",
			MODULE_NAME, VERSION, player.Name, tostring(result)))
		return false
	end
end

function ProfileService.GetProfile(player)
	return profileCache[player.UserId]
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

return ProfileService
