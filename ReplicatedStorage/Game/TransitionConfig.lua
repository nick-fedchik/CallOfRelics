--[[
================================================================================
KOSMICMAZER — TransitionConfig
================================================================================

Purpose:
Configuration for location transitions (Orbit ↔ Surface).
Defines animation timings, messages, and transition parameters.

Version:
0.2

Features:
- Departure animation timing (scale down ship, scale up planet)
- Loading screen configuration
- Landing sequence timing (approach, touchdown)
- Launch sequence configuration
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
- 0.2: Rename Liftoff → Launch, Ascending → Ascent (2026-01-15)
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

	-- Landing sequence (on surface) - two-phase animation
	LandingPhase1Duration = 4.0,       -- Phase 1: External view (watching ship descend)
	LandingPhase2Duration = 3.0,       -- Phase 2: Cockpit view (final approach)
	ApproachDuration = 0.0,            -- Legacy: No separate approach
	LandingDuration = 4.0,             -- Legacy: kept for compatibility
	CameraTransitionDuration = 1.5,    -- Camera return to player

	-- Launch sequence (from surface) - two-phase animation
	LaunchPhase1Duration = 3.0,        -- Phase 1: Cockpit view (liftoff - player inside ship)
	LaunchPhase2Duration = 4.0,        -- Phase 2: External view (ascent - watching ship rise)
	LaunchDuration = 4.0,              -- Legacy: kept for compatibility

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
		Departure = "departure",      -- Landing: Phase 0 - planet approach animation on orbit
		Loading = "loading",          -- Loading screen between locations
		Approach = "approach",        -- Landing: Phase 1 - external view watching ship descend
		Landing = "landing",          -- Landing: Phase 2 - cockpit view for touchdown
		Complete = "complete",        -- Transition finished
		Launch = "launch",            -- Launch: Phase 1 - cockpit view during liftoff
		Ascent = "ascent",            -- Launch: Phase 2 - external view watching ship rise
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

		-- Launch
		Launch = "Зліт на орбіту...",
		Ascent = "Вихід на орбіту...",
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
