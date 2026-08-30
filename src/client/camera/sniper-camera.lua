--[[
	First-person camera system with scope overlay and zoom
	Handles camera positioning, zoom levels, scope UI, and scope sway
]]

local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("constants"))

local SniperCamera = {}

-- Camera state
SniperCamera.State = {
	IsScoped = false,
	CurrentZoom = 1.0,
	ZoomLevels = Constants.Camera.ScopeZoomLevels,
	CurrentZoomIndex = 1,
	Position = Vector3.new(),
	CFrame = CFrame.new(),
	Sway = Vector3.new(),
	SwayTime = 0,
	Distance = 0,
	Target = nil,
	RotationX = 0,
	RotationY = 0,
}

-- ============================================================================
-- CAMERA UPDATE
-- ============================================================================

local function UpdateCameraPosition(humanoidRootPart, head)
	if not humanoidRootPart or not head then return end
	
	-- First-person camera from head
	SniperCamera.State.Position = head.Position
	
	-- Apply mouse-look rotation
	local rotationCFrame = CFrame.Angles(SniperCamera.State.RotationX, SniperCamera.State.RotationY, 0)
	SniperCamera.State.CFrame = head.CFrame * rotationCFrame
	
	-- Apply scope sway if active
	if SniperCamera.State.IsScoped then
		SniperCamera:ApplyScopeSway()
	end
	
	Camera.CFrame = SniperCamera.State.CFrame
	Camera.Focus = SniperCamera.State.CFrame + SniperCamera.State.CFrame.LookVector * 100
end

local function UpdateScopeSway(head)
	if not SniperCamera.State.IsScoped then return end
	
	-- Add wobble to simulate scope sway at distance
	local swayConfig = Constants.Difficulty.ScopeSway
	if not swayConfig.Enabled then return end
	
	SniperCamera.State.SwayTime = SniperCamera.State.SwayTime + RunService.RenderStepped:Wait()
	
	-- Sway increases with distance
	local distance = SniperCamera.State.Distance or 0
	local swayAmount = swayConfig.MinSway + (distance / 500) * (swayConfig.MaxSway - swayConfig.MinSway)
	swayAmount = math.min(swayAmount, swayConfig.MaxSway)
	
	-- Sine wave sway pattern
	local swayX = math.sin(SniperCamera.State.SwayTime * swayConfig.SwayFrequency) * swayAmount
	local swayY = math.cos(SniperCamera.State.SwayTime * swayConfig.SwayFrequency * 0.7) * swayAmount
	
	SniperCamera.State.Sway = Vector3.new(swayX, swayY, 0)
end

-- ============================================================================
-- MOUSE-LOOK (PC INPUT)
-- ============================================================================

local lastMousePosition = Vector2.new()
local isMouseLocked = false

local function OnMouseMove(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - lastMousePosition
		
		local sensitivity = Constants.Camera.MouseSensitivity * 0.003
		SniperCamera.State.RotationY = SniperCamera.State.RotationY + delta.X * sensitivity
		SniperCamera.State.RotationX = SniperCamera.State.RotationX - delta.Y * sensitivity
		
		-- Clamp vertical rotation to prevent flipping
		SniperCamera.State.RotationX = math.clamp(SniperCamera.State.RotationX, -math.pi/2.5, math.pi/2.5)
		
		lastMousePosition = input.Position
	end
end

local function InitializeMouseLook()
	UserInputService.InputChanged:Connect(OnMouseMove)
	
	-- Lock cursor to window when game is focused
	Camera.CameraType = Enum.CameraType.Scriptable
	mouse = game:GetService("Players").LocalPlayer:GetMouse()
	mouse.Icon = "rbxasset://textures/Cursors/MouseLockedCursor.png"
end

-- ============================================================================
-- ZOOM & SCOPE CONTROL
-- ============================================================================

function SniperCamera:SetZoom(zoomLevel)
	self.State.CurrentZoom = zoomLevel
	local fov = Constants.Camera.FOV / zoomLevel
	Camera.FieldOfView = fov
	print("[Camera] Zoom set to", zoomLevel, "x (FOV:", fov, ")")
end

function SniperCamera:CycleZoomLevel()
	if not self.State.IsScoped then return end
	
	-- Move to next zoom level
	self.State.CurrentZoomIndex = (self.State.CurrentZoomIndex % #self.State.ZoomLevels) + 1
	local zoomLevel = self.State.ZoomLevels[self.State.CurrentZoomIndex]
	self:SetZoom(zoomLevel)
end

function SniperCamera:ToggleScope(isActive)
	self.State.IsScoped = isActive
	
	if isActive then
		-- Zoom in to first scope level
		self.State.CurrentZoomIndex = 2 -- Start at 2x, not 1x
		self:SetZoom(self.State.ZoomLevels[self.State.CurrentZoomIndex])
		print("[Camera] Scope activated")
	else
		-- Reset to 1x
		self.State.CurrentZoomIndex = 1
		self:SetZoom(1.0)
		print("[Camera] Scope deactivated")
	end
	
	-- TODO: Show/hide scope overlay UI
end

-- ============================================================================
-- SCOPE SWAY APPLICATION
-- ============================================================================

function SniperCamera:ApplyScopeSway()
	if not self.State.Sway then return end
	
	-- Apply sway to rotation
	SniperCamera.State.RotationX = SniperCamera.State.RotationX + self.State.Sway.Y * 0.01
	SniperCamera.State.RotationY = SniperCamera.State.RotationY + self.State.Sway.X * 0.01
end

-- ============================================================================
-- THERMAL SCOPE MODE
-- ============================================================================

function SniperCamera:ActivateThermalScope()
	-- Desaturate world, highlight targets
	-- TODO: Apply color correction to camera
	-- TODO: Highlight active targets with neon glow
	print("[Camera] Thermal scope activated")
end

function SniperCamera:DeactivateThermalScope()
	-- Reset world colors
	-- TODO: Remove color correction
	print("[Camera] Thermal scope deactivated")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function SniperCamera:Initialize(character)
	print("[Camera] Initializing first-person camera")
	
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local head = character:WaitForChild("Head")
	
	-- Set camera to scriptable
	Camera.CameraType = Enum.CameraType.Scriptable
	UpdateCameraPosition(humanoidRootPart, head)
	
	-- Initialize mouse-look (PC only for now)
	InitializeMouseLook()
	
	-- Update camera every frame
	RunService.RenderStepped:Connect(function()
		UpdateCameraPosition(humanoidRootPart, head)
		UpdateScopeSway(head)
	end)
	
	print("[Camera] First-person camera ready")
	
	-- Set initial zoom
	self:SetZoom(1.0)
end

return SniperCamera
