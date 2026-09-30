--[[
	Client-side input handler
	Supports both PC (mouse/keyboard) and mobile (touch/gyro)
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local InputController = {}

-- Input state
InputController.State = {
	MousePosition = Vector2.new(),
	MouseDelta = Vector2.new(),
	IsFirePressed = false,
	IsScopeToggled = false,
	CurrentZoomLevel = 1,
}

-- Input events
function InputController.CreateInputSignal()
	local bindable = Instance.new("BindableEvent")
	local Signal = {}
	
	function Signal:Connect(callback)
		return bindable.Event:Connect(callback)
	end
	
	function Signal:Wait()
		return bindable.Event:Wait()
	end
	
	function Signal:Fire(...)
		bindable:Fire(...)
	end
	
	return Signal
end

InputController.OnMouseMove = InputController.CreateInputSignal()
InputController.OnFire = InputController.CreateInputSignal()
InputController.OnScopeToggle = InputController.CreateInputSignal()
InputController.OnZoomChange = InputController.CreateInputSignal()
InputController.OnSniperModeToggle = InputController.CreateInputSignal()

-- ============================================================================
-- PC INPUT (MOUSE & KEYBOARD)
-- ============================================================================

local function InitializePCInput()
	-- Mouse movement
	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			InputController.State.MouseDelta = input.Delta
			InputController.OnMouseMove:Fire(input.Delta)
		end
	end)
	
	-- Key input
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		print("[Input] InputBegan:", input.UserInputType.Name, input.KeyCode.Name, "gameProcessed:", gameProcessed)
		
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.F or input.UserInputType == Enum.UserInputType.MouseButton1 then
			print("[Input] Fire pressed")
			InputController.State.IsFirePressed = true
			InputController.OnFire:Fire(true)
		elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.LeftControl then
			-- Toggle third-person / sniper mode
			InputController.OnSniperModeToggle:Fire()
		elseif input.KeyCode == Enum.KeyCode.Q then
			-- Zoom out
			InputController.OnZoomChange:Fire(Enum.KeyCode.Q)
		elseif input.KeyCode == Enum.KeyCode.E then
			-- Zoom in
			InputController.OnZoomChange:Fire(Enum.KeyCode.E)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.F or input.UserInputType == Enum.UserInputType.MouseButton1 then
			InputController.State.IsFirePressed = false
			InputController.OnFire:Fire(false)
		end
	end)
end

-- ============================================================================
-- MOBILE INPUT (TOUCH & GYRO)
-- ============================================================================

local function InitializeMobileInput()
	-- TODO: Implement touch input for mobile
	-- - Touch screen movement (look around)
	-- - Button UI for fire, scope, zoom
	-- - Gyro aiming (device rotation)
	print("[Input] Mobile input initialization pending")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function InputController:Initialize()
	-- Detect mobile by checking if TouchEnabled is available
	if UserInputService.TouchEnabled then
		InitializeMobileInput()
	else
		InitializePCInput()
	end
	print("[Input] Input controller initialized")
end

return InputController
