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
	return Instance.new("BindableEvent")
end

InputController.OnMouseMove = InputController.CreateInputSignal()
InputController.OnFire = InputController.CreateInputSignal()
InputController.OnScopeToggle = InputController.CreateInputSignal()
InputController.OnZoomChange = InputController.CreateInputSignal()

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
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
			InputController.State.IsFirePressed = true
			InputController.OnFire:Fire(true)
		elseif input.KeyCode == Enum.KeyCode.E then
			InputController.State.IsScopeToggled = not InputController.State.IsScopeToggled
			InputController.OnScopeToggle:Fire(InputController.State.IsScopeToggled)
		elseif input.KeyCode == Enum.KeyCode.Q then
			-- Zoom out
			InputController.OnZoomChange:Fire(Enum.KeyCode.Q)
		elseif input.KeyCode == Enum.KeyCode.W then
			-- Zoom in
			InputController.OnZoomChange:Fire(Enum.KeyCode.W)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
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
	if UserInputService:GetPlatform() == Enum.Platform.UWP or 
	   UserInputService:GetPlatform() == Enum.Platform.Mobile then
		InitializeMobileInput()
	else
		InitializePCInput()
	end
	print("[Input] Input controller initialized")
end

return InputController
