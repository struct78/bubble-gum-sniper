--[[
	Remote events for client-server communication
	Handles firing, hit validation, and game state updates
]]

local RemoteEvents = {}

-- Create remote event folder
local function CreateRemoteEvents()
	local remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "RemoteEvents"
	remoteFolder.Parent = game:GetService("ReplicatedStorage")
	
	-- Fire event (client → server)
	local fireEvent = Instance.new("RemoteEvent")
	fireEvent.Name = "Fire"
	fireEvent.Parent = remoteFolder
	
	-- Hit event (server → client)
	local hitEvent = Instance.new("RemoteEvent")
	hitEvent.Name = "Hit"
	hitEvent.Parent = remoteFolder

	local bubblePopEvent = Instance.new("RemoteEvent")
	bubblePopEvent.Name = "BubblePop"
	bubblePopEvent.Parent = remoteFolder
	
	-- Update HUD event (server → client)
	local updateHUDEvent = Instance.new("RemoteEvent")
	updateHUDEvent.Name = "UpdateHUD"
	updateHUDEvent.Parent = remoteFolder
	
	-- Level complete event (server → client)
	local levelCompleteEvent = Instance.new("RemoteEvent")
	levelCompleteEvent.Name = "LevelComplete"
	levelCompleteEvent.Parent = remoteFolder
	
	-- Purchase cosmetic event (client → server)
	local purchaseCosmeticEvent = Instance.new("RemoteEvent")
	purchaseCosmeticEvent.Name = "PurchaseCosmetic"
	purchaseCosmeticEvent.Parent = remoteFolder
	
	-- Equip cosmetic event (client → server)
	local equipCosmeticEvent = Instance.new("RemoteEvent")
	equipCosmeticEvent.Name = "EquipCosmetic"
	equipCosmeticEvent.Parent = remoteFolder
	
	-- Cosmetics data event (server → client)
	local cosmeticsDataEvent = Instance.new("RemoteEvent")
	cosmeticsDataEvent.Name = "CosmeticsData"
	cosmeticsDataEvent.Parent = remoteFolder
	
	print("[RemoteEvents] Created remote events")
	
	return {
		Fire = fireEvent,
		Hit = hitEvent,
		BubblePop = bubblePopEvent,
		UpdateHUD = updateHUDEvent,
		LevelComplete = levelCompleteEvent,
		PurchaseCosmetic = purchaseCosmeticEvent,
		EquipCosmetic = equipCosmeticEvent,
		CosmeticsData = cosmeticsDataEvent,
		Folder = remoteFolder,
	}
end

RemoteEvents.Events = CreateRemoteEvents()

-- ============================================================================
-- EVENT HANDLERS (to be connected by server/client)
-- ============================================================================

function RemoteEvents:GetFireEvent()
	return self.Events.Fire
end

function RemoteEvents:GetHitEvent()
	return self.Events.Hit
end

function RemoteEvents:GetUpdateHUDEvent()
	return self.Events.UpdateHUD
end

function RemoteEvents:GetLevelCompleteEvent()
	return self.Events.LevelComplete
end

function RemoteEvents:GetPurchaseCosmeticEvent()
	return self.Events.PurchaseCosmetic
end

function RemoteEvents:GetEquipCosmeticEvent()
	return self.Events.EquipCosmetic
end

function RemoteEvents:GetCosmeticsDataEvent()
	return self.Events.CosmeticsData
end

return RemoteEvents
