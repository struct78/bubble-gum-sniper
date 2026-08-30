--[[
	Level management system
	Defines levels, spawns targets, manages progression
]]

local Level = {}

-- Level data definitions
Level.Levels = {
	{
		LevelNumber = 1,
		Name = "Urban Rooftop",
		Description = "Start on a city rooftop. Light wind conditions.",
		StartPosition = Vector3.new(0, 20, 0),
		SpawnPosition = Vector3.new(0, 20, 0),
		LookDirection = Vector3.new(0, 0, -1),
		WindProfile = {
			BaseWind = 10,
			Direction = Vector3.new(1, 0, 0),
			Variance = 5,
		},
		TargetPositions = {
			Vector3.new(50, 20, 0),
			Vector3.new(80, 22, 0),
			Vector3.new(120, 19, 0),
			Vector3.new(150, 25, 0),
			Vector3.new(100, 15, 30),
			Vector3.new(70, 18, -20),
			Vector3.new(140, 20, 20),
			Vector3.new(110, 23, -30),
		},
		TargetNames = {
			"Elon Tusk",
			"Kim Kar-dashian",
			"Kanye Vest",
			"Brad Pitt-ion",
			"Taylor Swiftly",
			"Dwayne the Rock Johnson",
			"Lady Gag-a",
			"Bruno Mars Bar",
		},
		TimeLimit = 300,
		Difficulty = 1,
		MaxDistance = 150,
	},
	{
		LevelNumber = 2,
		Name = "Mountain Peak",
		Description = "High altitude with strong wind gusts and reduced visibility.",
		StartPosition = Vector3.new(0, 50, 0),
		SpawnPosition = Vector3.new(0, 50, 0),
		LookDirection = Vector3.new(0, -0.3, -1),
		WindProfile = {
			BaseWind = 25,
			Direction = Vector3.new(2, 0.5, 1),
			Variance = 10,
		},
		TargetPositions = {
			Vector3.new(100, 48, 0),
			Vector3.new(200, 45, 50),
			Vector3.new(150, 52, -50),
			Vector3.new(250, 40, 0),
			Vector3.new(180, 55, 30),
			Vector3.new(120, 35, -80),
			Vector3.new(220, 50, -20),
			Vector3.new(170, 45, 60),
		},
		TargetNames = {
			"The Weeknd-ing",
			"Scarlett Johan-snow",
			"Tom Cruise Control",
			"Jennifer Lopez-sided",
			"Drake the Snake",
			"Beyoncé Yell-ow",
			"Ed Sheeran Closer",
			"Ariana Grande-ma",
		},
		TimeLimit = 300,
		Difficulty = 2,
		MaxDistance = 250,
	},
}

-- ============================================================================
-- LEVEL LOADING
-- ============================================================================

function Level:Load(levelNumber)
	local levelData = self.Levels[levelNumber]
	
	if not levelData then
		print("[Level] Level", levelNumber, "not found!")
		return nil
	end
	
	print("[Level] Loading level:", levelData.Name)
	print("[Level] Description:", levelData.Description)
	print("[Level] Targets:", #levelData.TargetPositions)
	
	return levelData
end

-- ============================================================================
-- LEVEL COMPLETION CHECK
-- ============================================================================

function Level:IsComplete(levelData, targets)
	if not targets or #targets == 0 then return false end
	
	-- All targets defeated?
	for _, target in ipairs(targets) do
		if not target.IsDefeated then
			return false
		end
	end
	return true
end

-- ============================================================================
-- LEVEL PROGRESSION
-- ============================================================================

function Level:GetNextLevel(currentLevel)
	if currentLevel < #self.Levels then
		return currentLevel + 1
	end
	return nil -- No more levels
end

function Level:GetTotalLevels()
	return #self.Levels
end

return Level
