--[[
================================================================================
KOSMICMAZER — ContextRegistryService
================================================================================

Purpose:
Central registry for tracking all content copied during Planet/Orbit/Location
initialization. Enables proper cleanup (Fini) when transitioning between contexts.

Version:
0.1

Features:
- Track copied scripts per context level (Planet, Orbit, Location)
- Track copied objects per context level
- Track copied lighting effects
- Provide Fini (cleanup) functions for each level
- CurrentPlanetPath tracking

API:
- Initialize() — Initialize service
- GetCurrentPlanetPath() — Get active planet path
- SetCurrentPlanetPath(path) — Set active planet path

Planet Level:
- RegisterPlanetScript(player, script) — Track planet-level script
- GetPlanetScripts(player) — Get all planet scripts
- ClearPlanetRegistry(player) — Clear and destroy planet content

Orbit Level:
- RegisterOrbitObject(player, object) — Track orbit workspace object
- RegisterOrbitScript(player, script) — Track orbit script
- RegisterOrbitLighting(player, lightingObj) — Track orbit lighting
- GetOrbitObjects(player) — Get all orbit objects
- GetOrbitScripts(player) — Get all orbit scripts
- GetOrbitLighting(player) — Get all orbit lighting
- ClearOrbitRegistry(player) — Clear and destroy orbit content

Location Level:
- RegisterLocationObject(player, object) — Track location workspace object
- RegisterLocationScript(player, script) — Track location script
- RegisterLocationLighting(player, lightingObj) — Track location lighting
- GetLocationObjects(player) — Get all location objects
- GetLocationScripts(player) — Get all location scripts
- GetLocationLighting(player) — Get all location lighting
- ClearLocationRegistry(player) — Clear and destroy location content

Calls to:
- None (standalone registry)

Called from:
- LocationService (Init/Fini operations)
- TransitionService (context transitions)

Events:
- None

Dependencies:
- None

ChangeLog:
- 0.1: Initial ContextRegistryService (2026-01-16)
================================================================================
]]

local ContextRegistryService = {}

local MODULE_NAME = "ContextRegistryService"
local VERSION = "0.1"

local Players = game:GetService("Players")

-- ============================================================================
-- STATE
-- ============================================================================

local isInitialized = false

-- Current planet path (e.g., "ServerStorage.Planets.Planet_1")
local currentPlanetPath = nil

-- Registry structure per player:
-- {
--     planet = { scripts = {} },
--     orbit = { objects = {}, scripts = {}, lighting = {} },
--     location = { objects = {}, scripts = {}, lighting = {} }
-- }
local playerRegistries = {}

-- ============================================================================
-- PRIVATE HELPERS
-- ============================================================================

local function EnsurePlayerRegistry(player)
	if not playerRegistries[player] then
		playerRegistries[player] = {
			planet = { scripts = {} },
			orbit = { objects = {}, scripts = {}, lighting = {} },
			location = { objects = {}, scripts = {}, lighting = {} }
		}
	end
	return playerRegistries[player]
end

local function DestroyItems(items)
	local count = 0
	for _, item in ipairs(items) do
		if item and item.Parent then
			item:Destroy()
			count = count + 1
		end
	end
	return count
end

-- ============================================================================
-- PUBLIC API — INITIALIZATION
-- ============================================================================

function ContextRegistryService.Initialize()
	if isInitialized then
		return true
	end

	-- Cleanup when player leaves
	Players.PlayerRemoving:Connect(function(player)
		if playerRegistries[player] then
			-- Destroy all tracked content
			ContextRegistryService.ClearLocationRegistry(player)
			ContextRegistryService.ClearOrbitRegistry(player)
			ContextRegistryService.ClearPlanetRegistry(player)
			playerRegistries[player] = nil
		end
	end)

	isInitialized = true
	print(string.format("[%s %s] ✓ ContextRegistryService ready", MODULE_NAME, VERSION))
	return true
end

-- ============================================================================
-- PUBLIC API — PLANET PATH
-- ============================================================================

function ContextRegistryService.GetCurrentPlanetPath()
	return currentPlanetPath
end

function ContextRegistryService.SetCurrentPlanetPath(path)
	currentPlanetPath = path
end

-- ============================================================================
-- PUBLIC API — PLANET LEVEL
-- ============================================================================

