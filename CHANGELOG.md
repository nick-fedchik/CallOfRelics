# Changelog — Call of Relics: Orbital Silence

Всі значущі зміни в проєкті документуються у цьому файлі.

---

## [0.12.0] - 2026-01-20 - Ramp Visual Effects

### Added - Ramp Stripes Pulsating Animation

- **SpaceShipService.lua** (v0.7) — візуальні ефекти трапу
  - `GetRampStripes(ship)` — знаходить всі stripe частини (LeftStripe_N, RightStripe_N)
  - `StartRampStripesPulse(player, ship)` — запускає пульсуючу анімацію
  - `StopRampStripesPulse(player, ship)` — зупиняє анімацію та ховає смужки
  - Анімація: transparency 0.1↔0.7, brightness 1↔3, цикл 2 секунди
  - Інтегровано в `DeployRamp()` — запуск пульсації
  - Інтегровано в `RetractRamp()` — зупинка пульсації
  - Оновлено `CleanupRampState()` — очищення pulse state

- **SpaceShipConfig.lua** (v0.7) — розширена конфігурація
  - Додано інформацію про систему освітлення корабля
  - Додано PilotMonitorLeft, PilotMonitorRight конфігурацію
  - Додано RampStripes до Structure.Ramp

### Changed - Engine Fire Effects

- **SpaceShipService.lua** (v0.6) — ефекти вогню двигунів
  - `GetEngineFires()` — знаходить Fire ефекти в BottomEngineLeft/Right
  - `SetEngineFires(ship, enabled)` — вмикає/вимикає Fire.Enabled
  - Інтегровано в `SetShipLanded()`:
    - Приземлення: вогонь вимикається
    - Зліт: вогонь вмикається
  - На орбіті двигуни завжди працюють (Fire enabled)

### Visual Behavior

- **Коли трап випущено:**
  - RampStripes — пульсуюча анімація (привертає увагу)
  - Transparency: 0.1 (яскраво) ↔ 0.7 (тьмяно)
  - Цикл: 2 секунди (1 сек яскраво, 1 сек тьмяно)

- **Коли трап згорнуто:**
  - RampStripes — сховані (Transparency = 1)
  - Анімація зупинена

- **Двигуни:**
  - На орбіті/в польоті: Fire enabled
  - Після приземлення: Fire disabled
  - При зльоті: Fire enabled

---

## [0.11.0] - 2026-01-19 - Ramp System

### Added - Ship Ramp System

- **SpaceShipService.lua** (v0.5) — система посадочного трапу
  - `SetShipLanded(player, isLanded)` — контроль стану приземлення
  - `DeployRamp(player)` — розгортання трапу з анімацією (Step1 → Step10)
  - `RetractRamp(player)` — згортання трапу з анімацією (Step10 → Step1)
  - `IsShipLanded(player)`, `IsRampDeployed(player)` — перевірка стану
  - RampTrigger touch detection — автоматичне розгортання при наближенні
  - RearShipExit collision control — блокування виходу в космосі/польоті
  - Ініціалізація трапу при spawn (flight mode: hidden, blocked)

- **SpaceShipConfig.lua** (v0.4) — конфігурація трапу
  - `Ramp.animation` — deployDuration, retractDuration, stepDelay, fadeTime
  - `Ramp.trigger` — highlightColor, highlightTransparency, inactiveTransparency
  - `Ramp.exitBlockedTransparency`, `exitOpenTransparency` — візуальний feedback
  - `GetRampConfig()`, `GetRampAnimationTiming()`, `GetRampTriggerConfig()`

- **TransitionService.lua** (v0.8) — інтеграція з Ramp System
  - Landing: `SetShipLanded(player, true)` після приземлення
  - Launch: `RetractRamp()` + `SetShipLanded(player, false)` перед зльотом

### Changed - Ramp Behavior

- **В космосі/польоті:**
  - ShipRamp — схований (Transparency = 1, CanCollide = false)
  - RearShipExit — блокує вихід (CanCollide = true, Transparency = 0.25)
  - RampTrigger — неактивний (без підсвітки)

