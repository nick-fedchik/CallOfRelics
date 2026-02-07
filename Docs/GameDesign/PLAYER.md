# Персонаж Гравця — Космічний Дослідник
**Project:** Call of Relics: Orbital Silence
**Document Type:** Game Design — Player Character & Profile System

---

## 1. ЗАГАЛЬНИЙ ОПИС

Гравець керує одним персонажем — землянином, освідченим науковцем-дослідником, учасником міжзоряної експедиції до джерела загадкових сигналів.

### Ключова фантазія

> *Ти — не герой.*
> *Ти — той, хто відповів на сигнал.*

### Роль у геймплеї

| Роль | Опис |
|------|------|
| Науковець-дослідник | Універсальний спеціаліст широкого профілю |
| Пілот корабля | Керує космічним кораблем «Самотній Колумб» |
| Дослідник планет | Сканує та досліджує планетні локації |
| Збирач знань | Накопичує knowledge (ніколи не втрачається) |
| Ресурсодобувач | Збирає ресурси (можуть бути втрачені) |

### Шлях гравця (Player Journey)

```mermaid
journey
    title Досвід гравця в Call of Relics
    section Початок
      Запуск гри: 3: Гравець
      Завантаження профілю: 3: Система
      Прибуття на орбіту: 5: Гравець
    section Дослідження
      Сканування планети: 4: Гравець
      Виявлення локації: 5: Гравець
      Посадка на поверхню: 5: Гравець
      Дослідження руїн: 5: Гравець
    section Прогрес
      Збір знань: 5: Гравець
      Повернення на корабель: 4: Гравець
      Відкриття нової планети: 5: Гравець
    section Фінал
      Накопичення енергії: 3: Гравець
      Повернення на Землю: 5: Гравець
```

---

## 2. ГЛОБАЛЬНІ СТАНИ ГРАВЦЯ

Гравець може перебувати у двох глобальних станах, які визначають, чи активний ігровий світ.

```mermaid
stateDiagram-v2
    [*] --> LoggedOff: Запуск гри

    LoggedOff --> LoggedIn: Увійти в гру
    LoggedIn --> LoggedOff: Вийти з гри
    LoggedIn --> LoggedOff: Втрата з'єднання

    note right of LoggedOff
        Заставка гри
        Ігрові системи неактивні
    end note

    note right of LoggedIn
        Керування персонажем
        Всі системи активні
    end note
```

### 2.1. Поза грою (Logged Off)

У стані **Logged Off** гравець:
- Бачить заставку гри
- Бачить свій аватар Roblox
- Бачить ім'я гравця
- Має можливість увійти у гру

Цей стан:
- Не впливає на ігровий світ
- Не запускає ігрові системи
- Є безпечним і нейтральним

Стан **Logged Off** використовується:
- Перед початком гри
- Після виходу з гри
- Після втрати з'єднання

### 2.2. У грі (Logged In)

У стані **Logged In**:
- Гравець керує персонажем
- Активні всі ігрові системи
- Відбувається збереження прогресу

Гравець може:
- Добровільно вийти з гри та перейти в Logged Off
- Автоматично перейти в Logged Off у разі втрати з'єднання

### 2.3. Втрата з'єднання

Якщо гравець втрачає підключення:
- Після таймауту він переводиться у стан Logged Off
- Ігровий прогрес зберігається
- При повторному вході гра відновлюється з корабля

---

## 3. ПОХОДЖЕННЯ ТА ПЕРЕДІСТОРІЯ

### 3.1. Експедиція

- **Організатор:** Корпорація «Нащаддя Ілона»
- **Мета:** Дослідити джерело сигналів *The Call* («Поклик»)
- **Корабель:** Експериментальний автономний «Самотній Колумб»

### 3.2. Початкова ситуація

Після міжзоряного перельоту:
- Корабель витратив майже всю енергію
- Повернення на Землю неможливе
- Місія перетворилася на довготривалу автономну експедицію

### 3.3. Початкові знання

На старті гри персонаж володіє базовими знаннями:
- Виживання
- Астрономія
- Геологія
- Фізика
- Хімія
- Комп'ютерні науки

---

## 4. ПРОФІЛЬ ГРАВЦЯ (PLAYER PROFILE)

