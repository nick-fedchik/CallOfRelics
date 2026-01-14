--[[
================================================================================
KOSMICMAZER — LandingLightsModule
================================================================================

Purpose:
Controls the blinking landing lights on the SpaceShip landing pad.
Provides start/stop functionality with configurable blink intervals.

Version:
0.1

Features:
- Initialize lights from LandingPad reference
- Start/stop blinking animation
- Configurable blink interval, colors, and transparency
- Coroutine-based animation loop

API:
- initialize(landingPadPath, config) — Find and setup lights
- start() — Begin blinking animation
- stop() — Stop animation and reset lights
- isRunning() — Check if animation is active
- getLightsCount() — Get number of lights
- updateConfig(newConfig) — Update blink parameters
- getConfig() — Get current configuration

Calls to:
- Workspace (to find LandingPad)

Called from:
- TransitionService (on landing sequence)

Dependencies:
- LandingPad model with LandingLights folder
- Light instances inside each light Part

ChangeLog:
- 0.1: Initial landing lights module (2026-01-14)
================================================================================
]]

local LandingLightsModule = {}

-- Параметри за замовчуванням
local DEFAULT_CONFIG = {
    blinkInterval = 1.0,
    onTransparency = 0,
    offTransparency = 0.7,
    onColor = nil, -- Використовувати оригінальний колір
    offColor = BrickColor.new("Dark stone grey")
}

-- Приватні змінні
local lights = {}
local isRunning = false
local blinkCoroutine = nil
local currentConfig = {}

-- Функція для знаходження та ініціалізації вогнів
function LandingLightsModule.initialize(landingPadPath, config)
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
        warn("LandingLightsModule: LandingPad not found at path: " .. tostring(landingPadPath))
        return false
    end
    
    local lightsFolder = landingPad:FindFirstChild("LandingLights")
    if not lightsFolder then
        warn("LandingLightsModule: LandingLights folder not found")
        return false
    end
    
    lights = {}
    for _, light in ipairs(lightsFolder:GetChildren()) do
        if light:IsA("Part") and light:FindFirstChild("Light") then
            table.insert(lights, {
                Part = light,
                Light = light.Light,
                OriginalColor = light.BrickColor
            })
        end
    end
    
    if #lights == 0 then
        warn("LandingLightsModule: No valid lights found")
        return false
    end
    
    return true
end

-- Функція блимання
local function blinkLights()
    local isOn = true
    
    while isRunning do
        isOn = not isOn
        
        for _, lightData in ipairs(lights) do
            if isOn then
                -- Ввімкнути вогні
                lightData.Part.Transparency = currentConfig.onTransparency
                lightData.Light.Enabled = true
                if currentConfig.onColor then
                    lightData.Part.BrickColor = currentConfig.onColor
                else
                    lightData.Part.BrickColor = lightData.OriginalColor
                end
            else
                -- Вимкнути вогні
                lightData.Part.Transparency = currentConfig.offTransparency
                lightData.Light.Enabled = false
                lightData.Part.BrickColor = currentConfig.offColor
            end
        end
        
        task.wait(currentConfig.blinkInterval)
    end
end

-- Запуск блимання
function LandingLightsModule.start()
    if isRunning then
        warn("LandingLightsModule: Lights are already running")
        return false
    end
    
    if #lights == 0 then
        warn("LandingLightsModule: No lights initialized. Call initialize() first.")
        return false
    end
    
    isRunning = true
    blinkCoroutine = task.spawn(blinkLights)
    return true
end

-- Зупинка блимання
function LandingLightsModule.stop()
    isRunning = false
    if blinkCoroutine then
        task.cancel(blinkCoroutine)
        blinkCoroutine = nil
    end
    
    -- Повернення вогнів у вихідний стан
    for _, lightData in ipairs(lights) do
        lightData.Part.Transparency = 0
        lightData.Light.Enabled = false
        lightData.Part.BrickColor = lightData.OriginalColor
    end
end

-- Перевірка статусу
function LandingLightsModule.isRunning()
    return isRunning
end

-- Отримання кількості вогнів
function LandingLightsModule.getLightsCount()
    return #lights
end

-- Оновлення конфігурації
function LandingLightsModule.updateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if DEFAULT_CONFIG[key] ~= nil then
            currentConfig[key] = value
        end
    end
end

-- Отримання поточної конфігурації
function LandingLightsModule.getConfig()
    local configCopy = {}
    for key, value in pairs(currentConfig) do
        configCopy[key] = value
    end
    return configCopy
end

return LandingLightsModule