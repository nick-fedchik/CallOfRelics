--[[
================================================================================
KOSMICMAZER — ProfileService
================================================================================

Purpose:
Manages player profiles with DataStore persistence.
Handles profile loading, creation, saving, and progression tracking.

Version:
0.4

Features:
- LoadProfile(player) — Load existing profile or create new
- CreateNewProfile(player) — Create fresh profile for new players
- SaveProfile(player, profileData) — Save profile to DataStore
- GetProfile(player) — Get cached profile
- Profile v2 schema with per-planet location tracking
- Backward compatible v1 → v2 migration
- Retry logic with exponential backoff (3 attempts)
- Temporary in-memory fallback on DataStore failure
- Auto-save on PlayerRemoving
- Save on PilotSeat sit (if profile changed)
- Knowledge saved immediately (never lost per GDD)

API:
- Initialize() — Setup DataStore connection
- LoadProfile(player) → {success, profile, isNewPlayer}
- CreateNewProfile(player) → {success, profile}
- SaveProfile(player, profileData) → {success}
- GetProfile(player) → profile or nil
- UpdateProfile(player, updates) → success
- MarkLocationDiscovered(player, planetId, locationName) → success
- UpdateCurrentState(player, planetId, locationName) → success
- AddResources(player, resourceId, quantity) → success
- RemoveResources(player, resourceId, quantity) → success
- AddKnowledge(player, knowledgeEntry) → success
- GetExploredLocationsForPlanet(player, planetId) → array
- IsProfileChanged(player) → boolean
- SaveIfChanged(player) → success

Calls to:
- None (DataStore direct access)

Called from:
- BootSequence
- ServerBootstrap (Initialize)
- TransitionService

Events:
- Listens: RequestProfileSync (Client → Server)
- Fires: ProfileUpdate (Server → Client)

Dependencies:
- DataStoreService
- ReplicatedStorage/Game/GameConfig

ChangeLog:
- 0.1: Initial ProfileService with DataStore integration (2026-01-11)
- 0.2: EPIC 8 - Full progression tracking, auto-save, v2 schema (2026-01-15)
- 0.3: GDD compliance - save on PilotSeat sit, knowledge saved immediately (2026-01-15)
- 0.4: Send displayName instead of ID for planet/location in ProfileUpdate (2026-01-15)
================================================================================
]]

local ProfileService = {}

local VERSION = "0.4"
local MODULE_NAME = "ProfileService"

-- ============================================================================
-- SERVICES
-- ============================================================================

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local GameConfig = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("GameConfig"))

local DATASTORE_NAME = "PlayerProfiles"
local PROFILE_VERSION = 2
local MAX_RETRIES = 3
local RETRY_DELAY = 1 -- seconds (will use exponential backoff)

-- ============================================================================
-- STATE
-- ============================================================================

local profileStore = nil
local profileCache = {} -- [player.UserId] = profileData
local isInitialized = false

-- Profile change tracking (GDD: save only when player sits in PilotSeat and profile changed)
local profileChanged = {} -- [player.UserId] = boolean

-- Remote events (lazy loaded)
local remoteEvents = nil

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

local function GetRemoteEvents()
	if not remoteEvents then
		remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	end
	return remoteEvents
end

-- Get displayName for planet from Config
local function GetPlanetDisplayName(planetId)
	local planetFolder = ServerStorage.Planets:FindFirstChild(planetId)
	if not planetFolder then return planetId end

	local configModule = planetFolder:FindFirstChild("Config")
	if not configModule then return planetId end

	local success, config = pcall(require, configModule)
	if not success then return planetId end

	return config.displayName or config.name or planetId
end

