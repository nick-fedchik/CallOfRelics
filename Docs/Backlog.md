# Backlog.md
**Project:** Call of Relics: Orbital Silence

**Type:** Single-player Exploration RPG (Roblox)

**Backlog Version:** 0.5

**Status:** Active Development

**Current Game Version:** 0.9.1

---

## 1. ROADMAP

### Phase 0 — Foundations ✅ COMPLETE
- Архітектурне ядро гри
- Глобальні стани (LoggedOff, Initializing, InGame)
- Boot sequence з 4-stage UI

### Phase 1 — Core Gameplay Loop ⏳ IN PROGRESS
> Орбіта → Локація → Повернення → Прогрес

**Завершено:**
- Перша планета (Біллі Рубін)
- 2 локації (Location_1, Location_2)
- Transition система (Landing/Launch)

**В роботі:**
- Сканування планет (EPIC 5)
- Gameplay локацій (EPIC 7)

**Завершено в Phase 1:**
- SpaceShip система (EPIC 3) ✅
- Planet & Location система (EPIC 4) ✅

### Phase 2 — Progression & Persistence ✅ COMPLETE
- ProfileService v2 з auto-save
- Ресурси та знання
- Повторні візити

### Phase 3 — Expansion & Variety
- Нові типи локацій
- Нові планети
- Наративні розгалуження

### Phase 4 — Polishing & Release
- Баланс
- UI/UX polish
- Оптимізація

---

## 2. ACTIVE EPICS

### EPIC 4 — Planet & Location System ✅ COMPLETE

**Опис:** Структура та конфігурація планет і локацій.

**Специфікація:**

```
ServerStorage/Planets/Planet_Id/
├── Config.luau                    # ОБОВ'ЯЗКОВО — Game Error
├── ReplicatedStorage/             # Planet Scripts
├── ServerScriptService/           # Planet Scripts
├── StarterPlayer/                 # Planet Scripts
├── Orbit/                         # ОБОВ'ЯЗКОВО — Game Error
│   ├── Config.luau                # Orbit config
│   ├── Workspace/
│   │   ├── Planet (Model)         # ОБОВ'ЯЗКОВО — Game Error
│   │   └── Lighting/              # → game.Lighting
│   ├── ReplicatedStorage/         # Orbit Scripts
│   ├── ServerScriptService/       # Orbit Scripts
│   └── StarterPlayer/             # Orbit Scripts
└── Surface/
    └── Location_Id/
        ├── Config.luau            # Location config
        ├── Workspace/
        │   └── Lighting/          # → game.Lighting
        ├── ReplicatedStorage/     # Location Scripts
        ├── ServerScriptService/   # Location Scripts
        └── StarterPlayer/         # Location Scripts
```

**Init/Fini System:**
- `Planet Init/Fini` — Planet Scripts + `PlanetScriptsRegistry`
- `Orbit Init/Fini` — Orbit Scripts + Workspace + `OrbitObjectsRegistry` + `OrbitScriptsRegistry`
- `Location Init/Fini` — Location Scripts + Workspace + `LocationObjectsRegistry` + `LocationScriptsRegistry`

**Ієрархія:**
```
Enter Game → Planet Init → Orbit Init
Landing    → Orbit Fini → Location Init
Launch     → Location Fini → Orbit Init
Leave Planet → Location/Orbit Fini → Planet Fini
```

**Stories:**
- [x] Planet configuration stored in Config.luau
- [x] Orbit folder with Planet model
- [x] Surface folder with Location subfolders
- [x] Planet Init/Fini with PlanetScriptsRegistry
- [x] Orbit Init/Fini with OrbitObjectsRegistry + OrbitScriptsRegistry
- [x] Location Init/Fini with LocationObjectsRegistry + LocationScriptsRegistry
- [x] Workspace/Lighting objects copied to game.Lighting
- [x] CurrentPlanetPath tracks active planet
- [x] Locations have independent rules (gravity)

---

### EPIC 5 — Surface Scanner System ⏳ IN PROGRESS

**Опис:** Виявлення нового контенту через сканування.

**Implementation:**
- ScannerService (server-side) — scan processing, cooldown, discovery
- SurfaceScannerUI (client-side) — scan button, progress bar, discovered list
- "Seat Planet Surface Scanner" — dedicated scanner seat on SpaceShip
- RemoteEvents: RequestScan, ScanProgress, ScanComplete

**Stories:**
- [x] Player can scan planet surface from orbit
- [x] Scanner reveals undiscovered locations
- [x] Scanner feedback is visual and clear (progress bar + messages)
- [x] Scanner cannot be used in invalid contexts (Orbit only)

---

### EPIC 7 — Location Gameplay (Arcades) 🆕 0/4

**Опис:** Локації як окремі ігрові аркади.

**Stories:**
- [ ] Each location has a primary goal
- [ ] Locations may have optional objectives
- [ ] Player can fail exploration
- [ ] Failure has consequences but preserves knowledge

---

### EPIC 11 — Engines System 🆕 0/4

