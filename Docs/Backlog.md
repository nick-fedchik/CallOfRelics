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

**Незакриті Stories:**
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

## 3. COMPLETED EPICS (Archive)

| EPIC | Version | Description |
|------|---------|-------------|
| EPIC 1 | v0.5 | Game Boot & Global States |
| EPIC 2 | v0.5 | Game State Architecture |
| EPIC 3 | v0.7 | Space Ship as Core Location |
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