-- Get displayName for location from Config
local function GetLocationDisplayName(planetId, locationId)
	-- Special case for Orbit
	if locationId == "Orbit" then
		local planetFolder = ServerStorage.Planets:FindFirstChild(planetId)
		if planetFolder then
			local orbitFolder = planetFolder:FindFirstChild("Orbit")
			if orbitFolder then
				local configModule = orbitFolder:FindFirstChild("Config")
				if configModule then
					local success, config = pcall(require, configModule)
					if success then
						return config.displayName or "Орбіта"
					end
				end
			end
		end
		return "Орбіта"
	end

	-- Surface location
	local planetFolder = ServerStorage.Planets:FindFirstChild(planetId)
	if not planetFolder then return locationId end

	local surfaceFolder = planetFolder:FindFirstChild("Surface")
	if not surfaceFolder then return locationId end

	local locationFolder = surfaceFolder:FindFirstChild(locationId)
	if not locationFolder then return locationId end

	local configModule = locationFolder:FindFirstChild("Config")
	if not configModule then return locationId end

	local success, config = pcall(require, configModule)
	if not success then return locationId end

	return config.displayName or config.name or locationId
end

local function GetProfileKey(player)
	return "Player_" .. tostring(player.UserId)
end

local function CreateDefaultProfile(player)
	local timestamp = os.time()

	return {
		-- Identity
		userId = player.UserId,
		createdAt = timestamp,
		lastLogin = timestamp,
		profileVersion = PROFILE_VERSION,

		-- === LOCATION STATE ===
		currentPlanet = GameConfig.StartPlanet,
		currentLocation = "Orbit",
		lastSafeState = {
			planetId = GameConfig.StartPlanet,
			locationName = "Orbit",
			timestamp = timestamp
		},

		-- === DISCOVERY TRACKING ===
		discoveredPlanets = {
			[GameConfig.StartPlanet] = timestamp
		},
		exploredLocations = {
			[GameConfig.StartPlanet] = {
				["Orbit"] = { discoveredAt = timestamp, visitCount = 1 },
				["Location1"] = { discoveredAt = timestamp, visitCount = 0 } -- Debug default
			}
		},
		visitHistory = {},

		-- === SHIP STATE ===
		shipState = {
			energyLevel = 100,
			hullIntegrity = 100,
			modules = {}
		},

		-- === INVENTORY ===
		resources = {},  -- Can be lost on failure
		knowledge = {},  -- Never lost

		-- === STATISTICS ===
		stats = {
			totalPlayTime = 0,
			locationsExplored = 1,
			resourcesCollected = 0,
			knowledgeDiscovered = 0
		}
	}
end

-- Migrate profile from v1 to v2
local function MigrateProfile(profileData)
	local currentVersion = profileData.profileVersion or 1

	if currentVersion < 2 then
		print(string.format("[%s %s][MigrateProfile] Migrating profile from v%d to v2",
			MODULE_NAME, VERSION, currentVersion))

		-- Get existing data
		local oldLocations = profileData.exploredLocations or {}
		local planetId = profileData.currentPlanet or GameConfig.StartPlanet
		local timestamp = profileData.createdAt or os.time()

		-- Convert flat exploredLocations array to per-planet structure
		if type(oldLocations) == "table" and #oldLocations > 0 then
			-- Old format was array: {"Location1", "Location2"}
			local newLocations = {
				[planetId] = {}
			}
			for _, locName in ipairs(oldLocations) do
				newLocations[planetId][locName] = {
					discoveredAt = timestamp,
					visitCount = 0
				}
			end
			profileData.exploredLocations = newLocations
		elseif type(oldLocations) == "table" and next(oldLocations) == nil then
			-- Empty table, initialize with defaults
			profileData.exploredLocations = {
				[planetId] = {
					["Orbit"] = { discoveredAt = timestamp, visitCount = 1 },
					["Location1"] = { discoveredAt = timestamp, visitCount = 0 }
				}
			}
		end

		-- Add missing fields with defaults
		profileData.currentLocation = profileData.currentLocation or "Orbit"
		profileData.lastSafeState = profileData.lastSafeState or {
			planetId = planetId,
			locationName = "Orbit",
			timestamp = os.time()
		}
		profileData.discoveredPlanets = profileData.discoveredPlanets or {
			[planetId] = timestamp
		}
		profileData.visitHistory = profileData.visitHistory or {}
		profileData.stats = profileData.stats or {
			totalPlayTime = 0,
			locationsExplored = 1,
			resourcesCollected = 0,
			knowledgeDiscovered = 0
		}

		-- Migrate shipState
		if profileData.shipState then
			if profileData.shipState.hullIntegrity == nil then
				profileData.shipState.hullIntegrity = 100
			end
			if profileData.shipState.modules == nil then
				profileData.shipState.modules = {}
			end
		else
			profileData.shipState = {
				energyLevel = 100,
				hullIntegrity = 100,
				modules = {}
			}
		end

		-- Ensure resources and knowledge are tables
		profileData.resources = profileData.resources or {}
		profileData.knowledge = profileData.knowledge or {}

		profileData.profileVersion = 2
		print(string.format("[%s %s][MigrateProfile] Migration complete", MODULE_NAME, VERSION))
	end

	return profileData
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
-- PROFILE CHANGE TRACKING
-- ============================================================================

