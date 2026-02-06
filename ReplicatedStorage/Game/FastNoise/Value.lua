--!strict
--!optimize 2
--!native

--[[
	Value Noise Module
	Value noise uses random values at lattice points with interpolation
]]

local Value = {}
Value.__index = Value

local p = {
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

local perm = table.create(512)
for i = 0, 511 do
	perm[i] = p[(i % 256) + 1]
end

local function fade(t: number): number
	return t * t * t * (t * (t * 6 - 15) + 10)
end

local function lerp(a: number, b: number, t: number): number
	return a + t * (b - a)
end

local function fastFloor(x: number): number
	local xi = x // 1
	return if x < xi then xi - 1 else xi
end

local function hash2D(x: number, y: number, seed: number): number
	local h = perm[(perm[(x + seed) % 256] + y) % 256]
	return (h / 255) * 2 - 1
end

local function hash3D(x: number, y: number, z: number, seed: number): number
	local h = perm[(perm[(perm[(x + seed) % 256] + y) % 256] + z) % 256]
	return (h / 255) * 2 - 1
end

--[[
	2D Value Noise
	@param x - X coordinate
	@param y - Y coordinate
	@param seed - Optional seed value (default 0)
	@return Noise value between -1 and 1
]]
function Value.noise2D(x: number, y: number, seed: number?): number
	seed = seed or 0
	
	local X = fastFloor(x)
	local Y = fastFloor(y)
	
	local xf = x - X
	local yf = y - Y
	
	local u = fade(xf)
	local v = fade(yf)
	
	local n00 = hash2D(X, Y, seed)
	local n10 = hash2D(X + 1, Y, seed)
	local n01 = hash2D(X, Y + 1, seed)
	local n11 = hash2D(X + 1, Y + 1, seed)
	
	local nx0 = lerp(n00, n10, u)
	local nx1 = lerp(n01, n11, u)
	
	return lerp(nx0, nx1, v)
end

--[[
	3D Value Noise
	@param x - X coordinate
	@param y - Y coordinate
	@param z - Z coordinate
	@param seed - Optional seed value (default 0)
	@return Noise value between -1 and 1
]]
function Value.noise3D(x: number, y: number, z: number, seed: number?): number
	seed = seed or 0
	
	local X = fastFloor(x)
	local Y = fastFloor(y)
	local Z = fastFloor(z)
	
	local xf = x - X
	local yf = y - Y
	local zf = z - Z
	
	local u = fade(xf)
	local v = fade(yf)
	local w = fade(zf)
	
	local n000 = hash3D(X, Y, Z, seed)
	local n100 = hash3D(X + 1, Y, Z, seed)
	local n010 = hash3D(X, Y + 1, Z, seed)
	local n110 = hash3D(X + 1, Y + 1, Z, seed)
	local n001 = hash3D(X, Y, Z + 1, seed)
	local n101 = hash3D(X + 1, Y, Z + 1, seed)
	local n011 = hash3D(X, Y + 1, Z + 1, seed)
	local n111 = hash3D(X + 1, Y + 1, Z + 1, seed)
	
	local nx00 = lerp(n000, n100, u)
	local nx10 = lerp(n010, n110, u)
	local nx01 = lerp(n001, n101, u)
	local nx11 = lerp(n011, n111, u)
	
	local nxy0 = lerp(nx00, nx10, v)
	local nxy1 = lerp(nx01, nx11, v)
	
	return lerp(nxy0, nxy1, w)
end

return Value