Профіль зберігається в DataStore і містить всю прогресію гравця.

```mermaid
classDiagram
    class Profile {
        +number userId
        +timestamp createdAt
        +timestamp lastLogin
        +number profileVersion = 4
    }

    class LocationState {
        +string currentPlanet
        +string currentLocation
        +object lastSafeState
    }

    class Discovery {
        +map discoveredPlanets
        +map exploredLocations
        +array visitHistory [max 100]
    }

    class ShipState {
        +string spaceShipModel
        +number energyLevel
        +number hullIntegrity
        +ScannerModule modules.scanner
    }

    class ScannerModule {
        +number batteryCharge = 500
        +number scanCount = 0
    }

    class Inventory {
        +array resources [losable]
        +array knowledge [permanent]
    }

    class Stats {
        +number totalPlayTime
        +number locationsExplored
        +number resourcesCollected
        +number knowledgeDiscovered
    }

    Profile --> LocationState
    Profile --> Discovery
    Profile --> ShipState
    Profile --> Inventory
    Profile --> Stats
    ShipState --> ScannerModule
```

### Зв'язки між ігровими сутностями (ER Diagram)

```mermaid
erDiagram
    PLAYER ||--o{ PROFILE : has
    PROFILE ||--|| SHIP : owns
    PROFILE ||--o{ DISCOVERY : tracks
    PROFILE ||--o{ INVENTORY : contains

    SHIP ||--o{ MODULE : equipped
    SHIP }o--|| PLANET : orbits

    PLANET ||--o{ LOCATION : contains
    LOCATION ||--o{ RESOURCE : spawns
    LOCATION ||--o{ KNOWLEDGE : holds

    DISCOVERY }o--|| PLANET : discovered
    DISCOVERY }o--|| LOCATION : explored

    INVENTORY ||--o{ RESOURCE : stores
    INVENTORY ||--o{ KNOWLEDGE : records

    PLAYER {
        number userId PK
        string displayName
    }
    PROFILE {
        number version
        timestamp lastLogin
    }
    SHIP {
        string model
        number energy
        number hull
    }
    PLANET {
        string id PK
        string name
        string type
    }
    LOCATION {
        string id PK
        string name
        string type
        number visibility
    }
```

### 4.1. Ідентифікація

| Поле | Тип | Опис |
|------|-----|------|
| userId | number | Roblox User ID |
| createdAt | timestamp | Час створення профілю |
| lastLogin | timestamp | Останній вхід |
| profileVersion | number | Версія схеми (поточна: **4**) |

**Історія версій профілю:**

| Версія | Зміна |
|--------|-------|
| 1 | Початкова схема |
| 2 | exploredLocations — з масиву на per-planet структуру |
| 3 | Очистка debug-локацій, скидання сканера |
| 4 | Повторне скидання сканера після debug-тестування |

> Міграція виконується автоматично при завантаженні профілю (`MigrateProfile()`).

### 4.2. Поточний стан (Location State)

| Поле | Тип | Початкове значення | Опис |
|------|-----|-------------------|------|
| currentPlanet | string | "Planet_1" | ID поточної планети |
| currentLocation | string | "Orbit" | ID поточної локації |
| lastSafeState | object | {planetId, locationName, timestamp} | Остання безпечна точка |

**lastSafeState** оновлюється коли гравець на орбіті (safe zone).

### 4.3. Відкриття (Discovery Tracking)

| Поле | Тип | Опис |
|------|-----|------|
| discoveredPlanets | {[planetId]: timestamp} | Відкриті планети |
| exploredLocations | {[planetId]: {[locationId]: data}} | Досліджені локації |
| visitHistory | array | Історія відвідувань (макс. 100, rolling buffer) |

**exploredLocations[planetId][locationId]:**
- `discoveredAt` — час відкриття
- `visitCount` — кількість відвідувань

**Початковий стан:** Planet_1 відкрита, Orbit відвідана з visitCount=1.

### 4.4. Корабель (Ship State)

| Поле | Тип | Початкове значення | Опис |
|------|-----|-------------------|------|
| spaceShipModel | string | "SpaceShip" | Модель корабля |
| shipState.energyLevel | number | 100 | Рівень енергії (макс. 1000 з SpaceShipConfig) |
| shipState.hullIntegrity | number | 100 | Цілісність корпусу (%) |

