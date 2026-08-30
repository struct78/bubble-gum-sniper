--[[
	Game configuration and setup utilities
]]

local Config = {}

-- Environment detection
Config.Environment = {
	IsServer = game:GetService("RunService"):IsServer(),
	IsClient = game:GetService("RunService"):IsClient(),
	IsStudio = game:GetService("RunService"):IsStudio(),
}

-- Game states
Config.GameState = {
	LOADING = "Loading",
	MENU = "Menu",
	IN_GAME = "InGame",
	PAUSED = "Paused",
	LEVEL_COMPLETE = "LevelComplete",
	GAME_OVER = "GameOver",
}

-- Custom signals for game events
function Config.CreateSignal()
	local Signal = {}
	Signal._bindable = Instance.new("BindableEvent")
	
	function Signal:Connect(callback)
		return self._bindable.Event:Connect(callback)
	end
	
	function Signal:Wait()
		return self._bindable.Event:Wait()
	end
	
	function Signal:Fire(...)
		self._bindable:Fire(...)
	end
	
	return Signal
end

return Config
