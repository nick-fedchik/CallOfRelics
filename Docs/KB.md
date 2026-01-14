# Knowledge Base - Call of Relics
> База знань успішних рішень, ефективних алгоритмів та перевірених практик

**Версія**: 0.2
**Остання оновлення**: 2026-01-14

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
8. [Epic 1 - Повна Імплементація](#epic-1---повна-імплементація)
9. [Seat Control System](#seat-control-system)
10. [Planet Location System](#planet-location-system)
11. [Transition System](#transition-system)

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

## Epic 1 - Повна Імплементація

### Огляд

**Status:** ✅ Complete
**Version:** 0.5
**Date:** 2026-01-12

Epic 1 встановлює фундамент архітектури гри:
- Повний lifecycle management
- Координація глобальних станів
- 4-stage boot sequence з progress tracking
- Error handling з retry mechanism
- Player LogOn/LogOff flow

### User Stories (Реалізовано)

✅ Гравець бачить ScreenSaver з прогресом завантаження перед входом
✅ Гравець може увійти та почати нову сесію
✅ Гравець може вийти та повернутись до ScreenSaver
✅ Гра коректно обробляє несподівані відключення
✅ Гра ініціалізується в чистому детермінованому стані

### Архітектура

#### Server Components

**1. GameStateManager.lua** (Core)
- Single source of truth для game state
- Manages: `LoggedOff`, `Initializing`, `InGame`
- Validates state transitions
- Broadcasts state changes

**2. BootSequence.lua** (Core)
- 4-stage server-driven boot sequence
- Dynamic progress calculation (25%, 50%, 75%, 100%)
- Error handling with retry support
- Stage 1: Game Configuration
- Stage 2: Player Information
- Stage 3: Profile Loading (with error state)
- Stage 4: Ready State

**3. ServerBootstrap.server.lua** (Core)
- Main server entry point
- Initializes GameStateManager
- Initializes PlayerService
- Handles boot failures safely

**4. PlayerService.lua** (Services)
- Player lifecycle management
- LogOn/LogOff processing
- Single-player enforcement
- Safe disconnect handling

**5. ProfileService.lua** (Services)
- DataStore integration
- Player profile management
- New/returning player detection
- Graceful degradation without DataStore

**6. RemoteEventsSetup.server.lua** (Setup)
- Creates RemoteEvents infrastructure
- Events: `StateChanged`, `BootStageUpdate`, `ConfirmGameStart`, `EnterGame`, `LogOff`, `StartGame`, `RetryBootStage`

#### Client Components

**7. ClientBootstrap.client.lua** (Core)
- Main client entry point
- Initializes ScreenSaverUI
- Initializes StatusBarUI
- Initializes UIManager
- Disables default Roblox UI

**8. ScreenSaverUI.lua** (UI) - v0.5
- Progressive/cumulative boot UI
- 1200px wide progress bar (bold, 16px height, rounded)
- Server-driven progress tracking
- Error state with retry button
- 1 second pause at 100% before button
- Removed spinner (clean text only)
- Removed "Готовність 100%" text

**9. StatusBarUI.lua** (UI)
- In-game status bar
- Player name, game state, version info
- Right-aligned elements

**10. UIManager.lua** (UI)
- Coordinates UI state transitions
- Listens to server state changes
- Shows/hides UI based on game state

### Game Flow

#### Boot Sequence (4 Stages)

```
Stage 1 (25%): Game Configuration
├── Game name, subtitle, version
└── Progress bar появляється

Stage 2 (50%): Player Information
├── Player avatar завантажується
├── Player name відображається
└── Progress → 50%

Stage 3 (75%): Profile Loading
├── DataStore read
├── New/returning player detection
├── Success → progress 75% + "Ініціалізація експедиції..."
└── Error → retry button + error message

Stage 4 (100%): Ready State
├── Progress → 100%
├── 1 second pause
├── Progress bar зникає
└── "Почати гру" button з'являється
```

#### LogOn Flow

```
1. Player → Space/Click on ScreenSaver
2. ScreenSaverUI → ConfirmGameStart → Server
3. Server → State: LoggedOff → Initializing
4. Server → BootSequence (4 stages)
5. Server → State: Initializing → InGame
6. Client → Hide ScreenSaver, Show StatusBar
```

#### LogOff Flow

```
1. Player → LogOff (via StatusBar або disconnect)
2. Server → State: InGame → LoggedOff
3. Server → ScreenSaverUI.Reset() → Client
4. Client → Show ScreenSaver
5. Ready for next player
```

### State Machine

```
┌─────────────┐
│  LoggedOff  │ ◄──────────────────┐
└──────┬──────┘                    │
       │ LogOn                     │
       ▼                           │
┌──────────────┐                   │
│ Initializing │                   │
│ (4 stages)   │                   │
└──────┬───────┘                   │
       │ Boot Complete      LogOff │
       ▼                           │
┌─────────────┐                    │
│   InGame    │────────────────────┘
└─────────────┘
```

**Allowed Transitions:**
- `LoggedOff` → `Initializing` ✅
- `Initializing` → `InGame` ✅
- `Initializing` → `LoggedOff` ✅ (on error)
- `InGame` → `LoggedOff` ✅

**Forbidden Transitions:**
- `LoggedOff` → `InGame` ❌ (must go through Initializing)
- `InGame` → `Initializing` ❌ (would break session)

### Technical Highlights

#### Cumulative UI Pattern
```lua
-- Stage 1: Game info + Progress bar (25%)
-- Stage 2: + Player avatar + Progress (50%)
-- Stage 3: + Loading text + Progress (75%)
-- Stage 4: Progress (100%) → pause → button
-- NO flickering, NO black screens
```

#### Server-Driven Progress
```lua
local function CalculateStageProgress(stageNumber)
    local totalStages = #GameConfig.BootStages
    return math.floor((stageNumber / totalStages) * 100)
end

-- Easy to extend: додати 5-й stage = автоматично 20% per stage
```

#### Error State with Retry
```lua
-- Stage 3 може fail (DataStore issues)
if not success then
    BootStageUpdate:FireClient(player, 3, {
        success = false,
        errorMessage = "Не вдалося завантажити профіль",
        canRetry = true,
        progress = 75
    })
end

-- Retry button → RetryBootStage:FireServer(3)
```

#### Graceful Degradation
```lua
-- ProfileService: якщо DataStore unavailable
if not datastoreEnabled then
    warn("DataStore unavailable - using temporary profile")
    return true, CreateTemporaryProfile(), true
end
```

### Files Structure

```
ServerScriptService/
├── Core/
│   ├── GameStateManager.lua (v0.2)
│   ├── BootSequence.lua (v0.3)
│   └── ServerBootstrap.server.lua (v0.2)
├── Services/
│   ├── PlayerService.lua (v0.2)
│   └── ProfileService.lua (v0.2)
└── Setup/
    └── RemoteEventsSetup.server.lua (v0.3)

StarterPlayer/StarterPlayerScripts/
├── Core/
│   └── ClientBootstrap.client.lua (v0.3)
└── UI/
    ├── ScreenSaverUI.lua (v0.5) ⭐ NEW
    ├── StatusBarUI.lua (v0.2)
    └── UIManager.lua (v0.2)

ReplicatedStorage/
└── Game/
    └── GameConfig.lua (v0.3)
```

### Testing Checklist

#### Manual Testing ✅

- [x] Server boots successfully
- [x] 4-stage boot sequence displays correctly
- [x] Progress bar: 0% → 25% → 50% → 75% → 100%
- [x] Progress bar bold (16px height) and visible
- [x] 1 second pause after 100% works
- [x] "Почати гру" button appears after pause
- [x] Avatar loads correctly
- [x] State transitions logged correctly
- [x] Player disconnect triggers LogOff
- [x] ScreenSaver resets on LogOff
- [x] StatusBar shows during InGame
- [x] Second player rejected (single-player)

#### Error State Testing (Partial)

- [x] Error UI created with proper transparency
- [ ] Error state displays correctly (needs more testing)
- [ ] Retry button works (needs testing)

### Compliance

- [x] All scripts have standardized headers
- [x] Version numbers in all modules
- [x] Logging follows standard format
- [x] State machine follows FSM pattern
- [x] Error handling with pcall()
- [x] Single-player constraint enforced
- [x] Server authoritative (client read-only)
- [x] Clean initialization sequence
- [x] No silent failures

### Backlog

- [ ] **Перейменувати сидіння в моделі SpaceShip** - В моделі сидіння називаються `Seat`, потрібно перейменувати на `Seat1`, `Seat2`, `Seat3`, `Seat4` щоб система Seat Control розпізнавала їх і показувала UI

### Next Steps (Epic 2+)

1. **Full error state testing** - Verify error UI and retry mechanism
2. **Space Ship Context** - Ship location, spawn points
3. **Contextual States** - World context, Orbital context
4. **Enhanced UI** - LogOff button, context indicators
5. **Unit Tests** - Critical module coverage

---

## 📝 Історія Змін

**2026-01-14** (v0.2):
- ✅ **Transition System** - повна система переходів Orbit ↔ Surface
- ✅ TransitionService.lua (v0.7) — координація landing/liftoff sequences
- ✅ TransitionUI.lua (v0.4) — loading screens, landing camera
- ✅ TransitionConfig.lua — конфігурація анімацій та повідомлень
- ✅ DisplayName system — локалізовані назви для UI
- ✅ Lazy-loaded StatusBarUI integration у TransitionUI
- ✅ Оптимізований Boot Sequence — завантаження перенесено в TransitionService.StartGameSequence()
- ✅ PilotUI context detection (Orbit/Surface)
- ✅ **Planet Location System** - документація структури локацій
- ✅ Оновлено Config.luau з повною структурою Location1
- ✅ ZoneWalls: LeftWall, RightWall, NearWall, FarWall з SurfaceGui labels
- ✅ ExplorationZone (80%) та LandingZone (20%) з різними матеріалами
- ✅ SpaceShipLandingPad з LandingLights та LandingPadFrame
- ✅ Анімовані сигнальні вогні та освітлення рамки

**2026-01-13**:
- ✅ **Seat Control System** - повна система керування сидіннями корабля
- ✅ 5 сидінь: PilotSeat, SurfaceScannerSeat, DeepSpaceScannerSeat, SystemsConsoleSeat, PersonalTerminalSeat
- ✅ SeatConfig.lua - конфігурація сидінь з FOV, display names, functionality
- ✅ SeatService.lua - серверна логіка керування сидіннями
- ✅ SeatController.client.lua - клієнтський детектор сидінь
- ✅ SeatUIManager.lua - менеджер UI модулів для кожного сидіння
- ✅ 5 UI модулів: PilotUI, SurfaceScannerUI, DeepSpaceScannerUI, SystemsConsoleUI, PersonalTerminalUI
- ✅ CameraController - інтеграція з SeatConfig для FOV per seat
- ✅ RemoteEvents: SeatOccupied, SeatVacated, SeatActionRequest, SeatActionResponse
- ✅ Fix: Player spawn in PilotSeat з ModelStreamingMode.Persistent
- ✅ Fix: Ship anchoring для запобігання падінню в low gravity
- ✅ Fix: VehicleSeat MaxSpeed=0, TurnSpeed=0 для стаціонарного корабля

**2026-01-12**:
- ✅ **EPIC 1 COMPLETE**: Merged ScreenSaverUI-dev → main (v0.5)
- ✅ Consolidated EPIC1_IMPLEMENTATION.md → KB.md (section 8)
- ✅ Consolidated studio setup from RESTRUCTURE_CLIENT.md, ROBLOX_STUDIO_SETUP.md, SETUP_SCRIPT_SYNC.md
- ✅ Додано секцію "Налаштування Studio" з детальними Script Sync інструкціями
- ✅ Phase 2 & 3 завершено: progress bar (1200px, bold, 16px height, rounded corners)
- ✅ Error state з retry mechanism
- ✅ Видалено spinner, залишено тільки loading text
- ✅ Cleaned up dev version files

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

## Seat Control System

### Огляд

**Status:** ✅ Implemented
**Version:** 0.1
**Date:** 2026-01-13

Система керування сидіннями корабля. Коли гравець сідає в сидіння, відкривається відповідний UI для керування пристроєм.

### 5 Сидінь на Кораблі

| Seat Name | Type | Display Name | UI Module | Функціонал |
|-----------|------|--------------|-----------|------------|
| PilotSeat | VehicleSeat | Пілотське крісло | PilotUI | Керування кораблем |
| SurfaceScannerSeat | Seat | Сканер поверхні | SurfaceScannerUI | Сканування поверхні планети |
| DeepSpaceScannerSeat | Seat | Сканер глибокого космосу | DeepSpaceScannerUI | Сканування далекого космосу |
| SystemsConsoleSeat | Seat | Консоль систем | SystemsConsoleUI | Керування щитами, енергією, життєзабезпеченням |
| PersonalTerminalSeat | Seat | Особистий термінал | PersonalTerminalUI | Інвентар, журнал, місії |

### Архітектура

```
Player sits in seat
       ↓
[Client] CameraController detects Humanoid.Seated
       ↓
[Client] SeatController identifies seat type from SeatConfig
       ↓
[Client] SeatController fires SeatOccupied to Server
       ↓
[Server] SeatService validates and records seat state
       ↓
[Client] SeatUIManager shows seat-specific UI
       ↓
Player stands up → reverse flow, UI hidden
```

### Файли Системи

#### Configuration
- `ReplicatedStorage/Game/SeatConfig.lua` - конфігурація всіх сидінь

#### Server
- `ServerScriptService/Services/SeatService.lua` - серверний сервіс

#### Client
- `StarterPlayer/StarterPlayerScripts/Core/SeatController.client.lua` - детекція сидінь
- `StarterPlayer/StarterPlayerScripts/UI/SeatUIManager.lua` - менеджер UI

#### UI Modules
- `StarterPlayer/StarterPlayerScripts/UI/SeatUI/PilotUI.lua`
- `StarterPlayer/StarterPlayerScripts/UI/SeatUI/SurfaceScannerUI.lua`
- `StarterPlayer/StarterPlayerScripts/UI/SeatUI/DeepSpaceScannerUI.lua`
- `StarterPlayer/StarterPlayerScripts/UI/SeatUI/SystemsConsoleUI.lua`
- `StarterPlayer/StarterPlayerScripts/UI/SeatUI/PersonalTerminalUI.lua`

### RemoteEvents

| Event | Direction | Purpose |
|-------|-----------|---------|
| SeatOccupied | Client → Server | Нотифікація про сідання |
| SeatVacated | Client → Server | Нотифікація про вставання |
| SeatActionRequest | Client → Server | Запит на дію (сканування, тощо) |
| SeatActionResponse | Server → Client | Відповідь на дію |

### SeatConfig API

```lua
-- Отримати повну конфігурацію сидіння
local config = SeatConfig.GetSeatConfig("PilotSeat")
-- Returns: {displayName, uiModule, seatType, camera, functionality}

-- Отримати налаштування камери
local cameraSettings = SeatConfig.GetCameraSettings("PilotSeat")
-- Returns: {mode, fov, minZoom, maxZoom}

-- Отримати назву UI модуля
local uiModule = SeatConfig.GetUIModule("PilotSeat")
-- Returns: "PilotUI"

-- Перевірити чи сидіння відоме
local isKnown = SeatConfig.IsSeatKnown("PilotSeat")
-- Returns: true/false
```

### Розширюваність

#### Додати Нове Сидіння

1. Додати запис в `SeatConfig.Seats`:
```lua
NewSeat = {
    displayName = "Нове сидіння",
    uiModule = "NewSeatUI",
    seatType = "Seat",
    camera = { fov = 60, minZoom = 2, maxZoom = 20 },
    functionality = { someFeature = true }
}
```

2. Створити UI модуль `SeatUI/NewSeatUI.lua` з методами:
   - `Initialize()` - створити UI
   - `Show(seatConfig)` - показати UI
   - `Hide()` - сховати UI

3. Додати сидіння в модель SpaceShip з відповідним ім'ям

#### Додати Нову Дію для Сидіння

1. В UI модулі:
```lua
SeatActionRequest:FireServer("SeatName", "ActionName", {data})
```

2. На сервері:
```lua
SeatService.RegisterActionHandler("SeatName", "ActionName", function(player, data)
    -- Handle action
    return {success = true, result = ...}
end)
```

3. В UI обробити відповідь:
```lua
SeatActionResponse.OnClientEvent:Connect(function(seatName, action, result)
    if seatName == "SeatName" and action == "ActionName" then
        -- Handle result
    end
end)
```

### Player Spawn в PilotSeat

#### Проблема: Моделі зникають після копіювання

**Рішення:** ModelStreamingMode.Persistent
```lua
if clone:IsA("Model") then
    clone.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
end
```

#### Проблема: Корабель падає в низькій гравітації

**Рішення:** Anchoring всіх частин (крім сидінь)
```lua
for _, part in ipairs(clone:GetDescendants()) do
    if part:IsA("BasePart") and not part:IsA("Seat") and not part:IsA("VehicleSeat") then
        part.Anchored = true
    end
end
```

#### Проблема: Корабель рухається при натисканні WASD

**Рішення:** Вимкнути рух VehicleSeat
```lua
if spawnPoint:IsA("VehicleSeat") then
    spawnPoint.Disabled = false
    spawnPoint.MaxSpeed = 0  -- Корабель стоїть на орбіті
    spawnPoint.TurnSpeed = 0
end
```

### Camera per Seat

CameraController автоматично застосовує FOV з SeatConfig:

```lua
local cameraSettings = SeatConfig.GetCameraSettings(seat.Name)
if cameraSettings and cameraSettings.fov then
    camera.FieldOfView = cameraSettings.fov
end
```

При вставанні FOV скидається до 70 (default).

### Testing Checklist

- [ ] SeatConfig завантажується без помилок
- [ ] RemoteEvents створені (SeatOccupied, SeatVacated, SeatActionRequest, SeatActionResponse)
- [ ] SeatService ініціалізується
- [ ] SeatController детектить сідання в PilotSeat при спавні
- [ ] PilotUI показується автоматично при спавні
- [ ] UI ховається при вставанні
- [ ] Сідання в інші сидіння показує правильний UI
- [ ] Камера застосовує правильний FOV для кожного сидіння

**Примітка:** Потрібно перейменувати PassengerSeat1-4 в моделі SpaceShip на:
- SurfaceScannerSeat
- DeepSpaceScannerSeat
- SystemsConsoleSeat
- PersonalTerminalSeat

---

**Дата останнього оновлення**: 2026-01-14
**Автори**: KOSMICMAZER + Claude Opus 4.5
**Статус**: Active Development

---

## Planet Location System

### Огляд

Система організації планетарних локацій. Кожна локація зберігається в `ServerStorage/Planets/` та містить власну конфігурацію, 3D об'єкти та скрипти.

### Структура Planet_1/Surface/Location1

```
ServerStorage/Planets/Planet_1/Surface/Location1/
├── Config.luau              # Конфігурація локації
├── Workspace/               # 3D об'єкти
│   ├── Lighting/
│   │   └── Sky              # Sky конфігурація
│   └── Baseplate/           # Основна поверхня (2048x16x2048)
│       ├── Texture          # Текстура поверхні
│       ├── ZoneWalls/       # Стіни з мітками зон
│       │   ├── LeftWall     # Ліва стіна
│       │   ├── RightWall    # Права стіна
│       │   ├── NearWall     # Ближня стіна (біля Landing Zone)
│       │   └── FarWall      # Дальня стіна
│       ├── ExplorationZone  # Зона дослідження (80%)
│       ├── LandingZone/     # Зона посадки (20%)
│       │   └── Texture
│       └── SpaceShipLandingPad/  # Посадковий майданчик
│           ├── LandingLights/    # Сигнальні вогні
│           │   ├── FrontLeftLight
│           │   ├── FrontRightLight
│           │   ├── BackLeftLight
│           │   └── BackRightLight
│           └── LandingPadFrame/  # Рамка та декор
│               ├── LeftFrame, RightFrame, FrontFrame, BackFrame
│               ├── FrontLeftCorner, FrontRightCorner
│               ├── BackLeftCorner, BackRightCorner
│               └── Stripe1, Stripe2, Stripe3
├── ServerScriptService/     # Серверні скрипти локації
├── ReplicatedStorage/       # Спільне сховище
└── StarterPlayer/           # Player скрипти
    ├── StarterCharacterScript/
    └── StarterPlayerScript/
```

### Zone Configuration

| Зона | Розмір | Покриття | Матеріал | Колір | Призначення |
|------|--------|----------|----------|-------|-------------|
| ExplorationZone | 2048×16×1638.4 | 80% | Grass | Bright green | Дослідження гравцем |
| LandingZone | 2048×16×409.6 | 20% | Concrete | Bright blue | Посадка корабля |
| SpaceShipLandingPad | 120×2×177.6 | - | Metal | Dark stone grey | Точка посадки |

### SpaceShipLandingPad Features

**Візуальні елементи:**
- 4 кутові сигнальні вогні (оранжеві, блимаючі)
- Cyan рамка з PointLight по периметру
- 4 жовті кутові маркери з PointLight
- 3 білі декоративні смуги

**Розміри:**
- Розмір: 120×2×177.6 studs
- На 20% більше за розміри корабля для безпечної посадки

### Config.luau API

```lua
local Config = require(path.to.Config)

-- Отримати структуру локації
local structure = Config.getStructure()

-- Отримати налаштування
local settings = Config.getSettings()
-- settings.gravity, settings.atmosphereEnabled, settings.maxPlayers, etc.

-- Отримати шлях до asset
local baseplateAsset = Config.getAsset("baseplate")
local landingPadAsset = Config.getAsset("spaceshipLandingPad")

-- Знайти об'єкт за ім'ям
local landingZone = Config.findObject("LandingZone")

-- Отримати metadata
local metadata = Config.getMetadata()
-- metadata.locationId, metadata.biome, metadata.size, metadata.features
```

### Location Settings

```lua
settings = {
    gravity = Vector3.new(0, -196.2, 0),  -- Стандартна гравітація
    atmosphereEnabled = true,
    lightingPreset = "Surface",
    maxPlayers = 16,
    respawnTime = 5,
    vehicleEnabled = false,
    combatEnabled = false,
    environmentType = "Surface"
}
```

### Metadata

```lua
metadata = {
    locationId = "planet1_surface_location1",
    description = "Primary surface location on Planet 1",
    biome = "Grassland",
    size = Vector3.new(2048, 16, 2048),
    zoneConfiguration = {
        landingZone = { coverage = "20%", position = "Near wall" },
        explorationZone = { coverage = "80%", position = "Central area" }
    },
    features = {
        "Zone boundary walls with labels",
        "Dedicated spaceship landing pad",
        "Animated signal lights",
        "Distinct zone materials and colors"
    },
    spaceshipCompatibility = {
        supported = true,
        landingPadSize = "120 x 177.6 studs",
        clearance = "20% larger than spaceship",
        visualGuidance = "Blinking lights and illuminated frame"
    }
}
```

---

## Transition System

### Огляд

**Status:** ✅ Implemented
**Version:** 0.7
**Date:** 2026-01-14

Система переходів між локаціями (Orbit ↔ Surface). Включає анімації, заставки, та управління камерою.

### Архітектура

```
┌─────────────────────────────────────────────────────────────┐
│                      TRANSITION FLOW                        │
├─────────────────────────────────────────────────────────────┤
│  Orbit (PilotUI) → Landing → Surface (PilotUI) → Liftoff    │
│         │            ↓              │               ↓       │
│         │       [Loading]           │          [Loading]    │
│         │            ↓              │               ↓       │
│         └───────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### Ключові Компоненти

#### Server
- **TransitionService.lua** — координатор переходів
  - `StartGameSequence(player)` — початок гри (Orbit spawn)
  - `StartLandingSequence(player, locationId)` — посадка на поверхню
  - `StartLiftoffSequence(player)` — підйом на орбіту
  - `GetAvailableLocations(player)` — список доступних локацій

#### Client
- **TransitionUI.lua** — UI анімацій та заставок
  - `ShowLoadingScreen(message)` — заставка завантаження
  - `ShowLandingCamera(data)` — камера посадки
  - `Hide(restoreCamera)` — приховати та відновити камеру

#### Configuration
- **TransitionConfig.lua** — конфігурація часових параметрів та повідомлень

### RemoteEvents

| Event | Direction | Purpose |
|-------|-----------|---------|
| RequestLanding | Client → Server | Запит на посадку |
| RequestLiftoff | Client → Server | Запит на підйом |
| TransitionUpdate | Server → Client | Стан переходу |
| TransitionLandingCamera | Server → Client | Дані камери посадки |
| AvailableLocationsResponse | Server → Client | Список локацій |

### Transition States

```lua
States = {
    Idle = "idle",
    GameStart = "gamestart",      -- Початок гри
    Departure = "departure",      -- Відліт з орбіти
    Loading = "loading",          -- Заставка
    Approach = "approach",        -- Наближення
    Landing = "landing",          -- Посадка
    Complete = "complete",        -- Завершено
    Liftoff = "liftoff",          -- Підйом
    Ascending = "ascending",      -- Набір висоти
}
```

### Landing Sequence Flow

```
1. [PilotUI] Гравець вибирає локацію
       ↓
2. [Client] RequestLanding → Server
       ↓
3. [Server] TransitionUpdate("loading", {message})
       ↓
4. [Client] ShowLoadingScreen("Приземлення на...")
       ↓
5. [Server] UnloadLocation → LoadLocation
       ↓
6. [Server] SpawnShipAbovePad → GetLandingCameraData
       ↓
7. [Server] TransitionLandingCamera → Client
       ↓
8. [Client] ShowLandingCamera (scriptable camera)
       ↓
9. [Server] AnimateShipLanding (TweenService)
       ↓
10. [Server] TransitionUpdate("complete", {displayNames})
       ↓
11. [Client] RestoreCamera + UpdateStatusBar
```

### Технічні Рішення

#### ✅ Scriptable Camera для Landing

**Проблема:** Стандартна камера Roblox слідує за персонажем.

**Рішення:** Тимчасова scriptable камера під час посадки:

```lua
-- TransitionUI.lua
function TransitionUI.ShowLandingCamera(data)
    local camera = workspace.CurrentCamera

    -- Зберегти оригінальний стан
    originalCameraMode = camera.CameraType
    originalCameraSubject = camera.CameraSubject

    -- Переключити на scriptable
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = CFrame.lookAt(data.cameraPosition, data.lookAtPosition)
end

function TransitionUI.RestoreCamera()
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom

    local player = Players.LocalPlayer
    if player.Character then
        camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
    end
end
```

**Переваги:**
- Кінематографічний ефект під час посадки
- Гравець бачить корабель зверху
- Плавне відновлення після завершення

#### ✅ DisplayName System для Локалізації

**Проблема:** Технічні ID (Planet_1, Location1) не підходять для UI.

**Рішення:** `displayName` у кожному Config.luau:

```lua
-- Planet1 Config
displayName = "Kepler-442b"

-- Orbit Config
displayName = "Орбіта"

-- Location1 Config
displayName = "Зелена долина"
```

**Використання:**
```lua
-- TransitionService відправляє displayName у Complete state
transitionUpdate:FireClient(player, States.Complete, {
    planetDisplayName = "Kepler-442b",
    locationDisplayName = "Орбіта"
})

-- TransitionUI оновлює StatusBar
StatusBarUI.SetPlanet(data.planetDisplayName)
StatusBarUI.SetLocation(data.locationDisplayName)
```

#### ✅ Lazy Loading UI Modules

**Проблема:** Модулі UI можуть бути не ініціалізовані при першому виклику.

**Рішення:** Lazy-loaded references:

```lua
local StatusBarUI = nil

local function GetStatusBarUI()
    if not StatusBarUI then
        local UI = script.Parent
        local statusBarModule = UI:FindFirstChild("StatusBarUI")
        if statusBarModule then
            StatusBarUI = require(statusBarModule)
        end
    end
    return StatusBarUI
end
```

**Переваги:**
- Уникнення circular dependencies
- Робота з ще не завантаженими модулями
- Graceful degradation якщо модуль відсутній

#### ✅ Оптимізований Boot Sequence

**Проблема:** BootSequence Stage4 завантажував локацію, що сповільнювало відображення кнопки "Почати гру".

**Рішення:** Перенести завантаження локації в TransitionService:

```lua
-- BootSequence Stage4 - тільки валідація assets
local planetFolder = ServerStorage.Planets:FindFirstChild(profile.currentPlanet)
if planetFolder and planetFolder:FindFirstChild("Orbit") then
    print("✓ Assets validated")
end

-- TransitionService.StartGameSequence() - реальне завантаження
function TransitionService.StartGameSequence(player)
    -- 1. Показати loading screen
    -- 2. Завантажити Orbit
    -- 3. Spawn корабель
    -- 4. Посадити гравця в PilotSeat
    -- 5. Завершити перехід
end
```

**Переваги:**
- Швидше відображення кнопки "Почати гру"
- Loading screen показує прогрес завантаження
- Чітке розділення валідації та завантаження

### PilotUI Context Detection

```lua
-- Визначення контексту на основі поточної локації
function PilotUI.DetectContext()
    local LocationService = require(Services:WaitForChild("LocationService"))
    local currentLocation = LocationService.GetCurrentLocation(player)

    if currentLocation and currentLocation.locationType == "Surface" then
        return TransitionConfig.Contexts.Surface  -- Показати "На орбіту"
    else
        return TransitionConfig.Contexts.Orbit    -- Показати список локацій
    end
end
```

### Landing Camera Configuration

```lua
-- TransitionConfig.lua
LandingCameraOffset = Vector3.new(-100, 150, -50),  -- Позиція камери відносно pad
LandingCameraLookAt = Vector3.new(0, 0, 0),         -- Точка фокусу

ShipSpawnHeight = 500,    -- Висота появи корабля
ShipLandingHeight = 25,   -- Фінальна висота (центр корабля)
LandingDuration = 4.0,    -- Тривалість анімації посадки
```

### Testing Checklist

- [x] GameStart завантажує Orbit і спавнить гравця в PilotSeat
- [x] PilotUI показує список локацій на орбіті
- [x] Клік на локацію запускає посадку
- [x] Loading screen показує повідомлення
- [x] Камера переключається на посадковий вид
- [x] Корабель анімовано приземляється
- [x] Камера відновлюється після посадки
- [x] StatusBar показує displayName планети та локації
- [x] PilotUI на поверхні показує кнопку "На орбіту"
- [x] Liftoff працює (зворотній процес)

### Файлова Структура

```
ServerScriptService/Services/
└── TransitionService.lua (v0.7)

StarterPlayer/StarterPlayerScripts/UI/
├── TransitionUI.lua (v0.4)
└── SeatUI/
    └── PilotUI.lua (v0.5)

ReplicatedStorage/Game/
└── TransitionConfig.lua (v0.1)
```

---

*Цей документ буде постійно оновлюватись із новими успішними рішеннями та уроками.*
