# Changelog — Call of Relics: Orbital Silence

Всі значущі зміни в проєкті документуються у цьому файлі.

---

## [Unreleased]

### Added
- Структура папок ServerScriptService (Core, Services, Systems, Setup)
- Документація структури проєкту (Docs/FOLDER_STRUCTURE.md)
- Інструкція налаштування Script Sync (SETUP_SCRIPT_SYNC.md)
- Рекомендації щодо структури у TDD розділ 13.3.2

### Changed
- **BREAKING:** Переміщено GameStateManager → ServerScriptService/Core/
- **BREAKING:** Переміщено ServerBootstrap → ServerScriptService/Core/
- **BREAKING:** Переміщено PlayerService → ServerScriptService/Services/
- **BREAKING:** Переміщено RemoteEventsSetup → ServerScriptService/Setup/
- Оновлено шляхи require() у ServerBootstrap (рядки 62-68)
- Оновлено шляхи require() у PlayerService (рядки 60-61)
- Оновлено EPIC1_IMPLEMENTATION.md з новими шляхами

### Fixed
- Виправлено "Infinite yield" помилку через застарілі шляхи до модулів

---

## [0.1.0] - 2026-01-11

### Added - EPIC 1: Game Boot & Global States

#### Server-Side
- GameStateManager.lua — координатор глобальних станів
- ServerBootstrap.server.lua — серверна ініціалізація
- PlayerService.lua — керування життєвим циклом гравця
- RemoteEventsSetup.server.lua — створення RemoteEvents

#### Client-Side
- ClientBootstrap.client.lua — клієнтська ініціалізація
- ScreenSaverUI.lua — інтерфейс ScreenSaver
- UIManager.lua — керування UI станами

#### Documentation
- EPIC1_IMPLEMENTATION.md — повний опис реалізації EPIC 1
- Docs/TDD.md — Technical Design Document v0
- Docs/GDD.md — Game Design Document
- Docs/Backlog.md — Product backlog

#### Features
- Повний життєвий цикл гри (Boot → LoggedOff → Initializing → InGame)
- ScreenSaver UI з можливістю входу (Space/Click)
- Глобальні стани: LoggedOff, Initializing, InGame
- Валідація переходів між станами
- Однокористувацька гра (single-player constraint)
- Server-authoritative архітектура
- Стандартизоване логування (TDD Section 11)
- Обробка помилок (TDD Section 10)

### Architecture
- Реалізовано State-driven architecture (TDD 1.2)
- Реалізовано єдиний координатор станів (TDD 2.5)
- Реалізовано принцип "Request → Verification → Permission" (TDD 3.4)
- Реалізовано boot sequence (TDD 4.3)
- Всі модулі мають стандартизовані заголовки (TDD 11.8)

---

## Формат

Цей changelog дотримується принципів [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Категорії змін:
- **Added** — нові можливості
- **Changed** — зміни існуючої функціональності
- **Deprecated** — функціональність, що застаріла
- **Removed** — видалена функціональність
- **Fixed** — виправлення помилок
- **Security** — виправлення безпеки

---

**Примітка:** BREAKING позначає зміни, що вимагають оновлення у Roblox Studio.
