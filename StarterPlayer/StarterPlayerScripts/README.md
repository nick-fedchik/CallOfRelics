# StarterPlayerScripts Structure

## Overview

Client-side scripts organized for Script Sync compatibility and architectural clarity.

---

## Folder Structure

```
StarterPlayer/
└── StarterPlayerScripts/        ← Anchor folder (Script Sync requirement)
    ├── Core/                     ← Bootstrap and core initialization
    │   └── ClientBootstrap.client.lua
    ├── UI/                       ← UI modules and systems
    │   ├── UIManager.lua
    │   └── ScreenSaverUI.lua
    └── Systems/                  ← Client-side game systems (future)
```

---

## Core/

**Purpose:** Client initialization and bootstrap scripts.

### ClientBootstrap.client.lua
- Main client entry point (auto-runs)
- Initializes UI systems
- Disables default Roblox UI
- Manages boot sequence

**Boot Order:**
1. Disable CoreGui elements
2. Initialize ScreenSaverUI
3. Initialize UIManager
4. Show ScreenSaver

---

## UI/

**Purpose:** UI modules and interface management.

### ScreenSaverUI.lua
- Multi-stage ScreenSaver (Stages 0-4)
- Handles boot sequence visualization
- Listens to BootStageUpdate RemoteEvent
- Manages "Почати гру" button interaction

### UIManager.lua
- Centralized UI state management
- Handles game state transitions
- Shows/hides UI based on server StateChanged events

---

## Systems/ (Future)

**Purpose:** Client-side gameplay systems.

**Planned:**
- InputHandler.lua — Player input management
- CameraController.lua — Camera system
- LocationRenderer.lua — Location visualization
- ShipUI.lua — Ship interface

---

## Script Sync Requirements

**CRITICAL:** StarterPlayerScripts is an **anchor folder** for Roblox Studio Script Sync.

### Setup Instructions:

1. **In Roblox Studio DataModel**, ensure StarterPlayer → StarterPlayerScripts exists
2. **Create anchor subfolders** in Studio:
   - Right-click StarterPlayerScripts
   - Insert Object → Folder → Name it "Core"
   - Insert Object → Folder → Name it "UI"
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

### RemoteEvents Used:

**Client → Server:**
- LogOnRequest — Player wants to enter game
- LogOffRequest — Player wants to leave game
- ConfirmGameStart — Player clicked "Почати гру" button

**Server → Client:**
- StateChanged — Game state transition notification
- BootStageUpdate — Boot sequence stage data

### Event Handlers Location:

- **ScreenSaverUI.lua:** Handles BootStageUpdate, sends LogOnRequest and ConfirmGameStart
- **UIManager.lua:** Handles StateChanged

---

## TDD Compliance

- ✅ **Section 1.2:** State-driven client (reads server state)
- ✅ **Section 4.3:** Client boot sequence
- ✅ **Section 7.2:** ScreenSaver UI implementation
- ✅ **Section 13.3.1:** Script Sync anchor folders

---

## Version History

- **v0.2 (2026-01-11):** Reorganized into Core/UI folders for Script Sync
- **v0.1 (2026-01-11):** Initial flat structure

---

**Architecture:** TDD Section 13.3
**Script Sync:** TDD Section 13.3.1
