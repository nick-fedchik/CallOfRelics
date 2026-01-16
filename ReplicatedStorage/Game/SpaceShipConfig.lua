--[[
================================================================================
KOSMICMAZER -- SpaceShipConfig
================================================================================

Purpose:
Centralized configuration for SpaceShip structure and seats.
Defines ship components, seat types, and UI/camera settings.

Version:
0.1

Features:
- SpaceShip structure definition (components, seats, reference points)
- Seat type definitions with display names
- UI module mapping for each seat
- Camera settings per seat type
- Functionality flags for seat capabilities

API:
Structure:
- GetStructure() -- Returns full SPACESHIP_STRUCTURE
- GetSeatNames() -- Returns list of seat names from structure

Seats:
- GetSeatConfig(seatName) -- Returns full config for seat
- GetUIModule(seatName) -- Returns UI module name
- GetCameraSettings(seatName) -- Returns camera settings
- GetDisplayName(seatName) -- Returns localized seat name
- GetFunctionality(seatName) -- Returns functionality flags
- GetAllSeatNames() -- Returns list of all configured seats
- IsSeatKnown(seatName) -- Check if seat is configured

ChangeLog:
- 0.1: Created from SeatConfig + SpaceShipService SPACESHIP_STRUCTURE (2026-01-16)
================================================================================
]]

local SpaceShipConfig = {}

-- ============================================================================
-- SPACESHIP STRUCTURE (Reference for model validation)
-- ============================================================================

SpaceShipConfig.Structure = {
	-- Main model components
	components = {
		-- Configuration folder with ship stats
		Configuration = {
			className = "Configuration",
			properties = {
				"MaxShield",    -- IntValue
				"MaxHull",      -- IntValue
				"ExplosionSize", -- NumberValue
				"Description",  -- StringValue
				"Class",        -- StringValue
				"Mass",         -- NumberValue
			}
		},

		-- Ship structural parts
		ShipParts = {
			className = "Model",
			description = "Ship structural components"
		},

		-- Weapon systems
		Torpedoes = {
			className = "Model",
			description = "Torpedo weapon system"
		},

		-- Seats (mapped to SeatConfig)
		PilotSeat = {
			className = "VehicleSeat",
			description = "Main pilot control seat"
		},
		["Seat Engines"] = {
			className = "Seat",
			description = "Engine control station"
		},
		["Seat Planet Surface Scanner"] = {
			className = "Seat",
			description = "Planet surface scanning station"
		},
		["Seat Planet Locator"] = {
			className = "Seat",
			description = "Planet locator station"
		},
		["Seat Personal Computer"] = {
			className = "Seat",
			description = "Personal terminal for inventory/knowledge"
		},

		-- Reference points
		DockPoint = {
			className = "Part",
			description = "Ship docking connection point"
		},
		CenterPoint = {
			className = "Part",
			description = "Ship center reference point"
		},
	},

	-- Seat names for quick lookup
	seatNames = {
		"PilotSeat",
		"Seat Engines",
		"Seat Planet Surface Scanner",
		"Seat Planet Locator",
		"Seat Personal Computer",
	}
}

-- ============================================================================
-- SEAT CONFIGURATIONS
-- ============================================================================

