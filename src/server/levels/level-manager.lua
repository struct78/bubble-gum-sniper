--[[
	Level manager
	Handles level loading, spawning, progression
]]

local LevelManager = {}

function LevelManager:LoadLevel(levelNumber)
	print("[LevelManager] Loading level", levelNumber)
	
	-- TODO: Load level data
	-- TODO: Spawn environment
	-- TODO: Spawn targets
	-- TODO: Setup wind profile
	-- TODO: Reset player state
end

function LevelManager:CompleteLevel(score)
	print("[LevelManager] Level completed with score", score)
	
	-- TODO: Show completion screen
	-- TODO: Update player progression
	-- TODO: Award cosmetics
	-- TODO: Load next level
end

function LevelManager:RestartLevel()
	print("[LevelManager] Restarting level")
	-- TODO: Reset current level
end

return LevelManager
