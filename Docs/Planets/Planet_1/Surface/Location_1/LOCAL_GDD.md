# LOCAL_GDD — Planet_1/Location_1 (Landing Site Alpha)
**Project:** Call of Relics: Orbital Silence
**Scope:** First Landing Location

---

## Overview

Landing Site Alpha — перша локація для дослідження на Kepler-442b. Безпечна зона для навчання базових механік.

---

## Location Data

| Property | Value |
|----------|-------|
| Location ID | Location1 |
| Display Name | Landing Site Alpha |
| Parent Planet | Planet_1 |
| Type | Exploration |
| Context | TransitionConfig.Contexts.Surface |
| Difficulty | Tutorial |

---

## Environment

### Terrain
- Рівнинна місцевість з м'якими пагорбами
- Скелясті утворення по периметру
- Посадковий майданчик (LandingPad)

### Flora
- Екзотичні рослини (декоративні)
- Світлові квіти (ambient lighting)
- Можливі інтерактивні рослини (TBD)

### Atmosphere
- Безпечна для дихання
- Легкий туман на горизонті
- Денне освітлення (без циклу дня/ночі)

---

## Gameplay Elements

### Primary Goal (EPIC 7)
- TBD — перше знайомство з механіками дослідження

### Optional Objectives
- TBD

### Resources
- TBD

### Knowledge Items
- TBD — перші записи про планету

---

## Player Actions

### Available
- Вийти з корабля (unseat)
- Дослідження території
- Збір ресурсів (TBD)
- Повернення до корабля

### Restricted
- Сканування (тільки з орбіти)

---

## Transitions

### Incoming
- **Landing** — посадка з орбіти

### Outgoing
- **Launch** — зліт на орбіту

---

## Technical Notes

**Storage Path:** `ServerStorage/Planets/Planet_1/Surface/Location1/`

**Required Elements:**
- `Workspace/LandingPad` — посадковий майданчик
- `Config.luau` — конфігурація локації

**Workspace Structure:**
```
Location1/Workspace/
├── LandingPad (Model)       # Ship landing point
├── Terrain/                 # Ground models
├── Flora/                   # Plants and vegetation
├── Lighting/
│   ├── Sky
│   └── Atmosphere
└── Collectibles/            # Resources (TBD)
```

---

## Config.luau Example

```lua
return {
    id = "Location1",
    displayName = "Landing Site Alpha",
    context = "Surface",

    -- Environment
    gravity = 1.2,
    hasAtmosphere = true,
    hazardLevel = 0,

    -- Gameplay
    timeLimit = nil,  -- No time limit
    primaryGoal = nil,  -- TBD

    -- Spawn
    spawnPoint = "LandingPad"
}
```

---

## Related Documents

- [../../LOCAL_GDD.md](../../LOCAL_GDD.md) — Planet_1 overview
- [../../Orbit/LOCAL_GDD.md](../../Orbit/LOCAL_GDD.md) — Orbital view
- [../Location_2/LOCAL_GDD.md](../Location_2/LOCAL_GDD.md) — Ancient Ruins
