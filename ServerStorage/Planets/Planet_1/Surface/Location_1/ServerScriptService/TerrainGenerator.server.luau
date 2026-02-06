--[[
================================================================================
KOSMICMAZER — LocationGenerator (Location_1)
================================================================================

Purpose:
Procedural content generation for Location_1 "Візитка" surface.
Generates terrain, bare patches, alien temple, and fractal trees.

Version:
0.2

Features:
- FBM noise terrain with gentle hills (3x lower than v0.1)
- Random bare patches (4-24 clearings without grass)
- Futuristic temple building (alien orthodox church style with dome)
- Fractal trees with trunks and branches (20-80 trees)
- Deterministic seed-based generation
- Building exclusion zones for terrain and trees
- Clear entrance paths to building

Dependencies:
- FastNoise (ReplicatedStorage/Game/FastNoise)
- Workspace.Terrain

ChangeLog:
- 0.2: Bare patches, alien temple, fractal trees, lower terrain (2026-02-06)
- 0.1: Initial procedural terrain with FBM noise (2026-02-06)
================================================================================
]]

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local SEED = 42
local MODULE_NAME = "LocationGenerator"
local VERSION = "0.2"

-- Terrain
local FREQUENCY = 0.008
local MAX_HEIGHT = 4             -- Was 12, now 3x lower
local MIN_HEIGHT = 0.3
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
local BUILDING_W = 40
local BUILDING_D = 30
local BUILDING_CLEARANCE = 8

-- Trees
local TREES_MIN = 20
local TREES_MAX = 80
local TREE_MIN_SPACING = 12
local TREE_BUILDING_MARGIN = 15
local TREE_ENTRANCE_LENGTH = 20
local TREE_ENTRANCE_WIDTH = 12
local TREE_BRANCH_DEPTH = 2

-- ============================================================================
-- SERVICES
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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

local function AlignPartY(midPos, direction)
	if math.abs(direction.Y) > 0.999 then
		if direction.Y > 0 then
			return CFrame.new(midPos)
		else
			return CFrame.new(midPos) * CFrame.Angles(math.pi, 0, 0)
		end
	end
	local worldUp = Vector3.new(0, 1, 0)
	local right = direction:Cross(worldUp).Unit
	return CFrame.fromMatrix(midPos, right, direction)
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

			if height > 0.5 then
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
-- STEP 4: BUILDING — Futuristic Alien Temple
-- ============================================================================

