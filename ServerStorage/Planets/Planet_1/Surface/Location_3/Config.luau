-- Config for Planet_1 Surface Location3
-- Contains information about all folders and objects in this location

local Location3Config = {
    -- Basic information
    name = "Planet_1 Surface Location3",
    displayName = "Маяк",
    type = "SurfaceLocation",
    version = "1.0",
    lastUpdated = os.time(),

    -- Services and folders structure
    structure = {
        {
            name = "StarterPlayer",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location3.StarterPlayer",
            description = "Player starter scripts and configurations for this location",
            children = {
                {
                    name = "StarterCharacterScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location3.StarterPlayer.StarterCharacterScript",
                    description = "Character-specific starter scripts for this location"
                },
                {
                    name = "StarterPlayerScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location3.StarterPlayer.StarterPlayerScript",
                    description = "Player-specific starter scripts for this location"
                }
            }
        },
        {
            name = "ReplicatedStorage",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location3.ReplicatedStorage",
            description = "Shared storage for client-server communication in this location"
        },
        {
            name = "ServerScriptService",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location3.ServerScriptService",
            description = "Server-side scripts specific to this surface location"
        },
        {
            name = "Workspace",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location3.Workspace",
            description = "3D objects and models for this surface location",
            children = {
                {
                    name = "Lighting",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location3.Workspace.Lighting",
                    description = "Lighting configuration for this location",
                    children = {
                        {
                            name = "Sky",
                            className = "Sky",
                            path = "ServerStorage.Planets.Planet_1.Surface.Location3.Workspace.Lighting.Sky",
                            description = "Sky configuration for surface location"
                        }
                    }
                },
                {
                    name = "SpawnLocation",
                    className = "SpawnLocation",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location3.Workspace.SpawnLocation",
                    description = "Player spawn point"
                },
                {
                    name = "Baseplate",
                    className = "Part",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location3.Workspace.Baseplate",
                    description = "Ground surface"
                }
            }
        }
    },

    -- Scanner visibility (0-100%)
    visibility = 50,

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
        spawnLocation = "ServerStorage.Planets.Planet_1.Surface.Location3.Workspace.SpawnLocation",
        baseplate = "ServerStorage.Planets.Planet_1.Surface.Location3.Workspace.Baseplate",
        lighting = "ServerStorage.Planets.Planet_1.Surface.Location3.Workspace.Lighting"
    },

    -- Location metadata
    metadata = {
        locationId = "planet1_surface_location3",
        description = "Lighthouse tower — platforming / climbing arcade",
        biome = "Rocky Coast",
        size = Vector3.new(512, 1, 512),
        arcadeType = "Platforming / Climbing"
    }
}

-- Helper functions
function Location3Config.getStructure()
    return Location3Config.structure
end

function Location3Config.getSettings()
    return Location3Config.settings
end

function Location3Config.getAsset(assetName)
    return Location3Config.assets[assetName]
end

function Location3Config.getMetadata()
    return Location3Config.metadata
end

return Location3Config
