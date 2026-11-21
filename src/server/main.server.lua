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
local ImpactContact = require(Server:WaitForChild("gameplay"):WaitForChild("impact-contact"))
local ImpactBubble = require(Server:WaitForChild("gameplay"):WaitForChild("impact-bubble"))
local SessionScore = require(Server:WaitForChild("player"):WaitForChild("session-score"))
local Target = require(Server:WaitForChild("gameplay"):WaitForChild("target"))
local TargetSpawner = require(Server:WaitForChild("gameplay"):WaitForChild("target-spawner"))
local GameController = require(Server:WaitForChild("gameplay"):WaitForChild("game-controller"))
local LevelData = require(Server:WaitForChild("levels"):WaitForChild("level-data"))
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
	local entry = GameState.ActivePlayers[player.UserId]
	if entry and entry.Player == player then return end
	print("[Server] Player joined:", player.Name)
	GameState.ActivePlayers[player.UserId] = {
		Player = player,
		SessionScore = SessionScore.Create(player),
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

local function OnCharacterAdded(character)
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		print("[Server] Character loaded for", player.Name)
	end
end

local function EnsureCharacterLoaded(player)
	if not player.Character then
		print("[Server] Loading character for", player.Name)
		local success, err = pcall(function()
			player:LoadCharacter()
		end)
		if not success then
			warn("[Server] LoadCharacter failed:", err)
		end
	end
end

-- ============================================================================
-- FIRING SYSTEM
-- ============================================================================

local function HandlePlayerFire(player, character, fireData)
	print("[Server] HandlePlayerFire from", player.Name, "character:", character and character.Name or "nil")
	
	-- Validate player and character
	if not character or character.Parent == nil then
		warn("[Server] Fire rejected: invalid character")
		return
	end
	
	-- Get camera direction (from client)
	local cameraDirection = fireData.Direction
	if not cameraDirection or cameraDirection.Magnitude == 0 then
		cameraDirection = Vector3.new(0, 0, -1) -- Fallback
	end
	cameraDirection = cameraDirection.Unit
	
	-- Get current wind (use Head position for wind sampling)
	local head = character:FindFirstChild("Head")
	local windSamplePos = head and head.Position or character:GetPivot().Position
	local wind = Wind:GetWindAtPosition(windSamplePos, LevelData.Levels[GameState.CurrentLevel])
	
	if not head then return end
	
	-- Spawn along the camera ray so the shot lines up with the crosshair
	local origin = fireData.Position
	if typeof(origin) ~= "Vector3" or (origin - head.Position).Magnitude > 20 then
		origin = head.Position
	end
	local firePosition = origin + cameraDirection * 3
	local fireVelocity = cameraDirection * (Constants.Projectile.Velocity * 4) -- Faster shot, flatter arc
	print("[Server] Spawning projectile at", tostring(firePosition), "dir:", tostring(cameraDirection))
	
	-- Create projectile
	local projectileData = Projectile:Create(firePosition, fireVelocity, "small")
	if character == player.Character then
		projectileData.ShooterUserId = player.UserId
	end
	table.insert(GameState.CurrentProjectiles, projectileData)
	
	-- Send fire event to clients for effects
	RemoteEvents:GetFireEvent():FireAllClients(firePosition, cameraDirection)
	
	print("[Server] Projectile fired from", player.Name)
end

-- ============================================================================
-- PROJECTILE UPDATE LOOP
-- ============================================================================

local function UpdateProjectiles(deltaTime)
	print("[Server] UpdateProjectiles called, count:", #GameState.CurrentProjectiles, "running:", GameState.IsRunning)
	local projectilesToRemove = {}
	
	for i, projectile in ipairs(GameState.CurrentProjectiles) do
		print("[Server] Updating projectile", i, "active:", projectile.IsActive, "instance:", projectile.Instance and projectile.Instance.Name or "nil")
		if not projectile.IsActive or not projectile.Instance or projectile.Instance.Parent == nil then
			table.insert(projectilesToRemove, i)
			projectile.IsActive = false
		else
			-- Get wind for this frame
			local levelData = LevelData.Levels[GameState.CurrentLevel]
			local wind = Wind:GetWindAtPosition(projectile.Position, levelData)
			
			-- Update physics
			local _, step = Physics:SimulateProjectile(projectile, deltaTime, wind, Constants.Projectile.Gravity)
			local visualContact
			if step then
				-- Only the surface accepted by physics can award player points.
				local victim = ImpactContact.FindVictim(step.Surface, projectile.ShooterUserId)
				SessionScore.AwardHit(projectile, victim, GameState.ActivePlayers)

				-- Snapshot before legacy scoring can destroy the struck target.
				if not projectile.ImpactVisualClaimed then
					local ok, result = pcall(ImpactContact.FindVisual, step, GameState.CurrentTargets)
					if step.Surface or (ok and result) then
						projectile.ImpactVisualClaimed = true
					end
					if not ok then
						warn("[Server] Impact contact visual failed:", result)
					else
						visualContact = result
					end
				end
			end
			
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

			if step and step.Surface then
				local ok, err = pcall(Projectile.HideSplat, projectile)
				if not ok then warn("[Server] Failed to hide impact splat:", err) end
			end

			if step then
				local ok, err = pcall(ImpactBubble.PopAlongStep, step, projectile)
				if not ok then warn("[Server] Impact bubble pop failed:", err) end
			end

			if visualContact then
				local ok, err = pcall(ImpactBubble.Spawn, visualContact, projectile)
				if not ok then warn("[Server] Impact bubble failed:", err) end
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
	print("[Server] GameLoop started")
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
	print("[Server] Loading level data for", levelNumber)
	local levelData = LevelData:Load(levelNumber)
	print("[Server] Level data loaded:", levelData and levelData.Name or "nil")
	if not levelData then
		print("[Server] Level", levelNumber, "not found!")
		return
	end
	
	-- Ensure all players have characters, then move them to spawn
	for _, player in pairs(Players:GetPlayers()) do
		EnsureCharacterLoaded(player)
		
		local character = player.Character
		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				humanoidRootPart.CFrame = CFrame.new(levelData.SpawnPosition)
				print("[Server] Moved", player.Name, "to spawn", tostring(levelData.SpawnPosition))
			else
				warn("[Server] Character for", player.Name, "has no HumanoidRootPart")
			end
		else
			warn("[Server] Player", player.Name, "has no character after load attempt")
		end
	end
	
	-- Spawn targets
	print("[Server] Spawning targets...")
	GameState.CurrentTargets = TargetSpawner:SpawnTargetsForLevel(levelData)
	print("[Server] Spawned", #GameState.CurrentTargets, "targets")
	
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
	print("[Server] Starting game loop...")
	task.spawn(GameLoop)
	print("[Server] Game loop spawned")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function Initialize()
	print("[Server] Initialize() entered")
	print("[Server] Initializing Bubble Gum Sniper server...")
	print("[Server] Game Constants loaded")
	print("[Server] Debug mode:", Constants.Debug.Enabled and "ON" or "OFF")
	
	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		InitializePlayer(player)
		player.CharacterAdded:Connect(OnCharacterAdded)
		-- Load character so client can initialize camera
		EnsureCharacterLoaded(player)
	end)
	Players.PlayerRemoving:Connect(CleanupPlayer)
	
	-- Initialize existing players
	for _, player in pairs(Players:GetPlayers()) do
		InitializePlayer(player)
		player.CharacterAdded:Connect(OnCharacterAdded)
		EnsureCharacterLoaded(player)
	end
	
	-- Setup remote event handlers
	RemoteEvents:GetFireEvent().OnServerEvent:Connect(HandlePlayerFire)
	
	-- Initialize game services
	print("[Server] Initializing Weapon...")
	Weapon:Initialize()
	print("[Server] Initializing Wind...")
	Wind:Initialize()
	print("[Server] Initializing GameController...")
	GameController:Initialize()
	
	print("[Server] Initialization complete!")
	
	-- Start first level after a short delay
	print("[Server] About to schedule level start...")
	task.delay(2, function()
		print("[Server] Delay elapsed, starting level 1")
		local success, err = pcall(function()
			StartLevel(1)
		end)
		if not success then
			warn("[Server] StartLevel failed:", err)
		end
	end)
	print("[Server] Level start scheduled")
end

-- ============================================================================
-- STARTUP
-- ============================================================================

print("[Server] main.server.lua loaded. IsServer:", Config.Environment.IsServer, "IsClient:", Config.Environment.IsClient, "IsStudio:", Config.Environment.IsStudio)

if Config.Environment.IsServer then
	local success, err = pcall(Initialize)
	if not success then
		warn("[Server] Initialize failed:", err)
	end
else
	print("[Client] Server script should not run on client!")
end
