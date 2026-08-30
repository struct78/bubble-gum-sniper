--[[
	Server main initialization script
	Responsible for:
	- Loading shared modules and constants
	- Initializing game services
	- Spawning players and their characters
	- Managing game state and progression
	- Running core gameplay loop
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Load shared modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("constants"))
local Config = require(Shared:WaitForChild("config"))

-- Load server modules (Phase 2 additions)
local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local Weapon = require(Server:WaitForChild("gameplay"):WaitForChild("weapon"))
local Wind = require(Server:WaitForChild("gameplay"):WaitForChild("wind"))
local Targeting = require(Server:WaitForChild("gameplay"):WaitForChild("targeting"))
local Physics = require(Server:WaitForChild("gameplay"):WaitForChild("physics"))
local Projectile = require(Server:WaitForChild("gameplay"):WaitForChild("projectile"))
local Target = require(Server:WaitForChild("gameplay"):WaitForChild("target"))
local TargetSpawner = require(Server:WaitForChild("gameplay"):WaitForChild("target-spawner"))
local GameController = require(Server:WaitForChild("gameplay"):WaitForChild("game-controller"))
local LevelData = require(Server:WaitForChild("levels"):WaitForChild("level-data"))
local LevelEnvironment = require(Server:WaitForChild("levels"):WaitForChild("level-environment"))
local RemoteEvents = require(Server:WaitForChild("networking"):WaitForChild("remote-events"))

-- Game state
local GameState = {
	IsRunning = false,
	CurrentLevel = 1,
	ActivePlayers = {},
	CurrentTargets = {},
	CurrentProjectiles = {},
	LastUpdateTime = tick(),
}

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

local function InitializePlayer(player)
	print("[Server] Player joined:", player.Name)
	GameState.ActivePlayers[player.UserId] = {
		Player = player,
		LevelProgress = 1,
		IsReady = false,
	}
end

local function CleanupPlayer(player)
	print("[Server] Player left:", player.Name)
	GameState.ActivePlayers[player.UserId] = nil
end

-- ============================================================================
-- CHARACTER SPAWNING
-- ============================================================================

local function CreateCharacter(player)
	print("[Server] Creating character for", player.Name)
	
	-- Create humanoid root part
	local humanoidRootPart = Instance.new("Part")
	humanoidRootPart.Name = "HumanoidRootPart"
	humanoidRootPart.Shape = Enum.PartType.Ball
	humanoidRootPart.Size = Vector3.new(2, 2, 1)
	humanoidRootPart.CanCollide = false
	humanoidRootPart.CFrame = CFrame.new(0, 5, 0)
	humanoidRootPart.Parent = player.Character or workspace
	
	-- Create head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2, 1, 1)
	head.BrickColor = BrickColor.new("Bright yellow")
	head.CanCollide = false
	head.TopSurface = Enum.SurfaceType.Smooth
	head.BottomSurface = Enum.SurfaceType.Smooth
	head.Parent = player.Character or workspace
	
	-- Weld head to humanoid root part
	local neck = Instance.new("Weld")
	neck.Name = "Neck"
	neck.Part0 = head
	neck.Part1 = humanoidRootPart
	neck.C0 = CFrame.new(0, 1, 0)
	neck.Parent = head
	
	-- Create humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.Parent = player.Character or workspace
	
	print("[Server] Character created for", player.Name)
	return player.Character or workspace
end

local function OnCharacterAdded(player)
	-- Wait for character to be loaded
	local character = player.Character or player.CharacterAdded:Wait()
	print("[Server] Character loaded for", player.Name)
end

-- ============================================================================
-- FIRING SYSTEM
-- ============================================================================

