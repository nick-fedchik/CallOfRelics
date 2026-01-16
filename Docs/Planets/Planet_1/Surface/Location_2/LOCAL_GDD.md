# LOCAL_GDD — Planet_1/Location_2 (Ancient Ruins)
**Project:** Call of Relics: Orbital Silence
**Scope:** Second Exploration Location

---

## Overview

Ancient Ruins — друга локація на Kepler-442b. Залишки невідомої цивілізації з потенційними артефактами та знаннями.

---

## Location Data

| Property | Value |
|----------|-------|
| Location ID | Location2 |
| Display Name | Ancient Ruins |
| Parent Planet | Planet_1 |
| Type | Exploration / Discovery |
| Context | TransitionConfig.Contexts.Surface |
| Difficulty | Easy |

---

## Environment

### Terrain
- Скелястий ландшафт
- Руїни стародавніх споруд
- Посадковий майданчик біля входу

### Structures
- Напівзруйновані стіни
- Колони з невідомими символами
- Центральна споруда (temple/archive)

### Atmosphere
- Безпечна для дихання
- Пил у повітрі біля руїн
- Містичне освітлення

---

## Gameplay Elements

### Primary Goal (EPIC 7)
- TBD — знайти перший артефакт/знання про цивілізацію

### Optional Objectives
- Дослідити всі кімнати
- Знайти приховані записи
- Сфотографувати символи

### Resources
- TBD — можливі рідкісні матеріали

### Knowledge Items
- Записи про зниклу цивілізацію
- Перші згадки про "Orbital Silence"
- Координати інших локацій?

---

## Narrative Elements

### Mystery
- Хто побудував ці споруди?
- Чому вони зникли?
- Зв'язок з "Orbital Silence"

### Discoveries
- Перші знаки розумного життя
- Попередження? Запрошення?
- Карта інших планет?

---

## Player Actions

### Available
- Вийти з корабля
- Дослідження руїн
- Взаємодія з артефактами
- Збір knowledge items
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

**Storage Path:** `ServerStorage/Planets/Planet_1/Surface/Location2/`

**Required Elements:**
- `Workspace/LandingPad` — посадковий майданчик
- `Workspace/Ruins` — моделі руїн
- `Config.luau` — конфігурація локації

**Workspace Structure:**
```
Location2/Workspace/
├── LandingPad (Model)       # Ship landing point
├── Ruins/                   # Ancient structures
│   ├── Walls
│   ├── Columns
│   └── CentralTemple
├── Lighting/
│   ├── Sky
│   └── Atmosphere
├── Collectibles/            # Knowledge items
└── Interactables/           # Artifacts
```

---

## Config.luau Example

```lua
return {
    id = "Location2",
    displayName = "Ancient Ruins",
    context = "Surface",

    -- Environment
    gravity = 1.2,
    hasAtmosphere = true,
    hazardLevel = 0,

    -- Gameplay
    timeLimit = nil,
    primaryGoal = "FindArtifact",  -- TBD

    -- Spawn
    spawnPoint = "LandingPad"
}
```

---

## Related Documents

- [../../LOCAL_GDD.md](../../LOCAL_GDD.md) — Planet_1 overview
- [../../Orbit/LOCAL_GDD.md](../../Orbit/LOCAL_GDD.md) — Orbital view
- [../Location_1/LOCAL_GDD.md](../Location_1/LOCAL_GDD.md) — Landing Site Alpha
