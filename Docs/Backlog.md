# Backlog.md  
**Project:** Call of Relics: Orbital Silence  
**Type:** Single-player Exploration RPG (Roblox)  
**Backlog Version:** 0.4  
**Status:** Active Development  
**Scope:** Architecture-first, Content-later  

---

## 1. ROADMAP

Roadmap визначає **етапи розвитку гри** на високому рівні.
Кожен етап завершується **стабільним ігровим станом**, а не набором фіч.

---

### Phase 0 — Foundations (Architecture First)

**Ціль:**  
Створити стабільне архітектурне ядро гри.

**Ключові результати:**
- Гра запускається без контенту
- Чіткі глобальні та локальні стани
- Коректний lifecycle гри
- Повна керованість через GameState

**Вихідний стан:**
- Player може LogOn / LogOff
- Працює ScreenSaver
- Корабель існує як безпечний контекст

---

### Phase 1 — Core Gameplay Loop

**Ціль:**  
Реалізувати базову петлю гри:
> Орбіта → Локація → Повернення → Прогрес

**Ключові результати:**
- Перша планета «Рубін»
- 2 локації (Story + Exploration)
- Сканування планет і локацій
- Teleport через SpawnLocation

---

### Phase 2 — Progression & Persistence

**Ціль:**  
Закріпити RPG-складову.

**Ключові результати:**
- Збереження прогресу
- Ресурси і знання
- Розвиток корабля
- Повторні візити до локацій

---

### Phase 3 — Expansion & Variety

**Ціль:**  
Збільшення різноманіття гри.

**Ключові результати:**
- Нові типи локацій
- Нові планети
- Підвищення складності
- Наративні розгалуження

---

### Phase 4 — Polishing & Release Readiness

**Ціль:**  
Стабільність, баланс, підготовка до релізу.

**Ключові результати:**
- Баланс локацій
- UI/UX polish
- Оптимізація
- Маркетингова підготовка (Roblox Discover)

---

## 2. EPICS AND STORIES

Backlog організований за **Epic → User Stories**.  
User Stories формулюються з точки зору **гравця** або **системи**.

---

### EPIC 1 — Game Boot & Global States ✅ COMPLETE

**Опис:**
Життєвий цикл гри від запуску до завершення сесії.

**Status:** ✅ Complete (v0.5)

#### Stories:
- ✅ Player can see ScreenSaver and avatar before entering the game
- ✅ Player can Log In and start a new session
- ✅ Player can Log Off and return to ScreenSaver
- ✅ Game handles unexpected disconnects safely
- ✅ Game initializes in a clean and deterministic state

---

### EPIC 2 — Game State Architecture ✅ COMPLETE

**Опис:**
Єдина система глобальних і локальних станів.

**Status:** ✅ Complete (v0.5)

#### Stories:
- ✅ Game has a single source of truth for state
- ✅ Systems react to state changes, not raw events
- ✅ Context switching is atomic and safe
- ✅ Transition states block player actions

---

### EPIC 3 — Space Ship as Core Location ✅ COMPLETE

**Опис:**
Корабель як безпечний хаб гри.

**Status:** ✅ Complete (v0.7)

#### Stories:
- ✅ Player always spawns on the ship (PilotSeat)
- ✅ Ship acts as save and restore point
- ✅ Player can view planet from orbit
- ✅ Ship systems reflect player progression (5 seats with UI)

---

### EPIC 4 — Planet & Location System ⏳ IN PROGRESS

**Опис:**
Планети як контейнери локацій.

**Status:** ⏳ In Progress (v0.7)

#### Stories:
- ✅ Planet contains multiple locations (LocationService, Config.luau)
- ✅ Locations can be discovered and visited (TransitionService landing)
- Locations have independent rules
- ✅ Player can revisit locations with updated state (liftoff → landing cycle)

---

### EPIC 5 — Scanner Systems

**Опис:**  
Виявлення нового контенту.

#### Stories:
- Player can scan planet surface from orbit
- Scanner reveals undiscovered locations
- Scanner feedback is visual and clear
- Scanner cannot be used in invalid contexts

---

### EPIC 6 — Teleportation & SpawnLocation ⏳ IN PROGRESS

**Опис:**
Переміщення між контекстами гри.

**Status:** ⏳ In Progress (v0.7)

**Note:** Реалізовано через TransitionService (Landing/Liftoff) замість традиційного Teleport.

#### Stories:
- ✅ SpawnLocation acts as teleport point (LandingPad with PilotSeat)
- SpawnLocation has active / inactive states
- ✅ Teleport GUI shows available destinations (PilotUI location list)
- Player can cancel teleport safely

