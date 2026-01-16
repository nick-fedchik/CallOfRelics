# LOCAL_GDD — Planet_1 (Kepler-442b)
**Project:** Call of Relics: Orbital Silence
**Scope:** First Playable Planet

---

## Overview

Kepler-442b — перша планета, яку досліджує гравець. Екзопланета в зоні життя з потенційно придатними умовами.

---

## Planet Data

| Property | Value |
|----------|-------|
| Planet ID | Planet_1 |
| Display Name | Kepler-442b |
| Type | Habitable (Super-Earth) |
| Atmosphere | Breathable |
| Gravity | 1.2g |
| Day/Night Cycle | TBD |

---

## Locations

| Location ID | Name | Status | Type |
|-------------|------|--------|------|
| Orbit | Orbital View | Implemented | Navigation Hub |
| Location1 | Landing Site Alpha | Implemented | Exploration |
| Location2 | Ancient Ruins | Implemented | Exploration |

---

## Discovery Order

1. Гравець прибуває на орбіту (GameStart)
2. Сканування поверхні відкриває локації
3. Landing на відкриті локації
4. Дослідження та збір ресурсів

---

## Planet-Specific Features

### Environment
- Синє небо з зеленуватим відтінком
- Подвійне сонце (бінарна система)
- Екзотична флора

### Hazards
- Немає (перша планета для навчання)

### Resources
- TBD (визначається в Location GDD)

---

## Narrative Context

Kepler-442b — перша зупинка експедиції. Планета обрана через:
- Стабільну орбіту в зоні життя
- Сигнали невідомого походження
- Потенційні сліди цивілізації

---

## Technical Notes

**Storage Path:** `ServerStorage/Planets/Planet_1/`

**Config.luau:**
```lua
return {
    id = "Planet_1",
    displayName = "Kepler-442b",
    type = "Habitable",
    gravity = 1.2,
    hasAtmosphere = true
}
```

---

## Related Documents

- [Orbit/LOCAL_GDD.md](Orbit/LOCAL_GDD.md) — Orbital view
- [Surface/Location_1/LOCAL_GDD.md](Surface/Location_1/LOCAL_GDD.md) — Landing Site Alpha
- [Surface/Location_2/LOCAL_GDD.md](Surface/Location_2/LOCAL_GDD.md) — Ancient Ruins
