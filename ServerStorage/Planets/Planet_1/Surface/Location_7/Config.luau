-- Config for Planet_1 Surface Location7
-- Contains information about all folders and objects in this location

local Location7Config = {
    -- Basic information
    name = "Planet_1 Surface Location7",
    displayName = "Колиска",
    type = "SurfaceLocation",
    version = "1.0",
    lastUpdated = os.time(),

    -- Services and folders structure
    structure = {
        {
            name = "StarterPlayer",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location7.StarterPlayer",
            description = "Player starter scripts and configurations for this location",
            children = {
                {
                    name = "StarterCharacterScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location7.StarterPlayer.StarterCharacterScript",
                    description = "Character-specific starter scripts for this location"
                },
                {
                    name = "StarterPlayerScript",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location7.StarterPlayer.StarterPlayerScript",
                    description = "Player-specific starter scripts for this location"
                }
            }
        },
        {
            name = "ReplicatedStorage",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location7.ReplicatedStorage",
            description = "Shared storage for client-server communication in this location"
        },
        {
            name = "ServerScriptService",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location7.ServerScriptService",
            description = "Server-side scripts specific to this surface location"
        },
        {
            name = "Workspace",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface.Location7.Workspace",
            description = "3D objects and models for this surface location",
            children = {
                {
                    name = "Lighting",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location7.Workspace.Lighting",
                    description = "Lighting configuration for this location",
                    children = {
                        {
                            name = "Sky",
                            className = "Sky",
                            path = "ServerStorage.Planets.Planet_1.Surface.Location7.Workspace.Lighting.Sky",
                            description = "Sky configuration for surface location"
                        }
                    }
                },
                {
                    name = "SpawnLocation",
                    className = "SpawnLocation",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location7.Workspace.SpawnLocation",
                    description = "Player spawn point"
                },
                {
                    name = "Baseplate",
                    className = "Part",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location7.Workspace.Baseplate",
                    description = "Ground surface"
                }
            }
        }
    },

    -- Scanner visibility (0-100%)
    visibility = 25,

    -- Location-specific settings
    settings = {
        gravity = Vector3.new(0, -196.2, 0),
        atmosphereEnabled = true,
        lightingPreset = "Surface",
        maxPlayers = 16,
        respawnTime = 5,
        vehicleEnabled = false,
        combatEnabled = true,
        environmentType = "Surface"
    },

    -- Asset references
    assets = {
        spawnLocation = "ServerStorage.Planets.Planet_1.Surface.Location7.Workspace.SpawnLocation",
        baseplate = "ServerStorage.Planets.Planet_1.Surface.Location7.Workspace.Baseplate",
        lighting = "ServerStorage.Planets.Planet_1.Surface.Location7.Workspace.Lighting"
    },

    -- Location metadata
    metadata = {
        locationId = "planet1_surface_location7",
        description = "Biological research dome by lake — survival / defense arcade",
        biome = "Lakeside / Greenhouse",
        size = Vector3.new(512, 1, 512),
        arcadeType = "Survival / Defense"
    }
}

-- Helper functions
function Location7Config.getStructure()
    return Location7Config.structure
end

function Location7Config.getSettings()
    return Location7Config.settings
end

function Location7Config.getAsset(assetName)
    return Location7Config.assets[assetName]
end

function Location7Config.getMetadata()
    return Location7Config.metadata
end

return Location7Config
