--[[
	Targeting and hit detection system
	Calculates scores, accuracy, and hit validation
]]

local Targeting = {}

-- ============================================================================
-- HIT DETECTION
-- ============================================================================

function Targeting:CheckTargetHit(projectilePosition, targetList)
	-- Find targets within hit radius
	local hits = {}
	
	for _, target in ipairs(targetList) do
		if not target.IsDefeated then
			local distance = (projectilePosition - target.Position).Magnitude
			
			if distance < 5 then -- Hit radius from constants
				table.insert(hits, {
					Target = target,
					HitDistance = distance,
					Accuracy = math.max(0, 1 - (distance / 5)), -- 0-1 accuracy
				})
			end
		end
	end
	
	-- Return closest hit (most accurate)
	if #hits > 0 then
		table.sort(hits, function(a, b)
			return a.HitDistance < b.HitDistance
		end)
		return hits[1]
	end
	
	return nil
end

-- ============================================================================
-- SCORING
-- ============================================================================

function Targeting:CalculateScore(hitResult, distance)
	if not hitResult then
		return 0 -- Miss
	end
	
	-- Base score: 100 points
	local baseScore = 100
	
	-- Distance bonus (farther = more points)
	local distanceBonus = (distance / 100) * 50 -- Up to 50 bonus points per 100 studs
	
	-- Accuracy bonus (more accurate = more points)
	local accuracyBonus = hitResult.Accuracy * 50 -- Up to 50 bonus points
	
	local totalScore = baseScore + distanceBonus + accuracyBonus
	
	return math.floor(totalScore)
end

-- ============================================================================
-- DIFFICULTY CALCULATION
-- ============================================================================

function Targeting:CalculateDifficulty(distance, windIntensity)
	-- Difficulty multiplier based on distance and wind
	local baseDifficulty = 1.0
	
	-- Distance increases difficulty
	local distanceDifficulty = 1 + (distance / 100) * 0.3
	
	-- Wind increases difficulty
	local windDifficulty = 1 + windIntensity * 0.5
	
	return baseDifficulty * distanceDifficulty * windDifficulty
end

return Targeting
