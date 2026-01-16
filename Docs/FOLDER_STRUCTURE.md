# Структура Проєкту — Call of Relics: Orbital Silence

**Версія:** 1.1
**Дата:** 2026-01-14
**Статус:** Рекомендовано

---

## Огляд

Цей документ описує рекомендовану структуру папок для проєкту,
яка узгоджена з TDD (розділ 13.3) та вимогами Roblox Studio Script Sync.

---

## Критична Вимога: Script Sync

**ВАЖЛИВО:** Roblox Studio Script Sync працює **виключно всередині існуючих контейнерів** у DataModel.

Це означає:
1. Спочатку створити структуру папок **в Roblox Studio**
2. Налаштувати Script Sync
3. Тільки після цього синхронізація працюватиме

---

## Структура ServerScriptService

### Поточна структура (v0.7)

```
ServerScriptService/
├── Core/
│   ├── GameStateManager.lua      -- Координатор станів (v0.2)
│   ├── BootSequence.lua          -- 4-stage boot sequence (v0.4)
│   └── ServerBootstrap.server.lua -- Точка входу (v0.2)
│
├── Services/
│   ├── PlayerService.lua         -- Життєвий цикл гравця (v0.2)
│   ├── ProfileService.lua        -- DataStore профілі (v0.2)
│   ├── LocationService.lua       -- Завантаження локацій (v0.2)
│   ├── TransitionService.lua     -- Переходи Orbit↔Surface (v0.7) ← NEW
│   └── SeatService.lua           -- Керування сидіннями (v0.1)
│
├── Systems/
│   └── (підготовлено для майбутніх систем)
│
└── Setup/
    └── RemoteEventsSetup.server.lua -- RemoteEvents (v0.4)
```

### Майбутня структура

```
ServerScriptService/
├── Core/
│   ├── GameStateManager.lua
│   ├── BootSequence.lua
│   └── ServerBootstrap.server.lua
│
├── Services/
│   ├── PlayerService.lua
│   ├── ProfileService.lua
│   ├── LocationService.lua
│   ├── TransitionService.lua
│   ├── SeatService.lua
│   └── SaveService.lua           -- EPIC 2+
│
├── Systems/
│   ├── ScanSystem.lua            -- EPIC 4+
│   ├── CombatSystem.lua          -- EPIC 5+
│   └── ResourceSystem.lua        -- EPIC 5+
│
└── Setup/
    └── RemoteEventsSetup.server.lua
```

---

## Інші Контейнери DataModel

### ReplicatedStorage

```
ReplicatedStorage/
├── Game/                         -- Конфігурація гри
│   ├── GameConfig.lua            -- Основна конфігурація (v0.3)
│   ├── SeatConfig.lua            -- Конфігурація сидінь (v0.1)
│   └── TransitionConfig.lua      -- Конфігурація переходів (v0.1) ← NEW
│
├── Modules/                      -- Загальні модулі
│   └── (майбутнє)
│
└── RemoteEvents/                 -- Створюється автоматично Setup скриптом
    ├── StateChanged              -- Зміна стану гри
    ├── BootStageUpdate           -- Прогрес boot sequence
    ├── ConfirmGameStart          -- Підтвердження старту гри
    ├── RetryBootStage            -- Повтор стадії boot
    ├── SeatOccupied              -- Сів у сидіння
    ├── SeatVacated               -- Встав з сидіння
    ├── SeatActionRequest         -- Запит дії сидіння
    ├── SeatActionResponse        -- Відповідь дії сидіння
    ├── RequestLanding            -- Запит посадки ← NEW
    ├── RequestLiftoff            -- Запит підйому ← NEW
    ├── TransitionUpdate          -- Стан переходу ← NEW
    ├── TransitionLandingCamera   -- Дані камери посадки ← NEW
    └── AvailableLocationsResponse -- Список локацій ← NEW
```

### StarterPlayer/StarterPlayerScripts

