# Roblox Studio Setup Guide

**Версія:** 1.0
**Дата:** 2026-01-11
**EPIC:** 1 — 4-Stage ScreenSaver Implementation

---

## Огляд

Цей посібник описує, як налаштувати Roblox Studio для роботи з Script Sync та організацією проєкту.

---

## Перед початком

### Перевірте файлову систему

Переконайтеся, що всі файли на місці:

```
d:\Code\Roblox\CallOfRelics/
├── ServerScriptService/
│   ├── Core/
│   │   ├── GameStateManager.lua
│   │   ├── BootSequence.lua
│   │   └── ServerBootstrap.server.lua
│   ├── Services/
│   │   ├── PlayerService.lua
│   │   └── ProfileService.lua
│   ├── Setup/
│   │   └── RemoteEventsSetup.server.lua
│   └── Systems/ (порожня)
│
├── StarterPlayer/StarterPlayerScripts/
│   ├── Core/
│   │   └── ClientBootstrap.client.lua
│   ├── UI/
│   │   ├── ScreenSaverUI.lua
│   │   └── UIManager.lua
│   └── Systems/ (порожня)
│
└── ReplicatedStorage/
    ├── Game/
    │   └── GameConfig.lua
    └── RemoteEvents/ (порожня)
```

---

## Крок 1: Створення якірних папок у Studio

### 1.1. ServerScriptService

1. Відкрити Roblox Studio
2. У **Explorer** знайти **ServerScriptService**
3. Створити папки:
   ```
   ServerScriptService
   ├── Core          (Insert Object → Folder)
   ├── Services      (Insert Object → Folder)
   ├── Systems       (Insert Object → Folder)
   └── Setup         (Insert Object → Folder)
   ```

### 1.2. StarterPlayerScripts

1. У **Explorer** знайти **StarterPlayer → StarterPlayerScripts**
2. Створити папки:
   ```
   StarterPlayerScripts
   ├── Core          (Insert Object → Folder)
   ├── UI            (Insert Object → Folder)
   └── Systems       (Insert Object → Folder)
   ```

### 1.3. ReplicatedStorage

1. У **Explorer** знайти **ReplicatedStorage**
2. Створити папки:
   ```
   ReplicatedStorage
   ├── Game          (Insert Object → Folder)
   └── Modules       (Insert Object → Folder)
   ```

   **Примітка:** Папка `RemoteEvents` створюється автоматично скриптом `RemoteEventsSetup.server.lua`

---

## Крок 2: Налаштування Script Sync

### 2.1. Увімкнути Script Sync

1. У Roblox Studio: **View → Script Sync**
2. У панелі Script Sync натиснути **Configure**
3. Вибрати папку проєкту: `d:\Code\Roblox\CallOfRelics`
4. Натиснути **Enable Sync**

### 2.2. Перша синхронізація

1. Script Sync автоматично знайде файли у файловій системі
2. Файли з'являться у відповідних папках в Studio
3. Перевірити, що всі файли синхронізовані

---

## Крок 3: Перевірка структури

### 3.1. ServerScriptService

Перевірте в Explorer:

```
ServerScriptService
├── Core
│   ├── GameStateManager (ModuleScript)
│   ├── BootSequence (ModuleScript)
│   └── ServerBootstrap (Script)
├── Services
│   ├── PlayerService (ModuleScript)
│   └── ProfileService (ModuleScript)
├── Setup
│   └── RemoteEventsSetup (Script)
└── Systems
    (порожня)
```

**Важливо:**
- `ServerBootstrap.server.lua` має стати **Script** (не LocalScript)
- `RemoteEventsSetup.server.lua` має стати **Script**
- Всі `.lua` файли мають стати **ModuleScript**

### 3.2. StarterPlayerScripts

Перевірте в Explorer:

```
StarterPlayer → StarterPlayerScripts
├── Core
│   └── ClientBootstrap (LocalScript)
├── UI
│   ├── ScreenSaverUI (ModuleScript)
│   └── UIManager (ModuleScript)
└── Systems
    (порожня)
```

**Важливо:**
- `ClientBootstrap.client.lua` має стати **LocalScript**
- Всі `.lua` файли (ScreenSaverUI, UIManager) мають стати **ModuleScript**

### 3.3. ReplicatedStorage

Перевірте в Explorer:

```
ReplicatedStorage
├── Game
│   └── GameConfig (ModuleScript)
├── Modules
│   (порожня)
└── RemoteEvents (створюється автоматично при запуску)
    ├── LogOnRequest (RemoteEvent)
    ├── LogOffRequest (RemoteEvent)
    ├── StateChanged (RemoteEvent)
    ├── BootStageUpdate (RemoteEvent)
    └── ConfirmGameStart (RemoteEvent)
```

**Важливо:**
- `GameConfig.lua` має стати **ModuleScript**
- Папка `RemoteEvents` з'явиться після першого запуску гри

