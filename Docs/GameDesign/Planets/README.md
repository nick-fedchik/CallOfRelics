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

Кожна планета має таку ігрову структуру:

```mermaid
flowchart TB
    subgraph Planet["🌍 Планета"]
        Orbit[🛸 Орбіта<br/>Navigation Hub]

        subgraph Surface["Поверхня"]
            L1[📍 Локація 1]
            L2[📍 Локація 2]
            L3[📍 ...]
        end
    end

    Orbit -->|Landing| L1
    Orbit -->|Landing| L2
    L1 -->|Launch| Orbit
    L2 -->|Launch| Orbit
```

### Компоненти планети

| Компонент | Призначення |
|-----------|-------------|
| **Орбіта** | Точка прибуття, сканування, навігація |
| **Локації поверхні** | Ігрові зони для дослідження |
| **Конфігурація** | Параметри планети (атмосфера, гравітація, тип) |

---

## Discovery System

- Планети відкриваються через сканування з попередньої локації
- Нові планети з'являються в ProfileService як `discoveredPlanets`
- Локації на планеті відкриваються через сканування з орбіти

---

## Navigation Rules

```mermaid
flowchart LR
    subgraph Planet1["🌍 Planet 1"]
        O1[Орбіта]
        L1[Location 1]
        L2[Location 2]
    end

    subgraph Planet2["🌍 Planet 2"]
        O2[Орбіта]
        L3[Location 1]
    end

    O1 -->|Landing| L1
    O1 -->|Landing| L2
    L1 -->|Launch| O1
    L2 -->|Launch| O1

    O1 -.->|Warp TBD| O2
    O2 -->|Landing| L3
    L3 -->|Launch| O2
```

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

## Концептуальна карта подорожі (Journey Map)

```mermaid
flowchart TD
    subgraph Origin["🌍 EARTH (Origin)"]
        E_Start[🚀 Старт експедиції]
    end

    subgraph Sector1["📍 Сектор Alpha"]
        P1[🟢 Біллі Рубін<br/>Habitable<br/>2 локації]
        P2[🟡 Planet 2<br/>Planned]
    end

    subgraph Sector2["📍 Сектор Beta"]
        P3[🟠 Planet 3<br/>Hostile?]
        P4[🔴 Planet 4<br/>Barren?]
    end

    subgraph Final["🌍 EARTH (Return)"]
        E_End[🏠 Повернення]
    end

    E_Start ==>|Міжзоряний стрибок| P1
    P1 -.->|Warp| P2
    P2 -.->|Warp| P3
    P3 -.->|Warp| P4
    P4 ==>|Фінальний стрибок| E_End

    style P1 fill:#90EE90
    style E_Start fill:#87CEEB
    style E_End fill:#FFD700
```

### Вимоги енергії для перельотів

```mermaid
xychart-beta
    title "Енергія для міжпланетних перельотів"
    x-axis [P1→P2, P2→P3, P3→P4, P4→Earth]
    y-axis "Енергія" 0 --> 1000
    bar [100, 200, 350, 800]
    line [100, 200, 350, 800]
```

---

## Related Documents

- [Planet_1/README.md](Planet_1/README.md) — Біллі Рубін
- [Planet_Earth/README.md](Planet_Earth/README.md) — Earth (origin)
