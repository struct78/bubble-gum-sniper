--[[
	Server-side shop handler
	Processes purchases, updates inventory, persists data
]]

local ShopHandler = {}

-- ============================================================================
-- PURCHASE COSMETIC
-- ============================================================================

function ShopHandler:PurchaseCosmetic(player, cosmeticId, playerData)
	-- Get cosmetics catalog
	local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
	local Shop = require(Server:WaitForChild("shop"):WaitForChild("cosmetics"))
	
	-- Find cosmetic
	local cosmetic = Shop:FindCosmetic(cosmeticId)
	if not cosmetic then
		return false, "Cosmetic not found"
	end
	
	-- Check ownership
	if playerData.Cosmetics.Owned[cosmeticId] then
		return false, "Already owned"
	end
	
	-- Check currency
	if playerData.SoftCurrency < cosmetic.Price then
		return false, "Insufficient currency"
	end
	
	-- Process purchase
	playerData.SoftCurrency = playerData.SoftCurrency - cosmetic.Price
	playerData.Cosmetics.Owned[cosmeticId] = cosmetic
	
	print("[ShopHandler] Player", player.Name, "purchased", cosmetic.Name)
	return true, "Purchase successful", playerData
end

-- ============================================================================
-- EQUIP COSMETIC
-- ============================================================================

function ShopHandler:EquipCosmetic(player, cosmeticId, playerData)
	-- Get cosmetics catalog
	local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
	local Shop = require(Server:WaitForChild("shop"):WaitForChild("cosmetics"))
	
	-- Find cosmetic
	local cosmetic = Shop:FindCosmetic(cosmeticId)
	if not cosmetic then
		return false, "Cosmetic not found"
	end
	
	-- Check ownership
	if not playerData.Cosmetics.Owned[cosmeticId] then
		return false, "Not owned"
	end
	
	-- Equip to appropriate slot
	playerData.Cosmetics.Equipped[cosmetic.Category] = cosmeticId
	
	-- Notify client to apply cosmetic visuals
	-- TODO: Send event to client with cosmetic data
	
	print("[ShopHandler] Player", player.Name, "equipped", cosmetic.Name)
	return true, "Cosmetic equipped", playerData
end

return ShopHandler
