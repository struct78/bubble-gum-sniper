--[[
	Level progression system
	Handles transitions between levels, level completion, and unlocks
]]

local LevelProgression = {}

-- Progression state
LevelProgression.PlayerProgress = {}

-- ============================================================================
-- COMPLETE LEVEL
-- ============================================================================

function LevelProgression:CompleteLevel(playerId, levelNumber, score)
	-- Record level completion
	if not self.PlayerProgress[playerId] then
		self.PlayerProgress[playerId] = {
			CompletedLevels = {},
			CurrentLevel = 1,
			TotalScore = 0,
		}
	end
	
	local progress = self.PlayerProgress[playerId]
	
	-- Mark level as completed
	progress.CompletedLevels[levelNumber] = {
		Score = score,
		CompletedAt = tick(),
	}
	
	-- Update total score
	progress.TotalScore = progress.TotalScore + score
	
	-- Unlock next level
	if levelNumber >= progress.CurrentLevel then
		progress.CurrentLevel = math.min(levelNumber + 1, 10) -- Max 10 levels (extensible)
	end
	
	print("[Progression] Player", playerId, "completed level", levelNumber, "with score", score)
	return progress
end

-- ============================================================================
-- GET PLAYER PROGRESS
-- ============================================================================

function LevelProgression:GetPlayerProgress(playerId)
	return self.PlayerProgress[playerId] or {
		CompletedLevels = {},
		CurrentLevel = 1,
		TotalScore = 0,
	}
end

-- ============================================================================
-- CHECK IF LEVEL UNLOCKED
-- ============================================================================

function LevelProgression:IsLevelUnlocked(playerId, levelNumber)
	local progress = self:GetPlayerProgress(playerId)
	return levelNumber <= progress.CurrentLevel
end

-- ============================================================================
-- GET BEST SCORE
-- ============================================================================

function LevelProgression:GetBestScore(playerId, levelNumber)
	local progress = self:GetPlayerProgress(playerId)
	if progress.CompletedLevels[levelNumber] then
		return progress.CompletedLevels[levelNumber].Score
	end
	return 0
end

return LevelProgression
