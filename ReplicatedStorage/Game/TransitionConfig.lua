--[[
================================================================================
KOSMICMAZER — TransitionConfig
================================================================================

Purpose:
Configuration for location transitions (Orbit ↔ Surface).
Defines animation timings, messages, and transition parameters.

Version:
0.1

Features:
- Departure animation timing (scale down ship, scale up planet)
- Loading screen configuration
- Landing sequence timing (approach, touchdown)
- Liftoff sequence configuration
- Localized messages (Ukrainian)

API:
- Direct require() access (read-only data table)

Calls to:
- None (pure data module)

Called from:
- TransitionService (server-side coordination)
- TransitionUI (client-side animations)
- PilotUI (context detection)

Dependencies:
- None

ChangeLog:
- 0.1: Initial transition configuration (2026-01-14)
================================================================================
]]

local TransitionConfig = {
	-- ============================================================================
	-- ANIMATION DURATIONS (seconds)
	-- ============================================================================

	-- Unified transition duration for landing and liftoff
	TransitionAnimationDuration = 4.0, -- Both landing and liftoff use same duration

	-- Departure animation (on orbit before loading)
	DepartureDuration = 3.0,           -- Planet scale up animation
	DepartureFadeStart = 2.0,          -- Start fade to black at this point

	-- Loading screen
	LoadingMinDuration = 2.0,          -- Minimum time to show loading screen
	LoadingFadeDuration = 0.5,         -- Fade in/out duration

	-- Landing sequence (on surface) - uses TransitionAnimationDuration
	ApproachDuration = 0.0,            -- No separate approach, all in landing
	LandingDuration = 4.0,             -- Ship descending to pad (with deceleration)
	CameraTransitionDuration = 1.5,    -- Camera return to player

	-- Liftoff sequence (from surface) - uses TransitionAnimationDuration
	LiftoffDuration = 4.0,             -- Ship rising from pad (with acceleration)
	AscentDuration = 0.0,              -- No separate ascent, all in liftoff

	-- ============================================================================
	-- SHIP ANIMATION PARAMETERS
	-- ============================================================================

	-- Departure (orbit)
	ShipScaleStart = 1.0,
	ShipScaleEnd = 0.1,
	PlanetScaleStart = 1.0,
	PlanetScaleEnd = 1.5,

	-- Landing (surface)
	ShipSpawnHeight = 500,             -- Height above landing pad
	ShipLandingHeight = 25,            -- Ship center height above pad (ship is ~30 tall, so center at 25 keeps bottom ~10 above pad)

	-- ============================================================================
	-- CAMERA SETTINGS
	-- ============================================================================

	-- Landing camera POV - overhead view (relative to landing pad center)
	-- Camera positioned above and to the left of the pad, looking down at landing area
	LandingCameraOffset = Vector3.new(-100, 150, -50),  -- Above and left of pad
	LandingCameraLookAt = Vector3.new(0, 0, 0),         -- Look at pad center

	-- ============================================================================
	-- TRANSITION STATES
	-- ============================================================================

	States = {
		Idle = "idle",
		GameStart = "gamestart",      -- Initial game start (from ScreenSaver)
		Departure = "departure",
		Loading = "loading",
		Approach = "approach",
		Landing = "landing",
		Complete = "complete",
		Liftoff = "liftoff",
		Ascending = "ascending",
	},

	-- ============================================================================
	-- CONTEXT TYPES
	-- ============================================================================

	Contexts = {
		Orbit = "Orbit",
		Surface = "Surface",
	},

	-- ============================================================================
	-- MESSAGES (Ukrainian)
	-- ============================================================================

	Messages = {
		-- Initial game start (from ScreenSaver)
		GameStart = "Прибуття на орбіту планети %s...",
		GameStartArrival = "Вихід на орбіту...",

		-- Landing
		Landing = "Приземлення на локацію %s...",
		Approaching = "Наближення до поверхні...",
		Touchdown = "Посадка завершена",

		-- Liftoff
		Liftoff = "Підйом на орбіту...",
		Ascending = "Вихід на орбіту...",
		OrbitReached = "Орбіта досягнута",
		OrbitLoading = "Орбіта планети %s...",

		-- Errors
		InvalidLocation = "Локація недоступна",
		TransitionInProgress = "Перехід вже виконується",
		NotInPilotSeat = "Необхідно сидіти в кріслі пілота",
	},

	-- ============================================================================
	-- VISUAL EFFECTS
	-- ============================================================================

	-- Fade overlay
	FadeColor = Color3.fromRGB(0, 0, 0),

	-- Loading screen
	LoadingTextColor = Color3.fromRGB(200, 220, 255),
	LoadingTextSize = 32,
	LoadingFont = Enum.Font.GothamBold,
}

return TransitionConfig
