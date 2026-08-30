--[[
	Level environment builder
	Creates platforms, visual elements, and level geometry
]]

local LevelEnvironment = {}

-- ============================================================================
-- ROOFTOP LEVEL (Level 1)
-- ============================================================================

local function BuildRooftopLevel()
	-- Main player rooftop
	local playerRooftop = Instance.new("Part")
	playerRooftop.Name = "PlayerRooftop"
	playerRooftop.Shape = Enum.PartType.Block
	playerRooftop.Size = Vector3.new(20, 1, 20)
	playerRooftop.Color = Color3.fromRGB(50, 50, 50)
	playerRooftop.Material = Enum.Material.Concrete
	playerRooftop.CanCollide = true
	playerRooftop.CFrame = CFrame.new(0, 19, 0)
	playerRooftop.Parent = workspace
	
	-- Distant buildings (visual)
	for i = 1, 5 do
		local building = Instance.new("Part")
		building.Name = "Building" .. i
		building.Shape = Enum.PartType.Block
		building.Size = Vector3.new(30, 20 + i * 5, 15)
		building.Color = Color3.fromRGB(100 + i * 10, 100 + i * 10, 100 + i * 10)
		building.Material = Enum.Material.Brick
		building.CanCollide = false
		building.CastShadow = false
		building.CFrame = CFrame.new(50 + i * 40, 15 + i * 2.5, -50)
		building.Parent = workspace
	end
	
	print("[LevelEnvironment] Rooftop level built")
end

-- ============================================================================
-- MOUNTAIN LEVEL (Level 2)
-- ============================================================================

local function BuildMountainLevel()
	-- Player platform on mountain
	local mountainPlatform = Instance.new("Part")
	mountainPlatform.Name = "MountainPlatform"
	mountainPlatform.Shape = Enum.PartType.Block
	mountainPlatform.Size = Vector3.new(30, 2, 30)
	mountainPlatform.Color = Color3.fromRGB(100, 80, 60)
	mountainPlatform.Material = Enum.Material.Rock
	mountainPlatform.CanCollide = true
	mountainPlatform.CFrame = CFrame.new(0, 48, 0)
	mountainPlatform.Parent = workspace
	
	-- Mountain slopes (visual)
	for i = 1, 8 do
		local slope = Instance.new("Part")
		slope.Name = "Slope" .. i
		slope.Shape = Enum.PartType.Block
		slope.Size = Vector3.new(80, 5, 60)
		slope.Color = Color3.fromRGB(80 + i * 5, 70 + i * 5, 50 + i * 5)
		slope.Material = Enum.Material.Rock
		slope.CanCollide = false
		slope.CastShadow = false
		slope.TopSurface = Enum.SurfaceType.Smooth
		slope.BottomSurface = Enum.SurfaceType.Smooth
		
		local angle = math.rad(i * 5)
		local distance = 100 + i * 30
		slope.CFrame = CFrame.new(distance * math.cos(angle), 30 + i * 5, distance * math.sin(angle)) * CFrame.Angles(math.rad(15), 0, 0)
		slope.Parent = workspace
	end
	
	-- Snow peaks (white neon for aesthetic)
	for i = 1, 4 do
		local peak = Instance.new("Part")
		peak.Name = "Peak" .. i
		peak.Shape = Enum.PartType.Block
		peak.Size = Vector3.new(20, 30, 20)
		peak.Color = Color3.fromRGB(220, 240, 255)
		peak.Material = Enum.Material.Neon
		peak.CanCollide = false
		peak.CastShadow = false
		peak.CFrame = CFrame.new(150 * math.cos(i * math.pi / 2), 60 + i * 10, 150 * math.sin(i * math.pi / 2))
		peak.Parent = workspace
	end
	
	print("[LevelEnvironment] Mountain level built")
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

local function CleanupLevel()
	-- Destroy all level geometry
	for _, part in pairs(workspace:FindPartBySide(Vector3.new(0, 1, 0), nil)) do
		if part.Name:match("Rooftop") or part.Name:match("Building") or 
		   part.Name:match("Mountain") or part.Name:match("Slope") or 
		   part.Name:match("Peak") then
			part:Destroy()
		end
	end
end

-- ============================================================================
-- PUBLIC FUNCTIONS
-- ============================================================================

function LevelEnvironment:BuildLevel(levelNumber)
	-- Clean up previous level
	CleanupLevel()
	
	if levelNumber == 1 then
		BuildRooftopLevel()
	elseif levelNumber == 2 then
		BuildMountainLevel()
	else
		print("[LevelEnvironment] Unknown level", levelNumber)
	end
end

return LevelEnvironment
