# Development Workflow
**Project:** Call of Relics: Orbital Silence
**Version:** 1.0
**Date:** 2026-01-24

---

## Інструменти розробки

| Інструмент | Призначення |
|------------|-------------|
| **Roblox Studio** | Редагування моделей, властивостей, тестування |
| **Script Sync** | Синхронізація .lua файлів ↔ локальна файлова система |
| **Claude Desktop + MCP** | AI-асистент з доступом до Studio через Roblox MCP |
| **Git + GitHub** | Версіонування коду та документації |

---

## Що синхронізується

### ✅ Script Sync (автоматично):
- `.lua` / `.luau` файли (скрипти, ModuleScripts)
- Зміни в коді

### ❌ НЕ синхронізується через Script Sync:
- Позиції, розміри, CFrame частин
- Атрибути моделей (Attributes)
- Властивості (Color, Material, Transparency)
- Структура ієрархії (Parent/Children)
- Lighting, Terrain, Effects

---

## Workflow: Зміни в моделях/геометрії

Коли змінюються властивості об'єктів (не код):

### 1. Зафіксувати зміни в документації

Оновити відповідний Config.luau або створити запис:

```lua
-- ServerStorage/Planets/Planet_1/Surface/Location_1/Config.luau
return {
    zones = {
        LandingZone = {
            size = Vector3.new(1024, 1, 260),
            position = Vector3.new(512, 1.5, 894),
        },
        ExplorationZone = {
            size = Vector3.new(1024, 1, 764),
            position = Vector3.new(512, 1.5, 382),
        },
        SpaceShipLandingPad = {
            size = Vector3.new(130, 0.5, 242),
            position = Vector3.new(512, 2, 894),
        },
    },
}
```

### 2. Зберегти проект в Studio
- File → Save (Ctrl+S)
- Це зберігає .rbxl/.rbxlx файл

### 3. Оновити CHANGELOG.md
```markdown
## [0.17.0] - 2026-01-24 - Zone Geometry Fix

### Fixed - Location_1 Zone Geometry
- **LandingZone** — збільшено для SpaceShip (260 studs depth)
- **ExplorationZone** — зменшено відповідно (764 studs depth)  
- **SpaceShipLandingPad** — центровано в LandingZone (130x242 studs)
- Зони більше не перетинаються
```

### 4. Git commit
```bash
git add .
git commit -m "Fix Location_1 zone geometry for SpaceShip landing"
git push
```

---

## Workflow: Зміни в коді

### 1. Редагувати в VSCode/IDE
Script Sync автоматично синхронізує з Studio

### 2. Тестувати в Studio
Play → Test → Fix

### 3. Оновити версію модуля
```lua
-- У заголовку скрипта
-- Version: 0.5 → 0.6
```

### 4. Оновити CHANGELOG.md

### 5. Git commit + push

---

## Workflow: Сесія з Claude MCP

### Початок сесії:
1. Відкрити Roblox Studio з проектом
2. Переконатися що MCP плагін активний ("MCP Studio plugin is ready")
3. Відкрити Claude Desktop

### Під час сесії:
- Claude може читати/змінювати об'єкти в Studio через `run_code`
- Claude може читати/змінювати код через Desktop Commander
- Зміни в Studio **не автоматичні** — потрібно підтвердити

### Завершення сесії:
1. Зберегти проект в Studio (Ctrl+S)
2. Оновити CHANGELOG.md
3. Git commit + push

---

## Контрольний список перед commit

- [ ] Код працює (протестовано в Studio)
- [ ] Версії модулів оновлені
- [ ] CHANGELOG.md оновлено
- [ ] Документація актуальна (якщо змінилась архітектура)
- [ ] Проект збережено в Studio

---

## GitHub Workflow

### Branches:
- `main` — стабільна версія
- `feature/*` — нові фічі
- `fix/*` — виправлення

### Commit message format:
```
<type>: <short description>

<optional body>
```

Types:
- `feat:` — нова функціональність
- `fix:` — виправлення багу
- `docs:` — документація
- `refactor:` — рефакторинг без зміни функціональності
- `style:` — форматування, відступи
- `chore:` — технічні зміни (залежності, конфіг)

---

**Версія документа:** 1.0
**Дата:** 2026-01-24
