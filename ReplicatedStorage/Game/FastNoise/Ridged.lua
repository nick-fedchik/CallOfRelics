--!strict
--!optimize 2
--!native

--[[
	Ridged Multifractal Noise Module
	Creates sharp ridges, great for mountain terrain
]]

local Perlin = require(script.Parent.Perlin)
local Value = require(script.Parent.Value)

local Ridged = {}
Ridged.__index = Ridged

export type NoiseType = "Perlin" | "Value"

export type RidgedConfig = {
	octaves: number?,
	lacunarity: number?,
	gain: number?,
	frequency: number?,
	offset: number?,
	noiseType: NoiseType?,
}

local DEFAULT_CONFIG: RidgedConfig = {
	octaves = 6,
	lacunarity = 2.0,
	gain = 2.0,
	frequency = 1.0,
	offset = 1.0,
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

local function computeSpectralWeights(octaves: number, lacunarity: number, gain: number): {number}
	local weights = table.create(octaves)
	local frequency = 1.0
	
	for i = 1, octaves do
		weights[i] = math.pow(frequency, -gain)
		frequency *= lacunarity
	end
	
	return weights
end

--[[
	2D Ridged Multifractal Noise
	@param x - X coordinate
	@param y - Y coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional Ridged configuration
	@return Noise value between -1 and 1
]]
function Ridged.noise2D(x: number, y: number, seed: number?, config: RidgedConfig?): number
	seed = seed or 0
	local cfg = config or DEFAULT_CONFIG
	
	local octaves = cfg.octaves or DEFAULT_CONFIG.octaves :: number
	local lacunarity = cfg.lacunarity or DEFAULT_CONFIG.lacunarity :: number
	local gain = cfg.gain or DEFAULT_CONFIG.gain :: number
	local frequency = cfg.frequency or DEFAULT_CONFIG.frequency :: number
	local offset = cfg.offset or DEFAULT_CONFIG.offset :: number
	local noiseType = cfg.noiseType or DEFAULT_CONFIG.noiseType :: NoiseType
	
	local noiseFunc = getNoiseFunction2D(noiseType)
	local weights = computeSpectralWeights(octaves, lacunarity, gain)
	
	local total = 0
	local currentFrequency = frequency
	local weight = 1.0
	
	for i = 1, octaves do
		local noise = noiseFunc(x * currentFrequency, y * currentFrequency, seed + i * 1000)
		noise = offset - math.abs(noise)
		noise = noise * noise
		noise = noise * weight
		weight = math.clamp(noise * gain, 0, 1)
		total += noise * weights[i]
		currentFrequency *= lacunarity
	end
	
	return (total * 1.25) - 1
end

--[[
	3D Ridged Multifractal Noise
	@param x - X coordinate
	@param y - Y coordinate
	@param z - Z coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional Ridged configuration
	@return Noise value between -1 and 1
]]
function Ridged.noise3D(x: number, y: number, z: number, seed: number?, config: RidgedConfig?): number
	seed = seed or 0
	local cfg = config or DEFAULT_CONFIG
	
	local octaves = cfg.octaves or DEFAULT_CONFIG.octaves :: number
	local lacunarity = cfg.lacunarity or DEFAULT_CONFIG.lacunarity :: number
	local gain = cfg.gain or DEFAULT_CONFIG.gain :: number
	local frequency = cfg.frequency or DEFAULT_CONFIG.frequency :: number
	local offset = cfg.offset or DEFAULT_CONFIG.offset :: number
	local noiseType = cfg.noiseType or DEFAULT_CONFIG.noiseType :: NoiseType
	
	local noiseFunc = getNoiseFunction3D(noiseType)
	local weights = computeSpectralWeights(octaves, lacunarity, gain)
	
	local total = 0
	local currentFrequency = frequency
	local weight = 1.0
	
	for i = 1, octaves do
		local noise = noiseFunc(
			x * currentFrequency, 
			y * currentFrequency, 
			z * currentFrequency, 
			seed + i * 1000
		)
		noise = offset - math.abs(noise)
		noise = noise * noise
		noise = noise * weight
		weight = math.clamp(noise * gain, 0, 1)
		total += noise * weights[i]
		currentFrequency *= lacunarity
	end
	
	return (total * 1.25) - 1
end

--[[
	Create a configured Ridged generator
	@param config - Ridged configuration
	@return Table with configured noise2D and noise3D functions
]]
function Ridged.create(config: RidgedConfig)
	return {
		noise2D = function(x: number, y: number, seed: number?): number
			return Ridged.noise2D(x, y, seed, config)
		end,
		noise3D = function(x: number, y: number, z: number, seed: number?): number
			return Ridged.noise3D(x, y, z, seed, config)
		end,
	}
end

return Ridged