---

## Крок 4: Налаштування гри

### 4.1. Увімкнути API Services

1. У Studio: **Home → Game Settings** (або натиснути Alt+S)
2. **Security → Allow HTTP Requests** → Увімкнути (для avatar thumbnails)
3. **Security → Enable Studio Access to API Services** → Увімкнути (для DataStore)

### 4.2. Створити spawn location (опціонально)

**Примітка:** Spawn не реалізований в EPIC 1 — гравець залишається в ScreenSaver після "Почати гру"

Для тестування можна:
1. Додати **SpawnLocation** у Workspace
2. Поставити його у видимому місці

---

## Крок 5: Перший запуск

### 5.1. Очікувана поведінка

1. Натиснути **Play** (F5) у Studio
2. У **Output** з'являться логи:
   ```
   ================================================================================
   SERVER BOOT SEQUENCE STARTED
   [ServerBootstrap 0.1] Initializing...
   ================================================================================
   [RemoteEventsSetup 0.1] Setting up RemoteEvents...
   [RemoteEventsSetup 0.1] Created: LogOnRequest
   [RemoteEventsSetup 0.1] Created: LogOffRequest
   [RemoteEventsSetup 0.1] Created: StateChanged
   [RemoteEventsSetup 0.1] Created: BootStageUpdate
   [RemoteEventsSetup 0.1] Created: ConfirmGameStart
   [ServerBootstrap 0.1][Boot] Phase 1: Initializing GameStateManager
   [GameStateManager 0.1][Initialize] Initializing...
   [GameStateManager 0.1][Initialize] Current state: LoggedOff
   [ServerBootstrap 0.1][Boot] Phase 2: Initializing ProfileService
   [ProfileService 0.1][Initialize] Initializing ProfileService
   [ProfileService 0.1][Initialize] DataStore connected: PlayerProfiles
   [ServerBootstrap 0.1][Boot] Phase 3: Initializing PlayerService
   [PlayerService 0.1][Initialize] PlayerService initialized
   [ServerBootstrap 0.1][Boot] Phase 4: Core systems ready
   [ServerBootstrap 0.1][Boot] Phase 5: ScreenSaver active
   ================================================================================
   BOOT COMPLETE
   Game State: LoggedOff (ScreenSaver)
   Waiting for player login...
   ================================================================================
   ```

3. На екрані з'явиться **ScreenSaver**:
   - Темний фон
   - Великий текст "CALL OF RELICS"
   - Підзаголовок "Orbital Silence"
   - Пульсуючий текст "Press SPACE or Click to Enter"

### 5.2. Тестування 4-стадійного boot sequence

1. **Натиснути SPACE** або **клікнути мишкою**
2. ScreenSaver перейде у **Stage 1**:
   - Назва гри великими літерами
   - Версія у правому нижньому куті
   - Тривалість: 1.5 секунди

3. Автоматично перейде у **Stage 2**:
   - Аватар гравця (150x150px)
   - Ім'я гравця
   - Тривалість: 1.5 секунди

4. Автоматично перейде у **Stage 3**:
   - Обертовий спінер (4 точки)
   - Текст "Ініціалізація експедиції..." (новий гравець) або "Відновлення експедиції..." (досвідчений)
   - Прогрес-бар
   - Тривалість: 2 секунди

5. Автоматично перейде у **Stage 4**:
   - Текст "Готовність 100%" (зелений)
   - Кнопка "Почати гру" (синя, з hover ефектом)
   - Чекає на клік

6. **Клікнути "Почати гру"**:
   - Перехід до InGame state
   - ScreenSaver зникає
   - У Output: "Player X is now in game"

### 5.3. Перевірка Output логів

**Очікувані логи після кліку SPACE:**

```
[PlayerService 0.1][LogOnRequest] Received from Player1
[PlayerService 0.1][LogOnPlayer] Starting session for Player1
[GameStateManager 0.1][RequestStateChange] Requesting transition: LoggedOff → Initializing
[BootSequence 0.1][StartBoot] Beginning boot sequence for Player1
[BootSequence 0.1][Stage1] Sending game configuration to Player1
[BootSequence 0.1][Stage2] Player connected: Player1 (UserId: 123456, DisplayName: Player1)
[BootSequence 0.1][Stage3] Loading profile for Player1
[ProfileService 0.1][LoadProfile] Loading profile for Player1 (UserId: 123456)
[ProfileService 0.1][LoadProfile] No profile found for Player1, will create new
[ProfileService 0.1][CreateNewProfile] Creating new profile for Player1
[ProfileService 0.1][CreateNewProfile] New profile created and saved for Player1
[BootSequence 0.1][Stage3] NEW PLAYER: Player1 — Profile created with planet Planet_1
[BootSequence 0.1][Stage4] Preparing game space for Player1
[BootSequence 0.1][Stage4] Game state for Player1:
  - Current Planet: Planet_1
  - Explored Locations: 0
  - Ship Energy: 100
[BootSequence 0.1][Stage4] Ready — Waiting for player to click 'Почати гру'
```

