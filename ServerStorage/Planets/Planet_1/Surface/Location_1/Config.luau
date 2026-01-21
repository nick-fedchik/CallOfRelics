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
                    description = "Main ground surface (1024x16x1024) with texture and zone divisions",
                    properties = {
                        texture = "Texture instance attached",
                        size = "1024 x 1 x 1024 studs",
                        material = "Rubber",
                        color = "Dark grey metallic",
                        position = "512, 0, 512",
                        anchored = true,
                        canCollide = true
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
                                    name = "ZoneWall_Left",
                                    className = "Part",
                                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.ZoneWalls.ZoneWall_Left",
                                    description = "Left boundary wall (transparent, ForceField material)",
                                    properties = {
                                        size = "1 x 40 x 1024 studs",
                                        position = "0, 20, 512",
                                        material = "ForceField",
                                        color = "Cyan",
                                        transparency = 0.7,
                                        reflectance = 0.3,
                                        anchored = true,
                                        canCollide = true
                                    }
                                },
                                {
                                    name = "ZoneWall_Right",
                                    className = "Part",
                                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.ZoneWalls.ZoneWall_Right",
                                    description = "Right boundary wall (transparent, ForceField material)",
                                    properties = {
                                        size = "1 x 40 x 1024 studs",
                                        position = "1024, 20, 512",
                                        material = "ForceField",
                                        color = "Cyan",
                                        transparency = 0.7,
                                        reflectance = 0.3,
                                        anchored = true,
                                        canCollide = true
                                    }
                                },
                                {
                                    name = "ZoneWall_Front",
                                    className = "Part",
                                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.ZoneWalls.ZoneWall_Front",
                                    description = "Front boundary wall (transparent, ForceField material)",
                                    properties = {
                                        size = "1026 x 40 x 1 studs",
                                        position = "512, 20, 1024",
                                        material = "ForceField",
                                        color = "Cyan",
                                        transparency = 0.7,
                                        reflectance = 0.3,
                                        anchored = true,
                                        canCollide = true
                                    }
                                },
                                {
                                    name = "ZoneWall_Back",
                                    className = "Part",
                                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.ZoneWalls.ZoneWall_Back",
                                    description = "Back boundary wall (transparent, ForceField material)",
                                    properties = {
                                        size = "1026 x 40 x 1 studs",
                                        position = "512, 20, 0",
                                        material = "ForceField",
                                        color = "Cyan",
                                        transparency = 0.7,
                                        reflectance = 0.3,
                                        anchored = true,
                                        canCollide = true
                                    }
                                }
                            }
                        },
                        {
                            name = "ExplorationZone",
                            className = "Part",
                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.ExplorationZone",
                            description = "Green exploration zone covering 80% of baseplate length (1024x16x819.2)",
                            properties = {
                                size = "1024 x 1 x 1024 studs",
                                position = "512, 1, 512",
                                material = "Grass",
                                color = "Bright green",
                                anchored = true,
                                canCollide = true,
                                coverage = "100% of baseplate area"
                            }
                        },
                        {
                            name = "LandingZone",
                            className = "Part",
                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.LandingZone",
                            description = "Blue landing zone covering 20% of baseplate length near Near wall (1024x16x204.8)",
                            properties = {
                                size = "256 x 1 x 256 studs",
                                position = "128, 1.5, 896",
                                material = "Concrete",
                                color = "Bright blue",
                                anchored = true,
                                canCollide = true,
                                coverage = "Specific landing area"
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
                            description = "Dedicated landing pad for spaceship (60x2x88.8) with visual enhancements and lighting",
                            properties = {
                                size = "88 x 1 x 144 studs",
                                position = "130, 2, 902",
                                material = "Metal",
                                color = "Dark stone grey",
                                purpose = "Spaceship landing area",
                                anchored = true,
                                canCollide = true
                            },
                            children = {
                                {
                                    name = "Light",
                                    className = "PointLight",
                                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.Light",
                                    description = "Main illumination light for landing pad"
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
                                            description = "Left side frame border (cyan, with PointLight)",
                                            properties = {
                                                size = "2 x 2 x 136 studs",
                                                position = "87, 3.5, 902",
                                                material = "Neon",
                                                color = "0.356863, 0.603922, 0.298039",
                                                anchored = true,
                                                canCollide = false
                                            }
                                        },
                                        {
                                            name = "RightFrame",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.RightFrame",
                                            description = "Right side frame border (cyan, with PointLight)",
                                            properties = {
                                                size = "2 x 2 x 136 studs",
                                                material = "Neon",
                                                color = "0.356863, 0.603922, 0.298039",
                                                anchored = true,
                                                canCollide = false
                                            }
                                        },
                                        {
                                            name = "FrontFrame",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.FrontFrame",
                                            description = "Front side frame border (cyan, with PointLight)",
                                            properties = {
                                                size = "80 x 2 x 2 studs",
                                                material = "Neon",
                                                color = "0.356863, 0.603922, 0.298039",
                                                anchored = true,
                                                canCollide = false
                                            }
                                        },
                                        {
                                            name = "BackFrame",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.BackFrame",
                                            description = "Back side frame border (cyan, with PointLight)",
                                            properties = {
                                                size = "80 x 2 x 2 studs",
                                                material = "Neon",
                                                color = "0.356863, 0.603922, 0.298039",
                                                anchored = true,
                                                canCollide = false
                                            }
                                        },
                                        {
                                            name = "FrontLeftCorner",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.FrontLeftCorner",
                                            description = "Front-left corner marker (bright yellow, with PointLight)",
                                            properties = {
                                                size = "4 x 4 x 4 studs",
                                                material = "Neon",
                                                color = "0.960784, 0.803922, 0.188235",
                                                anchored = true,
                                                canCollide = false
                                            }
                                        },
                                        {
                                            name = "FrontRightCorner",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.FrontRightCorner",
                                            description = "Front-right corner marker (bright yellow, with PointLight)",
                                            properties = {
                                                size = "4 x 4 x 4 studs",
                                                material = "Neon",
                                                color = "0.960784, 0.803922, 0.188235",
                                                anchored = true,
                                                canCollide = false
                                            }
                                        },
                                        {
                                            name = "BackLeftCorner",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.BackLeftCorner",
                                            description = "Back-left corner marker (bright yellow, with PointLight)",
                                            properties = {
                                                size = "4 x 4 x 4 studs",
                                                material = "Neon",
                                                color = "0.960784, 0.803922, 0.188235",
                                                anchored = true,
                                                canCollide = false
                                            }
                                        },
                                        {
                                            name = "BackRightCorner",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.BackRightCorner",
                                            description = "Back-right corner marker (bright yellow, with PointLight)",
                                            properties = {
                                                size = "3 x 3 x 3 studs",
                                                material = "Neon",
                                                color = "Bright yellow",
                                                anchored = true,
                                                canCollide = false
                                            }
                                        },
                                        {
                                            name = "Stripe1",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.Stripe1",
                                            description = "First decorative stripe (white, across the pad)",
                                            properties = {
                                                material = "Neon",
                                                color = "White",
                                                anchored = true,
                                                canCollide = false
                                            }
                                        },
                                        {
                                            name = "Stripe2",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.Stripe2",
                                            description = "Second decorative stripe (white, across the pad)",
                                            properties = {
                                                material = "Neon",
                                                color = "White",
                                                anchored = true,
                                                canCollide = false
                                            }
                                        },
                                        {
                                            name = "Stripe3",
                                            className = "Part",
                                            path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate.SpaceShipLandingPad.LandingPadFrame.Stripe3",
                                            description = "Third decorative stripe (white, across the pad)",
                                            properties = {
                                                material = "Neon",
                                                color = "White",
                                                anchored = true,
                                                canCollide = false
                                            }
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
    
    -- Scanner visibility (0-100%)
    -- 100% = always visible when scanning
    -- Lower values = harder to discover
    visibility = 100,

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
        size = Vector3.new(1024, 1, 1024),
        zoneConfiguration = {
            landingZone = {
                coverage = "Specific landing area",
                position = "128, 1.5, 896",
                purpose = "Spaceship landing and operations"
            },
            explorationZone = {
                coverage = "100% of baseplate area",
                position = "512, 1, 512",
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
            landingPadSize = "88 x 144 studs",
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