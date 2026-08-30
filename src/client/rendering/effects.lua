--[[
	Visual effects system
	Particle effects, screen shake, hit feedback
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Effects = {}

-- ============================================================================
-- BUBBLE BURST EFFECT
-- ============================================================================

function Effects:PlayBubbleBurst(position)
	-- Create particle effect for bubble burst
	local particles = {}
	
	for i = 1, 20 do
		local particle = Instance.new("Part")
		particle.Name = "BubbleParticle"
		particle.Shape = Enum.PartType.Ball
		particle.Size = Vector3.new(0.5, 0.5, 0.5)
		particle.Color = Color3.fromRGB(255, 255, 0) -- Yellow
		particle.Material = Enum.Material.Neon
		particle.CanCollide = false
		particle.CFrame = CFrame.new(position) + Vector3.new(
			math.random(-5, 5),
			math.random(-5, 5),
			math.random(-5, 5)
		)
		particle.Parent = workspace
		
		-- Trajectory
		local speed = 50
		local direction = (particle.Position - position).Unit
		particle.Velocity = direction * speed
		
		-- Fade out over time
		local startTime = tick()
		local lifetime = 1.0
		
		spawn(function()
			while tick() - startTime < lifetime do
				local elapsed = tick() - startTime
				local alpha = 1 - (elapsed / lifetime)
				
				if particle and particle.Parent then
					particle.Transparency = 1 - alpha
				end
				
				RunService.Heartbeat:Wait()
			end
			
			if particle then
				particle:Destroy()
			end
		end)
	end
	
	print("[Effects] Bubble burst at", position)
end

-- ============================================================================
-- SCREEN SHAKE
-- ============================================================================

function Effects:ScreenShake(intensity, duration)
	local camera = workspace.CurrentCamera
	local originalCFrame = camera.CFrame
	
	local startTime = tick()
	
	spawn(function()
		while tick() - startTime < duration do
			local elapsed = tick() - startTime
			local progress = elapsed / duration
			
			local shake = Vector3.new(
				(math.random() - 0.5) * intensity * (1 - progress),
				(math.random() - 0.5) * intensity * (1 - progress),
				(math.random() - 0.5) * intensity * (1 - progress)
			)
			
			camera.CFrame = originalCFrame * CFrame.new(shake)
			RunService.RenderStepped:Wait()
		end
		
		camera.CFrame = originalCFrame
	end)
end

-- ============================================================================
-- HIT MARKER
-- ============================================================================

function Effects:ShowHitMarker()
	-- TODO: Display hit marker on screen for brief moment
	print("[Effects] Hit marker!")
end

return Effects