**Опис:** Керування двигунами корабля через "Seat Engines".

**Seat:** `Seat Engines`
**UI Module:** `EnginesUI`
**Functionality:** `canControlEngines = true`

**Stories:**
- [ ] EnginesUI displays ship engine status
- [ ] Player can monitor fuel/energy levels
- [ ] Player can adjust engine power distribution
- [ ] Engine state affects ship capabilities (speed, maneuverability)

---

### EPIC 12 — Planet Locator System 🆕 0/4

**Опис:** Планетний локатор для виявлення та навігації до нових планет.

**Seat:** `Seat Locator`
**UI Module:** `PlanetLocatorUI`
**Functionality:** `canLocatePlanets = true`

**Stories:**
- [ ] PlanetLocatorUI displays known planets
- [ ] Player can scan for undiscovered planets
- [ ] Player can set navigation target
- [ ] Discovered planets saved to ProfileService

---

### EPIC 13 — Personal Computer System 🆕 0/4

**Опис:** Персональний комп'ютер для доступу до інвентарю та бази знань.

**Seat:** `Seat Personal Computer`
**UI Module:** `PersonalComputerUI`
**Functionality:** `canAccessInventory = true`, `canAccessKnowledge = true`

**Stories:**
- [ ] PersonalComputerUI displays inventory (resources)
- [ ] PersonalComputerUI displays knowledge base
- [ ] Player can view collected resources
- [ ] Player can browse discovered knowledge entries

---

### EPIC 9 — UI & UX ⏳ 3/4

**Незакриті Stories:**
- [ ] UI explains restrictions to player (tooltips, disabled states)

---

### EPIC 3 — SpaceShip System ⏳ 4/8

**Опис:** SpaceShip як основна локація гравця з 5 функціональними кріслами.

**Специфікація:**

```
ServerStorage/Actors/
├── SpaceShip                    # Default model
├── SpaceShip_Advanced           # Upgraded model (TBD)
└── SpaceShip_Elite              # Upgraded model (TBD)
```

**SpaceShip Seats (SpaceShipConfig):**
| Seat | UI Module | Functionality |
|------|-----------|---------------|
| PilotSeat | PilotUI | Navigation, Weapons control |
| Seat Engines | EnginesUI | Engine control |
| Seat Planet Surface Scanner | PlanetSurfaceScannerUI | Planet scanning |
| Seat Planet Locator | PlanetLocatorUI | Planet discovery |
| Seat Personal Computer | PersonalComputerUI | Inventory, Knowledge |

**SpaceShip Lifecycle:**
- Clone до `game.Workspace` на старті гри
- Destroy з `game.Workspace` по завершенні гри
- Незалежний від Planet/Location системи
- `ModelStreamingMode = Persistent`

**SpaceShip Upgrade:**
- Профіль гравця зберігає `spaceShipModel` посилання
- Fallback до `SpaceShip` якщо модель не знайдена

**Stories:**
- [x] SpaceShip model stored in ServerStorage/Actors/
- [x] SpaceShip cloned to Workspace on game start
- [x] SpaceShip destroyed from Workspace on game end
- [x] SpaceShip model loaded from player profile (upgrade system)
- [x] Game detects when player sits in any seat (logging)
- [ ] PilotSeat: Navigation system functional
- [ ] PilotSeat: Weapons control system (TBD)
- [ ] All seat UIs show proper content (not "NOT WORKING")

---

## 3. COMPLETED EPICS (Archive)

| EPIC | Version | Description |
|------|---------|-------------|
| EPIC 1 | v0.5 | Game Boot & Global States |
| EPIC 2 | v0.5 | Game State Architecture |
| EPIC 3 | v0.9 | SpaceShip System (base) |
| EPIC 4 | v0.9 | Planet & Location System (Init/Fini) |
| EPIC 5 | v0.9 | Surface Scanner System (in progress) |
| EPIC 6 | v0.8.2 | Teleportation (Postponed — covered by TransitionService) |
| EPIC 8 | v0.8 | Progression & Persistence |
| EPIC 10 | v0.8.2 | Diagnostics & Logging |

---

## 4. NEXT SPRINT

### Sprint 5 — Scanner & Discovery ✅ COMPLETE

**Goal:** Гравець відкриває локації через сканування.

**Stories:**
- [x] Create SurfaceScannerUI for "Seat Planet Surface Scanner"
- [x] Add ScannerService (server-side)
- [x] Implement scan progress animation
- [x] Mark locations as discovered in ProfileService
- [x] Update PilotUI to show only discovered locations

### Sprint 6 — Location Gameplay (EPIC 7)

**Goal:** Локації мають геймплей.

**Stories:**
- [ ] Define primary goal for Location_1 (tutorial)
- [ ] Define primary goal for Location_2 (exploration)
- [ ] Implement goal completion tracking
- [ ] Add failure/success outcomes

---

## NOTES

- Backlog є **живим документом**
- Пріоритет — **стабільність ядра**
- Контент додається після стабілізації систем
