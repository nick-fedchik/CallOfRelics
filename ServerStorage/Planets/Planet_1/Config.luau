-- Main Config for Planet_1
-- Contains information about all locations and their configurations

local Planet1Config = {
    -- Basic information
    name = "Planet_1",
    displayName = "Біллі Рубін",
    type = "Planet",
    version = "1.0",
    lastUpdated = os.time(),
    
    -- Planet structure
    structure = {
        {
            name = "Orbit",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Orbit",
            description = "Orbital space around the planet",
            configPath = "ServerStorage.Planets.Planet_1.Orbit.Config",
            type = "OrbitLocation",
            features = {
                spaceCombat = true,
                vehicles = true,
                zeroGravity = true,
                maxPlayers = 16
            }
        },
        {
            name = "Surface",
            className = "Folder",
            path = "ServerStorage.Planets.Planet_1.Surface",
            description = "Surface locations on the planet",
            type = "SurfaceContainer",
            children = {
                {
                    name = "Location1",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location1",
                    description = "First surface location",
                    configPath = "ServerStorage.Planets.Planet_1.Surface.Location1.Config",
                    type = "SurfaceLocation",
                    features = {
                        gravity = true,
                        atmosphere = true,
                        maxPlayers = 16
                    }
                },
                {
                    name = "Location2",
                    className = "Folder",
                    path = "ServerStorage.Planets.Planet_1.Surface.Location2",
                    description = "Second surface location",
                    configPath = "ServerStorage.Planets.Planet_1.Surface.Location2.Config",
                    type = "SurfaceLocation",
                    features = {
                        gravity = true,
                        atmosphere = true,
                        maxPlayers = 16
                    }
                }
            }
        }
    },
    
    -- Planet-wide settings
    settings = {
        maxPlayers = 16,
        respawnTime = 5,
        enablePvP = true,
        enableVehicles = true,
        environmentType = "Planet",
        atmosphereEnabled = true
    },
    
    -- Asset references
    assets = {
        orbitConfig = "ServerStorage.Planets.Planet_1.Orbit.Config",
        surfaceLocation1Config = "ServerStorage.Planets.Planet_1.Surface.Location1.Config",
        surfaceLocation2Config = "ServerStorage.Planets.Planet_1.Surface.Location2.Config"
    },
    
    -- Planet metadata
    metadata = {
        planetId = "planet_001",
        description = "Main planet with orbital and surface locations",
        biome = "Mixed",
        size = Vector3.new(2048, 2048, 2048),
        locations = {
            {
                name = "Orbit",
                type = "OrbitLocation",
                path = "ServerStorage.Planets.Planet_1.Orbit"
            },
            {
                name = "Location1",
                type = "SurfaceLocation",
                path = "ServerStorage.Planets.Planet_1.Surface.Location1"
            },
            {
                name = "Location2",
                type = "SurfaceLocation",
                path = "ServerStorage.Planets.Planet_1.Surface.Location2"
            }
        }
    }
}

-- Helper functions
function Planet1Config.getStructure()
    return Planet1Config.structure
end

function Planet1Config.getSettings()
    return Planet1Config.settings
end

function Planet1Config.getAsset(assetName)
    return Planet1Config.assets[assetName]
end

function Planet1Config.getLocation(locationName)
    for _, section in ipairs(Planet1Config.structure) do
        if section.name == locationName then
            return section
        end
        if section.children then
            for _, child in ipairs(section.children) do
                if child.name == locationName then
                    return child
                end
            end
        end
    end
    return nil
end

function Planet1Config.getAllLocations()
    local locations = {}
    for _, section in ipairs(Planet1Config.structure) do
        table.insert(locations, section)
        if section.children then
            for _, child in ipairs(section.children) do
                table.insert(locations, child)
            end
        end
    end
    return locations
end

function Planet1Config.getMetadata()
    return Planet1Config.metadata
end

function Planet1Config.loadLocationConfig(locationName)
    local location = Planet1Config.getLocation(locationName)
    if location and location.configPath then
        local success, config = pcall(require, location.configPath)
        if success then
            return config
        end
    end
    return nil
end

return Planet1Config