---

### EPIC 7 — Location Gameplay (Arcades)

**Опис:**  
Локації як окремі ігрові аркади.

#### Stories:
- Each location has a primary goal
- Locations may have optional objectives
- Player can fail exploration
- Failure has consequences but preserves knowledge

---

### EPIC 8 — Progression & Persistence ✅ COMPLETE

**Опис:**
Довготривалий прогрес гравця.

**Status:** ✅ Complete (v0.8)

#### Stories:
- ✅ Player progress is saved reliably (auto-save + event saves)
- ✅ Player returns to last known safe state (lastSafeState in profile)
- ✅ Resources may be lost on failure (RemoveResources API)
- ✅ Knowledge is never lost (AddKnowledge only, no removal)

---

### EPIC 9 — UI & UX ⏳ IN PROGRESS

**Опис:**
Контекстний інтерфейс гри.

**Status:** ⏳ In Progress (v0.7)

#### Stories:
- ✅ UI reflects current game state (StatusBarUI, PilotUI context)
- ✅ Contextual menus appear only when allowed (SeatUI system)
- ✅ UI never bypasses game logic (server-authoritative)
- UI explains restrictions to player

---

### EPIC 10 — Diagnostics & Logging ✅ COMPLETE

**Опис:**
Прозорість та керованість розробки.

**Status:** ✅ Complete (v0.7)

#### Stories:
- ✅ Every system logs its initialization
- ✅ Logs are concise and structured
- ✅ Output logs can be analyzed externally
- ✅ Scripts have standardized headers (KOSMICMAZER format, TDD 11.8)

---

## 3. SPRINT BACKLOG

Sprint Backlog формується **інкрементально**.
Перші спринти зосереджені **виключно на архітектурі**.

---

### Sprint 0 — Project Skeleton & Standards

**Goal:**  
Підготувати основу для розробки.

**Stories:**
- Create repository structure
- Add GDD.md, TDD.md, Backlog.md
- Define logging standard
- Define script header template
- Prepare ScreenSaver placeholder

---

### Sprint 1 — Global State & Boot Flow

**Goal:**  
Гра запускається стабільно.

**Stories:**
- Implement Game Boot sequence
- Implement ScreenSaver state
- Implement LogOn / LogOff flow
- Implement global state coordinator
- Log init of all core systems

---

### Sprint 2 — Space Ship Context

**Goal:**  
Корабель як стабільний контекст.

**Stories:**
- Initialize Space Ship location
- Spawn player on ship
- Define safe save point
- Display planet from orbit
ServerStorage
└── Planets
    └── Planet_1
        ├── Orbit
        │   ├── StarterPlayer
        │   │   ├── StarterCharacterScript
        │   │   └── StarterPlayerScript
        │   ├── ReplicatedStorage
        │   ├── ServerScriptService
        │   └── Workspace
        │       ├── Lighting
        │       │   └── Sky
        │       └── SpaceShip
        │           ├── Configuration
        │           │   ├── MaxShield
        │           │   ├── MaxHull
        │           │   ├── ExplosionSize
        │           │   ├── Description
        │           │   ├── Class
        │           │   └── Mass
        │           ├── ShipParts (багато частин та зварних з'єднань)
        │           ├── TurretPlate (5 шт.)
        │           ├── PilotSeat
        │           ├── Seat (4 шт.)
        │           ├── DockPoint
        │           └── CenterPoint
        └── Surface
            ├── Location1
            │   ├── Workspace
            │   │   └── Lighting
            │   │       └── Sky
            │   ├── ServerScriptService
            │   ├── ReplicatedStorage
            │   └── StarterPlayer
            │       ├── StarterCharacterScript
            │       └── StarterPlayerScript
            └── Location2
                ├── Workspace
                │   └── Lighting
                │       └── Sky
                ├── ServerScriptService
                ├── ReplicatedStorage
                └── StarterPlayer
                    ├── StarterCharacterScript
                    └── StarterPlayerScript
---

### Sprint 3 — First Planet & Scanning

**Goal:**  
Перший контакт з планетою.

**Stories:**
- Add Planet “Рубін”
- Implement planet surface scanner
- Discover locations
- Visual feedback for scanning

---

### Sprint 4 — First Locations

**Goal:**  
Початковий геймплей.

**Stories:**
- Location “Візитка” (Story)
- Location “Садочок” (Exploration)
- Location entry and exit flow
- Minimal success / failure conditions

---

## NOTES

- Backlog є **живим документом**
- Пріоритет — **стабільність ядра**
- Контент додається після стабілізації систем
- Будь-яка Story може бути переглянута після архітектурного рев’ю

---
