-- Config for Planet_1 Surface Location6
-- Contains information about all folders and objects in this location

local Location6Config = {
    -- Basic information
    name = "Planet_1 Surface Location6",
    displayName = "Обсерваторія",
    type = "SurfaceLocation",
    version = "1.0",
    lastUpdated = os.time(),

    -- Services and folders structure
    structure = {
        {
            name = "StarterPlayer",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location6.StarterPlayer",
            description = "Player starter scripts and configurations for this location",
            children = {
                {
                    name = "StarterCharacterScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location6.StarterPlayer.StarterCharacterScript",
                    description = "Character-specific starter scripts for this location"
                },
                {
                    name = "StarterPlayerScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location6.StarterPlayer.StarterPlayerScript",
                    description = "Player-specific starter scripts for this location"
                }
            }
        },
        {
            name = "ReplicatedStorage",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location6.ReplicatedStorage",
            description = "Shared storage for client-server communication in this location"
        },
        {
            name = "ServerScriptService",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location6.ServerScriptService",
            description = "Server-side scripts specific to this surface location"
        },
        {
            name = "Workspace",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location6.Workspace",
            description = "3D objects and models for this surface location",
            children = {
                {
                    name = "Lighting",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location6.Workspace.Lighting",
                    description = "Lighting configuration for this location",
                    children = {
                        {
                            name = "Sky",
                            className = "Sky",
                            path = "ServerStorage.Planets.Planet_1.Surface.Location6.Workspace.Lighting.Sky",
                            description = "Sky configuration for surface location"
                        }
                    }
                },
                {
                    name = "SpawnLocation",
                    className = "SpawnLocation",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location6.Workspace.SpawnLocation",
                    description = "Player spawn point"
                },
                {
                    name = "Baseplate",
                    className = "Part",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location6.Workspace.Baseplate",
                    description = "Ground surface"
                }
            }
        }
    },

    -- Scanner visibility (0-100%)
    visibility = 35,

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
        spawnLocation = "ServerStorage.Planets.Planet_1.Surface.Location6.Workspace.SpawnLocation",
        baseplate = "ServerStorage.Planets.Planet_1.Surface.Location6.Workspace.Baseplate",
        lighting = "ServerStorage.Planets.Planet_1.Surface.Location6.Workspace.Lighting"
    },

    -- Location metadata
    metadata = {
        locationId = "planet1_surface_location6",
        description = "Hilltop observatory — puzzle / hacking arcade",
        biome = "Highland",
        size = Vector3.new(512, 1, 512),
        arcadeType = "Puzzle / Hacking"
    }
}

-- Helper functions
function Location6Config.getStructure()
    return Location6Config.structure
end

function Location6Config.getSettings()
    return Location6Config.settings
end

function Location6Config.getAsset(assetName)
    return Location6Config.assets[assetName]
end

function Location6Config.getMetadata()
    return Location6Config.metadata
end

return Location6Config
