--[[
================================================================================
KOSMICMAZER — LocationGenerator (Location_1)
================================================================================

Purpose:
Procedural content generation for Location_1 "Візитка" surface.
Generates terrain, bare patches, alien temple with doors, and fractal trees.

Version:
0.8

Features:
- FBM noise terrain with gentle hills (6x lower than v0.1)
- Random bare patches (4-24 clearings without grass)
- Octagonal alien temple with 8 corner towers, hexagonal windows
- Proximity-triggered sliding doors on front/back walls
- Fractal trees with cylindrical trunks/branches, turquoise-agate leaves
- Random tree height variation
- Deterministic seed-based generation
- Circular building exclusion zone for terrain and trees
- Clear entrance paths to building
- Emitter malfunction system (random cycling, ≥1 always off)
- Auxiliary discharge with adjacency rule (fires only when adjacent emitter works)
- Main emitter charge system (0%→100%, 2-12% per aux discharge)
- Vertical lightning bolt triggered by charge accumulation
- ModuleScript lifecycle: levelInit()/levelFini()

Dependencies:
- FastNoise (ReplicatedStorage/Game/FastNoise)
- Workspace.Terrain
- TweenService (door animations)
- Players (door proximity detection)

ChangeLog:
- 0.8: ModuleScript pattern, charge system, adjacency rule, proper hex windows (2026-02-08)
- 0.7: Hex windows, round pedestal, emitter malfunction, discharge sound (2026-02-08)
- 0.6: Octagonal temple with 8 corner towers and 8 capacitor spheres (2026-02-08)
- 0.5: Spire embedding, lightning-like discharges, thunder (2026-02-08)
- 0.4: Vertical lightning bolt from central spire (2026-02-08)
- 0.3: 4x building, doors, cylindrical trees, turquoise leaves, lower grass (2026-02-06)
- 0.2: Bare patches, alien temple, fractal trees, lower terrain (2026-02-06)
- 0.1: Initial procedural terrain with FBM noise (2026-02-06)
================================================================================
]]

local TerrainGenerator = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local SEED = 42
local MODULE_NAME = "LocationGenerator"
local VERSION = "0.8"

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
local BUILDING_RADIUS = 80       -- Circumradius of octagonal temple
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

local FastNoise = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("FastNoise"))
local terrain = Workspace.Terrain

-- ============================================================================
-- MODULE STATE (reset in levelInit)
-- ============================================================================

local rng
local fbm
local proceduralFolder
local barePatches
local buildingCenter

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

local function PickBuildingPosition()
	local bx = rng:NextNumber(BUILDING_ZONE_MIN_X + BUILDING_RADIUS, BUILDING_ZONE_MAX_X - BUILDING_RADIUS)
	local bz = rng:NextNumber(BUILDING_ZONE_MIN_Z + BUILDING_RADIUS, BUILDING_ZONE_MAX_Z - BUILDING_RADIUS)
	buildingCenter = { x = bx, z = bz }
	print(string.format("[%s] Building position: (%.0f, %.0f)", MODULE_NAME, bx, bz))
end

-- ============================================================================
-- STEP 3: TERRAIN GENERATION
-- ============================================================================

local function IsInBuildingZone(x, z)
	if not buildingCenter then return false end
	local r = BUILDING_RADIUS + BUILDING_CLEARANCE
	return (x - buildingCenter.x) ^ 2 + (z - buildingCenter.z) ^ 2 <= r * r
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
-- STEP 4: BUILDING — Octagonal Alien Temple (circumradius 80, 8 corner towers)
-- ============================================================================

