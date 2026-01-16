--[[
================================================================================
KOSMICMAZER -- SpaceShipService
================================================================================

Purpose:
Server-side management of SpaceShip spawning and lifecycle.
Clones SpaceShip from ServerStorage/Actors based on player profile.

Version:
0.1

Features:
- Clone SpaceShip from ServerStorage/Actors/{modelName}
- Load model name from player profile (spaceShipModel)
- Fallback to default "SpaceShip" if model not found
- Set ModelStreamingMode to Persistent
- Anchor all parts except seats
- Track active ship per player
- Cleanup on game end

API:
- Initialize() -- Initialize service
- SpawnShip(player, position, rotation) -- Spawn ship for player
- GetShip(player) -- Get player's active ship
- DestroyShip(player) -- Remove player's ship
- GetShipModel(player) -- Get model name from profile

Calls to:
- ServerStorage.Actors
- ProfileService.GetProfile()

Called from:
- TransitionService (game start, transitions)
- LocationService (spawn point detection)

Events:
- None (internal service)

Dependencies:
- ProfileService
- ServerStorage/Actors folder

ChangeLog:
- 0.1: Initial SpaceShipService (2026-01-16)
================================================================================
]]

local SpaceShipService = {}

local VERSION = "0.1"
local MODULE_NAME = "SpaceShipService"

-- ============================================================================
-- SERVICES
-- ============================================================================

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

-- ============================================================================
-- MODULES
-- ============================================================================

local ProfileService

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local DEFAULT_SHIP_MODEL = "SpaceShip"
local ACTORS_FOLDER_NAME = "Actors"

-- ============================================================================
-- STATE
-- ============================================================================

local activeShips = {} -- [player] = shipModel
local isInitialized = false

-- ============================================================================
-- PRIVATE FUNCTIONS
-- ============================================================================

local function GetActorsFolder()
	return ServerStorage:FindFirstChild(ACTORS_FOLDER_NAME)
end

local function GetShipTemplate(modelName)
	local actorsFolder = GetActorsFolder()
	if not actorsFolder then
		warn(string.format("[%s %s] Actors folder not found in ServerStorage!", MODULE_NAME, VERSION))
		return nil
	end

	local template = actorsFolder:FindFirstChild(modelName)
	if template then
		return template
	end

	-- Fallback to default
	if modelName ~= DEFAULT_SHIP_MODEL then
		warn(string.format("[%s %s] Ship model '%s' not found, using default", MODULE_NAME, VERSION, modelName))
		template = actorsFolder:FindFirstChild(DEFAULT_SHIP_MODEL)
	end

	return template
end

local function PrepareShipModel(ship)
	-- Set ModelStreamingMode to Persistent
	ship.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	-- Anchor all parts except seats
	for _, part in ipairs(ship:GetDescendants()) do
		if part:IsA("BasePart") and not part:IsA("Seat") and not part:IsA("VehicleSeat") then
			part.Anchored = true
		end
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function SpaceShipService.Initialize()
	if isInitialized then return true end

	-- Load ProfileService
	local servicesFolder = script.Parent
	local profileServiceModule = servicesFolder:FindFirstChild("ProfileService")
	if profileServiceModule then
		ProfileService = require(profileServiceModule)
	end

	-- Verify Actors folder exists
	local actorsFolder = GetActorsFolder()
	if not actorsFolder then
		warn(string.format("[%s %s] WARNING: ServerStorage/Actors folder not found!", MODULE_NAME, VERSION))
	end

	isInitialized = true
	print(string.format("[%s %s] ✓ SpaceShipService ready", MODULE_NAME, VERSION))
	return true
end

function SpaceShipService.GetShipModelName(player)
	if not ProfileService then
		return DEFAULT_SHIP_MODEL
	end

	local profile = ProfileService.GetProfile(player)
	if profile and profile.spaceShipModel then
		return profile.spaceShipModel
	end

	return DEFAULT_SHIP_MODEL
end

function SpaceShipService.SpawnShip(player, position, rotation)
	-- Check for existing ship
	local existingShip = activeShips[player]
	if existingShip and existingShip.Parent then
		-- Reposition existing ship
		local cframe = CFrame.new(position)
		if rotation then
			cframe = cframe * rotation
		end
		existingShip:PivotTo(cframe)
		return existingShip
	end

	-- Get model name from profile
	local modelName = SpaceShipService.GetShipModelName(player)

	-- Get template
	local template = GetShipTemplate(modelName)
	if not template then
		warn(string.format("[%s %s] No ship template found for player %s!", MODULE_NAME, VERSION, player.Name))
		return nil
	end

	-- Clone and prepare
	local ship = template:Clone()
	ship.Name = "SpaceShip"
	PrepareShipModel(ship)

	-- Position ship
	local cframe = CFrame.new(position)
	if rotation then
		cframe = cframe * rotation
	end
	ship:PivotTo(cframe)

	-- Parent to Workspace
	ship.Parent = Workspace

	-- Track
	activeShips[player] = ship

	return ship
end

function SpaceShipService.GetShip(player)
	local ship = activeShips[player]
	if ship and ship.Parent then
		return ship
	end

	-- Also check Workspace for legacy compatibility
	return Workspace:FindFirstChild("SpaceShip")
end

function SpaceShipService.DestroyShip(player)
	local ship = activeShips[player]
	if ship then
		if ship.Parent then
			ship:Destroy()
		end
		activeShips[player] = nil
		return true
	end
	return false
end

function SpaceShipService.RepositionShip(player, position, rotation)
	local ship = SpaceShipService.GetShip(player)
	if not ship then
		return false
	end

	local cframe = CFrame.new(position)
	if rotation then
		cframe = cframe * rotation
	end
	ship:PivotTo(cframe)
	return true
end

-- Cleanup when player leaves
function SpaceShipService.OnPlayerRemoving(player)
	SpaceShipService.DestroyShip(player)
end

return SpaceShipService
