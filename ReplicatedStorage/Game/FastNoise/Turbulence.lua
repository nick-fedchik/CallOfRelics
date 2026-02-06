--!strict
--!optimize 2
--!native

--[[
	Turbulence Noise Module
	Creates turbulent patterns by summing absolute values of noise
	Similar to Billow but with different normalization
]]

local Perlin = require(script.Parent.Perlin)
local Value = require(script.Parent.Value)

local Turbulence = {}
Turbulence.__index = Turbulence

export type NoiseType = "Perlin" | "Value"

export type TurbulenceConfig = {
	octaves: number?,
	lacunarity: number?,
	persistence: number?,
	frequency: number?,
	power: number?,
	noiseType: NoiseType?,
}

local DEFAULT_CONFIG: TurbulenceConfig = {
	octaves = 6,
	lacunarity = 2.0,
	persistence = 0.5,
	frequency = 1.0,
	power = 1.0,
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
	2D Turbulence Noise
	@param x - X coordinate
	@param y - Y coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional Turbulence configuration
	@return Noise value between 0 and 1
]]
function Turbulence.noise2D(x: number, y: number, seed: number?, config: TurbulenceConfig?): number
	seed = seed or 0
	local cfg = config or DEFAULT_CONFIG
	
	local octaves = cfg.octaves or DEFAULT_CONFIG.octaves :: number
	local lacunarity = cfg.lacunarity or DEFAULT_CONFIG.lacunarity :: number
	local persistence = cfg.persistence or DEFAULT_CONFIG.persistence :: number
	local frequency = cfg.frequency or DEFAULT_CONFIG.frequency :: number
	local power = cfg.power or DEFAULT_CONFIG.power :: number
	local noiseType = cfg.noiseType or DEFAULT_CONFIG.noiseType :: NoiseType
	
	local noiseFunc = getNoiseFunction2D(noiseType)
	
	local total = 0
	local maxValue = 0
	local currentFrequency = frequency
	local currentAmplitude = 1.0
	
	for i = 1, octaves do
		local noise = noiseFunc(x * currentFrequency, y * currentFrequency, seed + i * 1000)
		total += math.abs(noise) * currentAmplitude
		maxValue += currentAmplitude
		currentFrequency *= lacunarity
		currentAmplitude *= persistence
	end
	
	local normalized = total / maxValue
	return math.pow(normalized, power)
end

--[[
	3D Turbulence Noise
	@param x - X coordinate
	@param y - Y coordinate
	@param z - Z coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional Turbulence configuration
	@return Noise value between 0 and 1
]]
function Turbulence.noise3D(x: number, y: number, z: number, seed: number?, config: TurbulenceConfig?): number
	seed = seed or 0
	local cfg = config or DEFAULT_CONFIG
	
	local octaves = cfg.octaves or DEFAULT_CONFIG.octaves :: number
	local lacunarity = cfg.lacunarity or DEFAULT_CONFIG.lacunarity :: number
	local persistence = cfg.persistence or DEFAULT_CONFIG.persistence :: number
	local frequency = cfg.frequency or DEFAULT_CONFIG.frequency :: number
	local power = cfg.power or DEFAULT_CONFIG.power :: number
	local noiseType = cfg.noiseType or DEFAULT_CONFIG.noiseType :: NoiseType
	
	local noiseFunc = getNoiseFunction3D(noiseType)
	
	local total = 0
	local maxValue = 0
	local currentFrequency = frequency
	local currentAmplitude = 1.0
	
	for i = 1, octaves do
		local noise = noiseFunc(
			x * currentFrequency, 
			y * currentFrequency, 
			z * currentFrequency, 
			seed + i * 1000
		)
		total += math.abs(noise) * currentAmplitude
		maxValue += currentAmplitude
		currentFrequency *= lacunarity
		currentAmplitude *= persistence
	end
	
	local normalized = total / maxValue
	return math.pow(normalized, power)
end

--[[
	Apply turbulence displacement to coordinates
	Useful for distorting other noise functions
	@param x - X coordinate
	@param y - Y coordinate
	@param seed - Optional seed value (default 0)
	@param strength - Displacement strength
	@param config - Optional Turbulence configuration
	@return Displaced x, y coordinates
]]
function Turbulence.displace2D(x: number, y: number, seed: number?, strength: number?, config: TurbulenceConfig?): (number, number)
	seed = seed or 0
	strength = strength or 1.0
	
	local dx = Turbulence.noise2D(x, y, seed, config) * strength
	local dy = Turbulence.noise2D(x + 1000, y + 1000, seed, config) * strength
	
	return x + dx, y + dy
end

--[[
	Apply turbulence displacement to 3D coordinates
	@param x - X coordinate
	@param y - Y coordinate
	@param z - Z coordinate
	@param seed - Optional seed value (default 0)
	@param strength - Displacement strength
	@param config - Optional Turbulence configuration
	@return Displaced x, y, z coordinates
]]
function Turbulence.displace3D(x: number, y: number, z: number, seed: number?, strength: number?, config: TurbulenceConfig?): (number, number, number)
	seed = seed or 0
	strength = strength or 1.0
	
	local dx = Turbulence.noise3D(x, y, z, seed, config) * strength
	local dy = Turbulence.noise3D(x + 1000, y + 1000, z, seed, config) * strength
	local dz = Turbulence.noise3D(x, y + 1000, z + 1000, seed, config) * strength
	
	return x + dx, y + dy, z + dz
end

--[[
	Create a configured Turbulence generator
	@param config - Turbulence configuration
	@return Table with configured noise2D, noise3D, and displace functions
]]
function Turbulence.create(config: TurbulenceConfig)
	return {
		noise2D = function(x: number, y: number, seed: number?): number
			return Turbulence.noise2D(x, y, seed, config)
		end,
		noise3D = function(x: number, y: number, z: number, seed: number?): number
			return Turbulence.noise3D(x, y, z, seed, config)
		end,
		displace2D = function(x: number, y: number, seed: number?, strength: number?): (number, number)
			return Turbulence.displace2D(x, y, seed, strength, config)
		end,
		displace3D = function(x: number, y: number, z: number, seed: number?, strength: number?): (number, number, number)
			return Turbulence.displace3D(x, y, z, seed, strength, config)
		end,
	}
end

return Turbulence