local function MarkProfileChanged(player)
	profileChanged[player.UserId] = true
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

	-- Save profile on player leaving (always save on disconnect)
	Players.PlayerRemoving:Connect(function(player)
		local profile = profileCache[player.UserId]
		if profile then
			ProfileService.SaveProfile(player, profile)
			profileCache[player.UserId] = nil
			profileChanged[player.UserId] = nil
		end
	end)

	-- Setup profile sync RemoteEvent
	task.spawn(function()
		local events = GetRemoteEvents()
		if events then
			local requestProfileSync = events:FindFirstChild("RequestProfileSync")
			if requestProfileSync then
				requestProfileSync.OnServerEvent:Connect(function(player)
					local profile = profileCache[player.UserId]
					if profile then
						local profileUpdate = events:FindFirstChild("ProfileUpdate")
						if profileUpdate then
							-- Get displayNames for UI
							local planetDisplayName = GetPlanetDisplayName(profile.currentPlanet)
							local locationDisplayName = GetLocationDisplayName(profile.currentPlanet, profile.currentLocation)

							profileUpdate:FireClient(player, {
								type = "fullSync",
								profile = {
									currentPlanet = planetDisplayName,
									currentLocation = locationDisplayName,
									resources = profile.resources,
									knowledge = profile.knowledge,
									stats = profile.stats,
									shipState = profile.shipState
								}
							})
							print(string.format("[%s %s][ProfileSync] Full sync sent to %s",
								MODULE_NAME, VERSION, player.Name))
						end
					end
				end)
				print(string.format("[%s %s][Initialize] ProfileSync handler connected", MODULE_NAME, VERSION))
			end
		end
	end)

	isInitialized = true
	print(string.format("[%s %s][Initialize] ProfileService ready (schema v%d)",
		MODULE_NAME, VERSION, PROFILE_VERSION))
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
		profileChanged[player.UserId] = false
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
		profileChanged[player.UserId] = false
		return true, tempProfile, true
	end

	-- Profile exists - returning player
	if profileData then
		print(string.format("[%s %s][LoadProfile] Existing profile found for %s (v%d)",
			MODULE_NAME, VERSION, player.Name, profileData.profileVersion or 1))

		-- Migrate if needed
		profileData = MigrateProfile(profileData)

		-- Update last login
		profileData.lastLogin = os.time()

		profileCache[player.UserId] = profileData
		profileChanged[player.UserId] = false
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

	profileChanged[player.UserId] = false
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
		-- Clear changed flag after successful save
		profileChanged[player.UserId] = false
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
-- PROFILE UPDATE METHODS
-- ============================================================================

-- Generic update with merge
function ProfileService.UpdateProfile(player, updates)
	local profile = profileCache[player.UserId]
	if not profile then
		warn(string.format("[%s %s][UpdateProfile] No profile for %s", MODULE_NAME, VERSION, player.Name))
		return false
	end

	-- Deep merge updates into profile
	for key, value in pairs(updates) do
		if type(value) == "table" and type(profile[key]) == "table" then
			-- Merge tables
			for subKey, subValue in pairs(value) do
				profile[key][subKey] = subValue
			end
		else
			profile[key] = value
		end
	end

	MarkProfileChanged(player)
	print(string.format("[%s %s][UpdateProfile] Profile updated for %s", MODULE_NAME, VERSION, player.Name))
	return true
