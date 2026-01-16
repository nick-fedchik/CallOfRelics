--[[
================================================================================
KOSMICMAZER — LandingPadEffectsModule
================================================================================

Purpose:
Controls the pulsing light effects on the SpaceShip landing pad frame.
Provides smooth brightness animation for frame lights during landing.

Version:
0.1

Features:
- Initialize frame lights from LandingPad reference
- Start/stop pulsing animation
- Configurable pulse interval, brightness range, and step
- Coroutine-based smooth animation loop

API:
- initialize(landingPadPath, config) — Find and setup frame lights
- start() — Begin pulsing animation
- stop() — Stop animation and reset lights
- isRunning() — Check if animation is active
- getFramePartsCount() — Get number of frame parts
- updateConfig(newConfig) — Update pulse parameters
- getConfig() — Get current configuration
- setBrightness(brightness) — Set brightness manually
- getCurrentBrightness() — Get current brightness level

Calls to:
- Workspace (to find LandingPad)

Called from:
- TransitionService (on landing sequence)

Dependencies:
- LandingPad model with LandingPadFrame folder
- Light instances inside each frame Part

ChangeLog:
- 0.1: Initial landing pad effects module (2026-01-14)
================================================================================
]]

local LandingPadEffectsModule = {}

-- Параметри за замовчуванням
local DEFAULT_CONFIG = {
    pulseInterval = 2.0,
    minBrightness = 0.5,
    maxBrightness = 2.0,
    brightnessStep = 0.05,
    updateInterval = 0.1
}

-- Приватні змінні
local frameParts = {}
local isRunning = false
local pulseCoroutine = nil
local currentConfig = {}
local currentBrightness = DEFAULT_CONFIG.minBrightness
local increasing = true

-- Функція для знаходження та ініціалізації частин рамки
function LandingPadEffectsModule.initialize(landingPadPath, config)
    if config then
        currentConfig = {}
        for key, value in pairs(DEFAULT_CONFIG) do
            currentConfig[key] = config[key] or value
        end
    else
        currentConfig = DEFAULT_CONFIG
    end
    
    local landingPad: Instance? = nil
    if typeof(landingPadPath) == "string" then
        local pathStr = landingPadPath :: string
        landingPad = game:GetService("Workspace"):FindFirstChild(pathStr)
        if not landingPad then
            -- Спроба знайти через повний шлях
            local parts = string.split(pathStr, ".")
            local current: Instance? = game
            for _, part in ipairs(parts) do
                if current then
                    current = current:FindFirstChild(part)
                end
            end
            landingPad = current
        end
    else
        landingPad = landingPadPath :: Instance
    end
    
    if not landingPad then
        warn("LandingPadEffectsModule: LandingPad not found at path: " .. tostring(landingPadPath))
        return false
    end
    
    local frameFolder = landingPad:FindFirstChild("LandingPadFrame")
    if not frameFolder then
        warn("LandingPadEffectsModule: LandingPadFrame folder not found")
        return false
    end
    
    frameParts = {}
    for _, part in ipairs(frameFolder:GetChildren()) do
        if part:IsA("Part") and part:FindFirstChild("Light") then
            table.insert(frameParts, part)
        end
    end
    
    if #frameParts == 0 then
        warn("LandingPadEffectsModule: No valid frame parts with lights found")
        return false
    end
    
    -- Скидання параметрів анімації
    currentBrightness = currentConfig.minBrightness
    increasing = true
    
    return true
end

-- Функція для оновлення яскравості світла
local function updateLights()
    for _, part in ipairs(frameParts) do
        local light = part:FindFirstChild("Light")
        if light then
            light.Brightness = currentBrightness
        end
    end
end

-- Цикл пульсування світла
local function pulseLights()
    while isRunning do
        if increasing then
            currentBrightness = currentBrightness + currentConfig.brightnessStep
            if currentBrightness >= currentConfig.maxBrightness then
                currentBrightness = currentConfig.maxBrightness
                increasing = false
            end
        else
            currentBrightness = currentBrightness - currentConfig.brightnessStep
            if currentBrightness <= currentConfig.minBrightness then
                currentBrightness = currentConfig.minBrightness
                increasing = true
            end
        end
        
        updateLights()
        task.wait(currentConfig.updateInterval)
    end
end

-- Запуск пульсування
function LandingPadEffectsModule.start()
    if isRunning then
        warn("LandingPadEffectsModule: Effects are already running")
        return false
    end
    
    if #frameParts == 0 then
        warn("LandingPadEffectsModule: No frame parts initialized. Call initialize() first.")
        return false
    end
    
    isRunning = true
    pulseCoroutine = task.spawn(pulseLights)
    return true
end

-- Зупинка пульсування
function LandingPadEffectsModule.stop()
    isRunning = false
    if pulseCoroutine then
        task.cancel(pulseCoroutine)
        pulseCoroutine = nil
    end
    
    -- Повернення світла у вихідний стан
    for _, part in ipairs(frameParts) do
        local light = part:FindFirstChild("Light")
        if light then
            light.Brightness = currentConfig.minBrightness
        end
    end
end

-- Перевірка статусу
function LandingPadEffectsModule.isRunning()
    return isRunning
end

-- Отримання кількості частин рамки
function LandingPadEffectsModule.getFramePartsCount()
    return #frameParts
end

-- Оновлення конфігурації
function LandingPadEffectsModule.updateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if DEFAULT_CONFIG[key] ~= nil then
            currentConfig[key] = value
        end
    end
end

-- Отримання поточної конфігурації
function LandingPadEffectsModule.getConfig()
    local configCopy = {}
    for key, value in pairs(currentConfig) do
        configCopy[key] = value
    end
    return configCopy
end

-- Встановлення яскравості вручну
function LandingPadEffectsModule.setBrightness(brightness)
    currentBrightness = math.max(currentConfig.minBrightness, math.min(currentConfig.maxBrightness, brightness))
    updateLights()
end

-- Отримання поточної яскравості
function LandingPadEffectsModule.getCurrentBrightness()
    return currentBrightness
end

return LandingPadEffectsModule