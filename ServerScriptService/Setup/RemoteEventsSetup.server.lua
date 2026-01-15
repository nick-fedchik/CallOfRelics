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

-- Core Events
CreateRemoteEvent("LogOnRequest")
CreateRemoteEvent("LogOffRequest")
CreateRemoteEvent("StateChanged")
CreateRemoteEvent("BootStageUpdate")
CreateRemoteEvent("ConfirmGameStart")
CreateRemoteEvent("RetryBootStage")

-- Seat System Events
CreateRemoteEvent("SeatOccupied")
CreateRemoteEvent("SeatVacated")
CreateRemoteEvent("SeatActionRequest")
CreateRemoteEvent("SeatActionResponse")

-- Transition System Events
CreateRemoteEvent("RequestLanding")
CreateRemoteEvent("RequestLaunch")
CreateRemoteEvent("TransitionUpdate")
CreateRemoteEvent("LocationsAvailable")
CreateRemoteEvent("RequestLocations")
CreateRemoteEvent("TransitionLandingCamera")

-- Profile System Events
CreateRemoteEvent("ProfileUpdate")
CreateRemoteEvent("RequestProfileSync")

print(string.format("[%s %s] ✓ RemoteEvents ready", MODULE_NAME, VERSION))
