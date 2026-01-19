--[[
================================================================================
KOSMICMAZER — GameConfig
================================================================================

Purpose:
Centralized game configuration. Single source of truth for game identity and
initial settings. Used during boot sequence and throughout game lifecycle.

Version:
0.7

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
- TransitionService (reads game version)

Dependencies:
- None

ChangeLog:
- 0.7: Version bump to 0.11.0 - Ramp System (2026-01-19)
- 0.6: Version bump to 0.10.0 - Scanner System v2 & Documentation (2026-01-16)
- 0.5: Version bump to 0.8.1 - Launch/Landing naming refactor (2026-01-15)
- 0.4: Version bump for EPIC 8 - Progression System (2026-01-15)
- 0.3: Version bump for Transition System (2026-01-14)
- 0.2: Added BootStages configuration (2026-01-12)
- 0.1: Initial game configuration (2026-01-11)
================================================================================
]]

local GameConfig = {
	-- ============================================================================
	-- GAME IDENTITY
	-- ============================================================================

	GameName = "CALL OF RELICS",
	GameSubtitle = "Orbital Silence",
	Version = "0.11.0",
	VersionTag = "Ramp System",
	Developer = "KosmicMazer",

	-- ============================================================================
	-- SHIP CONFIGURATION
	-- ============================================================================

	ShipName = "Самотній Колумб",
	ShipNameEn = "Ones Columbus",

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
