--[[
	Sniper weapon system
	Handles firing projectiles, ammo management, and recoil
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("constants"))

local Weapon = {}

-- Weapon state
Weapon.State = {
	CurrentAmmo = Constants.Level.AmmoCap,
	MaxAmmo = Constants.Level.AmmoCap,
	IsReloading = false,
	ReloadTime = 1.5,
	FireRate = 0.5, -- Seconds between shots
	LastFireTime = 0,
}

-- ============================================================================
-- FIRING SYSTEM
-- ============================================================================

function Weapon:CanFire()
	-- Check ammo
	if self.State.CurrentAmmo <= 0 then
		return false, "Out of ammo"
	end
	
	-- Check fire rate
	if tick() - self.State.LastFireTime < self.State.FireRate then
		return false, "Weapon cooling down"
	end
	
	-- Check reload state
	if self.State.IsReloading then
		return false, "Reloading"
	end
	
	return true
end

function Weapon:Fire(character, cameraDirection, wind)
	local canFire, reason = self:CanFire()
	
	if not canFire then
		return false, reason
	end
	
	-- Calculate initial velocity
	local muzzleVelocity = Constants.Projectile.Velocity
	local initialVelocity = cameraDirection * muzzleVelocity
	
	-- Get spawn position (from weapon muzzle)
	local head = character:FindFirstChild("Head")
	if not head then return false, "No head found" end
	
	local spawnPosition = head.Position + head.CFrame.LookVector * 5
	
	-- Fire projectile (server-side)
	self:FireProjectile(spawnPosition, initialVelocity, wind)
	
	-- Consume ammo
	self.State.CurrentAmmo = self.State.CurrentAmmo - 1
	self.State.LastFireTime = tick()
	
	-- Apply recoil (camera shake)
	-- TODO: Send recoil effect to client
	
	return true
end

function Weapon:FireProjectile(position, velocity, wind)
	-- Projectile creation happens server-side
	-- TODO: Call Projectile:Create() and start physics simulation
	print("[Weapon] Firing projectile at", position, "with velocity", velocity)
end

-- ============================================================================
-- AMMO MANAGEMENT
-- ============================================================================

function Weapon:Reload()
	if self.State.IsReloading then return end
	
	self.State.IsReloading = true
	print("[Weapon] Reloading...")
	
	-- Reload animation/wait
	wait(self.State.ReloadTime)
	
	self.State.CurrentAmmo = self.State.MaxAmmo
	self.State.IsReloading = false
	print("[Weapon] Reload complete")
end

function Weapon:RefillAmmo(amount)
	self.State.CurrentAmmo = math.min(self.State.CurrentAmmo + amount, self.State.MaxAmmo)
end

return Weapon
