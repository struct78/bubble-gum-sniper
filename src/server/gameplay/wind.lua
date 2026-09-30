--[[
	Wind simulation system
	Generates and manages wind based on level and time
]]

local RunService = game:GetService("RunService")
local Wind = {}

-- Wind state
Wind.State = {
	CurrentWind = Vector3.new(0, 0, 0),
	BaseWind = 10,
	WindVariance = 0,
	WindDirection = Vector3.new(1, 0, 0),
	NoiseTime = 0,
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function Wind:Initialize()
	print("[Wind] Initialized")
end

-- ============================================================================
-- WIND CALCULATION
-- ============================================================================

function Wind:UpdateWind(deltaTime, levelData)
	self.State.NoiseTime = self.State.NoiseTime + deltaTime
	
	-- Get base wind for level
	self.State.BaseWind = levelData.WindProfile.BaseWind
	self.State.WindDirection = levelData.WindProfile.Direction.Unit
	
	-- Add turbulence (Perlin-like noise simulation)
	-- For now, use sine wave to vary wind
	local turbulence = math.sin(self.State.NoiseTime * 0.5) * 5
	
	-- Calculate current wind vector
	local windSpeed = self.State.BaseWind + turbulence
	self.State.CurrentWind = self.State.WindDirection * windSpeed
	
	return self.State.CurrentWind
end

function Wind:GetWindAtPosition(position, levelData)
	-- Could vary wind based on altitude or position
	-- For MVP, wind is uniform across level
	return self.State.CurrentWind
end

-- ============================================================================
-- WIND VISUALIZATION
-- ============================================================================

function Wind:GetWindDirection()
	-- Returns normalized wind direction for UI display
	return self.State.WindDirection
end

function Wind:GetWindIntensity()
	-- Returns wind magnitude (0-1) for UI alpha
	local intensity = self.State.CurrentWind.Magnitude / 50 -- Normalize to 0-1
	return math.min(intensity, 1.0)
end

return Wind
