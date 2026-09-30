--[[
	Game controller
	Orchestrates all game systems: levels, targets, physics, scoring
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local GameController = {}

-- Game state
GameController.State = {
	CurrentLevel = 1,
	ActiveTargets = {},
	ActiveProjectiles = {},
	GameRunning = false,
	LevelStartTime = 0,
	LevelTimeRemaining = 0,
	Players = {},
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function GameController:Initialize()
	print("[GameController] Initialized")
end

-- ============================================================================
-- LEVEL INITIALIZATION
-- ============================================================================

function GameController:StartLevel(levelNumber)
	print("[GameController] Starting level", levelNumber)
	
	self.State.CurrentLevel = levelNumber
	self.State.GameRunning = true
	self.State.LevelStartTime = tick()
	
	-- Load level data
	-- TODO: Load from LevelData module
	
	-- Spawn targets
	-- TODO: Create targets at specified positions
	
	-- Initialize wind system for this level
	-- TODO: Initialize wind simulation
	
	print("[GameController] Level", levelNumber, "started")
end

-- ============================================================================
-- GAMEPLAY LOOP
-- ============================================================================

function GameController:GameLoop()
	local lastUpdateTime = tick()
	
	while self.State.GameRunning do
		local currentTime = tick()
		local deltaTime = currentTime - lastUpdateTime
		lastUpdateTime = currentTime
		
		-- Update projectiles
		self:UpdateProjectiles(deltaTime)
		
		-- Update wind
		self:UpdateWind(deltaTime)
		
		-- Check level completion
		self:CheckLevelCompletion()
		
		-- Update HUD for all players
		self:UpdateAllPlayerHUDs()
		
		RunService.Heartbeat:Wait()
	end
end

-- ============================================================================
-- PROJECTILE UPDATES
-- ============================================================================

function GameController:UpdateProjectiles(deltaTime)
	-- TODO: Update all active projectiles
	-- - Apply gravity and wind
	-- - Check collisions
	-- - Handle hits
	-- - Cleanup expired projectiles
end

function GameController:HandleProjectileHit(projectile, hitResult)
	if hitResult then
		-- Target was hit
		local score = self:CalculateScore(hitResult)
		print("[GameController] HIT! Score:", score)
		
		-- Update target
		hitResult.Target.IsDefeated = true
		
		-- Create visual effect
		-- TODO: Call effects system
		
		-- Update player stats
		-- TODO: Update player data
	else
		-- Miss
		print("[GameController] Miss!")
	end
	
	-- Destroy projectile
	projectile.IsActive = false
end

-- ============================================================================
-- WIND & ENVIRONMENT UPDATES
-- ============================================================================

function GameController:UpdateWind(deltaTime)
	-- TODO: Update wind based on level data
	-- Notify players of wind changes
end

-- ============================================================================
-- LEVEL COMPLETION CHECK
-- ============================================================================

function GameController:CheckLevelCompletion()
	-- Check if all targets are defeated
	local allDefeated = true
	for _, target in ipairs(self.State.ActiveTargets) do
		if not target.IsDefeated then
			allDefeated = false
			break
		end
	end
	
	if allDefeated then
		self:CompleteLevel()
	end
end

function GameController:CompleteLevel()
	print("[GameController] Level", self.State.CurrentLevel, "completed!")
	self.State.GameRunning = false
	
	-- Calculate final score
	-- TODO: Calculate based on time, accuracy, etc.
	
	-- Award cosmetics
	-- TODO: Unlock new cosmetics based on performance
	
	-- Update player progression
	-- TODO: Unlock next level
	
	-- Notify players
	-- TODO: Send level complete event to clients
end

-- ============================================================================
-- SCORING
-- ============================================================================

function GameController:CalculateScore(hitResult)
	-- TODO: Calculate score based on:
	-- - Distance to target
	-- - Accuracy of hit
	-- - Current difficulty
	-- - Time efficiency
	
	return 100 -- Placeholder
end

-- ============================================================================
-- HUD UPDATES
-- ============================================================================

function GameController:UpdateAllPlayerHUDs()
	-- TODO: Update HUD for all connected players
	-- Send current game state to each player's client
end

function GameController:GetPlayerHUDData(player)
	-- Returns data needed to update player's HUD
	return {
		TimeRemaining = self.State.LevelTimeRemaining,
		Distance = 0, -- To current target
		WindVector = Vector3.new(0, 0, 0),
		Ammo = 50,
		Score = 0,
	}
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function GameController:Initialize()
	print("[GameController] Initializing game controller")
	
	-- Setup event handlers
	-- TODO: Connect to firing events
	-- TODO: Connect to player join/leave events
end

return GameController
