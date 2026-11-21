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
	bubble.Size = Vector3.new(1.2, 1.2, 1.2) -- Larger so it's easier to see
	bubble.Color = Color3.fromRGB(255, 105, 180) -- Hot pink bubble gum
	bubble.Material = Enum.Material.Neon
	bubble.CanCollide = false
	bubble.Anchored = true -- Anchored so Roblox physics doesn't apply gravity
	bubble.TopSurface = Enum.SurfaceType.Smooth
	bubble.BottomSurface = Enum.SurfaceType.Smooth
	bubble.CFrame = CFrame.new(position)
	bubble.Parent = workspace
	
	-- Add a glowing trail so the projectile is visible
	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 0, 0.5)
	attachment0.Parent = bubble
	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, 0, -0.5)
	attachment1.Parent = bubble
	local trail = Instance.new("Trail")
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 105, 180))
	trail.Transparency = NumberSequence.new(0.3, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Lifetime = 0.3
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Parent = bubble
	
	local safeVelocity = velocity.Unit * math.max(velocity.Magnitude, 100)
	print("[Projectile] Created at", tostring(position), "vel:", tostring(safeVelocity))
	
	local projectileData = {
		Instance = bubble,
		Position = position,
		Velocity = safeVelocity,
		Wind = Vector3.new(0, 0, 0),
		CreatedAt = tick(),
		Caliber = caliber or "small",
		IsActive = true,
		Stuck = false,
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

-- ============================================================================
-- SURFACE STICKING
-- ============================================================================

function Projectile:StickToSurface(projectileData, hitResult)
	if projectileData.Stuck then return end
	projectileData.Stuck = true
	projectileData.IsActive = false
	
	local hitPart = hitResult.Instance
	local hitPosition = hitResult.Position
	local hitNormal = hitResult.Normal
	
	if hitPart and hitPart.CanCollide then
		-- Stop movement
		projectileData.Velocity = Vector3.new(0, 0, 0)
		
		local bubble = projectileData.Instance
		if bubble and bubble.Parent then
			-- Position slightly above surface
			bubble.Position = hitPosition + hitNormal * (bubble.Size.Y / 2)
			bubble.Anchored = true
			bubble.Velocity = Vector3.new()
			
			-- Weld to surface so it moves with the object
			local weld = Instance.new("Weld")
			weld.Part0 = bubble
			weld.Part1 = hitPart
			weld.C0 = bubble.CFrame:ToObjectSpace(hitPart.CFrame):Inverse()
			weld.Parent = bubble
			
			-- Preserve the stopped projectile's geometry, but replace the visible splat.
			local splatScale = Vector3.new(1.8, 0.3, 1.8)
			bubble.Size = splatScale
			bubble.CFrame = CFrame.lookAt(bubble.Position, bubble.Position + hitNormal) * CFrame.Angles(math.rad(90), 0, 0)
		end
		
		print("[Projectile] Bubble stuck to", hitPart.Name)
	else
		self:Deactivate(projectileData)
	end
end

function Projectile.HideSplat(projectileData)
	local bubble = projectileData.Instance
	if not bubble or not bubble.Parent then return end

	bubble.Transparency = 1
	local trail = bubble:FindFirstChildOfClass("Trail")
	if trail then
		trail.Enabled = false
		trail:Clear()
	end
end

return Projectile
