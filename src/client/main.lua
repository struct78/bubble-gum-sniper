--[[
	Client-side main initialization script
	Runs in the player's character/player and initializes all client systems
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Load shared modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("constants"))
local Config = require(Shared:WaitForChild("config"))

-- Load client modules
local InputController = require(script.Parent:WaitForChild("input"):WaitForChild("controller"))
local SniperCamera = require(script.Parent:WaitForChild("camera"):WaitForChild("sniper-camera"))
local HUD = require(script.Parent:WaitForChild("ui"):WaitForChild("hud"))
local ScopeUI = require(script.Parent:WaitForChild("ui"):WaitForChild("scope-overlay"))
local PauseMenu = require(script.Parent:WaitForChild("ui"):WaitForChild("pause-menu"))
local Effects = require(script.Parent:WaitForChild("rendering"):WaitForChild("effects"))

-- Get remote events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local FireEvent = RemoteEvents:WaitForChild("Fire")
local HitEvent = RemoteEvents:WaitForChild("Hit")
local UpdateHUDEvent = RemoteEvents:WaitForChild("UpdateHUD")
local LevelCompleteEvent = RemoteEvents:WaitForChild("LevelComplete")

-- Client state
local ClientState = {
	IsInitialized = false,
	CurrentLevel = 1,
	PlayerCharacter = nil,
	IsScoped = false,
	CurrentAmmo = 50,
	CurrentScore = 0,
	Wind = Vector3.new(0, 0, 0),
	Distance = 0,
}

-- ============================================================================
-- SERVER EVENT HANDLERS
-- ============================================================================

local function OnFire(firePosition, direction)
	-- Server sent fire event - play client-side effects
	Effects:ScreenShake(0.1, 0.1) -- Small screen shake
	print("[Client] Fire effect at", firePosition)
end

local function OnHit(hitPosition, score)
	-- Server sent hit event - play hit effects
	ClientState.CurrentScore = ClientState.CurrentScore + score
	Effects:PlayBubbleBurst(hitPosition)
	Effects:ShowHitMarker()
	HUD:UpdateScore(ClientState.CurrentScore)
	print("[Client] HIT! +", score, "points")
end

local function OnUpdateHUD(hudData)
	-- Update HUD with game state
	HUD:UpdateDistance(hudData.Distance or 0)
	HUD:UpdateWind(hudData.WindVector or Vector3.new(0, 0, 0))
	HUD:UpdateAmmo(hudData.Ammo or ClientState.CurrentAmmo, Constants.Level.AmmoCap)
	
	-- Store distance for scope UI
	ClientState.Distance = hudData.Distance or 0
	
	-- Update scope UI if active
	if ClientState.IsScoped then
		ScopeUI:UpdateDistance(ClientState.Distance)
		ScopeUI:UpdateWind(hudData.WindVector or Vector3.new(0, 0, 0))
		ScopeUI:UpdateBallistics(ClientState.Distance, (hudData.WindVector or Vector3.new()).Magnitude, Constants.Projectile.Velocity)
	end
	
	if hudData.LevelName then
		print("[Client] Level:", hudData.LevelName)
	end
end

local function OnLevelComplete(levelData)
	-- Server sent level complete event
	print("[Client] Level complete! Score:", levelData.Score)
	-- TODO: Show level complete screen
end

-- ============================================================================
-- FIRING HANDLER
-- ============================================================================

local function OnFireInput(isPressed)
	if not isPressed or not ClientState.IsInitialized then return end
	
	-- Get camera direction
	local camera = workspace.CurrentCamera
	local direction = camera.CFrame.LookVector
	
	-- Send fire event to server
	FireEvent:FireServer(ClientState.PlayerCharacter, {
		Position = camera.CFrame.Position,
		Direction = direction,
	})
	
	-- Play client-side effects immediately (for responsiveness)
	Effects:ScreenShake(0.15, 0.15)
	ClientState.CurrentAmmo = math.max(0, ClientState.CurrentAmmo - 1)
	HUD:UpdateAmmo(ClientState.CurrentAmmo, Constants.Level.AmmoCap)
end
INITIALIZATION
-- ============================================================================

local function Initialize()
	print("[Client] Initializing Bubble Gum Sniper client...")
	
	-- Get player and character
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	ClientState.PlayerCharacter = character
	
	print("[Client] Player:", player.Name)
	print("[Client] Character loaded")
	
	-- Initialize input system
	InputController:Initialize()
	
	-- Initialize first-person camera
	SniperCamera:Initialize(character)
	
	-- Initialize HUD
	HUD:Initialize()
	
	-- Initialize scope UI
	ScopeUI:Initialize()
	
	-- Initialize pause menu
	PauseMenu:Initialize()
	
	-- Connect to remote events
	FireEvent.OnClientEvent:Connect(OnFire)
	HitEvent.OnClientEvent:Connect(OnHit)
	UpdateHUDEvent.OnClientEvent:Connect(OnUpdateHUD)
	LevelCompleteEvent.OnClientEvent:Connect(OnLevelComplete)
	
	-- Setup input handlers
	InputController.OnFire:Connect(OnFireInput)
	
	InputController.OnScopeToggle:Connect(function(isScoped)
		
		if isScoped then
			ScopeUI:Show()
			HUD:Hide() -- Hide regular HUD when scoped
		else
			ScopeUI:Hide()
			HUD:Show() -- Show regular HUD when not scoped
		end
	end)
	
	-- Zoom input (Q/W keys)
	InputController.OnZoomChange:Connect(function(keyCode)
		if ClientState.IsScoped then
			SniperCamera:CycleZoomLevel()
			ScopeUI:UpdateDistance(ClientState.Distance) -- Refresh display
		end
		ClientState.IsScoped = isScoped
		print("[Client] Scope toggled:", isScoped)
		SniperCamera:ToggleScope(isScoped)
	end)
	
	ClientState.IsInitialized = true
	print("[Client] Client initialization complete!")
end

-- ============================================================================
-- STARTUP
-- ============================================================================

if Config.Environment.IsClient then
	Initialize()
	Initialize()
	-- ClientLoop() -- Uncomment when ready to implement game loop
else
	print("[Server] Client script should not run on server!")
end
