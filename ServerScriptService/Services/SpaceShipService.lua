--[[
================================================================================
KOSMICMAZER -- SpaceShipService
================================================================================

Purpose:
Server-side management of SpaceShip spawning, lifecycle, and seat interactions.
Clones SpaceShip from ServerStorage/Actors based on player profile.
Tracks seat occupancy and processes seat-based actions.

Version:
0.7

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
- Ramp system: deploy/retract ramp, RampTrigger detection, RearShipExit control
- Engine Fire effects: toggle on landing/launch (visual feedback)
- Ramp steps pulsating animation when ramp is deployed

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

Ramp Management:
- SetShipLanded(player, isLanded) -- Set landed state, control exit/trigger
- IsShipLanded(player) -- Check if ship is landed
- DeployRamp(player) -- Deploy ramp with animation
- RetractRamp(player) -- Retract ramp with animation
- IsRampDeployed(player) -- Check if ramp is deployed

Engine Effects:
- SetEngineFireEnabled(player, enabled) -- Toggle engine fire effects

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
- 0.8: Replace stripe pulsation with step pulsation (2026-01-21)
- 0.7: Ramp stripes pulsating animation when deployed (2026-01-20)
- 0.6: Engine Fire effects toggle on landing/launch (2026-01-19)
- 0.5: Ramp system: SetShipLanded, DeployRamp, RetractRamp, RampTrigger, RearShipExit (2026-01-19)
- 0.4: Use SpaceShipConfig instead of local SPACESHIP_STRUCTURE (2026-01-16)
- 0.3: Merge SeatService functionality (seat occupancy, actions) (2026-01-16)
- 0.2: Add SPACESHIP_STRUCTURE reference, GetStructure(), GetSeatNames() (2026-01-16)
- 0.1: Initial SpaceShipService (2026-01-16)
================================================================================
]]

local SpaceShipService = {}

local VERSION = "0.8"
local MODULE_NAME = "SpaceShipService"

-- ============================================================================
-- SERVICES
-- ============================================================================

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

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

-- Ramp System State
local shipLandedState = {} -- [player] = boolean
local rampDeployedState = {} -- [player] = boolean
local rampConnections = {} -- [player] = {touchConnection, ...}
local rampAnimating = {} -- [player] = boolean (prevents double animation)
local rampStepsPulseActive = {} -- [player] = boolean (pulsating steps animation)

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

	-- Initialize ramp system: ship starts in flight mode (ramp hidden, exit blocked)
	-- Note: Must be done here since ramp functions are defined later
	shipLandedState[player] = false
	rampDeployedState[player] = false
	rampAnimating[player] = false

	-- Hide ramp steps immediately after spawn
	local ramp = ship:FindFirstChild("ShipRamp")
	if ramp then
		local totalSteps = SpaceShipConfig.GetRampTotalSteps()
		for i = 1, totalSteps do
			local step = ramp:FindFirstChild("Step" .. i)
			if step then
				step.Transparency = 1
				step.CanCollide = false
			end
		end
	end

	-- Block rear exit
	local shipParts = ship:FindFirstChild("ShipParts")
	local rearExit = shipParts and shipParts:FindFirstChild("RearShipExit") or ship:FindFirstChild("RearShipExit")
	if rearExit then
		rearExit.CanCollide = true
		rearExit.Transparency = 0.25
	end

	-- Hide ramp trigger
	local trigger = ship:FindFirstChild("RampTrigger")
	if trigger then
		trigger.Transparency = 1
		local highlight = trigger:FindFirstChild("RampHighlight")
		if highlight then
			highlight.Enabled = false
		end
	end

	print(string.format("[%s %s] Ramp initialized: flight mode (hidden, exit blocked)", MODULE_NAME, VERSION))

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
	SpaceShipService.CleanupRampState(player)
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

-- ============================================================================
-- ENGINE EFFECTS - PRIVATE FUNCTIONS
-- ============================================================================

