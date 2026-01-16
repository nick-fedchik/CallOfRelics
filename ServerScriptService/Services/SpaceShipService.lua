--[[
================================================================================
KOSMICMAZER -- SpaceShipService
================================================================================

Purpose:
Server-side management of SpaceShip spawning, lifecycle, and seat interactions.
Clones SpaceShip from ServerStorage/Actors based on player profile.
Tracks seat occupancy and processes seat-based actions.

Version:
0.4

Features:
- Clone SpaceShip from ServerStorage/Actors/{modelName}
- Load model name from player profile (spaceShipModel)
- Fallback to default "SpaceShip" if model not found
- Set ModelStreamingMode to Persistent
- Anchor all parts except seats
- Track active ship per player
- Track seat occupancy per player
- Process seat-specific actions
- Extensible action handler registry
- GDD: Save profile when player sits in PilotSeat (if changed)
- Cleanup on game end / player disconnect

API:
Ship Management:
- Initialize() -- Initialize service
- SpawnShip(player, position, rotation) -- Spawn ship for player
- GetShip(player) -- Get player's active ship
- DestroyShip(player) -- Remove player's ship
- GetShipModelName(player) -- Get model name from profile
- RepositionShip(player, position, rotation) -- Move ship
- GetStructure() -- Get ship component structure
- GetSeatNames() -- Get list of seat names

Seat Management:
- OnSeatOccupied(player, seatName) -- Handle seat occupation
- OnSeatVacated(player, seatName) -- Handle seat vacation
- ProcessSeatAction(player, seatName, action, data) -- Process seat actions
- RegisterActionHandler(seatName, action, handler) -- Register action handler
- GetSeatOccupant(seatName) -- Get player in seat (or nil)
- IsSeatOccupied(seatName) -- Check if seat is occupied
- GetPlayerSeat(player) -- Get seat name for player

Calls to:
- ServerStorage.Actors
- ProfileService.GetProfile()
- ProfileService.SaveIfChanged()
- SpaceShipConfig

Called from:
- TransitionService (game start, transitions)
- LocationService (spawn point detection)
- Client via RemoteEvents (seat events)

Events:
- SeatOccupied (Client -> Server)
- SeatVacated (Client -> Server)
- SeatActionRequest (Client -> Server)
- SeatActionResponse (Server -> Client)

Dependencies:
- ProfileService
- SpaceShipConfig
- ServerStorage/Actors folder
- RemoteEvents

ChangeLog:
- 0.4: Use SpaceShipConfig instead of local SPACESHIP_STRUCTURE (2026-01-16)
- 0.3: Merge SeatService functionality (seat occupancy, actions) (2026-01-16)
- 0.2: Add SPACESHIP_STRUCTURE reference, GetStructure(), GetSeatNames() (2026-01-16)
- 0.1: Initial SpaceShipService (2026-01-16)
================================================================================
]]

local SpaceShipService = {}

local VERSION = "0.4"
local MODULE_NAME = "SpaceShipService"

-- ============================================================================
-- SERVICES
-- ============================================================================

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ============================================================================
-- MODULES
-- ============================================================================

local ProfileService
local SpaceShipConfig

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

-- Seat Management State
local seatOccupants = {} -- {[seatName] = player}
local actionHandlers = {} -- {[seatName] = {[actionName] = handlerFunction}}

