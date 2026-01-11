# Інструкція: Налаштування Script Sync

**Для:** Call of Relics: Orbital Silence
**Дата:** 2026-01-11
**Мета:** Синхронізувати файлову структуру з Roblox Studio

---

## Що Вже Зроблено

✅ Створено структуру папок у файловій системі:

```
ServerScriptService/
├── Core/
│   ├── GameStateManager.lua
│   └── ServerBootstrap.server.lua
├── Services/
│   └── PlayerService.lua
├── Systems/
│   └── (порожня папка)
└── Setup/
    └── RemoteEventsSetup.server.lua
```

✅ Оновлено TDD (розділ 13.3.2) з рекомендаціями щодо структури

✅ Створено документацію: [Docs/FOLDER_STRUCTURE.md](Docs/FOLDER_STRUCTURE.md)

✅ Оновлено EPIC1_IMPLEMENTATION.md з новими шляхами

---

## Що Потрібно Зробити в Roblox Studio

### Крок 1: Відкрити проєкт

1. Запустити Roblox Studio
2. Відкрити проєкт "Call of Relics: Orbital Silence"

---

### Крок 2: Створити структуру папок

**У ServerScriptService створити папки:**

1. Правий клік на **ServerScriptService**
2. **Insert Object → Folder**
3. Назвати папку: `Core`
4. Повторити для папок:
   - `Services`
   - `Systems`
   - `Setup`

**Результат:**
```
ServerScriptService
├── Core
├── Services
├── Systems
└── Setup
```

---

### Крок 3: Перемістити існуючі скрипти

**Якщо скрипти вже є в ServerScriptService (на верхньому рівні):**

**Перемістити до Core:**
- `GameStateManager` → перетягнути до папки `Core`
- `ServerBootstrap` → перетягнути до папки `Core`

**Перемістити до Services:**
- `PlayerService` → перетягнути до папки `Services`

**Перемістити до Setup:**
- `RemoteEventsSetup` → перетягнути до папки `Setup`

**Якщо скриптів немає** — вони з'являться після налаштування Script Sync.

---

### Крок 4: Налаштувати Script Sync

1. У Roblox Studio натиснути **View → Script Sync**
2. У вікні Script Sync натиснути **Choose Folder**
3. Вибрати папку проєкту:
   ```
   d:\Code\Roblox\CallOfRelics
   ```
4. Натиснути **Select Folder**
5. Увімкнути **Enable Sync** (якщо не увімкнуто)

---

### Крок 5: Перевірити синхронізацію

**Тест 1: Studio → Файлова система**

1. У Studio створити тестовий ModuleScript у папці `Core`
2. Назвати його `TestModule`
3. Перевірити у VSCode, що файл `ServerScriptService/Core/TestModule.lua` з'явився
4. Видалити тестовий модуль

**Тест 2: Файлова система → Studio**

1. У VSCode відкрити `ServerScriptService/Core/GameStateManager.lua`
2. Додати коментар на початку файла: `-- Test sync`
3. Зберегти файл
4. У Studio перевірити, що коментар з'явився у скрипті
5. Видалити тестовий коментар

**Якщо обидва тести пройшли — синхронізація працює! ✅**

---

## Очікувана Структура Після Синхронізації

### У Roblox Studio Explorer:

```
ServerScriptService
├── Core
│   ├── GameStateManager
│   └── ServerBootstrap
├── Services
│   └── PlayerService
├── Systems
│   (порожня)
└── Setup
    └── RemoteEventsSetup

StarterPlayer
└── StarterPlayerScripts
    ├── ClientBootstrap
    ├── ScreenSaverUI
    └── UIManager

ReplicatedStorage
└── RemoteEvents (створюється автоматично)
    ├── LogOnRequest
    ├── LogOffRequest
    └── StateChanged
```

---

## Можливі Проблеми та Рішення

### Проблема 1: Script Sync не бачить папки

**Причина:** Папки не створені в Studio

**Рішення:**
1. Вручну створити папки Core, Services, Systems, Setup
2. Перезапустити Script Sync

---

### Проблема 2: Скрипти дублюються

**Причина:** Скрипти існують і в кореневій папці, і в підпапках

**Рішення:**
1. Видалити дублікати з кореневої папки ServerScriptService
2. Залишити лише у відповідних підпапках

---

### Проблема 3: Зміни не синхронізуються

**Причина:** Script Sync вимкнено або неправильний шлях

**Рішення:**
1. Перевірити, що Script Sync увімкнено
2. Перевірити шлях до проєкту
3. Перезапустити Script Sync
4. Перезапустити Roblox Studio

---

### Проблема 4: "Infinite yield possible on WaitForChild"

**Причина:** Шляхи до модулів у require() застарілі (шукають на верхньому рівні)

**Помилка:**
```
Infinite yield possible on 'ServerScriptService:WaitForChild("GameStateManager")'
```

**Рішення:**

✅ **Файлова система вже виправлена!** Але якщо у вас є старі копії скриптів у Studio:

**У ServerBootstrap.server.lua** (рядки 62-68):
```lua
-- СТАРИЙ КОД (ВИДАЛИТИ):
-- local GameStateManager = require(ServerScriptService:WaitForChild("GameStateManager"))
-- local PlayerService = require(ServerScriptService:WaitForChild("PlayerService"))

-- НОВИЙ КОД (ВИКОРИСТОВУВАТИ):
-- Core modules (same folder)
local Core = script.Parent
local GameStateManager = require(Core:WaitForChild("GameStateManager"))

-- Services
local Services = ServerScriptService:WaitForChild("Services")
local PlayerService = require(Services:WaitForChild("PlayerService"))
```

**У PlayerService.lua** (рядки 60-61):
```lua
-- СТАРИЙ КОД (ВИДАЛИТИ):
-- local GameStateManager = require(ServerScriptService:WaitForChild("GameStateManager"))

-- НОВИЙ КОД (ВИКОРИСТОВУВАТИ):
local Core = ServerScriptService:WaitForChild("Core")
local GameStateManager = require(Core:WaitForChild("GameStateManager"))
```

**Після виправлення:**
1. Зберегти зміни у Studio або дочекатися синхронізації
2. Перезапустити гру (F5)

---

## Наступні Кроки Після Налаштування

1. **Запустити гру** у Studio (F5)
2. **Перевірити логи** у Output
3. **Натиснути Space** для LogOn
4. **Перевірити, що всі системи працюють**

Очікувані логи описані в [EPIC1_IMPLEMENTATION.md](EPIC1_IMPLEMENTATION.md)

---

## Додаткова Інформація

- **Структура проєкту:** [Docs/FOLDER_STRUCTURE.md](Docs/FOLDER_STRUCTURE.md)
- **Технічний дизайн:** [Docs/TDD.md](Docs/TDD.md) (розділ 13.3)
- **Реалізація EPIC 1:** [EPIC1_IMPLEMENTATION.md](EPIC1_IMPLEMENTATION.md)

---

**Статус:** Готово до налаштування в Roblox Studio

**Питання?** Перевірте документацію або логи Output у Studio
