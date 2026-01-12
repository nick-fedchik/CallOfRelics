# Phase 2 & 3 Implementation Plan - ScreenSaverUI-dev.lua

**Статус**: Phase 1 (Server) ✅ ЗАВЕРШЕНО та запушено до GitHub
**Поточний файл**: `ScreenSaverUI-dev.lua` (dev копія для безпечного розвитку)
**Основний файл**: `ScreenSaverUI.lua` (не чіпати до завершення тестування)

---

## Phase 2: UI Creation (45 хв)

### 2.1: CreateProgressBarElements() ✅ ГОТОВО
- **Рядки**: Після рядка 211 (після CreateStage2Elements)
- **Розмір**: 1200px × 60px (втричі ширший за оригінал)
- **Позиція**: Bottom center (0.85 від верху)
- **Елементи**: container, progressBg, progressFill, percentLabel (0-100%)

### 2.2: Оновити CreateStage3Elements()
**Поточні рядки**: 214-293 (spinner + text + progress bar)
**ВИДАЛИТИ**:
- SpinnerFrame (рядки 222-251) - всі 4 dot елементи
- Старий progress bar (рядки 268-288) - переміщено в CreateProgressBarElements

**ЗАЛИШИТИ**:
- LoadingContainer (простіший - тільки текст)
- LoadingText ("Ініціалізація експедиції..." / "Відновлення експедиції...")

**Новий розмір**: ~80 рядків → ~30 рядків

### 2.3: CreateErrorStateElements() - НОВИЙ
- **Рядки**: Після CreateStage3Elements
- **Розмір**: 800px × 250px (центр екрану)
- **Елементи**:
  - Error container (темно-червоний фон)
  - Error icon "⚠" (64px)
  - Error text (wrapping, змінний текст з сервера)
  - Retry button "Спробувати знову" (250px × 50px)
  - Hover effects для кнопки

### 2.4: Оновити CreateStage4Elements()
**Поточні рядки**: 299-371
**ВИДАЛИТИ**:
- ReadyText "Готовність 100%" (рядки 300-314)

**ЗАЛИШИТИ**:
- StartButton "Почати гру" (збільшити до 350px × 70px)
- Перемістити button в центр (0.7 від верху)

**Новий розмір**: ~72 рядки → ~50 рядків

### 2.5: Оновити CreateScreenSaverUI()
**Поточні рядки**: 377-395

**ЗМІНИТИ виклики**:
```lua
-- Було:
loadingContainer, loadingSpinner, loadingText, progressBarBg, progressBarFill = CreateStage3Elements(mainContainer)
readyText, startButton = CreateStage4Elements(mainContainer)

-- Стане:
progressBarContainer, progressBarBg, progressBarFill, progressPercentLabel = CreateProgressBarElements(mainContainer)
loadingContainer, loadingText = CreateStage3Elements(mainContainer)
errorContainer, errorText, retryButton = CreateErrorStateElements(mainContainer)
startButton = CreateStage4Elements(mainContainer)
```

**ДОДАТИ wire-up** для retry button:
```lua
retryButton.MouseButton1Click:Connect(function()
	errorContainer.Visible = false
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	local retryBootStage = remoteEvents:WaitForChild("RetryBootStage")
	retryBootStage:FireServer(3) -- Retry Stage 3
end)
```

---

## Phase 3: Stage Handlers (30 хв)

### 3.1: Додати Progress Helper Functions
**Місце**: Після FadeOut (після рядка 425)

**Функції**:
```lua
local function UpdateProgressBar(progressPercent, duration)
local function ShowProgressBar()
local function HideProgressBar()
```

### 3.2: Оновити ShowStage1()
**Поточні рядки**: 431-445

**ДОДАТИ** в кінець:
```lua
-- Show progress bar
ShowProgressBar()
if stageData and stageData.progress then
	UpdateProgressBar(stageData.progress, 1.0)
end
```

### 3.3: Оновити ShowStage2()
**Поточні рядки**: 447-480

**ДОДАТИ** в кінець (після рядка 479):
```lua
-- Update progress bar
if stageData and stageData.progress then
	UpdateProgressBar(stageData.progress, 1.0)
end
```

### 3.4: Оновити ShowStage3()
**Поточні рядки**: 482-531

**ПОВНІСТЮ ПЕРЕПИСАТИ**:
- Перевірити `stageData.success`
- Якщо `false`: показати errorContainer з errorMessage
- Якщо `true`: показати loadingText + оновити progress
- **ВИДАЛИТИ**: всю логіку spinner rotation (рядки 514-518)
- **ВИДАЛИТИ**: стару анімацію progress bar (рядки 520-530)

