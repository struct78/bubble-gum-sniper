--[[
	DataStore persistence wrapper
	Handles saving and loading player data with retry logic
]]

local DataStoreService = game:GetService("DataStoreService")
local Persistence = {}

-- DataStore reference
Persistence.PlayerDataStore = DataStoreService:GetDataStore("BubbleGumSniper_Players")

-- ============================================================================
-- SAVE PLAYER DATA
-- ============================================================================

function Persistence:SavePlayerData(playerId, playerData, retries)
	retries = retries or 3
	
	for attempt = 1, retries do
		local success, err = pcall(function()
			self.PlayerDataStore:SetAsync(tostring(playerId), playerData)
		end)
		
		if success then
			print("[Persistence] Player data saved for", playerId)
			return true
		else
			print("[Persistence] Save failed (attempt", attempt, "):", err)
			if attempt < retries then
				wait(1) -- Retry delay
			end
		end
	end
	
	print("[Persistence] Failed to save data for", playerId, "after", retries, "attempts")
	return false
end

-- ============================================================================
-- LOAD PLAYER DATA
-- ============================================================================

function Persistence:LoadPlayerData(playerId, defaultData, retries)
	retries = retries or 3
	
	for attempt = 1, retries do
		local success, data = pcall(function()
			return self.PlayerDataStore:GetAsync(tostring(playerId))
		end)
		
		if success then
			if data then
				print("[Persistence] Player data loaded for", playerId)
				return data
			else
				print("[Persistence] No data found for", playerId, "using defaults")
				return defaultData
			end
		else
			print("[Persistence] Load failed (attempt", attempt, "):", data)
			if attempt < retries then
				wait(1) -- Retry delay
			end
		end
	end
	
	print("[Persistence] Failed to load data for", playerId, "using defaults")
	return defaultData
end

return Persistence