-- Find all engine Fire effects in ship
local function GetEngineFires(ship)
	if not ship then return {} end

	local fires = {}
	local shipParts = ship:FindFirstChild("ShipParts")
	if not shipParts then return fires end

	-- Find BottomEngineLeft and BottomEngineRight
	local engineNames = {"BottomEngineLeft", "BottomEngineRight"}
	for _, engineName in ipairs(engineNames) do
		local engine = shipParts:FindFirstChild(engineName)
		if engine then
			local fire = engine:FindFirstChildOfClass("Fire")
			if fire then
				table.insert(fires, fire)
			end
		end
	end

	return fires
end

-- Set engine fire enabled state
local function SetEngineFires(ship, enabled)
	local fires = GetEngineFires(ship)
	for _, fire in ipairs(fires) do
		fire.Enabled = enabled
	end
	return #fires > 0
end

-- ============================================================================
-- RAMP SYSTEM - PRIVATE FUNCTIONS
-- ============================================================================

-- Find ShipRamp model in ship
local function GetShipRamp(ship)
	if not ship then return nil end
	return ship:FindFirstChild("ShipRamp")
end

-- Find RampTrigger part in ship
local function GetRampTrigger(ship)
	if not ship then return nil end
	return ship:FindFirstChild("RampTrigger")
end

-- Find RearShipExit in ship (inside ShipParts)
local function GetRearShipExit(ship)
	if not ship then return nil end
	local shipParts = ship:FindFirstChild("ShipParts")
	if shipParts then
		return shipParts:FindFirstChild("RearShipExit")
	end
	return ship:FindFirstChild("RearShipExit")
end

-- Set RearShipExit collision state
local function SetRearShipExitCollision(ship, canCollide)
	local rearExit = GetRearShipExit(ship)
	if not rearExit then return end

	local rampConfig = SpaceShipConfig.GetRampConfig()
	rearExit.CanCollide = canCollide

	-- Visual feedback: more transparent when open
	if canCollide then
		rearExit.Transparency = rampConfig.exitBlockedTransparency
	else
		rearExit.Transparency = rampConfig.exitOpenTransparency
	end
end

-- Set RampTrigger active state (visual highlight)
local function SetRampTriggerActive(ship, isActive)
	local trigger = GetRampTrigger(ship)
	if not trigger then return end

	local triggerConfig = SpaceShipConfig.GetRampTriggerConfig()

	if isActive then
		-- Create or update highlight
		local highlight = trigger:FindFirstChild("RampHighlight")
		if not highlight then
			highlight = Instance.new("Highlight")
			highlight.Name = "RampHighlight"
			highlight.Adornee = trigger
			highlight.FillColor = triggerConfig.highlightColor
			highlight.FillTransparency = triggerConfig.highlightTransparency
			highlight.OutlineColor = triggerConfig.highlightColor
			highlight.OutlineTransparency = 0.3
			highlight.Parent = trigger
		end
		highlight.Enabled = true
		trigger.Transparency = 0.7
	else
		-- Hide highlight
		local highlight = trigger:FindFirstChild("RampHighlight")
		if highlight then
			highlight.Enabled = false
		end
		trigger.Transparency = triggerConfig.inactiveTransparency
	end
end

-- Hide all ramp steps (initial state)
local function HideRampSteps(ship)
	local ramp = GetShipRamp(ship)
	if not ramp then return end

	for i = 1, SpaceShipConfig.GetRampTotalSteps() do
		local step = ramp:FindFirstChild("Step" .. i)
		if step then
			step.Transparency = 1
			step.CanCollide = false
		end
	end
end

-- Animate ramp deployment (Step1 → Step10)
local function AnimateRampDeploy(ship)
	local ramp = GetShipRamp(ship)
	if not ramp then return end

	local animConfig = SpaceShipConfig.GetRampAnimationTiming()
	local totalSteps = SpaceShipConfig.GetRampTotalSteps()

	for i = 1, totalSteps do
		local step = ramp:FindFirstChild("Step" .. i)
		if step then
			-- Fade in step
			step.CanCollide = true
			local tween = TweenService:Create(
				step,
				TweenInfo.new(animConfig.fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = 0}
			)
			tween:Play()
			task.wait(animConfig.stepDelay)
		end
	end
end