**Модулі корабля (shipState.modules):**

| Модуль | Поле | Початкове значення | Опис |
|--------|------|-------------------|------|
| scanner | batteryCharge | 500 | Заряд батареї сканера (макс. 500) |
| scanner | scanCount | 0 | Кількість сканувань (зношення: -5%/скан) |

---

## 5. ІНВЕНТАР (INVENTORY)

### 5.1. Ресурси (Resources)

| Властивість | Опис |
|-------------|------|
| Тип | Колекція предметів |
| Початкове значення | Порожній інвентар |
| При невдачі | **Можуть бути втрачені** |

Кожен ресурс має:
- ID (унікальний ідентифікатор)
- Кількість
- Час отримання

### 5.2. Знання (Knowledge)

| Властивість | Опис |
|-------------|------|
| Тип | Колекція записів |
| Початкове значення | Порожня база |
| При невдачі | **Ніколи не втрачаються** |

Кожен запис знань має:
- ID та назва
- Час відкриття
- Місце знаходження (планета/локація)

> **Ключова механіка:** Знання зберігаються негайно і ніколи не втрачаються (навіть при смерті персонажа або виході з гри).

---

## 6. СТАТИСТИКА (STATISTICS)

Статистика зберігається в об'єкті `stats` профілю (не в окремих полях).

| Поле | Тип | Початкове значення | Авто-інкремент | Опис |
|------|-----|-------------------|----------------|------|
| stats.totalPlayTime | number | 0 | Ні (заплановано) | Загальний час гри (секунди) |
| stats.locationsExplored | number | 1 | Так (при discovery) | Кількість досліджених локацій |
| stats.resourcesCollected | number | 0 | Так (при AddResources) | Загальна кількість зібраних ресурсів |
| stats.knowledgeDiscovered | number | 0 | Так (при AddKnowledge) | Кількість відкритих записів знань |

**Стан реалізації:**
- `locationsExplored` — інкрементується в `MarkLocationDiscovered()`, рахує лише поверхневі локації
- `resourcesCollected` — інкрементується в `AddResources()`, рахує загальну кількість (не унікальні типи)
- `knowledgeDiscovered` — інкрементується в `AddKnowledge()`, рахує унікальні записи
- `totalPlayTime` — поле існує, але автоматичний підрахунок ще не реалізовано

---

## 7. ЗБЕРЕЖЕННЯ ПРОГРЕСУ

### 7.1. Автоматичне збереження

| Подія | Опис | Деталі |
|-------|------|--------|
| PlayerRemoving | При виході гравця з гри | Повне збереження всіх змін |
| PilotSeat sit | Коли гравець сідає в крісло пілота | Лише якщо прапорець `profileChanged` |
| Knowledge added | Негайно при отриманні нових знань | Синхронне збереження (не батчеве) |

**Механізм збереження:**
- DataStoreService з ключем `Player_{UserId}`
- 3 спроби з exponential backoff (1, 2, 4 секунди)
- Fallback до тимчасового in-memory профілю при недоступності DataStore

### 7.2. Безпечний стан (Safe State)

При переході на орбіту оновлюється `lastSafeState`:
- Планета, на якій перебував гравець
- Локація (зазвичай "Orbit")
- Час збереження

При критичній невдачі гравець повертається до останнього безпечного стану.

---

## 8. РОЗВИТОК ПЕРСОНАЖА

### 8.1. RPG-аспект

У процесі гри персонаж:
- Накопичує нові знання
- Розширює свою компетенцію
- Відкриває нові наукові та технічні можливості

### 8.2. Зв'язок з кораблем

Розвиток персонажа:
- Зберігається між ігровими сесіями
- Напряму пов'язаний із дослідженням локацій
- Впливає на розвиток корабля

### 8.3. Прогресія знань

```mermaid
flowchart LR
    subgraph Location["📍 На локації"]
        D[🔍 Discovery<br/>Знаходження]
        A[🔬 Analysis<br/>Вивчення]
    end

    subgraph Permanent["💾 Постійне"]
        K[📚 Knowledge<br/>База знань]
    end

    subgraph Application["⚙️ Застосування"]
        U[🔧 Upgrades<br/>Апгрейди корабля]
        N[🆕 New Abilities<br/>Нові можливості]
    end

    D --> A --> K
    K --> U
    K --> N

    style K fill:#90EE90
```

