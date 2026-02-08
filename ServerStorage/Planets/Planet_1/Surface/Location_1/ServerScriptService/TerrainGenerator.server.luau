--[[
================================================================================
KOSMICMAZER — LocationGenerator (Location_1)
================================================================================

Purpose:
Procedural content generation for Location_1 "Візитка" surface.
Generates terrain, bare patches, alien temple with doors, and fractal trees.

Version:
0.4

Features:
- FBM noise terrain with gentle hills (6x lower than v0.1)
- Random bare patches (4-24 clearings without grass)
- Futuristic temple building (alien orthodox church style, 4x footprint, 2x height)
- Proximity-triggered sliding doors on both entrances
- Fractal trees with cylindrical trunks/branches, turquoise-agate leaves
- Random tree height variation
- Deterministic seed-based generation
- Building exclusion zones for terrain and trees
- Clear entrance paths to building
- Periodic vertical lightning bolt from central capacitor into sky

Dependencies:
- FastNoise (ReplicatedStorage/Game/FastNoise)
- Workspace.Terrain
- TweenService (door animations)
- Players (door proximity detection)

ChangeLog:
- 0.4: Vertical lightning bolt from central spire (2026-02-08)
- 0.3: 4x building, doors, cylindrical trees, turquoise leaves, lower grass (2026-02-06)
- 0.2: Bare patches, alien temple, fractal trees, lower terrain (2026-02-06)
- 0.1: Initial procedural terrain with FBM noise (2026-02-06)
================================================================================
]]

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local SEED = 42
local MODULE_NAME = "LocationGenerator"
local VERSION = "0.4"

-- Terrain
local FREQUENCY = 0.008
local MAX_HEIGHT = 0.5           -- Subtle grass texture only
local MIN_HEIGHT = 0.05
local GRID_STEP = 4
local OCTAVES = 4
local LACUNARITY = 2.0
local PERSISTENCE = 0.5

-- Zone bounds
local ZONE_MIN_X = 260
local ZONE_MAX_X = 1024
local ZONE_MIN_Z = 0
local ZONE_MAX_Z = 1024
local BASE_Y = 1
local GROUND_Y = 2               -- Top surface of ground parts
local FADE_WIDTH = 40

-- Bare patches
local BARE_PATCHES_MIN = 4
local BARE_PATCHES_MAX = 24
local BARE_PATCH_RADIUS_MIN = 8
local BARE_PATCH_RADIUS_MAX = 25

-- Building (center ~30% of ExplorationZone)
local BUILDING_ZONE_MIN_X = 433
local BUILDING_ZONE_MAX_X = 851
local BUILDING_ZONE_MIN_Z = 232
local BUILDING_ZONE_MAX_Z = 792
local BUILDING_W = 160           -- Was 40, 4x wider
local BUILDING_D = 120           -- Was 30, 4x deeper
local BUILDING_CLEARANCE = 20    -- Terrain exclusion around building

-- Trees
local TREES_MIN = 20
local TREES_MAX = 80
local TREE_MIN_SPACING = 12
local TREE_BUILDING_MARGIN = 25
local TREE_ENTRANCE_LENGTH = 40
local TREE_ENTRANCE_WIDTH = 14
local TREE_BRANCH_DEPTH = 2

-- ============================================================================
-- SERVICES
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

task.wait(1)

local FastNoise = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("FastNoise"))
local terrain = Workspace.Terrain
local rng = Random.new(SEED)

local proceduralFolder = Instance.new("Folder")
proceduralFolder.Name = "ProceduralContent"
proceduralFolder.Parent = Workspace

local fbm = FastNoise.FBM.create({
	octaves = OCTAVES,
	lacunarity = LACUNARITY,
	persistence = PERSISTENCE,
})

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function IsInsideCircle(x, z, cx, cz, radius)
	return (x - cx) ^ 2 + (z - cz) ^ 2 <= radius ^ 2
end

local function IsInsideRect(x, z, minX, minZ, maxX, maxZ)
	return x >= minX and x <= maxX and z >= minZ and z <= maxZ
end

local function RotateVector(vec, axis, angle)
	return CFrame.fromAxisAngle(axis.Unit, angle):VectorToWorldSpace(vec)
end

local function GetPerpendicular(vec)
	local up = Vector3.new(0, 1, 0)
	if math.abs(vec:Dot(up)) > 0.999 then
		up = Vector3.new(1, 0, 0)
	end
	return vec:Cross(up).Unit
end

-- Align Part's X axis along direction (for Cylinder shape)
local function AlignCylinderAxis(midPos, direction)
	local xAxis = direction.Unit
	local worldUp = Vector3.new(0, 1, 0)
	if math.abs(xAxis:Dot(worldUp)) > 0.999 then
		worldUp = Vector3.new(1, 0, 0)
	end
	local zAxis = xAxis:Cross(worldUp).Unit
	local yAxis = zAxis:Cross(xAxis).Unit
	return CFrame.fromMatrix(midPos, xAxis, yAxis)
end

-- ============================================================================
-- STEP 1: BARE PATCHES
-- ============================================================================

local barePatches = {}

local function GenerateBarePatches()
	local count = rng:NextInteger(BARE_PATCHES_MIN, BARE_PATCHES_MAX)
	for _ = 1, count do
		local cx = rng:NextNumber(ZONE_MIN_X + 60, ZONE_MAX_X - 20)
		local cz = rng:NextNumber(ZONE_MIN_Z + 20, ZONE_MAX_Z - 20)
		local radius = rng:NextNumber(BARE_PATCH_RADIUS_MIN, BARE_PATCH_RADIUS_MAX)
		table.insert(barePatches, { x = cx, z = cz, radius = radius })
	end
	print(string.format("[%s] Generated %d bare patches", MODULE_NAME, count))
end