local function HandlePlayerFire(player, character, fireData)
	-- Validate player and character
	if not character or character.Parent == nil then return end
	
	-- Get camera direction (from client)
	local cameraDirection = fireData.Direction
	if cameraDirection.Magnitude == 0 then
		cameraDirection = Vector3.new(0, 0, -1) -- Fallback
	end
	cameraDirection = cameraDirection.Unit
	
	-- Get current wind
	local wind = Wind:GetWindAtPosition(character.PrimaryPart.Position, LevelData.Levels[GameState.CurrentLevel])
	
	-- Fire weapon
	local success, reason = Weapon:Fire(character, cameraDirection, wind)
	
	if not success then
		print("[Server] Fire failed:", reason)
		return
	end
	
	-- Get fire position and velocity
	local head = character:FindFirstChild("Head")
	if not head then return end
	
	local firePosition = head.Position + head.CFrame.LookVector * 5
	local fireVelocity = cameraDirection * Constants.Projectile.Velocity
	
	-- Create projectile
	local projectileData = Projectile:Create(firePosition, fireVelocity, "small")
	table.insert(GameState.CurrentProjectiles, projectileData)
	
	-- Send fire event to clients for effects
	RemoteEvents:GetFireEvent():FireAllClients(firePosition, cameraDirection)
	
	print("[Server] Projectile fired from", player.Name)
end

-- ============================================================================
-- PROJECTILE UPDATE LOOP
-- ============================================================================

local function UpdateProjectiles(deltaTime)
	local projectilesToRemove = {}
	
	for i, projectile in ipairs(GameState.CurrentProjectiles) do
		if not projectile.IsActive or not projectile.Instance or projectile.Instance.Parent == nil then
			table.insert(projectilesToRemove, i)
			projectile.IsActive = false
		else
			-- Get wind for this frame
			local levelData = LevelData.Levels[GameState.CurrentLevel]
			local wind = Wind:GetWindAtPosition(projectile.Position, levelData)
			
			-- Update physics
			Physics:SimulateProjectile(projectile, deltaTime, wind, Constants.Projectile.Gravity)
			
			-- Check for target hits
			local hitResult = Targeting:CheckTargetHit(projectile.Position, GameState.CurrentTargets)
			
			if hitResult then
				-- Hit detected!
				local distance = Physics:CalculateDistanceToTarget(
					GameState.ActivePlayers[1] and GameState.ActivePlayers[1].SpawnPosition or Vector3.new(),
					hitResult.Target.Position
				)
				
				local score = Targeting:CalculateScore(hitResult, distance)
				print("[Server] HIT!", hitResult.Target.PunName, "Score:", score)
				
				-- Mark target as defeated
				hitResult.Target.IsDefeated = true
				if hitResult.Target.Instance then
					hitResult.Target.Instance:Destroy()
				end
				
				-- Remove projectile
				projectile.IsActive = false
				table.insert(projectilesToRemove, i)
				
				-- Send hit event to clients
				RemoteEvents:GetHitEvent():FireAllClients(hitResult.Target.Position, score)
			end
			
			-- Cleanup if projectile is too old or too far
			local timeElapsed = tick() - projectile.CreatedAt
			if timeElapsed > Constants.Projectile.MaxLifetime or projectile.Position.Magnitude > 1000 then
				projectile.IsActive = false
				table.insert(projectilesToRemove, i)
			end
		end
	end
	
	-- Remove inactive projectiles
	for i = #projectilesToRemove, 1, -1 do
		table.remove(GameState.CurrentProjectiles, projectilesToRemove[i])
	end
end

-- ============================================================================
-- HUD UPDATES
-- ============================================================================