| Етап | Опис |
|------|------|
| Discovery | Знаходження об'єкта/артефакту |
| Analysis | Вивчення та аналіз |
| Knowledge | Запис у базу знань (permanent) |
| Application | Використання знань для апгрейдів |

---

## 9. ПЕРСОНАЛЬНИЙ КОМП'ЮТЕР

Персональний комп'ютер (Seat Personal Computer) — це робоче місце на кораблі, де гравець переглядає свій профіль, статистику дослідження та стан корабля. Інтерфейс стилізований під ретро-термінал Apple II (зелений фосфорний CRT-монітор, 1980-х).

### 9.1. Візуальний стиль

| Параметр | Значення |
|----------|----------|
| Розмір CRT-екрану | 540 x 504 px |
| Колірна палітра | Green Phosphor (#33FF00) |
| Power LED | Зелений індикатор (нижній лівий кут) |
| Terminal ID | KM-OP/01 (нижній правий кут) |
| Анімація | CRT power-on/off fade через CanvasGroup |

### 9.2. Інформаційні блоки

Екран персонального комп'ютера відображає 4 секції:

**1. Оператор (верхня частина)**

| Поле | Джерело даних |
|------|---------------|
| Контекст | "ОРБIТА" або "ПОВЕРХНЯ" (з TransitionConfig) |
| Ім'я оператора | Player.DisplayName |
| Корабель | GameConfig.ShipName ("Самотній Колумб") |
| Клас | "Дослiдник" (фіксовано) |

**2. База знань (Knowledge Base)**

| Показник | Джерело даних |
|----------|---------------|
| Планети відкриті | Кількість з `profile.discoveredPlanets` |
| Локації досліджені | Кількість з `profile.exploredLocations` (без Orbit) |
| Реліквії знайдені | `profile.stats.knowledgeDiscovered` |
| Сканувань проведено | `profile.shipState.modules.scanner.scanCount` |

**3. Стан корабля (Ship Status)**

| Показник | Джерело даних |
|----------|---------------|
| Корпус (Hull) | % від maxHull (SpaceShipConfig.defense) |
| Щит (Shield) | % від maxShield (SpaceShipConfig.defense) |
| Характеристики | Корпус / Щит / Швидкість (з SpaceShipConfig) |

**4. Місія (Mission Overview)**

| Показник | Стан |
|----------|------|
| Поточна місія | Фіксований текст (заплановано: динамічний) |

### 9.3. Оновлення даних

Дані надходять через `ProfileUpdate` RemoteEvent від сервера:
- При завантаженні профілю
- При зміні стану (discovery, scan, location change)

### 9.4. Стан реалізації

| Функція | Статус |
|---------|--------|
| Відображення статистики | ✅ Реалізовано |
| CRT-анімація power-on/off | ✅ Реалізовано |
| Контекст орбіта/поверхня | ✅ Реалізовано |
| Інтерактивний інвентар | ❌ Заплановано (PersonalComputerService v0.1 — stub) |
| Детальний перегляд знань | ❌ Заплановано |
| Динамічна місія | ❌ Заплановано |

---

## 10. ВЗАЄМОДІЯ ГРАВЦЯ З СИСТЕМАМИ

### UseCase Diagram

Наступна діаграма показує основні варіанти використання (Use Cases) доступні гравцю:

```mermaid
flowchart TB
    subgraph Actors["👤 Актори"]
        Player["🧑‍🚀 Гравець"]
    end

    subgraph ShipSystems["🚀 Системи корабля"]
        UC_Pilot["Керувати кораблем"]
        UC_Scan["Сканувати поверхню"]
        UC_Locate["Використовувати локатор"]
        UC_Travel["Здійснювати перельоти"]
        UC_ManageShip["Керувати модулями"]
    end

    subgraph ExplorationSystems["🌍 Системи дослідження"]
        UC_Land["Здійснити посадку"]
        UC_Explore["Досліджувати локацію"]
        UC_Collect["Збирати ресурси"]
        UC_Complete["Виконати головну ціль"]
        UC_Escape["Втекти з локації"]
        UC_Return["Повернутись на корабель"]
    end

    subgraph ProgressSystems["📊 Системи прогресу"]
        UC_Save["Зберегти прогрес"]
        UC_Develop["Розвивати персонажа"]
        UC_Upgrade["Покращувати корабель"]
    end

    Player --> UC_Pilot
    Player --> UC_Scan
    Player --> UC_Locate
    Player --> UC_Travel
    Player --> UC_ManageShip

    Player --> UC_Land
    Player --> UC_Explore
    Player --> UC_Collect
    Player --> UC_Complete
    Player --> UC_Escape
    Player --> UC_Return

    Player --> UC_Save
    Player --> UC_Develop
    Player --> UC_Upgrade

    UC_Scan -.->|extends| UC_Land
    UC_Land -.->|extends| UC_Explore
    UC_Explore -.->|includes| UC_Collect
    UC_Explore -.->|extends| UC_Complete
    UC_Explore -.->|extends| UC_Escape
    UC_Complete -.->|extends| UC_Return
    UC_Escape -.->|extends| UC_Return
    UC_Return -.->|extends| UC_Travel
    UC_Complete -.->|includes| UC_Develop
```

### Опис ключових Use Cases

| Use Case | Опис | Передумова |
|----------|------|------------|
| Сканувати поверхню | Виявлення нових локацій на планеті | Корабель на орбіті |
| Використовувати локатор | Пошук нових планет | Корабель на орбіті |
| Здійснити посадку | Приземлення на виявлену локацію | Локація виявлена |
| Досліджувати локацію | Пересування та взаємодія на поверхні | Корабель приземлився |
| Виконати головну ціль | Завершення основного завдання локації | Фізична присутність |
| Втекти з локації | Екстрене повернення без завершення | Небезпека або вибір |

---

## 11. ЗВ'ЯЗОК З GDD

Цей документ деталізує **Розділ 2 GDD** — «Персонаж гравця» та частково **Розділ 5** — «Космічний корабель» (щодо профілю та стану корабля).

| Тема | GDD | Цей документ |
|------|-----|--------------|
| Глобальні стани гравця | Розділ 2 | Розділ 2: LoggedOff / LoggedIn |
| Походження та роль | Розділ 2 | Розділ 3: Експедиція, початкові знання |
| Профіль гравця | Розділ 2 | Розділ 4: Повна схема профілю v4 |
| Інвентар | Розділ 2 | Розділ 5: Resources + Knowledge |
| Стан корабля (в профілі) | Розділ 5 | Розділ 4.4: shipState, модулі |
| Персональний комп'ютер | Розділ 5 | Розділ 9: CRT-інтерфейс, показники |
| Збереження прогресу | Розділ 2 | Розділ 7: DataStore, автозбереження |

---

## 12. ПОВ'ЯЗАНІ ДОКУМЕНТИ

| Документ | Опис |
|----------|------|
| [GDD.md](GDD.md) | Головний Game Design Document |
| [SPACESHIP.md](SPACESHIP.md) | Космічний корабель |
| [Planets/README.md](Planets/README.md) | Планетарна система |
| [PLANET_LOCATIONS.md](PLANET_LOCATIONS.md) | Система планетних локацій |

> Технічна реалізація (ProfileService, DataStore) описана в `Docs/TechDesign/TDD.md`

---

**Версія документа:** 1.5
**Дата:** 2026-02-07

**Changelog:**
- 1.5: Актуалізовано профіль до v4 (історія міграцій); додано розділ 9 (Персональний комп'ютер — CRT-інтерфейс, 4 інформаційні блоки); оновлено статистику (stats об'єкт, авто-інкремент); деталізовано збереження (DataStore, retry, fallback); виправлено нумерацію підрозділів 3.x; оновлено зв'язок з GDD (таблиця відповідностей); перенумеровано розділи 10-12
- 1.4: Додано секцію 2 (Глобальні стани), секцію 9 (UseCase), journey діаграму; перенумеровано розділи
- 1.3: Додано ER діаграму для зв'язків між ігровими сутностями
- 1.2: Видалено технічну реалізацію (ProfileService API, DataStore) — фокус на Game Design
- 1.1: Додано Mermaid діаграми (Profile schema, Knowledge progression)
- 1.0: Початкова версія документа
