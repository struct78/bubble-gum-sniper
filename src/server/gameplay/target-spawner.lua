--[[
	Target spawner and manager
	Creates and tracks target instances for levels
]]

local TargetSpawner = {}

-- ============================================================================
-- SPAWN TARGETS FOR LEVEL
-- ============================================================================

function TargetSpawner:SpawnTargetsForLevel(levelData)
	print("[TargetSpawner] Spawning targets for level", levelData.LevelNumber)
	
	local targets = {}
	
	-- Get target names from level data, fallback to generic names
	local targetNames = levelData.TargetNames or {}
	
	-- Spawn targets at specified positions
	for i, position in ipairs(levelData.TargetPositions or {}) do
		local targetName = targetNames[i] or ("Target " .. i)
		local target = self:CreateTarget(position, targetName, levelData.LevelNumber)
		table.insert(targets, target)
	end
	
	print("[TargetSpawner] Spawned", #targets, "targets")
	return targets
end

-- ============================================================================
-- CREATE INDIVIDUAL TARGET
-- ============================================================================

function TargetSpawner:CreateTarget(position, punName, levelNumber)
	-- Create target model
	local targetModel = Instance.new("Model")
	targetModel.Name = punName
	targetModel:MoveTo(position)
	
	-- Main target part (neon pink block - silhouette style)
	local targetPart = Instance.new("Part")
	targetPart.Name = "TargetPart"
	targetPart.Shape = Enum.PartType.Block
	targetPart.Size = Vector3.new(2, 3, 0.5) -- Larger, more visible silhouette
	targetPart.Color = Color3.fromRGB(255, 20, 147) -- Neon pink
	targetPart.Material = Enum.Material.Neon
	targetPart.CanCollide = false
	targetPart.CastShadow = false
	targetPart.TopSurface = Enum.SurfaceType.Smooth
	targetPart.BottomSurface = Enum.SurfaceType.Smooth
	targetPart.Parent = targetModel
	
	-- Add head part for more visual interest
	local headPart = Instance.new("Part")
	headPart.Name = "Head"
	headPart.Shape = Enum.PartType.Ball
	headPart.Size = Vector3.new(0.8, 0.8, 0.8)
	headPart.Color = Color3.fromRGB(255, 100, 150)
	headPart.Material = Enum.Material.Neon
	headPart.CanCollide = false
	headPart.CastShadow = false
	headPart.Parent = targetModel
	
	-- Weld head to body
	local weld = Instance.new("Weld")
	weld.Part0 = targetPart
	weld.Part1 = headPart
	weld.C1 = CFrame.new(0, 1.8, 0)
	weld.Parent = headPart
	
	-- Add a nameplate above the target
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(4, 0, 2, 0)
	billboard.MaxDistance = 500
	billboard.Parent = targetPart
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 0.3
	nameLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextColor3 = Color3.fromRGB(255, 20, 147)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = punName
	nameLabel.Parent = billboard
	
	targetModel.Parent = workspace
	
	-- Return target data
	return {
		Instance = targetModel,
		Position = position,
		Health = 1,
		MaxHealth = 1,
		PunName = punName,
		IsDefeated = false,
		Level = levelNumber,
	}
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

function TargetSpawner:DestroyAllTargets(targets)
	for _, target in ipairs(targets or {}) do
		if target.Instance and target.Instance.Parent then
			target.Instance:Destroy()
		end
	end
end

return TargetSpawner