-- Animate ramp retraction (Step10 → Step1)
local function AnimateRampRetract(ship)
	local ramp = GetShipRamp(ship)
	if not ramp then return end

	local animConfig = SpaceShipConfig.GetRampAnimationTiming()
	local totalSteps = SpaceShipConfig.GetRampTotalSteps()

	for i = totalSteps, 1, -1 do
		local step = ramp:FindFirstChild("Step" .. i)
		if step then
			-- Fade out step
			local tween = TweenService:Create(
				step,
				TweenInfo.new(animConfig.fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Transparency = 1}
			)
			tween:Play()
			task.wait(animConfig.stepDelay)
			step.CanCollide = false
		end
	end
end

-- ============================================================================
-- RAMP STEPS PULSATING ANIMATION
-- ============================================================================

-- Get all ramp steps
local function GetRampSteps(ship)
	if not ship then return {} end

	local ramp = GetShipRamp(ship)
	if not ramp then return {} end

	local steps = {}
	local totalSteps = SpaceShipConfig.GetRampTotalSteps()
	for i = 1, totalSteps do
		local step = ramp:FindFirstChild("Step" .. i)
		if step then
			table.insert(steps, step)
		end
	end

	return steps
end

-- Start pulsating animation for ramp steps (subtle transparency pulse)
local function StartRampStepsPulse(player, ship)
	if rampStepsPulseActive[player] then return end

	local steps = GetRampSteps(ship)
	if #steps == 0 then
		print(string.format("[%s %s] No ramp steps found for pulsating animation", MODULE_NAME, VERSION))
		return
	end

	rampStepsPulseActive[player] = true
	print(string.format("[%s %s] Starting ramp steps pulse animation (%d steps)", MODULE_NAME, VERSION, #steps))

	-- Run pulsating animation in a separate thread
	task.spawn(function()
		local cycleTime = 2.0 -- 2 seconds per full cycle
		local minTransparency = 0.0 -- Fully visible
		local maxTransparency = 0.3 -- Slightly transparent (subtle pulse)

		while rampStepsPulseActive[player] do
			-- Pulse out (slightly dim)
			for _, step in ipairs(steps) do
				if step and step.Parent then
					local tween = TweenService:Create(
						step,
						TweenInfo.new(cycleTime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{Transparency = maxTransparency}
					)
					tween:Play()
				end
			end
			task.wait(cycleTime / 2)

			if not rampStepsPulseActive[player] then break end

			-- Pulse in (fully visible)
			for _, step in ipairs(steps) do
				if step and step.Parent then
					local tween = TweenService:Create(
						step,
						TweenInfo.new(cycleTime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{Transparency = minTransparency}
					)
					tween:Play()
				end
			end
			task.wait(cycleTime / 2)
		end
	end)
end

-- Stop pulsating animation for ramp steps
local function StopRampStepsPulse(player)
	if not rampStepsPulseActive[player] then return end

	rampStepsPulseActive[player] = false
	print(string.format("[%s %s] Stopping ramp steps pulse animation", MODULE_NAME, VERSION))
	-- Steps will be hidden by HideRampSteps or AnimateRampRetract
end

-- Setup RampTrigger touch detection
local function SetupRampTrigger(player, ship)
	local trigger = GetRampTrigger(ship)
	if not trigger then return end

	-- Cleanup existing connections
	if rampConnections[player] then
		for _, conn in ipairs(rampConnections[player]) do
			conn:Disconnect()
		end
	end
	rampConnections[player] = {}

	-- Connect touch event
	local touchConnection = trigger.Touched:Connect(function(hit)
		local character = hit.Parent
		local hitPlayer = Players:GetPlayerFromCharacter(character)

		-- Only react to the ship owner and only when landed
		if hitPlayer == player and shipLandedState[player] then
			-- Deploy ramp if not already deployed and not animating
			if not rampDeployedState[player] and not rampAnimating[player] then
				SpaceShipService.DeployRamp(player)
			end
		end
	end)

	table.insert(rampConnections[player], touchConnection)
end

-- Cleanup ramp connections for player
local function CleanupRampConnections(player)
	if rampConnections[player] then
		for _, conn in ipairs(rampConnections[player]) do
			conn:Disconnect()
		end
		rampConnections[player] = nil
	end
end

-- ============================================================================
-- RAMP SYSTEM - PUBLIC API
-- ============================================================================

-- Set ship landed state (called by TransitionService after landing/before launch)
function SpaceShipService.SetShipLanded(player, isLanded)
	local ship = SpaceShipService.GetShip(player)
	if not ship then
		warn(string.format("[%s %s] SetShipLanded: No ship found for %s", MODULE_NAME, VERSION, player.Name))
		return false
	end

	shipLandedState[player] = isLanded

	if isLanded then
		-- Ship just landed: enable exit, activate trigger, setup detection, disable engines
		SetRearShipExitCollision(ship, false) -- Allow exit
		SetRampTriggerActive(ship, true) -- Show trigger highlight
		SetupRampTrigger(player, ship) -- Enable touch detection
		HideRampSteps(ship) -- Ramp starts hidden, deploys on trigger
		SetEngineFires(ship, false) -- Turn off engine fire effects

		print(string.format("[%s %s] Ship landed: exit open, trigger active, engines off", MODULE_NAME, VERSION))
	else
		-- Ship taking off: block exit, hide trigger, cleanup, enable engines
		SetEngineFires(ship, true) -- Turn on engine fire effects (first, for visual feedback)
		SetRearShipExitCollision(ship, true) -- Block exit
		SetRampTriggerActive(ship, false) -- Hide trigger
		CleanupRampConnections(player) -- Disable touch detection
		HideRampSteps(ship) -- Hide ramp

		rampDeployedState[player] = false

		print(string.format("[%s %s] Ship in flight: exit blocked, ramp hidden, engines on", MODULE_NAME, VERSION))
	end

	return true
end

-- Check if ship is landed
function SpaceShipService.IsShipLanded(player)
	return shipLandedState[player] == true
end

-- Deploy ramp with animation
function SpaceShipService.DeployRamp(player)
	if rampDeployedState[player] then return false end
	if rampAnimating[player] then return false end

	local ship = SpaceShipService.GetShip(player)
	if not ship then return false end

	rampAnimating[player] = true

	print(string.format("[%s %s] Deploying ramp for %s", MODULE_NAME, VERSION, player.Name))

	-- Run animation
	AnimateRampDeploy(ship)

	-- Start pulsating steps animation
	StartRampStepsPulse(player, ship)

	rampDeployedState[player] = true
	rampAnimating[player] = false

	print(string.format("[%s %s] Ramp deployed for %s", MODULE_NAME, VERSION, player.Name))

	return true
end

-- Retract ramp with animation
function SpaceShipService.RetractRamp(player)
	if not rampDeployedState[player] then return false end
	if rampAnimating[player] then return false end

	local ship = SpaceShipService.GetShip(player)
	if not ship then return false end

	rampAnimating[player] = true

	print(string.format("[%s %s] Retracting ramp for %s", MODULE_NAME, VERSION, player.Name))

	-- Stop pulsating steps animation
	StopRampStepsPulse(player)

	-- Run animation
	AnimateRampRetract(ship)

	rampDeployedState[player] = false
	rampAnimating[player] = false

	print(string.format("[%s %s] Ramp retracted for %s", MODULE_NAME, VERSION, player.Name))

	return true
end

-- Check if ramp is deployed
function SpaceShipService.IsRampDeployed(player)
	return rampDeployedState[player] == true
end

-- Cleanup ramp state for player (called on player leaving)
function SpaceShipService.CleanupRampState(player)
	CleanupRampConnections(player)
	rampStepsPulseActive[player] = nil -- Stop any active pulse animation
	shipLandedState[player] = nil
	rampDeployedState[player] = nil
	rampAnimating[player] = nil
end

-- ============================================================================
-- ENGINE EFFECTS - PUBLIC API
-- ============================================================================

-- Set engine fire effects enabled state
-- Called automatically by SetShipLanded, but can be called manually if needed
function SpaceShipService.SetEngineFireEnabled(player, enabled)
	local ship = SpaceShipService.GetShip(player)
	if not ship then
		warn(string.format("[%s %s] SetEngineFireEnabled: No ship found for %s", MODULE_NAME, VERSION, player.Name))
		return false
	end

	local success = SetEngineFires(ship, enabled)
	if success then
		print(string.format("[%s %s] Engine fire %s for %s", MODULE_NAME, VERSION, enabled and "enabled" or "disabled", player.Name))
	end
	return success
end

return SpaceShipService
