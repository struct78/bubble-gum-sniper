--[[
	Pause menu and game state UI
	Main menu, pause screen, level select
]]

local PauseMenu = {}

-- UI state
PauseMenu.IsOpen = false
PauseMenu.CurrentMenu = "pause" -- "pause", "settings", "level_select"
PauseMenu.ScreenGui = nil

-- ============================================================================
-- PAUSE SCREEN CREATION
-- ============================================================================

local function CreatePauseScreen()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PauseMenu"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	
	-- Semi-transparent background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.6
	background.Parent = screenGui
	
	-- Menu panel
	local menuPanel = Instance.new("Frame")
	menuPanel.Name = "MenuPanel"
	menuPanel.Size = UDim2.new(0, 400, 0, 350)
	menuPanel.Position = UDim2.new(0.5, -200, 0.5, -175)
	menuPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	menuPanel.BorderColor3 = Color3.fromRGB(255, 20, 147)
	menuPanel.BorderSizePixel = 3
	menuPanel.Parent = screenGui
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 50)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 0
	titleLabel.BackgroundColor3 = Color3.fromRGB(255, 20, 147)
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 32
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "PAUSED"
	titleLabel.Parent = menuPanel
	
	-- Resume button
	local resumeButton = Instance.new("TextButton")
	resumeButton.Name = "ResumeButton"
	resumeButton.Size = UDim2.new(0, 300, 0, 50)
	resumeButton.Position = UDim2.new(0.5, -150, 0, 70)
	resumeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	resumeButton.TextColor3 = Color3.fromRGB(0, 255, 100)
	resumeButton.TextSize = 20
	resumeButton.Font = Enum.Font.Gotham
	resumeButton.Text = "Resume Game"
	resumeButton.Parent = menuPanel
	
	-- Level select button
	local levelSelectButton = Instance.new("TextButton")
	levelSelectButton.Name = "LevelSelectButton"
	levelSelectButton.Size = UDim2.new(0, 300, 0, 50)
	levelSelectButton.Position = UDim2.new(0.5, -150, 0, 130)
	levelSelectButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	levelSelectButton.TextColor3 = Color3.fromRGB(0, 200, 255)
	levelSelectButton.TextSize = 20
	levelSelectButton.Font = Enum.Font.Gotham
	levelSelectButton.Text = "Level Select"
	levelSelectButton.Parent = menuPanel
	
	-- Settings button
	local settingsButton = Instance.new("TextButton")
	settingsButton.Name = "SettingsButton"
	settingsButton.Size = UDim2.new(0, 300, 0, 50)
	settingsButton.Position = UDim2.new(0.5, -150, 0, 190)
	settingsButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	settingsButton.TextColor3 = Color3.fromRGB(255, 200, 0)
	settingsButton.TextSize = 20
	settingsButton.Font = Enum.Font.Gotham
	settingsButton.Text = "Settings"
	settingsButton.Parent = menuPanel
	
	-- Main menu button
	local mainMenuButton = Instance.new("TextButton")
	mainMenuButton.Name = "MainMenuButton"
	mainMenuButton.Size = UDim2.new(0, 300, 0, 50)
	mainMenuButton.Position = UDim2.new(0.5, -150, 0, 250)
	mainMenuButton.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
	mainMenuButton.TextColor3 = Color3.fromRGB(255, 100, 100)
	mainMenuButton.TextSize = 20
	mainMenuButton.Font = Enum.Font.Gotham
	mainMenuButton.Text = "Main Menu"
	mainMenuButton.Parent = menuPanel
	
	PauseMenu.ScreenGui = screenGui
	
	-- Button click handlers
	resumeButton.MouseButton1Click:Connect(function()
		PauseMenu:Close()
	end)
	
	levelSelectButton.MouseButton1Click:Connect(function()
		PauseMenu:ShowLevelSelect()
	end)
	
	settingsButton.MouseButton1Click:Connect(function()
		-- TODO: Show settings menu
		print("[UI] Settings menu (TODO)")
	end)
	
	mainMenuButton.MouseButton1Click:Connect(function()
		-- TODO: Return to main menu
		print("[UI] Main menu (TODO)")
	end)
	
	print("[UI] Pause menu created")
end