- **Після приземлення:**
  - RearShipExit — прохідний (CanCollide = false, Transparency = 0.8)
  - RampTrigger — активний (зелена підсвітка, touch detection)
  - ShipRamp — розгортається при торканні тригера

---

## [0.10.0] - 2026-01-16 - Scanner System v2 & Documentation

### Added - Scanner System v2

- **PlanetScannerService.lua** (v0.5) — повна система сканування з persistence
  - Власна батарея сканера (500 одиниць, 100 за скан)
  - Система зношення (wear): -5% точності за кожне сканування
  - Формула виявлення: `discoveryChance = effectiveAccuracy × (visibility / 100)`
  - Перший скан гарантовано успішний (`guaranteedFirstScan = true`)
  - Стан сканера зберігається в профілі гравця (persistent)
  - Ремонт та підзарядка сканера

- **SpaceShipConfig.lua** (v0.3) — конфігурація сканера
  - `Scanner.battery` — батарея (maxCapacity: 500, rechargeRate: 2/sec)
  - `Scanner.accuracy` — зношення (baseAccuracy: 100%, wearPerScan: 5%)
  - `CalculateDiscoveryChance()` — формула ймовірності виявлення
  - `CalculateScanAccuracy()` — розрахунок точності по зношенню
  - `GetScansUntilWornOut()` — макс. сканувань до повного зношення (20)

- **ProfileService.lua** (v0.5) — збереження стану сканера
  - `shipState.modules.scanner` — batteryCharge, scanCount в профілі
  - `GetScannerState()`, `UpdateScannerBattery()`, `IncrementScannerWear()`
  - `RepairScanner()`, `RechargeScannerBattery()`
  - Автоматична міграція старих профілів

- **Location Visibility** — параметр видимості локацій
  - Location_1: visibility = 100% (завжди видима)
  - Location_2: visibility = 70% (типова локація)
  - Впливає на ймовірність виявлення при скануванні

### Added - Documentation

- **PLAYER.md** — новий документ персонажа гравця
  - Походження та передісторія
  - Повна схема профілю (Profile Schema v2)
  - Інвентар: ресурси (втрачаються) vs знання (ніколи)
  - Технічна реалізація ProfileService

- **SPACESHIP.md** (v1.3) — оновлена документація корабля
  - Характеристики швидкості, енергетики, захисту
  - Детальний опис сканера з формулою виявлення
  - Таблиця ймовірності виявлення
  - Механіка зношення та ремонту

- **README.md** (v1.1) — оновлена навігація GameDesign
  - Додано PLAYER.md до структури
  - Оновлено швидкі посилання

### Changed

- **Location Configs** — додано параметр `visibility` для сканування

---

## [0.9.0] - 2026-01-16 - EPIC 3, 4, 5: SpaceShip & Planet Systems

### Added - EPIC 5: Scanner Systems

- **PlanetScannerService.lua** (v0.1) — серверний сервіс для сканування планети
  - `RequestScan()` — обробка запитів на сканування
  - Прогрес-бар з 10 кроків (5 секунд)
  - Cooldown 10 секунд між скануваннями
  - Випадкове відкриття локації з undiscovered list
  - Валідація контексту (тільки Orbit)

- **PlanetSurfaceScannerUI.lua** (v0.1) — клієнтський UI для сканера
  - Кнопка сканування
  - Прогрес-бар анімація
  - Список виявлених локацій
  - Контекст-aware (доступний лише на орбіті)

- **SpaceShipConfig.lua** (v0.1) — об'єднана конфігурація SpaceShip
  - Перейменовано з SeatConfig.lua
  - `Structure` — структура компонентів SpaceShip
  - `Seats` — конфігурація всіх сидінь
  - `GetStructure()`, `GetSeatNames()`, `GetComponentInfo()` API
  - `GetSeatConfig()`, `GetDisplayName()`, `IsSeatKnown()` API

- **SpaceShipService.lua** (v0.4) — структура SpaceShip + seat management
  - Використовує SpaceShipConfig замість локальної структури
  - `GetStructure()`, `GetSeatNames()` делегують до SpaceShipConfig
  - Merged SeatService: seat occupancy tracking, action handlers
  - `OnSeatOccupied()`, `OnSeatVacated()`, `ProcessSeatAction()`
  - `RegisterActionHandler()`, `GetSeatOccupant()`, `GetPlayerSeat()`