end

-- Mark location as discovered
function ProfileService.MarkLocationDiscovered(player, planetId, locationName)
	local profile = profileCache[player.UserId]
	if not profile then return false end

	-- Ensure planet structure exists
	if not profile.exploredLocations[planetId] then
		profile.exploredLocations[planetId] = {}
	end

	-- Ensure planet is in discoveredPlanets
	if not profile.discoveredPlanets[planetId] then
		profile.discoveredPlanets[planetId] = os.time()
		print(string.format("[%s %s][MarkLocationDiscovered] %s discovered NEW planet: %s",
			MODULE_NAME, VERSION, player.Name, planetId))
	end

	-- Check if already discovered
	if profile.exploredLocations[planetId][locationName] then
		-- Increment visit count
		profile.exploredLocations[planetId][locationName].visitCount =
			(profile.exploredLocations[planetId][locationName].visitCount or 0) + 1
		print(string.format("[%s %s][MarkLocationDiscovered] %s revisited %s/%s (visit #%d)",
			MODULE_NAME, VERSION, player.Name, planetId, locationName,
			profile.exploredLocations[planetId][locationName].visitCount))
	else
		-- New discovery
		profile.exploredLocations[planetId][locationName] = {
			discoveredAt = os.time(),
			visitCount = 1
		}
		profile.stats.locationsExplored = (profile.stats.locationsExplored or 0) + 1
		print(string.format("[%s %s][MarkLocationDiscovered] %s discovered NEW location: %s/%s",
			MODULE_NAME, VERSION, player.Name, planetId, locationName))
	end

	-- Add to visit history
	table.insert(profile.visitHistory, {
		planetId = planetId,
		locationId = locationName,
		timestamp = os.time()
	})

	-- Keep visit history manageable (last 100 entries)
	while #profile.visitHistory > 100 do
		table.remove(profile.visitHistory, 1)
	end

	MarkProfileChanged(player)
	return true
end

-- Update current location state
function ProfileService.UpdateCurrentState(player, planetId, locationName)
	local profile = profileCache[player.UserId]
	if not profile then return false end

	profile.currentPlanet = planetId
	profile.currentLocation = locationName

	-- Update last safe state only for safe locations (Orbit)
	if locationName == "Orbit" then
		profile.lastSafeState = {
			planetId = planetId,
			locationName = locationName,
			timestamp = os.time()
		}
	end

	MarkProfileChanged(player)
	print(string.format("[%s %s][UpdateCurrentState] %s now at %s/%s",
		MODULE_NAME, VERSION, player.Name, planetId, locationName))

	return true
end

-- Add resources (with stacking)
function ProfileService.AddResources(player, resourceId, quantity)
	local profile = profileCache[player.UserId]
	if not profile then return false end

	-- Find existing stack or create new
	local found = false
	for _, resource in ipairs(profile.resources) do
		if resource.id == resourceId then
			resource.quantity = resource.quantity + quantity
			found = true
			break
		end
	end

	if not found then
		table.insert(profile.resources, {
			id = resourceId,
			quantity = quantity,
			acquiredAt = os.time()
		})
	end

	profile.stats.resourcesCollected = (profile.stats.resourcesCollected or 0) + quantity

	MarkProfileChanged(player)
	print(string.format("[%s %s][AddResources] %s gained %d x %s",
		MODULE_NAME, VERSION, player.Name, quantity, resourceId))

	return true
end

-- Remove resources (returns false if insufficient)
function ProfileService.RemoveResources(player, resourceId, quantity)
	local profile = profileCache[player.UserId]
	if not profile then return false end

	for i, resource in ipairs(profile.resources) do
		if resource.id == resourceId then
			if resource.quantity >= quantity then
				resource.quantity = resource.quantity - quantity
				if resource.quantity <= 0 then
					table.remove(profile.resources, i)
				end
				MarkProfileChanged(player)
				print(string.format("[%s %s][RemoveResources] %s lost %d x %s",
					MODULE_NAME, VERSION, player.Name, quantity, resourceId))
				return true
			else
				warn(string.format("[%s %s][RemoveResources] Insufficient %s for %s (has %d, needs %d)",
					MODULE_NAME, VERSION, resourceId, player.Name, resource.quantity, quantity))
				return false
			end
		end
	end

	warn(string.format("[%s %s][RemoveResources] Resource %s not found for %s",
		MODULE_NAME, VERSION, resourceId, player.Name))
	return false
