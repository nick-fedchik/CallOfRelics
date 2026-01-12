# Knowledge Base - Call of Relics
> База знань успішних рішень, ефективних алгоритмів та перевірених практик

**Версія**: 0.1
**Остання оновлення**: 2026-01-11

---

## 🎯 Призначення

Цей документ містить:
- ✅ Успішні архітектурні рішення
- ✅ Ефективні алгоритми та структури даних
- ✅ Перевірені протоколи та стандарти
- ✅ Вдалі UI/UX паттерни
- ✅ Оптимізовані підходи до Roblox API
- ✅ Уроки з помилок та їх рішення

---

## 📚 Зміст

1. [Налаштування Studio](#налаштування-studio)
2. [Архітектурні Рішення](#архітектурні-рішення)
3. [State Management](#state-management)
4. [UI/UX Паттерни](#uiux-паттерни)
5. [Комунікація Client-Server](#комунікація-client-server)
6. [Roblox API Best Practices](#roblox-api-best-practices)
7. [Уроки з Помилок](#уроки-з-помилок)

---

## Налаштування Studio

### Крок 1: Створення Якірних Папок (Anchor Folders)

**Важливо:** Script Sync вимагає, щоб папки існували в Studio **перед** синхронізацією файлів.

#### ServerScriptService

1. У **Explorer** знайти **ServerScriptService**
2. Правий клік → **Insert Object → Folder**
3. Створити папки:
   - `Core` - серверне ядро (GameStateManager, BootSequence, ServerBootstrap)
   - `Services` - бізнес-логіка (PlayerService, ProfileService)
   - `Setup` - ініціалізаційні скрипти (RemoteEventsSetup, DataStoreSetup)
   - `Systems` - ігрові системи (порожня для майбутніх EPIC)

#### StarterPlayer → StarterPlayerScripts

1. У **Explorer** знайти **StarterPlayer → StarterPlayerScripts**
2. Створити папки:
   - `Core` - клієнтське ядро (ClientBootstrap)
   - `UI` - UI модулі (ScreenSaverUI, StatusBarUI, UIManager)
   - `Systems` - клієнтські системи (порожня для майбутніх EPIC)

#### ReplicatedStorage

1. У **Explorer** знайти **ReplicatedStorage**
2. Створити папки:
   - `Game` - спільні конфіги (GameConfig)
   - `Modules` - спільні модулі (порожня)

**Примітка:** Папка `RemoteEvents` створюється автоматично скриптом `RemoteEventsSetup.server.lua`

---

### Крок 2: Налаштування Script Sync

#### Активація Script Sync

1. У Roblox Studio: **View → Script Sync**
2. Натиснути **Configure** або **Choose Folder**
3. Вибрати корінь проєкту: `d:\Code\Roblox\CallOfRelics`
4. Натиснути **Enable Sync** або **Start Sync**

#### Конвенція Розширень Файлів

Script Sync визначає тип скрипта за розширенням:

- `.lua` → **ModuleScript** (require для використання)
- `.server.lua` → **Script** (server-side, автовиконання)
- `.client.lua` → **LocalScript** (client-side, автовиконання)

**Приклади:**
- `GameConfig.lua` → ModuleScript
- `RemoteEventsSetup.server.lua` → Script (server)
- `ClientBootstrap.client.lua` → LocalScript (client)

#### Перевірка Синхронізації

**Тест 1: Файлова система → Studio**
1. У VS Code додати коментар у будь-який `.lua` файл
2. Зберегти файл (Ctrl+S)
3. Перевірити у Studio, що зміни з'явилися

**Тест 2: Studio → Файлова система**
1. У Studio створити тестовий ModuleScript у `Core/`
2. Перевірити у VS Code, що файл з'явився
3. Видалити тестовий модуль

**Якщо обидва тести пройшли — синхронізація працює! ✅**

---

### Крок 3: Увімкнення API Services

#### Налаштування Game Settings

1. **Home → Game Settings** (або Alt+S)
2. **Security → Allow HTTP Requests** → ✅ Увімкнути
   - Потрібно для завантаження avatar thumbnails
3. **Security → Enable Studio Access to API Services** → ✅ Увімкнути
   - Потрібно для DataStore (збереження профілів)

#### Перевірка DataStore

Виконати у Command Bar:

```lua
local DataStoreService = game:GetService("DataStoreService")
local testStore = DataStoreService:GetDataStore("TestStore")
print("DataStore enabled:", testStore ~= nil)
```

**Очікуваний результат:** `DataStore enabled: true`

---

### Крок 4: Очікувана Структура Після Синхронізації

```
ServerScriptService/
├── Core/
│   ├── GameStateManager (ModuleScript)
│   ├── BootSequence (ModuleScript)
│   └── ServerBootstrap (Script)
├── Services/
│   ├── PlayerService (ModuleScript)
│   └── ProfileService (ModuleScript)
├── Setup/
│   └── RemoteEventsSetup (Script)
└── Systems/
    (порожня)

StarterPlayer/StarterPlayerScripts/
├── Core/
│   └── ClientBootstrap (LocalScript)
├── UI/
│   ├── ScreenSaverUI (ModuleScript)
│   ├── ScreenSaverUI-dev (ModuleScript) -- dev version для тестування
│   ├── StatusBarUI (ModuleScript)
│   └── UIManager (ModuleScript)
└── Systems/
    (порожня)

ReplicatedStorage/
├── Game/
│   └── GameConfig (ModuleScript)
├── Modules/
│   (порожня)
└── RemoteEvents/ (створюється при запуску)
    ├── StateChanged (RemoteEvent)
    ├── BootStageUpdate (RemoteEvent)
    ├── EnterGame (RemoteEvent)
    ├── LogOff (RemoteEvent)
    ├── StartGame (RemoteEvent)
    └── RetryBootStage (RemoteEvent)
```

---

### Troubleshooting: Script Sync

#### Проблема: "Infinite yield possible on WaitForChild"

**Причина:** Anchor folders не створені в Studio

**Рішення:**
1. Створити всі папки в Studio вручну (Core, Services, UI тощо)
2. Перезапустити Script Sync
3. Перезапустити Studio якщо потрібно

#### Проблема: Файли не з'являються

**Причина:** Неправильний root path або папки відсутні

**Рішення:**
1. Перевірити root path у Script Sync window
2. Створити anchor folders в Studio
3. Stop → Start Script Sync

#### Проблема: Скрипти у неправильному місці

**Причина:** Folder structure mismatch

**Рішення:**
1. Перевірити, що файлова структура відповідає Studio structure
2. Переміщувати файли в файловій системі, а не в Studio
3. Script Sync автоматично оновить Studio

#### Проблема: Зміни не синхронізуються

**Причина:** Script Sync зупинено або конфлікт

**Рішення:**
1. Перевірити статус Script Sync (має бути "Up to date")
2. Якщо конфлікт: вибрати "Use filesystem version" (рекомендовано)
3. Restart Script Sync

---

### Troubleshooting: DataStore

#### Проблема: "DataStore request was throttled"

**Причина:** Забагато запитів у Studio testing mode

**Рішення:**
- Додати `task.wait(1)` між DataStore викликами
- Кешувати дані замість повторних reads
- Це нормально для Studio - в production не буде проблеми

#### Проблема: "502: API Services rejected request"

**Причина:** API Services не увімкнені або немає інтернету

**Рішення:**
1. Увімкнути "Studio Access to API Services"
2. Перевірити інтернет з'єднання
3. Перезапустити Studio
4. Гра працюватиме з тимчасовими in-memory профілями

---

## Архітектурні Рішення

### ✅ Модульна Структура Проекту

**Проблема**: Потрібна чітка організація коду для підтримуваності та масштабованості.

**Рішення**: Розділення на логічні сервіси та модулі:

```
ServerScriptService/
├── Core/              # Ядро гри (GameStateManager, BootSequence)
└── Services/          # Бізнес-логіка (PlayerService, ProfileService)

StarterPlayer/StarterPlayerScripts/
├── Core/              # Клієнтське ядро (ClientBootstrap)
└── UI/                # UI модулі (ScreenSaverUI, StatusBarUI, UIManager)

ReplicatedStorage/
├── Game/              # Спільні конфіги (GameConfig)
└── RemoteEvents/      # Комунікація Client-Server
```

**Переваги**:
- Чіткий розподіл відповідальності
- Легко знайти потрібний код
- Простіше тестувати окремі модулі
- Зручно додавати нові функції

---

### ✅ UIManager Pattern - Централізоване Управління UI

**Проблема**: Кілька UI модулів повинні координовано реагувати на зміни стану гри.

**Рішення**: UIManager як єдина точка контролю:

```lua
-- UIManager.Initialize() приймає всі UI модулі
UIManager.Initialize(ScreenSaverUI, StatusBarUI)

-- UIManager керує видимістю на основі GameState
function UIManager.OnStateChanged(oldState, newState)
    if newState == "LoggedOff" then
        ScreenSaverUI.Reset()
        ScreenSaverUI.Show()
        StatusBarUI.Hide()
    elseif newState == "InGame" then
        ScreenSaverUI.Hide()
        StatusBarUI.Show()
    end
end
```

**Переваги**:
- Один модуль відповідає за координацію UI
- UI модулі не знають один про одного (loose coupling)
- Легко додавати нові UI елементи
- Передбачувана поведінка при зміні стану

**Файл**: [UIManager.lua](../StarterPlayer/StarterPlayerScripts/UI/UIManager.lua)

---

### ✅ Module-Based UI Architecture

**Проблема**: UI код важко підтримувати при монолітній структурі.

**Рішення**: Кожен UI елемент - окремий модуль з стандартним API:

```lua
-- Стандартний API для UI модулів:
local Module = {}

function Module.Initialize()
    -- Створення UI елементів
    -- Налаштування event listeners
end

function Module.Show()
    -- Показ UI з анімацією
end

function Module.Hide()
    -- Приховування UI з анімацією
end

function Module.Reset()
    -- Скидання до початкового стану
end

return Module
```

**Переваги**:
- Стандартний інтерфейс для всіх UI модулів
- Легко тестувати кожен модуль окремо
- Повторне використання коду (fade animations)
- Просте додавання нових UI елементів

**Приклади**: [ScreenSaverUI.lua](../StarterPlayer/StarterPlayerScripts/UI/ScreenSaverUI.lua), [StatusBarUI.lua](../StarterPlayer/StarterPlayerScripts/UI/StatusBarUI.lua)

---

## State Management

### ✅ Finite State Machine для Гри

**Проблема**: Контролювати складні переходи між станами гри (LoggedOff, Initializing, InGame).

**Рішення**: GameStateManager як централізований FSM:

```lua
-- Визначення можливих переходів
local ALLOWED_TRANSITIONS = {
    [States.LoggedOff] = {States.Initializing},
    [States.Initializing] = {States.InGame, States.LoggedOff}, -- fallback на помилку
    [States.InGame] = {States.LoggedOff}
}

-- Перевірка перед переходом
function GameStateManager.RequestStateChange(newState, context)
    -- Валідація переходу
    if not IsTransitionAllowed(currentState, newState) then
        warn(string.format("[GameStateManager] Forbidden transition: %s → %s",
            currentState, newState))
        return false
    end

    -- Зміна стану
    local oldState = currentState
    currentState = newState

    -- Нотифікація клієнтів
    NotifyStateChange(oldState, newState, context)

    return true
end
```

**Переваги**:
- Неможливі некоректні переходи (InGame → Initializing заборонено)
- Єдина точка контролю стану
- Легко додати логування/аналітику
- Передбачувана поведінка системи

**Файл**: [GameStateManager.lua](../ServerScriptService/Core/GameStateManager.lua)

---

### ✅ Flexible Context Handling

**Проблема**: Різні частини коду передають player контекст у різних форматах (Player object vs {player: Player}).

**Рішення**: Універсальний handler в GameStateManager:

```lua
-- Приймає як Player object, так і {player: Player}
local player = nil
if typeof(context) == "Instance" and context:IsA("Player") then
    player = context -- Прямий Player object
elseif type(context) == "table" and context.player then
    player = context.player -- Table формат
end
```

**Переваги**:
- Гнучкість у використанні API
- Backward compatibility
- Менше помилок при рефакторингу
- Зручніше для розробника

**Урок**: Якщо API може приймати різні формати одних і тих же даних, це зменшує ймовірність помилок.

---

## UI/UX Паттерни

### ✅ Cumulative/Progressive UI Pattern

**Проблема**: ScreenSaver показував окремі екрани для кожної стадії, що створювало мерехтіння та чорні екрани між переходами.

**НЕПРАВИЛЬНИЙ підхід** (заміна екранів):
```lua
-- Stage 1: Показати екран 1
ShowScreen1()
wait(1.5)
HideScreen1() -- ❌ Чорний екран!

-- Stage 2: Показати екран 2
wait(0.3)
ShowScreen2()
```

**ПРАВИЛЬНИЙ підхід** (накопичення елементів):
```lua
-- Всі елементи створені заздалегідь, але прозорі (TextTransparency = 1)

-- Stage 1: ДОДАТИ game name (інші елементи залишаються прозорими)
function ShowStage1()
    FadeIn(gameNameLabel, 0.6)
    FadeIn(gameSubtitleLabel, 0.6)
    FadeIn(versionLabel, 0.6)
end

-- Stage 2: ДОДАТИ player info (Stage 1 залишається видимим!)
function ShowStage2()
    FadeIn(avatarFrame, 0.6)
    FadeIn(playerNameLabel, 0.6)
    -- gameNameLabel все ще видимий!
end

-- Stage 3: ДОДАТИ loading spinner (Stages 1+2 видимі)
function ShowStage3()
    FadeIn(loadingSpinner, 0.6)
    FadeIn(progressBar, 0.6)
    -- gameNameLabel і avatarFrame все ще видимі!
end
```

**Переваги**:
- Немає мерехтіння/чорних екранів
- Плавні переходи (TweenService)
- Відчуття прогресу для користувача
- Контекст попередніх стадій залишається видимим

**Візуалізація**:
```
Stage 1:  [GAME NAME]
Stage 2:  [GAME NAME] + [AVATAR + PLAYER NAME]
Stage 3:  [GAME NAME] + [AVATAR + PLAYER NAME] + [LOADING SPINNER]
Stage 4:  [GAME NAME] + [AVATAR + PLAYER NAME] + [READY BUTTON]
```

**Файл**: [ScreenSaverUI.lua v0.4](../StarterPlayer/StarterPlayerScripts/UI/ScreenSaverUI.lua)

---

### ✅ TweenService для Плавних Анімацій

**Проблема**: Різкі з'явлення/зникнення UI елементів виглядають непрофесійно.

**Рішення**: Універсальна функція FadeIn/FadeOut:

```lua
local TweenService = game:GetService("TweenService")

local function FadeIn(element, duration, property)
    property = property or "TextTransparency"

    local tweenInfo = TweenInfo.new(
        duration or 0.6,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    local goal = {[property] = 0}
    local tween = TweenService:Create(element, tweenInfo, goal)
    tween:Play()
end

local function FadeOut(element, duration, property)
    property = property or "TextTransparency"

    local goal = {[property] = 1}
    local tween = TweenService:Create(element, tweenInfo, goal)
    tween:Play()
end
```

**Використання**:
```lua
-- Для тексту (TextTransparency)
FadeIn(textLabel, 0.6)

-- Для фону (BackgroundTransparency)
FadeIn(frame, 0.6, "BackgroundTransparency")

-- Для зображень (ImageTransparency)
FadeIn(imageLabel, 0.6, "ImageTransparency")
```

**Переваги**:
- Професійний вигляд UI
- Повторне використання коду
- Гнучкість (різні duration та properties)
- Оптимізовано (TweenService використовує C++ backend)

---

### ✅ UI Layout - Уникнення Конфліктів з Roblox UI

**Проблема**: Кнопка "Вихід" в лівому верхньому куті конфліктувала зі стандартними елементами Roblox (player list, chat, Roblox menu).

**Рішення**: Розміщення інтерактивних елементів справа:

```lua
-- ❌ НЕПРАВИЛЬНО - конфлікт з Roblox UI
exit.Position = UDim2.new(0, 10, 0.5, 0) -- Ліво
exit.AnchorPoint = Vector2.new(0, 0.5)

-- ✅ ПРАВИЛЬНО - безпечна зона справа
exit.Position = UDim2.new(1, -10, 0.5, 0) -- Право
exit.AnchorPoint = Vector2.new(1, 0.5)
```

**Layout стратегія**:
```
┌─────────────────────────────────────────────────────┐
│ [STATIC INFO LEFT]              [INTERACTIVE RIGHT] │
└─────────────────────────────────────────────────────┘
   ↑                                        ↑
   Інформація                              Кнопки/дії
   (Planet, Location)                      (Exit)
```

**Правила**:
- Статична інформація - зліва
- Інтерактивні елементи (кнопки) - справа
- Уникати центру верхньої частини екрану (Roblox menu)
- Уникати лівого верхнього кута (player list, chat)

**Файл**: [StatusBarUI.lua v0.2](../StarterPlayer/StarterPlayerScripts/UI/StatusBarUI.lua)

---

### ✅ Responsive Button Design

**Проблема**: Кнопки без hover effects виглядають "мертвими".

**Рішення**: MouseEnter/MouseLeave events для візуального feedback:

```lua
local button = Instance.new("TextButton")
button.BackgroundColor3 = Color3.fromRGB(41, 128, 185) -- Синій

button.MouseEnter:Connect(function()
    button.BackgroundColor3 = Color3.fromRGB(52, 152, 219) -- Світліше
end)

button.MouseLeave:Connect(function()
    button.BackgroundColor3 = Color3.fromRGB(41, 128, 185) -- Назад
end)
```

**Для Exit button** (червона кнопка):
```lua
exit.BackgroundColor3 = Color3.fromRGB(192, 57, 43) -- Червоний

exit.MouseEnter:Connect(function()
    exit.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Світліший червоний
end)

exit.MouseLeave:Connect(function()
    exit.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
end)
```

**Переваги**:
- Миттєвий візуальний feedback
- Зрозуміло, що це інтерактивний елемент
- Підвищує UX якість
- Дуже простий у реалізації

---

## Комунікація Client-Server

### ✅ RemoteEvent Protocol для Boot Sequence

**Проблема**: Синхронізація прогресу Boot Sequence між сервером і клієнтом.

**Рішення**: Структурований протокол передачі даних:

```lua
-- Server → Client: BootStageUpdate
bootStageUpdate:FireClient(player, stageNumber, {
    -- Stage 1
    gameName = "CALL OF RELICS",
    gameSubtitle = "Orbital Silence",
    version = "0.2",
    versionTag = "EPIC 1"

    -- Stage 2
    userId = player.UserId,
    displayName = player.DisplayName,

    -- Stage 3
    isNewPlayer = true/false,
    profileId = "..."
})

-- Client обробка
BootStageUpdate.OnClientEvent:Connect(function(stage, stageData)
    if stage == 1 then
        ScreenSaverUI.ShowStage1(stageData)
    elseif stage == 2 then
        ScreenSaverUI.ShowStage2(stageData)
    -- ...
    end
end)
```

**Переваги**:
- Типізовані дані (передбачувана структура)
- Сервер контролює прогрес (анти-чіт)
- Легко додати нові поля
- Зручно для debug (console.log stageData)

**Файли**:
- Server: [BootSequence.lua](../ServerScriptService/Core/BootSequence.lua)
- Client: [ScreenSaverUI.lua](../StarterPlayer/StarterPlayerScripts/UI/ScreenSaverUI.lua)

---

### ✅ Request-Response Pattern для Дій Гравця

**Проблема**: Клієнт хоче виконати дію (LogOff, StartGame), яку повинен підтвердити сервер.

**Рішення**: Client → Server RemoteEvent:

```lua
-- Client: Запит на вихід
local function OnExitClicked()
    local logOffRequest = remoteEvents:WaitForChild("LogOffRequest")
    logOffRequest:FireServer() -- Не чекаємо відповіді
end

-- Server: Обробка запиту
LogOffRequest.OnServerEvent:Connect(function(player)
    -- Валідація
    if not PlayerService.IsPlayerInGame(player) then
        return -- Ігнорувати некоректний запит
    end

    -- Виконання
    PlayerService.LogOffPlayer(player)
end)

-- Server автоматично нотифікує клієнта через StateChanged event
```

**Переваги**:
- Сервер контролює всі важливі дії
- Клієнт не може "обдурити" систему
- Асинхронна комунікація (не блокує UI)
- Автоматична нотифікація через StateChanged

**Протокол RemoteEvents**:
```
Client → Server:
- LogOffRequest: FireServer()
- ConfirmGameStart: FireServer()

Server → Client:
- StateChanged: FireClient(player, oldState, newState)
- BootStageUpdate: FireClient(player, stage, stageData)
```

---

### ✅ Centralized RemoteEvents Folder

**Проблема**: RemoteEvents розкидані по різних місцях, важко відслідкувати.

**Рішення**: ReplicatedStorage/RemoteEvents як єдине джерело:

```
ReplicatedStorage/
└── RemoteEvents/
    ├── StateChanged (RemoteEvent)
    ├── BootStageUpdate (RemoteEvent)
    ├── LogOffRequest (RemoteEvent)
    └── ConfirmGameStart (RemoteEvent)
```

**Використання**:
```lua
-- Server або Client
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local stateChanged = remoteEvents:WaitForChild("StateChanged")

-- Використовувати як зазвичай
stateChanged:FireClient(player, oldState, newState)
```

**Переваги**:
- Всі RemoteEvents в одному місці
- Легко побачити всі комунікаційні канали
- Уникнення дублювання
- Простіше для документації

---

## Roblox API Best Practices

### ✅ Асинхронне Завантаження Avatar Thumbnail

**Проблема**: `Players:GetUserThumbnailAsync()` може зависнути або упасти.

**Рішення**: task.spawn() + pcall():

```lua
-- ❌ НЕПРАВИЛЬНО - блокує основний потік
local thumbnail = Players:GetUserThumbnailAsync(
    userId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size150x150
)
avatarImage.Image = thumbnail

-- ✅ ПРАВИЛЬНО - асинхронно з error handling
task.spawn(function()
    local success, thumbnail = pcall(function()
        return Players:GetUserThumbnailAsync(
            userId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size150x150
        )
    end)

    if success then
        avatarImage.Image = thumbnail
    else
        warn("[ScreenSaverUI] Failed to load avatar:", thumbnail)
        -- Fallback: залишити порожнім або показати placeholder
    end
end)
```

**Переваги**:
- Не блокує UI
- Обробка помилок (недоступна мережа, HTTP не ввімкнено)
- Graceful degradation
- Не ламає Boot Sequence якщо thumbnail не завантажився

---

### ✅ WaitForChild() з Timeout

**Проблема**: `WaitForChild()` без timeout може зависнути назавжди.

**Рішення**: Завжди вказувати timeout:

```lua
-- ❌ НЕБЕЗПЕЧНО - може зависнути назавжди
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- ✅ БЕЗПЕЧНО - timeout 10 секунд
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteEvents then
    error("[Module] RemoteEvents folder not found!")
end
```

**Для критичних елементів**:
```lua
-- Невелика затримка = швидше fail fast
local stateChanged = remoteEvents:WaitForChild("StateChanged", 5)
if not stateChanged then
    error("Critical RemoteEvent missing!")
end
```

---

### ✅ Prevent Double Script Execution

**Проблема**: ClientBootstrap може виконатись двічі (Roblox Studio bug).

**Рішення**: Attribute-based guard:

```lua
-- На початку ClientBootstrap
if player:GetAttribute("ClientBootstrapRan") then
    warn("[ClientBootstrap] Already ran for this player, skipping...")
    return
end

player:SetAttribute("ClientBootstrapRan", true)

-- Продовжити ініціалізацію...
```

**Переваги**:
- Простий і надійний механізм
- Attributes зберігаються на Player object
- Легко debug (видно в Explorer)
- Нульовий overhead

**Файл**: [ClientBootstrap.client.lua](../StarterPlayer/StarterPlayerScripts/Core/ClientBootstrap.client.lua)

---

## Уроки з Помилок

### ❌ → ✅ Помилка: Double State Transition

**Що сталося**:
```lua
-- PlayerService.OnPlayerAdded()
GameStateManager.RequestStateChange("Initializing", player) -- ❌ Перший виклик
PlayerService.LogOnPlayer(player) -- ❌ Викликає RequestStateChange знову!

-- Помилка: "Forbidden transition: Initializing → Initializing"
```

**Чому це погано**:
- FSM блокує дублікати переходів
- Boot Sequence не стартував
- Гравець бачив чорний екран

**Як виправили**:
```lua
-- PlayerService.OnPlayerAdded()
PlayerService.LogOnPlayer(player) -- ✅ Тільки один виклик

-- PlayerService.LogOnPlayer() обробляє перехід всередині
function PlayerService.LogOnPlayer(player)
    GameStateManager.RequestStateChange("Initializing", player)
    BootSequence.StartBoot(player)
end
```

**Урок**: Дублікати викликів state transitions = небезпечно. Один відповідальний за кожен перехід.

---

### ❌ → ✅ Помилка: "player is not a valid member of Player"

**Що сталося**:
```lua
-- PlayerService викликав:
RequestStateChange("Initializing", player) -- player = Player object

// GameStateManager очікував:
local playerObj = context.player -- ❌ context.player не існує!
```

**Чому це погано**:
- Runtime error при кожному переході
- StateChanged event не надсилався клієнту
- UI не оновлювався

**Як виправили**:
```lua
-- Універсальний handler в GameStateManager
local player = nil
if typeof(context) == "Instance" and context:IsA("Player") then
    player = context -- ✅ Прямий Player object
elseif type(context) == "table" and context.player then
    player = context.player -- ✅ Table формат
end
```

**Урок**: API має бути гнучким. Якщо може бути кілька форматів - підтримувати всі.

---

### ❌ → ✅ Помилка: ScreenSaver "Мерехтіння"

**Що сталося**:
- Кожна стадія була окремим контейнером
- ShowStage2() викликав HideStage1() → чорний екран → ShowStage2()
- Гравець бачив 4 окремі екрани з чорними проміжками

**Візуалізація проблеми**:
```
[Stage 1] → [BLACK] → [Stage 2] → [BLACK] → [Stage 3] → [BLACK] → [Stage 4]
  1.5s       0.3s       1.5s       0.3s       2s         0.3s       ∞
```

**Як виправили**: Cumulative UI Pattern
```
[Stage 1] → [Stage 1+2] → [Stage 1+2+3] → [Stage 1+2+4]
  1.5s         1.5s            2s              ∞
```

**Урок**: UI має бути прогресивним, не заміняючим. Додавай нові елементи, не видаляй старі.

**Файл**: [ScreenSaverUI.lua v0.4](../StarterPlayer/StarterPlayerScripts/UI/ScreenSaverUI.lua)

---

### ❌ → ✅ Помилка: UI Конфлікт з Roblox Elements

**Що сталося**:
- Кнопка "Вихід" була в лівому верхньому куті
- Roblox player list, chat, menu перекривали кнопку
- Гравець не міг натиснути кнопку

**Як виправили**:
```lua
-- Перемістили кнопку вправо
exit.Position = UDim2.new(1, -10, 0.5, 0) -- Право
exit.AnchorPoint = Vector2.new(1, 0.5)
```

**Урок**: Завжди враховувати стандартні UI елементи Roblox:
- Ліво верх: Player List, Chat
- Право верх: Settings, Report
- Центр верх: Roblox Menu (при натисканні Esc)

**Безпечні зони**:
- ✅ Право (для кнопок)
- ✅ Низ (для HUD)
- ✅ Ліво (для інформації, але не інтерактивних елементів)

---

## 🔧 Інструменти та Утиліти

### ✅ Git Commit Messages - Стандарт

**Формат**:
```
<Short Title (50 chars)>

<Detailed Description>

Key Changes:
- Change 1
- Change 2

Modified Files:
- File 1: Description
- File 2: Description

Bug Fixes:
- Bug 1: How fixed
- Bug 2: How fixed

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Приклад**: Commit `1e47f63`
```
Fix state management and complete UI cycle (LoggedOff ↔ InGame)

This commit finalizes EPIC 1 by fixing critical state management bugs
and implementing the full game cycle with proper UI transitions.

Key Changes:
- Fixed double state transition (Initializing → Initializing)
- Unified player context format in GameStateManager
- Rewrote ScreenSaverUI to cumulative/progressive UI (v0.4)
...
```

**Переваги**:
- Легко знайти потрібний commit
- Зрозуміло що було змінено без читання коду
- Відслідковування історії змін
- Професійний вигляд проекту

---

### ✅ Version Tagging для Модулів

**Стандарт**: Вказувати версію в коментарях модуля:

```lua
--[[
    ScreenSaverUI.lua
    Version: 0.4
    Last Updated: 2026-01-11

    Boot sequence UI with cumulative/progressive stages.
    Each stage ADDS elements without hiding previous ones.
]]
```

**Переваги**:
- Легко відслідкувати зміни в модулі
- Зрозуміло чи актуальна версія
- Зручно для команди

---

## 📊 Метрики Успіху

### EPIC 1 - Результати

**Виконано**:
- ✅ 4-stage Boot Sequence (автоматичний запуск)
- ✅ Cumulative ScreenSaver UI без мерехтіння
- ✅ State Management (FSM з валідацією переходів)
- ✅ StatusBar UI для InGame стану
- ✅ Повний цикл гри: LoggedOff ↔ InGame
- ✅ Profile Management з DataStore

**Виправлено критичних багів**: 4
- Double state transition
- Player context format error
- ScreenSaver flickering
- UI layout conflicts

**Створено модулів**: 8
- GameStateManager
- PlayerService
- ProfileService
- BootSequence
- ScreenSaverUI
- StatusBarUI
- UIManager
- ClientBootstrap

**Рядків коду**: ~1500+ (без документації)

**Час розробки**: 1 сесія (з рефакторингом)

---

## 🎓 Висновки та Next Steps

### Що працює відмінно:

1. **Модульна архітектура** - легко масштабувати
2. **State Management** - надійний та передбачуваний
3. **UI/UX** - професійний вигляд, плавні анімації
4. **Client-Server комунікація** - структурована та безпечна
5. **Error Handling** - graceful degradation

### Що можна покращити (майбутнє):

1. **Unit Tests** - додати тести для критичних модулів
2. **Analytics** - відслідковування user behavior
3. **Локалізація** - підтримка інших мов
4. **Performance** - профілювання та оптимізація
5. **Accessibility** - підтримка для гравців з особливими потребами

### Готові паттерни для повторного використання:

- ✅ UIManager pattern
- ✅ Cumulative UI pattern
- ✅ RemoteEvent protocol
- ✅ FSM для state management
- ✅ Async API calls з pcall()
- ✅ Module-based architecture

---

## 📝 Історія Змін

**2026-01-12**:
- ✅ Consolidated studio setup from RESTRUCTURE_CLIENT.md, ROBLOX_STUDIO_SETUP.md, SETUP_SCRIPT_SYNC.md
- ✅ Додано секцію "Налаштування Studio" з детальними Script Sync інструкціями
- ✅ Phase 2 & 3 завершено: progress bar (1200px, bold, 16px height, rounded corners)
- ✅ Error state з retry mechanism
- ✅ Видалено spinner, залишено тільки loading text

**2026-01-11**:
- ✅ Phase 1 (Server): 4-stage boot sequence implementation
- ✅ GameStateManager FSM з валідацією переходів
- ✅ ProfileService з DataStore
- ✅ Cumulative UI pattern
- ✅ StatusBar alignment fix
- ✅ Auto-restart boot sequence after LogOff

**Початкова версія**:
- Створено базу знань з успішних рішень EPIC 1

---

**Дата останнього оновлення**: 2026-01-12
**Автори**: KOSMICMAZER + Claude Sonnet 4.5
**Статус**: Active Development

---

*Цей документ буде постійно оновлюватись із новими успішними рішеннями та уроками.*