-- Remote Events (set during Initialize)
local RemoteEvents
local SeatOccupied
local SeatVacated
local SeatActionRequest
local SeatActionResponse

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

	-- Load SpaceShipConfig
	local Game = ReplicatedStorage:WaitForChild("Game")
	SpaceShipConfig = require(Game:WaitForChild("SpaceShipConfig"))

	-- Verify Actors folder exists
	local actorsFolder = GetActorsFolder()
	if not actorsFolder then
		warn(string.format("[%s %s] WARNING: ServerStorage/Actors folder not found!", MODULE_NAME, VERSION))
	end

	-- Setup seat RemoteEvents
	RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	SeatOccupied = RemoteEvents:WaitForChild("SeatOccupied")
	SeatVacated = RemoteEvents:WaitForChild("SeatVacated")
	SeatActionRequest = RemoteEvents:WaitForChild("SeatActionRequest")
	SeatActionResponse = RemoteEvents:WaitForChild("SeatActionResponse")

	-- Connect seat events
	SeatOccupied.OnServerEvent:Connect(function(player, seatName)
		SpaceShipService.OnSeatOccupied(player, seatName)
	end)

	SeatVacated.OnServerEvent:Connect(function(player, seatName)
		SpaceShipService.OnSeatVacated(player, seatName)
	end)

	SeatActionRequest.OnServerEvent:Connect(function(player, seatName, action, data)
		SpaceShipService.ProcessSeatAction(player, seatName, action, data)
	end)

	-- Cleanup on player leaving
	Players.PlayerRemoving:Connect(function(player)
		SpaceShipService.OnPlayerRemoving(player)
	end)

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
	SpaceShipService.CleanupPlayerSeats(player)
end

-- Get SpaceShip structure reference
function SpaceShipService.GetStructure()
	return SpaceShipConfig.GetStructure()
end

-- Get list of seat names
function SpaceShipService.GetSeatNames()
	return SpaceShipConfig.GetSeatNames()
end

-- ============================================================================
-- SEAT MANAGEMENT API
-- ============================================================================

function SpaceShipService.OnSeatOccupied(player, seatName)
	if not SpaceShipConfig.IsSeatKnown(seatName) then
		warn(string.format("[%s %s] Unknown seat: %s", MODULE_NAME, VERSION, seatName))
		return
	end

	local seatConfig = SpaceShipConfig.GetSeatConfig(seatName)
	local displayName = seatConfig and seatConfig.displayName or seatName

	seatOccupants[seatName] = player
	print(string.format("[%s %s] %s sat in: %s (%s)",
		MODULE_NAME, VERSION, player.Name, seatName, displayName))

	-- GDD: Save profile when player sits in PilotSeat (if changed)
	if seatName == "PilotSeat" and ProfileService then
		ProfileService.SaveIfChanged(player)
	end
end

function SpaceShipService.OnSeatVacated(player, seatName)
	if seatOccupants[seatName] == player then
		seatOccupants[seatName] = nil
		print(string.format("[%s %s] %s left seat: %s", MODULE_NAME, VERSION, player.Name, seatName))
	end
end

function SpaceShipService.ProcessSeatAction(player, seatName, action, data)
	if seatOccupants[seatName] ~= player then
		SeatActionResponse:FireClient(player, seatName, action, {
			success = false,
			error = "NotInSeat"
		})
		return
	end

	local seatHandlers = actionHandlers[seatName]
	local handler = seatHandlers and seatHandlers[action]

	if handler then
		local success, result = pcall(handler, player, data)
		if success then
			SeatActionResponse:FireClient(player, seatName, action, result)
		else
			SeatActionResponse:FireClient(player, seatName, action, {
				success = false,
				error = "HandlerError"
			})
		end
	else
		SeatActionResponse:FireClient(player, seatName, action, {
			success = false,
			error = "UnknownAction"
		})
	end
end

function SpaceShipService.RegisterActionHandler(seatName, action, handler)
	if not actionHandlers[seatName] then
		actionHandlers[seatName] = {}
	end
	actionHandlers[seatName][action] = handler
end

function SpaceShipService.GetSeatOccupant(seatName)
	return seatOccupants[seatName]
end

function SpaceShipService.IsSeatOccupied(seatName)
	return seatOccupants[seatName] ~= nil
end

function SpaceShipService.GetPlayerSeat(player)
	for seatName, occupant in pairs(seatOccupants) do
		if occupant == player then
			return seatName
		end
	end
	return nil
end

function SpaceShipService.CleanupPlayerSeats(player)
	for seatName, occupant in pairs(seatOccupants) do
		if occupant == player then
			seatOccupants[seatName] = nil
		end
	end
end

return SpaceShipService
