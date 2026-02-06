--!strict
--!optimize 2
--!native

--[[
	Worley (Cellular) Noise Module
	Creates cell-like patterns based on distance to feature points
]]

local Worley = {}
Worley.__index = Worley

export type DistanceFunction = "Euclidean" | "Manhattan" | "Chebyshev"
export type ReturnType = "F1" | "F2" | "F2MinusF1" | "F1PlusF2"

export type WorleyConfig = {
	frequency: number?,
	distanceFunction: DistanceFunction?,
	returnType: ReturnType?,
	jitter: number?,
}

local DEFAULT_CONFIG: WorleyConfig = {
	frequency = 1.0,
	distanceFunction = "Euclidean",
	returnType = "F1",
	jitter = 1.0,
}

local PERM = {
	151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,
	8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,
	35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,
	134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,
	55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,
	18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,
	250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,
	189,28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,
	172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,
	228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,
	107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,
	138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
}

local function fastFloor(x: number): number
	local xi = x // 1
	return if x < xi then xi - 1 else xi
end

local function hash2D(x: number, y: number, seed: number): number
	return PERM[((PERM[((x + seed) % 256) + 1] + y) % 256) + 1]
end

local function hash3D(x: number, y: number, z: number, seed: number): number
	return PERM[((PERM[((PERM[((x + seed) % 256) + 1] + y) % 256) + 1] + z) % 256) + 1]
end

local function getFeaturePoint2D(cellX: number, cellY: number, seed: number, jitter: number): (number, number)
	local h = hash2D(cellX, cellY, seed)
	local h2 = hash2D(cellX + 1000, cellY + 1000, seed)
	
	local fx = cellX + 0.5 + (h / 255 - 0.5) * jitter
	local fy = cellY + 0.5 + (h2 / 255 - 0.5) * jitter
	
	return fx, fy
end

local function getFeaturePoint3D(cellX: number, cellY: number, cellZ: number, seed: number, jitter: number): (number, number, number)
	local h = hash3D(cellX, cellY, cellZ, seed)
	local h2 = hash3D(cellX + 1000, cellY + 1000, cellZ, seed)
	local h3 = hash3D(cellX, cellY + 1000, cellZ + 1000, seed)
	
	local fx = cellX + 0.5 + (h / 255 - 0.5) * jitter
	local fy = cellY + 0.5 + (h2 / 255 - 0.5) * jitter
	local fz = cellZ + 0.5 + (h3 / 255 - 0.5) * jitter
	
	return fx, fy, fz
end

local function euclideanDistance2D(dx: number, dy: number): number
	return math.sqrt(dx * dx + dy * dy)
end

local function manhattanDistance2D(dx: number, dy: number): number
	return math.abs(dx) + math.abs(dy)
end

local function chebyshevDistance2D(dx: number, dy: number): number
	return math.max(math.abs(dx), math.abs(dy))
end

local function euclideanDistance3D(dx: number, dy: number, dz: number): number
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function manhattanDistance3D(dx: number, dy: number, dz: number): number
	return math.abs(dx) + math.abs(dy) + math.abs(dz)
end

local function chebyshevDistance3D(dx: number, dy: number, dz: number): number
	return math.max(math.abs(dx), math.abs(dy), math.abs(dz))
end

local function getDistanceFunc2D(distType: DistanceFunction): (number, number) -> number
	if distType == "Manhattan" then
		return manhattanDistance2D
	elseif distType == "Chebyshev" then
		return chebyshevDistance2D
	end
	return euclideanDistance2D
end

local function getDistanceFunc3D(distType: DistanceFunction): (number, number, number) -> number
	if distType == "Manhattan" then
		return manhattanDistance3D
	elseif distType == "Chebyshev" then
		return chebyshevDistance3D
	end
	return euclideanDistance3D
end

