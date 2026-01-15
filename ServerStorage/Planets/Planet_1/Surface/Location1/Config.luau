-- Config for Planet_1 Surface Location1
-- Contains information about all folders and objects in this location

local Location1Config = {
    -- Basic information
    name = "Planet_1 Surface Location1",
    displayName = "Візитка",
    type = "SurfaceLocation",
    version = "1.0",
    lastUpdated = os.time(),
    
    -- Services and folders structure
    structure = {
        {
            name = "Workspace",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace",
            description = "3D objects and models for this surface location",
            children = {
                {
                    name = "Lighting",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Lighting",
                    description = "Lighting configuration for this location",
                    children = {
                        {
                            name = "Sky",
                            className = "Sky",
                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Lighting.Sky",
                            description = "Sky configuration for surface location"
                        }
                    }
                },
                {
                    name = "Baseplate",
                    className = "Part",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate",
                    description = "Main ground surface (2048x16x2048) with texture and zone divisions",
                    properties = {
                        texture = "Texture instance attached",
                        size = "2048 x 16 x 2048 studs",
                        material = "Grass"
                    },
                    children = {
                        {
                            name = "Texture",
                            className = "Texture",
                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.Texture",
                            description = "Surface texture for baseplate"
                        },
                        {
                            name = "ZoneWalls",
                            className = "Folder",
                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.ZoneWalls",
                            description = "Transparent walls with labels marking zone boundaries",
                            children = {
                                {
                                    name = "LeftWall",
                                    className = "Part",
                                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.ZoneWalls.LeftWall",
                                    description = "Left boundary wall with SurfaceGui label"
                                },
                                {
                                    name = "RightWall",
                                    className = "Part",
                                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.ZoneWalls.RightWall",
                                    description = "Right boundary wall with SurfaceGui label"
                                },
                                {
                                    name = "NearWall",
                                    className = "Part",
                                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.ZoneWalls.NearWall",
                                    description = "Near boundary wall with SurfaceGui label (adjacent to Landing Zone)"
                                },
                                {
                                    name = "FarWall",
                                    className = "Part",
                                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.ZoneWalls.FarWall",
                                    description = "Far boundary wall with SurfaceGui label"
                                }
                            }
                        },
                        {
                            name = "ExplorationZone",
                            className = "Part",
                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.ExplorationZone",
                            description = "Green exploration zone covering 80% of baseplate length (2048x16x1638.4)",
                            properties = {
                                size = "2048 x 16 x 1638.4 studs",
                                material = "Grass",
                                color = "Bright green",
                                coverage = "80% of baseplate length"
                            }
                        },
                        {
                            name = "LandingZone",
                            className = "Part",
                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.LandingZone",
                            description = "Blue landing zone covering 20% of baseplate length near Near wall (2048x16x409.6)",
                            properties = {
                                size = "2048 x 16 x 409.6 studs",
                                material = "Concrete",
                                color = "Bright blue",
                                coverage = "20% of baseplate length",
                                position = "Adjacent to Near wall (Z: -1024 to -614.4)"
                            },
                            children = {
                                {
                                    name = "Texture",
                                    className = "Texture",
                                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.LandingZone.Texture",
                                    description = "Surface texture for landing zone"
                                }
                            }
                        },
                        {
                            name = "SpaceShipLandingPad",
                            className = "Part",
                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad",
                            description = "Dedicated landing pad for spaceship (120x2x177.6) with visual enhancements and lighting",
                            properties = {
                                size = "120 x 2 x 177.6 studs",
                                material = "Metal",
                                color = "Dark stone grey",
                                purpose = "Spaceship landing area",
                                sizeRatio = "20% larger than spaceship dimensions"
                            },
                            children = {
                                {
                                    name = "LandingLights",
                                    className = "Folder",
                                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingLights",
                                    description = "Four corner signal lights with blinking animation",
                                    children = {
                                        {
                                            name = "FrontLeftLight",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingLights.FrontLeftLight",
                                            description = "Front-left corner signal light (orange, blinking)"
                                        },
                                        {
                                            name = "FrontRightLight",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingLights.FrontRightLight",
                                            description = "Front-right corner signal light (orange, blinking)"
                                        },
                                        {
                                            name = "BackLeftLight",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingLights.BackLeftLight",
                                            description = "Back-left corner signal light (orange, blinking)"
                                        },
                                        {
                                            name = "BackRightLight",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingLights.BackRightLight",
                                            description = "Back-right corner signal light (orange, blinking)"
                                        }
                                    }
                                },
                                {
                                    name = "LandingPadFrame",
                                    className = "Folder",
                                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame",
                                    description = "Visual frame and decorative elements with animated lighting",
                                    children = {
                                        {
                                            name = "LeftFrame",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.LeftFrame",
                                            description = "Left side frame border (cyan, with PointLight)"
                                        },
                                        {
                                            name = "RightFrame",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.RightFrame",
                                            description = "Right side frame border (cyan, with PointLight)"
                                        },
                                        {
                                            name = "FrontFrame",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.FrontFrame",
                                            description = "Front side frame border (cyan, with PointLight)"
                                        },
                                        {
                                            name = "BackFrame",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.BackFrame",
                                            description = "Back side frame border (cyan, with PointLight)"
                                        },
                                        {
                                            name = "FrontLeftCorner",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.FrontLeftCorner",
                                            description = "Front-left corner marker (bright yellow, with PointLight)"
                                        },
                                        {
                                            name = "FrontRightCorner",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.FrontRightCorner",
                                            description = "Front-right corner marker (bright yellow, with PointLight)"
                                        },
                                        {
                                            name = "BackLeftCorner",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.BackLeftCorner",
                                            description = "Back-left corner marker (bright yellow, with PointLight)"
                                        },
                                        {
                                            name = "BackRightCorner",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.BackRightCorner",
                                            description = "Back-right corner marker (bright yellow, with PointLight)"
                                        },
                                        {
                                            name = "Stripe1",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.Stripe1",
                                            description = "First decorative stripe (white, across the pad)"
                                        },
                                        {
                                            name = "Stripe2",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.Stripe2",
                                            description = "Second decorative stripe (white, across the pad)"
                                        },
                                        {
                                            name = "Stripe3",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.Stripe3",
                                            description = "Third decorative stripe (white, across the pad)"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        {
            name = "ServerScriptService",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location1.ServerScriptService",
            description = "Server-side scripts specific to this surface location"
        },
        {
            name = "ReplicatedStorage",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location1.ReplicatedStorage",
            description = "Shared storage for client-server communication in this location"
        },
        {
            name = "StarterPlayer",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location1.StarterPlayer",
            description = "Player starter scripts and configurations for this location",
            children = {
                {
                    name = "StarterCharacterScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.StarterPlayer.StarterCharacterScript",
                    description = "Character-specific starter scripts for this location"
                },
                {
                    name = "StarterPlayerScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.StarterPlayer.StarterPlayerScript",
                    description = "Player-specific starter scripts for this location"
                }
            }
        }
    },
    
    -- Location-specific settings
    settings = {
        gravity = Vector3.new(0, -196.2, 0), -- Standard Roblox gravity
        atmosphereEnabled = true,
        lightingPreset = "Surface",
        maxPlayers = 16,
        respawnTime = 5,
        vehicleEnabled = false,
        combatEnabled = false,
        environmentType = "Surface"
    },
    
    -- Asset references
    assets = {
        baseplate = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate",
        lighting = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Lighting",
        explorationZone = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.ExplorationZone",
        landingZone = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.LandingZone",
        spaceshipLandingPad = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad",
        zoneWalls = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.ZoneWalls"
    },
    
    -- Location metadata
    metadata = {
        locationId = "planet1_surface_location1",
        description = "Primary surface location on Planet 1 with divided zones for exploration and spaceship landing",
        biome = "Grassland",
        size = Vector3.new(2048, 16, 2048),
        zoneConfiguration = {
            landingZone = {
                coverage = "20% of total length",
                position = "Near wall (Z: -1024 to -614.4)",
                purpose = "Spaceship landing and operations"
            },
            explorationZone = {
                coverage = "80% of total length",
                position = "Central area (Z: -614.4 to 1024)",
                purpose = "Player exploration and activities"
            }
        },
        features = {
            "Zone boundary walls with labels",
            "Dedicated spaceship landing pad with visual enhancements",
            "Animated signal lights and frame lighting",
            "Distinct zone materials and colors"
        },
        spaceshipCompatibility = {
            supported = true,
            landingPadSize = "120 x 177.6 studs",
            clearance = "20% larger than spaceship dimensions",
            visualGuidance = "Blinking lights and illuminated frame"
        }
    }
}

-- Helper functions
function Location1Config.getStructure()
    return Location1Config.structure
end

function Location1Config.getSettings()
    return Location1Config.settings
end

function Location1Config.getAsset(assetName)
    return Location1Config.assets[assetName]
end

function Location1Config.findObject(objectName)
    for _, section in ipairs(Location1Config.structure) do
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

function Location1Config.getMetadata()
    return Location1Config.metadata
end

return Location1Config