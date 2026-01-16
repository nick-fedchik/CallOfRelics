# Backlog.md
**Project:** Call of Relics: Orbital Silence
**Type:** Single-player Exploration RPG (Roblox)
**Backlog Version:** 0.5
**Status:** Active Development
**Current Version:** 0.8.2

---

## 1. ROADMAP

### Phase 0 — Foundations ✅ COMPLETE
- Архітектурне ядро гри
- Глобальні стани (LoggedOff, Initializing, InGame)
- Boot sequence з 4-stage UI

### Phase 1 — Core Gameplay Loop ⏳ IN PROGRESS
> Орбіта → Локація → Повернення → Прогрес

**Завершено:**
- Перша планета (Kepler-442b)
- 2 локації (Location1, Location2)
- Transition система (Landing/Launch)

**В роботі:**
- SpaceShip система (EPIC 3)
- Planet & Location система (EPIC 4)
- Сканування планет (EPIC 5)
- Gameplay локацій (EPIC 7)

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

### EPIC 4 — Planet & Location System ⏳ 3/4

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
│   │   └── Lighting/              # → game.Workspace.Lighting
│   ├── ReplicatedStorage/         # Orbit Scripts
│   ├── ServerScriptService/       # Orbit Scripts
│   └── StarterPlayer/             # Orbit Scripts
└── Surface/
    └── Location_Id/
        ├── Config.luau            # Location config
        ├── Workspace/
        │   └── Lighting/          # → game.Workspace.Lighting
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

**Завершені Stories:**
- [x] Planet configuration stored in Config.luau
- [x] Orbit folder with Planet model
- [x] Surface folder with Location subfolders

**Незакриті Stories:**
- [ ] Planet Init/Fini with PlanetScriptsRegistry
- [ ] Orbit Init/Fini with OrbitObjectsRegistry + OrbitScriptsRegistry
- [ ] Location Init/Fini with LocationObjectsRegistry + LocationScriptsRegistry
- [ ] Workspace/Lighting objects copied to game.Workspace.Lighting
- [ ] CurrentPlanetPath tracks active planet
- [ ] Locations have independent rules (gravity, hazards, time limits)

---

### EPIC 5 — Scanner Systems 🆕 0/4

**Опис:** Виявлення нового контенту через сканування.

**Stories:**
- [ ] Player can scan planet surface from orbit
- [ ] Scanner reveals undiscovered locations
- [ ] Scanner feedback is visual and clear
- [ ] Scanner cannot be used in invalid contexts

---

### EPIC 7 — Location Gameplay (Arcades) 🆕 0/4

**Опис:** Локації як окремі ігрові аркади.

**Stories:**
- [ ] Each location has a primary goal
- [ ] Locations may have optional objectives
- [ ] Player can fail exploration
- [ ] Failure has consequences but preserves knowledge

---

### EPIC 9 — UI & UX ⏳ 3/4

**Незакриті Stories:**
- [ ] UI explains restrictions to player (tooltips, disabled states)

---

### EPIC 3 — SpaceShip System ⏳ 0/4

**Опис:** SpaceShip як основна локація гравця, незалежна від планет.

**Специфікація:**

```
ServerStorage/Actors/
├── SpaceShip                    # Default model
├── SpaceShip_Advanced           # Upgraded model (TBD)
└── SpaceShip_Elite              # Upgraded model (TBD)
```

**SpaceShip Lifecycle:**
- Clone до `game.Workspace` на старті гри
- Destroy з `game.Workspace` по завершенні гри
- Незалежний від Planet/Location системи
- `ModelStreamingMode = Persistent`

**SpaceShip Upgrade:**
- Профіль гравця зберігає `spaceShipModel` посилання
- Fallback до `SpaceShip` якщо модель не знайдена

**Stories:**
- [ ] SpaceShip model stored in ServerStorage/Actors/
- [ ] SpaceShip cloned to Workspace on game start
- [ ] SpaceShip destroyed from Workspace on game end
- [ ] SpaceShip model loaded from player profile (upgrade system)

---

## 3. COMPLETED EPICS (Archive)

| EPIC | Version | Description |
|------|---------|-------------|
| EPIC 1 | v0.5 | Game Boot & Global States |
| EPIC 2 | v0.5 | Game State Architecture |
| EPIC 6 | v0.8.2 | Teleportation (Postponed — covered by TransitionService) |
| EPIC 8 | v0.8 | Progression & Persistence |
| EPIC 10 | v0.8.2 | Diagnostics & Logging |

---

## 4. NEXT SPRINT

### Sprint 5 — Scanner & Discovery

**Goal:** Гравець відкриває локації через сканування.

**Stories:**
- [ ] Create ScannerUI for PilotSeat
- [ ] Add ScannerService (server-side)
- [ ] Implement scan progress animation
- [ ] Mark locations as discovered in ProfileService
- [ ] Update PilotUI to show only discovered locations

---

## NOTES

- Backlog є **живим документом**
- Пріоритет — **стабільність ядра**
- Контент додається після стабілізації систем
