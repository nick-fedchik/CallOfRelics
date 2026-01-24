# Technical Design Documentation
**Project:** Call of Relics: Orbital Silence

---

## Про цей розділ

Папка `Docs/TechDesign/` містить технічну документацію проєкту — архітектурні рішення, структуру коду, перевірені практики та технічні специфікації.

Документи цього розділу описують:
- Архітектуру та структуру проєкту
- Технічні рішення та їх обґрунтування
- Стандарти коду та конвенції
- Перевірені практики (Knowledge Base)

---

## Структура документації

```
Docs/TechDesign/
├── README.md              ← Цей файл (навігація)
├── TDD.md                 ← Technical Design Document
├── ARCHITECTURE.md        ← Architecture Documentation (з Mermaid діаграмами)
├── KB.md                  ← Knowledge Base (перевірені рішення)
├── FOLDER_STRUCTURE.md    ← Структура папок проєкту
├── README_GUI_DEV.md      ← Документація клієнтських UI систем
└── WORKFLOW.md            ← Development Workflow (NEW)
```

---

## Головні документи

### TDD.md — Technical Design Document

**Головний технічний документ проєкту.** Описує архітектуру, ієрархію станів та розмежування відповідальностей.

**Зміст:**
| Розділ | Тема |
|--------|------|
| 1 | Архітектурна модель |
| 2 | Глобальні стани гри |
| 3 | Ієрархія сервісів |
| 4 | Client-Server комунікація |
| 5 | Система переходів (Transitions) |
| 6 | Context Registry |
| 7 | Profile Service |

**Посилання:** [TDD.md](TDD.md)

---

### ARCHITECTURE.md — Architecture Documentation

**Архітектурна документація з Mermaid діаграмами.** Візуальне представлення всіх компонентів системи.

**Зміст:**
| Розділ | Тема |
|--------|------|
| 1 | Architecture Overview |
| 2 | Components Diagram (Server, UI, Replicated) |
| 3 | ServerStorage та Planets Structure |
| 4 | Game Boot Sequence |
| 5 | Loading/Unloading Level Sequence |
| 6 | Game Statuses and State Machine |
| 7 | Events (діаграма) |
| 8 | Player Profile |

**Посилання:** [ARCHITECTURE.md](ARCHITECTURE.md)

---

### KB.md — Knowledge Base

**База знань проєкту.** Містить перевірені рішення, ефективні алгоритми та успішні практики.

**Зміст:**
- Перевірені архітектурні рішення
- Рішення типових проблем
- Ефективні алгоритми (анімації, камера, UI)
- Інтеграційні патерни

**Посилання:** [KB.md](KB.md)

---

### FOLDER_STRUCTURE.md — Структура проєкту

**Рекомендована структура папок** для Script Sync, ServerScriptService, ReplicatedStorage.

**Зміст:**
- Ієрархія папок
- Конвенції іменування
- Правила організації коду

**Посилання:** [FOLDER_STRUCTURE.md](FOLDER_STRUCTURE.md)

---

### README_GUI_DEV.md — UI Development Guide

**Документація клієнтських систем.** StarterPlayerScripts структура, UI модулі, Core bootstrap.

**Зміст:**
- Структура StarterPlayerScripts
- UI модулі та їх відповідальності
- Core bootstrap процес
- Клієнтські системи

**Посилання:** [README_GUI_DEV.md](README_GUI_DEV.md)

---

## Зв'язок з іншими документами

### Docs/GameDesign/ (ігровий дизайн)

| Документ | Призначення |
|----------|-------------|
| [GDD.md](../GameDesign/GDD.md) | Game Design Document (13 розділів) |
| [SPACESHIP.md](../GameDesign/SPACESHIP.md) | Космічний корабель, модулі, сканування |
| [PLAYER.md](../GameDesign/PLAYER.md) | Персонаж гравця, глобальні стани |
| [PLANET_LOCATIONS.md](../GameDesign/PLANET_LOCATIONS.md) | Система планетних локацій |
| [Planets/](../GameDesign/Planets/) | Планети та локації |

### Зовнішні ресурси

| Ресурс | Призначення |
|--------|-------------|
| [GitHub Issues](https://github.com/nick-fedchik/CallOfRelics/issues) | Product Backlog |
| [GitHub Milestones](https://github.com/nick-fedchik/CallOfRelics/milestones) | EPICs |
| [CHANGELOG.md](../../CHANGELOG.md) | Історія змін проєкту |

---

## Ієрархія документації

```
GameDesign/GDD.md (що робимо)
    ↓ реалізується в
TechDesign/TDD.md (як робимо)
    ↓ відстежується в
GitHub Issues (tasks)
    ↓ документується в
TechDesign/KB.md (що працює)
```

---

## Принципи документації

### Naming Convention

- **TDD.md** — Technical Design Document
- **KB.md** — Knowledge Base
- **README.md** — опис папки/розділу
- **CAPS_SNAKE.md** — документи по темах

### Мова документації

- Основна мова: **українська**
- Технічні терміни: **англійська** (де доречно)
- Код та назви файлів: **англійська**

---

**Версія:** 2.2
**Дата:** 2026-01-21

**Changelog:**
- 2.2: Оновлено посилання на GameDesign; додано PLANET_LOCATIONS.md
- 2.1: Додано ARCHITECTURE.md з Mermaid діаграмами
- 2.0: Реструктуризація — Backlog перенесено на GitHub Issues
- 1.0: Початкова версія
