--[[
================================================================================
KOSMICMAZER — RemoteEventsSetup
================================================================================

Purpose:
Creates and configures RemoteEvents for client-server communication.
Runs early in boot sequence.

Version:
0.2

Features:
- Creates RemoteEvents folder in ReplicatedStorage
- Sets up LogOnRequest event
- Sets up LogOffRequest event
- Sets up StateChanged event (server to client)

API:
- None (auto-executes)

Calls to:
- None

Called from:
- Roblox Server (auto-run, loads before ServerBootstrap)

Events:
- Creates: LogOnRequest, LogOffRequest, StateChanged

Dependencies:
- None

ChangeLog:
- 0.2: Rename RequestLiftoff → RequestLaunch (2026-01-15)
- 0.1: Initial RemoteEvents setup (2026-01-11)
================================================================================
]]

local VERSION = "0.2"
local MODULE_NAME = "RemoteEventsSetup"

print(string.format("[%s %s] Setting up RemoteEvents...", MODULE_NAME, VERSION))

-- ============================================================================
-- SERVICES
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================================
-- CREATE REMOTE EVENTS FOLDER
-- ============================================================================

local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
	remoteEventsFolder = Instance.new("Folder")
	remoteEventsFolder.Name = "RemoteEvents"
	remoteEventsFolder.Parent = ReplicatedStorage
end

-- ============================================================================
-- CREATE INDIVIDUAL EVENTS
-- ============================================================================

local function CreateRemoteEvent(name)
	local existing = remoteEventsFolder:FindFirstChild(name)
	if existing then
		return existing
	end

	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remoteEventsFolder
	return event
end

-- LogOn Request (Client → Server)
local logOnRequest = CreateRemoteEvent("LogOnRequest")
print(string.format("[%s %s] Created: LogOnRequest", MODULE_NAME, VERSION))

-- LogOff Request (Client → Server)
local logOffRequest = CreateRemoteEvent("LogOffRequest")
print(string.format("[%s %s] Created: LogOffRequest", MODULE_NAME, VERSION))

-- State Changed (Server → Client)
local stateChanged = CreateRemoteEvent("StateChanged")
print(string.format("[%s %s] Created: StateChanged", MODULE_NAME, VERSION))

-- Boot Stage Update (Server → Client)
local bootStageUpdate = CreateRemoteEvent("BootStageUpdate")
print(string.format("[%s %s] Created: BootStageUpdate", MODULE_NAME, VERSION))

-- Confirm Game Start (Client → Server)
local confirmGameStart = CreateRemoteEvent("ConfirmGameStart")
print(string.format("[%s %s] Created: ConfirmGameStart", MODULE_NAME, VERSION))

-- Retry Boot Stage (Client → Server)
local retryBootStage = CreateRemoteEvent("RetryBootStage")
print(string.format("[%s %s] Created: RetryBootStage", MODULE_NAME, VERSION))

-- ============================================================================
-- SEAT SYSTEM EVENTS
-- ============================================================================

-- Seat Occupied (Client → Server)
local seatOccupied = CreateRemoteEvent("SeatOccupied")
print(string.format("[%s %s] Created: SeatOccupied", MODULE_NAME, VERSION))

-- Seat Vacated (Client → Server)
local seatVacated = CreateRemoteEvent("SeatVacated")
print(string.format("[%s %s] Created: SeatVacated", MODULE_NAME, VERSION))

-- Seat Action Request (Client → Server)
local seatActionRequest = CreateRemoteEvent("SeatActionRequest")
print(string.format("[%s %s] Created: SeatActionRequest", MODULE_NAME, VERSION))

-- Seat Action Response (Server → Client)
local seatActionResponse = CreateRemoteEvent("SeatActionResponse")
print(string.format("[%s %s] Created: SeatActionResponse", MODULE_NAME, VERSION))

-- ============================================================================
-- TRANSITION SYSTEM EVENTS
-- ============================================================================

-- Request Landing (Client → Server)
local requestLanding = CreateRemoteEvent("RequestLanding")
print(string.format("[%s %s] Created: RequestLanding", MODULE_NAME, VERSION))

-- Request Launch (Client → Server)
local requestLaunch = CreateRemoteEvent("RequestLaunch")
print(string.format("[%s %s] Created: RequestLaunch", MODULE_NAME, VERSION))

-- Transition Update (Server → Client)
local transitionUpdate = CreateRemoteEvent("TransitionUpdate")
print(string.format("[%s %s] Created: TransitionUpdate", MODULE_NAME, VERSION))

-- Locations Available (Server → Client)
local locationsAvailable = CreateRemoteEvent("LocationsAvailable")
print(string.format("[%s %s] Created: LocationsAvailable", MODULE_NAME, VERSION))

-- Request Available Locations (Client → Server)
local requestLocations = CreateRemoteEvent("RequestLocations")
print(string.format("[%s %s] Created: RequestLocations", MODULE_NAME, VERSION))

-- Transition Landing Camera (Server → Client)
local transitionLandingCamera = CreateRemoteEvent("TransitionLandingCamera")
print(string.format("[%s %s] Created: TransitionLandingCamera", MODULE_NAME, VERSION))

-- ============================================================================
-- PROFILE SYSTEM EVENTS
-- ============================================================================

-- Profile Update (Server → Client) - Push profile changes to client
local profileUpdate = CreateRemoteEvent("ProfileUpdate")
print(string.format("[%s %s] Created: ProfileUpdate", MODULE_NAME, VERSION))

-- Request Profile Sync (Client → Server) - Client requests current profile
local requestProfileSync = CreateRemoteEvent("RequestProfileSync")
print(string.format("[%s %s] Created: RequestProfileSync", MODULE_NAME, VERSION))

print(string.format("[%s %s] RemoteEvents setup complete", MODULE_NAME, VERSION))
