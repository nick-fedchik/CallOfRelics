# EPIC 1 — Game Boot & Global States

**Status:** ✅ Implemented
**Version:** 0.1
**Date:** 2026-01-11

---

## Overview

This document describes the implementation of **EPIC 1 — Game Boot & Global States** from the Backlog.

EPIC 1 establishes the foundation of the game's architecture:
- Complete game lifecycle management
- Global state coordination
- ScreenSaver functionality
- Player LogOn/LogOff flow

---

## User Stories Implemented

✅ **Player can see ScreenSaver and avatar before entering the game**
✅ **Player can Log In and start a new session**
✅ **Player can Log Off and return to ScreenSaver**
✅ **Game handles unexpected disconnects safely**
✅ **Game initializes in a clean and deterministic state**

---

## Architecture Overview

### Server-Side Components

#### 1. **GameStateManager.lua**
- **Location:** `ServerScriptService/GameStateManager.lua`
- **Purpose:** Single source of truth for game state (TDD Section 2.5)
- **Responsibilities:**
  - Manages global states: `LoggedOff`, `Initializing`, `InGame`
  - Validates state transitions
  - Notifies server and client systems of state changes
  - Enforces forbidden transitions

#### 2. **ServerBootstrap.server.lua**
- **Location:** `ServerScriptService/ServerBootstrap.server.lua`
- **Purpose:** Main server initialization script (TDD Section 4.3)
- **Responsibilities:**
  - Boots the game in controlled sequence
  - Initializes GameStateManager
  - Initializes PlayerService
  - Handles boot failures safely

#### 3. **PlayerService.lua**
- **Location:** `ServerScriptService/PlayerService.lua`
- **Purpose:** Manages player lifecycle
- **Responsibilities:**
  - Handles player connections/disconnections
  - Processes LogOn/LogOff requests
  - Enforces single-player constraint
  - Manages safe disconnects

#### 4. **RemoteEventsSetup.server.lua**
- **Location:** `ServerScriptService/RemoteEventsSetup.server.lua`
- **Purpose:** Creates RemoteEvents for client-server communication
- **Responsibilities:**
  - Creates `RemoteEvents` folder in ReplicatedStorage
  - Sets up `LogOnRequest`, `LogOffRequest`, `StateChanged` events

### Client-Side Components

#### 5. **ClientBootstrap.client.lua**
- **Location:** `StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua`
- **Purpose:** Main client initialization script
- **Responsibilities:**
  - Initializes client-side systems
  - Sets up ScreenSaver UI
  - Initializes UIManager
  - Disables default Roblox UI elements

#### 6. **ScreenSaverUI.lua**
- **Location:** `StarterPlayer/StarterPlayerScripts/ScreenSaverUI.lua`
- **Purpose:** ScreenSaver interface (TDD Section 7.2)
- **Responsibilities:**
  - Displays visual screensaver
  - Shows "Press to Enter" prompt
  - Handles player input (Space or Click)
  - Sends LogOn request to server

#### 7. **UIManager.lua**
- **Location:** `StarterPlayer/StarterPlayerScripts/UIManager.lua`
- **Purpose:** Manages UI state transitions
- **Responsibilities:**
  - Listens to server state changes
  - Shows/hides UI based on game state
  - Coordinates between UI modules

---

## Game Flow

### Boot Sequence

1. **Server Boot**
   ```
   RemoteEventsSetup → Creates RemoteEvents
   ServerBootstrap → Initializes GameStateManager
   ServerBootstrap → Initializes PlayerService
   Initial State: LoggedOff
   ```

2. **Client Boot**
   ```
   ClientBootstrap → Initializes ScreenSaverUI
   ClientBootstrap → Initializes UIManager
   ClientBootstrap → Shows ScreenSaver
   ```

### LogOn Flow

1. Player presses **Space** or **Clicks** on ScreenSaver
2. `ScreenSaverUI` sends `LogOnRequest` to server
3. `PlayerService` receives request
4. State transition: `LoggedOff → Initializing`
5. Server notifies client via `StateChanged` event
6. `UIManager` hides ScreenSaver
7. Simulated boot time (1 second)
8. State transition: `Initializing → InGame`
9. Server notifies client
10. Player is now in game

### LogOff Flow

1. Player triggers LogOff (currently via disconnect or future UI)
2. `PlayerService` processes LogOff
3. State transition: `InGame → LoggedOff`
4. Server notifies client
5. `UIManager` shows ScreenSaver
6. Player slot released

### Disconnect Handling

1. Roblox fires `PlayerRemoving` event
2. `PlayerService.OnPlayerRemoving` called
3. Automatic LogOff executed
4. State returns to `LoggedOff`
5. Game ready for next player

---

## State Machine

```
┌─────────────┐
│  LoggedOff  │ ◄─────────────────┐
└──────┬──────┘                   │
       │ LogOn Request            │
       ▼                          │
┌──────────────┐                  │
│ Initializing │                  │
└──────┬───────┘                  │
       │ Boot Complete     LogOff │
       │ (or Fail)                │
       ▼                          │
┌─────────────┐                   │
│   InGame    │───────────────────┘
└─────────────┘
```

### Allowed Transitions

- `LoggedOff` → `Initializing` ✅
- `Initializing` → `InGame` ✅
- `Initializing` → `LoggedOff` ✅ (on failure)
- `InGame` → `LoggedOff` ✅

### Forbidden Transitions

- `LoggedOff` → `InGame` ❌ (must go through Initializing)
- `InGame` → `Initializing` ❌ (would break session)