-- ============================================================================
-- STEP 2: BUILDING POSITION
-- ============================================================================

local buildingCenter = nil

local function PickBuildingPosition()
	local bx = rng:NextNumber(BUILDING_ZONE_MIN_X + BUILDING_W / 2, BUILDING_ZONE_MAX_X - BUILDING_W / 2)
	local bz = rng:NextNumber(BUILDING_ZONE_MIN_Z + BUILDING_D / 2, BUILDING_ZONE_MAX_Z - BUILDING_D / 2)
	buildingCenter = { x = bx, z = bz }
	print(string.format("[%s] Building position: (%.0f, %.0f)", MODULE_NAME, bx, bz))
end

-- ============================================================================
-- STEP 3: TERRAIN GENERATION
-- ============================================================================

local function IsInBuildingZone(x, z)
	if not buildingCenter then return false end
	local hw = BUILDING_W / 2 + BUILDING_CLEARANCE
	local hd = BUILDING_D / 2 + BUILDING_CLEARANCE
	return IsInsideRect(x, z,
		buildingCenter.x - hw, buildingCenter.z - hd,
		buildingCenter.x + hw, buildingCenter.z + hd)
end

local function IsInBarePatch(x, z)
	for _, patch in ipairs(barePatches) do
		if IsInsideCircle(x, z, patch.x, patch.z, patch.radius) then
			return true
		end
	end
	return false
end

local function GenerateTerrain()
	local startTime = os.clock()
	local blocksGenerated = 0

	terrain:FillRegion(
		Region3.new(
			Vector3.new(ZONE_MIN_X, BASE_Y, ZONE_MIN_Z),
			Vector3.new(ZONE_MAX_X, BASE_Y + MAX_HEIGHT + 10, ZONE_MAX_Z)
		):ExpandToGrid(4),
		4,
		Enum.Material.Air
	)

	for x = ZONE_MIN_X, ZONE_MAX_X - GRID_STEP, GRID_STEP do
		for z = ZONE_MIN_Z, ZONE_MAX_Z - GRID_STEP, GRID_STEP do
			if IsInBuildingZone(x, z) then continue end
			if IsInBarePatch(x, z) then continue end

			local noiseValue = fbm.noise2D(x * FREQUENCY, z * FREQUENCY, SEED)
			local normalized = FastNoise.normalize(noiseValue)
			local height = MIN_HEIGHT + normalized * MAX_HEIGHT

			local distFromBorder = x - ZONE_MIN_X
			if distFromBorder < FADE_WIDTH then
				height = height * (distFromBorder / FADE_WIDTH)
			end

			if height > 0.3 then
				terrain:FillBlock(
					CFrame.new(x + GRID_STEP / 2, BASE_Y + height / 2, z + GRID_STEP / 2),
					Vector3.new(GRID_STEP, height, GRID_STEP),
					Enum.Material.Grass
				)
				blocksGenerated += 1
			end
		end

		if x % 32 == 0 then
			task.wait()
		end
	end

	print(string.format("[%s] Terrain: %d blocks in %.2fs", MODULE_NAME, blocksGenerated, os.clock() - startTime))
end

-- ============================================================================
-- STEP 4: BUILDING — Futuristic Alien Temple (4x footprint, 2x height)
-- ============================================================================

