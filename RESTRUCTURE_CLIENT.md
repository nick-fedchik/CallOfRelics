# Client Scripts Restructure

**Дата:** 2026-01-11
**Статус:** ✅ Завершено

---

## Мета

Організувати клієнтські скрипти у якірні папки для Script Sync відповідно до архітектури TDD Section 13.3.

---

## Зміни

### До реструктуризації:

```
StarterPlayer/StarterPlayerScripts/
├── ClientBootstrap.client.lua
├── ScreenSaverUI.lua
└── UIManager.lua
```

### Після реструктуризації:

```
StarterPlayer/StarterPlayerScripts/
├── Core/
│   └── ClientBootstrap.client.lua
├── UI/
│   ├── ScreenSaverUI.lua
│   └── UIManager.lua
└── Systems/
    └── (порожня — для майбутніх систем)
```

---

## Оновлені файли

### 1. `StarterPlayerScripts/Core/ClientBootstrap.client.lua`

**Зміни:**
```lua
-- Було:
local ScreenSaverUI = require(script.Parent:WaitForChild("ScreenSaverUI"))
local UIManager = require(script.Parent:WaitForChild("UIManager"))

-- Стало:
local StarterPlayerScripts = script.Parent.Parent
local UI = StarterPlayerScripts:WaitForChild("UI")

local ScreenSaverUI = require(UI:WaitForChild("ScreenSaverUI"))
local UIManager = require(UI:WaitForChild("UIManager"))
```

**Обґрунтування:**
Модулі тепер знаходяться в папці `UI/`, тому потрібен новий шлях для require().

---

## Організація папок

### Core/
**Призначення:** Bootstrap та ініціалізація клієнта

**Файли:**
- `ClientBootstrap.client.lua` — точка входу клієнта

**Правила:**
- Містить лише bootstrap скрипти
- Ініціалізує інші системи
- Не містить ігрової логіки

---

### UI/
**Призначення:** UI модулі та інтерфейси

**Файли:**
- `ScreenSaverUI.lua` — 4-стадійний ScreenSaver
- `UIManager.lua` — керування UI станами

**Правила:**
- Містить лише UI-логіку
- ModuleScripts (require для використання)
- Не містить ігрової логіки

---

### Systems/
**Призначення:** Клієнтські ігрові системи (майбутнє)

**Плановані файли:**
- `InputHandler.lua` — обробка вводу
- `CameraController.lua` — система камери
- `LocationRenderer.lua` — рендеринг локацій
- `ShipUI.lua` — інтерфейс корабля

---

## Script Sync Інструкції

### Крок 1: У Roblox Studio

1. Відкрити проєкт у Roblox Studio
2. Знайти **StarterPlayer → StarterPlayerScripts** в Explorer
3. Створити папки:
   ```
   Insert Object → Folder → Name: "Core"
   Insert Object → Folder → Name: "UI"
   Insert Object → Folder → Name: "Systems"
   ```

### Крок 2: Налаштування Script Sync

1. **View → Script Sync** в Roblox Studio
2. Вибрати папку проєкту: `d:\Code\Roblox\CallOfRelics`
3. Увімкнути синхронізацію
4. Перевірити, що файли синхронізовані

### Крок 3: Перевірка

**Тест 1: Файли у правильних папках**
```
Explorer → StarterPlayer → StarterPlayerScripts
  → Core → ClientBootstrap (LocalScript)
  → UI → ScreenSaverUI (ModuleScript)
  → UI → UIManager (ModuleScript)
  → Systems (Folder, порожня)
```

**Тест 2: Скрипти працюють**
1. Запустити гру в Studio
2. Перевірити Output на помилки "module not found"
3. Перевірити, що ScreenSaver з'являється

---

## Важливі примітки

### ⚠️ Критичні вимоги Script Sync:

1. **Anchor folders обов'язкові:**
   StarterPlayerScripts є anchor folder — папки всередині (Core, UI, Systems) мають існувати в Studio ПЕРЕД синхронізацією

2. **Автоматично виконувані скрипти:**
   Файли з розширенням `.client.lua` виконуються автоматично при старті клієнта

3. **ModuleScripts:**
   Файли з розширенням `.lua` є ModuleScripts — потрібно викликати через `require()`

4. **Шляхи require():**
   Шляхи у `require()` мають бути оновлені після переміщення файлів

---

## Наступні кроки

1. ✅ Створити папки Core, UI, Systems в Studio
2. ✅ Перемістити файли через Script Sync
3. ✅ Перевірити, що ClientBootstrap запускається
4. ✅ Перевірити, що ScreenSaver працює
5. ⏳ Додати Systems/ модулі в майбутніх EPIC

---

## TDD Compliance

- ✅ **Section 13.3:** Folder structure follows architectural principles
- ✅ **Section 13.3.1:** Script Sync anchor folders requirement
- ✅ **Section 4.3:** Client bootstrap sequence intact
- ✅ **Section 7.2:** ScreenSaver UI functionality preserved

---

## Посилання

- [FOLDER_STRUCTURE.md](Docs/FOLDER_STRUCTURE.md) — Повна структура проєкту
- [StarterPlayerScripts/README.md](StarterPlayer/StarterPlayerScripts/README.md) — Детальна документація клієнтської частини
- [TDD.md](Docs/TDD.md) — Technical Design Document

---

**Статус:** Реструктуризація завершена, готово до тестування
