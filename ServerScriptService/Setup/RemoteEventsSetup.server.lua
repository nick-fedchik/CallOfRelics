--[[
================================================================================
KOSMICMAZER — RemoteEventsSetup
================================================================================

Purpose:
Creates and configures RemoteEvents for client-server communication.
Runs early in boot sequence.

Version:
0.1

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
- 0.1: Initial RemoteEvents setup (2026-01-11)
================================================================================
]]

local VERSION = "0.1"
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

print(string.format("[%s %s] RemoteEvents setup complete", MODULE_NAME, VERSION))
