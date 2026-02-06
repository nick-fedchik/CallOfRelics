--!strict
--!optimize 2
--!native

--[[
	Perlin Noise Module
	Classic Perlin noise implementation optimized for Luau
]]

local Perlin = {}
Perlin.__index = Perlin

local F2 = 0.5 * (math.sqrt(3) - 1)
local G2 = (3 - math.sqrt(3)) / 6
local F3 = 1 / 3
local G3 = 1 / 6

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
local permMod12 = table.create(512)
for i = 0, 511 do
	perm[i] = p[(i % 256) + 1]
	permMod12[i] = perm[i] % 12
end

local grad2 = {
	{1, 1}, {-1, 1}, {1, -1}, {-1, -1},
	{1, 0}, {-1, 0}, {0, 1}, {0, -1}
}

local grad3 = {
	{1,1,0}, {-1,1,0}, {1,-1,0}, {-1,-1,0},
	{1,0,1}, {-1,0,1}, {1,0,-1}, {-1,0,-1},
	{0,1,1}, {0,-1,1}, {0,1,-1}, {0,-1,-1}
}

local function fade(t: number): number
	return t * t * t * (t * (t * 6 - 15) + 10)
end

local function lerp(a: number, b: number, t: number): number
	return a + t * (b - a)
end

local function dot2(gx: number, gy: number, x: number, y: number): number
	return gx * x + gy * y
end

local function dot3(gx: number, gy: number, gz: number, x: number, y: number, z: number): number
	return gx * x + gy * y + gz * z
end

local function fastFloor(x: number): number
	local xi = x // 1
	return if x < xi then xi - 1 else xi
end

--[[
	2D Perlin Noise
	@param x - X coordinate
	@param y - Y coordinate  
	@param seed - Optional seed value (default 0)
	@return Noise value between -1 and 1
]]
function Perlin.noise2D(x: number, y: number, seed: number?): number
	seed = seed or 0
	
	local X = fastFloor(x)
	local Y = fastFloor(y)
	
	local xf = x - X
	local yf = y - Y
	
	X = (X + seed) % 256
	Y = Y % 256
	
	local u = fade(xf)
	local v = fade(yf)
	
	local aa = perm[(perm[X] + Y) % 256]
	local ab = perm[(perm[X] + Y + 1) % 256]
	local ba = perm[(perm[(X + 1) % 256] + Y) % 256]
	local bb = perm[(perm[(X + 1) % 256] + Y + 1) % 256]
	
	local g00 = grad2[(aa % 8) + 1]
	local g10 = grad2[(ba % 8) + 1]
	local g01 = grad2[(ab % 8) + 1]
	local g11 = grad2[(bb % 8) + 1]
	
	local n00 = dot2(g00[1], g00[2], xf, yf)
	local n10 = dot2(g10[1], g10[2], xf - 1, yf)
	local n01 = dot2(g01[1], g01[2], xf, yf - 1)
	local n11 = dot2(g11[1], g11[2], xf - 1, yf - 1)
	
	local nx0 = lerp(n00, n10, u)
	local nx1 = lerp(n01, n11, u)
	
	return lerp(nx0, nx1, v)
end

--[[
	3D Perlin Noise
	@param x - X coordinate
	@param y - Y coordinate
	@param z - Z coordinate
	@param seed - Optional seed value (default 0)
	@return Noise value between -1 and 1
]]
function Perlin.noise3D(x: number, y: number, z: number, seed: number?): number
	seed = seed or 0
	
	local X = fastFloor(x)
	local Y = fastFloor(y)
	local Z = fastFloor(z)
	
	local xf = x - X
	local yf = y - Y
	local zf = z - Z
	
	X = (X + seed) % 256
	Y = Y % 256
	Z = Z % 256
	
	local u = fade(xf)
	local v = fade(yf)
	local w = fade(zf)
	
	local A = perm[X] + Y
	local AA = perm[A % 256] + Z
	local AB = perm[(A + 1) % 256] + Z
	local B = perm[(X + 1) % 256] + Y
	local BA = perm[B % 256] + Z
	local BB = perm[(B + 1) % 256] + Z
	
	local gi000 = permMod12[AA % 256]
	local gi100 = permMod12[BA % 256]
	local gi010 = permMod12[AB % 256]
	local gi110 = permMod12[BB % 256]
	local gi001 = permMod12[(AA + 1) % 256]
	local gi101 = permMod12[(BA + 1) % 256]
	local gi011 = permMod12[(AB + 1) % 256]
	local gi111 = permMod12[(BB + 1) % 256]
	
	local g000 = grad3[gi000 + 1]
	local g100 = grad3[gi100 + 1]
	local g010 = grad3[gi010 + 1]
	local g110 = grad3[gi110 + 1]
	local g001 = grad3[gi001 + 1]
	local g101 = grad3[gi101 + 1]
	local g011 = grad3[gi011 + 1]
	local g111 = grad3[gi111 + 1]
	
	local n000 = dot3(g000[1], g000[2], g000[3], xf, yf, zf)
	local n100 = dot3(g100[1], g100[2], g100[3], xf - 1, yf, zf)
	local n010 = dot3(g010[1], g010[2], g010[3], xf, yf - 1, zf)
	local n110 = dot3(g110[1], g110[2], g110[3], xf - 1, yf - 1, zf)
	local n001 = dot3(g001[1], g001[2], g001[3], xf, yf, zf - 1)
	local n101 = dot3(g101[1], g101[2], g101[3], xf - 1, yf, zf - 1)
	local n011 = dot3(g011[1], g011[2], g011[3], xf, yf - 1, zf - 1)
	local n111 = dot3(g111[1], g111[2], g111[3], xf - 1, yf - 1, zf - 1)
	
	local nx00 = lerp(n000, n100, u)
	local nx10 = lerp(n010, n110, u)
	local nx01 = lerp(n001, n101, u)
	local nx11 = lerp(n011, n111, u)
	
	local nxy0 = lerp(nx00, nx10, v)
	local nxy1 = lerp(nx01, nx11, v)
	
	return lerp(nxy0, nxy1, w)
end

return Perlin
