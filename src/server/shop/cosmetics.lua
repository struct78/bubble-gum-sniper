--[[
	Shop system for cosmetics
	Manages cosmetics catalog, purchases, and inventory
]]

local Shop = {}

-- Cosmetics catalog
Shop.Catalog = {
	{
		Id = "scope_2x",
		Name = "2x Scope",
		Category = "Scope",
		Description = "Zoom in 2x on distant targets",
		Price = 250,
		Color = Color3.fromRGB(0, 200, 255),
		Rarity = "Common",
	},
	{
		Id = "scope_4x",
		Name = "4x Scope",
		Category = "Scope",
		Description = "Zoom in 4x on distant targets",
		Price = 500,
		Color = Color3.fromRGB(100, 200, 255),
		Rarity = "Rare",
	},
	{
		Id = "ammo_medium",
		Name = "Medium Calibubbles",
		Category = "Ammunition",
		Description = "Larger bubble gum projectiles",
		Price = 150,
		Color = Color3.fromRGB(255, 100, 100),
		Rarity = "Common",
	},
	{
		Id = "ammo_large",
		Name = "Large Calibubbles",
		Category = "Ammunition",
		Description = "Even larger bubble gum projectiles",
		Price = 350,
		Color = Color3.fromRGB(255, 50, 50),
		Rarity = "Rare",
	},
	{
		Id = "outfit_neon_pink",
		Name = "Neon Pink Outfit",
		Category = "Outfit",
		Description = "Bright pink camouflage",
		Price = 200,
		Color = Color3.fromRGB(255, 20, 147),
		Rarity = "Common",
	},
	{
		Id = "gun_skin_plastic",
		Name = "Plastic Gun Skin",
		Category = "GunSkin",
		Description = "Bright plastic-looking gun",
		Price = 100,
		Color = Color3.fromRGB(255, 200, 100),
		Rarity = "Common",
	},
}

-- ============================================================================
-- PURCHASE
-- ============================================================================

function Shop:Purchase(playerId, cosmeticId, playerData)
	local cosmetic = self:FindCosmetic(cosmeticId)
	
	if not cosmetic then
		return false, "Cosmetic not found"
	end
	
	if playerData.SoftCurrency < cosmetic.Price then
		return false, "Insufficient currency"
	end
	
	-- Deduct currency
	playerData.SoftCurrency = playerData.SoftCurrency - cosmetic.Price
	
	-- Add to inventory
	if not playerData.Cosmetics.Owned[cosmeticId] then
		playerData.Cosmetics.Owned[cosmeticId] = cosmetic
	end
	
	return true, "Purchase successful"
end

-- ============================================================================
-- EQUIP COSMETIC
-- ============================================================================

function Shop:EquipCosmetic(playerId, cosmeticId, playerData)
	local cosmetic = self:FindCosmetic(cosmeticId)
	
	if not cosmetic then
		return false, "Cosmetic not found"
	end
	
	-- Equip to appropriate slot
	playerData.Cosmetics.Equipped[cosmetic.Category] = cosmeticId
	
	-- TODO: Apply cosmetic to character model
	
	return true, "Cosmetic equipped"
end

-- ============================================================================
-- UTILITY
-- ============================================================================

function Shop:FindCosmetic(cosmeticId)
	for _, cosmetic in ipairs(self.Catalog) do
		if cosmetic.Id == cosmeticId then
			return cosmetic
		end
	end
	return nil
end

return Shop