---

## Technical Specifications

### Logging Standard (TDD Section 11)

All scripts follow the standardized logging format:
```lua
print(string.format("[%s %s][Function] Message", MODULE_NAME, VERSION))
```

Each script includes:
- Detailed header comment with module info
- Version number
- Features list
- API documentation
- Dependencies
- ChangeLog

### Script Headers

All scripts use the KOSMICMAZER standard template (TDD Section 11.8):
```lua
--[[
================================================================================
KOSMICMAZER — <Module Name>
================================================================================

Purpose:
<Description>

Version:
<X.Y>

Features:
- <Feature 1>
...

API:
- <Function>(...) — <Description>
...

ChangeLog:
- X.Y: <Change> (YYYY-MM-DD)
================================================================================
]]
```

### Error Handling (TDD Section 10)

- Boot failures are caught with `pcall`
- Critical failures print detailed error messages
- System uses fail-safe pattern (return to LoggedOff)
- No "silent failures"

---

## Testing Checklist

### Manual Testing

- [x] Server boots successfully
- [x] ScreenSaver displays on client join
- [x] Space key triggers LogOn request
- [x] Click triggers LogOn request
- [x] State transitions are logged correctly
- [x] Client UI responds to state changes
- [x] Player disconnect triggers LogOff
- [x] Second player is rejected (single-player constraint)

### Expected Logs

**Server Output:**
```
================================================================================
CALL OF RELICS: ORBITAL SILENCE
Server Boot Sequence Started
[ServerBootstrap 0.1] Initializing...
================================================================================
[RemoteEventsSetup 0.1] Setting up RemoteEvents...
[RemoteEventsSetup 0.1] Created: LogOnRequest
[RemoteEventsSetup 0.1] Created: LogOffRequest
[RemoteEventsSetup 0.1] Created: StateChanged
[RemoteEventsSetup 0.1] RemoteEvents setup complete
[ServerBootstrap 0.1][Boot] Phase 1: Initializing GameStateManager
[GameStateManager 0.1][Initialize] State manager initialized. Current state: LoggedOff
[ServerBootstrap 0.1][Boot] Current state: LoggedOff
[ServerBootstrap 0.1][Boot] Phase 2: Initializing PlayerService
[PlayerService 0.1][Initialize] PlayerService initialized
[PlayerService 0.1][SetupRemoteEvents] RemoteEvent handlers connected
[ServerBootstrap 0.1][Boot] Phase 3: Core systems ready
[ServerBootstrap 0.1][Boot] Phase 4: ScreenSaver active
================================================================================
BOOT COMPLETE
Game State: LoggedOff (ScreenSaver)
Waiting for player login...
================================================================================
```

**Client Output:**
```
================================================================================
CALL OF RELICS: ORBITAL SILENCE - CLIENT
Client Boot Sequence Started
[ClientBootstrap 0.1] Initializing...
================================================================================
[ClientBootstrap 0.1][Boot] Client initializing for player: PlayerName
[ClientBootstrap 0.1][Boot] Phase 1: Initializing ScreenSaver UI
[ScreenSaverUI 0.1][Initialize] Creating ScreenSaver UI
[ScreenSaverUI 0.1][Initialize] ScreenSaver UI ready
[ClientBootstrap 0.1][Boot] Phase 2: Initializing UIManager
[UIManager 0.1][Initialize] UIManager initializing
[UIManager 0.1][SetupStateListener] Listening for state changes
[UIManager 0.1][Initialize] UIManager ready
[ClientBootstrap 0.1][Boot] Phase 3: UI systems ready
[ClientBootstrap 0.1][Boot] Phase 4: Showing ScreenSaver
[ScreenSaverUI 0.1][Show] ScreenSaver visible
================================================================================
CLIENT BOOT COMPLETE
ScreenSaver Active - Waiting for player input
================================================================================
```

---

## Files Created

```
ServerScriptService/
├── GameStateManager.lua
├── ServerBootstrap.server.lua
├── PlayerService.lua
└── RemoteEventsSetup.server.lua

StarterPlayer/StarterPlayerScripts/
├── ClientBootstrap.client.lua
├── ScreenSaverUI.lua
└── UIManager.lua
```

---

## Next Steps (EPIC 2 - Sprint 2)

After EPIC 1 is tested and stable:

1. **Space Ship Context** (EPIC 3)
   - Create ship location
   - Implement player spawn point
   - Define safe save point

2. **Contextual States** (from TDD Section 2.3)
   - Implement world context states
   - Add Orbital context
   - Prepare for location system

3. **Enhanced UI**
   - In-game UI for ship
   - LogOff button
   - Context indicators

---

## TDD References

This implementation follows these TDD sections:

- **Section 1.2** - State-driven architecture
- **Section 2.2** - Global Game States
- **Section 2.5** - Single state coordinator
- **Section 3.4** - Request → Verification → Permission
- **Section 4.3** - Boot sequence
- **Section 7.2** - ScreenSaver UI
- **Section 10** - Error handling
- **Section 11** - Logging standards

---

## Compliance Checklist

- [x] All scripts have standardized headers
- [x] Version numbers in all modules (0.1)
- [x] Logging follows TDD Section 11 format
- [x] State machine implements TDD Section 2
- [x] Error handling follows TDD Section 10
- [x] Single-player constraint enforced
- [x] No direct state changes from UI or content
- [x] All transitions go through GameStateManager
- [x] Client is read-only for state (server authoritative)
- [x] Clean initialization sequence

---

**EPIC 1 Status: COMPLETE ✅**
