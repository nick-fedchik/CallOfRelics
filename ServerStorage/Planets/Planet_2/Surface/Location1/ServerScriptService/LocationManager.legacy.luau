-- Скрипт для управління локацією Location1
-- Завантажує та ініціалізує всі модулі локації

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Отримання конфігурації локації
local LocationConfig = require(ServerStorage.Planets.Planet_1.Surface.Location1.Config)

-- Отримання модулів
local LandingLightsModule = require(script.Parent.LandingLightsModule)
local LandingPadEffectsModule = require(script.Parent.LandingPadEffectsModule)

-- Приватні змінні
local isInitialized = false
local modules = {}

-- Функція для отримання шляху до об'єкта з конфігурації
local function getObjectPath(assetName)
    local path = LocationConfig.getAsset(assetName)
    if not path then
        warn("LocationManager: Asset '" .. assetName .. "' not found in config")
        return nil
    end
    
    -- Конвертація шляху з ServerStorage в Workspace
    local workspacePath = path:gsub("ServerStorage%.Planets%.Planet_1%.Surface%.Location_1%.Workspace%.", "")
    return workspacePath
end

-- Ініціалізація модулів
local function initializeModules()
    print("LocationManager: Initializing modules for Location1")
    
    -- Ініціалізація модуля вогнів приземлення
    local landingPadPath = getObjectPath("spaceshipLandingPad")
    if landingPadPath then
        local success = LandingLightsModule.initialize(landingPadPath, {
            blinkInterval = 1.0,
            onTransparency = 0,
            offTransparency = 0.7,
            offColor = BrickColor.new("Dark stone grey")
        })
        
        if success then
            table.insert(modules, {
                name = "LandingLights",
                module = LandingLightsModule,
                started = false
            })
            print("LocationManager: LandingLights module initialized")
        else
            warn("LocationManager: Failed to initialize LandingLights module")
        end
    end
    
    -- Ініціалізація модуля ефектів майданчика
    if landingPadPath then
        local success = LandingPadEffectsModule.initialize(landingPadPath, {
            pulseInterval = 2.0,
            minBrightness = 0.5,
            maxBrightness = 2.0,
            brightnessStep = 0.05,
            updateInterval = 0.1
        })
        
        if success then
            table.insert(modules, {
                name = "LandingPadEffects",
                module = LandingPadEffectsModule,
                started = false
            })
            print("LocationManager: LandingPadEffects module initialized")
        else
            warn("LocationManager: Failed to initialize LandingPadEffects module")
        end
    end
    
    isInitialized = true
    print("LocationManager: All modules initialized. Total modules: " .. #modules)
end

-- Запуск всіх модулів
local function startModules()
    if not isInitialized then
        warn("LocationManager: Modules not initialized. Call initializeModules() first.")
        return
    end
    
    print("LocationManager: Starting all modules")
    
    for _, moduleData in ipairs(modules) do
        local success = moduleData.module.start()
        if success then
            moduleData.started = true
            print("LocationManager: " .. moduleData.name .. " started successfully")
        else
            warn("LocationManager: Failed to start " .. moduleData.name)
        end
    end
end

-- Зупинка всіх модулів
local function stopModules()
    print("LocationManager: Stopping all modules")
    
    for _, moduleData in ipairs(modules) do
        if moduleData.started then
            moduleData.module.stop()
            moduleData.started = false
            print("LocationManager: " .. moduleData.name .. " stopped")
        end
    end
end

-- Отримання статусу модулів
local function getModulesStatus()
    local status = {}
    for _, moduleData in ipairs(modules) do
        status[moduleData.name] = {
            initialized = true,
            running = moduleData.module.isRunning()
        }
    end
    return status
end

-- Головна функція ініціалізації локації
local function initializeLocation()
    print("LocationManager: Initializing Location1")
    
    -- Ініціалізація модулів
    initializeModules()
    
    -- Запуск модулів
    startModules()
    
    -- Виведення статусу
    local status = getModulesStatus()
    print("LocationManager: Location1 initialization complete")
    for moduleName, moduleStatus in pairs(status) do
        print("  - " .. moduleName .. ": " .. (moduleStatus.running and "Running" or "Stopped"))
    end
end

-- Очищення при видалені скрипту
local function cleanup()
    stopModules()
    print("LocationManager: Cleanup complete")
end

-- Ініціалізація локації (затримка для завантаження об'єктів)
task.spawn(function()
    task.wait(1) -- Затримка для завантаження об'єктів у Workspace
    initializeLocation()
end)

-- Підключення до події видалення скрипту
script.Destroying:Connect(cleanup)

-- Експорт функцій для зовнішнього використання
return {
    initializeLocation = initializeLocation,
    startModules = startModules,
    stopModules = stopModules,
    getModulesStatus = getModulesStatus,
    getModule = function(moduleName)
        for _, moduleData in ipairs(modules) do
            if moduleData.name == moduleName then
                return moduleData.module
            end
        end
        return nil
    end
}