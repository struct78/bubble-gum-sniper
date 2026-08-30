--[[
	Scope UI overlay
	Displays reticle, distance, wind indicator, and ammo counter
]]

local UserInterface = {}

-- UI elements (created at runtime)
UserInterface.Elements = {
	Reticle = nil,
	DistanceLabel = nil,
	WindArrow = nil,
	AmmoCounter = nil,
	HUDContainer = nil,
}

-- ============================================================================
-- HUD CREATION
-- ============================================================================

-- ============================================================================
-- HUD CREATION
-- ============================================================================

local function CreateHUD()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SniperHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	
	-- Reticle (center screen)
	local reticle = Instance.new("Frame")
	reticle.Name = "Reticle"
	reticle.Size = UDim2.new(0, 50, 0, 50)
	reticle.Position = UDim2.new(0.5, -25, 0.5, -25)
	reticle.BackgroundTransparency = 1
	reticle.Parent = screenGui
	
	local reticleCross = Instance.new("TextLabel")
	reticleCross.Name = "Cross"
	reticleCross.Size = UDim2.new(1, 0, 1, 0)
	reticleCross.BackgroundTransparency = 1
	reticleCross.TextColor3 = Color3.fromRGB(0, 255, 100) -- Neon green
	reticleCross.TextScaled = true
	reticleCross.Text = "+"
	reticleCross.Parent = reticle
	
	-- Distance label (top-left)
	local distanceLabel = Instance.new("TextLabel")
	distanceLabel.Name = "Distance"
	distanceLabel.Size = UDim2.new(0, 200, 0, 50)
	distanceLabel.Position = UDim2.new(0, 10, 0, 10)
	distanceLabel.BackgroundTransparency = 0.5
	distanceLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	distanceLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
	distanceLabel.TextSize = 18
	distanceLabel.Font = Enum.Font.GothamMono
	distanceLabel.Text = "Distance: 0 studs"
	distanceLabel.Parent = screenGui
	
	-- Wind indicator (top-right)
	local windArrow = Instance.new("Frame")
	windArrow.Name = "WindArrow"
	windArrow.Size = UDim2.new(0, 60, 0, 60)
	windArrow.Position = UDim2.new(1, -70, 0, 10)
	windArrow.BackgroundTransparency = 0.5
	windArrow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	windArrow.Parent = screenGui
	
	local arrowLabel = Instance.new("TextLabel")
	arrowLabel.Name = "Arrow"
	arrowLabel.Size = UDim2.new(1, 0, 1, 0)
	arrowLabel.BackgroundTransparency = 1
	arrowLabel.TextColor3 = Color3.fromRGB(0, 200, 255) -- Neon cyan
	arrowLabel.TextScaled = true
	arrowLabel.Text = "↑"
	arrowLabel.Parent = windArrow
	
	-- Ammo counter (bottom-right)
	local ammoCounter = Instance.new("TextLabel")
	ammoCounter.Name = "Ammo"
	ammoCounter.Size = UDim2.new(0, 150, 0, 50)
	ammoCounter.Position = UDim2.new(1, -160, 1, -60)
	ammoCounter.BackgroundTransparency = 0.5
	ammoCounter.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ammoCounter.TextColor3 = Color3.fromRGB(255, 255, 0)
	ammoCounter.TextSize = 18
	ammoCounter.Font = Enum.Font.GothamMono
	ammoCounter.Text = "Ammo: 50"
	ammoCounter.Parent = screenGui
	
	-- Score label (bottom-left)
	local scoreLabel = Instance.new("TextLabel")
	scoreLabel.Name = "Score"
	scoreLabel.Size = UDim2.new(0, 150, 0, 50)
	scoreLabel.Position = UDim2.new(0, 10, 1, -60)
	scoreLabel.BackgroundTransparency = 0.5
	scoreLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	scoreLabel.TextColor3 = Color3.fromRGB(255, 100, 200)
	scoreLabel.TextSize = 18
	scoreLabel.Font = Enum.Font.GothamMono
	scoreLabel.Text = "Score: 0"
	scoreLabel.Parent = screenGui
	
	UserInterface.Elements.Reticle = reticle
	UserInterface.Elements.DistanceLabel = distanceLabel
	UserInterface.Elements.WindArrow = windArrow
	UserInterface.Elements.AmmoCounter = ammoCounter
	UserInterface.Elements.ScoreLabel = scoreLabel
	UserInterface.Elements.HUDContainer = screenGui
	
	print("[UI] HUD created")
end

-- ============================================================================
-- HUD UPDATES
-- ============================================================================

function UserInterface:UpdateDistance(distance)
	if self.Elements.DistanceLabel then
		self.Elements.DistanceLabel.Text = string.format("Distance: %.0f studs", distance)
	end
end

function UserInterface:UpdateWind(windVector)
	if self.Elements.WindArrow then
		-- Rotate arrow based on wind direction
		local angle = math.atan2(windVector.Z, windVector.X)
		-- TODO: Apply rotation to arrow UI
	end
end

function UserInterface:UpdateAmmo(current, max)
	if self.Elements.AmmoCounter then
		self.Elements.AmmoCounter.Text = string.format("Ammo: %d/%d", current, max)
	end
end

function UserInterface:UpdateScore(score)
	if self.Elements.ScoreLabel then
		self.Elements.ScoreLabel.Text = string.format("Score: %d", score)
	end
end

function UserInterface:Show()
	if self.Elements.HUDContainer then
		self.Elements.HUDContainer.Enabled = true
	end
end

function UserInterface:Hide()
	if self.Elements.HUDContainer then
		self.Elements.HUDContainer.Enabled = false
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function UserInterface:Initialize()
	CreateHUD()
	print("[UI] User interface initialized")
end

return UserInterface