function ContextRegistryService.RegisterPlanetScript(player, script)
	local registry = EnsurePlayerRegistry(player)
	table.insert(registry.planet.scripts, script)
end

function ContextRegistryService.GetPlanetScripts(player)
	local registry = EnsurePlayerRegistry(player)
	return registry.planet.scripts
end

function ContextRegistryService.ClearPlanetRegistry(player)
	local registry = playerRegistries[player]
	if not registry then return 0 end

	local count = DestroyItems(registry.planet.scripts)
	registry.planet.scripts = {}

	return count
end

-- ============================================================================
-- PUBLIC API — ORBIT LEVEL
-- ============================================================================

function ContextRegistryService.RegisterOrbitObject(player, object)
	local registry = EnsurePlayerRegistry(player)
	table.insert(registry.orbit.objects, object)
end

function ContextRegistryService.RegisterOrbitScript(player, script)
	local registry = EnsurePlayerRegistry(player)
	table.insert(registry.orbit.scripts, script)
end

function ContextRegistryService.RegisterOrbitLighting(player, lightingObj)
	local registry = EnsurePlayerRegistry(player)
	table.insert(registry.orbit.lighting, lightingObj)
end

function ContextRegistryService.GetOrbitObjects(player)
	local registry = EnsurePlayerRegistry(player)
	return registry.orbit.objects
end

function ContextRegistryService.GetOrbitScripts(player)
	local registry = EnsurePlayerRegistry(player)
	return registry.orbit.scripts
end

function ContextRegistryService.GetOrbitLighting(player)
	local registry = EnsurePlayerRegistry(player)
	return registry.orbit.lighting
end

function ContextRegistryService.ClearOrbitRegistry(player)
	local registry = playerRegistries[player]
	if not registry then return 0 end

	local count = 0
	count = count + DestroyItems(registry.orbit.objects)
	count = count + DestroyItems(registry.orbit.scripts)
	count = count + DestroyItems(registry.orbit.lighting)

	registry.orbit.objects = {}
	registry.orbit.scripts = {}
	registry.orbit.lighting = {}

	return count
end

-- ============================================================================
-- PUBLIC API — LOCATION LEVEL
-- ============================================================================

function ContextRegistryService.RegisterLocationObject(player, object)
	local registry = EnsurePlayerRegistry(player)
	table.insert(registry.location.objects, object)
end

function ContextRegistryService.RegisterLocationScript(player, script)
	local registry = EnsurePlayerRegistry(player)
	table.insert(registry.location.scripts, script)
end

function ContextRegistryService.RegisterLocationLighting(player, lightingObj)
	local registry = EnsurePlayerRegistry(player)
	table.insert(registry.location.lighting, lightingObj)
end

function ContextRegistryService.GetLocationObjects(player)
	local registry = EnsurePlayerRegistry(player)
	return registry.location.objects
end

function ContextRegistryService.GetLocationScripts(player)
	local registry = EnsurePlayerRegistry(player)
	return registry.location.scripts
end

function ContextRegistryService.GetLocationLighting(player)
	local registry = EnsurePlayerRegistry(player)
	return registry.location.lighting
end

function ContextRegistryService.ClearLocationRegistry(player)
	local registry = playerRegistries[player]
	if not registry then return 0 end

	local count = 0
	count = count + DestroyItems(registry.location.objects)
	count = count + DestroyItems(registry.location.scripts)
	count = count + DestroyItems(registry.location.lighting)

	registry.location.objects = {}
	registry.location.scripts = {}
	registry.location.lighting = {}

	return count
end

-- ============================================================================
-- PUBLIC API — UTILITY
-- ============================================================================

function ContextRegistryService.GetRegistrySummary(player)
	local registry = playerRegistries[player]
	if not registry then
		return {
			planet = { scripts = 0 },
			orbit = { objects = 0, scripts = 0, lighting = 0 },
			location = { objects = 0, scripts = 0, lighting = 0 }
		}
	end

	return {
		planet = { scripts = #registry.planet.scripts },
		orbit = {
			objects = #registry.orbit.objects,
			scripts = #registry.orbit.scripts,
			lighting = #registry.orbit.lighting
		},
		location = {
			objects = #registry.location.objects,
			scripts = #registry.location.scripts,
			lighting = #registry.location.lighting
		}
	}
end

-- ============================================================================
-- RETURN
-- ============================================================================

return ContextRegistryService
