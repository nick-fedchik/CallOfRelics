--[[
================================================================================
KOSMICMAZER -- SeatService
================================================================================

Purpose:
Server-side management of seat occupancy and seat-based actions.
Validates seat interactions and maintains authoritative state.

Version:
0.2

Features:
- Track seat occupancy per player
- Validate seat interactions
- Process seat-specific actions
- Extensible action handler registry
- Cleanup on player disconnect
- GDD: Save profile when player sits in PilotSeat (if changed)

API:
- Initialize() -- Initialize service
- OnSeatOccupied(player, seatName) -- Handle seat occupation
- OnSeatVacated(player, seatName) -- Handle seat vacation
- ProcessSeatAction(player, seatName, action, data) -- Process seat actions
- RegisterActionHandler(seatName, action, handler) -- Register action handler
- GetSeatOccupant(seatName) -- Get player in seat (or nil)

Calls to:
- ReplicatedStorage.Game.SeatConfig
- ReplicatedStorage.RemoteEvents
- ProfileService.SaveIfChanged()

Called from:
- ServerBootstrap (initialization)
- Client via RemoteEvents

Events:
- SeatOccupied (Client -> Server)
- SeatVacated (Client -> Server)
- SeatActionRequest (Client -> Server)
- SeatActionResponse (Server -> Client)

Dependencies:
- SeatConfig
- RemoteEvents
- ProfileService

ChangeLog:
- 0.2: GDD save on PilotSeat sit (2026-01-15)
- 0.1: Initial SeatService (2026-01-13)
================================================================================
]]

local SeatService = {}

local VERSION = "0.2"
local MODULE_NAME = "SeatService"

-- ============================================================================
-- SERVICES
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ============================================================================
-- STATE
-- ============================================================================

local isInitialized = false
local seatOccupants = {} -- {[seatName] = player}

-- Remote Events (set during Initialize)
local RemoteEvents
local SeatOccupied
local SeatVacated
local SeatActionRequest
local SeatActionResponse

-- Action handlers registry (extensible)
-- Structure: {[seatName] = {[actionName] = handlerFunction}}
local actionHandlers = {}

-- Modules (set during Initialize)
local SeatConfig
local ProfileService

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function SeatService.Initialize()
	if isInitialized then
		return true
	end

	local Game = ReplicatedStorage:WaitForChild("Game")
	SeatConfig = require(Game:WaitForChild("SeatConfig"))

	local ServerScriptService = game:GetService("ServerScriptService")
	local Services = ServerScriptService:WaitForChild("Services")
	ProfileService = require(Services:WaitForChild("ProfileService"))

	RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	SeatOccupied = RemoteEvents:WaitForChild("SeatOccupied")
	SeatVacated = RemoteEvents:WaitForChild("SeatVacated")
	SeatActionRequest = RemoteEvents:WaitForChild("SeatActionRequest")
	SeatActionResponse = RemoteEvents:WaitForChild("SeatActionResponse")

	SeatOccupied.OnServerEvent:Connect(function(player, seatName)
		SeatService.OnSeatOccupied(player, seatName)
	end)

	SeatVacated.OnServerEvent:Connect(function(player, seatName)
		SeatService.OnSeatVacated(player, seatName)
	end)

	SeatActionRequest.OnServerEvent:Connect(function(player, seatName, action, data)
		SeatService.ProcessSeatAction(player, seatName, action, data)
	end)

	Players.PlayerRemoving:Connect(function(player)
		SeatService.CleanupPlayer(player)
	end)

	isInitialized = true
	print(string.format("[%s %s] ✓ SeatService ready", MODULE_NAME, VERSION))
	return true
end

function SeatService.OnSeatOccupied(player, seatName)
	if not SeatConfig.IsSeatKnown(seatName) then
		return
	end

	seatOccupants[seatName] = player

	-- GDD: Save profile when player sits in PilotSeat (if changed)
	if seatName == "PilotSeat" then
		ProfileService.SaveIfChanged(player)
	end
end

function SeatService.OnSeatVacated(player, seatName)
	if seatOccupants[seatName] == player then
		seatOccupants[seatName] = nil
	end
end

function SeatService.ProcessSeatAction(player, seatName, action, data)
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

function SeatService.RegisterActionHandler(seatName, action, handler)
	if not actionHandlers[seatName] then
		actionHandlers[seatName] = {}
	end
	actionHandlers[seatName][action] = handler
end

function SeatService.GetSeatOccupant(seatName)
	return seatOccupants[seatName]
end

function SeatService.IsSeatOccupied(seatName)
	return seatOccupants[seatName] ~= nil
end

function SeatService.GetPlayerSeat(player)
	for seatName, occupant in pairs(seatOccupants) do
		if occupant == player then
			return seatName
		end
	end
	return nil
end

function SeatService.CleanupPlayer(player)
	for seatName, occupant in pairs(seatOccupants) do
		if occupant == player then
			seatOccupants[seatName] = nil
		end
	end
end

-- ============================================================================
-- RETURN
-- ============================================================================

return SeatService
