# LOCAL_GDD — Planet_1/Orbit
**Project:** Call of Relics: Orbital Silence
**Scope:** Kepler-442b Orbital View

---

## Overview

Орбітальний вигляд планети Kepler-442b. Центр навігації для сканування та вибору локацій.

---

## Location Data

| Property | Value |
|----------|-------|
| Location ID | Orbit |
| Parent Planet | Planet_1 |
| Type | Navigation Hub |
| Context | TransitionConfig.Contexts.Orbit |

---

## Player State

- Гравець сидить у PilotSeat корабля
- Доступ до PilotUI для навігації
- Доступ до Scanner для відкриття локацій

---

## Visual Elements

### Planet Model
- Велика 3D модель планети під кораблем
- Атмосферне сяйво
- Обертання планети (subtle animation)

### Skybox
- Космічний фон з зірками
- Бінарна зоряна система (два сонця)
- Можливі туманності на горизонті

### Lighting
- Ambient космічне освітлення
- Відблиски від планети
- Тіні від корабля

---

## Available Actions

### From PilotSeat
1. **Сканування** — відкриває нові локації на поверхні
2. **Landing** — посадка на відкриту локацію
3. **Ship Systems** — TBD (управління кораблем)

### Scanner System (EPIC 5)
- Сканування займає час
- Прогрес-бар відображається в UI
- Успішне сканування відкриває локацію в ProfileService

---

## Transitions

### Incoming
- **GameStart** — гравець з'являється на орбіті при старті гри
- **Launch** — повернення з поверхні на орбіту

### Outgoing
- **Landing** — посадка на локацію поверхні

---

## Technical Notes

**Storage Path:** `ServerStorage/Planets/Planet_1/Orbit/`

**Required Elements:**
- `Workspace/Planet` (Model) — 3D модель планети
- `Config.luau` — конфігурація орбіти

**Workspace Structure:**
```
Orbit/Workspace/
├── Planet (Model)           # REQUIRED
├── Lighting/
│   ├── Sky                  # Skybox
│   └── Atmosphere           # Optional effects
└── Effects/                 # Optional
```

---

## Config.luau Example

```lua
return {
    id = "Orbit",
    displayName = "Kepler-442b Orbit",
    context = "Orbit",

    -- Scanner settings
    scannerEnabled = true,
    scanDuration = 5.0,

    -- Lighting preset
    lightingPreset = "Space"
}
```

---

## Related Documents

- [../LOCAL_GDD.md](../LOCAL_GDD.md) — Planet_1 overview
- [../Surface/Location_1/LOCAL_GDD.md](../Surface/Location_1/LOCAL_GDD.md) — Landing Site Alpha
- [../Surface/Location_2/LOCAL_GDD.md](../Surface/Location_2/LOCAL_GDD.md) — Ancient Ruins
