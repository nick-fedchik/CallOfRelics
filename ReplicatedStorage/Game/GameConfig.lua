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
	Developer = "KosmicMazer",

	-- ============================================================================
	-- INITIAL STATE FOR NEW PLAYERS
	-- ============================================================================

	StartPlanet = "Planet_1",

	-- ============================================================================
	-- BOOT SEQUENCE CONFIGURATION
	-- ============================================================================

	-- Boot sequence stages (dynamic, can add more stages)
	BootStages = {
		{
			name = "GameConfiguration",
			duration = 1.5,
		},
		{
			name = "PlayerInformation",
			duration = 1.5,
		},
		{
			name = "ProfileLoading",
			duration = 2.0,
		},
		{
			name = "ReadyState",
			duration = 0, -- Waits for user input
		},
	},

	-- Additional timing
	ProgressBarPauseBeforeButton = 1.0, -- Pause after 100% before showing button

	-- Error handling configuration
	ErrorRetryEnabled = true,
	ErrorRetryMaxAttempts = 3,
	ErrorMessages = {
		ProfileLoadFailed = "Не вдалося завантажити профіль гравця",
		DataStoreUnavailable = "Сервіси зберігання даних недоступні",
		UnknownError = "Невідома помилка ініціалізації",
	}

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
