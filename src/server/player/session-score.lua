local PLAYER_HIT_POINTS = 5

local SessionScore = {}

function SessionScore.Create(player)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		if not stats:IsA("Folder") or stats:FindFirstChild("Score") then
			warn("[SessionScore] Cannot add Score without replacing existing leaderstats")
			return nil
		end
	else
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
	end

	local score = Instance.new("IntValue")
	score.Name = "Score"
	score.Value = 0
	score.Parent = stats
	return score
end

function SessionScore.AwardHit(shot, victim, activePlayers)
	if not victim or not shot.ShooterUserId or victim.UserId == shot.ShooterUserId
		or shot.PlayerAwardCommitted then
		return
	end
	local entry = activePlayers[victim.UserId]
	if not entry or entry.Player ~= victim or not entry.SessionScore or not entry.SessionScore.Parent then
		return
	end

	shot.PlayerAwardCommitted = true
	entry.SessionScore.Value = entry.SessionScore.Value + PLAYER_HIT_POINTS
end

return SessionScore
