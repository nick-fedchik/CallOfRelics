# LOCAL_GDD — Planets System
**Project:** Call of Relics: Orbital Silence
**Scope:** All Planets

---

## Overview

Планетарна система гри. Кожна планета — окремий ігровий контейнер з орбітою та локаціями на поверхні.

---

## Planet Registry

| Planet ID | Name | Status | Locations |
|-----------|------|--------|-----------|
| Planet_1 | Біллі Рубін | Implemented | 2 |
| Planet_Earth | Earth | Planned | 0 |

---

## Planet Structure

Кожна планета зберігається в `ServerStorage/Planets/Planet_Id/`:

```
Planet_Id/
├── Config.luau                    # Planet configuration
├── ReplicatedStorage/             # Planet-level scripts
├── ServerScriptService/           # Planet-level scripts
├── StarterPlayer/                 # Planet-level scripts
├── Orbit/                         # Orbital view
│   ├── Config.luau
│   ├── Workspace/
│   │   ├── Planet (Model)
│   │   └── Lighting/
│   └── Scripts folders...
└── Surface/
    └── Location_Id/
        ├── Config.luau
        ├── Workspace/
        │   └── Lighting/
        └── Scripts folders...
```

---

## Discovery System

- Планети відкриваються через сканування з попередньої локації
- Нові планети з'являються в ProfileService як `discoveredPlanets`
- Локації на планеті відкриваються через сканування з орбіти

---

## Navigation Rules

1. **Orbit → Surface**: Landing через TransitionService
2. **Surface → Orbit**: Launch через TransitionService
3. **Planet → Planet**: TBD (warp/jump system)

---

## Planet Types (Planned)

| Type | Characteristics | Example |
|------|----------------|---------|
| Habitable | Breathable atmosphere, low hazards | Біллі Рубін |
| Hostile | Environmental hazards, time limits | TBD |
| Barren | No atmosphere, suit required | TBD |
| Gas Giant | Orbit only, no surface landing | TBD |

---

## Related Documents

- [Planet_1/README.md](Planet_1/README.md) — Біллі Рубін
- [Planet_Earth/README.md](Planet_Earth/README.md) — Earth (origin)
