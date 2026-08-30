--[[
	Player data and progression system
	Manages player stats, cosmetics, and level progression
]]

local Players = game:GetService("Players")
local PlayerData = {}

-- Default player data template
function PlayerData:CreateDefault(playerId)
	return {
		UserId = playerId,
		LevelProgress = 1,
		Cosmetics = {
			Owned = {},
			Equipped = {
				Scope = nil,
				Ammunition = nil,
				Outfit = nil,
				GunSkin = nil,
			},
		},
		SoftCurrency = 100,
		Stats = {
			LevelsCompleted = 0,
			TotalScore = 0,
			TotalShotsHit = 0,
			TotalShots = 0,
		},
		LastUpdated = tick(),
	}
end

-- ============================================================================
-- LEVEL COMPLETION
-- ============================================================================

function PlayerData:CompleteLevel(playerData, levelNumber, score)
	playerData.Stats.LevelsCompleted = playerData.Stats.LevelsCompleted + 1
	playerData.Stats.TotalScore = playerData.Stats.TotalScore + score
	playerData.LevelProgress = math.max(playerData.LevelProgress, levelNumber + 1)
	
	-- Award soft currency
	playerData.SoftCurrency = playerData.SoftCurrency + 100
	
	playerData.LastUpdated = tick()
end

-- ============================================================================
-- STATS UPDATE
-- ============================================================================

function PlayerData:RecordShot(playerData, hitAccurate)
	playerData.Stats.TotalShots = playerData.Stats.TotalShots + 1
	if hitAccurate then
		playerData.Stats.TotalShotsHit = playerData.Stats.TotalShotsHit + 1
	end
end

function PlayerData:GetAccuracy(playerData)
	if playerData.Stats.TotalShots == 0 then return 0 end
	return playerData.Stats.TotalShotsHit / playerData.Stats.TotalShots
end

return PlayerData
