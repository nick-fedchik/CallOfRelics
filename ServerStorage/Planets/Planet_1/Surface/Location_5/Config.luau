-- Config for Planet_1 Surface Location5
-- Contains information about all folders and objects in this location

local Location5Config = {
    -- Basic information
    name = "Planet_1 Surface Location5",
    displayName = "Лабіринт",
    type = "SurfaceLocation",
    version = "1.0",
    lastUpdated = os.time(),

    -- Services and folders structure
    structure = {
        {
            name = "StarterPlayer",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location5.StarterPlayer",
            description = "Player starter scripts and configurations for this location",
            children = {
                {
                    name = "StarterCharacterScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location5.StarterPlayer.StarterCharacterScript",
                    description = "Character-specific starter scripts for this location"
                },
                {
                    name = "StarterPlayerScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location5.StarterPlayer.StarterPlayerScript",
                    description = "Player-specific starter scripts for this location"
                }
            }
        },
        {
            name = "ReplicatedStorage",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location5.ReplicatedStorage",
            description = "Shared storage for client-server communication in this location"
        },
        {
            name = "ServerScriptService",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location5.ServerScriptService",
            description = "Server-side scripts specific to this surface location"
        },
        {
            name = "Workspace",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location5.Workspace",
            description = "3D objects and models for this surface location",
            children = {
                {
                    name = "Lighting",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location5.Workspace.Lighting",
                    description = "Lighting configuration for this location",
                    children = {
                        {
                            name = "Sky",
                            className = "Sky",
                            path = "ServerStorage.Planets.Planet_1.Surface.Location5.Workspace.Lighting.Sky",
                            description = "Sky configuration for surface location"
                        }
                    }
                },
                {
                    name = "SpawnLocation",
                    className = "SpawnLocation",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location5.Workspace.SpawnLocation",
                    description = "Player spawn point"
                },
                {
                    name = "Baseplate",
                    className = "Part",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location5.Workspace.Baseplate",
                    description = "Ground surface"
                }
            }
        }
    },

    -- Scanner visibility (0-100%)
    visibility = 30,

    -- Location-specific settings
    settings = {
        gravity = Vector3.new(0, -196.2, 0),
        atmosphereEnabled = true,
        lightingPreset = "Underground",
        maxPlayers = 16,
        respawnTime = 5,
        vehicleEnabled = false,
        combatEnabled = false,
        environmentType = "Underground"
    },

    -- Asset references
    assets = {
        spawnLocation = "ServerStorage.Planets.Planet_1.Surface.Location5.Workspace.SpawnLocation",
        baseplate = "ServerStorage.Planets.Planet_1.Surface.Location5.Workspace.Baseplate",
        lighting = "ServerStorage.Planets.Planet_1.Surface.Location5.Workspace.Lighting"
    },

    -- Location metadata
    metadata = {
        locationId = "planet1_surface_location5",
        description = "Underground tunnel labyrinth — maze / stealth arcade",
        biome = "Underground",
        size = Vector3.new(512, 1, 512),
        arcadeType = "Maze / Stealth"
    }
}

-- Helper functions
function Location5Config.getStructure()
    return Location5Config.structure
end

function Location5Config.getSettings()
    return Location5Config.settings
end

function Location5Config.getAsset(assetName)
    return Location5Config.assets[assetName]
end

function Location5Config.getMetadata()
    return Location5Config.metadata
end

return Location5Config