end

-- Add knowledge (never removed - EPIC 8 requirement)
function ProfileService.AddKnowledge(player, knowledgeEntry)
	local profile = profileCache[player.UserId]
	if not profile then return false end

	-- Check for duplicate
	for _, k in ipairs(profile.knowledge) do
		if k.id == knowledgeEntry.id then
			print(string.format("[%s %s][AddKnowledge] %s already has knowledge: %s",
				MODULE_NAME, VERSION, player.Name, knowledgeEntry.id))
			return true -- Already known, success
		end
	end

	-- Add new knowledge
	local entry = {
		id = knowledgeEntry.id,
		title = knowledgeEntry.title or knowledgeEntry.id,
		discoveredAt = os.time(),
		planetId = knowledgeEntry.planetId,
		locationId = knowledgeEntry.locationId
	}
	table.insert(profile.knowledge, entry)

	profile.stats.knowledgeDiscovered = (profile.stats.knowledgeDiscovered or 0) + 1

	-- GDD: Knowledge is saved immediately (never lost)
	ProfileService.SaveProfile(player, profile)

	print(string.format("[%s %s][AddKnowledge] %s discovered: %s (saved immediately)",
		MODULE_NAME, VERSION, player.Name, entry.title))

	return true
end

-- Get locations for specific planet (for TransitionService)
function ProfileService.GetExploredLocationsForPlanet(player, planetId)
	local profile = profileCache[player.UserId]
	if not profile then return {} end

	local planetLocations = profile.exploredLocations[planetId] or {}
	local result = {}

	for locationName, _ in pairs(planetLocations) do
		table.insert(result, locationName)
	end

	return result
end

-- Check if profile has unsaved changes
function ProfileService.IsProfileChanged(player)
	return profileChanged[player.UserId] == true
end

-- Save profile if changed (GDD: save when player sits in PilotSeat)
function ProfileService.SaveIfChanged(player)
	if not ProfileService.IsProfileChanged(player) then
		print(string.format("[%s %s][SaveIfChanged] No changes for %s, skipping save",
			MODULE_NAME, VERSION, player.Name))
		return false
	end

	local profile = profileCache[player.UserId]
	if profile then
		local success = ProfileService.SaveProfile(player, profile)
		if success then
			print(string.format("[%s %s][SaveIfChanged] Profile saved for %s (had changes)",
				MODULE_NAME, VERSION, player.Name))
		end
		return success
	end

	return false
end

-- Legacy compatibility (replaced by SaveIfChanged)
function ProfileService.TriggerEventSave(player, eventName)
	print(string.format("[%s %s][TriggerEventSave] Called for %s (event: %s) - using SaveIfChanged",
		MODULE_NAME, VERSION, player.Name, eventName))
	return ProfileService.SaveIfChanged(player)
end

-- Fire profile update to client
function ProfileService.NotifyClient(player, updateType, data)
	local events = GetRemoteEvents()
	if not events then return false end

	local profileUpdate = events:FindFirstChild("ProfileUpdate")
	if profileUpdate then
		local profile = profileCache[player.UserId]
		local planetId = profile and profile.currentPlanet
		local locationId = profile and profile.currentLocation

		-- Get displayNames for UI
		local planetDisplayName = planetId and GetPlanetDisplayName(planetId) or nil
		local locationDisplayName = (planetId and locationId) and GetLocationDisplayName(planetId, locationId) or nil

		profileUpdate:FireClient(player, {
			type = updateType,
			data = data,
			currentState = {
				planet = planetDisplayName,
				location = locationDisplayName
			}
		})
		return true
	end

	return false
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

return ProfileService
