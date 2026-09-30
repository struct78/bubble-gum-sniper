--[[
	Game constants and configuration for Bubble Gum Sniper
	Adjust these values to balance gameplay difficulty and feel
]]

local Constants = {}

-- ============================================================================
-- PHYSICS & PROJECTILE SETTINGS
-- ============================================================================

Constants.Projectile = {
	-- Bubble gum pellet properties
	Size = Vector3.new(0.5, 0.5, 0.5),
	Mass = 0.1,
	Velocity = 50, -- Studs per second
	MaxLifetime = 30, -- Seconds before projectile despawns
	
	-- Wind physics
	WindMultiplier = 1.0, -- Base wind strength (increased per level)
	MaxWindSpeed = 50, -- Max wind velocity in studs/second
	
	-- Gravity
	Gravity = 3.0, -- Reduced by 90% from Roblox gravity for bubble-gum float
	
	-- Collision
	HitRadius = 5, -- Studs - proximity radius for hit detection
}

-- ============================================================================
-- DIFFICULTY & SCALING
-- ============================================================================

Constants.Difficulty = {
	-- Distance-based difficulty multiplier
	-- Formula: BaseDamage * (1 + distanceInStuds / 100 * DistanceMultiplier)
	DistanceMultiplier = 0.1,
	
	-- Accuracy scoring
	-- Formula: BaseScore * (accuracy % * AccuracyMultiplier)
	AccuracyMultiplier = 2.0,
	
	-- Wind difficulty scaling
	-- Applied per level: currentWind = BaseWind * (1 + levelNumber * WindScaling)
	WindScaling = 0.2,
	
	-- Scope sway (wobble) increases with distance
	ScopeSway = {
		Enabled = true,
		MinSway = 0.05,
		MaxSway = 0.5,
		SwayFrequency = 2.0, -- Hz (cycles per second)
	},
}

-- ============================================================================
-- CAMERA & INPUT
-- ============================================================================

Constants.Camera = {
	-- First-person camera settings
	FOV = 80, -- Default field of view
	ScopeZoomLevels = {
		1.0, -- 1x (iron sights)
		2.0, -- 2x zoom
		4.0, -- 4x zoom
		8.0, -- 8x zoom (premium cosmetic)
	},
	
	-- Mouse sensitivity (PC)
	MouseSensitivity = 1.0,
	
	-- Mobile gyro sensitivity
	GyroSensitivity = 0.8,
	GyroSmoothing = 0.2, -- Lower = smoother, higher = more responsive
	
	-- Scope sway
	ScopeSway = 0.02,
}

-- ============================================================================
-- LEVELS & TARGETS
-- ============================================================================

Constants.Level = {
	-- Base difficulty settings per level
	MaxDistance = {
		[1] = 150, -- Level 1: Close range
		[2] = 250, -- Level 2: Medium range
	},
	
	BaseWind = {
		[1] = 10, -- Level 1: Light wind (studs/sec)
		[2] = 20, -- Level 2: Moderate wind
	},
	
	TimeLimit = 300, -- Seconds (5 minutes per level)
	AmmoCap = 50, -- Maximum ammo per level
	
	-- Target system
	TargetsPerLevel = 8,
	TargetHealth = 1, -- One-shot targets (MVP)
}

Constants.Target = {
	-- Target visual properties
	Size = Vector3.new(1.5, 4, 0.3),
	Color = Color3.fromRGB(255, 20, 147), -- Deep pink (neon)
	
	-- Hit feedback
	HitParticleColor = Color3.fromRGB(255, 255, 0), -- Bright yellow burst
	HitLifetime = 1.0,
	HitExplosionRadius = 15,
}

-- ============================================================================
-- UI & HUD
-- ============================================================================

Constants.UI = {
	-- HUD elements
	HUDUpdateRate = 0.016, -- ~60 FPS
	
	-- Scope overlay
	ReticleSize = 50, -- Pixels
	ReticleColor = Color3.fromRGB(0, 255, 100), -- Neon green
	
	-- Distance readout
	DistanceFormat = "Distance: %.0f studs",
	
	-- Wind indicator
	WindArrowSize = 40, -- Pixels
	WindArrowColor = Color3.fromRGB(0, 200, 255), -- Neon cyan
	
	-- Score display
	ScoreFormat = "Score: %d",
}

-- ============================================================================
-- COSMETICS & SHOP
-- ============================================================================

Constants.Shop = {
	-- In-game currency
	SoftCurrencyName = "Bubbles", -- Cosmetic currency name
	StartingBalance = 100, -- Starting soft currency
	
	-- Cosmetic prices
	Prices = {
		Scope2x = 250,
		Scope4x = 500,
		ScopeThirmal = 750,
		AmmoMedium = 150,
		AmmoLarge = 350,
		OutfitNeonPink = 200,
		OutfitNeonGreen = 200,
		OutfitGold = 400,
		GunSkinPlastic = 100,
		GunSkinChrome = 300,
	},
	
	-- Cosmetic unlock progression
	UnlockLevels = {
		Scope2x = 1,
		AmmoMedium = 2,
		OutfitNeonPink = 3,
	},
	
	-- Reward per level completion
	RewardPerLevel = 100, -- Soft currency earned
}

-- ============================================================================
-- PLAYER PROGRESSION & PERSISTENCE
-- ============================================================================

Constants.Player = {
	-- DataStore
	DataStoreRetries = 3,
	DataStoreRetryDelay = 1.0, -- Seconds
	
	-- Default player data structure
	DefaultData = {
		LevelProgress = 1, -- Current level unlocked (1-indexed)
		Cosmetics = {
			Owned = {}, -- List of owned cosmetic IDs
			Equipped = {}, -- Currently equipped cosmetics
		},
		SoftCurrency = 100,
		Stats = {
			LevelsCompleted = 0,
			TotalScore = 0,
			TotalShotsHit = 0,
			TotalShots = 0,
		},
	},
}

-- ============================================================================
-- AUDIO
-- ============================================================================

Constants.Audio = {
	-- SFX volume (0-1)
	GunfireVolume = 0.8,
	HitVolume = 0.6,
	UIVolume = 0.5,
	AmbientVolume = 0.3,
	
	-- Music
	MusicEnabled = true,
	MusicVolume = 0.5,
}

-- ============================================================================
-- VISUAL EFFECTS & AESTHETICS
-- ============================================================================

Constants.Visual = {
	-- Neon color palette
	NeonColors = {
		Pink = Color3.fromRGB(255, 20, 147),
		Green = Color3.fromRGB(0, 255, 100),
		Blue = Color3.fromRGB(0, 200, 255),
		Red = Color3.fromRGB(255, 50, 50),
		Yellow = Color3.fromRGB(255, 255, 0),
		Purple = Color3.fromRGB(200, 0, 255),
		Gold = Color3.fromRGB(255, 215, 0),
		Silver = Color3.fromRGB(192, 192, 192),
	},
	
	-- Particle effects
	BubbleBurstParticles = 20,
	BubbleBurstSpeed = 50, -- Studs/sec
	
	-- World lighting (neon aesthetic)
	AmbientBrightness = 0.8,
	Saturation = 1.2, -- Oversaturate for neon look
}

-- ============================================================================
-- DEBUG & DEVELOPMENT
-- ============================================================================

Constants.Debug = {
	Enabled = false, -- Set to true for dev mode
	ShowProjectilePaths = false,
	ShowWindVectors = false,
	ShowTargetHitboxes = false,
	InfiniteAmmo = false,
	SkipLevel = false, -- Auto-win level on start
}

return Constants
