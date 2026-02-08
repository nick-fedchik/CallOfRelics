# Architecture Documentation
**Project:** Call of Relics: Orbital Silence
**Version:** 1.1
**Date:** 2026-02-08

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Components Diagram](#2-components-diagram)
   - [Server Side](#21-server-side)
   - [UI (Client)](#22-ui-client)
   - [Replicated Storage](#23-replicated-storage)
3. [ServerStorage](#3-serverstorage)
   - [Planets Structure](#31-planets-structure)
4. [Game Boot Sequence](#4-game-boot-sequence)
5. [Loading Level Sequence](#5-loading-level-sequence)
6. [Unloading Level Sequence](#6-unloading-level-sequence)
7. [Game Statuses and State Machine](#7-game-statuses-and-state-machine)
8. [Events](#8-events)
9. [Player Profile](#9-player-profile)

---

## 1. Architecture Overview

Call of Relics використовує **сервіс-орієнтовану архітектуру** з чітким розділенням відповідальностей між сервером і клієнтом.

```mermaid
flowchart TB
    subgraph Client["🖥️ Client (StarterPlayerScripts)"]
        CB[ClientBootstrap]
        UI[UI Modules]
        SeatUI[Seat UI System]
    end

    subgraph Server["🖧 Server (ServerScriptService)"]
        SB[ServerBootstrap]
        Services[Services Layer]
        Setup[Setup Scripts]
    end

    subgraph Shared["📦 Shared (ReplicatedStorage)"]
        Config[Game Configs]
        Events[RemoteEvents]
        Modules[Shared Modules]
    end

    subgraph Storage["📁 ServerStorage"]
        Planets[Planets Content]
        Actors[Actors/Ships]
    end

    Client <-->|RemoteEvents| Server
    Client --> Shared
    Server --> Shared
    Server --> Storage

    SB --> Services
    Services --> Storage
```

### Ключові принципи

| Принцип | Опис |
|---------|------|
| **Service-Oriented** | Кожна фіча інкапсульована в окремому сервісі |
| **State Machine** | Глобальний стан гри (LoggedOff → Initializing → InGame) |
| **Profile Persistence** | Весь прогрес зберігається в DataStore |
| **Context Hierarchy** | Ієрархія Planet/Orbit/Location з Init/Fini очисткою |
| **Configuration-Driven** | Централізовані конфіги (GameConfig, SpaceShipConfig, TransitionConfig) |

---

## 2. Components Diagram

### 2.1 Server Side

```mermaid
flowchart TB
    subgraph Bootstrap["🚀 Bootstrap"]
        RES[RemoteEventsSetup]
        SB[ServerBootstrap v0.2]
    end

    subgraph Core["⚙️ Core Services"]
        GSM[GameStateManager v0.1]
        PS[ProfileService v0.5]
        LS[LocationService v0.7]
    end

    subgraph Player["👤 Player Services"]
        PLS[PlayerService v0.1]
        BS[BootSequence v0.5]
    end

    subgraph Ship["🚀 Ship Services"]
        SSS[SpaceShipService v0.8]
        TS[TransitionService v0.10]
    end

    subgraph Discovery["🔍 Discovery Services"]
        PSS[PlanetScannerService v0.5]
        CRS[ContextRegistryService v0.1]
    end

    subgraph Stubs["📋 Stub Services"]
        PCS[PersonalComputerService v0.1]
        PLOCS[PlanetLocatorService v0.1]
    end

    RES --> SB
    SB --> GSM
    SB --> PS
    SB --> LS
    SB --> PLS
    SB --> SSS
    SB --> TS
    SB --> PSS

    PLS --> BS
    TS --> LS
    TS --> SSS
    LS --> CRS
```

#### Services Reference

| Service | Version | Відповідальність |
|---------|---------|------------------|
| **GameStateManager** | 0.1 | Глобальні стани гри, валідація переходів |
| **ProfileService** | 0.5 | Профілі гравців, DataStore, міграція v1→v2 |
| **LocationService** | 0.7 | Завантаження/вивантаження локацій, LevelController Init/Fini |
| **PlayerService** | 0.1 | Життєвий цикл гравця (LogOn/LogOff) |
| **SpaceShipService** | 0.8 | Спавн корабля, сидіння, рампа, ефекти |
| **TransitionService** | 0.10 | Послідовності Landing/Launch |
| **PlanetScannerService** | 0.5 | Сканування поверхні, відкриття локацій |
| **ContextRegistryService** | 0.1 | Реєстр скопійованого контенту для очистки |

---

### 2.2 UI (Client)

```mermaid
flowchart TB
    subgraph Bootstrap["🚀 Client Bootstrap"]
        CB[ClientBootstrap v0.2]
    end

    subgraph Core["📱 Core UI"]
        UIM[UIManager]
        SSU[ScreenSaverUI]
        SBU[StatusBarUI]
        TUI[TransitionUI v0.15]
    end

    subgraph SeatSystem["💺 Seat UI System"]
        SUIM[SeatUIManager]

        subgraph Seats["Seat UIs"]
            PUI[PilotUI]
            EUI[EnginesUI]
            PLUI[PlanetLocatorUI]
            PSSUI[PlanetSurfaceScannerUI]
            PCUI[PersonalComputerUI]
            GSUI[GenericSeatUI]
        end
    end

    CB --> SSU
    CB --> SBU
    CB --> UIM
    CB --> SUIM
    CB --> TUI

    SUIM --> Seats

    UIM -.->|State Events| SSU
    UIM -.->|State Events| SBU
```

#### UI Modules Reference

| UI Module | Призначення |
|-----------|-------------|
| **UIManager** | Координація UI на основі станів |
| **ScreenSaverUI** | Екран завантаження, splash screen |
| **StatusBarUI** | HUD статус інформація |
| **TransitionUI** | Анімації Landing/Launch, переходи екранів |
| **SeatUIManager** | Управління активацією Seat UI |
| **PilotUI** | UI пілотського крісла, управління кораблем |
| **PlanetSurfaceScannerUI** | UI сканера, прогрес, результати |

---

### 2.3 Replicated Storage

```mermaid
flowchart LR
    subgraph RS["📦 ReplicatedStorage"]
        subgraph Game["Game/"]
            GC[GameConfig v0.8]
            SSC[SpaceShipConfig v0.7]
            TC[TransitionConfig v0.3]
        end

        subgraph Events["RemoteEvents/"]
            direction TB
            CoreE[Core Events]
            SeatE[Seat Events]
            TransE[Transition Events]
            ProfileE[Profile Events]
            ScanE[Scanner Events]
        end

        subgraph Modules["Modules/"]
            Shared[Shared Utilities]
        end
    end
```

#### Configuration Modules

| Config | Version | Призначення |
|--------|---------|-------------|
| **GameConfig** | 0.8 | Ідентичність гри, версія, тайминги boot |
| **SpaceShipConfig** | 0.7 | Структура корабля, сидіння, статистика |
| **TransitionConfig** | 0.3 | Тайминги анімацій, параметри камери |

---

## 3. ServerStorage

### 3.1 Planets Structure

```mermaid
flowchart TB
    subgraph SS["📁 ServerStorage"]
        subgraph Planets["Planets/"]
            subgraph P1["Planet_1/"]
                P1C[Config.luau]

                subgraph P1O["Orbit/"]
                    P1OC[Config.luau]
                    P1OW[Workspace/]
                    P1OL[Lighting/]
                    P1OS[ServerScriptService/]
                    P1OR[ReplicatedStorage/]
                end

                subgraph P1S["Surface/"]
                    subgraph L1["Location_1/"]
                        L1C[Config.luau]
                        L1W[Workspace/]
                        L1L[Lighting/]
                        L1S[ServerScriptService/]
                        L1R[ReplicatedStorage/]
                    end

                    subgraph L2["Location_2/"]
                        L2C[Config.luau]
                        L2W[Workspace/]
                    end
                end
            end

            P2["Planet_2/"]
            PE["Planet_Earth/"]
        end

        subgraph Actors["Actors/"]
            Ship[SpaceShip Model]
        end
    end
```

#### Planets Hierarchy

```
ServerStorage/
├── Planets/
│   ├── Planet_1/                    ← "Біллі Рубін"
│   │   ├── Config.luau              ← Planet metadata
│   │   ├── Orbit/
│   │   │   ├── Config.luau          ← Orbital settings, arrival animation
│   │   │   ├── Workspace/           ← Planet model, skybox
│   │   │   ├── Lighting/            ← Space lighting
│   │   │   ├── ServerScriptService/ ← Cloned as folder, LevelController entry point
│   │   │   └── ReplicatedStorage/   ← Orbital modules
│   │   └── Surface/
│   │       ├── Location_1/
│   │       │   ├── Config.luau      ← Location metadata, landing pad
│   │       │   ├── Workspace/       ← Baseplate, zones, landing pad
│   │       │   ├── Lighting/        ← Surface lighting
│   │       │   ├── ServerScriptService/ ← Cloned as folder, LevelController entry point
│   │       │   └── ReplicatedStorage/
│   │       └── Location_2/
│   ├── Planet_2/
│   └── Planet_Earth/
└── Actors/
    └── SpaceShip/                   ← Ship template for cloning
```

---

## 4. Game Boot Sequence

```mermaid
sequenceDiagram
    autonumber
    participant Setup as RemoteEventsSetup
    participant SB as ServerBootstrap
    participant GSM as GameStateManager
    participant PS as ProfileService
    participant LS as LocationService
    participant PLS as PlayerService
    participant SSS as SpaceShipService
    participant TS as TransitionService
    participant PSS as PlanetScannerService

    Note over Setup,PSS: 🚀 Server Boot Phase

    Setup->>Setup: Create RemoteEvents
    Setup->>SB: Events Ready

    SB->>GSM: Init()
    GSM-->>SB: State = LoggedOff

    SB->>PS: Init()
    PS-->>SB: DataStore Connected

    SB->>LS: Init()
    LS-->>SB: ContextRegistry Ready

    SB->>PLS: Init()
    PLS-->>SB: Player Listeners Ready

    SB->>SSS: Init()
    SSS-->>SB: Ship Templates Ready

    SB->>TS: Init()
    TS-->>SB: Transitions Ready

    SB->>PSS: Init()
    PSS-->>SB: Scanner Ready

    Note over Setup,PSS: ✅ Server Ready for Players
```

### Player Join Sequence

```mermaid
sequenceDiagram
    autonumber
    participant Player
    participant PLS as PlayerService
    participant GSM as GameStateManager
    participant BS as BootSequence
    participant PS as ProfileService
    participant LS as LocationService
    participant Client

    Note over Player,Client: 👤 Player Join Phase

    Player->>PLS: PlayerAdded
    PLS->>PLS: LogOnPlayer()
    PLS->>GSM: RequestStateChange(Initializing)
    GSM-->>Client: StateChanged(Initializing)

    PLS->>BS: StartBoot(player)

    Note over BS,Client: Stage 1: Game Config
    BS->>Client: BootStageUpdate(1, GameConfig)
    Client-->>BS: Stage 1 OK

    Note over BS,Client: Stage 2: Character Spawn
    BS->>BS: Spawn temp character
    BS->>Client: BootStageUpdate(2, PlayerInfo)
    Client-->>BS: Stage 2 OK

    Note over BS,PS: Stage 3: Profile Load
    BS->>PS: LoadProfile(player)
    PS->>PS: DataStore:GetAsync()
    PS-->>BS: Profile loaded
    BS->>Client: BootStageUpdate(3, ProfileData)
    Client-->>BS: Stage 3 OK

    Note over BS,LS: Stage 4: Initial Location
    BS->>LS: InitOrbit(player, planet1)
    LS-->>BS: Orbit loaded
    BS->>Client: BootStageUpdate(4, Ready)

    Note over Client,GSM: 🎮 Player Confirms Start
    Client->>GSM: ConfirmGameStart
    GSM->>GSM: RequestStateChange(InGame)
    GSM-->>Client: StateChanged(InGame)
```

---

## 5. Loading Level Sequence

### Landing Sequence (Orbit → Surface)

```mermaid
sequenceDiagram
    autonumber
    participant Client
    participant TUI as TransitionUI
    participant TS as TransitionService
    participant LS as LocationService
    participant CRS as ContextRegistry
    participant SSS as SpaceShipService

    Note over Client,SSS: ⬇️ Landing: Orbit → Surface

    Client->>TS: RequestLanding(locationId)
    TS->>TS: Validate player state

    TS->>Client: TransitionUpdate(landing, phase1)
    TUI->>TUI: ShowLandingPhase1(4s)
    Note over TUI: External view - watch ship descend

    TS->>LS: FiniOrbit(player, keepShip=true)
    LS->>CRS: Cleanup orbit content

    TS->>LS: InitLocation(player, locationId)

    rect rgb(200, 220, 255)
        Note over LS,CRS: 📥 Content Copy Phase
        LS->>LS: Clone Workspace content
        LS->>CRS: Register(Location, objects)
        LS->>LS: Clone Lighting
        LS->>CRS: Register(Location, lighting)
        LS->>LS: Clone ServerScriptService folder
        LS->>CRS: Register(Location, folder)
        Note over LS: Find & require LevelController
        LS->>LS: LevelController.levelInit()
        LS->>LS: Clone ReplicatedStorage
        LS->>CRS: Register(Location, modules)
    end

    TS->>Client: TransitionUpdate(landing, phase2)
    TUI->>TUI: ShowLandingPhase2(3s)
    Note over TUI: Cockpit view - final approach

    TS->>SSS: SetShipLanded(player, true)
    SSS->>SSS: DeployRamp()
    SSS->>SSS: StartRampStepsPulse()

    TS->>Client: TransitionUpdate(complete)
    TUI->>TUI: Hide()
```

### Content Copy Diagram

```mermaid
flowchart LR
    subgraph Source["📁 ServerStorage/Planets/Planet_1/Surface/Location_1"]
        SW[Workspace/]
        SL[Lighting/]
        SS[ServerScriptService/]
        SR[ReplicatedStorage/]
    end

    subgraph Target["🎮 Game Services"]
        TW[game.Workspace]
        TL[game.Lighting]
        TS[game.ServerScriptService]
        TR[game.ReplicatedStorage]
    end

    subgraph Registry["📋 ContextRegistry"]
        R[Location Level Registry]
    end

    SW -->|Clone children| TW
    SL -->|Clone children| TL
    SS -->|Clone folder + LevelController.levelInit| TS
    SR -->|Clone children| TR

    TW -.->|Track| R
    TL -.->|Track| R
    TS -.->|Track| R
    TR -.->|Track| R
```

---

## 6. Unloading Level Sequence

### Launch Sequence (Surface → Orbit)

```mermaid
sequenceDiagram
    autonumber
    participant Client
    participant TUI as TransitionUI
    participant TS as TransitionService
    participant SSS as SpaceShipService
    participant LS as LocationService
    participant CRS as ContextRegistry

    Note over Client,CRS: ⬆️ Launch: Surface → Orbit

    Client->>TS: RequestLaunch()
    TS->>TS: Validate player state

    TS->>SSS: SetShipLanded(player, false)
    SSS->>SSS: StopRampStepsPulse()
    SSS->>SSS: RetractRamp()
    SSS->>SSS: ToggleEngineFire(true)

    TS->>Client: TransitionUpdate(launch, phase1)
    TUI->>TUI: ShowLaunchPhase1(3s)
    Note over TUI: Cockpit view - liftoff

    TS->>Client: TransitionUpdate(launch, phase2)
    TUI->>TUI: ShowLaunchPhase2(4s)
    Note over TUI: External view - ascent

    rect rgb(255, 220, 200)
        Note over LS,CRS: 📤 Content Cleanup Phase
        TS->>LS: FiniLocation(player)
        LS->>CRS: GetRegisteredContent(Location)
        CRS-->>LS: [objects, lighting, scripts, modules]
        LS->>LS: Destroy all registered content
        LS->>CRS: ClearRegistry(Location)
    end

    TS->>LS: InitOrbit(player, planetId)

    rect rgb(200, 255, 220)
        Note over LS,CRS: 📥 Orbit Content Load
        LS->>LS: Clone Orbit/Workspace
        LS->>CRS: Register(Orbit, objects)
        LS->>LS: Clone Orbit/Lighting
        LS->>CRS: Register(Orbit, lighting)
    end

    TS->>Client: TransitionUpdate(arrival)
    TUI->>TUI: ShowArrival(4s)
    Note over TUI: Cockpit view - planet approaches

    TS->>Client: TransitionUpdate(complete)
    TUI->>TUI: Hide()
```

### Cleanup Flow

```mermaid
flowchart TB
    subgraph Fini["🧹 FiniLocation Process"]
        F1[Get registered content from ContextRegistry]
        F1b[LevelController.levelFini — stop loops, cleanup]
        F2[Destroy Workspace objects]
        F3[Destroy Lighting objects]
        F4[Destroy ServerScriptService folder]
        F5[Destroy ReplicatedStorage modules]
        F6[Clear registry for Location level]
    end

    F1 --> F1b --> F2 --> F3 --> F4 --> F5 --> F6

    subgraph Hierarchy["📊 Cleanup Hierarchy"]
        L[Location Level]
        O[Orbit Level]
        P[Planet Level]
    end

    L -->|First| O -->|Then| P

    Note1[Location Fini cleans Location content only]
    Note2[Orbit Fini cleans Orbit content]
    Note3[Planet Fini cleans Planet-level scripts]
```

---

## 7. Game Statuses and State Machine

### Global Game States

```mermaid
stateDiagram-v2
    [*] --> LoggedOff: Server Start

    LoggedOff --> Initializing: Player Joins\n(LogOnPlayer)

    Initializing --> InGame: ConfirmGameStart\n(Boot Complete)

    InGame --> LoggedOff: Player Leaves\n(LogOffPlayer)

    note right of LoggedOff
        No active player
        Server idle state
    end note

    note right of Initializing
        Boot sequence active
        Loading profile
        Setting up location
    end note

    note right of InGame
        Player playing
        All systems active
    end note
```

### Transition States

```mermaid
stateDiagram-v2
    [*] --> Idle: Game Start

    state "Orbit Context" as Orbit {
        Idle --> Landing: RequestLanding
        Landing --> LandingPhase1: Start descent
        LandingPhase1 --> LandingPhase2: Switch to cockpit
        LandingPhase2 --> Landed: Touch down
    }

    state "Surface Context" as Surface {
        Landed --> Exploring: Ramp deployed
        Exploring --> Launch: RequestLaunch
        Launch --> LaunchPhase1: Liftoff
        LaunchPhase1 --> LaunchPhase2: External view
        LaunchPhase2 --> Ascending: Ship rises
    }

    Ascending --> Arrival: Reach orbit
    Arrival --> Idle: Animation complete

    Landed --> Exploring
    Exploring --> Landed: Return to ship
```

### State Transitions Table

| From State | To State | Trigger | Validation |
|------------|----------|---------|------------|
| LoggedOff | Initializing | Player.PlayerAdded | Single player only |
| Initializing | InGame | ConfirmGameStart | Boot complete |
| InGame | LoggedOff | Player.PlayerRemoving | Save profile |
| Idle | Landing | RequestLanding | Player in PilotSeat |
| Landed | Launch | RequestLaunch | Player in PilotSeat |
| Launch | Arrival | Animation complete | - |
| Arrival | Idle | Animation complete | - |

---

## 8. Events

### Events Architecture

```mermaid
flowchart TB
    subgraph RemoteEvents["📡 RemoteEvents (ReplicatedStorage)"]
        subgraph Core["Core Events"]
            LOR[LogOnRequest]
            LOFR[LogOffRequest]
            SC[StateChanged]
            BSU[BootStageUpdate]
            CGS[ConfirmGameStart]
            RBS[RetryBootStage]
        end

        subgraph Seat["Seat Events"]
            SO[SeatOccupied]
            SV[SeatVacated]
            SAReq[SeatActionRequest]
            SARes[SeatActionResponse]
        end

        subgraph Transition["Transition Events"]
            RL[RequestLanding]
            RLa[RequestLaunch]
            RLoc[RequestLocations]
            TU[TransitionUpdate]
            LA[LocationsAvailable]
            TLC[TransitionLandingCamera]
        end

        subgraph Profile["Profile Events"]
            PU[ProfileUpdate]
            RPS[RequestProfileSync]
        end

        subgraph Scanner["Scanner Events"]
            RS[RequestScan]
            SP[ScanProgress]
            SCo[ScanComplete]
        end
    end

    subgraph Server["🖧 Server"]
        Services[Services]
    end

    subgraph Client["🖥️ Client"]
        UI[UI Modules]
    end

    Client -->|Request| LOR
    Client -->|Request| RL
    Client -->|Request| RS

    Services -->|Response| SC
    Services -->|Response| TU
    Services -->|Response| SP
```

### Events Flow Diagram

```mermaid
sequenceDiagram
    participant C as Client
    participant RE as RemoteEvents
    participant S as Server Services

    Note over C,S: 🔵 Boot Events
    C->>RE: ConfirmGameStart
    RE->>S: Handle confirmation
    S->>RE: StateChanged(InGame)
    RE->>C: Update UI state

    Note over C,S: 🟢 Transition Events
    C->>RE: RequestLanding(locationId)
    RE->>S: TransitionService.StartLandingSequence()
    S->>RE: TransitionUpdate(landing, phase1)
    RE->>C: TransitionUI.ShowLandingPhase1()
    S->>RE: TransitionUpdate(landing, phase2)
    RE->>C: TransitionUI.ShowLandingPhase2()
    S->>RE: TransitionUpdate(complete)
    RE->>C: TransitionUI.Hide()

    Note over C,S: 🟡 Scanner Events
    C->>RE: RequestScan(locationId)
    RE->>S: PlanetScannerService.RequestScan()
    loop Every 0.5s
        S->>RE: ScanProgress(%)
        RE->>C: Update progress bar
    end
    S->>RE: ScanComplete(results)
    RE->>C: Show discovery
```

### Events Reference Table

| Event | Direction | Payload | Purpose |
|-------|-----------|---------|---------|
| **LogOnRequest** | C→S | - | Player wants to log on |
| **StateChanged** | S→C | state, data | Global state changed |
| **BootStageUpdate** | S→C | stage, data | Boot progress update |
| **ConfirmGameStart** | C→S | - | Player ready to play |
| **RequestLanding** | C→S | locationId | Start landing sequence |
| **RequestLaunch** | C→S | - | Start launch sequence |
| **TransitionUpdate** | S→C | state, data | Transition progress |
| **RequestScan** | C→S | locationId | Start surface scan |
| **ScanProgress** | S→C | progress% | Scan progress update |
| **ScanComplete** | S→C | results | Scan finished |
| **ProfileUpdate** | S→C | profileData | Profile data changed |

---

## 9. Player Profile

### Profile Schema (v2)

```mermaid
classDiagram
    class Profile {
        +string odId
        +number createdAt
        +number lastLogin
        +number profileVersion
        +string currentPlanet
        +string currentLocation
        +string lastSafeState
        +string spaceShipModel
    }

    class Discovery {
        +string[] discoveredPlanets
        +string[] exploredLocations
        +VisitEntry[] visitHistory
    }

    class ShipState {
        +number energyLevel
        +number hullIntegrity
        +Modules modules
    }

    class Modules {
        +ScannerModule scanner
    }

    class ScannerModule {
        +number batteryCharge
        +number scanCount
    }

    class Stats {
        +number totalPlayTime
        +number locationsExplored
        +number resourcesCollected
        +number knowledgeDiscovered
    }

    class VisitEntry {
        +string locationId
        +number timestamp
    }

    Profile --> Discovery
    Profile --> ShipState
    Profile --> Stats
    ShipState --> Modules
    Modules --> ScannerModule
    Discovery --> VisitEntry
```

### Profile Component Diagram

```mermaid
flowchart TB
    subgraph ProfileService["📊 ProfileService v0.5"]
        Init[Init]
        Load[LoadProfile]
        Save[SaveProfile]
        Get[GetProfile]
        Update[UpdateProfile]
        Migrate[MigrateProfile]
    end

    subgraph DataStore["💾 DataStore"]
        DS[(PlayerProfiles)]
    end

    subgraph Events["📡 Events"]
        PU[ProfileUpdate]
        RPS[RequestProfileSync]
    end

    subgraph Consumers["🔌 Consumers"]
        TS[TransitionService]
        PSS[PlanetScannerService]
        BS[BootSequence]
    end

    Init --> DS
    Load --> DS
    Save --> DS

    Load --> Migrate
    Migrate -->|v1 to v2| Load

    Update --> Save
    Update --> PU

    BS -->|Stage 3| Load
    TS -->|Save on sit| Save
    PSS -->|Save scanner state| Update

    RPS --> Get
```

### Profile Persistence Flow

```mermaid
sequenceDiagram
    autonumber
    participant Player
    participant BS as BootSequence
    participant PS as ProfileService
    participant DS as DataStore
    participant TS as TransitionService
    participant PSS as PlanetScannerService

    Note over Player,DS: 📥 Profile Load (Boot Stage 3)
    BS->>PS: LoadProfile(player)
    PS->>DS: GetAsync(userId)
    DS-->>PS: Raw profile data
    PS->>PS: MigrateProfile(v1 → v2)
    PS-->>BS: Profile ready

    Note over Player,DS: 💾 Auto-Save Triggers

    rect rgb(200, 255, 200)
        Note over TS,PS: Save on PilotSeat Sit
        Player->>TS: Sits in PilotSeat
        TS->>PS: SaveProfile(player)
        PS->>DS: SetAsync(userId, profile)
    end

    rect rgb(200, 220, 255)
        Note over PSS,PS: Save Scanner State
        Player->>PSS: RequestScan()
        PSS->>PS: UpdateProfile(scanner state)
        PS->>DS: SetAsync(userId, profile)
    end

    rect rgb(255, 220, 200)
        Note over Player,DS: Save on Leave
        Player->>PS: PlayerRemoving
        PS->>DS: SetAsync(userId, profile)
    end
```

### Profile Data Example

```lua
Profile = {
    odId = "123456789",
    createdAt = 1705776000,
    lastLogin = 1737475200,
    profileVersion = 2,

    currentPlanet = "planet1",
    currentLocation = "orbit",
    lastSafeState = "orbit",

    discoveredPlanets = {"planet1"},
    exploredLocations = {"planet1_surface_location1"},
    visitHistory = {
        {locationId = "planet1_surface_location1", timestamp = 1737474000}
    },

    spaceShipModel = "default",

    shipState = {
        energyLevel = 100,
        hullIntegrity = 100,
        modules = {
            scanner = {
                batteryCharge = 500,  -- Max 500
                scanCount = 0         -- Wear counter
            }
        }
    },

    resources = {},
    knowledge = {},

    stats = {
        totalPlayTime = 3600,
        locationsExplored = 1,
        resourcesCollected = 0,
        knowledgeDiscovered = 0
    }
}
```

---

## Appendix: File Structure Reference

```
CallOfRelics/
├── ServerScriptService/
│   ├── Setup/
│   │   └── RemoteEventsSetup.server.lua
│   ├── Core/
│   │   ├── ServerBootstrap.server.lua
│   │   ├── GameStateManager.lua
│   │   └── BootSequence.lua
│   └── Services/
│       ├── ProfileService.lua
│       ├── LocationService.lua
│       ├── PlayerService.lua
│       ├── SpaceShipService.lua
│       ├── TransitionService.lua
│       ├── PlanetScannerService.lua
│       └── ContextRegistryService.lua
│
├── StarterPlayer/
│   └── StarterPlayerScripts/
│       ├── Core/
│       │   └── ClientBootstrap.client.lua
│       └── UI/
│           ├── UIManager.lua
│           ├── ScreenSaverUI.lua
│           ├── StatusBarUI.lua
│           ├── TransitionUI.lua
│           ├── SeatUIManager.lua
│           └── SeatUI/
│               ├── PilotUI.lua
│               ├── EnginesUI.lua
│               ├── PlanetLocatorUI.lua
│               ├── PlanetSurfaceScannerUI.lua
│               └── PersonalComputerUI.lua
│
├── ReplicatedStorage/
│   ├── Game/
│   │   ├── GameConfig.lua
│   │   ├── SpaceShipConfig.lua
│   │   └── TransitionConfig.lua
│   └── RemoteEvents/
│       └── [Created by RemoteEventsSetup]
│
└── ServerStorage/
    ├── Planets/
    │   ├── Planet_1/
    │   │   ├── Config.luau
    │   │   ├── Orbit/
    │   │   └── Surface/
    │   ├── Planet_2/
    │   └── Planet_Earth/
    └── Actors/
        └── SpaceShip/
```

---

**Версія:** 1.0
**Автор:** Claude Code
**Дата:** 2026-01-21
