--[[
	Cosmetics application system
	Handles equipping and applying cosmetics to player models
]]

local CosmeticsVisuals = {}

-- ============================================================================
-- APPLY GUN SKIN
-- ============================================================================

function CosmeticsVisuals:ApplyGunSkin(character, skinId)
	-- TODO: Apply gun model/color based on skin
	print("[Cosmetics] Applied gun skin:", skinId)
end

-- ============================================================================
-- APPLY OUTFIT
-- ============================================================================

function CosmeticsVisuals:ApplyOutfit(character, outfitId)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Apply outfit color to character
	local colorMap = {
		outfit_neon_pink = Color3.fromRGB(255, 20, 147),
		outfit_neon_green = Color3.fromRGB(0, 255, 100),
		outfit_neon_blue = Color3.fromRGB(0, 200, 255),
		outfit_gold = Color3.fromRGB(255, 215, 0),
		outfit_silver = Color3.fromRGB(192, 192, 192),
	}
	
	local color = colorMap[outfitId] or Color3.fromRGB(255, 255, 255)
	
	-- Apply to all character parts
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Color = color
		end
	end
	
	print("[Cosmetics] Applied outfit:", outfitId)
end

-- ============================================================================
-- APPLY SCOPE
-- ============================================================================

function CosmeticsVisuals:ApplyScope(character, scopeId)
	-- Different scopes change zoom levels (handled in camera)
	print("[Cosmetics] Applied scope:", scopeId)
end

-- ============================================================================
-- APPLY AMMUNITION
-- ============================================================================

function CosmeticsVisuals:ApplyAmmunition(character, ammoId)
	-- Different ammo sizes change projectile size (handled in physics)
	print("[Cosmetics] Applied ammunition:", ammoId)
end

return CosmeticsVisuals
