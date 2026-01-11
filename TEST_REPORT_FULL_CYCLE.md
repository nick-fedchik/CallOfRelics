# Test Report: Full Game Cycle

**Date**: 2026-01-11
**Version**: EPIC 1 v0.2
**Tester**: KOSMICMAZER AI Assistant

---

## Test Scope

Testing the complete game cycle:
1. Player connects → Boot Sequence → InGame
2. Player clicks Exit → Return to LoggedOff
3. Repeat cycle to verify state management

---

## Test Checklist

### Phase 1: Player Connect → Boot Sequence

- [ ] **Player joins server**
  - Expected: GameStateManager transitions LoggedOff → Initializing
  - Expected: BootSequence.StartBoot() called automatically

- [ ] **Stage 1: Game Configuration (1.5s)**
  - Expected: ScreenSaverUI shows game name "CALL OF RELICS"
  - Expected: Subtitle "Orbital Silence" displayed
  - Expected: Version "v0.1 - EPIC 1" in bottom-right corner
  - Expected: Elements fade in smoothly

- [ ] **Stage 2: Player Information (1.5s)**
  - Expected: Player avatar thumbnail loads (150x150px)
  - Expected: Player name displayed below avatar
  - Expected: Stage 1 elements REMAIN VISIBLE (cumulative)
  - Expected: No black screen flicker

- [ ] **Stage 3: Profile Loading (2s)**
  - Expected: Loading spinner appears (rotating dots)
  - Expected: Progress bar animates
  - Expected: Text shows "Ініціалізація експедиції..." (new player) or "Відновлення експедиції..." (returning player)
  - Expected: All previous elements still visible

- [ ] **Stage 4: Ready State**
  - Expected: "Готовність 100%" text appears (green tint)
  - Expected: "Почати гру" button displayed (300x60px, blue)
  - Expected: Loading spinner/progress bar hidden
  - Expected: Button hover effect works
  - Expected: All previous elements still visible

### Phase 2: Enter Game

- [ ] **Player clicks "Почати гру"**
  - Expected: ConfirmGameStart RemoteEvent fired to server
  - Expected: GameStateManager transitions Initializing → InGame
  - Expected: ScreenSaverUI.Hide() called
  - Expected: StatusBarUI.Show() called

- [ ] **StatusBar Appearance**
  - Expected: Top bar visible (50px height, dark background)
  - Expected: Planet label on LEFT side: "Планета: Planet_1"
  - Expected: Location label on LEFT side (after planet): "Локація: Космічний Корабель"
  - Expected: Exit button on RIGHT side: "Вихід" (100px width, red background)
  - Expected: No conflict with Roblox UI elements (player list, chat)

### Phase 3: Exit Game

- [ ] **Player clicks "Вихід"**
  - Expected: Button hover effect works (color change)
  - Expected: LogOffRequest RemoteEvent fired to server
  - Expected: GameStateManager transitions InGame → LoggedOff
  - Expected: StatusBarUI.Hide() called
  - Expected: ScreenSaverUI.Reset() called
  - Expected: ScreenSaverUI.Show() called

- [ ] **Return to ScreenSaver**
  - Expected: ScreenSaver resets to initial state (all elements transparent)
  - Expected: Boot Sequence starts again automatically
  - Expected: Stages 1-4 run through again

### Phase 4: Repeat Cycle

- [ ] **Second Boot Sequence**
  - Expected: Profile loads as "RETURNING PLAYER"
  - Expected: Stage 3 shows "Відновлення експедиції..."
  - Expected: All stages work correctly on second run

- [ ] **Enter Game Again**
  - Expected: StatusBar appears correctly
  - Expected: Exit button still on right side
  - Expected: All functionality works

---

## Architecture Verification

### State Management
- [ ] No double state transitions
- [ ] State changes broadcast to client correctly
- [ ] Player context handled uniformly (direct Player object or {player: Player})

### UI Cumulative Logic
- [ ] Each stage ADDS elements, doesn't replace
- [ ] No black screen flicker between stages
- [ ] Reset() function clears all elements properly
- [ ] Fade animations smooth (0.6s duration)

### RemoteEvents
- [ ] LogOnRequest (Client → Server) - triggers boot sequence
- [ ] LogOffRequest (Client → Server) - triggers return to LoggedOff
- [ ] StateChanged (Server → Client) - notifies state transitions
- [ ] BootStageUpdate (Server → Client) - sends stage data
- [ ] ConfirmGameStart (Client → Server) - player clicked button

---

## Known Issues

1. **Double ClientBootstrap Run Warning**
   - Status: Handled with HasAttribute check
   - Impact: None (warning only, functionality works)

2. **Avatar Thumbnail Loading**
   - Status: Requires HTTP requests enabled in Studio
   - Fallback: Empty image if loading fails

---

## Test Results

### Manual Testing Required

This test requires running in Roblox Studio with:
- HTTP requests enabled
- DataStore API access enabled
- Rojo sync active

### Expected Log Output

```
-- Player Connect
[PlayerService] Player connected. Starting boot sequence...
[GameStateManager] State transition: LoggedOff → Initializing

-- Boot Sequence
[BootSequence] Stage 1: Game Configuration
[BootSequence] Stage 2: Player Information (userId: XXX, displayName: YYY)
[BootSequence] Stage 3: Profile Loading (isNewPlayer: true/false)
[BootSequence] Stage 4: Ready - waiting for player confirmation

-- Enter Game
[BootSequence] Player confirmed game start
[GameStateManager] State transition: Initializing → InGame
[StatusBarUI] StatusBar visible

-- Exit Game
[StatusBarUI] Player clicked 'Вихід'
[StatusBarUI] LogOff request sent to server
[GameStateManager] State transition: InGame → LoggedOff
[ScreenSaverUI] ScreenSaver visible - reset and restarting boot sequence
```

---

## Files Involved

1. [ClientBootstrap.client.lua](StarterPlayer/StarterPlayerScripts/Core/ClientBootstrap.client.lua)
2. [ScreenSaverUI.lua v0.4](StarterPlayer/StarterPlayerScripts/UI/ScreenSaverUI.lua)
3. [StatusBarUI.lua v0.2](StarterPlayer/StarterPlayerScripts/UI/StatusBarUI.lua)
4. [UIManager.lua](StarterPlayer/StarterPlayerScripts/UI/UIManager.lua)
5. [ServerBootstrap.server.lua](ServerScriptService/Core/ServerBootstrap.server.lua)
6. [GameStateManager.lua](ServerScriptService/Core/GameStateManager.lua)
7. [PlayerService.lua](ServerScriptService/Services/PlayerService.lua)
8. [BootSequence.lua](ServerScriptService/Core/BootSequence.lua)

---

## Conclusion

All code changes are complete. Manual testing in Roblox Studio is required to verify:
- Full cycle works (Connect → InGame → Exit → LoggedOff → Repeat)
- StatusBar Exit button positioned correctly (right side)
- No state transition errors
- UI elements display cumulatively without flicker

**Status**: ✅ Code Complete - Ready for Manual Testing
