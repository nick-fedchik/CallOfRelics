-- Config for Planet_1 Surface Location1
-- Contains information about all folders and objects in this location

local Location1Config = {
    -- Basic information
    name = "Planet_1 Surface Location1",
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
                    name = "SpawnLocation",
                    className = "SpawnLocation",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.SpawnLocation",
                    description = "Player spawn point with decal",
                    properties = {
                        decal = "Decal instance attached"
                    }
                },
                {
                    name = "Baseplate",
                    className = "Part",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate",
                    description = "Ground surface with texture",
                    properties = {
                        texture = "Texture instance attached"
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
        spawnLocation = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.SpawnLocation",
        baseplate = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Baseplate",
        lighting = "ServerStorage.Planets.Planet_1.Surface.Location1.Workspace.Lighting"
    },
    
    -- Location metadata
    metadata = {
        locationId = "planet1_surface_location1",
        description = "First surface location on Planet 1",
        biome = "Default",
        size = Vector3.new(512, 1, 512),
        spawnPoints = {
            {
                name = "MainSpawn",
                position = Vector3.new(0, 5, 0),
                team = "Neutral"
            }
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