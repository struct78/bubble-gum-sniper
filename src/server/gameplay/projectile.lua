--[[
	Server-side projectile system
	Handles bubble gum projectile spawning, physics, and collision
]]

local Debris = game:GetService("Debris")

local Projectile = {}
Projectile.ActiveProjectiles = {}

-- ============================================================================
-- PROJECTILE CREATION
-- ============================================================================

function Projectile:Create(position, velocity, caliber)
	-- Create projectile part
	local bubble = Instance.new("Part")
	bubble.Name = "BubbleGumProjectile"
	bubble.Shape = Enum.PartType.Ball
	bubble.Size = Vector3.new(0.3, 0.3, 0.3)
	bubble.Color = Color3.fromRGB(255, 200, 100) -- Bubble gum color
	bubble.Material = Enum.Material.Neon
	bubble.CanCollide = false
	bubble.TopSurface = Enum.SurfaceType.Smooth
	bubble.BottomSurface = Enum.SurfaceType.Smooth
	bubble.CFrame = CFrame.new(position)
	bubble.Velocity = velocity
	bubble.Parent = workspace
	
	local projectileData = {
		Instance = bubble,
		Position = position,
		Velocity = velocity,
		Wind = Vector3.new(0, 0, 0),
		CreatedAt = tick(),
		Caliber = caliber or "small",
		IsActive = true,
	}
	
	table.insert(self.ActiveProjectiles, projectileData)
	
	-- Cleanup after max lifetime
	Debris:AddItem(bubble, 30)
	
	return projectileData
end

-- ============================================================================
-- PROJECTILE PHYSICS UPDATE
-- ============================================================================

function Projectile:ApplyPhysics(deltaTime, wind, gravity)
	for i, proj in ipairs(self.ActiveProjectiles) do
		if proj.IsActive and proj.Instance and proj.Instance.Parent then
			-- Apply gravity
			proj.Velocity = proj.Velocity + Vector3.new(0, -gravity * deltaTime, 0)
			
			-- Apply wind
			proj.Velocity = proj.Velocity + (wind * deltaTime)
			
			-- Update position
			proj.Position = proj.Position + proj.Velocity * deltaTime
			proj.Instance.Position = proj.Position
		else
			-- Remove inactive projectile
			table.remove(self.ActiveProjectiles, i)
		end
	end
end

-- ============================================================================
-- COLLISION DETECTION
-- ============================================================================

function Projectile:CheckCollision(projectile, targets)
	local hits = {}
	
	for _, target in ipairs(targets) do
		local distance = (projectile.Position - target.Position).Magnitude
		
		-- Hit if within radius
		if distance < 5 then -- 5 studs hit radius
			table.insert(hits, {
				Target = target,
				Distance = distance,
				Accuracy = 1 - (distance / 5), -- 0-1 accuracy
			})
		end
	end
	
	return hits
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

function Projectile:Deactivate(projectileData)
	projectileData.IsActive = false
	if projectileData.Instance and projectileData.Instance.Parent then
		projectileData.Instance:Destroy()
	end
end

return Projectile
