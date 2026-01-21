# StarterPlayerScripts Structure

## Overview

Client-side scripts organized for Script Sync compatibility and architectural clarity.

```mermaid
flowchart TB
    subgraph Client["🖥️ Client (StarterPlayerScripts)"]
        subgraph Core["Core/"]
            CB[ClientBootstrap.client.lua]
            SC[SeatController.client.lua]
            CC[CameraController.lua]
        end

        subgraph UI["UI/"]
            UIM[UIManager.lua]
            SSU[ScreenSaverUI.lua]
            SBU[StatusBarUI.lua]
            SUIM[SeatUIManager.lua]
            TUI[TransitionUI.lua]

            subgraph SeatUI["SeatUI/"]
                PUI[PilotUI.lua]
                SSUI[SurfaceScannerUI.lua]
                DSUI[DeepSpaceScannerUI.lua]
            end
        end

        subgraph Systems["Systems/"]
            Future[Future modules...]
        end
    end

    CB --> SSU
    CB --> SBU
    CB --> UIM
    CB --> SUIM
    CB --> TUI

    SC --> SUIM
    SUIM --> SeatUI
```

---

## Folder Structure

```
StarterPlayer/
└── StarterPlayerScripts/        ← Anchor folder (Script Sync requirement)
    ├── Core/                     ← Bootstrap and core initialization
    │   ├── ClientBootstrap.client.lua
    │   ├── SeatController.client.lua   ← Seat detection
    │   └── CameraController.lua        ← Camera management
    ├── UI/                       ← UI modules and systems
    │   ├── UIManager.lua
    │   ├── ScreenSaverUI.lua
    │   ├── StatusBarUI.lua
    │   ├── SeatUIManager.lua
    │   ├── TransitionUI.lua      ← NEW: Transition animations
    │   └── SeatUI/               ← Per-seat UI modules
    │       ├── PilotUI.lua
    │       ├── SurfaceScannerUI.lua
    │       ├── DeepSpaceScannerUI.lua
    │       ├── SystemsConsoleUI.lua
    │       └── PersonalTerminalUI.lua
    └── Systems/                  ← Client-side game systems (future)
```

---

## Core/

**Purpose:** Client initialization and bootstrap scripts.

### ClientBootstrap.client.lua (v0.3)
- Main client entry point (auto-runs)
- Initializes UI systems
- Disables default Roblox UI
- Manages boot sequence

**Boot Order:**
1. Disable CoreGui elements
2. Initialize ScreenSaverUI
3. Initialize StatusBarUI
4. Initialize UIManager
5. Show ScreenSaver

### SeatController.client.lua (v0.1)
- Detects when player sits/stands from seats
- Identifies seat type from SeatConfig
- Fires SeatOccupied/SeatVacated RemoteEvents
- Triggers SeatUIManager

### CameraController.lua (v0.2)
- Manages camera FOV per seat
- Applies SeatConfig camera settings
- Restores default camera on seat exit

---

## UI/

**Purpose:** UI modules and interface management.

### ScreenSaverUI.lua (v0.5)
- Multi-stage ScreenSaver (Stages 0-4)
- Progressive boot UI with progress bar
- Handles boot sequence visualization
- Listens to BootStageUpdate RemoteEvent
- Manages "Почати гру" button interaction

### StatusBarUI.lua (v0.2)
- In-game status bar
- Shows planet displayName and location displayName
- Version info and game state

### UIManager.lua (v0.2)
- Centralized UI state management
- Handles game state transitions
- Shows/hides UI based on server StateChanged events

### SeatUIManager.lua (v0.1)
- Manages per-seat UI modules
- Shows appropriate UI when sitting
- Hides UI when standing

### TransitionUI.lua (v0.4) — NEW
- Location transition animations
- Loading screen with messages
- Landing camera sequence (POV from landing pad)
- StatusBar integration for displayName updates

---

## UI/SeatUI/

**Purpose:** Individual UI modules for each ship seat.

### PilotUI.lua (v0.5)
- Context-aware UI (Orbit/Surface)
- Landing menu with available locations (on Orbit)
- Liftoff button (on Surface)
- DisplayName localization for locations

### SurfaceScannerUI.lua (v0.1)
- Placeholder for surface scanning UI

### DeepSpaceScannerUI.lua (v0.1)
- Placeholder for deep space scanning UI