```
StarterPlayer/StarterPlayerScripts/
├── Core/
│   ├── ClientBootstrap.client.lua -- Клієнтська ініціалізація (v0.3)
│   ├── SeatController.client.lua  -- Детекція сидінь (v0.1)
│   └── CameraController.lua       -- Керування камерою (v0.2)
│
├── UI/
│   ├── ScreenSaverUI.lua         -- Boot sequence UI (v0.5)
│   ├── StatusBarUI.lua           -- In-game status bar (v0.2)
│   ├── UIManager.lua             -- Координатор UI (v0.2)
│   ├── SeatUIManager.lua         -- Менеджер UI сидінь (v0.1)
│   ├── TransitionUI.lua          -- UI переходів (v0.4) ← NEW
│   └── SeatUI/                   -- Модулі UI для кожного сидіння
│       ├── PilotUI.lua           -- Пілотське крісло (v0.5)
│       ├── SurfaceScannerUI.lua  -- Сканер поверхні (v0.1)
│       ├── DeepSpaceScannerUI.lua -- Глибокий космос (v0.1)
│       ├── SystemsConsoleUI.lua  -- Консоль систем (v0.1)
│       └── PersonalTerminalUI.lua -- Особистий термінал (v0.1)
│
└── Systems/                      -- Майбутні клієнтські системи
    └── (порожня)
```

### ServerStorage

```
ServerStorage/
└── Planets/                      -- Контент планет (v0.7) ← EXPANDED
    └── Planet_1/                 -- Планета Біллі Рубін
        ├── Config.luau           -- Конфігурація планети
        ├── Orbit/                -- Орбітальна локація
        │   ├── Config.luau       -- Конфіг орбіти (з animationData)
        │   └── Workspace/        -- 3D об'єкти
        │       ├── Lighting/     -- Sky, Atmosphere, Effects
        │       ├── SpaceShip/    -- Модель корабля (PilotSeat, seats)
        │       └── Planet/       -- Модель планети (Surface, CloudLayers)
        │
        └── Surface/              -- Поверхневі локації
            ├── Location_1/       -- "Зелена долина"
            │   ├── Config.luau   -- Конфіг локації
            │   └── Workspace/    -- 3D об'єкти
            │       ├── Lighting/ -- Sky конфігурація
            │       └── Baseplate/ -- Поверхня з зонами
            │           ├── ExplorationZone   -- 80% території
            │           ├── LandingZone       -- 20% території
            │           ├── SpaceShipLandingPad -- Посадковий майданчик
            │           │   ├── LandingLights/    -- Сигнальні вогні
            │           │   └── LandingPadFrame/  -- Рамка та декор
            │           └── ZoneWalls/        -- Стіни з мітками
            │
            └── Location_2/       -- "Гірський хребет"
                ├── Config.luau
                └── Workspace/
```

---

## Інструкції: Налаштування в Roblox Studio

### Крок 1: Створення базової структури

#### ServerScriptService:
1. Відкрити проєкт у Roblox Studio
2. У Explorer знайти **ServerScriptService**
3. Створити папки:
   - Правий клік на ServerScriptService → Insert Object → Folder
   - Назвати: `Core`
   - Повторити для: `Services`, `Systems`, `Setup`

#### StarterPlayerScripts:
1. У Explorer знайти **StarterPlayer → StarterPlayerScripts**
2. Створити папки:
   - Правий клік на StarterPlayerScripts → Insert Object → Folder
   - Назвати: `Core`
   - Повторити для: `UI`, `Systems`

#### ReplicatedStorage:
1. У Explorer знайти **ReplicatedStorage**
2. Створити папки:
   - Правий клік на ReplicatedStorage → Insert Object → Folder
   - Назвати: `Game`
   - Повторити для: `Modules`
3. **RemoteEvents** папка створюється автоматично скриптом RemoteEventsSetup

### Крок 2: Переміщення існуючих скриптів

**ServerScriptService/Core:**
- `GameStateManager.lua`
- `BootSequence.lua`
- `ServerBootstrap.server.lua`

**ServerScriptService/Services:**
- `PlayerService.lua`
- `ProfileService.lua`

**ServerScriptService/Setup:**
- `RemoteEventsSetup.server.lua`

**StarterPlayerScripts/Core:**
- `ClientBootstrap.client.lua`

**StarterPlayerScripts/UI:**
- `ScreenSaverUI.lua`
- `UIManager.lua`

**ReplicatedStorage/Game:**
- `GameConfig.lua`

**Systems папки:**
- Залишити порожніми (для майбутніх систем)

### Крок 3: Налаштування Script Sync

1. У Roblox Studio: **View → Script Sync**
2. Вибрати папку проєкту: `d:\Code\Roblox\CallOfRelics`
3. Увімкнути синхронізацію
4. Перевірити, що зміни синхронізуються в обидва боки

### Крок 4: Перевірка

**Тест 1: Studio → Файлова система**
1. Створити тестовий скрипт у Studio
2. Перевірити, що він з'явився у файловій системі

