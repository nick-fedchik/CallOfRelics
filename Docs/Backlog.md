# Backlog.md
**Project:** Call of Relics: Orbital Silence

**Type:** Single-player Exploration RPG (Roblox)

**Backlog Version:** 0.7

**Status:** Active Development

**Current Game Version:** 0.12

---

## 1. ROADMAP

### Phase 0 — Foundations ✅ COMPLETE
### Phase 1 — Core Gameplay Loop ⏳ IN PROGRESS
> Орбіта → Локація → Повернення → Прогрес

**В роботі:**
- Gameplay локацій (EPIC 7)

### Phase 2 — Progression & Persistence ✅ COMPLETE
### Phase 3 — Expansion & Variety
- Нові типи локацій
- Нові планети
- Наративні розгалуження

### Phase 4 — Polishing & Release
- Баланс
- UI/UX polish
- Оптимізація

---

## 2. ACTIVE EPICS

### EPIC 7 — Location Gameplay (Arcades) 🆕 0/4

**Опис:** Локації як окремі ігрові аркади.

**Stories:**
- [ ] Each location has a primary goal
- [ ] Locations may have optional objectives
- [ ] Player can fail exploration
- [ ] Failure has consequences but preserves knowledge

---

### EPIC 11 — Engines System ⏳ 1/5

**Опис:** Керування двигунами корабля через "Seat Engines".

**Stories:**
- [x] Engine Fire effects toggle on landing/launch (visual feedback) — v0.11
- [ ] EnginesUI displays ship engine status
- [ ] Player can monitor fuel/energy levels
- [ ] Player can adjust engine power distribution
- [ ] Engine state affects ship capabilities (speed, maneuverability)

---

### EPIC 12 — Planet Locator System 🆕 0/4

**Опис:** Планетний локатор для виявлення та навігації до нових планет.

**Stories:**
- [ ] PlanetLocatorUI displays known planets
- [ ] Player can scan for undiscovered planets
- [ ] Player can set navigation target
- [ ] Discovered planets saved to ProfileService

---

### EPIC 13 — Personal Computer System 🆕 0/4

**Опис:** Персональний комп'ютер для доступу до інвентарю та бази знань.

**Stories:**
- [ ] PersonalComputerUI displays inventory (resources)
- [ ] PersonalComputerUI displays knowledge base
- [ ] Player can view collected resources
- [ ] Player can browse discovered knowledge entries

---

### EPIC 14 — Cockpit Displays 🆕 0/4

**Опис:** Великі дисплеї біля крісла пілота для відображення станів обладнання корабля.

**Stories:**
- [ ] Left display shows ship systems status (energy, shields, hull)
- [ ] Right display shows navigation/scanning info
- [ ] Displays update in real-time based on ship state
- [ ] Visual alerts on critical system warnings

---

### EPIC 9 — UI & UX ⏳ 3/4

**Незакриті Stories:**
- [ ] UI explains restrictions to player (tooltips, disabled states)

---

### EPIC 3 — SpaceShip System ⏳ (залишок)

**Незакриті Stories:**
- [ ] PilotSeat: Navigation system functional
- [ ] PilotSeat: Weapons control system (TBD)
- [ ] All seat UIs show proper content (not "NOT WORKING")

---

## 3. COMPLETED EPICS (Archive)

| EPIC | Version | Description |
|------|---------|-------------|
| EPIC 1 | v0.5 | Game Boot & Global States |
| EPIC 2 | v0.5 | Game State Architecture |
| EPIC 3 | v0.9 | SpaceShip System (base) |
| EPIC 3.1 | v0.11 | Ramp System |
| EPIC 3.2 | v0.12 | Ramp Visual Effects (stripes pulsation) |
| EPIC 4 | v0.9 | Planet & Location System |
| EPIC 5 | v0.10 | Surface Scanner System |
| EPIC 6 | v0.8.2 | Teleportation (covered by TransitionService) |
| EPIC 8 | v0.8 | Progression & Persistence |
| EPIC 10 | v0.8.2 | Diagnostics & Logging |

---

## 4. NEXT SPRINT

### Sprint 6 — Location Gameplay (EPIC 7)

**Goal:** Локації мають геймплей.

**Stories:**
- [ ] Define primary goal for Location_1 (tutorial)
- [ ] Define primary goal for Location_2 (exploration)
- [ ] Implement goal completion tracking
- [ ] Add failure/success outcomes

---

## 5. МОЖЛИВІ ПОДАЛЬШІ КРОКИ

### Короткострокові (Sprint 6-7)

1. **Location Gameplay (EPIC 7)** — найвищий пріоритет
   - Визначити мету для Location_1 (туторіал: збір першого ресурсу)
   - Визначити мету для Location_2 (дослідження: знайти артефакт)
   - Система відстеження прогресу локації
   - Умови успіху/провалу

2. **Resource Collection System**
   - Pickable об'єкти на локаціях
   - Додавання ресурсів до інвентарю (ProfileService)
   - Візуальний feedback при зборі

3. **Knowledge Discovery System**
   - Scannable об'єкти (записки, термінали, артефакти)
   - Додавання записів до бази знань
   - UI для перегляду знайдених записів

### Середньострокові (Sprint 8-10)

4. **Personal Computer UI (EPIC 13)**
   - Інвентар: відображення зібраних ресурсів
   - База знань: перегляд відкритих записів
   - Статистика гравця

5. **Engines UI (EPIC 11)**
   - Моніторинг стану двигунів
   - Енергетичний баланс корабля
   - Вплив на швидкість/маневреність

6. **Planet Locator (EPIC 12)**
   - Сканування космосу на нові планети
   - Навігація між планетами
   - Друга планета (контент)

### Довгострокові (Phase 3+)

7. **Друга планета**
   - Нова планета з унікальними локаціями
   - Міжпланетний переліт (енергозатрати)
   - Нові типи ресурсів/знань

8. **Система апгрейдів корабля**
   - Покращення модулів (сканер, двигуни)
   - Нові моделі корабля (SpaceShip_Advanced)
   - Крафтинг з ресурсів

9. **Наративна система**
   - Квестова лінія
   - Діалоги/записки
   - Фінал гри (повернення на Землю)

---

## NOTES

- Backlog є **живим документом**
- Пріоритет — **стабільність ядра**
- Контент додається після стабілізації систем
