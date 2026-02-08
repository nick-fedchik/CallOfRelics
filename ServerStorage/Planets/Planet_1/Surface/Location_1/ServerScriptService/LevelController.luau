--[[
================================================================================
KOSMICMAZER — LevelController (Planet_1 / Location_1 "Візитка")
================================================================================

Purpose:
Single entry point for level lifecycle. Called by LocationService framework.
Orchestrates initialization and cleanup of all level-specific modules
in the correct order.

Version:
0.1

API:
- levelInit() — Initialize all level modules in sequence
- levelFini() — Cleanup all level modules in reverse order

Managed modules:
- TerrainGenerator — Procedural terrain, octagonal temple, emitter systems

Available modules (not yet managed, for future integration):
- LandingLightsModule — Landing pad blinking lights
- LandingPadEffectsModule — Landing pad pulse effects

Called from:
- LocationService (automatic via LevelController convention)

ChangeLog:
- 0.1: Initial LevelController for Location_1 (2026-02-08)
================================================================================
]]

local LevelController = {}

-- Require sibling modules (preserved hierarchy allows script.Parent access)
local TerrainGenerator = require(script.Parent:WaitForChild("TerrainGenerator"))

function LevelController.levelInit()
	TerrainGenerator.levelInit()
end

function LevelController.levelFini()
	TerrainGenerator.levelFini()
end

return LevelController
