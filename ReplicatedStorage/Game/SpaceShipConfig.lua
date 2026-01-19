--[[
================================================================================
KOSMICMAZER -- SpaceShipConfig
================================================================================

Purpose:
Centralized configuration for SpaceShip structure and seats.
Defines ship components, seat types, and UI/camera settings.

Version:
0.3

Features:
- SpaceShip structure definition (components, seats, reference points)
- Ship stats (speed, energy, defense)
- Seat type definitions with display names
- UI module mapping for each seat
- Camera settings per seat type
- Functionality flags for seat capabilities
- Scanner configuration (battery, wear system, power consumption)

API:
Structure:
- GetStructure() -- Returns full SPACESHIP_STRUCTURE
- GetSeatNames() -- Returns list of seat names from structure

Stats:
- GetStats() -- Returns ship stats configuration
- GetEnergy() -- Returns energy configuration
- GetSpeed() -- Returns speed configuration

Seats:
- GetSeatConfig(seatName) -- Returns full config for seat
- GetUIModule(seatName) -- Returns UI module name
- GetCameraSettings(seatName) -- Returns camera settings
- GetDisplayName(seatName) -- Returns localized seat name
- GetFunctionality(seatName) -- Returns functionality flags
- GetAllSeatNames() -- Returns list of all configured seats
- IsSeatKnown(seatName) -- Check if seat is configured

Scanner:
- GetScannerConfig() -- Returns scanner configuration
- GetScanPowerConsumption() -- Returns power consumption per scan
- GetScannerBatteryConfig() -- Returns battery configuration
- GetScannerAccuracyConfig() -- Returns accuracy/wear configuration
- CalculateScanAccuracy(scanCount) -- Calculate accuracy based on wear
- GetScansUntilWornOut() -- Get max scans before worn out

ChangeLog:
- 0.3: New scanner model: battery system, wear-based accuracy, power consumption (2026-01-16)
- 0.2: Added ship stats (speed, energy), scanner config (accuracy, energy cost) (2026-01-16)
- 0.1: Created from SeatConfig + SpaceShipService SPACESHIP_STRUCTURE (2026-01-16)
================================================================================
]]

local SpaceShipConfig = {}

-- ============================================================================
-- SPACESHIP STATS (Ship characteristics)
-- ============================================================================

SpaceShipConfig.Stats = {
	-- Speed characteristics
	speed = {
		maxSpeed = 100,           -- Maximum speed (studs/sec)
		acceleration = 20,        -- Acceleration rate (studs/sec²)
		deceleration = 30,        -- Braking rate (studs/sec²)
		maneuverability = 0.8,    -- Turn rate multiplier (0.0 - 1.0)
		boostMultiplier = 1.5,    -- Speed boost multiplier
		boostDuration = 3.0,      -- Boost duration (seconds)
	},

	-- Energy characteristics
	energy = {
		maxEnergy = 1000,         -- Maximum energy capacity
		currentEnergy = 1000,     -- Starting energy (full)
		regenRate = 5,            -- Energy regeneration per second
		regenDelay = 2.0,         -- Delay before regen starts (seconds)

		-- Consumption rates
		consumption = {
			idle = 0,             -- Energy per second when idle
			moving = 2,           -- Energy per second when moving
			boost = 10,           -- Energy per second during boost
			scan = 50,            -- Energy per scan operation
			landing = 100,        -- Energy for landing sequence
			launch = 150,         -- Energy for launch sequence
			interplanetary = 500, -- Energy for interplanetary travel
		},
	},

	-- Defense characteristics (for future use)
	defense = {
		maxShield = 100,          -- Maximum shield points
		maxHull = 200,            -- Maximum hull points
		shieldRegenRate = 2,      -- Shield regen per second
		shieldRegenDelay = 5.0,   -- Delay before shield regen (seconds)
	},
}

-- ============================================================================
-- SCANNER CONFIGURATION
-- ============================================================================