--[[
	2D Worley Noise
	@param x - X coordinate
	@param y - Y coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional Worley configuration
	@return Noise value between 0 and 1
]]
function Worley.noise2D(x: number, y: number, seed: number?, config: WorleyConfig?): number
	seed = seed or 0
	local cfg = config or DEFAULT_CONFIG
	
	local frequency = cfg.frequency or DEFAULT_CONFIG.frequency :: number
	local distanceFunction = cfg.distanceFunction or DEFAULT_CONFIG.distanceFunction :: DistanceFunction
	local returnType = cfg.returnType or DEFAULT_CONFIG.returnType :: ReturnType
	local jitter = cfg.jitter or DEFAULT_CONFIG.jitter :: number
	
	x = x * frequency
	y = y * frequency
	
	local cellX = fastFloor(x)
	local cellY = fastFloor(y)
	
	local distFunc = getDistanceFunc2D(distanceFunction)
	
	local f1 = math.huge
	local f2 = math.huge
	
	for dy = -1, 1 do
		for dx = -1, 1 do
			local ncx = cellX + dx
			local ncy = cellY + dy
			
			local fx, fy = getFeaturePoint2D(ncx, ncy, seed, jitter)
			local dist = distFunc(x - fx, y - fy)
			
			if dist < f1 then
				f2 = f1
				f1 = dist
			elseif dist < f2 then
				f2 = dist
			end
		end
	end
	
	local result: number
	if returnType == "F2" then
		result = f2
	elseif returnType == "F2MinusF1" then
		result = f2 - f1
	elseif returnType == "F1PlusF2" then
		result = (f1 + f2) * 0.5
	else -- F1
		result = f1
	end
	
	return math.clamp(result, 0, 1)
end

--[[
	3D Worley Noise
	@param x - X coordinate
	@param y - Y coordinate
	@param z - Z coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional Worley configuration
	@return Noise value between 0 and 1
]]
function Worley.noise3D(x: number, y: number, z: number, seed: number?, config: WorleyConfig?): number
	seed = seed or 0
	local cfg = config or DEFAULT_CONFIG
	
	local frequency = cfg.frequency or DEFAULT_CONFIG.frequency :: number
	local distanceFunction = cfg.distanceFunction or DEFAULT_CONFIG.distanceFunction :: DistanceFunction
	local returnType = cfg.returnType or DEFAULT_CONFIG.returnType :: ReturnType
	local jitter = cfg.jitter or DEFAULT_CONFIG.jitter :: number
	
	x = x * frequency
	y = y * frequency
	z = z * frequency
	
	local cellX = fastFloor(x)
	local cellY = fastFloor(y)
	local cellZ = fastFloor(z)
	
	local distFunc = getDistanceFunc3D(distanceFunction)
	
	local f1 = math.huge
	local f2 = math.huge
	
	for dz = -1, 1 do
		for dy = -1, 1 do
			for dx = -1, 1 do
				local ncx = cellX + dx
				local ncy = cellY + dy
				local ncz = cellZ + dz
				
				local fx, fy, fz = getFeaturePoint3D(ncx, ncy, ncz, seed, jitter)
				local dist = distFunc(x - fx, y - fy, z - fz)
				
				if dist < f1 then
					f2 = f1
					f1 = dist
				elseif dist < f2 then
					f2 = dist
				end
			end
		end
	end
	
	local result: number
	if returnType == "F2" then
		result = f2
	elseif returnType == "F2MinusF1" then
		result = f2 - f1
	elseif returnType == "F1PlusF2" then
		result = (f1 + f2) * 0.5
	else -- F1
		result = f1
	end
	
	return math.clamp(result, 0, 1)
end

--[[
	Create a configured Worley generator
	@param config - Worley configuration
	@return Table with configured noise2D and noise3D functions
]]
function Worley.create(config: WorleyConfig)
	return {
		noise2D = function(x: number, y: number, seed: number?): number
			return Worley.noise2D(x, y, seed, config)
		end,
		noise3D = function(x: number, y: number, z: number, seed: number?): number
			return Worley.noise3D(x, y, z, seed, config)
		end,
	}
end

return Worley
