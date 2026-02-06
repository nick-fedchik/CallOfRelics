--!strict
--!optimize 2
--!native

--[[
	Domain Warp Module
	Distorts input coordinates using noise to create organic, warped patterns
]]

local Perlin = require(script.Parent.Perlin)
local Value = require(script.Parent.Value)

local DomainWarp = {}
DomainWarp.__index = DomainWarp

export type NoiseType = "Perlin" | "Value"
export type WarpType = "Basic" | "Fractal" | "Progressive"

export type DomainWarpConfig = {
	amplitude: number?,
	frequency: number?,
	octaves: number?,
	lacunarity: number?,
	persistence: number?,
	noiseType: NoiseType?,
	warpType: WarpType?,
}

local DEFAULT_CONFIG: DomainWarpConfig = {
	amplitude = 30.0,
	frequency = 0.01,
	octaves = 3,
	lacunarity = 2.0,
	persistence = 0.5,
	noiseType = "Perlin",
	warpType = "Basic",
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

local function fbm2D(x: number, y: number, seed: number, noiseFunc: (number, number, number?) -> number, octaves: number, lacunarity: number, persistence: number): number
	local total = 0
	local maxValue = 0
	local amplitude = 1.0
	local frequency = 1.0
	
	for i = 1, octaves do
		total += noiseFunc(x * frequency, y * frequency, seed + i * 1000) * amplitude
		maxValue += amplitude
		frequency *= lacunarity
		amplitude *= persistence
	end
	
	return total / maxValue
end

local function fbm3D(x: number, y: number, z: number, seed: number, noiseFunc: (number, number, number, number?) -> number, octaves: number, lacunarity: number, persistence: number): number
	local total = 0
	local maxValue = 0
	local amplitude = 1.0
	local frequency = 1.0
	
	for i = 1, octaves do
		total += noiseFunc(x * frequency, y * frequency, z * frequency, seed + i * 1000) * amplitude
		maxValue += amplitude
		frequency *= lacunarity
		amplitude *= persistence
	end
	
	return total / maxValue
end

--[[
	Basic 2D Domain Warp
	Single layer of warping
	@param x - X coordinate
	@param y - Y coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional DomainWarp configuration
	@return Warped x, y coordinates
]]
function DomainWarp.warp2D(x: number, y: number, seed: number?, config: DomainWarpConfig?): (number, number)
	seed = seed or 0
	local cfg = config or DEFAULT_CONFIG
	
	local amplitude = cfg.amplitude or DEFAULT_CONFIG.amplitude :: number
	local frequency = cfg.frequency or DEFAULT_CONFIG.frequency :: number
	local noiseType = cfg.noiseType or DEFAULT_CONFIG.noiseType :: NoiseType
	
	local noiseFunc = getNoiseFunction2D(noiseType)
	
	local scaledX = x * frequency
	local scaledY = y * frequency
	
	local warpX = noiseFunc(scaledX, scaledY, seed) * amplitude
	local warpY = noiseFunc(scaledX + 5.2, scaledY + 1.3, seed) * amplitude
	
	return x + warpX, y + warpY
end

--[[
	Fractal 2D Domain Warp
	Uses FBM for smoother, more detailed warping
	@param x - X coordinate
	@param y - Y coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional DomainWarp configuration
	@return Warped x, y coordinates
]]
function DomainWarp.warpFractal2D(x: number, y: number, seed: number?, config: DomainWarpConfig?): (number, number)
	seed = seed or 0
	local cfg = config or DEFAULT_CONFIG
	
	local amplitude = cfg.amplitude or DEFAULT_CONFIG.amplitude :: number
	local frequency = cfg.frequency or DEFAULT_CONFIG.frequency :: number
	local octaves = cfg.octaves or DEFAULT_CONFIG.octaves :: number
	local lacunarity = cfg.lacunarity or DEFAULT_CONFIG.lacunarity :: number
	local persistence = cfg.persistence or DEFAULT_CONFIG.persistence :: number
	local noiseType = cfg.noiseType or DEFAULT_CONFIG.noiseType :: NoiseType
	
	local noiseFunc = getNoiseFunction2D(noiseType)
	
	local scaledX = x * frequency
	local scaledY = y * frequency
	
	local warpX = fbm2D(scaledX, scaledY, seed, noiseFunc, octaves, lacunarity, persistence) * amplitude
	local warpY = fbm2D(scaledX + 5.2, scaledY + 1.3, seed + 100, noiseFunc, octaves, lacunarity, persistence) * amplitude
	
	return x + warpX, y + warpY
end

--[[
	Progressive 2D Domain Warp (Multi-layer)
	Applies multiple layers of warping for complex organic patterns
	@param x - X coordinate
	@param y - Y coordinate
	@param seed - Optional seed value (default 0)
	@param layers - Number of warp layers (default 2)
	@param config - Optional DomainWarp configuration
	@return Warped x, y coordinates
]]
function DomainWarp.warpProgressive2D(x: number, y: number, seed: number?, layers: number?, config: DomainWarpConfig?): (number, number)
	seed = seed or 0
	layers = layers or 2
	local cfg = config or DEFAULT_CONFIG
	
	local amplitude = cfg.amplitude or DEFAULT_CONFIG.amplitude :: number
	local frequency = cfg.frequency or DEFAULT_CONFIG.frequency :: number
	local noiseType = cfg.noiseType or DEFAULT_CONFIG.noiseType :: NoiseType
	
	local noiseFunc = getNoiseFunction2D(noiseType)
	
	local warpedX = x
	local warpedY = y
	
	for i = 1, layers do
		local scaledX = warpedX * frequency
		local scaledY = warpedY * frequency
		local layerAmplitude = amplitude / i -- Reduce amplitude for each layer
		
		local dx = noiseFunc(scaledX, scaledY, seed + i * 100) * layerAmplitude
		local dy = noiseFunc(scaledX + 5.2, scaledY + 1.3, seed + i * 100 + 50) * layerAmplitude
		
		warpedX = warpedX + dx
		warpedY = warpedY + dy
	end
	
	return warpedX, warpedY
end

--[[
	Basic 3D Domain Warp
	@param x - X coordinate
	@param y - Y coordinate
	@param z - Z coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional DomainWarp configuration
	@return Warped x, y, z coordinates
]]
function DomainWarp.warp3D(x: number, y: number, z: number, seed: number?, config: DomainWarpConfig?): (number, number, number)
	seed = seed or 0
	local cfg = config or DEFAULT_CONFIG
	
	local amplitude = cfg.amplitude or DEFAULT_CONFIG.amplitude :: number
	local frequency = cfg.frequency or DEFAULT_CONFIG.frequency :: number
	local noiseType = cfg.noiseType or DEFAULT_CONFIG.noiseType :: NoiseType
	
	local noiseFunc = getNoiseFunction3D(noiseType)
	
	local scaledX = x * frequency
	local scaledY = y * frequency
	local scaledZ = z * frequency
	
	local warpX = noiseFunc(scaledX, scaledY, scaledZ, seed) * amplitude
	local warpY = noiseFunc(scaledX + 5.2, scaledY + 1.3, scaledZ + 2.8, seed) * amplitude
	local warpZ = noiseFunc(scaledX + 9.1, scaledY + 4.7, scaledZ + 6.3, seed) * amplitude
	
	return x + warpX, y + warpY, z + warpZ
end

--[[
	Fractal 3D Domain Warp
	@param x - X coordinate
	@param y - Y coordinate
	@param z - Z coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional DomainWarp configuration
	@return Warped x, y, z coordinates
]]
function DomainWarp.warpFractal3D(x: number, y: number, z: number, seed: number?, config: DomainWarpConfig?): (number, number, number)
	seed = seed or 0
	local cfg = config or DEFAULT_CONFIG
	
	local amplitude = cfg.amplitude or DEFAULT_CONFIG.amplitude :: number
	local frequency = cfg.frequency or DEFAULT_CONFIG.frequency :: number
	local octaves = cfg.octaves or DEFAULT_CONFIG.octaves :: number
	local lacunarity = cfg.lacunarity or DEFAULT_CONFIG.lacunarity :: number
	local persistence = cfg.persistence or DEFAULT_CONFIG.persistence :: number
	local noiseType = cfg.noiseType or DEFAULT_CONFIG.noiseType :: NoiseType
	
	local noiseFunc = getNoiseFunction3D(noiseType)
	
	local scaledX = x * frequency
	local scaledY = y * frequency
	local scaledZ = z * frequency
	
	local warpX = fbm3D(scaledX, scaledY, scaledZ, seed, noiseFunc, octaves, lacunarity, persistence) * amplitude
	local warpY = fbm3D(scaledX + 5.2, scaledY + 1.3, scaledZ + 2.8, seed + 100, noiseFunc, octaves, lacunarity, persistence) * amplitude
	local warpZ = fbm3D(scaledX + 9.1, scaledY + 4.7, scaledZ + 6.3, seed + 200, noiseFunc, octaves, lacunarity, persistence) * amplitude
	
	return x + warpX, y + warpY, z + warpZ
end

--[[
	Apply domain warp to a noise function (2D)
	@param noiseFunc - The noise function to warp
	@param x - X coordinate
	@param y - Y coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional DomainWarp configuration
	@return Noise value at warped coordinates
]]
function DomainWarp.applyToNoise2D(noiseFunc: (number, number, number?) -> number, x: number, y: number, seed: number?, config: DomainWarpConfig?): number
	local warpedX, warpedY = DomainWarp.warpFractal2D(x, y, seed, config)
	return noiseFunc(warpedX, warpedY, seed)
end

--[[
	Apply domain warp to a noise function (3D)
	@param noiseFunc - The noise function to warp
	@param x - X coordinate
	@param y - Y coordinate
	@param z - Z coordinate
	@param seed - Optional seed value (default 0)
	@param config - Optional DomainWarp configuration
	@return Noise value at warped coordinates
]]
function DomainWarp.applyToNoise3D(noiseFunc: (number, number, number, number?) -> number, x: number, y: number, z: number, seed: number?, config: DomainWarpConfig?): number
	local warpedX, warpedY, warpedZ = DomainWarp.warpFractal3D(x, y, z, seed, config)
	return noiseFunc(warpedX, warpedY, warpedZ, seed)
end

--[[
	Create a configured DomainWarp generator
	@param config - DomainWarp configuration
	@return Table with configured warp functions
]]
function DomainWarp.create(config: DomainWarpConfig)
	return {
		warp2D = function(x: number, y: number, seed: number?): (number, number)
			return DomainWarp.warp2D(x, y, seed, config)
		end,
		warpFractal2D = function(x: number, y: number, seed: number?): (number, number)
			return DomainWarp.warpFractal2D(x, y, seed, config)
		end,
		warpProgressive2D = function(x: number, y: number, seed: number?, layers: number?): (number, number)
			return DomainWarp.warpProgressive2D(x, y, seed, layers, config)
		end,
		warp3D = function(x: number, y: number, z: number, seed: number?): (number, number, number)
			return DomainWarp.warp3D(x, y, z, seed, config)
		end,
		warpFractal3D = function(x: number, y: number, z: number, seed: number?): (number, number, number)
			return DomainWarp.warpFractal3D(x, y, z, seed, config)
		end,
	}
end

return DomainWarp
