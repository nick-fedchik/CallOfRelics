--[[
    DebugLogger v1.1
    
    Система логування для Call of Relics.
    Зберігає логи в ReplicatedStorage.Debug.Log для читання через MCP.
    
    USAGE (два варіанти):
    
    1. Явний виклик (рекомендовано для нового коду):
        local Logger = require(game.ReplicatedStorage.Game.DebugLogger)
        Logger:Info("GameStateManager", "State changed to InGame")
        Logger:Warn("ProfileService", "Profile not found")
        Logger:Error("LocationService", "Failed to load location")
    
    2. Перехоплення стандартних функцій (для існуючого коду):
        local Logger = require(game.ReplicatedStorage.Game.DebugLogger)
        Logger:HookGlobalOutput()  -- Тепер всі print/warn автоматично логуються
    
    FEATURES:
        - Автоматичне створення Debug структури в ReplicatedStorage
        - Обмеження розміру логу (щоб уникнути overflow)
        - Різні рівні логування (DEBUG, INFO, WARN, ERROR)
        - Timestamp для кожного запису
        - Збереження останньої помилки окремо
        - Опціональне перехоплення print/warn/error
    
    VERSION: 1.1
    CHANGELOG:
        v1.1 - Added HookGlobalOutput() for intercepting print/warn
        v1.0 - Initial implementation
--]]

local DebugLogger = {}
DebugLogger.__index = DebugLogger

-- Налаштування
local MAX_LOG_SIZE = 150000  -- ~150KB максимум (StringValue limit ~200KB)
local LOG_LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

-- Мінімальний рівень для запису
local MIN_LOG_LEVEL = LOG_LEVELS.DEBUG

-- Кеш для Debug об'єктів
local debugFolder = nil
local logValue = nil
local counterValue = nil
local lastErrorValue = nil

-- Оригінальні функції (для перехоплення)
local originalPrint = print
local originalWarn = warn
local isHooked = false

-- Ініціалізація Debug структури
local function ensureDebugStructure()
    if debugFolder and logValue and counterValue and lastErrorValue then
        return true
    end
    
    local rs = game:GetService("ReplicatedStorage")
    
    debugFolder = rs:FindFirstChild("Debug")
    if not debugFolder then
        debugFolder = Instance.new("Folder")
        debugFolder.Name = "Debug"
        debugFolder.Parent = rs
    end
    
    logValue = debugFolder:FindFirstChild("Log")
    if not logValue then
        logValue = Instance.new("StringValue")
        logValue.Name = "Log"
        logValue.Value = ""
        logValue.Parent = debugFolder
    end
    
    counterValue = debugFolder:FindFirstChild("Counter")
    if not counterValue then
        counterValue = Instance.new("IntValue")
        counterValue.Name = "Counter"
        counterValue.Value = 0
        counterValue.Parent = debugFolder
    end
    
    lastErrorValue = debugFolder:FindFirstChild("LastError")
    if not lastErrorValue then
        lastErrorValue = Instance.new("StringValue")
        lastErrorValue.Name = "LastError"
        lastErrorValue.Value = ""
        lastErrorValue.Parent = debugFolder
    end
    
    return true
end

-- Форматування timestamp
local function getTimestamp()
    local time = os.date("*t")
    return string.format("%02d:%02d:%02d", time.hour, time.min, time.sec)
end

-- Конвертація аргументів у string
local function argsToString(...)
    local args = {...}
    local parts = {}
    for i, v in ipairs(args) do
        parts[i] = tostring(v)
    end
    return table.concat(parts, " ")
end

-- Основна функція логування (internal)
local function writeLog(level, module, message, skipOutput)
    if LOG_LEVELS[level] < MIN_LOG_LEVEL then
        return
    end
    
    ensureDebugStructure()
    
    local timestamp = getTimestamp()
    local logLine = string.format("[%s][%s][%s] %s\n", timestamp, level, module, tostring(message))
    
    -- Виводимо в Output (якщо не перехоплено)
    if not skipOutput then
        if level == "ERROR" then
            originalWarn(logLine)
        else
            originalPrint(logLine)
        end
    end
    
    -- Додаємо до логу
    local currentLog = logValue.Value
    
    -- Перевірка на переповнення
    if #currentLog + #logLine > MAX_LOG_SIZE then
        local cutPoint = math.floor(#currentLog * 0.2)
        local newlinePos = string.find(currentLog, "\n", cutPoint)
        if newlinePos then
            currentLog = "... [LOG TRIMMED] ...\n" .. string.sub(currentLog, newlinePos + 1)
        else
            currentLog = "... [LOG TRIMMED] ...\n"
        end
    end
    
    logValue.Value = currentLog .. logLine
    counterValue.Value = counterValue.Value + 1
    
    if level == "ERROR" then
        lastErrorValue.Value = logLine
    end
end

-- Запис сирого тексту (для перехоплення print/warn)
local function writeRaw(level, message)
    ensureDebugStructure()
    
    local timestamp = getTimestamp()
    local logLine = string.format("[%s][%s] %s\n", timestamp, level, message)
    
    local currentLog = logValue.Value
    
    if #currentLog + #logLine > MAX_LOG_SIZE then
        local cutPoint = math.floor(#currentLog * 0.2)
        local newlinePos = string.find(currentLog, "\n", cutPoint)
        if newlinePos then
            currentLog = "... [LOG TRIMMED] ...\n" .. string.sub(currentLog, newlinePos + 1)
        else
            currentLog = "... [LOG TRIMMED] ...\n"
        end
    end
    
    logValue.Value = currentLog .. logLine
    counterValue.Value = counterValue.Value + 1
    
    if level == "ERROR" or level == "WARN" then
        lastErrorValue.Value = logLine
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function DebugLogger:Debug(module, message)
    writeLog("DEBUG", module, message)
end

function DebugLogger:Info(module, message)
    writeLog("INFO", module, message)
end

function DebugLogger:Warn(module, message)
    writeLog("WARN", module, message)
end

function DebugLogger:Error(module, message)
    writeLog("ERROR", module, message)
end

function DebugLogger:Clear()
    ensureDebugStructure()
    logValue.Value = ""
    counterValue.Value = 0
    lastErrorValue.Value = ""
    originalPrint("[DebugLogger] Log cleared")
end

function DebugLogger:GetCount()
    ensureDebugStructure()
    return counterValue.Value
end

function DebugLogger:SetMinLevel(level)
    if LOG_LEVELS[level] then
        MIN_LOG_LEVEL = LOG_LEVELS[level]
        originalPrint("[DebugLogger] Min log level set to: " .. level)
    end
end

-- ============================================================================
-- GLOBAL HOOK (перехоплення print/warn)
-- ============================================================================

function DebugLogger:HookGlobalOutput()
    if isHooked then
        originalPrint("[DebugLogger] Already hooked")
        return
    end
    
    -- Перехоплюємо print
    print = function(...)
        local message = argsToString(...)
        originalPrint(...)  -- Оригінальний вивід
        writeRaw("INFO", message)  -- Додатково в лог
    end
    
    -- Перехоплюємо warn
    warn = function(...)
        local message = argsToString(...)
        originalWarn(...)  -- Оригінальний вивід
        writeRaw("WARN", message)  -- Додатково в лог
    end
    
    isHooked = true
    originalPrint("[DebugLogger] Global output hooked - all print/warn will be logged")
end

function DebugLogger:UnhookGlobalOutput()
    if not isHooked then
        return
    end
    
    print = originalPrint
    warn = originalWarn
    isHooked = false
    originalPrint("[DebugLogger] Global output unhooked")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

ensureDebugStructure()

return DebugLogger