local function CreateBuilding()
	if not buildingCenter then return nil end

	local building = Instance.new("Model")
	building.Name = "AncientTemple"

	local cx = buildingCenter.x
	local cz = buildingCenter.z
	local floorY = GROUND_Y

	local W = BUILDING_W
	local D = BUILDING_D
	local WH = 16
	local WT = 3
	local DOOR_W = 8
	local DOOR_H = 12
	local WIN_W = 3
	local WIN_H = 8
	local halfW = W / 2
	local halfD = D / 2
	local innerW = W - 2 * WT

	-- Colors
	local C_WALL = Color3.fromRGB(175, 175, 185)
	local C_DOME = Color3.fromRGB(195, 165, 55)
	local C_NEON = Color3.fromRGB(0, 220, 255)
	local C_FLOOR = Color3.fromRGB(55, 60, 70)
	local C_GLASS = Color3.fromRGB(20, 160, 200)
	local C_PILLAR = Color3.fromRGB(150, 150, 165)
	local C_TOWER = Color3.fromRGB(165, 165, 175)

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
	MP("FrontWall_L", Vector3.new(WT, WH, sideSegZ),
		Vector3.new(cx - halfW + WT / 2, floorY + WH / 2 + 0.5, cz - halfD + sideSegZ / 2), C_WALL)
	MP("FrontWall_R", Vector3.new(WT, WH, sideSegZ),
		Vector3.new(cx - halfW + WT / 2, floorY + WH / 2 + 0.5, cz + halfD - sideSegZ / 2), C_WALL)
	MP("FrontWall_Top", Vector3.new(WT, WH - DOOR_H, DOOR_W),
		Vector3.new(cx - halfW + WT / 2, floorY + DOOR_H + (WH - DOOR_H) / 2 + 0.5, cz), C_WALL)

	-- ======= BACK WALL (X+ face) with door =======
	MP("BackWall_L", Vector3.new(WT, WH, sideSegZ),
		Vector3.new(cx + halfW - WT / 2, floorY + WH / 2 + 0.5, cz - halfD + sideSegZ / 2), C_WALL)
	MP("BackWall_R", Vector3.new(WT, WH, sideSegZ),
		Vector3.new(cx + halfW - WT / 2, floorY + WH / 2 + 0.5, cz + halfD - sideSegZ / 2), C_WALL)
	MP("BackWall_Top", Vector3.new(WT, WH - DOOR_H, DOOR_W),
		Vector3.new(cx + halfW - WT / 2, floorY + DOOR_H + (WH - DOOR_H) / 2 + 0.5, cz), C_WALL)

	-- ======= SIDE WALLS (Z- and Z+ faces) with windows =======
	-- Window positions at X offsets from center
	local winX1 = cx - innerW / 4
	local winX2 = cx + innerW / 4
	local winSillY = floorY + 6 + 0.5
	local wallStartX = cx - innerW / 2
	local wallEndX = cx + innerW / 2

	-- Segment widths around windows
	local seg1W = (winX1 - WIN_W / 2) - wallStartX
	local seg2W = (winX2 - WIN_W / 2) - (winX1 + WIN_W / 2)
	local seg3W = wallEndX - (winX2 + WIN_W / 2)
	local bottomH = winSillY - floorY - 0.5
	local topH = (floorY + WH + 0.5) - (winSillY + WIN_H)

	-- Build both side walls (Z- and Z+)
	for _, side in ipairs({ { z = cz - halfD + WT / 2, prefix = "Left" }, { z = cz + halfD - WT / 2, prefix = "Right" } }) do
		-- Bottom strip
		MP(side.prefix .. "Wall_Bottom", Vector3.new(innerW, bottomH, WT),
			Vector3.new(cx, floorY + bottomH / 2 + 0.5, side.z), C_WALL)
		-- Top strip
		MP(side.prefix .. "Wall_Top", Vector3.new(innerW, topH, WT),
			Vector3.new(cx, winSillY + WIN_H + topH / 2, side.z), C_WALL)
		-- Pillars between windows
		MP(side.prefix .. "Wall_P1", Vector3.new(seg1W, WIN_H, WT),
			Vector3.new(wallStartX + seg1W / 2, winSillY + WIN_H / 2, side.z), C_WALL)
		MP(side.prefix .. "Wall_P2", Vector3.new(seg2W, WIN_H, WT),
			Vector3.new(winX1 + WIN_W / 2 + seg2W / 2, winSillY + WIN_H / 2, side.z), C_WALL)
		MP(side.prefix .. "Wall_P3", Vector3.new(seg3W, WIN_H, WT),
			Vector3.new(winX2 + WIN_W / 2 + seg3W / 2, winSillY + WIN_H / 2, side.z), C_WALL)
		-- Window glass
		MP(side.prefix .. "Win1", Vector3.new(WIN_W, WIN_H, 0.5),
			Vector3.new(winX1, winSillY + WIN_H / 2, side.z), C_GLASS, Enum.Material.Glass, 0.4)
		MP(side.prefix .. "Win2", Vector3.new(WIN_W, WIN_H, 0.5),
			Vector3.new(winX2, winSillY + WIN_H / 2, side.z), C_GLASS, Enum.Material.Glass, 0.4)
	end

	-- ======= NEON TRIM (top edge of walls) =======
	local neonH = 0.5
	local wallTopY = floorY + WH + 0.5 + neonH / 2
	MP("NeonTrim_Front", Vector3.new(WT + 0.4, neonH, D + 0.4),
		Vector3.new(cx - halfW + WT / 2, wallTopY, cz), C_NEON, Enum.Material.Neon)
	MP("NeonTrim_Back", Vector3.new(WT + 0.4, neonH, D + 0.4),
		Vector3.new(cx + halfW - WT / 2, wallTopY, cz), C_NEON, Enum.Material.Neon)
	MP("NeonTrim_Left", Vector3.new(innerW, neonH, WT + 0.4),
		Vector3.new(cx, wallTopY, cz - halfD + WT / 2), C_NEON, Enum.Material.Neon)
	MP("NeonTrim_Right", Vector3.new(innerW, neonH, WT + 0.4),
		Vector3.new(cx, wallTopY, cz + halfD - WT / 2), C_NEON, Enum.Material.Neon)

	-- ======= MAIN DOME =======
	local drumH = 4
	local drumDiam = 16
	local drumPart = Instance.new("Part")
	drumPart.Name = "DomeDrum"
	drumPart.Shape = Enum.PartType.Cylinder
	drumPart.Size = Vector3.new(drumH, drumDiam, drumDiam)
	drumPart.CFrame = CFrame.new(cx, floorY + WH + 0.5 + drumH / 2, cz) * CFrame.Angles(0, 0, math.rad(90))
	drumPart.Anchored = true
	drumPart.Color = C_WALL
	drumPart.Material = Enum.Material.SmoothPlastic
	drumPart.Parent = building

	-- Dome sphere (elongated for onion shape)
	local domePart = Instance.new("Part")
	domePart.Name = "MainDome"
	domePart.Shape = Enum.PartType.Ball
	domePart.Size = Vector3.new(18, 22, 18)
	domePart.Position = Vector3.new(cx, floorY + WH + 0.5 + drumH + 8, cz)
	domePart.Anchored = true
	domePart.Color = C_DOME
	domePart.Material = Enum.Material.Glass
	domePart.Transparency = 0.2
	domePart.Parent = building

	-- Dome spire
	MP("DomeSpire", Vector3.new(1, 6, 1),
		Vector3.new(cx, floorY + WH + 0.5 + drumH + 22, cz), C_NEON, Enum.Material.Neon)

	-- ======= CORNER TOWERS =======
	local towerH = 18
	local towerR = 3
	local towerDomeSize = 8
	local tox = halfW - 2
	local toz = halfD - 2

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

		-- Tower dome
		local td = Instance.new("Part")
		td.Name = "TowerDome_" .. i
		td.Shape = Enum.PartType.Ball
		td.Size = Vector3.new(towerDomeSize, towerDomeSize * 1.3, towerDomeSize)
		td.Position = Vector3.new(pos[1], floorY + towerH + 0.5 + towerDomeSize * 0.4, pos[2])
		td.Anchored = true
		td.Color = C_DOME
		td.Material = Enum.Material.Glass
		td.Transparency = 0.2
		td.Parent = building

		-- Tower spire
		MP("TowerSpire_" .. i, Vector3.new(0.6, 4, 0.6),
			Vector3.new(pos[1], floorY + towerH + 0.5 + towerDomeSize * 1.2, pos[2]), C_NEON, Enum.Material.Neon)
	end

	-- ======= INTERIOR =======
	local pox = innerW / 4
	local poz = (D - 2 * WT) / 4
	local pillarPositions = {
		{ cx - pox, cz - poz }, { cx - pox, cz + poz },
		{ cx + pox, cz - poz }, { cx + pox, cz + poz },
	}

	for i, pos in ipairs(pillarPositions) do
		MP("Pillar_" .. i, Vector3.new(2, WH, 2),
			Vector3.new(pos[1], floorY + WH / 2 + 0.5, pos[2]), C_PILLAR)
		MP("PillarNeon_" .. i, Vector3.new(2.5, 0.3, 2.5),
			Vector3.new(pos[1], floorY + WH + 0.2, pos[2]), C_NEON, Enum.Material.Neon)
	end

	-- Central pedestal (for future artifact)
	MP("Pedestal", Vector3.new(4, 3, 4), Vector3.new(cx, floorY + 2, cz), C_PILLAR)
	MP("PedestalNeon", Vector3.new(4.5, 0.3, 4.5),
		Vector3.new(cx, floorY + 3.65, cz), C_NEON, Enum.Material.Neon)

	-- ======= ENTRANCE FRAMES =======
	MP("FrontArch", Vector3.new(1, DOOR_H + 2, DOOR_W + 2),
		Vector3.new(cx - halfW - 0.5, floorY + (DOOR_H + 2) / 2 + 0.5, cz), C_NEON, Enum.Material.Neon)
	MP("BackArch", Vector3.new(1, DOOR_H + 2, DOOR_W + 2),
		Vector3.new(cx + halfW + 0.5, floorY + (DOOR_H + 2) / 2 + 0.5, cz), C_NEON, Enum.Material.Neon)

	building.Parent = proceduralFolder
	print(string.format("[%s] Temple created at (%.0f, %.0f) — %d parts",
		MODULE_NAME, cx, cz, #building:GetChildren()))
	return building
end

-- ============================================================================
-- STEP 5: FRACTAL TREES
-- ============================================================================

local function CreateFractalTree(rootPosition)
	local tree = Instance.new("Model")
	tree.Name = "FractalTree"

	local trunkHeight = rng:NextNumber(8, 14)
	local trunkThickness = rng:NextNumber(1.5, 2.5)

	local function CreateBranch(startPos, direction, length, thickness, depth)
		local endPos = startPos + direction * length
		local midPos = startPos + direction * (length / 2)

		local branch = Instance.new("Part")
		branch.Name = depth == 0 and "Trunk" or "Branch"
		branch.Size = Vector3.new(thickness, length, thickness)
		branch.CFrame = AlignPartY(midPos, direction)
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
			for _ = 1, numBranches do
				local angle = math.rad(rng:NextInteger(25, 50))
				local spin = math.rad(rng:NextInteger(0, 359))

				local perp = GetPerpendicular(direction)
				local tilted = RotateVector(direction, perp, angle)
				local newDir = RotateVector(tilted, direction, spin)

				CreateBranch(endPos, newDir.Unit, length * 0.6, thickness * 0.55, depth + 1)
			end
		else
			-- Leaf cluster
			local leaf = Instance.new("Part")
			leaf.Name = "Leaves"
			leaf.Shape = Enum.PartType.Ball
			local leafSize = 3 + rng:NextNumber(0, 3)
			leaf.Size = Vector3.new(leafSize, leafSize * 0.8, leafSize)
			leaf.Position = endPos
			leaf.Anchored = true
			leaf.CanCollide = false
			leaf.Material = Enum.Material.Grass
			leaf.Color = Color3.fromRGB(
				34 + rng:NextInteger(-10, 20),
				100 + rng:NextInteger(-15, 40),
				42 + rng:NextInteger(-10, 15)
			)
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
CreateBuilding()
task.wait()
PlantTrees()

print(string.format("[%s %s] Generation complete", MODULE_NAME, VERSION))
