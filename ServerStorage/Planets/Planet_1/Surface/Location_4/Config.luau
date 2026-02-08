-- Config for Planet_1 Surface Location4
-- Contains information about all folders and objects in this location

local Location4Config = {
    -- Basic information
    name = "Planet_1 Surface Location4",
    displayName = "Кузня",
    type = "SurfaceLocation",
    version = "1.0",
    lastUpdated = os.time(),

    -- Services and folders structure
    structure = {
        {
            name = "StarterPlayer",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location4.StarterPlayer",
            description = "Player starter scripts and configurations for this location",
            children = {
                {
                    name = "StarterCharacterScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location4.StarterPlayer.StarterCharacterScript",
                    description = "Character-specific starter scripts for this location"
                },
                {
                    name = "StarterPlayerScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location4.StarterPlayer.StarterPlayerScript",
                    description = "Player-specific starter scripts for this location"
                }
            }
        },
        {
            name = "ReplicatedStorage",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location4.ReplicatedStorage",
            description = "Shared storage for client-server communication in this location"
        },
        {
            name = "ServerScriptService",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location4.ServerScriptService",
            description = "Server-side scripts specific to this surface location"
        },
        {
            name = "Workspace",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location4.Workspace",
            description = "3D objects and models for this surface location",
            children = {
                {
                    name = "Lighting",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location4.Workspace.Lighting",
                    description = "Lighting configuration for this location",
                    children = {
                        {
                            name = "Sky",
                            className = "Sky",
                            path = "ServerStorage.Planets.Planet_1.Surface.Location4.Workspace.Lighting.Sky",
                            description = "Sky configuration for surface location"
                        }
                    }
                },
                {
                    name = "SpawnLocation",
                    className = "SpawnLocation",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location4.Workspace.SpawnLocation",
                    description = "Player spawn point"
                },
                {
                    name = "Baseplate",
                    className = "Part",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location4.Workspace.Baseplate",
                    description = "Ground surface"
                }
            }
        }
    },

    -- Scanner visibility (0-100%)
    visibility = 40,

    -- Location-specific settings
    settings = {
        gravity = Vector3.new(0, -196.2, 0),
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
        spawnLocation = "ServerStorage.Planets.Planet_1.Surface.Location4.Workspace.SpawnLocation",
        baseplate = "ServerStorage.Planets.Planet_1.Surface.Location4.Workspace.Baseplate",
        lighting = "ServerStorage.Planets.Planet_1.Surface.Location4.Workspace.Lighting"
    },

    -- Location metadata
    metadata = {
        locationId = "planet1_surface_location4",
        description = "Industrial forge complex — gathering / crafting arcade",
        biome = "Industrial",
        size = Vector3.new(512, 1, 512),
        arcadeType = "Gathering / Crafting"
    }
}

-- Helper functions
function Location4Config.getStructure()
    return Location4Config.structure
end

function Location4Config.getSettings()
    return Location4Config.settings
end

function Location4Config.getAsset(assetName)
    return Location4Config.assets[assetName]
end

function Location4Config.getMetadata()
    return Location4Config.metadata
end

return Location4Config
