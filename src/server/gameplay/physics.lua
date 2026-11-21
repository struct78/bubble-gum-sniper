--[[
	Physics engine for projectile simulation
	Handles gravity, wind, and trajectory calculations
]]

local PhysicsEngine = {}

-- ============================================================================
-- PROJECTILE SIMULATION
-- ============================================================================

function PhysicsEngine:SimulateProjectile(projectile, deltaTime, wind, gravity)
	if projectile.Stuck then return projectile end
	
	print("[Physics] Simulate dt:", deltaTime, "pos:", tostring(projectile.Position), "vel:", tostring(projectile.Velocity), "grav:", gravity)
	
	-- Apply forces
	local acceleration = Vector3.new(0, -gravity, 0)
	
	-- Add wind force
	local speed = math.max(projectile.Velocity.Magnitude, 0.001)
	local windForce = wind * (0.1 / speed) -- Scale wind by velocity
	acceleration = acceleration + windForce
	
	-- Update velocity
	projectile.Velocity = projectile.Velocity + (acceleration * deltaTime)
	
	-- Raycast from current position to next position to detect surface hits
	local step = projectile.Velocity * deltaTime
	if step.Magnitude < 0.01 then
		step = projectile.Velocity.Unit * 0.5 -- minimum step for raycast
	end
	local nextPosition = projectile.Position + step
	local traversed = { Origin = projectile.Position, Displacement = step, Time = time() }
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { projectile.Instance }
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	local raycastResult = workspace:Raycast(projectile.Position, step, raycastParams)
	
	if raycastResult and raycastResult.Instance and raycastResult.Instance.CanCollide then
		traversed.Surface = raycastResult
		traversed.Displacement = raycastResult.Position - traversed.Origin
		-- Stick to surface
		projectile.Position = raycastResult.Position
		if projectile.Instance then
			projectile.Instance.Position = projectile.Position
		end
		
		local ProjectileModule = require(game:GetService("ServerScriptService").Server.gameplay.projectile)
		ProjectileModule:StickToSurface(projectile, raycastResult)
		return projectile, traversed
	end
	
	-- Update position
	projectile.Position = nextPosition
	
	-- Apply position to anchored part (no physics velocity)
	if projectile.Instance then
		projectile.Instance.CFrame = CFrame.new(projectile.Position)
		projectile.Instance.Rotation = Vector3.new(0, 0, 0)
	end
	
	return projectile, traversed
end

-- ============================================================================
-- TRAJECTORY PREDICTION (for debug visualization)
-- ============================================================================

function PhysicsEngine:PredictTrajectory(startPosition, velocity, wind, gravity, maxTime)
	-- Returns array of positions along predicted path
	local trajectory = { startPosition }
	local currentVelocity = velocity
	local currentPosition = startPosition
	local timeStep = 0.05 -- 50ms steps
	
	for t = 0, maxTime, timeStep do
		-- Apply gravity
		currentVelocity = currentVelocity + Vector3.new(0, -gravity * timeStep, 0)
		
		-- Apply wind
		currentVelocity = currentVelocity + (wind * timeStep)
		
		-- Update position
		currentPosition = currentPosition + (currentVelocity * timeStep)
		table.insert(trajectory, currentPosition)
		
		-- Stop if projectile goes too far or too low
		if currentPosition.Y < -100 or currentPosition.Magnitude > 500 then
			break
		end
	end
	
	return trajectory
end

-- ============================================================================
-- DISTANCE & ANGLE CALCULATIONS
-- ============================================================================

function PhysicsEngine:CalculateDistanceToTarget(shooterPosition, targetPosition)
	return (targetPosition - shooterPosition).Magnitude
end

function PhysicsEngine:CalculateRequiredLeadTime(projectileVelocity, distance, targetVelocity)
	-- Calculates lead time if target is moving
	-- For MVP, targets are stationary, but formula is ready
	if projectileVelocity == 0 then return 0 end
	return distance / projectileVelocity
end

return PhysicsEngine
