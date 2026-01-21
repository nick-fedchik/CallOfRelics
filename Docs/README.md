# Documentation — Call of Relics: Orbital Silence

> Центральний індекс документації проєкту

---

## Структура документації

```
Docs/
├── README.md                ← Цей файл (головна навігація)
├── GameDesign/              ← Ігровий дизайн
│   ├── README.md            ← Навігація по GameDesign
│   ├── GDD.md               ← Game Design Document (13 розділів)
│   ├── SPACESHIP.md         ← Космічний корабель
│   ├── PLAYER.md            ← Персонаж гравця
│   ├── PLANET_LOCATIONS.md  ← Система планетних локацій (NEW)
│   └── Planets/             ← Планети та локації
└── TechDesign/              ← Технічна документація
    ├── README.md            ← Навігація по TechDesign
    ├── TDD.md               ← Technical Design Document
    ├── KB.md                ← Knowledge Base
    ├── FOLDER_STRUCTURE.md
    └── README_GUI_DEV.md
```

---

## GameDesign — Ігровий дизайн

**Папка:** [GameDesign/](GameDesign/)

Містить документацію з ігрового дизайну — концепція гри, механіки, ігровий світ, планети та локації.

### Документи

| Документ | Опис |
|----------|------|
| [GDD.md](GameDesign/GDD.md) | **Game Design Document** — головний документ (13 розділів), концепція, механіки, світ |
| [SPACESHIP.md](GameDesign/SPACESHIP.md) | **Космічний корабель** — "Самотній Колумб", модулі, робочі місця, сканування |
| [PLAYER.md](GameDesign/PLAYER.md) | **Персонаж гравця** — глобальні стани, профіль, інвентар, UseCase |
| [PLANET_LOCATIONS.md](GameDesign/PLANET_LOCATIONS.md) | **Система локацій** — класифікація, стани, прогресія, невдачі |
| [Planets/](GameDesign/Planets/) | **Планети та локації** — опис кожної планети та її локацій |

### Що тут шукати?

- Концепція та ідея гри
- Опис ігрових механік
- Характеристики персонажа та корабля
- Опис планет і локацій
- Наративна складова

**Детальніше:** [GameDesign/README.md](GameDesign/README.md)

---

## TechDesign — Технічна документація

**Папка:** [TechDesign/](TechDesign/)

Містить технічну документацію — архітектура, структура коду, перевірені рішення та стандарти.

### Документи

| Документ | Опис |
|----------|------|
| [TDD.md](TechDesign/TDD.md) | **Technical Design Document** — архітектура, ієрархія станів, сервіси |
| [KB.md](TechDesign/KB.md) | **Knowledge Base** — перевірені рішення, ефективні алгоритми |
| [FOLDER_STRUCTURE.md](TechDesign/FOLDER_STRUCTURE.md) | **Структура папок** — організація коду проєкту |
| [README_GUI_DEV.md](TechDesign/README_GUI_DEV.md) | **UI Development** — клієнтські системи, StarterPlayerScripts |

### Що тут шукати?

- Архітектурні рішення
- Структура сервісів (Server/Client)
- Конвенції коду
- Рішення типових проблем
- Технічні специфікації

**Детальніше:** [TechDesign/README.md](TechDesign/README.md)

---

## Product Backlog

Беклог проєкту ведеться на GitHub:

| Ресурс | Посилання |
|--------|-----------|
| **Issues** (Stories) | [github.com/nick-fedchik/CallOfRelics/issues](https://github.com/nick-fedchik/CallOfRelics/issues) |
| **Milestones** (EPICs) | [github.com/nick-fedchik/CallOfRelics/milestones](https://github.com/nick-fedchik/CallOfRelics/milestones) |

---

## Інші файли

| Файл | Опис |
|------|------|
| [../CHANGELOG.md](../CHANGELOG.md) | Історія змін проєкту |
| [../README.md](../README.md) | Головний README репозиторію |
| [../README-UKR.md](../README-UKR.md) | README українською |

---

## Ієрархія документації

```
GameDesign/GDD.md          ← ЩО робимо (концепція)
    ↓ деталізується
GameDesign/SPACESHIP.md    ← Деталі систем
GameDesign/Planets/        ← Деталі контенту
    ↓ реалізується
TechDesign/TDD.md          ← ЯК робимо (архітектура)
    ↓ відстежується
GitHub Issues              ← Tasks & Stories
    ↓ документується
TechDesign/KB.md           ← ЩО ПРАЦЮЄ (досвід)
```

---

## Швидкі посилання

| Що шукаєте? | Де знайти? |
|-------------|------------|
| Концепція гри | [GameDesign/GDD.md](GameDesign/GDD.md) |
| Космічний корабель | [GameDesign/SPACESHIP.md](GameDesign/SPACESHIP.md) |
| Персонаж гравця | [GameDesign/PLAYER.md](GameDesign/PLAYER.md) |
| Система локацій | [GameDesign/PLANET_LOCATIONS.md](GameDesign/PLANET_LOCATIONS.md) |
| Планети | [GameDesign/Planets/](GameDesign/Planets/) |
| Архітектура | [TechDesign/TDD.md](TechDesign/TDD.md) |
| Перевірені рішення | [TechDesign/KB.md](TechDesign/KB.md) |
| Структура папок | [TechDesign/FOLDER_STRUCTURE.md](TechDesign/FOLDER_STRUCTURE.md) |
| Backlog | [GitHub Issues](https://github.com/nick-fedchik/CallOfRelics/issues) |

---

**Версія:** 1.1
**Дата:** 2026-01-21