-- ============================================================================
-- LEVEL COMPLETE SCREEN
-- ============================================================================

local function CreateLevelCompleteScreen()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LevelCompleteMenu"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	
	-- Background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.6
	background.Parent = screenGui
	
	-- Result panel
	local resultPanel = Instance.new("Frame")
	resultPanel.Name = "ResultPanel"
	resultPanel.Size = UDim2.new(0, 500, 0, 400)
	resultPanel.Position = UDim2.new(0.5, -250, 0.5, -200)
	resultPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	resultPanel.BorderColor3 = Color3.fromRGB(0, 255, 100)
	resultPanel.BorderSizePixel = 3
	resultPanel.Parent = screenGui
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 60)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 0
	titleLabel.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
	titleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.TextSize = 36
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "LEVEL COMPLETE!"
	titleLabel.Parent = resultPanel
	
	-- Score display
	local scoreLabel = Instance.new("TextLabel")
	scoreLabel.Name = "ScoreLabel"
	scoreLabel.Size = UDim2.new(1, 0, 0, 60)
	scoreLabel.Position = UDim2.new(0, 0, 0, 70)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
	scoreLabel.TextSize = 28
	scoreLabel.Font = Enum.Font.GothamMono
	scoreLabel.Text = "Score: 0"
	scoreLabel.Parent = resultPanel
	
	-- Accuracy display
	local accuracyLabel = Instance.new("TextLabel")
	accuracyLabel.Name = "AccuracyLabel"
	accuracyLabel.Size = UDim2.new(1, 0, 0, 40)
	accuracyLabel.Position = UDim2.new(0, 0, 0, 140)
	accuracyLabel.BackgroundTransparency = 1
	accuracyLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	accuracyLabel.TextSize = 18
	accuracyLabel.Font = Enum.Font.GothamMono
	accuracyLabel.Text = "Accuracy: 0%"
	accuracyLabel.Parent = resultPanel
	
	-- Continue button
	local continueButton = Instance.new("TextButton")
	continueButton.Name = "ContinueButton"
	continueButton.Size = UDim2.new(0, 300, 0, 50)
	continueButton.Position = UDim2.new(0.5, -150, 0, 320)
	continueButton.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
	continueButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	continueButton.TextSize = 20
	continueButton.Font = Enum.Font.GothamBold
	continueButton.Text = "Next Level"
	continueButton.Parent = resultPanel
	
	continueButton.MouseButton1Click:Connect(function()
		PauseMenu:CloseLevelComplete()
		-- TODO: Load next level
	end)
	
	PauseMenu.LevelCompleteGui = screenGui
	print("[UI] Level complete screen created")
end

-- ============================================================================
-- LEVEL SELECT SCREEN
-- ============================================================================

local function CreateLevelSelectScreen()
	-- TODO: Create level select grid with available levels
	print("[UI] Level select screen (TODO)")
end

-- ============================================================================
-- MENU CONTROL
-- ============================================================================

function PauseMenu:Show()
	self.IsOpen = true
	self.ScreenGui.Enabled = true
	game:GetService("RunService"):Set("IsRunning", false)
	print("[UI] Pause menu opened")
end

function PauseMenu:Close()
	self.IsOpen = false
	self.ScreenGui.Enabled = false
	game:GetService("RunService"):Set("IsRunning", true)
	print("[UI] Pause menu closed")
end

function PauseMenu:ShowLevelComplete(levelData)
	self.LevelCompleteGui.Enabled = true
	print("[UI] Level complete screen shown")
end

function PauseMenu:CloseLevelComplete()
	self.LevelCompleteGui.Enabled = false
	print("[UI] Level complete screen closed")
end

function PauseMenu:ShowLevelSelect()
	-- TODO: Implement level select
	print("[UI] Level select (TODO)")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function PauseMenu:Initialize()
	CreatePauseScreen()
	CreateLevelCompleteScreen()
	CreateLevelSelectScreen()
	
	-- Connect to pause input (ESC key)
	local UserInputService = game:GetService("UserInputService")
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.Escape then
			if self.IsOpen then
				self:Close()
			else
				self:Show()
			end
		end
	end)
	
	print("[PauseMenu] Pause menu initialized")
end

return PauseMenu
