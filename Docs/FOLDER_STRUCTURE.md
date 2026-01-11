# Структура Проєкту — Call of Relics: Orbital Silence

**Версія:** 1.0
**Дата:** 2026-01-11
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

### Поточна структура (файлова система)

```
ServerScriptService/
├── Core/
│   ├── GameStateManager.lua
│   ├── BootSequence.lua          -- EPIC 1
│   └── ServerBootstrap.server.lua
│
├── Services/
│   ├── PlayerService.lua
│   └── ProfileService.lua        -- EPIC 1
│
├── Systems/
│   └── (порожня, підготовлена для майбутнього)
│
└── Setup/
    └── RemoteEventsSetup.server.lua
```

### Майбутня структура (після розширення)

```
ServerScriptService/
├── Core/
│   ├── GameStateManager.lua
│   └── ServerBootstrap.server.lua
│
├── Services/
│   ├── PlayerService.lua
│   ├── SaveService.lua           -- EPIC 2+
│   ├── TeleportService.lua       -- EPIC 3+
│   └── LocationService.lua       -- EPIC 3+
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
├── Game/                 -- Конфігурація гри (EPIC 1)
│   └── GameConfig.lua
│
├── Modules/              -- Загальні модулі (клієнт + сервер)
│   └── (майбутнє)
│
└── RemoteEvents/         -- Створюється автоматично Setup скриптом
    ├── LogOnRequest
    ├── LogOffRequest
    ├── StateChanged
    ├── BootStageUpdate
    └── ConfirmGameStart
```

### StarterPlayer/StarterPlayerScripts

```
StarterPlayer/StarterPlayerScripts/
├── Core/
│   └── ClientBootstrap.client.lua
│
├── UI/
│   ├── ScreenSaverUI.lua
│   └── UIManager.lua
│
└── Systems/              -- Майбутні клієнтські системи
    └── (порожня)
```

### ServerStorage

```
ServerStorage/
└── Planets/              -- Контент: дані планет
    └── (майбутнє)
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

- **1.0** — Початкова версія структури (2026-01-11)
  - Створено папки Core, Services, Systems, Setup
  - Переміщено існуючі скрипти
  - Додано рекомендації до TDD

---

**Статус:** Готово до синхронізації з Roblox Studio