### 3.5: Оновити ShowStage4()
**Поточні рядки**: 533-555

**ЗМІНИТИ логіку**:
```lua
1. UpdateProgressBar(100%, 1.0s)
2. FadeOut loadingText (0.4s)
3. Hide loadingContainer
4. ⏱️ task.wait(1.0) -- КРИТИЧНО: 1 секунда паузи
5. HideProgressBar()
6. task.wait(0.5)
7. FadeIn startButton (БЕЗ readyText)
8. canInteract = true
```

### 3.6: Оновити Reset()
**Поточні рядки**: 602-624

**ДОДАТИ скидання**:
- progressBarBg/progressBarFill transparency = 1
- progressBarFill.Size = 0%
- progressPercentLabel = "0%"
- errorContainer.Visible = false

### 3.7: Оновити ShowStage()
**Поточні рядки**: 626-640

**ДОДАТИ логування**:
```lua
if stageData and stageData.progress then
	print(string.format("[ShowStage] Progress: %d%% (Stage %d/%d)",
		stageData.progress, stageData.stageNumber, stageData.totalStages))
end
```

**ЗМІНИТИ виклик**:
```lua
-- Було:
ShowStage4()

-- Стане:
ShowStage4(stageData)
```

---

## Verification Checklist

### UI Elements Created:
- [ ] Progress bar 1200px wide з process label
- [ ] Error container з retry button
- [ ] Stage 3 без spinner (тільки текст)
- [ ] Stage 4 без "Готовність 100%"

### Functionality:
- [ ] Progress bar з'являється на Stage 1
- [ ] Progress оновлюється: 25% → 50% → 75% → 100%
- [ ] Error state відображається коректно
- [ ] Retry button працює
- [ ] 1 секунда паузи після 100%
- [ ] Текст "Ініціалізація..." залишився

### Code Quality:
- [ ] Видалено всі reference на loadingSpinner
- [ ] Видалено всі reference на readyText
- [ ] Видалено всі reference на старий progressBar в Stage 3
- [ ] Оновлено всі function signatures

---

## Estimated Lines of Code Changes

| Section | Before | After | Change |
|---------|--------|-------|--------|
| State variables | 15 | 20 | +5 |
| CreateStage3 | 80 | 30 | -50 |
| CreateProgressBar | 0 | 60 | +60 |
| CreateErrorState | 0 | 80 | +80 |
| CreateStage4 | 72 | 50 | -22 |
| Progress helpers | 0 | 30 | +30 |
| ShowStage3 | 50 | 30 | -20 |
| ShowStage4 | 23 | 30 | +7 |
| Reset | 23 | 30 | +7 |
| **TOTAL** | **~21KB** | **~23KB** | **+2KB** |

---

## Testing Strategy

### Local Testing (before moving to main file):
1. Змінити ClientBootstrap.client.lua:
   ```lua
   -- Тимчасово використовувати dev версію
   local ScreenSaverUI = require(UI:WaitForChild("ScreenSaverUI-dev"))
   ```

2. Запустити гру в Roblox Studio
3. Перевірити нормальний boot sequence
4. Симулювати помилку Stage 3
5. Перевірити retry механізм

### After Testing:
1. Якщо все працює → перенести зміни в ScreenSaverUI.lua
2. Видалити ScreenSaverUI-dev.lua
3. Коміт і push

---

## Critical Warnings

⚠️ **НЕ ЧІПАТИ** ScreenSaverUI.lua до завершення Phase 2 & 3
⚠️ **ПРАЦЮВАТИ ТІЛЬКИ** з ScreenSaverUI-dev.lua
⚠️ **ТЕСТУВАТИ** перед переносом в основний файл
⚠️ **ЗБЕРІГАТИ** ScreenSaverUI_OLD.lua як fallback

---

## Next Session Commands

```bash
# Відновити роботу:
cd "d:\Code\Roblox\CallOfRelics"
git status
git pull

# Почати Phase 2:
code "StarterPlayer/StarterPlayerScripts/UI/ScreenSaverUI-dev.lua"

# Після завершення Phase 2 & 3:
git add StarterPlayer/StarterPlayerScripts/UI/ScreenSaverUI-dev.lua
git commit -m "Phase 2 & 3: Client UI implementation (dev version)"
git push

# Після успішного тестування:
mv ScreenSaverUI-dev.lua ScreenSaverUI.lua
git add ScreenSaverUI.lua
git commit -m "Merge ScreenSaverUI-dev into main file"
git push
```

---

**Created**: 2026-01-12
**Status**: Ready for Phase 2 implementation
**Current Commit**: d10baab (Phase 1 completed)
