--[[
================================================================================
KOSMICMAZER — TerrainGenerator
================================================================================

Purpose:
Procedural terrain generation for ExplorationZone using FastNoise FBM.
Auto-runs when LocationService copies it to ServerScriptService.

Version:
0.1

Features:
- FBM noise-based heightmap generation
- Grass terrain with gentle hills
- Skips LandingZone (X < 260)
- Smooth height transition near zone border
- Configurable seed, frequency, height

Dependencies:
- FastNoise (ReplicatedStorage/Game/FastNoise)
- Workspace.Terrain

ChangeLog:
- 0.1: Initial procedural terrain with FBM noise (2026-02-06)
================================================================================
]]

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local SEED = 42
local FREQUENCY = 0.008       -- Noise scale (lower = wider hills)
local MAX_HEIGHT = 12          -- Max hill height in studs
local MIN_HEIGHT = 1           -- Minimum terrain thickness
local GRID_STEP = 4            -- Terrain voxel resolution (4 studs)
local OCTAVES = 4
local LACUNARITY = 2.0
local PERSISTENCE = 0.5

-- Zone bounds
local ZONE_MIN_X = 260         -- ExplorationZone starts here
local ZONE_MAX_X = 1024
local ZONE_MIN_Z = 0
local ZONE_MAX_Z = 1024
local BASE_Y = 1               -- Just above baseplate (Y=0.5)

-- Smooth transition from LandingZone border
local FADE_WIDTH = 40           -- Studs of gradual height increase

-- ============================================================================
-- SERVICES
-- ============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Wait for workspace models to be copied by LocationService
task.wait(1)

local FastNoise = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("FastNoise"))

local terrain = Workspace.Terrain

-- Create FBM noise generator
local fbm = FastNoise.FBM.create({
	octaves = OCTAVES,
	lacunarity = LACUNARITY,
	persistence = PERSISTENCE,
})

-- ============================================================================
-- TERRAIN GENERATION
-- ============================================================================

local startTime = os.clock()
local blocksGenerated = 0

-- Clear existing terrain in the zone
terrain:FillRegion(
	Region3.new(
		Vector3.new(ZONE_MIN_X, BASE_Y, ZONE_MIN_Z),
		Vector3.new(ZONE_MAX_X, BASE_Y + MAX_HEIGHT + 10, ZONE_MAX_Z)
	):ExpandToGrid(4),
	4,
	Enum.Material.Air
)

-- Generate terrain
for x = ZONE_MIN_X, ZONE_MAX_X - GRID_STEP, GRID_STEP do
	for z = ZONE_MIN_Z, ZONE_MAX_Z - GRID_STEP, GRID_STEP do
		-- Sample noise at this point
		local noiseValue = fbm.noise2D(x * FREQUENCY, z * FREQUENCY, SEED)

		-- Normalize from [-1,1] to [0,1]
		local normalized = FastNoise.normalize(noiseValue)

		-- Calculate height
		local height = MIN_HEIGHT + normalized * MAX_HEIGHT

		-- Fade near LandingZone border (smooth transition)
		local distFromBorder = x - ZONE_MIN_X
		if distFromBorder < FADE_WIDTH then
			local fade = distFromBorder / FADE_WIDTH
			height = height * fade
		end

		-- Skip very thin terrain
		if height > 0.5 then
			terrain:FillBlock(
				CFrame.new(x + GRID_STEP / 2, BASE_Y + height / 2, z + GRID_STEP / 2),
				Vector3.new(GRID_STEP, height, GRID_STEP),
				Enum.Material.Grass
			)
			blocksGenerated += 1
		end
	end

	-- Yield every row to prevent script timeout
	if x % 32 == 0 then
		task.wait()
	end
end

local elapsed = os.clock() - startTime
print(string.format("[TerrainGenerator 0.1] Generated %d blocks in %.2fs (seed=%d)",
	blocksGenerated, elapsed, SEED))
