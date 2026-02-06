--!strict
--!optimize 2
--!native

--[[
	Fractal Brownian Motion (FBM) Module
	Combines multiple octaves of noise for natural-looking results
]]

local Perlin = require(script.Parent.Perlin)
local Value = require(script.Parent.Value)

local FBM = {}
FBM.__index = FBM

export type NoiseType = "Perlin" | "Value"

export type FBMConfig = {
	octaves: number?,
	lacunarity: number?,
	persistence: number?,
	frequency: number?,
	amplitude: number?,
	noiseType: NoiseType?,
}

local DEFAULT_CONFIG: FBMConfig = {
	octaves = 6,
	lacunarity = 2.0,
	persistence = 0.5,
	frequency = 1.0,
	amplitude = 1.0,
	noiseType = "Perlin",
}

local function getNoiseFunction2D(noiseType: NoiseType): (number, number, number?) -> number
	if noiseType == "Value" then
		return Value.noise2D
	end
	return Perlin.noise2D
end

local function getNoiseFunction3D(noiseType: NoiseType): (number, number, number, number?) -> number
	if noiseType == "Value" then
		return Value.noise3D
	end
	return Perlin.noise3D
end

--[[
	2D Fractal Brownian Motion
	@param x - X coordinate
	@param y - Y coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional FBM configuration
	@return Noise value (range depends on octaves)
]]
function FBM.noise2D(x: number, y: number, seed: number?, config: FBMConfig?): number
	seed = seed or 0
	local cfg = config or DEFAULT_CONFIG
	
	local octaves = cfg.octaves or DEFAULT_CONFIG.octaves :: number
	local lacunarity = cfg.lacunarity or DEFAULT_CONFIG.lacunarity :: number
	local persistence = cfg.persistence or DEFAULT_CONFIG.persistence :: number
	local frequency = cfg.frequency or DEFAULT_CONFIG.frequency :: number
	local amplitude = cfg.amplitude or DEFAULT_CONFIG.amplitude :: number
	local noiseType = cfg.noiseType or DEFAULT_CONFIG.noiseType :: NoiseType
	
	local noiseFunc = getNoiseFunction2D(noiseType)
	
	local total = 0
	local maxValue = 0
	local currentFrequency = frequency
	local currentAmplitude = amplitude
	
	for i = 1, octaves do
		total += noiseFunc(x * currentFrequency, y * currentFrequency, seed + i * 1000) * currentAmplitude
		maxValue += currentAmplitude
		currentFrequency *= lacunarity
		currentAmplitude *= persistence
	end
	
	return total / maxValue
end

--[[
	3D Fractal Brownian Motion
	@param x - X coordinate
	@param y - Y coordinate
	@param z - Z coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional FBM configuration
	@return Noise value (range depends on octaves)
]]
function FBM.noise3D(x: number, y: number, z: number, seed: number?, config: FBMConfig?): number
	seed = seed or 0
	local cfg = config or DEFAULT_CONFIG
	
	local octaves = cfg.octaves or DEFAULT_CONFIG.octaves :: number
	local lacunarity = cfg.lacunarity or DEFAULT_CONFIG.lacunarity :: number
	local persistence = cfg.persistence or DEFAULT_CONFIG.persistence :: number
	local frequency = cfg.frequency or DEFAULT_CONFIG.frequency :: number
	local amplitude = cfg.amplitude or DEFAULT_CONFIG.amplitude :: number
	local noiseType = cfg.noiseType or DEFAULT_CONFIG.noiseType :: NoiseType
	
	local noiseFunc = getNoiseFunction3D(noiseType)
	
	local total = 0
	local maxValue = 0
	local currentFrequency = frequency
	local currentAmplitude = amplitude
	
	for i = 1, octaves do
		total += noiseFunc(
			x * currentFrequency, 
			y * currentFrequency, 
			z * currentFrequency, 
			seed + i * 1000
		) * currentAmplitude
		maxValue += currentAmplitude
		currentFrequency *= lacunarity
		currentAmplitude *= persistence
	end
	
	return total / maxValue
end

--[[
	Create a configured FBM generator
	@param config - FBM configuration
	@return Table with configured noise2D and noise3D functions
]]
function FBM.create(config: FBMConfig)
	return {
		noise2D = function(x: number, y: number, seed: number?): number
			return FBM.noise2D(x, y, seed, config)
		end,
		noise3D = function(x: number, y: number, z: number, seed: number?): number
			return FBM.noise3D(x, y, z, seed, config)
		end,
	}
end

return FBM
