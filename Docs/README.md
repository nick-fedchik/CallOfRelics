# Documentation — Call of Relics: Orbital Silence

> Центральний індекс документації проєкту

---

## Core Documents

| Document | Description |
|----------|-------------|
| [GDD.md](GDD.md) | **Game Design Document** — ігрова концепція, сценарій, світ, ролі гравця, базові правила та ключові системи |
| [TDD.md](TDD.md) | **Technical Design Document** — архітектурна модель, ієрархія станів, розмежування відповідальностей |
| [Backlog.md](Backlog.md) | **Product Backlog** — roadmap, active EPICs, stories, sprint planning |
| [KB.md](KB.md) | **Knowledge Base** — успішні рішення, ефективні алгоритми, перевірені практики |

---

## Structure Documents

| Document | Description |
|----------|-------------|
| [FOLDER_STRUCTURE.md](FOLDER_STRUCTURE.md) | Рекомендована структура папок для Script Sync, ServerScriptService, ReplicatedStorage |
| [README_GUI_DEV.md](README_GUI_DEV.md) | StarterPlayerScripts структура — UI модулі, Core bootstrap, клієнтські системи |

---

## Planets Documentation

Локальна документація для кожної планети та локації.

### Planets Overview

| Document | Description |
|----------|-------------|
| [Planets/README.md](Planets/README.md) | Огляд планетарної системи, Planet Registry, структура планет |

### Planet_1 — Біллі Рубін

```
Planets/Planet_1/
├── README.md                      # Planet overview
├── Orbit/
│   └── README.md                  # Orbital view documentation
└── Surface/
    ├── Location_1/
    │   └── README.md              # Landing Site Alpha
    └── Location_2/
        └── README.md              # Ancient Ruins
```

| Document | Description |
|----------|-------------|
| [Planets/Planet_1/README.md](Planets/Planet_1/README.md) | **Біллі Рубін** — перша планета, опис та конфігурація |
| [Planets/Planet_1/Orbit/README.md](Planets/Planet_1/Orbit/README.md) | Орбітальний вигляд — навігація, сканування, PilotUI |
| [Planets/Planet_1/Surface/Location_1/README.md](Planets/Planet_1/Surface/Location_1/README.md) | **Landing Site Alpha** — перша локація, tutorial zone |
| [Planets/Planet_1/Surface/Location_2/README.md](Planets/Planet_1/Surface/Location_2/README.md) | **Ancient Ruins** — руїни давньої цивілізації |

### Planet_Earth — Earth (Planned)

```
Planets/Planet_Earth/
└── README.md                      # Planet overview (planned)
```

| Document | Description |
|----------|-------------|
| [Planets/Planet_Earth/README.md](Planets/Planet_Earth/README.md) | **Earth** — планета-походження (planned) |

---

## Utility Documents

| Document | Description |
|----------|-------------|
| [copilot-instructions.md](copilot-instructions.md) | Інструкції для GitHub Copilot |

---

## Related Files (Root)

| File | Description |
|------|-------------|
| [../CHANGELOG.md](../CHANGELOG.md) | Історія змін проєкту |
| [../README.md](../README.md) | Головний README проєкту |

---

## Document Conventions

- **GDD** — Game Design Document (що робимо)
- **TDD** — Technical Design Document (як робимо)
- **LOCAL_GDD** — локальна документація планет/локацій (тепер README.md)
- **KB** — Knowledge Base (що працює)
- **Backlog** — Product Backlog (що далі)
