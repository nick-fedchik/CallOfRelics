--!strict
--!optimize 2
--!native

--[[
	Billow Noise Module
	Uses absolute value of noise to create "billowy" cloud-like patterns
]]

local Perlin = require(script.Parent.Perlin)
local Value = require(script.Parent.Value)

local Billow = {}
Billow.__index = Billow

export type NoiseType = "Perlin" | "Value"

export type BillowConfig = {
	octaves: number?,
	lacunarity: number?,
	persistence: number?,
	frequency: number?,
	amplitude: number?,
	noiseType: NoiseType?,
}

local DEFAULT_CONFIG: BillowConfig = {
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
	2D Billow Noise
	@param x - X coordinate
	@param y - Y coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional Billow configuration
	@return Noise value between 0 and 1
]]
function Billow.noise2D(x: number, y: number, seed: number?, config: BillowConfig?): number
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
		local noise = noiseFunc(x * currentFrequency, y * currentFrequency, seed + i * 1000)
		total += math.abs(noise) * currentAmplitude
		maxValue += currentAmplitude
		currentFrequency *= lacunarity
		currentAmplitude *= persistence
	end
	
	local normalized = total / maxValue
	return normalized * 2 - 1
end

--[[
	3D Billow Noise
	@param x - X coordinate
	@param y - Y coordinate
	@param z - Z coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional Billow configuration
	@return Noise value between -1 and 1
]]
function Billow.noise3D(x: number, y: number, z: number, seed: number?, config: BillowConfig?): number
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
	return normalized * 2 - 1
end

--[[
	Create a configured Billow generator
	@param config - Billow configuration
	@return Table with configured noise2D and noise3D functions
]]
function Billow.create(config: BillowConfig)
	return {
		noise2D = function(x: number, y: number, seed: number?): number
			return Billow.noise2D(x, y, seed, config)
		end,
		noise3D = function(x: number, y: number, z: number, seed: number?): number
			return Billow.noise3D(x, y, z, seed, config)
		end,
	}
end

return Billow