SpaceShipConfig.Scanner = {
	-- Timing
	scanDuration = 5.0,           -- Total scan time (seconds)
	scanCooldown = 10.0,          -- Cooldown between scans (seconds)
	scanSteps = 10,               -- Number of progress updates

	-- Scanner Battery (own power source)
	battery = {
		maxCapacity = 500,        -- Maximum battery capacity
		currentCharge = 500,      -- Starting charge (full)
		rechargeRate = 2,         -- Recharge per second (from ship energy)
		rechargeDelay = 3.0,      -- Delay before recharge starts (seconds)
	},

	-- Power Consumption
	powerConsumption = 100,       -- Energy consumed per scan from scanner battery

	-- Accuracy & Wear System
	accuracy = {
		baseAccuracy = 1.0,       -- 100% accuracy when new
		wearPerScan = 0.05,       -- -5% accuracy per scan (wear)
		minAccuracy = 0.0,        -- 0% minimum (completely worn out)
		repairCost = 200,         -- Energy cost to repair scanner (restore accuracy)
	},

	-- Discovery settings
	maxDiscoveriesPerScan = 1,    -- Max locations discovered per scan
	guaranteedFirstScan = true,   -- First scan always discovers something (ignores accuracy)
}

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
			description = "Ship structural components",
			subComponents = {
				RearShipExit = {
					className = "Part",
					description = "Rear ship exit point for crew disembarkation",
					attributes = {
						material = "DiamondPlate",
						size = "4, 6, 1",
						color = "Toothpaste (Cyan)",
						transparency = 0.25,
						canCollide = false,
						canTouch = true,
						surfaces = {
							top = "Weld",
							bottom = "Weld",
							left = "Weld",
							right = "Weld",
							front = "Smooth",
							back = "Smooth"
						}
					}
				}
			}
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

		-- Ramp system
		ShipRamp = {
			className = "Model",
			description = "Ship boarding ramp model with 10 metal steps for crew boarding",
			attributes = {
				totalSteps = 10,
				stepMaterial = "Metal",
				stepColor = "0.639216, 0.635294, 0.647059 (Silver Gray)",
				stepSize = "10.178728103637695, 2.035745620727539, 5.089364051818848",
				stepHeight = 2.035745620727539,
				stepWidth = 10.178728103637695,
				stepDepth = 5.089364051818848,
				anchored = true,
				canCollide = true,
				transparency = 0,
				reflectance = 0,
				surfaceProperties = {
					topSurface = "Studs",
					bottomSurface = "Inlet",
					frontSurface = "Smooth",
					backSurface = "Smooth",
					leftSurface = "Smooth",
					rightSurface = "Smooth"
				}
			},
			subComponents = {
				Step1 = {
					className = "Part",
					description = "First step of the boarding ramp (highest position)",
					attributes = {
						position = "485.8764953613281, -438.93768310546875, 36.36967468261719",
						size = "10.178728103637695, 2.035745620727539, 5.089364051818848",
						material = "Metal",
						color = "0.639216, 0.635294, 0.647059 (Silver Gray)",
						anchored = true,
						canCollide = true,
						transparency = 0,
						reflectance = 0
					}
				},
				Step2 = {
					className = "Part",
					description = "Second step of the boarding ramp",
					attributes = {
						position = "485.8885803222656, -440.973876953125, 31.280502319335938",
						size = "10.178728103637695, 2.035745620727539, 5.089364051818848",
						material = "Metal",
						color = "0.639216, 0.635294, 0.647059 (Silver Gray)",
						anchored = true,
						canCollide = true,
						transparency = 0,
						reflectance = 0
					}
				},
				Step3 = {
					className = "Part",
					description = "Third step of the boarding ramp",
					attributes = {
						position = "485.90069580078125, -443.01007080078125, 26.19131851196289",
						size = "10.178728103637695, 2.035745620727539, 5.089364051818848",
						material = "Metal",
						color = "0.639216, 0.635294, 0.647059 (Silver Gray)",
						anchored = true,
						canCollide = true,
						transparency = 0,
						reflectance = 0
					}
				},
				Step4 = {
					className = "Part",
					description = "Fourth step of the boarding ramp",
					attributes = {
						position = "485.9126892089844, -445.0462646484375, 21.102144241333008",
						size = "10.178728103637695, 2.035745620727539, 5.089364051818848",
						material = "Metal",
						color = "0.639216, 0.635294, 0.647059 (Silver Gray)",
						anchored = true,
						canCollide = true,
						transparency = 0,
						reflectance = 0
					}
				},
				Step5 = {
					className = "Part",
					description = "Fifth step of the boarding ramp (middle position)",
					attributes = {
						position = "485.92486572265625, -447.08233642578125, 16.012958526611328",
						size = "10.178728103637695, 2.035745620727539, 5.089364051818848",
						material = "Metal",
						color = "0.639216, 0.635294, 0.647059 (Silver Gray)",
						anchored = true,
						canCollide = true,
						transparency = 0,
						reflectance = 0
					}
				},
				Step6 = {
					className = "Part",
					description = "Sixth step of the boarding ramp",
					attributes = {
						position = "485.9369201660156, -449.1185302734375, 10.923778533935547",
						size = "10.178728103637695, 2.035745620727539, 5.089364051818848",
						material = "Metal",
						color = "0.639216, 0.635294, 0.647059 (Silver Gray)",
						anchored = true,
						canCollide = true,
						transparency = 0,
						reflectance = 0
					}
				},
				Step7 = {
					className = "Part",
					description = "Seventh step of the boarding ramp",
					attributes = {
						position = "485.9490051269531, -451.15472412109375, 5.834601402282715",
						size = "10.178728103637695, 2.035745620727539, 5.089364051818848",
						material = "Metal",
						color = "0.639216, 0.635294, 0.647059 (Silver Gray)",
						anchored = true,
						canCollide = true,
						transparency = 0,
						reflectance = 0
					}
				},
				Step8 = {
					className = "Part",
					description = "Eighth step of the boarding ramp",
					attributes = {
						position = "485.961181640625, -453.19091796875, 0.7454242706298828",
						size = "10.178728103637695, 2.035745620727539, 5.089364051818848",
						material = "Metal",
						color = "0.639216, 0.635294, 0.647059 (Silver Gray)",
						anchored = true,
						canCollide = true,
						transparency = 0,
						reflectance = 0
					}
				},
				Step9 = {
					className = "Part",
					description = "Ninth step of the boarding ramp",
					attributes = {
						position = "485.9731750488281, -455.22711181640625, -4.343758583068848",
						size = "10.178728103637695, 2.035745620727539, 5.089364051818848",
						material = "Metal",
						color = "0.639216, 0.635294, 0.647059 (Silver Gray)",
						anchored = true,
						canCollide = true,
						transparency = 0,
						reflectance = 0
					}
				},
				Step10 = {
					className = "Part",
					description = "Tenth step of the boarding ramp (lowest position, ground level)",
					attributes = {
						position = "485.98529052734375, -457.26324462890625, -9.432936668395996",
						size = "10.178728103637695, 2.035745620727539, 5.089364051818848",
						material = "Metal",
						color = "0.639216, 0.635294, 0.647059 (Silver Gray)",
						anchored = true,
						canCollide = true,
						transparency = 0,
						reflectance = 0
					}
				}
			}
		},
		RampTrigger = {
			className = "Part",
			description = "Trigger zone for automatic ramp activation/deactivation when players approach",
			attributes = {
				position = "486, -437.9664001464844, 41.900001525878906",
				size = "4, 1, 5.800000190734863",
				shape = "Block",
				material = "Metal",
				color = "0.3333333432674408, 0.3333333432674408, 1 (Royal Purple)",
				brickColor = "Royal purple",
				anchored = false,
				canCollide = true,
				canTouch = true,
				canQuery = true,
				transparency = 0,
				reflectance = 0,
				castShadow = true,
				massless = false,
				locked = false,
				collisionGroup = "Default",
				rootPriority = 0,
				enableFluidForces = true,
				audioCanCollide = true,
				surfaceProperties = {
					topSurface = "Smooth",
					bottomSurface = "Smooth",
					frontSurface = "Smooth",
					backSurface = "Smooth",
					leftSurface = "Smooth",
					rightSurface = "Smooth"
				},
				physicsProperties = {
					assemblyLinearVelocity = "0, 0, 0",
					assemblyAngularVelocity = "0, 0, 0",
					pivotOffset = {
						position = "0, 0, 0",
						rotation = "1, 0, 0, 0, 1, 0, 0, 0, 1"
					}
				}
			}
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
-- STATS API
-- ============================================================================

function SpaceShipConfig.GetStats()
	return SpaceShipConfig.Stats
end

function SpaceShipConfig.GetSpeed()
	return SpaceShipConfig.Stats.speed
end

function SpaceShipConfig.GetEnergy()
	return SpaceShipConfig.Stats.energy
end

function SpaceShipConfig.GetDefense()
	return SpaceShipConfig.Stats.defense
end

function SpaceShipConfig.GetEnergyConsumption(action)
	return SpaceShipConfig.Stats.energy.consumption[action] or 0
end

-- ============================================================================
-- SCANNER API
-- ============================================================================

function SpaceShipConfig.GetScannerConfig()
	return SpaceShipConfig.Scanner
end

function SpaceShipConfig.GetScanDuration()
	return SpaceShipConfig.Scanner.scanDuration
end

function SpaceShipConfig.GetScanCooldown()
	return SpaceShipConfig.Scanner.scanCooldown
end

function SpaceShipConfig.GetScanPowerConsumption()
	return SpaceShipConfig.Scanner.powerConsumption
end

function SpaceShipConfig.GetScannerBatteryConfig()
	return SpaceShipConfig.Scanner.battery
end

function SpaceShipConfig.GetScannerAccuracyConfig()
	return SpaceShipConfig.Scanner.accuracy
end

-- Calculate current accuracy based on wear (scan count)
function SpaceShipConfig.CalculateScanAccuracy(scanCount)
	local config = SpaceShipConfig.Scanner.accuracy
	local accuracy = config.baseAccuracy - (scanCount * config.wearPerScan)
	return math.clamp(accuracy, config.minAccuracy, config.baseAccuracy)
end

-- Calculate how many scans until scanner is worn out
function SpaceShipConfig.GetScansUntilWornOut()
	local config = SpaceShipConfig.Scanner.accuracy
	return math.floor(config.baseAccuracy / config.wearPerScan)
end

-- Calculate discovery chance based on:
-- 1. Battery charge ratio (if charge < powerConsumption, proportionally reduce)
-- 2. Wear-based accuracy (degrades with scan count)
-- 3. Location visibility (0-100%)
-- Formula: discoveryChance = effectiveAccuracy × (locationVisibility / 100)
--          effectiveAccuracy = wearAccuracy × chargeRatio
function SpaceShipConfig.CalculateDiscoveryChance(scanCount, currentCharge, locationVisibility)
	local scannerConfig = SpaceShipConfig.Scanner

	-- 1. Charge ratio: if charge >= powerConsumption, ratio = 1.0
	local chargeRatio = math.min(currentCharge / scannerConfig.powerConsumption, 1.0)

	-- 2. Wear-based accuracy
	local wearAccuracy = SpaceShipConfig.CalculateScanAccuracy(scanCount)

	-- 3. Effective accuracy (wear × charge)
	local effectiveAccuracy = wearAccuracy * chargeRatio

	-- 4. Apply location visibility (0-100 → 0-1)
	local visibility = (locationVisibility or 100) / 100
	local discoveryChance = effectiveAccuracy * visibility

	return math.clamp(discoveryChance, 0, 1)
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
