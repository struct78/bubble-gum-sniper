--[[
	Physics engine for projectile simulation
	Handles gravity, wind, and trajectory calculations
]]

local PhysicsEngine = {}

-- ============================================================================
-- PROJECTILE SIMULATION
-- ============================================================================

function PhysicsEngine:SimulateProjectile(projectile, deltaTime, wind, gravity)
	-- Apply forces
	local acceleration = Vector3.new(0, -gravity, 0)
	
	-- Add wind force
	local windForce = wind * (0.1 / projectile.Velocity.Magnitude) -- Scale wind by velocity
	acceleration = acceleration + windForce
	
	-- Update velocity
	projectile.Velocity = projectile.Velocity + (acceleration * deltaTime)
	
	-- Update position
	projectile.Position = projectile.Position + (projectile.Velocity * deltaTime)
	
	-- Apply velocity to part (for visual representation)
	if projectile.Instance then
		projectile.Instance.Position = projectile.Position
		projectile.Instance.Velocity = projectile.Velocity
	end
	
	return projectile
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
