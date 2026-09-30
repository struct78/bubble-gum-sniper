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
	if not isPressed then return end
	if not ClientState.PlayerCharacter then
		warn("[Client] Cannot fire: no character")
		return
	end
	
	-- Get camera direction
	local camera = workspace.CurrentCamera
	if not camera then
		warn("[Client] Cannot fire: no camera")
		return
	end
	
	-- First person: fire along the crosshair. Third person: fire where the character faces.
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector
	if not SniperCamera.State.IsSniperMode then
		local hrp = ClientState.PlayerCharacter:FindFirstChild("HumanoidRootPart")
		local head = ClientState.PlayerCharacter:FindFirstChild("Head")
		if hrp then
			direction = hrp.CFrame.LookVector
			origin = (head or hrp).Position
		end
	end
	print("[Client] Firing! Direction:", tostring(direction))
	
	-- Send fire event to server
	FireEvent:FireServer(ClientState.PlayerCharacter, {
		Position = origin,
		Direction = direction,
	})
	
	-- Play client-side effects immediately (for responsiveness)
	Effects:ScreenShake(0.15, 0.15)
	ClientState.CurrentAmmo = math.max(0, ClientState.CurrentAmmo - 1)
	HUD:UpdateAmmo(ClientState.CurrentAmmo, Constants.Level.AmmoCap)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function OnCharacterAdded(character)
	print("[Client] Character added/respawned:", character.Name)
	ClientState.PlayerCharacter = character
	
	-- Re-initialize camera for new character
	SniperCamera:Initialize(character)
end

local function Initialize()
	print("[Client] Initializing Bubble Gum Sniper client...")
	
	-- Get player and character
	local player = Players.LocalPlayer
	if not player then
		warn("[Client] LocalPlayer not available!")
		return
	end
	
	print("[Client] Player:", player.Name)
	
	-- Initialize systems that don't depend on character
	InputController:Initialize()
	HUD:Initialize()
	ScopeUI:Initialize()
	PauseMenu:Initialize()
	
	-- Connect to remote events
	FireEvent.OnClientEvent:Connect(OnFire)
	HitEvent.OnClientEvent:Connect(OnHit)
	UpdateHUDEvent.OnClientEvent:Connect(OnUpdateHUD)
	LevelCompleteEvent.OnClientEvent:Connect(OnLevelComplete)
	
	-- Setup input handlers
	print("[Client] Connecting OnFire handler")
	InputController.OnFire:Connect(function(isPressed)
		print("[Client] OnFire fired, isPressed:", isPressed)
		OnFireInput(isPressed)
	end)
	
	InputController.OnSniperModeToggle:Connect(function()
		local isSniperMode = SniperCamera:ToggleSniperMode()
		ClientState.IsScoped = isSniperMode
		
		if isSniperMode then
			ScopeUI:Show()
			HUD:Hide() -- Hide regular HUD when scoped
		else
			ScopeUI:Hide()
			HUD:Show() -- Show regular HUD when not scoped
		end
	end)
	
	-- Zoom input (E zoom in / Q zoom out)
	InputController.OnZoomChange:Connect(function(keyCode)
		if ClientState.IsScoped then
			SniperCamera:CycleZoomLevel()
			ScopeUI:UpdateDistance(ClientState.Distance) -- Refresh display
		end
	end)
	
	-- Handle initial character and respawns
	player.CharacterAdded:Connect(OnCharacterAdded)
	
	local character = player.Character
	if character then
		print("[Client] Initial character already present")
		OnCharacterAdded(character)
	else
		print("[Client] Waiting for initial character...")
		character = player.CharacterAdded:Wait()
		OnCharacterAdded(character)
	end
	
	ClientState.IsInitialized = true
	print("[Client] Client initialization complete!")
end

-- ============================================================================
-- STARTUP
-- ============================================================================

if Config.Environment.IsClient then
	Initialize()
	-- ClientLoop() -- Uncomment when ready to implement game loop
else
	print("[Server] Client script should not run on server!")
end
