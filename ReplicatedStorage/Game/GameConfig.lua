--[[
================================================================================
KOSMICMAZER — GameConfig
================================================================================

Purpose:
Centralized game configuration. Single source of truth for game identity and
initial settings. Used during boot sequence and throughout game lifecycle.

Version:
0.1

Features:
- Game name and version information
- Initial state configuration for new players
- Boot sequence timing parameters
- Extensible for future configuration needs

API:
- Direct require() access (read-only data table)

Calls to:
- None (pure data module)

Called from:
- BootSequence (reads game identity and timing)
- ProfileService (reads StartPlanet for new profiles)

Dependencies:
- None

ChangeLog:
- 0.1: Initial game configuration (2026-01-11)
================================================================================
]]

local GameConfig = {
	-- ============================================================================
	-- GAME IDENTITY
	-- ============================================================================

	GameName = "CALL OF RELICS",
	GameSubtitle = "Orbital Silence",
	Version = "0.1",
	VersionTag = "EPIC 1",
	Developer = "KOSMICMAZER",

	-- ============================================================================
	-- INITIAL STATE FOR NEW PLAYERS
	-- ============================================================================

	StartPlanet = "Planet_1",

	-- ============================================================================
	-- BOOT SEQUENCE CONFIGURATION
	-- ============================================================================

	BootStageDuration = 1.5, -- seconds per stage (base duration)

	-- Stage-specific duration multipliers
	Stage1Duration = 1.5, -- Game Configuration display
	Stage2Duration = 1.5, -- Player Information display
	Stage3Duration = 2.0, -- Profile Loading (longer for DataStore)
	Stage4Duration = 0,   -- Ready State (waits for user input)

	-- ============================================================================
	-- FUTURE: More configuration as game expands
	-- ============================================================================
	-- Will add:
	-- - Ship configuration
	-- - Resource types
	-- - Difficulty settings
	-- - Economy parameters
}

return GameConfig
