-- Config for Planet_1 Orbit
-- Contains information about all folders and objects in this location

local OrbitConfig = {
    -- Basic information
    name = "Planet_1 Orbit",
    type = "OrbitLocation",
    version = "1.0",
    lastUpdated = os.time(),
    
    -- Services and folders structure
    structure = {
        {
            name = "StarterPlayer",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Orbit.StarterPlayer",
            description = "Player starter scripts and configurations",
            children = {
                {
                    name = "StarterCharacterScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Orbit.StarterPlayer.StarterCharacterScript",
                    description = "Character-specific starter scripts"
                },
                {
                    name = "StarterPlayerScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Orbit.StarterPlayer.StarterPlayerScript",
                    description = "Player-specific starter scripts"
                }
            }
        },
        {
            name = "ReplicatedStorage",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Orbit.ReplicatedStorage",
            description = "Shared storage for client-server communication"
        },
        {
            name = "ServerScriptService",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Orbit.ServerScriptService",
            description = "Server-side scripts for this location"
        },
        {
            name = "Workspace",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Orbit.Workspace",
            description = "3D objects and models for this location",
            children = {
                {
                    name = "Lighting",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Orbit.Workspace.Lighting",
                    description = "Lighting effects and atmosphere",
                    children = {
                        {
                            name = "Atmosphere",
                            className = "Atmosphere",
                            path = "ServerStorage.Planets.Planet_1.Orbit.Workspace.Lighting.Atmosphere",
                            description = "Atmospheric effects"
                        },
                        {
                            name = "Bloom",
                            className = "BloomEffect",
                            path = "ServerStorage.Planets.Planet_1.Orbit.Workspace.Lighting.Bloom",
                            description = "Bloom lighting effect"
                        },
                        {
                            name = "DepthOfField",
                            className = "DepthOfFieldEffect",
                            path = "ServerStorage.Planets.Planet_1.Orbit.Workspace.Lighting.DepthOfField",
                            description = "Depth of field effect"
                        },
                        {
                            name = "SunRays",
                            className = "SunRaysEffect",
                            path = "ServerStorage.Planets.Planet_1.Orbit.Workspace.Lighting.SunRays",
                            description = "Sun rays lighting effect"
                        },
                        {
                            name = "Sky",
                            className = "Sky",
                            path = "ServerStorage.Planets.Planet_1.Orbit.Workspace.Lighting.Sky",
                            description = "Sky configuration"
                        }
                    }
                },
                {
                    name = "SpaceShip",
                    className = "Model",
                    path = "ServerStorage.Planets.Planet_1.Orbit.Workspace.SpaceShip",
                    description = "Main spaceship model with all components",
                    components = {
                        {
                            name = "Configuration",
                            className = "Configuration",
                            description = "Ship configuration values",
                            properties = {
                                MaxShield = "IntValue",
                                MaxHull = "IntValue",
                                ExplosionSize = "NumberValue",
                                Description = "StringValue",
                                Class = "StringValue",
                                Mass = "NumberValue"
                            }
                        },
                        {
                            name = "ShipParts",
                            className = "Model",
                            description = "Ship structural components (483 parts: 224 Part, 259 WedgePart)"
                        },
                        {
                            name = "Torpedoes",
                            className = "Model",
                            description = "Torpedo weapon system",
                            components = {
                                WeaponType = "StringValue",
                                BarrelInterval = "NumberValue",
                                ProjectileSize = "Part",
                                Barrels = "2 Part instances"
                            }
                        },
                        {
                            name = "TurretPlates",
                            className = "Part",
                            count = 5,
                            description = "Turret mounting points with configuration"
                        },
                        {
                            name = "PilotSeat",
                            className = "VehicleSeat",
                            description = "Main pilot control seat (22 children)"
                        },
                        {
                            name = "PassengerSeats",
                            className = "Seat",
                            count = 4,
                            description = "Passenger seating"
                        },
                        {
                            name = "DockPoint",
                            className = "Part",
                            description = "Ship docking connection point"
                        },
                        {
                            name = "CenterPoint",
                            className = "Part",
                            description = "Ship center reference point"
                        }
                    }
                },
                {
                    name = "Planet",
                    className = "Model",
                    path = "ServerStorage.Planets.Planet_1.Orbit.Workspace.Planet",
                    description = "Planet model with atmospheric layers",
                    components = {
                        {
                            name = "Atmosphere",
                            className = "Part",
                            description = "Planet atmosphere layer"
                        },
                        {
                            name = "Surface",
                            className = "Part",
                            description = "Planet surface with 6 decals"
                        },
                        {
                            name = "CloudLayer0",
                            className = "Part",
                            description = "First cloud layer with 6 decals"
                        },
                        {
                            name = "CloudLayer1",
                            className = "Part",
                            description = "Second cloud layer with 6 decals"
                        }
                    }
                }
            }
        }
    },
    
    -- Location-specific settings
    settings = {
        gravity = Vector3.new(0, 0, 0),
        atmosphereEnabled = true,
        lightingPreset = "Space",
        maxPlayers = 16,
        respawnTime = 5,
        vehicleEnabled = true,
        combatEnabled = true
    },
    
    -- Asset references
    assets = {
        spaceship = "ServerStorage.Planets.Planet_1.Orbit.Workspace.SpaceShip",
        planet = "ServerStorage.Planets.Planet_1.Orbit.Workspace.Planet",
        lighting = "ServerStorage.Planets.Planet_1.Orbit.Workspace.Lighting"
    }
}

-- Helper functions
function OrbitConfig.getStructure()
    return OrbitConfig.structure
end

function OrbitConfig.getSettings()
    return OrbitConfig.settings
end

function OrbitConfig.getAsset(assetName)
    return OrbitConfig.assets[assetName]
end

function OrbitConfig.findObject(objectName)
    for _, section in ipairs(OrbitConfig.structure) do
        if section.name == objectName then
            return section
        end
        if section.children then
            for _, child in ipairs(section.children) do
                if child.name == objectName then
                    return child
                end
                if child.children then
                    for _, subChild in ipairs(child.children) do
                        if subChild.name == objectName then
                            return subChild
                        end
                    end
                end
            end
        end
    end
    return nil
end

return OrbitConfig