**Після кліку "Почати гру":**

```
[BootSequence 0.1][ConfirmGameStart] Player Player1 confirmed game start — transitioning to InGame
[GameStateManager 0.1][RequestStateChange] Requesting transition: Initializing → InGame
[GameStateManager 0.1][RequestStateChange] Transition successful: Initializing → InGame
[BootSequence 0.1][ConfirmGameStart] Successfully transitioned Player1 to InGame
```

---

## Крок 6: Перевірка DataStore

### 6.1. Увімкнути DataStore в Studio

**Важливо:** За замовчуванням DataStore у Studio працює лише якщо ввімкнено "Enable Studio Access to API Services"

1. **Home → Game Settings**
2. **Security → Enable Studio Access to API Services** → ✅ Увімкнути
3. Перезапустити гру

### 6.2. Перевірка збереження профілю

1. Запустити гру, пройти весь boot sequence, клікнути "Почати гру"
2. Зупинити гру (Stop)
3. Запустити гру знову
4. Пройти boot sequence
5. У **Output** перевірити:
   ```
   [BootSequence 0.1][Stage3] RETURNING PLAYER: Player1 — Last login: 2026-01-11 12:34:56, Current planet: Planet_1
   ```
   (замість "NEW PLAYER")

### 6.3. Якщо DataStore не працює

Якщо у Output з'являється:
```
[ProfileService 0.1][Initialize] Failed to get DataStore: ...
[ProfileService 0.1][Initialize] Will use temporary in-memory profiles
```

**Рішення:**
1. Перевірити, що API Services увімкнені
2. Переконатися, що інтернет з'єднання активне
3. Спробувати перезапустити Studio
4. Гра працюватиме з тимчасовими профілями (дані не зберігаються між сесіями)

---

## Крок 7: Тестування повторного входу

### 7.1. Новий гравець (перший вхід)

**Очікувана поведінка:**
- Stage 3: "Ініціалізація експедиції..."
- Output: "NEW PLAYER: PlayerName — Profile created with planet Planet_1"

### 7.2. Досвідчений гравець (повторний вхід)

**Очікувана поведінка:**
- Stage 3: "Відновлення експедиції..."
- Output: "RETURNING PLAYER: PlayerName — Last login: ..., Current planet: Planet_1"

---

## Troubleshooting

### Проблема 1: "Infinite yield possible on 'WaitForChild'"

**Причина:** Папки не створені в Studio або Script Sync не налаштований

**Рішення:**
1. Перевірити, що всі anchor folders існують у Studio
2. Перевірити, що Script Sync увімкнений
3. Перезапустити Studio

### Проблема 2: ScreenSaver не з'являється

**Причина:** ClientBootstrap не виконується або помилка у require()

**Рішення:**
1. Перевірити Output на помилки
2. Переконатися, що ClientBootstrap є LocalScript
3. Перевірити, що UI/ папка містить ModuleScripts

### Проблема 3: "Module not found" у Output

**Причина:** Неправильні шляхи у require() або файли у неправильних папках

**Рішення:**
1. Перевірити, що всі ModuleScripts у правильних папках
2. Перевірити шляхи у require()
3. Перезавантажити Studio

### Проблема 4: DataStore помилки

**Причина:** API Services не увімкнені або немає інтернету

**Рішення:**
1. Увімкнити "Enable Studio Access to API Services"
2. Перевірити інтернет з'єднання
3. Гра працюватиме з тимчасовими профілями

### Проблема 5: RemoteEvents не створюються

**Причина:** RemoteEventsSetup.server.lua не виконався

**Рішення:**
1. Перевірити Output на помилки
2. Переконатися, що RemoteEventsSetup є Script (не LocalScript)
3. Перевірити, що файл у папці Setup/

---

## Наступні кроки (EPIC 2+)

- [ ] Додати spawn location для гравця
- [ ] Реалізувати Ship в орбіті
- [ ] Додати локації на Planet_1
- [ ] Реалізувати систему телепортації

---

## Посилання

- [EPIC1_4STAGE_IMPLEMENTATION.md](EPIC1_4STAGE_IMPLEMENTATION.md) — Детальна документація реалізації
- [FOLDER_STRUCTURE.md](Docs/FOLDER_STRUCTURE.md) — Структура проєкту
- [TDD.md](Docs/TDD.md) — Technical Design Document
- [RESTRUCTURE_CLIENT.md](RESTRUCTURE_CLIENT.md) — Документація реструктуризації клієнта

---

**Статус:** Готово до тестування
**Версія:** EPIC 1 Complete
