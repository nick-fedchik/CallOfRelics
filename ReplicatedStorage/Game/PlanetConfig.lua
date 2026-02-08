--[[
================================================================================
KOSMICMAZER — PlanetConfig
================================================================================

Purpose:
Centralized planetary characteristics database. Single source of truth for all
planet physical parameters, weather, and gameplay modifiers. Used by Scanner UI,
PilotUI, and PlanetLocatorUI.

Version:
0.1

Features:
- All planet physical characteristics (gravity, atmosphere, pressure, etc.)
- Weather parameters per planet
- Gameplay modifiers (suit mode, O₂ drain, speed, jump, hazard)
- Planet registry with status and metadata
- API functions for convenient data access

API:
- GetPlanet(planetId) — Full planet table
- GetPlanetName(planetId) — Display name
- GetPhysical(planetId) — Physical characteristics subtable
- GetWeather(planetId) — Weather subtable
- GetGameplay(planetId) — Gameplay modifiers subtable
- GetAllPlanets() — Ordered list for UI display
- GetAbbreviated(planetId) — 5 key params for compact display

Calls to:
- None (pure data module)

Called from:
- PlanetSurfaceScannerUI (full characteristics display)
- PilotUI (abbreviated characteristics)
- PlanetLocatorUI (planet registry list)

Dependencies:
- None

ChangeLog:
- 0.1: Initial planet characteristics database (2026-02-06)
================================================================================
]]

local PlanetConfig = {}

-- ============================================================================
-- PLANET DATABASE
-- ============================================================================

PlanetConfig.Planets = {
	Planet_1 = {
		id = "Planet_1",
		name = "Біллі Рубін",
		type = "Суперземля",
		starSystem = "Бінарна K2V+K5V",
		locations = 7,
		status = "current",

		physical = {
			gravity = "1.2g",
			atmosphere = "Придатна",
			pressure = "1.05 атм",
			temperature = "+12..+34\u{00B0}C",
			radiation = "Низька",
			magneticField = "Сильне",
			water = "Рідка",
			dayNight = "20 хв",
		},

		weather = {
			type = "Спокійна",
			precipitation = "Дощ (легкий)",
			wind = "Слабкий",
			visibility = "Ясно",
		},

		gameplay = {
			suitMode = "Звичайний",
			o2Drain = "\u{00D7}0.5",
			surfaceTime = "Необмежено",
			speedMod = "\u{00D7}0.9",
			jumpMod = "\u{00D7}0.85",
			hazard = "Безпечна",
		},
	},

	Planet_2 = {
		id = "Planet_2",
		name = "Kepler-442b",
		type = "Кам'яна",
		starSystem = "Kepler-442 (K-тип)",
		locations = 2,
		status = "locked",

		physical = {
			gravity = "0.8g",
			atmosphere = "Тонка",
			pressure = "0.3 атм",
			temperature = "-40..+5\u{00B0}C",
			radiation = "Середня",
			magneticField = "Слабке",
			water = "Лід",
			dayNight = "36 хв",
		},

		weather = {
			type = "Суворі",
			precipitation = "Сніг",
			wind = "Сильний",
			visibility = "Низька",
		},

		gameplay = {
			suitMode = "Захисний",
			o2Drain = "\u{00D7}1.5",
			surfaceTime = "30 хв",
			speedMod = "\u{00D7}1.1",
			jumpMod = "\u{00D7}1.2",
			hazard = "Помірна",
		},
	},

	Planet_Earth = {
		id = "Planet_Earth",
		name = "Земля",
		type = "Рідна планета",
		starSystem = "Sol (G2V)",
		locations = 1,
		status = "locked",

		physical = {
			gravity = "1.0g",
			atmosphere = "Придатна",
			pressure = "1.0 атм",
			temperature = "-20..+40\u{00B0}C",
			radiation = "Немає",
			magneticField = "Сильне",
			water = "Рідка",
			dayNight = "24 год",
		},

		weather = {
			type = "Мінлива",
			precipitation = "Дощ / Сніг",
			wind = "Мінливий",
			visibility = "Ясно",
		},

		gameplay = {
			suitMode = "Звичайний",
			o2Drain = "\u{00D7}0.0",
			surfaceTime = "Необмежено",
			speedMod = "\u{00D7}1.0",
			jumpMod = "\u{00D7}1.0",
			hazard = "Безпечна",
		},
	},
}

-- Display order for UI lists
PlanetConfig.PlanetOrder = { "Planet_1", "Planet_2", "Planet_Earth" }

-- ============================================================================
-- API FUNCTIONS
-- ============================================================================

function PlanetConfig.GetPlanet(planetId)
	return PlanetConfig.Planets[planetId]
end

function PlanetConfig.GetPlanetName(planetId)
	local planet = PlanetConfig.Planets[planetId]
	return planet and planet.name or planetId
end

function PlanetConfig.GetPhysical(planetId)
	local planet = PlanetConfig.Planets[planetId]
	return planet and planet.physical or nil
end

function PlanetConfig.GetWeather(planetId)
	local planet = PlanetConfig.Planets[planetId]
	return planet and planet.weather or nil
end

function PlanetConfig.GetGameplay(planetId)
	local planet = PlanetConfig.Planets[planetId]
	return planet and planet.gameplay or nil
end

function PlanetConfig.GetAllPlanets()
	local planets = {}
	for _, planetId in ipairs(PlanetConfig.PlanetOrder) do
		local planet = PlanetConfig.Planets[planetId]
		if planet then
			table.insert(planets, planet)
		end
	end
	return planets
end

function PlanetConfig.GetAbbreviated(planetId)
	local planet = PlanetConfig.Planets[planetId]
	if not planet then return nil end
	return {
		{ label = "Грав", value = planet.physical.gravity },
		{ label = "Атм", value = planet.physical.atmosphere },
		{ label = "Темп", value = planet.physical.temperature },
		{ label = "Рад", value = planet.physical.radiation },
		{ label = "Загроза", value = planet.gameplay.hazard },
	}
end

return PlanetConfig