### SystemsConsoleUI.lua (v0.1)
- Placeholder for ship systems management UI

### PersonalTerminalUI.lua (v0.1)
- Placeholder for personal terminal UI

---

## Systems/ (Future)

**Purpose:** Client-side gameplay systems.

**Planned:**
- InputHandler.lua — Player input management
- LocationRenderer.lua — Location visualization

---

## Script Sync Requirements

**CRITICAL:** StarterPlayerScripts is an **anchor folder** for Roblox Studio Script Sync.

### Setup Instructions:

1. **In Roblox Studio DataModel**, ensure StarterPlayer → StarterPlayerScripts exists
2. **Create anchor subfolders** in Studio:
   - Right-click StarterPlayerScripts
   - Insert Object → Folder → Name it "Core"
   - Insert Object → Folder → Name it "UI"
   - Inside UI, create Folder → Name it "SeatUI"
3. **Enable Script Sync** in Studio settings
4. **Sync files** from file system

### Important Notes:

- All client scripts MUST be inside StarterPlayerScripts or its subfolders
- Script Sync will NOT create top-level folders automatically
- Bootstrap scripts with `.client.lua` extension run automatically
- ModuleScripts (`.lua`) must be required by other scripts

---

## Module Loading Pattern

### From ClientBootstrap.client.lua:

```lua
-- Access parent folder (StarterPlayerScripts)
local StarterPlayerScripts = script.Parent.Parent

-- Load modules from UI folder
local UI = StarterPlayerScripts:WaitForChild("UI")
local ScreenSaverUI = require(UI:WaitForChild("ScreenSaverUI"))
local UIManager = require(UI:WaitForChild("UIManager"))
```

### From other client scripts:

```lua
local StarterPlayerScripts = game:GetService("Players").LocalPlayer
    :WaitForChild("PlayerScripts")
    :WaitForChild("StarterPlayerScripts")

local UI = StarterPlayerScripts:WaitForChild("UI")
local ScreenSaverUI = require(UI:WaitForChild("ScreenSaverUI"))
```

---

## Client-Server Communication

### Events Architecture

```mermaid
flowchart LR
    subgraph Client["🖥️ Client"]
        SSU[ScreenSaverUI]
        UIM[UIManager]
        SUIM[SeatUIManager]
        TUI[TransitionUI]
        PUI[PilotUI]
        PSSUI[ScannerUI]
    end

    subgraph Events["📡 RemoteEvents"]
        direction TB
        C2S[Client → Server]
        S2C[Server → Client]
    end

    subgraph Server["🖧 Server"]
        GSM[GameStateManager]
        BS[BootSequence]
        TS[TransitionService]
        SSS[SpaceShipService]
        PSS[ScannerService]
    end

    SSU -->|ConfirmGameStart| C2S
    PUI -->|RequestLanding| C2S
    PUI -->|RequestLaunch| C2S
    PSSUI -->|RequestScan| C2S

    S2C -->|StateChanged| UIM
    S2C -->|BootStageUpdate| SSU
    S2C -->|TransitionUpdate| TUI
    S2C -->|ScanProgress| PSSUI
```

### RemoteEvents Used:

**Client → Server:**
- ConfirmGameStart — Player clicked "Почати гру" button
- RetryBootStage — Player wants to retry failed stage
- SeatOccupied — Player sat in seat
- SeatVacated — Player left seat
- SeatActionRequest — Request action from seat
- RequestLanding — Request landing on location
- RequestLaunch — Request launch to orbit
- RequestLocations — Request location list
- RequestScan — Request surface scan

**Server → Client:**
- StateChanged — Game state transition notification
- BootStageUpdate — Boot sequence stage data
- SeatActionResponse — Response to seat action
- TransitionUpdate — Transition state update
- TransitionLandingCamera — Landing camera data
- LocationsAvailable — List of available locations
- ScanProgress — Scan progress percentage
- ScanComplete — Scan finished with results

### Boot Sequence Protocol