**Тест 2: Файлова система → Studio**
1. Змінити коментар у `GameStateManager.lua` через VSCode
2. Перевірити, що зміна відобразилася у Studio

---

## Принципи Організації (з TDD)

### Core/ — Архітектурне ядро

**Призначення:**
- Координація глобальних станів
- Bootstrap гри
- Стабільне ядро, що рідко змінюється

**Правила:**
- Не залежить від контенту
- Змінюється лише при архітектурних змінах
- Містить єдиний координатор станів (TDD 2.5)

**Файли:**
- `GameStateManager.lua` — координатор станів
- `ServerBootstrap.server.lua` — точка входу

---

### Services/ — Довготривалі сервіси

**Призначення:**
- Координація між системами
- Управління ресурсами
- Надання контрактів

**Правила (TDD 3.2):**
- "Має довготривале існування"
- "Ініціалізується під час boot"
- "Є єдиним для сесії гравця"
- Надає чітко визначений контракт

**Поточні файли:**
- `PlayerService.lua` — керування гравцями

**Майбутні файли:**
- `SaveService.lua` — збереження/відновлення
- `TeleportService.lua` — переміщення між контекстами
- `LocationService.lua` — керування локаціями

---

### Systems/ — Функціональні системи

**Призначення:**
- Реалізація ігрових механік
- Реакція на зміни станів
- Ізольована функціональність

**Правила (TDD 3.1):**
- "Відповідає за одну функціональну область"
- "Реагує на зміни станів"
- "Не ініціює переходи станів напряму"
- Працює в межах дозволеного контексту

**Майбутні файли:**
- `ScanSystem.lua` — система сканування планет
- `CombatSystem.lua` — бойова система
- `ResourceSystem.lua` — керування ресурсами

---

### Setup/ — Ініціалізація інфраструктури

**Призначення:**
- Одноразові ініціалізаційні скрипти
- Створення RemoteEvents
- Підготовка інфраструктури

**Правила:**
- Виконуються до основного boot
- Не містять ігрової логіки
- Створюють необхідні об'єкти

**Поточні файли:**
- `RemoteEventsSetup.server.lua` — створення RemoteEvents

---

## Правила Додавання Нових Модулів

### Перед створенням нового модуля:

1. **Визначити тип:**
   - Core? (рідко, лише архітектурні зміни)
   - Service? (координація, довготривале існування)
   - System? (ігрова механіка, реакція на стани)
   - Setup? (інфраструктура)

2. **Вибрати правильну папку:**
   - Створити скрипт у відповідній папці
   - Дотримуватися стандарту KOSMICMAZER (TDD 11.8)

3. **Синхронізація:**
   - Якщо створюється в Studio → автоматично з'явиться у файловій системі
   - Якщо створюється у VSCode → автоматично з'явиться в Studio

---

## Переваги Цієї Структури

✅ **Чітке розмежування відповідальностей**
- Легко зрозуміти, де що знаходиться

✅ **Масштабованість**
- Додавання нових модулів не вимагає реорганізації

✅ **Відповідність TDD**
- Структура відображає архітектурні принципи

✅ **Запобігання "монолітним скриптам"**
- Природний поділ на малі, зрозумілі модулі

✅ **Сумісність з Script Sync**
- Структура працює з обмеженнями Roblox Studio

---

## Посилання

- **TDD Розділ 3** — Розмежування систем, сервісів, контенту
- **TDD Розділ 11** — Стандарти логування та діагностики
- **TDD Розділ 13.3** — Вимоги до структури проєкту
- **EPIC1_IMPLEMENTATION.md** — Реалізація EPIC 1

---

## ChangeLog

- **1.1** — Оновлення структури v0.7 (2026-01-14)
  - Додано TransitionService.lua до Services/
  - Додано TransitionConfig.lua до ReplicatedStorage/Game/
  - Додано TransitionUI.lua до UI/
  - Оновлено PilotUI.lua (v0.5) - context detection
  - Розширено ServerStorage/Planets/ з повною структурою
  - Додано RemoteEvents для Transition System
  - Документовано структуру Location_1 з зонами та посадковим майданчиком

- **1.0** — Початкова версія структури (2026-01-11)
  - Створено папки Core, Services, Systems, Setup
  - Переміщено існуючі скрипти
  - Додано рекомендації до TDD

---

**Статус:** Готово до синхронізації з Roblox Studio