local function CreateBuilding()
	if not buildingCenter then return nil, nil end

	local building = Instance.new("Model")
	building.Name = "AncientTemple"

	local cx = buildingCenter.x
	local cz = buildingCenter.z
	local floorY = GROUND_Y

	-- Octagonal geometry
	local R = BUILDING_RADIUS                          -- 80 (circumradius)
	local SIDES = 8
	local sideLen = 2 * R * math.sin(math.pi / SIDES) -- ~61.24
	local apothem = R * math.cos(math.pi / SIDES)     -- ~73.9

	-- Dimensions
	local WH = 32              -- Wall height
	local WT = 4               -- Wall thickness
	local DOOR_W = 8           -- Door width
	local DOOR_H = 12          -- Door height
	local HEX_R = 7            -- Hexagonal window circumradius

	-- Colors
	local C_WALL = Color3.fromRGB(175, 175, 185)
	local C_DOME = Color3.fromRGB(195, 165, 55)
	local C_NEON = Color3.fromRGB(240, 200, 80)
	local C_FLOOR = Color3.fromRGB(55, 60, 70)
	local C_GLASS = Color3.fromRGB(20, 160, 200)
	local C_PILLAR = Color3.fromRGB(150, 150, 165)
	local C_TOWER = Color3.fromRGB(165, 165, 175)
	local C_DOOR = Color3.fromRGB(110, 120, 135)

	-- Part factory: accepts CFrame or Vector3 position
	local function MP(name, size, cfOrPos, color, material, transparency)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		if typeof(cfOrPos) == "CFrame" then
			p.CFrame = cfOrPos
		else
			p.Position = cfOrPos
		end
		p.Anchored = true
		p.Color = color or C_WALL
		p.Material = material or Enum.Material.SmoothPlastic
		p.Transparency = transparency or 0
		p.Parent = building
		return p
	end

	-- ======= OCTAGONAL VERTICES =======
	-- Vertex i at angle 22.5° + i*45° (i=0..7)
	local vertices = {}
	for i = 0, SIDES - 1 do
		local angle = math.rad(22.5 + i * 45)
		vertices[i + 1] = {
			x = cx + R * math.cos(angle),
			z = cz + R * math.sin(angle),
		}
	end

	-- Wall i (1..8): between vertex i and vertex i+1 (mod 8)
	-- Normal angle for wall i = i * 45° (outward)
	-- Wall 4: normal 180° → faces -X (FRONT door)
	-- Wall 8: normal 360°/0° → faces +X (BACK door)
	local doorWalls = { [4] = true, [8] = true }

	-- ======= FLOOR (cylindrical, inscribed circle) =======
	local floorDiam = apothem * 2
	local floorPart = Instance.new("Part")
	floorPart.Name = "Floor"
	floorPart.Shape = Enum.PartType.Cylinder
	floorPart.Size = Vector3.new(1, floorDiam, floorDiam)
	floorPart.CFrame = CFrame.new(cx, floorY, cz) * CFrame.Angles(0, 0, math.rad(90))
	floorPart.Anchored = true
	floorPart.Color = C_FLOOR
	floorPart.Material = Enum.Material.SmoothPlastic
	floorPart.Parent = building

	-- ======= WALLS (8 sides: 2 with doors, 6 with windows) =======
	-- Wall CFrame: Size(WT, WH, sideLen), local X=normal, local Z=tangent
	-- CFrame = CFrame.new(wallCenter) * CFrame.Angles(0, -normalAngle, 0)
	local wallCenterY = floorY + WH / 2 + 0.5
	local doorPanels = {}
	local doorData = {}
	local towerSpires = {}
	local wallNeonTrims = {}

	for i = 1, SIDES do
		local normalAngle = math.rad(i * 45)
		local nx = math.cos(normalAngle)
		local nz = math.sin(normalAngle)
		local tx = -math.sin(normalAngle)  -- tangent direction
		local tz = math.cos(normalAngle)
		local wallCX = cx + apothem * nx
		local wallCZ = cz + apothem * nz
		local rot = CFrame.Angles(0, -normalAngle, 0)

		if doorWalls[i] then
			-- === DOOR WALL ===
			local sideSegLen = (sideLen - DOOR_W) / 2

			-- Left segment (tangent negative side)
			MP("Wall" .. i .. "_L", Vector3.new(WT, WH, sideSegLen),
				CFrame.new(wallCX + tx * (sideLen / 2 - sideSegLen / 2) * -1,
					wallCenterY,
					wallCZ + tz * (sideLen / 2 - sideSegLen / 2) * -1) * rot, C_WALL)
			-- Right segment (tangent positive side)
			MP("Wall" .. i .. "_R", Vector3.new(WT, WH, sideSegLen),
				CFrame.new(wallCX + tx * (sideLen / 2 - sideSegLen / 2),
					wallCenterY,
					wallCZ + tz * (sideLen / 2 - sideSegLen / 2)) * rot, C_WALL)
			-- Top segment (above door)
			local topH = WH - DOOR_H
			MP("Wall" .. i .. "_Top", Vector3.new(WT, topH, DOOR_W),
				CFrame.new(wallCX, floorY + DOOR_H + topH / 2 + 0.5, wallCZ) * rot, C_WALL)

			-- Door panels (slide along tangent)
			local doorCenterY = floorY + DOOR_H / 2 + 0.5
			local doorL = MP("Door" .. i .. "_L", Vector3.new(WT, DOOR_H, DOOR_W / 2),
				CFrame.new(wallCX + tx * (-DOOR_W / 4), doorCenterY, wallCZ + tz * (-DOOR_W / 4)) * rot, C_DOOR)
			local doorR = MP("Door" .. i .. "_R", Vector3.new(WT, DOOR_H, DOOR_W / 2),
				CFrame.new(wallCX + tx * (DOOR_W / 4), doorCenterY, wallCZ + tz * (DOOR_W / 4)) * rot, C_DOOR)

			-- Door frame neon strips
			local frameT = 0.5
			local ftop = MP("DoorFrame" .. i .. "_Top", Vector3.new(WT + 0.2, frameT, DOOR_W + 1),
				CFrame.new(wallCX, floorY + DOOR_H + 0.5 + frameT / 2, wallCZ) * rot, C_NEON, Enum.Material.Neon)
			ftop.CanCollide = false
			local fleft = MP("DoorFrame" .. i .. "_L", Vector3.new(WT + 0.2, DOOR_H, frameT),
				CFrame.new(wallCX + tx * (-DOOR_W / 2 - frameT / 2), doorCenterY,
					wallCZ + tz * (-DOOR_W / 2 - frameT / 2)) * rot, C_NEON, Enum.Material.Neon)
			fleft.CanCollide = false
			local fright = MP("DoorFrame" .. i .. "_R", Vector3.new(WT + 0.2, DOOR_H, frameT),
				CFrame.new(wallCX + tx * (DOOR_W / 2 + frameT / 2), doorCenterY,
					wallCZ + tz * (DOOR_W / 2 + frameT / 2)) * rot, C_NEON, Enum.Material.Neon)
			fright.CanCollide = false

			-- Door slide data (tangent direction for open/close)
			local slideOffset = DOOR_W / 2 + 1
			local tangent = Vector3.new(tx, 0, tz)
			table.insert(doorData, {
				position = Vector3.new(wallCX, GROUND_Y + 3, wallCZ),
				panels = {
					{ part = doorL, closedPos = doorL.Position, openPos = doorL.Position - tangent * slideOffset },
					{ part = doorR, closedPos = doorR.Position, openPos = doorR.Position + tangent * slideOffset },
				},
			})
		else
			-- === SOLID WALL WITH HEXAGONAL WINDOW ===
			local hexCenterY = floorY + WH / 2 + 0.5
			local HEX_H = HEX_R * math.sqrt(3) -- ~12.12 (hex height, flat-top)
			local HEX_W = HEX_R * 2             -- 14 (hex width)
			local openH = HEX_H + 1
			local openW = HEX_W + 1

			-- Bottom strip (full width, below hex opening)
			local botH = (hexCenterY - openH / 2) - (floorY + 0.5)
			MP("Wall" .. i .. "_Bottom", Vector3.new(WT, botH, sideLen),
				CFrame.new(wallCX, floorY + 0.5 + botH / 2, wallCZ) * rot, C_WALL)

			-- Top strip (full width, above hex opening)
			local topBase = hexCenterY + openH / 2
			local topH = (floorY + WH + 0.5) - topBase
			MP("Wall" .. i .. "_Top", Vector3.new(WT, topH, sideLen),
				CFrame.new(wallCX, topBase + topH / 2, wallCZ) * rot, C_WALL)

			-- Left side strip
			local sideW = (sideLen - openW) / 2
			MP("Wall" .. i .. "_Left", Vector3.new(WT, openH, sideW),
				CFrame.new(wallCX + tx * (-(openW / 2 + sideW / 2)), hexCenterY,
					wallCZ + tz * (-(openW / 2 + sideW / 2))) * rot, C_WALL)

			-- Right side strip
			MP("Wall" .. i .. "_Right", Vector3.new(WT, openH, sideW),
				CFrame.new(wallCX + tx * (openW / 2 + sideW / 2), hexCenterY,
					wallCZ + tz * (openW / 2 + sideW / 2)) * rot, C_WALL)

			-- Glass pane (covers full opening behind hex frame)
			MP("HexGlass_" .. i, Vector3.new(0.5, openH, openW),
				CFrame.new(wallCX, hexCenterY, wallCZ) * rot,
				C_GLASS, Enum.Material.Glass, 0.4)

			-- Hexagonal neon frame: 6 edge strips between hex vertices
			-- Flat-top hex: vertex v at angle v*60° from center
			local wallNormalVec = Vector3.new(nx, 0, nz)
			local hexVerts = {}
			for v = 0, 5 do
				local a = math.rad(v * 60)
				local vz = HEX_R * math.cos(a) -- tangent offset
				local vy = HEX_R * math.sin(a) -- vertical offset
				hexVerts[v + 1] = Vector3.new(
					wallCX + tx * vz,
					hexCenterY + vy,
					wallCZ + tz * vz
				)
			end

			for e = 1, 6 do
				local p1 = hexVerts[e]
				local p2 = hexVerts[(e % 6) + 1]
				local mid = (p1 + p2) / 2
				local edgeLen = (p2 - p1).Magnitude
				local dir = (p2 - p1).Unit
				local perp = dir:Cross(wallNormalVec).Unit
				local cf = CFrame.fromMatrix(mid, perp, wallNormalVec)
				local strip = MP("HexFrame_" .. i .. "_" .. e,
					Vector3.new(0.8, 0.4, edgeLen), cf, C_NEON, Enum.Material.Neon)
				strip.CanCollide = false
			end
		end

		-- Neon trim on top of each wall (tracked for malfunction system)
		local neonH = 0.5
		local wallTopY = floorY + WH + 0.5 + neonH / 2
		wallNeonTrims[i] = MP("NeonTrim_" .. i, Vector3.new(WT + 0.4, neonH, sideLen + 0.4),
			CFrame.new(wallCX, wallTopY, wallCZ) * rot, C_NEON, Enum.Material.Neon)
	end

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

	-- Dome spire — embedded into dome sphere for visual contact
	local mainSpireH = 12
	local domeTopY = domeCenterY + domeSizeY / 2
	local spireEmbed = 3
	MP("DomeSpire", Vector3.new(1.5, mainSpireH, 1.5),
		Vector3.new(cx, domeTopY - spireEmbed + mainSpireH / 2, cz), C_NEON, Enum.Material.Neon)

	-- ======= CAPACITOR SPHERES & ELECTRIC DISCHARGE =======
	local C_CAPACITOR = Color3.fromRGB(80, 180, 255)
	local dischargeBeams = {}

	-- Central capacitor sphere (electromagnetic energy concentrator)
	local centralCapSize = 6
	local centralCapY = domeTopY - spireEmbed + mainSpireH - 1 + centralCapSize / 2
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

	-- ======= CORNER TOWERS (8 towers at octagonal vertices) =======
	local towerH = 36
	local towerR = 5
	local towerDomeSize = 14
	local towerDomeSizeY = towerDomeSize * 1.3
	local towerSpireH = 8

	for i, vtx in ipairs(vertices) do
		-- Tower cylinder
		local tower = Instance.new("Part")
		tower.Name = "Tower_" .. i
		tower.Shape = Enum.PartType.Cylinder
		tower.Size = Vector3.new(towerH, towerR * 2, towerR * 2)
		tower.CFrame = CFrame.new(vtx.x, floorY + towerH / 2 + 0.5, vtx.z) * CFrame.Angles(0, 0, math.rad(90))
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
		td.Position = Vector3.new(vtx.x, towerDomeCenterY, vtx.z)
		td.Anchored = true
		td.Color = C_DOME
		td.Material = Enum.Material.Glass
		td.Transparency = 0
		td.Parent = building

		-- Tower spire — embedded into tower dome for visual contact
		local towerDomeTopY = towerDomeCenterY + towerDomeSizeY / 2
		local towerEmbed = 2
		local spire = MP("TowerSpire_" .. i, Vector3.new(1, towerSpireH, 1),
			Vector3.new(vtx.x, towerDomeTopY - towerEmbed + towerSpireH / 2, vtx.z), C_NEON, Enum.Material.Neon)
		towerSpires[i] = spire

		-- Electric discharge beam from tower spire to central capacitor
		local towerAttach = Instance.new("Attachment")
		towerAttach.Parent = spire

		local beam = Instance.new("Beam")
		beam.Name = "Discharge_" .. i
		beam.Attachment0 = towerAttach
		beam.Attachment1 = centralAttach
		beam.Color = ColorSequence.new(C_CAPACITOR, Color3.fromRGB(200, 230, 255))
		beam.Width0 = 1.5
		beam.Width1 = 0.5
		beam.Transparency = NumberSequence.new(0)
		beam.CurveSize0 = rng:NextNumber(-15, 15)
		beam.CurveSize1 = rng:NextNumber(-15, 15)
		beam.Segments = 40
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Enabled = false
		beam.Parent = building

		table.insert(dischargeBeams, beam)
	end

	-- ======= INTERIOR PILLARS (8 pillars in a circle) =======
	local pillarSize = 3
	local pillarRadius = apothem * 0.45  -- ~33 studs from center

	for i = 1, SIDES do
		local pAngle = math.rad(i * 45)
		local px = cx + pillarRadius * math.cos(pAngle)
		local pz = cz + pillarRadius * math.sin(pAngle)
		MP("Pillar_" .. i, Vector3.new(pillarSize, WH, pillarSize),
			Vector3.new(px, floorY + WH / 2 + 0.5, pz), C_PILLAR)
		MP("PillarNeon_" .. i, Vector3.new(pillarSize + 0.5, 0.3, pillarSize + 0.5),
			Vector3.new(px, floorY + WH + 0.2, pz), C_NEON, Enum.Material.Neon)
	end

	-- Central pedestal (round, for future artifact)
	local pedestal = Instance.new("Part")
	pedestal.Name = "Pedestal"
	pedestal.Shape = Enum.PartType.Cylinder
	pedestal.Size = Vector3.new(4, 6, 6)
	pedestal.CFrame = CFrame.new(cx, floorY + 2.5, cz) * CFrame.Angles(0, 0, math.rad(90))
	pedestal.Anchored = true
	pedestal.Color = C_PILLAR
	pedestal.Material = Enum.Material.SmoothPlastic
	pedestal.Parent = building

	-- ======= EXTERIOR WALL DECALS (alien cultural art) =======
	local WALL_GLYPHS = {
		"𐤀", "𐤁", "𐤂", "𐤃", "𐤄", "𐤅", "𐤆", "𐤇", -- Phoenician
		"☬", "☸", "✡", "☥", "⚶", "⯅", "⬟", "⏣",     -- Sacred geometry
		"𓁿", "𓂀", "𓃭", "𓆏", "𓇳", "𓊝",               -- Hieroglyphic style
	}
	local C_DECAL = Color3.fromRGB(160, 150, 130)

	-- Place 1 decal on each solid wall (6 walls without doors)
	for i = 1, SIDES do
		if not doorWalls[i] then
			local normalAngle = math.rad(i * 45)
			local decalDist = apothem + 0.5  -- just outside the wall
			local decalX = cx + decalDist * math.cos(normalAngle)
			local decalZ = cz + decalDist * math.sin(normalAngle)
			local decalY = floorY + WH * rng:NextNumber(0.35, 0.70)

			local anchor = Instance.new("Part")
			anchor.Name = "WallDecal_" .. i
			anchor.Size = Vector3.new(0.1, 0.1, 0.1)
			anchor.Position = Vector3.new(decalX, decalY, decalZ)
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
	end

	building.Parent = proceduralFolder

	print(string.format("[%s] Octagonal temple at (%.0f, %.0f) — %d parts",
		MODULE_NAME, cx, cz, #building:GetChildren()))
	return building, doorData, domeSymbolLabels, dischargeBeams, centralCap, towerSpires, wallNeonTrims
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
-- STEP 7: EMITTER MALFUNCTION SYSTEM (beacon status: malfunctioning)
-- ============================================================================

local function SetupEmitterMalfunction(building, towerSpires, wallNeonTrims)
	if not building or not towerSpires or #towerSpires == 0 then return {} end

	local C_NEON_ON = Color3.fromRGB(240, 200, 80)
	local C_NEON_OFF = Color3.fromRGB(80, 70, 40)

	local emitterOn = {}
	for i = 1, 8 do emitterOn[i] = true end

	local function countOff()
		local c = 0
		for i = 1, 8 do if not emitterOn[i] then c = c + 1 end end
		return c
	end

	local function updateVisuals(idx)
		local on = emitterOn[idx]

		-- Tower spire neon on/off
		if towerSpires[idx] then
			towerSpires[idx].Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
			towerSpires[idx].Color = on and C_NEON_ON or C_NEON_OFF
		end

		-- Adjacent wall neon trims: tower idx is at vertex idx
		-- Wall k goes from vertex k to vertex (k%8)+1
		-- So tower idx affects wall (idx-1) and wall idx
		local wallA = ((idx - 2) % 8) + 1 -- wall before this tower
		local wallB = idx                   -- wall starting at this tower

		for _, wIdx in ipairs({ wallA, wallB }) do
			if wallNeonTrims[wIdx] then
				local startTower = wIdx
				local endTower = (wIdx % 8) + 1
				local wallOn = emitterOn[startTower] and emitterOn[endTower]
				wallNeonTrims[wIdx].Material = wallOn and Enum.Material.Neon or Enum.Material.SmoothPlastic
				wallNeonTrims[wIdx].Color = wallOn and C_NEON_ON or C_NEON_OFF
			end
		end
	end

	-- Force one random emitter off at start (beacon is malfunctioning)
	local malfRng = Random.new(SEED + 200)
	local startOff = malfRng:NextInteger(1, 8)
	emitterOn[startOff] = false
	updateVisuals(startOff)

	-- Spawn malfunction cycle for each emitter
	for idx = 1, 8 do
		task.spawn(function()
			local cycleRng = Random.new(SEED + 200 + idx)

			-- Stagger start times so emitters don't all cycle in sync
			task.wait(cycleRng:NextNumber(0, 15))

			while building and building.Parent do
				if emitterOn[idx] then
					-- ON phase: wait before turning off (10-50 sec)
					task.wait(cycleRng:NextNumber(10, 50))
					if not building or not building.Parent then break end

					-- Turn off
					emitterOn[idx] = false
					updateVisuals(idx)

					-- OFF phase: wait before trying to turn on (5-30 sec)
					task.wait(cycleRng:NextNumber(5, 30))
					if not building or not building.Parent then break end

					-- Turn on only if at least 2 are off (keep ≥1 always off)
					if countOff() > 1 then
						emitterOn[idx] = true
						updateVisuals(idx)
					else
						-- We're the only one off — wait until another turns off
						while countOff() <= 1 and building and building.Parent do
							task.wait(1)
						end
						if building and building.Parent then
							emitterOn[idx] = true
							updateVisuals(idx)
						end
					end
				else
					-- Started off (initial state) — wait then try to turn on
					task.wait(cycleRng:NextNumber(5, 30))
					if not building or not building.Parent then break end

					if countOff() > 1 then
						emitterOn[idx] = true
						updateVisuals(idx)
					else
						while countOff() <= 1 and building and building.Parent do
							task.wait(1)
						end
						if building and building.Parent then
							emitterOn[idx] = true
							updateVisuals(idx)
						end
					end
				end
			end
		end)
	end

	print(string.format("[%s] Emitter malfunction system active (8 emitters, ≥1 always off)", MODULE_NAME))
	return emitterOn
end

-- ============================================================================
-- STEP 8: AUXILIARY DISCHARGE WITH ADJACENCY + CHARGE SYSTEM
-- ============================================================================

local function SetupElectricDischarges(building, beams, emitterStates, fireBoltFunc)
	if not building or not beams or #beams == 0 then return end

	-- Main emitter charge (0%→100%, fires at ≥100%)
	local mainCharge = 0

	-- Electrostatic discharge sound
	local centralCapPart = building:FindFirstChild("CentralCapacitor")
	local dischargeSound = Instance.new("Sound")
	dischargeSound.Name = "ElectrostaticDischarge"
	dischargeSound.SoundId = "rbxassetid://12222084"
	dischargeSound.Volume = 0.15
	dischargeSound.RollOffMaxDistance = 120
	dischargeSound.RollOffMinDistance = 10
	dischargeSound.RollOffMode = Enum.RollOffMode.LinearSquare
	dischargeSound.Parent = centralCapPart or building

	-- Adjacency check: tower idx has neighbors (idx-1) and (idx+1) on octagon
	local function hasAdjacentWorkingEmitter(idx)
		if not emitterStates then return true end
		local prev = ((idx - 2) % 8) + 1
		local next = (idx % 8) + 1
		return emitterStates[prev] or emitterStates[next]
	end

	task.spawn(function()
		local arcRng = Random.new(SEED + 77)

		while building and building.Parent do
			-- Faster discharge interval (2-6 seconds, was 4-12)
			task.wait(arcRng:NextNumber(2, 6))

			if not building or not building.Parent then break end

			-- Pick 1-3 random beams to fire simultaneously
			-- Only fire if: emitter is active AND has adjacent working emitter
			local fireCount = arcRng:NextInteger(1, math.min(3, #beams))
			local fireIndices = {}
			for _ = 1, fireCount do
				local idx = arcRng:NextInteger(1, #beams)
				if (not emitterStates or emitterStates[idx]) and hasAdjacentWorkingEmitter(idx) then
					fireIndices[idx] = true
				end
			end

			-- Skip if no beams to fire
			local hasAny = false
			for _ in pairs(fireIndices) do hasAny = true; break end
			if not hasAny then continue end

			-- Play sound only if a player is near the building on the surface
			local soundPos = dischargeSound.Parent and dischargeSound.Parent:IsA("BasePart")
				and dischargeSound.Parent.Position or nil
			if soundPos then
				local anyNear = false
				for _, player in ipairs(Players:GetPlayers()) do
					local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if hrp and (hrp.Position - soundPos).Magnitude < 150 then
						anyNear = true
						break
					end
				end
				if anyNear then
					dischargeSound.PlaybackSpeed = arcRng:NextNumber(1.8, 2.8)
					dischargeSound:Play()
				end
			end

			-- Burst: 3-6 rapid flickers over 0.3-1.0 seconds
			local flickerCount = arcRng:NextInteger(3, 6)
			for f = 1, flickerCount do
				for idx in pairs(fireIndices) do
					local beam = beams[idx]
					if not beam or not beam.Parent then continue end

					-- Jagged lightning shape — large random curves
					beam.CurveSize0 = arcRng:NextNumber(-20, 20)
					beam.CurveSize1 = arcRng:NextNumber(-20, 20)

					-- Bright flash
					beam.Enabled = true
					beam.Width0 = arcRng:NextNumber(1.0, 3.0)
					beam.Width1 = arcRng:NextNumber(0.3, 1.5)
					beam.Transparency = NumberSequence.new(arcRng:NextNumber(0, 0.2))
				end

				-- Brief flash duration
				task.wait(arcRng:NextNumber(0.04, 0.10))

				-- Momentary off between flickers (looks like re-strike)
				if f < flickerCount then
					for idx in pairs(fireIndices) do
						local beam = beams[idx]
						if beam and beam.Parent then
							beam.Enabled = false
						end
					end
					task.wait(arcRng:NextNumber(0.03, 0.08))
				end
			end

			-- All off after burst
			for idx in pairs(fireIndices) do
				local beam = beams[idx]
				if beam and beam.Parent then
					beam.Enabled = false
				end
			end

			-- Each fired auxiliary discharge adds 2-12% charge to main emitter
			for _ in pairs(fireIndices) do
				mainCharge = mainCharge + arcRng:NextInteger(2, 12)
			end

			-- Fire main vertical lightning when charge reaches 100%
			if mainCharge >= 100 and fireBoltFunc then
				mainCharge = 0
				fireBoltFunc()
			end
		end
	end)

	print(string.format("[%s] Auxiliary discharge system active (%d beams, charge-based main bolt)", MODULE_NAME, #beams))
end

-- ============================================================================
-- STEP 9: VERTICAL LIGHTNING BOLT (triggered by charge, not timer)
-- ============================================================================

local function SetupVerticalLightning(building, centralCapacitor)
	if not building or not centralCapacitor then return nil end

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

	-- Main lightning bolt beam (initially disabled)
	local bolt = Instance.new("Beam")
	bolt.Name = "VerticalLightning"
	bolt.Attachment0 = capAttach
	bolt.Attachment1 = skyAttach
	bolt.Color = ColorSequence.new(
		Color3.fromRGB(140, 210, 255),
		Color3.fromRGB(255, 255, 255)
	)
	bolt.Width0 = 4
	bolt.Width1 = 0.3
	bolt.Segments = 50
	bolt.FaceCamera = true
	bolt.LightEmission = 1
	bolt.LightInfluence = 0
	bolt.Transparency = NumberSequence.new(0)
	bolt.Enabled = false
	bolt.Parent = building

	-- Secondary thinner bolt (branch lightning)
	local bolt2 = Instance.new("Beam")
	bolt2.Name = "VerticalLightning2"
	bolt2.Attachment0 = capAttach
	bolt2.Attachment1 = skyAttach
	bolt2.Color = ColorSequence.new(
		Color3.fromRGB(180, 220, 255),
		Color3.fromRGB(220, 240, 255)
	)
	bolt2.Width0 = 1.5
	bolt2.Width1 = 0.1
	bolt2.Segments = 40
	bolt2.FaceCamera = true
	bolt2.LightEmission = 1
	bolt2.LightInfluence = 0
	bolt2.Transparency = NumberSequence.new(0.3)
	bolt2.Enabled = false
	bolt2.Parent = building

	-- Flash light on the capacitor (large radius for dramatic effect)
	local flash = Instance.new("PointLight")
	flash.Name = "LightningFlash"
	flash.Color = Color3.fromRGB(160, 220, 255)
	flash.Brightness = 0
	flash.Range = 200
	flash.Parent = centralCapacitor

	-- Thunder sound
	local thunder = Instance.new("Sound")
	thunder.Name = "Thunder"
	thunder.SoundId = "rbxassetid://12222084"  -- Roblox thunder sound
	thunder.Volume = 2.5
	thunder.RollOffMaxDistance = 600
	thunder.RollOffMinDistance = 50
	thunder.Parent = centralCapacitor

	local boltRng = Random.new(SEED + 55)

	-- Return a function that fires the bolt on demand (called when charge ≥100%)
	local function FireBolt()
		if not building or not building.Parent then return end

		-- Multiple re-strikes (2-4 bolts in rapid succession, like real lightning)
		local strikeCount = boltRng:NextInteger(2, 4)

		for strike = 1, strikeCount do
			-- Randomize bolt shape — large jagged curves
			bolt.CurveSize0 = boltRng:NextNumber(-30, 30)
			bolt.CurveSize1 = boltRng:NextNumber(-30, 30)
			bolt.Width0 = boltRng:NextNumber(3, 7)
			bolt.Width1 = boltRng:NextNumber(0.2, 0.8)

			-- Branch bolt with different curve (offset path)
			bolt2.CurveSize0 = boltRng:NextNumber(-25, 25)
			bolt2.CurveSize1 = boltRng:NextNumber(-25, 25)

			-- FLASH: both bolts + light burst
			bolt.Enabled = true
			bolt2.Enabled = true
			flash.Brightness = boltRng:NextNumber(5, 10)

			-- Play thunder on first strike
			if strike == 1 then
				thunder.PlaybackSpeed = boltRng:NextNumber(0.7, 1.3)
				thunder:Play()
			end

			-- Brief bright hold with jitter
			local holdTime = boltRng:NextNumber(0.05, 0.15)
			local flickerEnd = os.clock() + holdTime
			while os.clock() < flickerEnd do
				bolt.CurveSize0 = boltRng:NextNumber(-35, 35)
				bolt.CurveSize1 = boltRng:NextNumber(-35, 35)
				bolt.Transparency = NumberSequence.new(boltRng:NextNumber(0, 0.15))
				flash.Brightness = boltRng:NextNumber(3, 10)
				task.wait(0.03)
			end

			-- Off between re-strikes
			bolt.Enabled = false
			bolt2.Enabled = false
			flash.Brightness = 0

			if strike < strikeCount then
				task.wait(boltRng:NextNumber(0.05, 0.20))
			end
		end

		-- Slow flash fade out (afterglow)
		flash.Brightness = 1
		TweenService:Create(flash,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Brightness = 0 }
		):Play()
	end

	print(string.format("[%s] Vertical lightning system ready (charge-triggered)", MODULE_NAME))
	return FireBolt
end

-- ============================================================================
-- STEP 10: FRACTAL TREES (cylindrical, turquoise-agate leaves)
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

		-- Building exclusion (circular zone + entrance paths)
		if buildingCenter then
			local exclR = BUILDING_RADIUS + TREE_BUILDING_MARGIN
			if IsInsideCircle(tx, tz, buildingCenter.x, buildingCenter.z, exclR) then
				continue
			end
			-- Front entrance path (X- direction)
			if IsInsideRect(tx, tz,
				buildingCenter.x - BUILDING_RADIUS - TREE_ENTRANCE_LENGTH,
				buildingCenter.z - TREE_ENTRANCE_WIDTH / 2,
				buildingCenter.x - BUILDING_RADIUS,
				buildingCenter.z + TREE_ENTRANCE_WIDTH / 2) then
				continue
			end
			-- Back entrance path (X+ direction)
			if IsInsideRect(tx, tz,
				buildingCenter.x + BUILDING_RADIUS,
				buildingCenter.z - TREE_ENTRANCE_WIDTH / 2,
				buildingCenter.x + BUILDING_RADIUS + TREE_ENTRANCE_LENGTH,
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
-- LIFECYCLE: levelInit / levelFini
-- ============================================================================

function TerrainGenerator.levelInit()
	print(string.format("[%s %s] Starting generation (seed=%d)", MODULE_NAME, VERSION, SEED))

	-- Reset module state
	rng = Random.new(SEED)
	barePatches = {}
	buildingCenter = nil

	proceduralFolder = Instance.new("Folder")
	proceduralFolder.Name = "ProceduralContent"
	proceduralFolder.Parent = Workspace

	fbm = FastNoise.FBM.create({
		octaves = OCTAVES,
		lacunarity = LACUNARITY,
		persistence = PERSISTENCE,
	})

	-- Generate world
	GenerateBarePatches()
	PickBuildingPosition()
	GenerateTerrain()
	task.wait()
	local building, doorData, domeSymbolLabels, dischargeBeams, centralCap, towerSpires, wallNeonTrims = CreateBuilding()
	task.wait()

	-- Setup interactive systems
	SetupDoorSystem(building, doorData)
	SetupDomeSymbolAnimation(building, domeSymbolLabels)
	local emitterStates = SetupEmitterMalfunction(building, towerSpires, wallNeonTrims)
	local fireBolt = SetupVerticalLightning(building, centralCap)
	SetupElectricDischarges(building, dischargeBeams, emitterStates, fireBolt)
	PlantTrees()

	print(string.format("[%s %s] Generation complete", MODULE_NAME, VERSION))
end

function TerrainGenerator.levelFini()
	print(string.format("[%s %s] Cleaning up", MODULE_NAME, VERSION))

	-- Destroy procedural content (stops all while-loops checking building.Parent)
	if proceduralFolder then
		proceduralFolder:Destroy()
		proceduralFolder = nil
	end

	-- Clear generated terrain
	terrain:Clear()

	-- Reset state
	barePatches = nil
	buildingCenter = nil
	rng = nil
	fbm = nil
end

return TerrainGenerator
