--[[
================================================================================
KOSMICMAZER -- SpaceShipConfig
================================================================================

Purpose:
Centralized configuration for SpaceShip structure and seats.
Defines ship components, seat types, and UI/camera settings.

Version:
0.7

Features:
- SpaceShip structure definition (components, seats, reference points)
- Ship stats (speed, energy, defense)
- Seat type definitions with display names
- UI module mapping for each seat
- Camera settings per seat type
- Functionality flags for seat capabilities
- Scanner configuration (battery, wear system, power consumption)
- Ramp configuration (animation timing, highlight color)
- Complete lighting system documentation (rear cabin illumination)
- Lighting parts API for dynamic light management
- Cargo lighting system documentation and API
- Direct SpaceShip child parts management
- Ramp configuration (animation timing, highlight color)

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

Ramp:
- GetRampConfig() -- Returns ramp configuration
- GetRampAnimationTiming() -- Returns animation timing settings

ChangeLog:
- 0.7: Added pilot monitors configuration (PilotMonitorLeft, PilotMonitorRight) with detailed attributes and special properties (2026-01-19)
- 0.6: Cargo lighting system documentation and API (CargoLighter part) (2026-01-19)
- 0.5: Complete lighting system documentation and API (rear cabin illumination, 6 lighting parts) (2026-01-19)
- 0.4: Ramp configuration (animation timing, trigger highlight) (2026-01-19)
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
-- RAMP CONFIGURATION
-- ============================================================================

SpaceShipConfig.Ramp = {
	-- Animation timing
	animation = {
		deployDuration = 1.5,     -- Total time to deploy ramp (seconds)
		retractDuration = 1.5,    -- Total time to retract ramp (seconds)
		stepDelay = 0.1,          -- Delay between each step appearing/disappearing
		fadeTime = 0.3,           -- Fade in/out time for each step
	},

	-- Trigger settings
	trigger = {
		highlightColor = Color3.fromRGB(0, 255, 128),  -- Green glow when active
		highlightTransparency = 0.5,                   -- Highlight transparency
		inactiveTransparency = 1,                      -- Fully invisible when inactive
	},

	-- RearShipExit settings
	exitBlockedTransparency = 0.25,   -- Semi-transparent when blocking (visual cue)
	exitOpenTransparency = 0.8,       -- More transparent when open

	-- Step count (should match ShipRamp model)
	totalSteps = 11,
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
			description = "Ship structural components including engines, hull, and exit points",
			subComponents = {
				-- Bottom engines
				BottomEngineLeft = {
					className = "Part",
					description = "Left bottom engine with fire effect for propulsion",
					attributes = {
						position = "449.9994812011719, -455.4991149902344, 38.5",
						size = "10, 1, 8",
						shape = "Block",
						material = "Plastic",
						color = "0.7686274647712708, 0.1568627506494522, 0.10980392247438431 (Bright Red)",
						brickColor = "Bright red",
						anchored = false,
						canCollide = true,
						canTouch = true,
						canQuery = true,
						transparency = 1,
						reflectance = 0,
						massless = false,
						locked = false,
						castShadow = true,
						collisionGroup = "Default",
						rootPriority = 0,
						enableFluidForces = true,
						audioCanCollide = true,
						rotation = "-90, 0.0020000000949949026, 0",
						surfaceProperties = {
							topSurface = "Studs",
							bottomSurface = "Weld",
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
						},
						childComponents = {
							Fire = {
								className = "Fire",
								description = "Engine fire effect for left bottom engine",
								attributes = {
									enabled = true,
									color = "0.9254902005195618, 0.545098066329956, 0.27450981736183167 (Orange)",
									secondaryColor = "0.545098066329956, 0.3137255012989044, 0.21568629145622253 (Brown)",
									heat = 20,
									size = 20,
									timeScale = 1
								}
							},
							Weld = {
								className = "Weld",
								description = "Weld constraint for left bottom engine attachment"
							}
						}
					}
				},
				BottomEngineRight = {
					className = "Part",
					description = "Right bottom engine with fire effect for propulsion",
					attributes = {
						position = "521.9993896484375, -455.5003967285156, 38.5",
						size = "10, 1, 8",
						shape = "Block",
						material = "Plastic",
						color = "0.7686274647712708, 0.1568627506494522, 0.10980392247438431 (Bright Red)",
						brickColor = "Bright red",
						anchored = false,
						canCollide = true,
						canTouch = true,
						canQuery = true,
						transparency = 1,
						reflectance = 0,
						massless = false,
						locked = false,
						castShadow = true,
						collisionGroup = "Default",
						rootPriority = 0,
						enableFluidForces = true,
						audioCanCollide = true,
						rotation = "-90, 0.0010000000474974513, 0",
						surfaceProperties = {
							topSurface = "Studs",
							bottomSurface = "Weld",
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
						},
						childComponents = {
							Fire = {
								className = "Fire",
								description = "Engine fire effect for right bottom engine",
								attributes = {
									enabled = true,
									color = "0.9254902005195618, 0.545098066329956, 0.27450981736183167 (Orange)",
									secondaryColor = "0.545098066329956, 0.3137255012989044, 0.21568629145622253 (Brown)",
									heat = 20,
									size = 20,
									timeScale = 1
								}
							}
						}
					}
				},
					-- Exit point
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
				},

				-- Rear cabin lighting system
				RearCeilingLightCenter = {
					className = "Part",
					description = "Central ceiling light for rear cabin illumination",
					attributes = {
						position = "0.49877893924713135, 9.000385284423828, 31.495079040527344",
						size = "11, 1, 11",
						shape = "Block",
						material = "Neon",
						color = "0.7686274647712708, 0.1568627506494522, 0.10980392247438431 (Bright red)",
						brickColor = "Bright red",
						anchored = false,
						canCollide = true,
						canTouch = true,
						canQuery = true,
						transparency = 0,
						reflectance = 0,
						massless = false,
						locked = false,
						castShadow = true,
						collisionGroup = "Default",
						rootPriority = 0,
						enableFluidForces = true,
						audioCanCollide = true,
						rotation = "0, 0, 0.0010000000474974513",
						surfaceProperties = {
							topSurface = "Weld",
							bottomSurface = "Weld",
							frontSurface = "SmoothNoOutlines",
							backSurface = "SmoothNoOutlines",
							leftSurface = "SmoothNoOutlines",
							rightSurface = "SmoothNoOutlines"
						},
						physicsProperties = {
							assemblyLinearVelocity = "0, 0, 0",
							assemblyAngularVelocity = "0, 0, 0",
							pivotOffset = {
								position = "0, 0, 0",
								rotation = "1, 0, 0, 0, 1, 0, 0, 0, 1"
							}
						},
						childComponents = {
							PointLight = {
								className = "PointLight",
								description = "Central cabin illumination source",
								attributes = {
									enabled = true,
									color = "1, 1, 1 (White)",
									brightness = 1,
									range = 20,
									shadows = false
								}
							},
							Weld = {
								className = "Weld",
								description = "Weld constraint for central ceiling light attachment"
							}
						}
					}
				},

				RearCeilingLightLeftFront = {
					className = "Part",
					description = "Left front ceiling light for rear cabin illumination",
					attributes = {
						position = "-16.500961303710938, 5.000600814819336, 41.995079040527344",
						size = "1, 1, 2",
						shape = "Block",
						material = "Neon",
						color = "0.929411768913269, 0.9176470637321472, 0.9176470637321472 (Lily white)",
						brickColor = "Lily white",
						anchored = false,
						canCollide = true,
						canTouch = true,
						canQuery = true,
						transparency = 0,
						reflectance = 0,
						massless = false,
						locked = false,
						castShadow = true,
						collisionGroup = "Default",
						rootPriority = 0,
						enableFluidForces = true,
						audioCanCollide = true,
						rotation = "0, 0, -0.0010000000474974513",
						surfaceProperties = {
							topSurface = "SmoothNoOutlines",
							bottomSurface = "SmoothNoOutlines",
							frontSurface = "SmoothNoOutlines",
							backSurface = "SmoothNoOutlines",
							leftSurface = "SmoothNoOutlines",
							rightSurface = "SmoothNoOutlines"
						},
						physicsProperties = {
							assemblyLinearVelocity = "0, 0, 0",
							assemblyAngularVelocity = "0, 0, 0",
							pivotOffset = {
								position = "0, 0, 0",
								rotation = "1, 0, 0, 0, 1, 0, 0, 0, 1"
							}
						},
						childComponents = {
							PointLight = {
								className = "PointLight",
								description = "Left front cabin illumination source",
								attributes = {
									enabled = true,
									color = "1, 1, 1 (White)",
									brightness = 1,
									range = 20,
									shadows = true
								}
							},
							Weld = {
								className = "Weld",
								description = "Weld constraint for left front ceiling light attachment"
							}
						}
					}
				},

				RearCeilingLightLeftRear = {
					className = "Part",
					description = "Left rear ceiling light for rear cabin illumination (high intensity)",
					attributes = {
						position = "-16.500886917114258, 9.500600814819336, -8.004920959472656",
						size = "1, 14, 18",
						shape = "Block",
						material = "Neon",
						color = "0, 1, 1 (Toothpaste)",
						brickColor = "Toothpaste",
						anchored = false,
						canCollide = true,
						canTouch = true,
						canQuery = true,
						transparency = 0,
						reflectance = 0,
						massless = false,
						locked = false,
						castShadow = true,
						collisionGroup = "Default",
						rootPriority = 0,
						enableFluidForces = true,
						audioCanCollide = true,
						rotation = "180, 0, -179.99899291992188",
						surfaceProperties = {
							topSurface = "SmoothNoOutlines",
							bottomSurface = "Weld",
							frontSurface = "Weld",
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
						},
						childComponents = {
							PointLight = {
								className = "PointLight",
								description = "Left rear high-intensity cabin illumination source",
								attributes = {
									enabled = true,
									color = "1, 1, 1 (White)",
									brightness = 10,
									range = 30,
									shadows = true
								}
							},
							Weld = {
								className = "Weld",
								description = "Weld constraint for left rear ceiling light attachment"
							}
						}
					}
				},

				SideLightStripRightFront = {
					className = "Part",
					description = "Right front side light strip for cabin illumination",
					attributes = {
						position = "16.499053955078125, 5.000140190124512, 41.995079040527344",
						size = "1, 1, 2",
						shape = "Block",
						material = "Neon",
						color = "0.929411768913269, 0.9176470637321472, 0.9176470637321472 (Lily white)",
						brickColor = "Lily white",
						anchored = false,
						canCollide = true,
						canTouch = true,
						canQuery = true,
						transparency = 0,
						reflectance = 0,
						massless = false,
						locked = false,
						castShadow = true,
						collisionGroup = "Default",
						rootPriority = 0,
						enableFluidForces = true,
						audioCanCollide = true,
						rotation = "0, 0, 0",
						surfaceProperties = {
							topSurface = "SmoothNoOutlines",
							bottomSurface = "SmoothNoOutlines",
							frontSurface = "SmoothNoOutlines",
							backSurface = "SmoothNoOutlines",
							leftSurface = "SmoothNoOutlines",
							rightSurface = "SmoothNoOutlines"
						},
						physicsProperties = {
							assemblyLinearVelocity = "0, 0, 0",
							assemblyAngularVelocity = "0, 0, 0",
							pivotOffset = {
								position = "0, 0, 0",
								rotation = "1, 0, 0, 0, 1, 0, 0, 0, 1"
							}
						},
						childComponents = {
							PointLight = {
								className = "PointLight",
								description = "Right front side illumination source",
								attributes = {
									enabled = true,
									color = "1, 1, 1 (White)",
									brightness = 1,
									range = 20,
									shadows = false
								}
							},
							Weld = {
								className = "Weld",
								description = "Weld constraint for right front side light strip attachment"
							}
						}
					}
				},

				SideLightStripRightRear = {
					className = "Part",
					description = "Right rear side light strip for cabin illumination (high intensity)",
					attributes = {
						position = "16.499114990234375, 9.500131607055664, -8.004920959472656",
						size = "1, 14, 18",
						shape = "Block",
						material = "Neon",
						color = "0, 1, 1 (Toothpaste)",
						brickColor = "Toothpaste",
						anchored = false,
						canCollide = true,
						canTouch = true,
						canQuery = true,
						transparency = 0,
						reflectance = 0,
						massless = false,
						locked = false,
						castShadow = true,
						collisionGroup = "Default",
						rootPriority = 0,
						enableFluidForces = true,
						audioCanCollide = true,
						rotation = "180, 0, -179.99899291992188",
						surfaceProperties = {
							topSurface = "SmoothNoOutlines",
							bottomSurface = "Weld",
							frontSurface = "Weld",
							backSurface = "Smooth",
							leftSurface = "Weld",
							rightSurface = "Smooth"
						},
						physicsProperties = {
							assemblyLinearVelocity = "0, 0, 0",
							assemblyAngularVelocity = "0, 0, 0",
							pivotOffset = {
								position = "0, 0, 0",
								rotation = "1, 0, 0, 0, 1, 0, 0, 0, 1"
							}
						},
						childComponents = {
							PointLight = {
								className = "PointLight",
								description = "Right rear high-intensity side illumination source",
								attributes = {
									enabled = true,
									color = "1, 1, 1 (White)",
									brightness = 10,
									range = 30,
									shadows = true
								}
							},
							Weld = {
								className = "Weld",
								description = "Weld constraint for right rear side light strip attachment"
							}
						}
					}
				},

				RearIndicatorLight = {
					className = "Part",
					description = "Rear indicator light for ship status and visibility",
					attributes = {
						position = "-0.001049626269377768, 3.500255584716797, -37.504920959472656",
						size = "6, 2, 17",
						shape = "Block",
						material = "Neon",
						color = "0, 1, 1 (Toothpaste)",
						brickColor = "Toothpaste",
						anchored = false,
						canCollide = true,
						canTouch = true,
						canQuery = true,
						transparency = 0,
						reflectance = 0,
						massless = false,
						locked = false,
						castShadow = true,
						collisionGroup = "Default",
						rootPriority = 0,
						enableFluidForces = true,
						audioCanCollide = true,
						rotation = "180, 0, 180",
						surfaceProperties = {
							topSurface = "SmoothNoOutlines",
							bottomSurface = "Weld",
							frontSurface = "Weld",
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
						},
						childComponents = {
							PointLight = {
								className = "PointLight",
								description = "Rear indicator illumination source",
								attributes = {
									enabled = true,
									color = "1, 1, 1 (White)",
									brightness = 10,
									range = 30,
									shadows = true
								}
							},
							Weld = {
								className = "Weld",
								description = "Weld constraint for rear indicator light attachment"
							}
						}
					}
				},

				-- Pilot monitors for cockpit interface
				PilotMonitorLeft = {
					className = "Part",
					description = "Left pilot monitor for cockpit interface display",
					attributes = {
						position = "9.499028205871582, 9.000290870666504, 90.99506378173828",
						size = "1, 5, 8",
						shape = "Block",
						material = "Plastic",
						color = "0.10588235408067703, 0.16470588743686676, 0.2078431397676468 (Black)",
						brickColor = "Black",
						anchored = false,
						canCollide = true,
						canTouch = true,
						canQuery = true,
						transparency = 0,
						reflectance = 0,
						massless = false,
						locked = false,
						castShadow = true,
						collisionGroup = "Default",
						rootPriority = 0,
						enableFluidForces = true,
						audioCanCollide = true,
						rotation = "0, 0, 0",
						surfaceProperties = {
							topSurface = "SmoothNoOutlines",
							bottomSurface = "SmoothNoOutlines",
							frontSurface = "SmoothNoOutlines",
							backSurface = "SmoothNoOutlines",
							leftSurface = "SmoothNoOutlines",
							rightSurface = "Smooth"
						},
						physicsProperties = {
							assemblyLinearVelocity = "0, 0, 0",
							assemblyAngularVelocity = "0, 0, 0",
							pivotOffset = {
								position = "0, 0, 0",
								rotation = "1, 0, 0, 0, 1, 0, 0, 0, 1"
							}
						},
						childComponents = {
							Weld = {
								className = "Weld",
								description = "Weld constraint for left pilot monitor attachment"
							}
						},
						specialProperties = {
							purpose = "PilotInterface",
							location = "CockpitLeft",
							installationType = "Fixed",
							maintenanceAccess = "Moderate",
							powerConsumption = "Low",
							displayType = "InterfaceMonitor",
							functionality = "FlightDataDisplay"
						}
					}
				},

				PilotMonitorRight = {
					className = "Part",
					description = "Right pilot monitor for cockpit interface display",
					attributes = {
						position = "-9.50090217590332, 9.000511169433594, 90.99506378173828",
						size = "1, 5, 8",
						shape = "Block",
						material = "Plastic",
						color = "0.10588235408067703, 0.16470588743686676, 0.2078431397676468 (Black)",
						brickColor = "Black",
						anchored = false,
						canCollide = true,
						canTouch = true,
						canQuery = true,
						transparency = 0,
						reflectance = 0,
						massless = false,
						locked = false,
						castShadow = true,
						collisionGroup = "Default",
						rootPriority = 0,
						enableFluidForces = true,
						audioCanCollide = true,
						rotation = "180, 0, -179.99899291992188",
						surfaceProperties = {
							topSurface = "SmoothNoOutlines",
							bottomSurface = "SmoothNoOutlines",
							frontSurface = "SmoothNoOutlines",
							backSurface = "SmoothNoOutlines",
							leftSurface = "SmoothNoOutlines",
							rightSurface = "Smooth"
						},
						physicsProperties = {
							assemblyLinearVelocity = "0, 0, 0",
							assemblyAngularVelocity = "0, 0, 0",
							pivotOffset = {
								position = "0, 0, 0",
								rotation = "1, 0, 0, 0, 1, 0, 0, 0, 1"
							}
						},
						childComponents = {
							Weld = {
								className = "Weld",
								description = "Weld constraint for right pilot monitor attachment"
							}
						},
						specialProperties = {
							purpose = "PilotInterface",
							location = "CockpitRight",
							installationType = "Fixed",
							maintenanceAccess = "Moderate",
							powerConsumption = "Low",
							displayType = "InterfaceMonitor",
							functionality = "FlightDataDisplay"
						}
					}
				},

				-- Cargo lighting system
				CargoLighter = {
					className = "Part",
					description = "Cargo area illumination light for rear cabin visibility",
					attributes = {
						position = "Direct child of SpaceShip model",
						size = "Varies based on cargo area requirements",
						shape = "Block",
						material = "Neon",
						color = "1, 0, 0 (Bright red)",
						brickColor = "Bright red",
						anchored = false,
						canCollide = true,
						canTouch = true,
						canQuery = true,
						transparency = 0,
						reflectance = 0,
						massless = false,
						locked = false,
						castShadow = true,
						collisionGroup = "Default",
						rootPriority = 0,
						enableFluidForces = true,
						audioCanCollide = true,
						rotation = "Varies based on installation",
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
						},
						childComponents = {
							PointLight = {
								className = "PointLight",
								description = "Cargo area illumination source",
								attributes = {
									enabled = true,
									color = "1, 1, 1 (White)",
									brightness = "Varies based on cargo requirements",
									range = "Varies based on cargo area size",
									shadows = false
								}
							}
						},
						specialProperties = {
							purpose = "CargoAreaIllumination",
							location = "DirectSpaceShipChild",
							installationType = "Modular",
							maintenanceAccess = "Easy",
							powerConsumption = "Low"
						}
					}
				},

				-- Ship ramp visual enhancement system
				RampStripes = {
					className = "Model",
					description = "Visual enhancement system for ship ramp with pulsating blue stripes",
					attributes = {
						parent = "ShipRamp",
						location = "Sides of each ramp step",
						totalSteps = 11,
						stripesPerStep = 2,
						totalStripes = 22,
						stripeWidthRatio = 0.1, -- 10% of step width
						material = "Neon",
						color = "0, 0.5, 1 (Bright blue)",
						brickColor = "Bright blue",
						anchored = true,
						canCollide = false,
						canTouch = true,
						canQuery = true,
						transparency = "Variable (pulsating 0.1-0.7)",
						reflectance = 0,
						massless = false,
						locked = false,
						castShadow = false,
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
						},
						childComponents = {
							PointLight = {
								className = "PointLight",
								description = "Pulsating illumination source for ramp stripes",
								attributes = {
									enabled = true,
									color = "0, 0.5, 1 (Blue)",
									brightness = "Variable (pulsating 1-3)",
									range = 5,
									shadows = false
								}
							}
						},
						stepStripes = {
							Step1 = {
								leftStripe = "LeftStripe_1",
								rightStripe = "RightStripe_1",
								stripeWidth = 1.0178728103637696,
								stepWidth = 10.178728103637696,
								position = "Left and right sides of Step1"
							},
							Step2 = {
								leftStripe = "LeftStripe_2",
								rightStripe = "RightStripe_2",
								stripeWidth = 1.0178728103637696,
								stepWidth = 10.178728103637696,
								position = "Left and right sides of Step2"
							},
							Step3 = {
								leftStripe = "LeftStripe_3",
								rightStripe = "RightStripe_3",
								stripeWidth = 1.0178728103637696,
								stepWidth = 10.178728103637696,
								position = "Left and right sides of Step3"
							},
							Step4 = {
								leftStripe = "LeftStripe_4",
								rightStripe = "RightStripe_4",
								stripeWidth = 1.0178728103637696,
								stepWidth = 10.178728103637696,
								position = "Left and right sides of Step4"
							},
							Step5 = {
								leftStripe = "LeftStripe_5",
								rightStripe = "RightStripe_5",
								stripeWidth = 1.0178728103637696,
								stepWidth = 10.178728103637696,
								position = "Left and right sides of Step5"
							},
							Step6 = {
								leftStripe = "LeftStripe_6",
								rightStripe = "RightStripe_6",
								stripeWidth = 1.0178728103637696,
								stepWidth = 10.178728103637696,
								position = "Left and right sides of Step6"
							},
							Step7 = {
								leftStripe = "LeftStripe_7",
								rightStripe = "RightStripe_7",
								stripeWidth = 1.0178728103637696,
								stepWidth = 10.178728103637696,
								position = "Left and right sides of Step7"
							},
							Step8 = {
								leftStripe = "LeftStripe_8",
								rightStripe = "RightStripe_8",
								stripeWidth = 1.0178728103637696,
								stepWidth = 10.178728103637696,
								position = "Left and right sides of Step8"
							},
							Step9 = {
								leftStripe = "LeftStripe_9",
								rightStripe = "RightStripe_9",
								stripeWidth = 1.0178728103637696,
								stepWidth = 10.178728103637696,
								position = "Left and right sides of Step9"
							},
							Step10 = {
								leftStripe = "LeftStripe_10",
								rightStripe = "RightStripe_10",
								stripeWidth = 1.0178728103637696,
								stepWidth = 10.178728103637696,
								position = "Left and right sides of Step10"
							},
							Step11 = {
								leftStripe = "LeftStripe_11",
								rightStripe = "RightStripe_11",
								stripeWidth = 1.0178728103637696,
								stepWidth = 10.178728103637696,
								position = "Left and right sides of Step11"
							}
						},
						specialProperties = {
							purpose = "VisualEnhancement",
							location = "ShipRampSides",
							installationType = "Decorative",
							maintenanceAccess = "Easy",
							powerConsumption = "Low",
							pulsatingEffect = true,
							synchronization = "AllStripes",
							animationSpeed = "2 seconds per cycle",
							transparencyRange = "0.1-0.7",
							brightnessRange = "1-3"
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
			description = "Ship boarding ramp model with 11 metal steps for crew boarding",
			attributes = {
				totalSteps = 11,
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
					description = "Tenth step of the boarding ramp",
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
				},
				Step11 = {
					className = "Part",
					description = "Eleventh step of the boarding ramp (lowest position, ground level)",
					attributes = {
						position = "485.9973449707031, -459.29937744140625, -14.522115707397461",
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
-- RAMP API
-- ============================================================================

function SpaceShipConfig.GetRampConfig()
	return SpaceShipConfig.Ramp
end

function SpaceShipConfig.GetRampAnimationTiming()
	return SpaceShipConfig.Ramp.animation
end

function SpaceShipConfig.GetRampTriggerConfig()
	return SpaceShipConfig.Ramp.trigger
end

function SpaceShipConfig.GetRampTotalSteps()
	return SpaceShipConfig.Ramp.totalSteps
end

-- ============================================================================
-- LIGHTING SYSTEM API
-- ============================================================================

function SpaceShipConfig.GetLightingConfig()
	return {
		-- Rear cabin lighting system
		rearCabin = {
			-- Central ceiling light (main illumination)
			centerLight = {
				partName = "RearCeilingLightCenter",
				description = "Central ceiling light for rear cabin illumination",
				type = "MainLight",
				intensity = "Normal",
				color = "Bright Red",
				material = "Neon",
				lightProperties = {
					enabled = true,
					color = "White",
					brightness = 1,
					range = 20,
					shadows = false
				}
			},

			-- Left side lights
			leftLights = {
				front = {
					partName = "RearCeilingLightLeftFront",
					description = "Left front ceiling light",
					type = "AccentLight",
					intensity = "Normal",
					color = "Lily White",
					material = "Neon",
					lightProperties = {
						enabled = true,
						color = "White",
						brightness = 1,
						range = 20,
						shadows = true
					}
				},
				rear = {
					partName = "RearCeilingLightLeftRear",
					description = "Left rear high-intensity ceiling light",
					type = "HighIntensityLight",
					intensity = "High",
					color = "Toothpaste (Cyan)",
					material = "Neon",
					lightProperties = {
						enabled = true,
						color = "White",
						brightness = 10,
						range = 30,
						shadows = true
					}
				}
			},

			-- Right side lights
			rightLights = {
				front = {
					partName = "SideLightStripRightFront",
					description = "Right front side light strip",
					type = "AccentLight",
					intensity = "Normal",
					color = "Lily White",
					material = "Neon",
					lightProperties = {
						enabled = true,
						color = "White",
						brightness = 1,
						range = 20,
						shadows = false
					}
				},
				rear = {
					partName = "SideLightStripRightRear",
					description = "Right rear high-intensity side light strip",
					type = "HighIntensityLight",
					intensity = "High",
					color = "Toothpaste (Cyan)",
					material = "Neon",
					lightProperties = {
						enabled = true,
						color = "White",
						brightness = 10,
						range = 30,
						shadows = true
					}
				}
			},

			-- Rear indicator light
			indicator = {
				partName = "RearIndicatorLight",
				description = "Rear indicator light for ship status and visibility",
				type = "IndicatorLight",
				intensity = "High",
				color = "Toothpaste (Cyan)",
				material = "Neon",
				lightProperties = {
					enabled = true,
					color = "White",
					brightness = 10,
					range = 30,
					shadows = true
				}
			}
		},

		-- Cargo lighting system
		cargoArea = {
			mainLight = {
				partName = "CargoLighter",
				description = "Cargo area illumination light for rear cabin visibility",
				type = "CargoLight",
				intensity = "Variable",
				color = "Bright Red",
				material = "Neon",
				location = "DirectSpaceShipChild",
				lightProperties = {
					enabled = true,
					color = "White",
					brightness = "Variable based on cargo requirements",
					range = "Variable based on cargo area size",
					shadows = false
				},
				specialProperties = {
					purpose = "CargoAreaIllumination",
					installationType = "Modular",
					maintenanceAccess = "Easy",
					powerConsumption = "Low"
				}
			}
		},

		-- Lighting system metadata
		metadata = {
			totalLights = 7,
			highIntensityLights = 3,
			normalIntensityLights = 3,
			cargoLights = 1,
			materials = {"Neon"},
			colors = {"Bright Red", "Lily White", "Toothpaste (Cyan)"},
			functions = {
				"CabinIllumination",
				"StatusIndication",
				"AmbientLighting",
				"NavigationAid",
				"CargoAreaLighting"
			}
		}
	}
end

function SpaceShipConfig.GetLightingPart(partName)
	local lightingConfig = SpaceShipConfig.GetLightingConfig()
	local rearCabin = lightingConfig.rearCabin
	local cargoArea = lightingConfig.cargoArea
	
	-- Check center light
	if rearCabin.centerLight.partName == partName then
		return rearCabin.centerLight
	end
	
	-- Check indicator light
	if rearCabin.indicator.partName == partName then
		return rearCabin.indicator
	end
	
	-- Check left lights
	if rearCabin.leftLights.front.partName == partName then
		return rearCabin.leftLights.front
	end
	if rearCabin.leftLights.rear.partName == partName then
		return rearCabin.leftLights.rear
	end
	
	-- Check right lights
	if rearCabin.rightLights.front.partName == partName then
		return rearCabin.rightLights.front
	end
	if rearCabin.rightLights.rear.partName == partName then
		return rearCabin.rightLights.rear
	end
	
	-- Check cargo area light
	if cargoArea.mainLight.partName == partName then
		return cargoArea.mainLight
	end
	
	return nil
end

function SpaceShipConfig.GetAllLightingParts()
	local lightingConfig = SpaceShipConfig.GetLightingConfig()
	local parts = {}
	
	-- Add all lighting parts
	table.insert(parts, lightingConfig.rearCabin.centerLight.partName)
	table.insert(parts, lightingConfig.rearCabin.indicator.partName)
	table.insert(parts, lightingConfig.rearCabin.leftLights.front.partName)
	table.insert(parts, lightingConfig.rearCabin.leftLights.rear.partName)
	table.insert(parts, lightingConfig.rearCabin.rightLights.front.partName)
	table.insert(parts, lightingConfig.rearCabin.rightLights.rear.partName)
	table.insert(parts, lightingConfig.cargoArea.mainLight.partName)
	
	return parts
end

function SpaceShipConfig.GetHighIntensityLights()
	local lightingConfig = SpaceShipConfig.GetLightingConfig()
	local highIntensityParts = {}
	
	-- Add high intensity lights
	table.insert(highIntensityParts, lightingConfig.rearCabin.leftLights.rear.partName)
	table.insert(highIntensityParts, lightingConfig.rearCabin.rightLights.rear.partName)
	table.insert(highIntensityParts, lightingConfig.rearCabin.indicator.partName)
	
	return highIntensityParts
end

function SpaceShipConfig.GetCargoLights()
	local lightingConfig = SpaceShipConfig.GetLightingConfig()
	local cargoParts = {}
	
	-- Add cargo area lights
	table.insert(cargoParts, lightingConfig.cargoArea.mainLight.partName)
	
	return cargoParts
end

-- ============================================================================
-- RAMP STRIPES CONFIGURATION (Visual enhancement system)
-- ============================================================================

function SpaceShipConfig.GetRampStripesConfig()
	return SpaceShipConfig.Structure.ShipParts.RampStripes
end

function SpaceShipConfig.GetAllRampStripes()
	local rampStripesConfig = SpaceShipConfig.GetRampStripesConfig()
	local allStripes = {}

	-- Add all stripes from each step
	for i = 1, 11 do
		local stepKey = "Step" .. i
		if rampStripesConfig.attributes.stepStripes[stepKey] then
			table.insert(allStripes, rampStripesConfig.attributes.stepStripes[stepKey].leftStripe)
			table.insert(allStripes, rampStripesConfig.attributes.stepStripes[stepKey].rightStripe)
		end
	end

	return allStripes
end

function SpaceShipConfig.GetStepStripes(stepNumber)
	local rampStripesConfig = SpaceShipConfig.GetRampStripesConfig()
	local stepKey = "Step" .. stepNumber
	
	if rampStripesConfig.attributes.stepStripes[stepKey] then
		return {
			leftStripe = rampStripesConfig.attributes.stepStripes[stepKey].leftStripe,
			rightStripe = rampStripesConfig.attributes.stepStripes[stepKey].rightStripe,
			stripeWidth = rampStripesConfig.attributes.stepStripes[stepKey].stripeWidth,
			stepWidth = rampStripesConfig.attributes.stepStripes[stepKey].stepWidth,
			position = rampStripesConfig.attributes.stepStripes[stepKey].position
		}
	end
	
	return nil
end

function SpaceShipConfig.GetRampStripeCount()
	local rampStripesConfig = SpaceShipConfig.GetRampStripesConfig()
	return rampStripesConfig.attributes.totalStripes
end

function SpaceShipConfig.IsLightingPart(partName)
	local allParts = SpaceShipConfig.GetAllLightingParts()
	for _, name in ipairs(allParts) do
		if name == partName then
			return true
		end
	end
	return false
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
