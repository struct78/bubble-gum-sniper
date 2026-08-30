--[[
	Target system
	Manages target instances, health, and hit detection
]]

local Target = {}
Target.ActiveTargets = {}

-- ============================================================================
-- TARGET CREATION
-- ============================================================================

function Target:Create(position, punName, level)
	-- Create target model
	local model = Instance.new("Model")
	model.Name = punName
	
	-- Create target part (red box)
	local part = Instance.new("Part")
	part.Name = "TargetPart"
	part.Shape = Enum.PartType.Block
	part.Size = Vector3.new(1.5, 4, 0.3)
	part.Color = Color3.fromRGB(255, 20, 147) -- Neon pink
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	
	model:MoveTo(position)
	model.Parent = workspace
	
	local targetData = {
		Instance = model,
		Position = position,
		Health = 1, -- One-shot target
		MaxHealth = 1,
		PunName = punName,
		IsDefeated = false,
		Level = level,
	}
	
	table.insert(self.ActiveTargets, targetData)
	
	return targetData
end

-- ============================================================================
-- TARGET HEALTH & DEFEAT
-- ============================================================================

function Target:TakeDamage(targetData, damage)
	if targetData.IsDefeated then return end
	
	targetData.Health = targetData.Health - damage
	
	if targetData.Health <= 0 then
		self:Defeat(targetData)
	end
end

function Target:Defeat(targetData)
	targetData.IsDefeated = true
	
	-- Play burst effect
	self:PlayBurstEffect(targetData.Position)
	
	-- Destroy model
	if targetData.Instance and targetData.Instance.Parent then
		targetData.Instance:Destroy()
	end
end

-- ============================================================================
-- VISUAL EFFECTS
-- ============================================================================

function Target:PlayBurstEffect(position)
	-- TODO: Create particle burst effect
	-- For now, just print
	print("[Target] Bubble burst at", position)
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

function Target:CleanupAll()
	for _, targetData in ipairs(self.ActiveTargets) do
		if targetData.Instance and targetData.Instance.Parent then
			targetData.Instance:Destroy()
		end
	end
	self.ActiveTargets = {}
end

return Target