SpaceShipConfig.Seats = {
	PilotSeat = {
		displayName = "Пілотське крісло",
		uiModule = "PilotUI",
		seatType = "VehicleSeat",
		camera = {
			mode = "Custom",
			fov = 70,
			minZoom = 5,
			maxZoom = 50,
		},
		functionality = {
			canControl = true,
			canNavigate = true,
		}
	},

	["Seat Planet Surface Scanner"] = {
		displayName = "Сканер поверхні",
		uiModule = "PlanetSurfaceScannerUI",
		seatType = "Seat",
		camera = {
			mode = "Custom",
			fov = 70,
			minZoom = 5,
			maxZoom = 50,
		},
		functionality = {
			canScan = true,
		}
	},

	["Seat Engines"] = {
		displayName = "Керування двигунами",
		uiModule = "EnginesUI",
		seatType = "Seat",
		camera = {
			mode = "Custom",
			fov = 70,
			minZoom = 5,
			maxZoom = 30,
		},
		functionality = {
			canControlEngines = true,
		}
	},

	["Seat Planet Locator"] = {
		displayName = "Планетний локатор",
		uiModule = "PlanetLocatorUI",
		seatType = "Seat",
		camera = {
			mode = "Custom",
			fov = 70,
			minZoom = 5,
			maxZoom = 50,
		},
		functionality = {
			canLocatePlanets = true,
		}
	},

	["Seat Personal Computer"] = {
		displayName = "Персональний комп'ютер",
		uiModule = "PersonalComputerUI",
		seatType = "Seat",
		camera = {
			mode = "Custom",
			fov = 70,
			minZoom = 5,
			maxZoom = 30,
		},
		functionality = {
			canAccessInventory = true,
			canAccessKnowledge = true,
		}
	},

	Seat1 = {
		displayName = "Крісло-1",
		uiModule = "GenericSeatUI",
		seatType = "Seat",
		camera = {
			mode = "Custom",
			fov = 70,
			minZoom = 5,
			maxZoom = 30,
		},
		functionality = {}
	},

	Seat2 = {
		displayName = "Крісло-2",
		uiModule = "GenericSeatUI",
		seatType = "Seat",
		camera = {
			mode = "Custom",
			fov = 70,
			minZoom = 5,
			maxZoom = 30,
		},
		functionality = {}
	},

	Seat3 = {
		displayName = "Крісло-3",
		uiModule = "GenericSeatUI",
		seatType = "Seat",
		camera = {
			mode = "Custom",
			fov = 70,
			minZoom = 5,
			maxZoom = 30,
		},
		functionality = {}
	},

	Seat4 = {
		displayName = "Крісло-4",
		uiModule = "GenericSeatUI",
		seatType = "Seat",
		camera = {
			mode = "Custom",
			fov = 70,
			minZoom = 5,
			maxZoom = 30,
		},
		functionality = {}
	},
}

-- Default camera settings for unknown seats
SpaceShipConfig.DefaultCamera = {
	mode = "Custom",
	fov = 70,
	minZoom = 5,
	maxZoom = 30,
}

-- ============================================================================
-- STRUCTURE API
-- ============================================================================

function SpaceShipConfig.GetStructure()
	return SpaceShipConfig.Structure
end

function SpaceShipConfig.GetSeatNames()
	return SpaceShipConfig.Structure.seatNames
end

function SpaceShipConfig.GetComponentInfo(componentName)
	return SpaceShipConfig.Structure.components[componentName]
end

-- ============================================================================
-- SEAT API
-- ============================================================================

function SpaceShipConfig.GetSeatConfig(seatName)
	return SpaceShipConfig.Seats[seatName]
end

function SpaceShipConfig.GetUIModule(seatName)
	local config = SpaceShipConfig.Seats[seatName]
	return config and config.uiModule or nil
end

function SpaceShipConfig.GetCameraSettings(seatName)
	local config = SpaceShipConfig.Seats[seatName]
	return config and config.camera or SpaceShipConfig.DefaultCamera
end

function SpaceShipConfig.GetDisplayName(seatName)
	local config = SpaceShipConfig.Seats[seatName]
	return config and config.displayName or seatName
end

function SpaceShipConfig.GetFunctionality(seatName)
	local config = SpaceShipConfig.Seats[seatName]
	return config and config.functionality or {}
end

function SpaceShipConfig.GetAllSeatNames()
	local names = {}
	for name, _ in pairs(SpaceShipConfig.Seats) do
		table.insert(names, name)
	end
	return names
end

function SpaceShipConfig.IsSeatKnown(seatName)
	return SpaceShipConfig.Seats[seatName] ~= nil
end

-- ============================================================================
-- BACKWARD COMPATIBILITY (SeatConfig aliases)
-- ============================================================================

-- These allow existing code to use SpaceShipConfig as a drop-in replacement
SpaceShipConfig.GetSeatDescription = function(seatName)
	local componentInfo = SpaceShipConfig.Structure.components[seatName]
	return componentInfo and componentInfo.description or nil
end

return SpaceShipConfig