### Removed

- **SeatService.lua** — merged into SpaceShipService (seat management now part of ship)
- **SeatConfig.lua** — renamed to SpaceShipConfig.lua

- **RemoteEventsSetup** — Scanner events
  - `RequestScan` — клієнт запитує сканування
  - `ScanProgress` — сервер відправляє прогрес
  - `ScanComplete` — сервер відправляє результат

### Changed - EPIC 5

- **TransitionService.lua** — видалено fallback до Location_1
  - PilotUI показує лише discovered locations
  - Порожній список якщо нічого не відкрито

### Changed - Documentation

- **Docs/** — замінено "Kepler-442b" на "Біллі Рубін" у всіх файлах
- **Docs/Planets/** — перейменовано LOCAL_GDD.md → README.md у всіх підпапках
  - Оновлено внутрішні посилання на README.md

### Added - EPIC 3: SpaceShip System

- **SpaceShipService.lua** (v0.1) — новий сервіс для управління SpaceShip
  - Клонування SpaceShip з `ServerStorage/Actors/` замість `Planet_1/Orbit/Workspace`
  - Підтримка `spaceShipModel` з профілю гравця
  - Fallback до default "SpaceShip" якщо модель не знайдена
  - `SpawnShip()`, `GetShip()`, `DestroyShip()`, `RepositionShip()` API

- **ProfileService.lua** — додано `spaceShipModel` поле в profile schema
  - Default value: "SpaceShip"
  - Дозволяє upgrade system в майбутньому

### Changed - SpaceShip Integration

- **TransitionService.lua** (v0.7) — інтеграція з SpaceShipService
  - `StartGameSequence()` — спавнить SpaceShip з ServerStorage/Actors перед player spawn
  - `SpawnShipAboveLandingPad()` — використовує SpaceShipService замість clone з Orbit

- **LocationService.lua** — SpaceShip більше не копіюється з location Workspace
  - Skip SpaceShip в `CopyModelsToWorkspace()` — керується SpaceShipService

- **ServerBootstrap.server.lua** — ініціалізація SpaceShipService

### Fixed - SpaceShip/Planet Positioning

- **TransitionService.lua** — читання позиції SpaceShip з Orbit Config animationData
  - Замість пошуку SpaceShip в Orbit/Workspace (який тепер в Actors)
  - SpaceShip: `(0, 100, 0)` — за замовчуванням

- **LocationService.lua** (v0.4) — застосування animationData позицій після копіювання моделей
  - `CopyModelsToWorkspace()` приймає animationData параметр
  - Моделі (Planet) позиціонуються згідно з `config.animationData.{modelName}.finalPosition`

- **Orbit/Config.luau** — оновлені позиції в animationData
  - SpaceShip: `(0, 100, 0)` — початкова позиція корабля
  - Planet: `(0, 100, 600)` — планета видима перед кораблем на осі +Z

### Changed - Naming Convention

- **Location ID Format:** `Location%d` → `Location_%d` (Location1 → Location_1)
  - Уніфікація формату з Planet_Id для консистентності
  - **ProfileService.lua** — оновлено default exploredLocations
  - **TransitionService.lua** — оновлено fallback locations
  - **ServerStorage/Planets/** — оновлено Config.luau файли
  - **Docs/** — оновлено всі посилання на Location_1, Location_2

### Added - EPIC 4: Planet & Location Init/Fini System

- **ContextRegistryService.lua** (v0.1) — новий сервіс для відстеження контенту
  - Реєстрація скопійованих скриптів, об'єктів, освітлення
  - Три рівні: Planet, Orbit, Location
  - `CurrentPlanetPath` tracking
  - Автоматичний cleanup при виході гравця

- **LocationService.lua** (v0.5) — Init/Fini система
  - `InitPlanet()` / `FiniPlanet()` — Planet-level scripts
  - `InitOrbit()` / `FiniOrbit()` — Orbit objects + scripts + lighting
  - `InitLocation()` / `FiniLocation()` — Location objects + scripts + lighting
  - Ієрархія: Enter Game → Planet Init → Orbit Init
  - Ієрархія: Landing → Orbit Fini → Location Init
  - Ієрархія: Launch → Location Fini → Orbit Init
  - `GetActiveContexts()`, `GetRegistrySummary()` — utility API

---

## [0.8.2] - 2026-01-15 - Log Cleanup & Optimization

### Changed - Production Logging

Масове очищення verbose логів для production-ready коду. Збережено лише логи зі змінними/станами.

#### Server-Side (~600 рядків видалено)
- **BootSequence.lua** — видалено ~30 verbose логів (stage details)
- **GameStateManager.lua** — збережено лише state transitions
- **ServerBootstrap.server.lua** — видалено init logs
- **LocationService.lua** — видалено ~50 verbose логів, збережено state changes
- **PlayerService.lua** — видалено init/event logs
- **ProfileService.lua** — видалено ~40 verbose логів, збережено critical operations
- **SeatService.lua** — видалено verbose seat logs
- **TransitionService.lua** — видалено ~60 verbose логів, збережено state transitions
- **RemoteEventsSetup.server.lua** — видалено individual event creation logs

#### Client-Side (~325 рядків видалено)
- **ScreenSaverUI.lua** — видалено ~15 verbose логів (init, show, hide, stages)
- **UIManager.lua** — видалено ~5 логів (init, state changes)
- **StatusBarUI.lua** — видалено ~8 логів (init, profile sync)
- **TransitionUI.lua** — видалено ~20 логів (all phase logs)
- **PilotUI.lua** — видалено ~8 логів (init, context, clicks)
- **ClientBootstrap.client.lua** — видалено duplicate-run warning

### Fixed - RunContext Warnings

- **CameraController.client.lua** — Added double-execution prevention
  - Uses `CameraControllerInitialized` attribute pattern (same as ClientBootstrap)
  - Prevents "script will run multiple times" warning in StarterPlayerScripts

### Statistics
- **Total lines removed:** ~925 (303 added, 925 deleted)
- **Files modified:** 16
- **Remaining logs:** Only logs with state/variable parameters (State: X → Y, Player: X, Location: X/Y)

### Logging Strategy
Збережені логи:
- `[GameStateManager] State: LoggedOff → Initializing` ✓
- `[LocationService] ✓ Location loaded: Planet_1/Orbit` ✓
- `[TransitionService] ✓ Landing complete for Sealord_75` ✓

Видалені логи:
- `[Module] Initializing...` ✗
- `[Module] ✓ Ready` ✗
- `[Module] Processing...` ✗

---

## [0.8.1] - 2026-01-15 - Transition System Refactoring

### Changed - Naming Refactoring (Liftoff → Launch)

Уніфікація термінології для процесів переходу між локаціями:

- **Launch** — загальний процес зльоту з поверхні на орбіту
  - Phase 1 (Liftoff) — відрив від поверхні, cockpit view
  - Phase 2 (Ascent) — підйом на орбіту, external view
- **Landing** — загальний процес посадки з орбіти на поверхню
  - Phase 1 (Approach) — наближення, external view
  - Phase 2 (Touchdown) — фінальна посадка, cockpit view

#### Files Changed

| File | Version | Changes |
|------|---------|---------|
| TransitionConfig.lua | 0.1 → 0.2 | `States.Liftoff` → `States.Launch`, `States.Ascending` → `States.Ascent`, timing params |
| TransitionService.lua | 0.4 → 0.5 | `StartLiftoffSequence()` → `StartLaunchSequence()`, RequestLaunch event |
| TransitionUI.lua | 0.8 → 0.9 | `ShowLiftoffPhase1/2()` → `ShowLaunchPhase1/2()`, state handlers |
| PilotUI.lua | 0.6 → 0.7 | `liftoffButton` → `launchButton`, RequestLaunch, button text "Зліт на орбіту" |
| RemoteEventsSetup.server.lua | 0.1 → 0.2 | `RequestLiftoff` → `RequestLaunch` |

### Fixed - Camera Issues
- **TransitionUI.lua (v0.8)**: Fix Launch Phase 1 camera tracking (camera follows player as ship rises)
- **TransitionUI.lua (v0.8)**: Add delay before GameStart cockpit setup to prevent flickering

---

## [0.8.0] - 2026-01-15 - EPIC 8: Progression & Persistence

### Added - Profile System v2

#### ProfileService.lua (v0.2) — Complete progression tracking
- **Extended Profile Schema (v2)**
  - `currentLocation` — Track exact location (not just planet)
  - `lastSafeState` — For respawn on failure
  - `discoveredPlanets` — Set of discovered planets with timestamps
  - `exploredLocations` — Per-planet location tracking with visitCount
  - `visitHistory` — Last 100 visits with timestamps
  - `shipState.hullIntegrity`, `shipState.modules` — Extended ship data
  - `stats` — totalPlayTime, locationsExplored, resourcesCollected, knowledgeDiscovered

- **Profile Update Methods**
  - `UpdateProfile(player, updates)` — Generic merge
  - `MarkLocationDiscovered(player, planetId, locationName)` — Discovery + visitCount
  - `UpdateCurrentState(player, planetId, locationName)` — Current location tracking
  - `AddResources(player, resourceId, quantity)` — Resource stacking
  - `RemoveResources(player, resourceId, quantity)` — Resource removal (can fail)
  - `AddKnowledge(player, knowledgeEntry)` — Knowledge (never removed)
  - `GetExploredLocationsForPlanet(player, planetId)` — Per-planet locations

- **Mid-Session Auto-Save**
  - Auto-save every 5 minutes
  - Event-triggered saves on landing/liftoff
  - 10-second debounce between saves
  - `TriggerEventSave(player, eventName)` — Manual save trigger

- **Profile Migration**
  - Automatic v1 → v2 migration for existing profiles
  - Backward compatible with all existing data

#### RemoteEvents (NEW)
- `ProfileUpdate` — Server → Client: push profile changes
- `RequestProfileSync` — Client → Server: request full profile

#### Client-Side Sync
- **StatusBarUI.lua (v0.4)** — Profile sync listener
  - `SetupProfileSync()` — Setup event listeners
  - Real-time planet/location updates
  - Initial sync on game start

### Changed
- **TransitionService.lua (v0.2)** — ProfileService integration
  - `StartLandingSequence()` — Mark location discovered, update state, trigger save
  - `StartLiftoffSequence()` — Update state, trigger save
  - `StartGameSequence()` — Initial state setup
  - `GetAvailableLocations()` — Use per-planet location structure

- **ClientBootstrap.client.lua** — Call `StatusBarUI.SetupProfileSync()`

### EPIC 8 Stories Completed
- ✅ Player progress is saved reliably (auto-save + event saves)
- ✅ Player returns to last known safe state (lastSafeState tracking)
- ✅ Resources may be lost on failure (RemoveResources API)
- ✅ Knowledge is never lost (AddKnowledge only, no removal)

### Testing Checklist
- [ ] New player gets v2 profile with all fields
- [ ] Existing v1 profile migrates to v2 correctly
- [ ] Auto-save triggers every 5 minutes
- [ ] Save triggers on landing/liftoff
- [ ] Location marked discovered after first landing
- [ ] Visit count increments on revisit
- [ ] ProfileUpdate events fire to client
- [ ] StatusBarUI updates on state change

---

## [0.7.0] - 2026-01-14 - Transition System (Orbit ↔ Surface)

### Added - Location Transitions

#### Server-Side
- **TransitionService.lua (v0.7)** — Complete transition coordination
  - `StartGameSequence(player)` — Initial game start (load Orbit, spawn in PilotSeat)
  - `StartLandingSequence(player, locationId)` — Landing from Orbit to Surface
  - `StartLiftoffSequence(player)` — Liftoff from Surface to Orbit
  - `GetAvailableLocations(player)` — Return list of discovered locations
  - Server-side ship animation with TweenService
  - Landing camera data calculation

#### Client-Side
- **TransitionUI.lua (v0.4)** — Transition animations and UI
  - Loading screen with localized messages
  - Landing camera sequence (scriptable camera POV from landing pad)
  - Camera restore after transition
  - StatusBarUI integration for displayName updates
- **PilotUI.lua (v0.5)** — Context-aware pilot interface
  - Orbit context: Location selection menu
  - Surface context: Liftoff button
  - DisplayName localization for locations

#### Configuration
- **TransitionConfig.lua (v0.1)** — Transition parameters
  - Animation durations (landing, liftoff, loading)
  - Camera offsets for landing POV
  - Ship spawn/landing heights
  - Localized messages (Ukrainian)
  - Transition states enum

#### RemoteEvents (NEW)
- `RequestLanding` — Client → Server: request landing on location
- `RequestLiftoff` — Client → Server: request liftoff to orbit
- `TransitionUpdate` — Server → Client: transition state updates
- `TransitionLandingCamera` — Server → Client: landing camera data
- `AvailableLocationsResponse` — Server → Client: list of locations
- `RequestAvailableLocations` — Client → Server: request locations

#### Planet Configuration
- **Planet_1/Config.luau** — Added `displayName = "Kepler-442b"`
- **Orbit/Config.luau** — Added `displayName = "Орбіта"`, `animationData` for transitions
- **Location1/Config.luau** — Added `displayName = "Зелена долина"`
- **Location2/Config.luau** — Added `displayName = "Гірський хребет"`

### Changed
- **BootSequence.lua (v0.4)** — Optimized boot sequence
  - Stage 4 now only validates assets (doesn't load location)
  - Location loading moved to TransitionService.StartGameSequence()
  - Faster "Почати гру" button appearance
- **StatusBarUI.lua** — Now displays `displayName` instead of technical IDs
  - Planet: "Kepler-442b" instead of "Planet_1"
  - Location: "Орбіта" instead of "Orbit"
- **GameConfig.lua (v0.3)** — Updated version to 0.7, VersionTag to "Transition System"

### Fixed
- StatusBar displaying technical names (Planet_1) instead of displayName (Kepler-442b)
- Camera not restoring properly after transition complete
- PilotUI context detection on initial show

### Architecture Improvements
- **Scriptable Camera Pattern** — Cinematic landing view with camera restore
- **DisplayName Localization** — All UI shows Ukrainian display names
- **Lazy-loaded StatusBarUI** — Avoids circular dependencies in TransitionUI
- **Server-authoritative Transitions** — All animations coordinated from server

### Documentation
- **KB.md (v0.2)** — Added Transition System section
- **FOLDER_STRUCTURE.md (v1.1)** — Updated with new files and SS/Planets structure
- **README_GUI_DEV.md** — Updated with TransitionUI and SeatUI documentation

### Testing Checklist
- [x] GameStart loads Orbit and spawns player in PilotSeat
- [x] PilotUI shows location list on Orbit
- [x] Clicking location starts landing sequence
- [x] Loading screen shows localized message
- [x] Landing camera shows ship from above
- [x] Ship animates down to landing pad
- [x] Camera restores after landing
- [x] StatusBar shows displayName for planet and location
- [x] PilotUI shows "На орбіту" button on Surface
- [x] Liftoff sequence works (reverse process)

---

## [0.6.0] - 2026-01-12 - Location Loading System

### Added - Location Management

#### Server-Side
- **LocationService.lua (v0.1)** — Complete location loading system
  - LoadLocation(player, planetId, locationName) — Load level from ServerStorage
  - UnloadLocation(player) — Complete context cleanup (TDD 5.6)
  - SpawnPlayerInLocation(player, spawnType) — Spawn in PilotSeat or SpawnLocation
  - ClearWorkspace() — Clear all models and lighting
  - Track current location per player
  - Support for Orbit and Surface location types
- **BootSequence.lua (v0.4)** — LocationService integration
  - Stage 4: Load initial location (Planet_1/Orbit)
  - Spawn player in SpaceShip PilotSeat on game start
- **ServerBootstrap.server.lua (v0.2)** — LocationService initialization
  - Phase 3: Initialize LocationService before PlayerService

#### ServerStorage Structure
- **Planets/Planet_1/Config.luau** — Main planet configuration
  - Planet metadata, structure, settings
  - Helper functions: getLocation(), getAllLocations()
- **Planets/Planet_1/Orbit/Config.luau** — Orbital location config
  - SpaceShip model (483 parts, torpedoes, turrets, pilot seat)
  - Planet model with atmosphere and cloud layers
  - Zero gravity settings, space combat enabled
- **Planets/Planet_1/Surface/Location1/Config.luau** — Surface location 1
  - Standard gravity, spawn points, baseplate
  - Helper functions: findObject(), getSettings()
- **Planets/Planet_1/Surface/Location2/Config.luau** — Surface location 2
  - Identical structure to Location1

### Changed
- Boot sequence Stage 4 now loads game level before showing "Почати гру"
- Player spawns directly in PilotSeat inside SpaceShip (not default spawn)
- Orbit location uses standard Roblox gravity (196.2) instead of zero gravity

### Fixed
- LocationService.Initialize() missing return value (v0.6.0 hotfix)
- LocationService.SpawnPlayerInLocation() incorrect Seat API usage (use Seat:Sit() instead of Humanoid.SeatPart)
- Workspace.Gravity setting now uses absolute value (math.abs) for correct physics
- Player spawn in PilotSeat with proper sitting mechanics

### Architecture Improvements
- **TDD 5.6 Compliance** — Complete context cleanup on location unload
- **TDD 3.2 Service Pattern** — LocationService as coordinating service
- **Modular Level Structure** — Each location self-contained with Config
- **Config-Driven Content** — Helper functions for querying structure/settings

### Next Steps
- Test location loading in Roblox Studio
- Verify SpaceShip and Planet models appear in Workspace
- Verify player spawns in PilotSeat
- Implement location transitions (Orbit ↔ Surface)

---

## [0.5.0] - 2026-01-12 - EPIC 1 COMPLETE ✅

### Added - Phase 2 & 3: Enhanced Boot Sequence

#### Server-Side
- **BootSequence.lua (v0.3)** — 4-stage server-driven boot sequence
  - Dynamic progress calculation (25%, 50%, 75%, 100%)
  - Error handling with retry support
  - Stage 1: Game Configuration
  - Stage 2: Player Information
  - Stage 3: Profile Loading (with error state)
  - Stage 4: Ready State
- **ProfileService.lua (v0.2)** — DataStore integration
  - Player profile management
  - New/returning player detection
  - Graceful degradation without DataStore
- **GameConfig.lua (v0.3)** — BootStages configuration
  - Dynamic stage definitions
  - Error messages configuration
  - Retry settings

#### Client-Side
- **ScreenSaverUI.lua (v0.5)** — Progressive boot UI ⭐ MAJOR UPDATE
  - 1200px wide progress bar (3x wider)
  - 16px height progress bar (2x taller, bold)
  - Rounded corners (8px radius)
  - Brighter blue color (RGB 120,180,255)
  - Server-driven progress tracking (0% → 25% → 50% → 75% → 100%)
  - Error state with red alert + retry button
  - 1 second pause at 100% before button
  - Cumulative/progressive UI pattern (no flickering)
- **StatusBarUI.lua (v0.2)** — Right-aligned elements fix
- **UIManager.lua (v0.2)** — State-based UI coordination

#### RemoteEvents
- `BootStageUpdate` — Server → Client progress updates
- `ConfirmGameStart` — Client → Server game start confirmation
- `RetryBootStage` — Client → Server retry request

#### Documentation
- **Docs/KB.md** — Comprehensive Knowledge Base (1190 lines)
  - Section 1: Studio Setup (Script Sync, API Services)
  - Section 2: Architectural Patterns
  - Section 3: State Management
  - Section 4: UI/UX Patterns
  - Section 5: Client-Server Communication
  - Section 6: Roblox API Best Practices
  - Section 7: Lessons Learned
  - Section 8: Epic 1 Complete Implementation ⭐ NEW

### Changed
- **ScreenSaverUI**: Removed spinning dots animation (cleaner UX)
- **ScreenSaverUI**: Removed "Готовність 100%" text (button is self-explanatory)
- **GameConfig**: Replaced individual stage durations with BootStages array
- **ClientBootstrap.client.lua (v0.3)**: Switched from dev to main ScreenSaverUI

### Removed
- `ScreenSaverUI-dev.lua` — Merged into main version
- `EPIC1_IMPLEMENTATION.md` — Consolidated into KB.md
- `EPIC1_4STAGE_IMPLEMENTATION.md` — Superseded by current implementation
- `PHASE_2_3_PLAN.md` — Completed and integrated
- `TEST_REPORT_FULL_CYCLE.md` — Superseded by KB.md testing checklist

### Fixed
- Progress bar transparency initialization (all elements start at transparency = 1)
- Error state transparency for icon, text, and button
- StatusBar element alignment (moved to right side)

### Architecture Improvements
- **Cumulative UI Pattern** — Elements accumulate stage by stage (no black screens)
- **Server-Driven Progress** — Easy to extend (add 5th stage = auto 20% per stage)
- **Error Recovery** — Graceful error handling with user retry option
- **Modular Boot Sequence** — Each stage is independent and testable

### Testing
- [x] 4-stage boot sequence (25% → 50% → 75% → 100%)
- [x] Progress bar visibility and animations
- [x] 1 second pause after 100%
- [x] Avatar loading
- [x] State transitions
- [x] LogOff → ScreenSaver reset
- [x] StatusBar display in InGame
- [x] Single-player enforcement
- [ ] Error state display (partial - needs more testing)
- [ ] Retry button functionality (needs testing)

---

## [0.2.0] - 2026-01-11 - Structure Refactoring

### Added
- Структура папок ServerScriptService (Core, Services, Systems, Setup)
- Документація структури проєкту (Docs/FOLDER_STRUCTURE.md)
- Інструкція налаштування Script Sync (SETUP_SCRIPT_SYNC.md)
- Рекомендації щодо структури у TDD розділ 13.3.2

### Changed
- **BREAKING:** Переміщено GameStateManager → ServerScriptService/Core/
- **BREAKING:** Переміщено ServerBootstrap → ServerScriptService/Core/
- **BREAKING:** Переміщено PlayerService → ServerScriptService/Services/
- **BREAKING:** Переміщено RemoteEventsSetup → ServerScriptService/Setup/
- Оновлено шляхи require() у ServerBootstrap (рядки 62-68)
- Оновлено шляхи require() у PlayerService (рядки 60-61)
- Оновлено EPIC1_IMPLEMENTATION.md з новими шляхами

### Fixed
- Виправлено "Infinite yield" помилку через застарілі шляхи до модулів

---

## [0.1.0] - 2026-01-11

### Added - EPIC 1: Game Boot & Global States

#### Server-Side
- GameStateManager.lua — координатор глобальних станів
- ServerBootstrap.server.lua — серверна ініціалізація
- PlayerService.lua — керування життєвим циклом гравця
- RemoteEventsSetup.server.lua — створення RemoteEvents

#### Client-Side
- ClientBootstrap.client.lua — клієнтська ініціалізація
- ScreenSaverUI.lua — інтерфейс ScreenSaver
- UIManager.lua — керування UI станами

#### Documentation
- EPIC1_IMPLEMENTATION.md — повний опис реалізації EPIC 1
- Docs/TDD.md — Technical Design Document v0
- Docs/GDD.md — Game Design Document
- Docs/Backlog.md — Product backlog

#### Features
- Повний життєвий цикл гри (Boot → LoggedOff → Initializing → InGame)
- ScreenSaver UI з можливістю входу (Space/Click)
- Глобальні стани: LoggedOff, Initializing, InGame
- Валідація переходів між станами
- Однокористувацька гра (single-player constraint)
- Server-authoritative архітектура
- Стандартизоване логування (TDD Section 11)
- Обробка помилок (TDD Section 10)

### Architecture
- Реалізовано State-driven architecture (TDD 1.2)
- Реалізовано єдиний координатор станів (TDD 2.5)
- Реалізовано принцип "Request → Verification → Permission" (TDD 3.4)
- Реалізовано boot sequence (TDD 4.3)
- Всі модулі мають стандартизовані заголовки (TDD 11.8)

---

## Формат

Цей changelog дотримується принципів [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Категорії змін:
- **Added** — нові можливості
- **Changed** — зміни існуючої функціональності
- **Deprecated** — функціональність, що застаріла
- **Removed** — видалена функціональність
- **Fixed** — виправлення помилок
- **Security** — виправлення безпеки

---

**Примітка:** BREAKING позначає зміни, що вимагають оновлення у Roblox Studio.
