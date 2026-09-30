--[[
	Camera system with third-person and first-person sniper view toggle
	Press Left Shift to switch between modes
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("constants"))

local SniperCamera = {}

-- Camera state
SniperCamera.State = {
	IsSniperMode = false, -- true = first-person, false = third-person
	ZoomLevels = Constants.Camera.ScopeZoomLevels,
	CurrentZoomIndex = 1,
	Position = Vector3.new(),
	CFrame = CFrame.new(),
	Sway = Vector3.new(),
	SwayTime = 0,
	Distance = 0,
	RotationX = 0,
	RotationY = 0,
	TargetRotationX = 0,
	TargetRotationY = 0,
	ThirdPersonDistance = 10,
	ThirdPersonHeight = 3,
}

SniperCamera.Character = nil
SniperCamera.RenderConnection = nil

-- ============================================================================
-- CAMERA HELPERS
-- ============================================================================

local function Lerp(a, b, t)
	return a + (b - a) * t
end

local function ClampRotationX(rotationX)
	return math.clamp(rotationX, -math.pi/2.5, math.pi/2.5)
end

local function GetCamera()
	return workspace.CurrentCamera
end

-- ============================================================================
-- FIRST-PERSON SNIPER CAMERA
-- ============================================================================

local function SetCharacterTransparency(character, transparency)
	if not character then return end
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = transparency
		end
	end
end

-- ============================================================================
-- THIRD-PERSON CAMERA
-- ============================================================================

local function UpdateThirdPersonCamera()
	local camera = GetCamera()
	if not camera then
		return
	end
	
	-- Force scriptable every frame to prevent default camera from taking over
	camera.CameraType = Enum.CameraType.Scriptable
	
	local character = SniperCamera.Character
	if not character then
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	
	-- Show local character in third-person
	SetCharacterTransparency(character, 0)
	
	-- Smoothly interpolate rotation
	SniperCamera.State.RotationX = Lerp(SniperCamera.State.RotationX, SniperCamera.State.TargetRotationX, 0.2)
	SniperCamera.State.RotationY = Lerp(SniperCamera.State.RotationY, SniperCamera.State.TargetRotationY, 0.2)
	
	local rotationCFrame = CFrame.Angles(SniperCamera.State.RotationX, SniperCamera.State.RotationY, 0)
	local baseCFrame = CFrame.new(humanoidRootPart.Position) * rotationCFrame
	
	-- Position camera behind and above character
	local offset = Vector3.new(0, SniperCamera.State.ThirdPersonHeight, SniperCamera.State.ThirdPersonDistance)
	local cameraPosition = baseCFrame * CFrame.new(offset).Position
	
	-- Raycast to avoid going through walls
	local rayOrigin = humanoidRootPart.Position + Vector3.new(0, 2, 0)
	local rayDirection = cameraPosition - rayOrigin
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	
	if raycastResult then
		cameraPosition = raycastResult.Position
	end
	
	camera.CFrame = CFrame.new(cameraPosition, humanoidRootPart.Position + Vector3.new(0, 2, 0))
	camera.FieldOfView = Constants.Camera.FOV
end

-- ============================================================================
-- FIRST-PERSON SNIPER CAMERA
-- ============================================================================

local function UpdateFirstPersonCamera()
	local camera = GetCamera()
	if not camera then
		return
	end
	
	-- Force scriptable every frame to prevent default camera from taking over
	camera.CameraType = Enum.CameraType.Scriptable
	
	local character = SniperCamera.Character
	if not character then
		return
	end
	
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	
	-- Smoothly interpolate rotation
	SniperCamera.State.RotationX = Lerp(SniperCamera.State.RotationX, SniperCamera.State.TargetRotationX, 0.2)
	SniperCamera.State.RotationY = Lerp(SniperCamera.State.RotationY, SniperCamera.State.TargetRotationY, 0.2)
	
	-- Apply scope sway if active
	if SniperCamera.State.CurrentZoomIndex > 1 then
		local swayConfig = Constants.Difficulty.ScopeSway
		local distance = SniperCamera.State.Distance or 0
		local swayAmount = swayConfig.MinSway + (distance / 500) * (swayConfig.MaxSway - swayConfig.MinSway)
		swayAmount = math.min(swayAmount, swayConfig.MaxSway)
		
		local swayX = math.sin(SniperCamera.State.SwayTime * swayConfig.SwayFrequency) * swayAmount
		local swayY = math.cos(SniperCamera.State.SwayTime * swayConfig.SwayFrequency * 0.7) * swayAmount
		
		SniperCamera.State.RotationX = SniperCamera.State.RotationX + swayY * 0.01
		SniperCamera.State.RotationY = SniperCamera.State.RotationY + swayX * 0.01
	end
	
	local rotationCFrame = CFrame.Angles(SniperCamera.State.RotationX, SniperCamera.State.RotationY, 0)
	
	-- Use head position but override orientation to rotation-only so the camera stays level
	local baseCFrame = CFrame.new(head.Position) * rotationCFrame
	
	-- Offset camera forward/up from head center so it doesn't clip through character
	local eyeOffset = Vector3.new(0, 0.5, -1.5)
	SniperCamera.State.CFrame = baseCFrame * CFrame.new(eyeOffset)
	
	camera.CFrame = SniperCamera.State.CFrame
	camera.Focus = SniperCamera.State.CFrame + SniperCamera.State.CFrame.LookVector * 100
	
	-- Hide local character in sniper mode to prevent clipping
	SetCharacterTransparency(character, 1)
end

-- ============================================================================
-- MOUSE INPUT
-- ============================================================================

local lastMousePosition = Vector2.new()

local function OnMouseMove(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		local inputPosition = Vector2.new(input.Position.X, input.Position.Y)
		local delta = inputPosition - lastMousePosition
		
		local sensitivity = Constants.Camera.MouseSensitivity * 0.003
		SniperCamera.State.TargetRotationY = SniperCamera.State.TargetRotationY + delta.X * sensitivity
		SniperCamera.State.TargetRotationX = SniperCamera.State.TargetRotationX - delta.Y * sensitivity
		SniperCamera.State.TargetRotationX = ClampRotationX(SniperCamera.State.TargetRotationX)
		
		lastMousePosition = inputPosition
	end
end

local function InitializeMouseLook()
	UserInputService.InputChanged:Connect(OnMouseMove)
	
	-- Hide default cursor in sniper mode
	local player = game:GetService("Players").LocalPlayer
	if player then
		local mouse = player:GetMouse()
		mouse.Icon = ""
	end
end

-- ============================================================================
-- CAMERA MODE TOGGLE
-- ============================================================================

function SniperCamera:ToggleSniperMode()
	self.State.IsSniperMode = not self.State.IsSniperMode
	
	if self.State.IsSniperMode then
		-- Switch to sniper view (2x zoom default)
		self.State.CurrentZoomIndex = 2
		self:SetZoom(self.State.ZoomLevels[self.State.CurrentZoomIndex])
		print("[Camera] Sniper mode ON")
	else
		-- Switch back to third-person
		self.State.CurrentZoomIndex = 1
		self:SetZoom(1.0)
		print("[Camera] Sniper mode OFF")
	end
	
	return self.State.IsSniperMode
end

function SniperCamera:SetZoom(zoomLevel)
	local camera = GetCamera()
	if camera then
		local fov = Constants.Camera.FOV / zoomLevel
		camera.FieldOfView = fov
		print("[Camera] Zoom set to", zoomLevel, "x (FOV:", fov, ")")
	end
end

function SniperCamera:CycleZoomLevel()
	if not self.State.IsSniperMode then return end
	
	self.State.CurrentZoomIndex = (self.State.CurrentZoomIndex % #self.State.ZoomLevels) + 1
	local zoomLevel = self.State.ZoomLevels[self.State.CurrentZoomIndex]
	self:SetZoom(zoomLevel)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function SniperCamera:Initialize(character)
	print("[Camera] Initializing camera system for character:", character and character.Name or "nil")
	
	if not character then
		warn("[Camera] Initialize called with nil character")
		return
	end
	
	self.Character = character
	
	-- Ensure required parts exist
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local head = character:WaitForChild("Head")
	print("[Camera] Found HumanoidRootPart:", humanoidRootPart and true or false, "Head:", head and true or false)
	
	-- Set camera to scriptable (must use current camera dynamically)
	local camera = GetCamera()
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
		print("[Camera] Set CameraType to Scriptable")
	else
		warn("[Camera] workspace.CurrentCamera is nil during init!")
	end
	
	-- Ensure camera type stays scriptable if camera changes
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local newCamera = GetCamera()
		if newCamera then
			newCamera.CameraType = Enum.CameraType.Scriptable
			print("[Camera] Re-applied Scriptable to new CurrentCamera")
		end
	end)
	
	-- Initialize mouse-look
	InitializeMouseLook()
	
	-- Unbind any previous camera update
	if self.RenderConnection then
		pcall(function()
			RunService:UnbindFromRenderStep("BubbleGumSniperCamera")
		end)
	end
	
	-- Update camera every frame using RenderStepped
	local lastFrameTime = tick()
	local frameCounter = 0
	self.RenderConnection = RunService.RenderStepped:Connect(function()
		local currentTime = tick()
		local deltaTime = currentTime - lastFrameTime
		lastFrameTime = currentTime
		
		-- Update sway time in sniper mode
		if self.State.IsSniperMode then
			self.State.SwayTime = self.State.SwayTime + deltaTime
			UpdateFirstPersonCamera()
		else
			UpdateThirdPersonCamera()
		end
		
		-- Debug telemetry every ~1 second
		frameCounter = frameCounter + 1
		if frameCounter % 60 == 0 then
			local cam = GetCamera()
			local char = self.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			print("[Camera] Mode:", self.State.IsSniperMode and "SNIPER" or "THIRD", 
				"CamPos:", cam and tostring(cam.CFrame.Position) or "nil",
				"HRP:", hrp and tostring(hrp.Position) or "nil")
		end
	end)
	
	print("[Camera] Camera system ready - Third person active")
	
	-- Start in third person
	self:SetZoom(1.0)
end

return SniperCamera