local function UpdatePlayerHUD(player, character)
	if not character or not GameState.CurrentTargets or #GameState.CurrentTargets == 0 then return end
	
	-- Calculate distance to nearest target
	local head = character:FindFirstChild("Head")
	if not head then return end
	
	local nearestDistance = math.huge
	for _, target in ipairs(GameState.CurrentTargets) do
		if not target.IsDefeated then
			local distance = (head.Position - target.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
			end
		end
	end
	
	-- Get wind
	local levelData = LevelData.Levels[GameState.CurrentLevel]
	local wind = Wind:GetWindAtPosition(head.Position, levelData)
	
	-- Send HUD update to player
	RemoteEvents:GetUpdateHUDEvent():FireClient(player, {
		Distance = nearestDistance,
		WindVector = wind,
		Ammo = Weapon.State.CurrentAmmo,
		Wind = wind.Magnitude,
	})
end

local function GameLoop()
	while GameState.IsRunning do
		local currentTime = tick()
		local deltaTime = currentTime - GameState.LastUpdateTime
		GameState.LastUpdateTime = currentTime
		
		-- Update projectiles
		UpdateProjectiles(deltaTime)
		
		-- Update wind (changes over time)
		Wind:UpdateWind(deltaTime, LevelData.Levels[GameState.CurrentLevel])
		
		-- Update HUD for all players
		for _, player in pairs(Players:GetPlayers()) do
			local character = player.Character
			if character then
				UpdatePlayerHUD(player, character)
			end
		end
		
		-- Check level completion (all targets defeated)
		local allDefeated = true
		for _, target in ipairs(GameState.CurrentTargets) do
			if not target.IsDefeated then
				allDefeated = false
				break
			end
		end
		
		if allDefeated and #GameState.CurrentTargets > 0 then
			print("[Server] Level complete!")
			GameState.IsRunning = false
			RemoteEvents:GetLevelCompleteEvent():FireAllClients({
				LevelNumber = GameState.CurrentLevel,
				Score = 0, -- TODO: Calculate final score
			})
		end
		
		RunService.Heartbeat:Wait()
	end
end

-- ============================================================================
-- LEVEL START
-- ============================================================================

local function StartLevel(levelNumber)
	print("[Server] Starting level", levelNumber)
	
	GameState.CurrentLevel = levelNumber
	GameState.CurrentTargets = {}
	GameState.CurrentProjectiles = {}
	GameState.LastUpdateTime = tick()
	GameState.IsRunning = true
	
	-- Get level data
	local levelData = LevelData:Load(levelNumber)
	if not levelData then
		print("[Server] Level", levelNumber, "not found!")
		return
	end
	
	-- Build level environment
	LevelEnvironment:BuildLevel(levelNumber)
	
	-- Spawn player at level start position
	for _, player in pairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				humanoidRootPart.CFrame = CFrame.new(levelData.SpawnPosition)
			end
		end
	end
	
	-- Spawn targets
	GameState.CurrentTargets = TargetSpawner:SpawnTargetsForLevel(levelData)
	
	-- Initialize wind for level
	Wind.State.BaseWind = levelData.WindProfile.BaseWind
	Wind.State.WindDirection = levelData.WindProfile.Direction
	
	-- Notify players level has started
	RemoteEvents:GetUpdateHUDEvent():FireAllClients({
		LevelNumber = levelNumber,
		LevelName = levelData.Name,
		TargetCount = #GameState.CurrentTargets,
	})
	
	-- Start main game loop
	spawn(GameLoop)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function Initialize()
	print("[Server] Initializing Bubble Gum Sniper server...")
	print("[Server] Game Constants loaded")
	print("[Server] Debug mode:", Constants.Debug.Enabled and "ON" or "OFF")
	
	-- Connect player events
	Players.PlayerAdded:Connect(InitializePlayer)
	Players.PlayerRemoving:Connect(CleanupPlayer)
	
	-- Initialize existing players
	for _, player in pairs(Players:GetPlayers()) do
		InitializePlayer(player)
	end
	
	-- Setup remote event handlers
	RemoteEvents:GetFireEvent().OnServerEvent:Connect(HandlePlayerFire)
	
	-- Initialize game services
	Weapon:Initialize()
	Wind:Initialize()
	GameController:Initialize()
	
	print("[Server] Initialization complete!")
	
	-- Start first level after a short delay
	wait(2)
	StartLevel(1)
end

-- ============================================================================
-- STARTUP
-- ============================================================================

if Config.Environment.IsServer then
	Initialize()
else
	print("[Client] Server script should not run on client!")
end