```mermaid
sequenceDiagram
    autonumber
    participant Client as Client (ScreenSaverUI)
    participant RE as RemoteEvents
    participant Server as Server (BootSequence)

    Note over Client,Server: 🚀 Boot Sequence

    Server->>RE: BootStageUpdate(1, GameConfig)
    RE->>Client: Stage 1 - Show game info
    Client->>Client: Display version, name

    Server->>RE: BootStageUpdate(2, PlayerInfo)
    RE->>Client: Stage 2 - Show player info
    Client->>Client: Display avatar

    Server->>RE: BootStageUpdate(3, ProfileData)
    RE->>Client: Stage 3 - Profile loaded
    Client->>Client: Update progress

    Server->>RE: BootStageUpdate(4, Ready)
    RE->>Client: Stage 4 - Ready
    Client->>Client: Show "Почати гру" button

    Client->>RE: ConfirmGameStart
    RE->>Server: Player confirmed

    Server->>RE: StateChanged(InGame)
    RE->>Client: Hide ScreenSaver
```

### Landing Sequence Protocol

```mermaid
sequenceDiagram
    autonumber
    participant PUI as PilotUI
    participant TUI as TransitionUI
    participant RE as RemoteEvents
    participant TS as TransitionService

    Note over PUI,TS: ⬇️ Landing Sequence

    PUI->>RE: RequestLanding(locationId)
    RE->>TS: Start landing

    TS->>RE: TransitionUpdate(landing, phase1)
    RE->>TUI: Show external view (4s)

    TS->>RE: TransitionLandingCamera(cameraData)
    RE->>TUI: Setup landing camera

    TS->>RE: TransitionUpdate(landing, phase2)
    RE->>TUI: Switch to cockpit view (3s)

    TS->>RE: TransitionUpdate(complete)
    RE->>TUI: Hide transition UI

    TUI->>TUI: Smooth camera handoff
```

### Launch Sequence Protocol

```mermaid
sequenceDiagram
    autonumber
    participant PUI as PilotUI
    participant TUI as TransitionUI
    participant RE as RemoteEvents
    participant TS as TransitionService

    Note over PUI,TS: ⬆️ Launch Sequence

    PUI->>RE: RequestLaunch
    RE->>TS: Start launch

    TS->>RE: TransitionUpdate(launch, phase1)
    RE->>TUI: Show cockpit view (3s)

    TS->>RE: TransitionUpdate(launch, phase2)
    RE->>TUI: Switch to external view (4s)

    TS->>RE: TransitionUpdate(arrival)
    RE->>TUI: Cockpit arrival view (4s)

    TS->>RE: TransitionUpdate(complete)
    RE->>TUI: Hide transition UI
```

### Scan Sequence Protocol

```mermaid
sequenceDiagram
    autonumber
    participant UI as ScannerUI
    participant RE as RemoteEvents
    participant PSS as ScannerService
    participant PS as ProfileService

    Note over UI,PS: 🔍 Scan Sequence

    UI->>RE: RequestScan(locationId)
    RE->>PSS: Start scan

    PSS->>PSS: Check battery, cooldown

    loop Every 0.5s
        PSS->>RE: ScanProgress(percentage)
        RE->>UI: Update progress bar
    end

    PSS->>PS: Mark location discovered
    PSS->>PS: Save scanner state

    PSS->>RE: ScanComplete(results)
    RE->>UI: Show discovery
```

### Event Handlers Location:

| Module | Listens To | Sends |
|--------|------------|-------|
| **ScreenSaverUI** | BootStageUpdate | ConfirmGameStart, RetryBootStage |
| **UIManager** | StateChanged | - |
| **SeatUIManager** | SeatOccupied, SeatVacated | - |
| **TransitionUI** | TransitionUpdate, TransitionLandingCamera | - |
| **PilotUI** | LocationsAvailable | RequestLanding, RequestLaunch, RequestLocations |
| **ScannerUI** | ScanProgress, ScanComplete | RequestScan |

---

## TDD Compliance

- ✅ **Section 1.2:** State-driven client (reads server state)
- ✅ **Section 4.3:** Client boot sequence
- ✅ **Section 7.2:** ScreenSaver UI implementation
- ✅ **Section 7.4:** Contextual interfaces (SeatUI)
- ✅ **Section 13.3.1:** Script Sync anchor folders

---

## Version History

- **v0.7 (2026-01-14):** Added TransitionUI, updated PilotUI with context detection
- **v0.6 (2026-01-13):** Added SeatUI modules, CameraController, SeatController
- **v0.2 (2026-01-11):** Reorganized into Core/UI folders for Script Sync
- **v0.1 (2026-01-11):** Initial flat structure

---

**Architecture:** TDD Section 13.3
**Script Sync:** TDD Section 13.3.1