local function CreateBuilding()
	if not buildingCenter then return nil, nil end

	local building = Instance.new("Model")
	building.Name = "AncientTemple"

	local cx = buildingCenter.x
	local cz = buildingCenter.z
	local floorY = GROUND_Y

	-- Dimensions (4x horizontal, 2x vertical from v0.2; entrances unchanged)
	local W = BUILDING_W       -- 160
	local D = BUILDING_D       -- 120
	local WH = 32              -- Wall height (was 16)
	local WT = 4               -- Wall thickness
	local DOOR_W = 8           -- Door width (unchanged)
	local DOOR_H = 12          -- Door height (unchanged)
	local WIN_W = 6            -- Window width
	local WIN_H = 12           -- Window height
	local NUM_WIN = 4          -- Windows per side wall
	local halfW = W / 2        -- 80
	local halfD = D / 2        -- 60
	local innerW = W - 2 * WT  -- 152

	-- Colors
	local C_WALL = Color3.fromRGB(175, 175, 185)
	local C_DOME = Color3.fromRGB(195, 165, 55)
	local C_NEON = Color3.fromRGB(240, 200, 80)
	local C_FLOOR = Color3.fromRGB(55, 60, 70)
	local C_GLASS = Color3.fromRGB(20, 160, 200)
	local C_PILLAR = Color3.fromRGB(150, 150, 165)
	local C_TOWER = Color3.fromRGB(165, 165, 175)
	local C_DOOR = Color3.fromRGB(110, 120, 135)

	local function MP(name, size, position, color, material, transparency)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = position
		p.Anchored = true
		p.Color = color or C_WALL
		p.Material = material or Enum.Material.SmoothPlastic
		p.Transparency = transparency or 0
		p.Parent = building
		return p
	end

	-- ======= FLOOR =======
	MP("Floor", Vector3.new(W, 1, D), Vector3.new(cx, floorY, cz), C_FLOOR)

	-- ======= FRONT WALL (X- face) with door =======
	local sideSegZ = (D - DOOR_W) / 2
	local wallCenterY = floorY + WH / 2 + 0.5
	local frontWallX = cx - halfW + WT / 2
	local backWallX = cx + halfW - WT / 2

	MP("FrontWall_L", Vector3.new(WT, WH, sideSegZ),
		Vector3.new(frontWallX, wallCenterY, cz - halfD + sideSegZ / 2), C_WALL)
	MP("FrontWall_R", Vector3.new(WT, WH, sideSegZ),
		Vector3.new(frontWallX, wallCenterY, cz + halfD - sideSegZ / 2), C_WALL)
	MP("FrontWall_Top", Vector3.new(WT, WH - DOOR_H, DOOR_W),
		Vector3.new(frontWallX, floorY + DOOR_H + (WH - DOOR_H) / 2 + 0.5, cz), C_WALL)

	-- ======= BACK WALL (X+ face) with door =======
	MP("BackWall_L", Vector3.new(WT, WH, sideSegZ),
		Vector3.new(backWallX, wallCenterY, cz - halfD + sideSegZ / 2), C_WALL)
	MP("BackWall_R", Vector3.new(WT, WH, sideSegZ),
		Vector3.new(backWallX, wallCenterY, cz + halfD - sideSegZ / 2), C_WALL)
	MP("BackWall_Top", Vector3.new(WT, WH - DOOR_H, DOOR_W),
		Vector3.new(backWallX, floorY + DOOR_H + (WH - DOOR_H) / 2 + 0.5, cz), C_WALL)

	-- ======= DOOR PANELS (slide open on proximity) =======
	local frontDoorL = MP("FrontDoor_L", Vector3.new(WT, DOOR_H, DOOR_W / 2),
		Vector3.new(frontWallX, floorY + DOOR_H / 2 + 0.5, cz - DOOR_W / 4), C_DOOR)
	local frontDoorR = MP("FrontDoor_R", Vector3.new(WT, DOOR_H, DOOR_W / 2),
		Vector3.new(frontWallX, floorY + DOOR_H / 2 + 0.5, cz + DOOR_W / 4), C_DOOR)
	local backDoorL = MP("BackDoor_L", Vector3.new(WT, DOOR_H, DOOR_W / 2),
		Vector3.new(backWallX, floorY + DOOR_H / 2 + 0.5, cz - DOOR_W / 4), C_DOOR)
	local backDoorR = MP("BackDoor_R", Vector3.new(WT, DOOR_H, DOOR_W / 2),
		Vector3.new(backWallX, floorY + DOOR_H / 2 + 0.5, cz + DOOR_W / 4), C_DOOR)

	-- ======= SIDE WALLS (Z- and Z+ faces) with windows =======
	local winSillY = floorY + 12 + 0.5
	local wallStartX = cx - innerW / 2
	local wallEndX = cx + innerW / 2
	local bottomH = winSillY - floorY - 0.5
	local topH = (floorY + WH + 0.5) - (winSillY + WIN_H)

	-- Window X positions (evenly spaced)
	local winSpacing = innerW / (NUM_WIN + 1)
	local winXPositions = {}
	for w = 1, NUM_WIN do
		table.insert(winXPositions, wallStartX + w * winSpacing)
	end

	for _, side in ipairs({
		{ z = cz - halfD + WT / 2, prefix = "Left" },
		{ z = cz + halfD - WT / 2, prefix = "Right" },
	}) do
		-- Full-width bottom strip (below windows)
		MP(side.prefix .. "Wall_Bottom", Vector3.new(innerW, bottomH, WT),
			Vector3.new(cx, floorY + bottomH / 2 + 0.5, side.z), C_WALL)
		-- Full-width top strip (above windows)
		MP(side.prefix .. "Wall_Top", Vector3.new(innerW, topH, WT),
			Vector3.new(cx, winSillY + WIN_H + topH / 2, side.z), C_WALL)
		-- Vertical segments between and around windows
		for s = 0, NUM_WIN do
			local segL = (s == 0) and wallStartX or (winXPositions[s] + WIN_W / 2)
			local segR = (s == NUM_WIN) and wallEndX or (winXPositions[s + 1] - WIN_W / 2)
			local segW = segR - segL
			if segW > 0.5 then
				MP(side.prefix .. "WallSeg_" .. s, Vector3.new(segW, WIN_H, WT),
					Vector3.new((segL + segR) / 2, winSillY + WIN_H / 2, side.z), C_WALL)
			end
		end
		-- Window glass panes
		for w, wx in ipairs(winXPositions) do
			MP(side.prefix .. "Win_" .. w, Vector3.new(WIN_W, WIN_H, 0.5),
				Vector3.new(wx, winSillY + WIN_H / 2, side.z), C_GLASS, Enum.Material.Glass, 0.4)
		end
	end

	-- ======= NEON TRIM (top edge of walls) =======
	local neonH = 0.5
	local wallTopY = floorY + WH + 0.5 + neonH / 2
	MP("NeonTrim_Front", Vector3.new(WT + 0.4, neonH, D + 0.4),
		Vector3.new(frontWallX, wallTopY, cz), C_NEON, Enum.Material.Neon)
	MP("NeonTrim_Back", Vector3.new(WT + 0.4, neonH, D + 0.4),
		Vector3.new(backWallX, wallTopY, cz), C_NEON, Enum.Material.Neon)
	MP("NeonTrim_Left", Vector3.new(innerW, neonH, WT + 0.4),
		Vector3.new(cx, wallTopY, cz - halfD + WT / 2), C_NEON, Enum.Material.Neon)
	MP("NeonTrim_Right", Vector3.new(innerW, neonH, WT + 0.4),
		Vector3.new(cx, wallTopY, cz + halfD - WT / 2), C_NEON, Enum.Material.Neon)

	-- ======= MAIN DOME =======
	local drumH = 8
	local drumDiam = 54

	local drumPart = Instance.new("Part")
	drumPart.Name = "DomeDrum"
	drumPart.Shape = Enum.PartType.Cylinder
	drumPart.Size = Vector3.new(drumH, drumDiam, drumDiam)
	drumPart.CFrame = CFrame.new(cx, floorY + WH + 0.5 + drumH / 2, cz) * CFrame.Angles(0, 0, math.rad(90))
	drumPart.Anchored = true
	drumPart.Color = C_WALL
	drumPart.Material = Enum.Material.SmoothPlastic
	drumPart.Parent = building

	-- Dome sphere (elongated onion shape) — OPAQUE
	local domeSizeXZ = 50
	local domeSizeY = 40
	local domeCenterY = floorY + WH + 0.5 + drumH + domeSizeY / 2

	local domePart = Instance.new("Part")
	domePart.Name = "MainDome"
	domePart.Shape = Enum.PartType.Ball
	domePart.Size = Vector3.new(domeSizeXZ, domeSizeY, domeSizeXZ)
	domePart.Position = Vector3.new(cx, domeCenterY, cz)
	domePart.Anchored = true
	domePart.Color = C_DOME
	domePart.Material = Enum.Material.Glass
	domePart.Transparency = 0
	domePart.Parent = building

	-- Dome spire — touches top of dome sphere
	local mainSpireH = 12
	local domeTopY = domeCenterY + domeSizeY / 2
	MP("DomeSpire", Vector3.new(1.5, mainSpireH, 1.5),
		Vector3.new(cx, domeTopY + mainSpireH / 2, cz), C_NEON, Enum.Material.Neon)

	-- ======= CAPACITOR SPHERES & ELECTRIC DISCHARGE =======
	local C_CAPACITOR = Color3.fromRGB(80, 180, 255)
	local dischargeBeams = {}

	-- Central capacitor sphere (electromagnetic energy concentrator)
	local centralCapSize = 6
	local centralCapY = domeTopY + mainSpireH + centralCapSize / 2
	local centralCap = Instance.new("Part")
	centralCap.Name = "CentralCapacitor"
	centralCap.Shape = Enum.PartType.Ball
	centralCap.Size = Vector3.new(centralCapSize, centralCapSize, centralCapSize)
	centralCap.Position = Vector3.new(cx, centralCapY, cz)
	centralCap.Anchored = true
	centralCap.CanCollide = false
	centralCap.Color = C_CAPACITOR
	centralCap.Material = Enum.Material.Neon
	centralCap.Parent = building

	local centralAttach = Instance.new("Attachment")
	centralAttach.Parent = centralCap

	-- Upward energy radiation (chaotic electromagnetic emission into space)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "EnergyRadiation"
	emitter.Rate = 12
	emitter.Lifetime = NumberRange.new(1.5, 3.0)
	emitter.Speed = NumberRange.new(20, 45)
	emitter.SpreadAngle = Vector2.new(12, 12)
	emitter.Color = ColorSequence.new(C_CAPACITOR, Color3.fromRGB(200, 230, 255))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 1.5),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.6, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Parent = centralCap

	-- ======= DOME INTERIOR SYMBOLS (mysterious alien glyphs) =======
	local DOME_GLYPHS = {
		"ᚠ", "ᚢ", "ᚦ", "ᚨ", "ᚱ", "ᚲ", "ᚷ", "ᚾ", "ᛁ", "ᛈ",
		"ᛉ", "ᛊ", "ᛏ", "ᛖ", "ᛗ", "ᛚ", "ᛞ", "ᛟ", "◈", "⊕", "⬡", "△", "☉",
	}
	local C_GLYPH = Color3.fromRGB(240, 210, 100)
	local domeSymbolLabels = {}
	local numDomeSymbols = 12
	local innerFactor = 0.82
	local domeRx = domeSizeXZ / 2 * innerFactor
	local domeRy = domeSizeY / 2 * innerFactor

	for si = 1, numDomeSymbols do
		local theta = math.rad(25 + rng:NextNumber(0, 50))
		local phi = math.rad((si - 1) * (360 / numDomeSymbols) + rng:NextNumber(-10, 10))

		local sx = domeRx * math.sin(theta) * math.cos(phi)
		local sy = domeRy * math.cos(theta)
		local sz = domeRx * math.sin(theta) * math.sin(phi)

		local anchor = Instance.new("Part")
		anchor.Name = "DomeGlyph_" .. si
		anchor.Size = Vector3.new(0.1, 0.1, 0.1)
		anchor.Position = Vector3.new(cx + sx, domeCenterY + sy, cz + sz)
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.Transparency = 1
		anchor.Parent = building

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 70, 0, 70)
		billboard.AlwaysOnTop = false
		billboard.MaxDistance = 80
		billboard.LightInfluence = 0
		billboard.Parent = anchor

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = DOME_GLYPHS[rng:NextInteger(1, #DOME_GLYPHS)]
		label.TextColor3 = C_GLYPH
		label.TextSize = 42
		label.Font = Enum.Font.GothamBold
		label.TextTransparency = 1
		label.Parent = billboard

		table.insert(domeSymbolLabels, label)
	end

	-- ======= CORNER TOWERS =======
	local towerH = 36
	local towerR = 5
	local towerDomeSize = 14
	local towerDomeSizeY = towerDomeSize * 1.3
	local towerSpireH = 8
	local tox = halfW - 6
	local toz = halfD - 6

	local towerPositions = {
		{ cx - tox, cz - toz }, { cx - tox, cz + toz },
		{ cx + tox, cz - toz }, { cx + tox, cz + toz },
	}

	for i, pos in ipairs(towerPositions) do
		-- Tower cylinder
		local tower = Instance.new("Part")
		tower.Name = "Tower_" .. i
		tower.Shape = Enum.PartType.Cylinder
		tower.Size = Vector3.new(towerH, towerR * 2, towerR * 2)
		tower.CFrame = CFrame.new(pos[1], floorY + towerH / 2 + 0.5, pos[2]) * CFrame.Angles(0, 0, math.rad(90))
		tower.Anchored = true
		tower.Color = C_TOWER
		tower.Material = Enum.Material.SmoothPlastic
		tower.Parent = building

		-- Tower dome — OPAQUE
		local towerDomeCenterY = floorY + towerH + 0.5 + towerDomeSizeY / 2
		local td = Instance.new("Part")
		td.Name = "TowerDome_" .. i
		td.Shape = Enum.PartType.Ball
		td.Size = Vector3.new(towerDomeSize, towerDomeSizeY, towerDomeSize)
		td.Position = Vector3.new(pos[1], towerDomeCenterY, pos[2])
		td.Anchored = true
		td.Color = C_DOME
		td.Material = Enum.Material.Glass
		td.Transparency = 0
		td.Parent = building

		-- Tower spire — touches top of tower dome sphere
		local towerDomeTopY = towerDomeCenterY + towerDomeSizeY / 2
		MP("TowerSpire_" .. i, Vector3.new(1, towerSpireH, 1),
			Vector3.new(pos[1], towerDomeTopY + towerSpireH / 2, pos[2]), C_NEON, Enum.Material.Neon)

		-- Tower capacitor sphere
		local towerCapSize = 4
		local towerCapY = towerDomeTopY + towerSpireH + towerCapSize / 2
		local towerCap = Instance.new("Part")
		towerCap.Name = "TowerCapacitor_" .. i
		towerCap.Shape = Enum.PartType.Ball
		towerCap.Size = Vector3.new(towerCapSize, towerCapSize, towerCapSize)
		towerCap.Position = Vector3.new(pos[1], towerCapY, pos[2])
		towerCap.Anchored = true
		towerCap.CanCollide = false
		towerCap.Color = C_CAPACITOR
		towerCap.Material = Enum.Material.Neon
		towerCap.Parent = building

		-- Electric discharge beam from tower to central capacitor
		local towerAttach = Instance.new("Attachment")
		towerAttach.Parent = towerCap

		local beam = Instance.new("Beam")
		beam.Name = "Discharge_" .. i
		beam.Attachment0 = towerAttach
		beam.Attachment1 = centralAttach
		beam.Color = ColorSequence.new(C_CAPACITOR)
		beam.Width0 = 0.8
		beam.Width1 = 0.8
		beam.Transparency = NumberSequence.new(0.5)
		beam.CurveSize0 = rng:NextNumber(-4, 4)
		beam.CurveSize1 = rng:NextNumber(-4, 4)
		beam.Segments = 20
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Parent = building

		table.insert(dischargeBeams, beam)
	end

	-- ======= INTERIOR PILLARS (6 pillars — 2 rows x 3 columns) =======
	local pillarSize = 3
	local pox = innerW / 4
	local poz = (D - 2 * WT) / 4

	local pillarPositions = {}
	for _, px in ipairs({ cx - pox, cx + pox }) do
		for _, pz in ipairs({ cz - poz, cz, cz + poz }) do
			table.insert(pillarPositions, { px, pz })
		end
	end

	for i, pos in ipairs(pillarPositions) do
		MP("Pillar_" .. i, Vector3.new(pillarSize, WH, pillarSize),
			Vector3.new(pos[1], floorY + WH / 2 + 0.5, pos[2]), C_PILLAR)
		MP("PillarNeon_" .. i, Vector3.new(pillarSize + 0.5, 0.3, pillarSize + 0.5),
			Vector3.new(pos[1], floorY + WH + 0.2, pos[2]), C_NEON, Enum.Material.Neon)
	end

	-- Central pedestal (for future artifact)
	MP("Pedestal", Vector3.new(6, 4, 6), Vector3.new(cx, floorY + 2.5, cz), C_PILLAR)
	MP("PedestalNeon", Vector3.new(7, 0.3, 7),
		Vector3.new(cx, floorY + 4.65, cz), C_NEON, Enum.Material.Neon)

	-- ======= EXTERIOR WALL DECALS (alien cultural art) =======
	local WALL_GLYPHS = {
		"𐤀", "𐤁", "𐤂", "𐤃", "𐤄", "𐤅", "𐤆", "𐤇", -- Phoenician
		"☬", "☸", "✡", "☥", "⚶", "⯅", "⬟", "⏣",     -- Sacred geometry
		"𓁿", "𓂀", "𓃭", "𓆏", "𓇳", "𓊝",               -- Hieroglyphic style
	}
	local C_DECAL = Color3.fromRGB(160, 150, 130) -- Faded stone-carved look
	local wallDecalPositions = {
		-- Left wall (Z-) exterior
		{ x = cx - innerW * 0.25, y = floorY + WH * 0.45, z = cz - halfD - 0.5 },
		{ x = cx + innerW * 0.15, y = floorY + WH * 0.65, z = cz - halfD - 0.5 },
		{ x = cx + innerW * 0.35, y = floorY + WH * 0.35, z = cz - halfD - 0.5 },
		-- Right wall (Z+) exterior
		{ x = cx - innerW * 0.30, y = floorY + WH * 0.55, z = cz + halfD + 0.5 },
		{ x = cx + innerW * 0.10, y = floorY + WH * 0.40, z = cz + halfD + 0.5 },
		{ x = cx + innerW * 0.30, y = floorY + WH * 0.70, z = cz + halfD + 0.5 },
		-- Front wall (X-) exterior
		{ x = cx - halfW - 0.5, y = floorY + WH * 0.60, z = cz - D * 0.20 },
		{ x = cx - halfW - 0.5, y = floorY + WH * 0.40, z = cz + D * 0.25 },
	}

	for di, pos in ipairs(wallDecalPositions) do
		local anchor = Instance.new("Part")
		anchor.Name = "WallDecal_" .. di
		anchor.Size = Vector3.new(0.1, 0.1, 0.1)
		anchor.Position = Vector3.new(pos.x, pos.y, pos.z)
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.Transparency = 1
		anchor.Parent = building

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 90, 0, 90)
		billboard.AlwaysOnTop = false
		billboard.MaxDistance = 60
		billboard.LightInfluence = 1
		billboard.Parent = anchor

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = WALL_GLYPHS[rng:NextInteger(1, #WALL_GLYPHS)]
		label.TextColor3 = C_DECAL
		label.TextSize = 52
		label.Font = Enum.Font.GothamBold
		label.TextTransparency = 0.3
		label.Parent = billboard
	end

	-- ======= ENTRANCE DOOR FRAMES (thin neon strips, same look from both sides) =======
	local frameT = 0.5  -- frame strip thickness
	for _, side in ipairs({
		{ x = cx - halfW + WT / 2, prefix = "Front" },
		{ x = cx + halfW - WT / 2, prefix = "Back" },
	}) do
		-- Top strip
		local top = MP(side.prefix .. "DoorFrame_Top", Vector3.new(WT + 0.2, frameT, DOOR_W + 1),
			Vector3.new(side.x, floorY + DOOR_H + 0.5 + frameT / 2, cz), C_NEON, Enum.Material.Neon)
		top.CanCollide = false
		-- Left strip
		local left = MP(side.prefix .. "DoorFrame_L", Vector3.new(WT + 0.2, DOOR_H, frameT),
			Vector3.new(side.x, floorY + DOOR_H / 2 + 0.5, cz - DOOR_W / 2 - frameT / 2), C_NEON, Enum.Material.Neon)
		left.CanCollide = false
		-- Right strip
		local right = MP(side.prefix .. "DoorFrame_R", Vector3.new(WT + 0.2, DOOR_H, frameT),
			Vector3.new(side.x, floorY + DOOR_H / 2 + 0.5, cz + DOOR_W / 2 + frameT / 2), C_NEON, Enum.Material.Neon)
		right.CanCollide = false
	end

	building.Parent = proceduralFolder

	-- Prepare door animation data
	local slideOffset = DOOR_W / 2 + 1
	local doorData = {
		{
			position = Vector3.new(cx - halfW, GROUND_Y + 3, cz),
			panels = {
				{ part = frontDoorL, closedPos = frontDoorL.Position, openPos = frontDoorL.Position + Vector3.new(0, 0, -slideOffset) },
				{ part = frontDoorR, closedPos = frontDoorR.Position, openPos = frontDoorR.Position + Vector3.new(0, 0, slideOffset) },
			},
		},
		{
			position = Vector3.new(cx + halfW, GROUND_Y + 3, cz),
			panels = {
				{ part = backDoorL, closedPos = backDoorL.Position, openPos = backDoorL.Position + Vector3.new(0, 0, -slideOffset) },
				{ part = backDoorR, closedPos = backDoorR.Position, openPos = backDoorR.Position + Vector3.new(0, 0, slideOffset) },
			},
		},
	}

	print(string.format("[%s] Temple created at (%.0f, %.0f) — %d parts",
		MODULE_NAME, cx, cz, #building:GetChildren()))
	return building, doorData, domeSymbolLabels, dischargeBeams, centralCap
end

-- ============================================================================
-- STEP 5: DOOR PROXIMITY SYSTEM
-- ============================================================================

local function SetupDoorSystem(building, doorData)
	if not building or not doorData then return end

	local OPEN_DIST = 15
	local CLOSE_DIST = 20
	local TWEEN_TIME = 0.8

	local doorStates = {}
	for i = 1, #doorData do
		doorStates[i] = false
	end

	task.spawn(function()
		while building and building.Parent do
			for i, door in ipairs(doorData) do
				local nearest = math.huge
				for _, player in ipairs(Players:GetPlayers()) do
					local char = player.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if hrp then
						local d = (hrp.Position - door.position).Magnitude
						if d < nearest then nearest = d end
					end
				end

				if nearest < OPEN_DIST and not doorStates[i] then
					doorStates[i] = true
					for _, panel in ipairs(door.panels) do
						TweenService:Create(panel.part,
							TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ Position = panel.openPos }
						):Play()
					end
				elseif nearest > CLOSE_DIST and doorStates[i] then
					doorStates[i] = false
					for _, panel in ipairs(door.panels) do
						TweenService:Create(panel.part,
							TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
							{ Position = panel.closedPos }
						):Play()
					end
				end
			end
			task.wait(0.25)
		end
	end)

	print(string.format("[%s] Door proximity system active", MODULE_NAME))
end

-- ============================================================================
-- STEP 6: DOME SYMBOL ANIMATION
-- ============================================================================

local function SetupDomeSymbolAnimation(building, symbolLabels)
	if not building or not symbolLabels or #symbolLabels == 0 then return end

	task.spawn(function()
		local animRng = Random.new(SEED + 99)

		while building and building.Parent do
			-- Pick 1-3 random symbols to animate
			local count = animRng:NextInteger(1, 3)
			for _ = 1, count do
				local idx = animRng:NextInteger(1, #symbolLabels)
				local label = symbolLabels[idx]
				if not label or not label.Parent then continue end

				-- Fade in
				local targetTransparency = animRng:NextNumber(0.1, 0.4)
				local fadeInTime = animRng:NextNumber(1.0, 2.5)
				TweenService:Create(label,
					TweenInfo.new(fadeInTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{ TextTransparency = targetTransparency }
				):Play()

				-- Schedule fade out after hold time
				local holdTime = animRng:NextNumber(2.0, 5.0)
				local fadeOutTime = animRng:NextNumber(1.5, 3.0)
				task.delay(fadeInTime + holdTime, function()
					if label and label.Parent then
						TweenService:Create(label,
							TweenInfo.new(fadeOutTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
							{ TextTransparency = 1 }
						):Play()
					end
				end)
			end

			-- Wait before next animation cycle
			task.wait(animRng:NextNumber(3.0, 7.0))
		end
	end)

	print(string.format("[%s] Dome symbol animation active (%d symbols)", MODULE_NAME, #symbolLabels))
end

-- ============================================================================
-- STEP 7: ELECTRIC DISCHARGE ANIMATION
-- ============================================================================

local function SetupElectricDischarges(building, beams)
	if not building or not beams or #beams == 0 then return end

	task.spawn(function()
		local arcRng = Random.new(SEED + 77)

		while building and building.Parent do
			for _, beam in ipairs(beams) do
				if not beam or not beam.Parent then continue end

				-- Randomize arc shape every tick
				beam.CurveSize0 = arcRng:NextNumber(-5, 5)
				beam.CurveSize1 = arcRng:NextNumber(-5, 5)

				-- Random intensity pulse
				local intensity = arcRng:NextNumber(0, 1)
				if intensity > 0.7 then
					-- Bright discharge
					beam.Enabled = true
					beam.Width0 = arcRng:NextNumber(0.8, 2.5)
					beam.Width1 = arcRng:NextNumber(0.8, 2.5)
					beam.Transparency = NumberSequence.new(arcRng:NextNumber(0, 0.3))
				elseif intensity > 0.3 then
					-- Dim arc
					beam.Enabled = true
					beam.Width0 = arcRng:NextNumber(0.2, 0.6)
					beam.Width1 = arcRng:NextNumber(0.2, 0.6)
					beam.Transparency = NumberSequence.new(arcRng:NextNumber(0.5, 0.8))
				else
					-- Momentarily off
					beam.Enabled = false
				end
			end

			task.wait(arcRng:NextNumber(0.05, 0.15))
		end
	end)

	print(string.format("[%s] Electric discharge system active (%d beams)", MODULE_NAME, #beams))
end

-- ============================================================================
-- STEP 8: VERTICAL LIGHTNING BOLT (Central Capacitor → Sky)
-- ============================================================================

local function SetupVerticalLightning(building, centralCapacitor)
	if not building or not centralCapacitor then return end

	-- Create invisible sky anchor ~500 studs above the capacitor
	local skyAnchor = Instance.new("Part")
	skyAnchor.Name = "SkyAnchor"
	skyAnchor.Size = Vector3.new(1, 1, 1)
	skyAnchor.Position = centralCapacitor.Position + Vector3.new(0, 500, 0)
	skyAnchor.Anchored = true
	skyAnchor.CanCollide = false
	skyAnchor.Transparency = 1
	skyAnchor.Parent = building

	local skyAttach = Instance.new("Attachment")
	skyAttach.Parent = skyAnchor

	local capAttach = centralCapacitor:FindFirstChildOfClass("Attachment")
	if not capAttach then
		capAttach = Instance.new("Attachment")
		capAttach.Parent = centralCapacitor
	end

	-- Lightning beam (initially disabled)
	local bolt = Instance.new("Beam")
	bolt.Name = "VerticalLightning"
	bolt.Attachment0 = capAttach
	bolt.Attachment1 = skyAttach
	bolt.Color = ColorSequence.new(
		Color3.fromRGB(120, 200, 255),
		Color3.fromRGB(255, 255, 255)
	)
	bolt.Width0 = 3
	bolt.Width1 = 0.5
	bolt.Segments = 30
	bolt.FaceCamera = true
	bolt.LightEmission = 1
	bolt.LightInfluence = 0
	bolt.Transparency = NumberSequence.new(0)
	bolt.Enabled = false
	bolt.Parent = building

	-- Flash light on the capacitor
	local flash = Instance.new("PointLight")
	flash.Name = "LightningFlash"
	flash.Color = Color3.fromRGB(140, 210, 255)
	flash.Brightness = 0
	flash.Range = 120
	flash.Parent = centralCapacitor

	task.spawn(function()
		local boltRng = Random.new(SEED + 55)

		while building and building.Parent do
			-- Wait random interval between bolts (15-60 seconds)
			task.wait(boltRng:NextNumber(15, 60))

			if not building or not building.Parent then break end

			-- Randomize bolt shape
			bolt.CurveSize0 = boltRng:NextNumber(-15, 15)
			bolt.CurveSize1 = boltRng:NextNumber(-15, 15)
			bolt.Width0 = boltRng:NextNumber(2, 5)
			bolt.Width1 = boltRng:NextNumber(0.3, 1.0)

			-- FLASH: enable bolt + light burst
			bolt.Enabled = true
			flash.Brightness = boltRng:NextNumber(3, 6)

			-- Hold for 0.3-0.8 seconds with flickering
			local holdTime = boltRng:NextNumber(0.3, 0.8)
			local flickerEnd = os.clock() + holdTime
			while os.clock() < flickerEnd do
				bolt.CurveSize0 = boltRng:NextNumber(-20, 20)
				bolt.CurveSize1 = boltRng:NextNumber(-20, 20)
				bolt.Transparency = NumberSequence.new(boltRng:NextNumber(0, 0.3))
				flash.Brightness = boltRng:NextNumber(1, 6)
				task.wait(0.05)
			end

			-- Fade out
			bolt.Enabled = false
			TweenService:Create(flash,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Brightness = 0 }
			):Play()
		end
	end)

	print(string.format("[%s] Vertical lightning system active", MODULE_NAME))
end

-- ============================================================================
-- STEP 9: FRACTAL TREES (cylindrical, turquoise-agate leaves)
-- ============================================================================

local function CreateFractalTree(rootPosition)
	local tree = Instance.new("Model")
	tree.Name = "FractalTree"

	-- Random height variation
	local treeScale = rng:NextNumber(0.5, 1.5)
	local trunkHeight = rng:NextNumber(6, 16) * treeScale
	local trunkThickness = rng:NextNumber(1.0, 1.6) + trunkHeight * 0.06

	local function CreateBranch(startPos, direction, length, thickness, depth)
		local endPos = startPos + direction * length
		local midPos = startPos + direction * (length / 2)

		-- Cylindrical branch
		local branch = Instance.new("Part")
		branch.Name = depth == 0 and "Trunk" or "Branch"
		branch.Shape = Enum.PartType.Cylinder
		branch.Size = Vector3.new(length, thickness, thickness)
		branch.CFrame = AlignCylinderAxis(midPos, direction)
		branch.Anchored = true
		branch.CanCollide = (depth <= 1)
		branch.Material = Enum.Material.Wood
		branch.Color = Color3.fromRGB(
			math.max(60, 101 - depth * 15),
			math.max(45, 79 - depth * 12),
			math.max(25, 49 - depth * 8)
		)
		branch.Parent = tree

		if depth < TREE_BRANCH_DEPTH then
			local numBranches = rng:NextInteger(2, 3)
			local branchLenFactor = rng:NextNumber(0.5, 0.7)
			for _ = 1, numBranches do
				local angle = math.rad(rng:NextInteger(25, 50))
				local spin = math.rad(rng:NextInteger(0, 359))

				local perp = GetPerpendicular(direction)
				local tilted = RotateVector(direction, perp, angle)
				local newDir = RotateVector(tilted, direction, spin)

				CreateBranch(endPos, newDir.Unit, length * branchLenFactor, thickness * 0.55, depth + 1)
			end
		else
			-- Leaf cluster — turquoise to agate color range
			local leaf = Instance.new("Part")
			leaf.Name = "Leaves"
			leaf.Shape = Enum.PartType.Ball
			local leafSize = 3 + rng:NextNumber(0, 4)
			leaf.Size = Vector3.new(leafSize, leafSize * 0.8, leafSize)
			leaf.Position = endPos
			leaf.Anchored = true
			leaf.CanCollide = false
			leaf.Material = Enum.Material.Grass

			local t = rng:NextNumber(0, 1)
			local r = math.clamp(math.floor(t * 100 + rng:NextInteger(-15, 15)), 0, 255)
			local g = math.clamp(math.floor(190 - t * 140 + rng:NextInteger(-15, 15)), 0, 255)
			local b = math.clamp(math.floor(190 - t * 120 + rng:NextInteger(-15, 15)), 0, 255)
			leaf.Color = Color3.fromRGB(r, g, b)

			leaf.Parent = tree
		end
	end

	-- Trunk starts at ground level, grows upward
	CreateBranch(rootPosition, Vector3.new(0, 1, 0), trunkHeight, trunkThickness, 0)

	tree.Parent = proceduralFolder
	return tree
end

local function PlantTrees()
	local treeCount = rng:NextInteger(TREES_MIN, TREES_MAX)
	local treePositions = {}
	local attempts = 0
	local maxAttempts = treeCount * 10

	while #treePositions < treeCount and attempts < maxAttempts do
		attempts += 1

		local tx = rng:NextNumber(ZONE_MIN_X + 20, ZONE_MAX_X - 10)
		local tz = rng:NextNumber(ZONE_MIN_Z + 10, ZONE_MAX_Z - 10)

		-- Building exclusion (building + margin + entrance paths)
		if buildingCenter then
			local bHW = BUILDING_W / 2 + TREE_BUILDING_MARGIN
			local bHD = BUILDING_D / 2 + TREE_BUILDING_MARGIN
			if IsInsideRect(tx, tz,
				buildingCenter.x - bHW, buildingCenter.z - bHD,
				buildingCenter.x + bHW, buildingCenter.z + bHD) then
				continue
			end
			-- Front entrance path (X- direction)
			if IsInsideRect(tx, tz,
				buildingCenter.x - BUILDING_W / 2 - TREE_ENTRANCE_LENGTH,
				buildingCenter.z - TREE_ENTRANCE_WIDTH / 2,
				buildingCenter.x - BUILDING_W / 2,
				buildingCenter.z + TREE_ENTRANCE_WIDTH / 2) then
				continue
			end
			-- Back entrance path (X+ direction)
			if IsInsideRect(tx, tz,
				buildingCenter.x + BUILDING_W / 2,
				buildingCenter.z - TREE_ENTRANCE_WIDTH / 2,
				buildingCenter.x + BUILDING_W / 2 + TREE_ENTRANCE_LENGTH,
				buildingCenter.z + TREE_ENTRANCE_WIDTH / 2) then
				continue
			end
		end

		-- Minimum spacing between trees
		local tooClose = false
		for _, pos in ipairs(treePositions) do
			if (tx - pos.x) ^ 2 + (tz - pos.z) ^ 2 < TREE_MIN_SPACING ^ 2 then
				tooClose = true
				break
			end
		end
		if tooClose then continue end

		table.insert(treePositions, { x = tx, z = tz })
	end

	for i, pos in ipairs(treePositions) do
		CreateFractalTree(Vector3.new(pos.x, GROUND_Y, pos.z))
		if i % 10 == 0 then
			task.wait()
		end
	end

	print(string.format("[%s] Trees: %d planted", MODULE_NAME, #treePositions))
end

-- ============================================================================
-- MAIN EXECUTION
-- ============================================================================

print(string.format("[%s %s] Starting generation (seed=%d)", MODULE_NAME, VERSION, SEED))

GenerateBarePatches()
PickBuildingPosition()
GenerateTerrain()
task.wait()
local building, doorData, domeSymbolLabels, dischargeBeams, centralCap = CreateBuilding()
task.wait()
SetupDoorSystem(building, doorData)
SetupDomeSymbolAnimation(building, domeSymbolLabels)
SetupElectricDischarges(building, dischargeBeams)
SetupVerticalLightning(building, centralCap)
PlantTrees()

print(string.format("[%s %s] Generation complete", MODULE_NAME, VERSION))
