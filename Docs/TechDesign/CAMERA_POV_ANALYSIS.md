# Camera Point of View (PoV) Analysis
**Project:** Call of Relics: Orbital Silence
**Document Type:** Technical Analysis

---

## Проблема

Коли гравець на орбіті сідає в крісло, камера стрибає в неправильну позицію (десь до середини корабля), замість того щоб залишатися за гравцем з видом на планету через лобове скло.

---

## Всі місця встановлення PoV

### 1. **CameraController.client.lua** (StarterPlayerScripts/Core)

**Файл:** `StarterPlayer/StarterPlayerScripts/Core/CameraController.client.lua`
**Версія:** 0.1
**Призначення:** Базова камера для сидінь

#### SetupVehicleCamera(seat)
```lua
camera.CameraType = Enum.CameraType.Custom
camera.FieldOfView = cameraSettings.fov or 70
camera.CameraSubject = humanoid
```

**Проблема:**
- Встановлює `CameraSubject = humanoid`
- НЕ встановлює `camera.CFrame`
- Roblox автоматично визначає позицію камери для VehicleSeat
- Для орбіти це призводить до камери в центрі корабля

**Тригер:** `Humanoid.Seated` event

---

### 2. **TransitionUI.lua** — ShowArrivalAnimation()

**Файл:** `StarterPlayer/StarterPlayerScripts/UI/TransitionUI.lua:703`
**Версія:** 0.15
**Призначення:** Анімація прибуття корабля на орбіту

#### Під час анімації (Scriptable camera)
```lua
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 70

-- Track player position during arrival
local offset = Vector3.new(3, 3.5, 0)
local lookAtPoint = playerPos + Vector3.new(0, 1.5, -10)
camera.CFrame = CFrame.new(playerPos + offset, lookAtPoint)
```

**Коментар:** PoV 3.5 studs up (raised for better view)

#### Після анімації (TransitionUI.Hide)
```lua
-- If player is seated (orbit arrival)
if isSitting then
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
    -- NO camera.CFrame set!
end
```

**Проблема:**
- Передає контроль Roblox без встановлення CFrame
- CameraController потім встановлює CameraSubject = humanoid
- Камера стрибає в дефолтну позицію для VehicleSeat

---

### 3. **TransitionUI.lua** — ShowLandingPhase2()

**Файл:** `StarterPlayer/StarterPlayerScripts/UI/TransitionUI.lua:585`
**Призначення:** Посадка (Phase 2 - cockpit view)

```lua
camera.CameraType = Enum.CameraType.Scriptable
-- Cockpit PoV: 2 studs back, 4 studs up (closer and higher)
local offset = Vector3.new(0, 4, 2)
local lookAtPoint = playerPos + humanoidRootPart.CFrame.LookVector * 20
camera.CFrame = CFrame.new(playerPos + offset, lookAtPoint)
```

#### Після посадки (TransitionUI.Hide)
```lua
-- Player is standing (landing) - smooth transition
local offset = Vector3.new(0, 2, 8)
local lookAtPoint = rootPart.Position + Vector3.new(0, 2, 0)
local targetCFrame = CFrame.new(rootPart.Position + offset, lookAtPoint)

-- Tween camera to behind-player position
local tween = TweenService:Create(camera, TweenInfo.new(1.0, Enum.EasingStyle.Quad))
tween:Play()

camera.CameraType = Enum.CameraType.Custom
camera.CameraSubject = humanoid
```

**Різниця:** Для посадки є плавний tween до позиції за гравцем

---

### 4. **TransitionUI.lua** — ShowLaunchPhase1()

**Файл:** `StarterPlayer/StarterPlayerScripts/UI/TransitionUI.lua:632`
**Призначення:** Зліт (Phase 1 - cockpit view)

```lua
camera.CameraType = Enum.CameraType.Scriptable
-- Raised PoV: 3.5 studs up (was 2.5)
local offset = Vector3.new(3, 3.5, 0)
local lookAtPoint = playerPos + Vector3.new(0, 0, -30)
camera.CFrame = CFrame.new(playerPos + offset, lookAtPoint)
```

---

## Рішення

### Варіант 1: Встановити CFrame після Arrival

У `TransitionUI.Hide()` для випадку `isSitting`:

```lua
if isSitting then
    -- Smooth transition to orbit cockpit view
    local character = LocalPlayer.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

    if humanoidRootPart then
        -- Same offset as during arrival animation
        local playerPos = humanoidRootPart.Position
        local offset = Vector3.new(3, 3.5, 0) -- 3 back, 3.5 up
        local lookAtPoint = playerPos + Vector3.new(0, 1.5, -10) -- Look forward

        local targetCFrame = CFrame.new(playerPos + offset, lookAtPoint)

        -- Tween to target position
        local tween = TweenService:Create(
            camera,
            TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {CFrame = targetCFrame}
        )
        tween:Play()
        tween.Completed:Wait()
    end

    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
end
```

### Варіант 2: Створити CameraAttachment в PilotSeat

Додати `Attachment` до PilotSeat з назвою "CameraAttachment":
- Position: (0, 3.5, 3) відносно сидіння
- CameraController встановлює `camera.CameraSubject = attachment`

### Варіант 3: Використовувати CameraOffset в Humanoid

```lua
humanoid.CameraOffset = Vector3.new(3, 3.5, 0)
```

**Рекомендація:** Варіант 1 (встановити CFrame з tween)

---

## Всі PoV точки (зведена таблиця)

| Ситуація | Offset | LookAt | Коментар |
|----------|--------|--------|----------|
| **Arrival (orbit)** | (3, 3.5, 0) | +10 forward | Raised PoV during animation |
| **Arrival → Seated** | ❌ NOT SET | ❌ NOT SET | **ПРОБЛЕМА** |
| **Landing Phase 2** | (0, 4, 2) | +20 forward | Cockpit view descending |
| **Landing → Standing** | (0, 2, 8) | +2 up | Smooth tween (1s) |
| **Launch Phase 1** | (3, 3.5, 0) | -30 forward | Same as Arrival |
| **GameStart** | (3, 3.5, 0) | -10 forward | Initial cockpit |

---

## Рекомендації

1. **Виправити TransitionUI.Hide()** для випадку `isSitting`
2. Додати tween до правильної позиції (як для landing)
3. Використовувати той самий offset що й під час Arrival: `(3, 3.5, 0)`
4. LookAt: `playerPos + Vector3.new(0, 1.5, -10)` (вперед на планету)

---

**Версія документа:** 1.0
**Дата:** 2026-01-22
