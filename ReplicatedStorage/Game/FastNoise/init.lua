--!strict
--!optimize 2

--[[
	FastNoise - A comprehensive noise library for Roblox/Luau
	
	Available Noise Types:
	- Perlin: Classic gradient noise
	- Value: Lattice-based value noise
	- FBM: Fractal Brownian Motion (multiple octaves)
	- Billow: Billowy, cloud-like patterns
	- Ridged: Sharp ridges, great for mountains
	- Worley: Cellular/Voronoi-based noise
	- Voronoi: Cell-based regions with IDs
	- Turbulence: Turbulent flow patterns
	- DomainWarp: Coordinate distortion for organic patterns
	
	Usage:
	```lua
	local FastNoise = require(ReplicatedStorage.FastNoise)
	
	-- Simple usage
	local value = FastNoise.Perlin.noise2D(x, y, seed)
	
	-- With configuration
	local fbm = FastNoise.FBM.create({
		octaves = 4,
		lacunarity = 2.0,
		persistence = 0.5,
	})
	local value = fbm.noise2D(x, y, seed)
	```
]]

local FastNoise = {}

-- Import all noise modules
FastNoise.Perlin = require(script.Perlin)
FastNoise.Value = require(script.Value)
FastNoise.FBM = require(script.FBM)
FastNoise.Billow = require(script.Billow)
FastNoise.Ridged = require(script.Ridged)
FastNoise.Worley = require(script.Worley)
FastNoise.Voronoi = require(script.Voronoi)
FastNoise.Turbulence = require(script.Turbulence)
FastNoise.DomainWarp = require(script.DomainWarp)

-- Re-export types
export type FBMConfig = {
	octaves: number?,
	lacunarity: number?,
	persistence: number?,
	frequency: number?,
	amplitude: number?,
	noiseType: "Perlin" | "Value"?,
}

export type BillowConfig = FBMConfig

export type RidgedConfig = {
	octaves: number?,
	lacunarity: number?,
	gain: number?,
	frequency: number?,
	offset: number?,
	noiseType: "Perlin" | "Value"?,
}

export type WorleyConfig = {
	frequency: number?,
	distanceFunction: "Euclidean" | "Manhattan" | "Chebyshev"?,
	returnType: "F1" | "F2" | "F2MinusF1" | "F1PlusF2"?,
	jitter: number?,
}

export type VoronoiConfig = {
	frequency: number?,
	distanceFunction: "Euclidean" | "Manhattan" | "Chebyshev"?,
	returnType: "CellValue" | "Distance" | "Both"?,
	jitter: number?,
}

export type TurbulenceConfig = {
	octaves: number?,
	lacunarity: number?,
	persistence: number?,
	frequency: number?,
	power: number?,
	noiseType: "Perlin" | "Value"?,
}

export type DomainWarpConfig = {
	amplitude: number?,
	frequency: number?,
	octaves: number?,
	lacunarity: number?,
	persistence: number?,
	noiseType: "Perlin" | "Value"?,
	warpType: "Basic" | "Fractal" | "Progressive"?,
}

--[[
	Utility: Normalize noise value from [-1, 1] to [0, 1]
	@param value - Noise value in range [-1, 1]
	@return Normalized value in range [0, 1]
]]
function FastNoise.normalize(value: number): number
	return (value + 1) * 0.5
end

--[[
	Utility: Map noise value to a custom range
	@param value - Noise value (any range)
	@param min - Minimum output value
	@param max - Maximum output value
	@param inputMin - Input minimum (default -1)
	@param inputMax - Input maximum (default 1)
	@return Mapped value
]]
function FastNoise.map(value: number, min: number, max: number, inputMin: number?, inputMax: number?): number
	inputMin = inputMin or -1
	inputMax = inputMax or 1
	local t = (value - inputMin) / (inputMax - inputMin)
	return min + t * (max - min)
end

--[[
	Utility: Clamp noise value to a range
	@param value - Input value
	@param min - Minimum value (default -1)
	@param max - Maximum value (default 1)
	@return Clamped value
]]
function FastNoise.clamp(value: number, min: number?, max: number?): number
	min = min or -1
	max = max or 1
	return math.clamp(value, min, max)
end

--[[
	Utility: Create a seeded random number generator
	@param seed - Seed value
	@return Random number generator function
]]
function FastNoise.createRNG(seed: number): () -> number
	local state = seed
	return function(): number
		state = (state * 1103515245 + 12345) % 2147483648
		return state / 2147483648
	end
end

--[[
	Utility: Hash function for deterministic pseudo-random values
	@param x - X coordinate
	@param y - Y coordinate (optional)
	@param z - Z coordinate (optional)
	@param seed - Seed value
	@return Hash value between 0 and 1
]]
function FastNoise.hash(x: number, y: number?, z: number?, seed: number?): number
	seed = seed or 0
	y = y or 0
	z = z or 0
	
	local h = seed + x * 374761393 + y * 668265263 + z * 1274126177
	h = bit32.bxor(h, bit32.rshift(h, 13))
	h = h * 1274126177
	h = bit32.bxor(h, bit32.rshift(h, 16))
	
	return (h % 1000000) / 1000000
end

--[[
	Combine multiple noise values with different weights
	@param noises - Array of {value: number, weight: number}
	@return Combined noise value
]]
function FastNoise.combine(noises: {{value: number, weight: number}}): number
	local total = 0
	local totalWeight = 0
	
	for _, noise in noises do
		total += noise.value * noise.weight
		totalWeight += noise.weight
	end
	
	if totalWeight == 0 then
		return 0
	end
	
	return total / totalWeight
end

--[[
	Create a noise sampler that caches configuration
	@param noiseType - Type of noise ("Perlin", "Value", "FBM", etc.)
	@param config - Configuration for the noise type
	@return Sampler with noise2D and noise3D methods
]]
function FastNoise.createSampler(noiseType: string, config: any?)
	local noiseModule = (FastNoise :: any)[noiseType]
	
	if not noiseModule then
		error(`Unknown noise type: {noiseType}`)
	end
	
	if noiseModule.create then
		return noiseModule.create(config or {})
	end
	
	-- For basic modules without create (Perlin, Value)
	return {
		noise2D = noiseModule.noise2D,
		noise3D = noiseModule.noise3D,
	}
end

return FastNoise
