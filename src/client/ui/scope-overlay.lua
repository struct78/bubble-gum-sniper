--[[
	Scope UI overlay system
	Displays scope reticle, distance, wind, ballistic info
]]

local ScopeUI = {}

-- UI elements
ScopeUI.Elements = {
	ScopeOverlay = nil,
	ScopeReticle = nil,
	DistanceReadout = nil,
	WindGauge = nil,
	LeadIndicator = nil,
	BallisticInfo = nil,
}

-- ============================================================================
-- SCOPE OVERLAY CREATION
-- ============================================================================

local function CreateScopeOverlay()
	local screenGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("ScopeOverlay")
	
	if screenGui then
		screenGui:Destroy()
	end
	
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ScopeOverlay"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	
	-- Scope reticle (circular)
	local scopeFrame = Instance.new("Frame")
	scopeFrame.Name = "ScopeReticle"
	scopeFrame.Size = UDim2.new(0, 200, 0, 200)
	scopeFrame.Position = UDim2.new(0.5, -100, 0.5, -100)
	scopeFrame.BackgroundTransparency = 1
	scopeFrame.Parent = screenGui
	
	-- Outer circle
	local outerCircle = Instance.new("Frame")
	outerCircle.Name = "OuterCircle"
	outerCircle.Size = UDim2.new(1, 0, 1, 0)
	outerCircle.BackgroundTransparency = 1
	outerCircle.BorderColor3 = Color3.fromRGB(0, 255, 100)
	outerCircle.BorderSizePixel = 2
	outerCircle.Parent = scopeFrame
	
	-- Center dot
	local centerDot = Instance.new("TextLabel")
	centerDot.Name = "CenterDot"
	centerDot.Size = UDim2.new(0, 10, 0, 10)
	centerDot.Position = UDim2.new(0.5, -5, 0.5, -5)
	centerDot.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
	centerDot.BackgroundTransparency = 0
	centerDot.BorderSizePixel = 0
	centerDot.Text = ""
	centerDot.Parent = scopeFrame
	
	-- Reticle lines (crosshair)
	local lineColor = Color3.fromRGB(0, 255, 100)
	
	-- Vertical line
	local vLine = Instance.new("Frame")
	vLine.Name = "VLine"
	vLine.Size = UDim2.new(0, 2, 0, 50)
	vLine.Position = UDim2.new(0.5, -1, 0.5, -25)
	vLine.BackgroundColor3 = lineColor
	vLine.BorderSizePixel = 0
	vLine.Parent = scopeFrame
	
	-- Horizontal line
	local hLine = Instance.new("Frame")
	hLine.Name = "HLine"
	hLine.Size = UDim2.new(0, 50, 0, 2)
	hLine.Position = UDim2.new(0.5, -25, 0.5, -1)
	hLine.BackgroundColor3 = lineColor
	hLine.BorderSizePixel = 0
	hLine.Parent = scopeFrame
	
	-- Distance readout (top)
	local distanceReadout = Instance.new("TextLabel")
	distanceReadout.Name = "DistanceReadout"
	distanceReadout.Size = UDim2.new(0, 120, 0, 30)
	distanceReadout.Position = UDim2.new(0.5, -60, 0, 20)
	distanceReadout.BackgroundTransparency = 0.6
	distanceReadout.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	distanceReadout.TextColor3 = Color3.fromRGB(0, 255, 100)
	distanceReadout.TextSize = 14
	distanceReadout.Font = Enum.Font.GothamMono
	distanceReadout.Text = "0 m"
	distanceReadout.Parent = screenGui
	
	-- Wind gauge (left side)
	local windGauge = Instance.new("Frame")
	windGauge.Name = "WindGauge"
	windGauge.Size = UDim2.new(0, 60, 0, 150)
	windGauge.Position = UDim2.new(0, 10, 0.5, -75)
	windGauge.BackgroundTransparency = 0.6
	windGauge.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	windGauge.Parent = screenGui
	
	local windLabel = Instance.new("TextLabel")
	windLabel.Name = "Label"
	windLabel.Size = UDim2.new(1, 0, 0, 20)
	windLabel.Position = UDim2.new(0, 0, 0, 0)
	windLabel.BackgroundTransparency = 1
	windLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
	windLabel.TextSize = 12
	windLabel.Font = Enum.Font.GothamMono
	windLabel.Text = "WIND"
	windLabel.Parent = windGauge
	
	local windArrow = Instance.new("TextLabel")
	windArrow.Name = "Arrow"
	windArrow.Size = UDim2.new(1, 0, 0, 40)
	windArrow.Position = UDim2.new(0, 0, 0.5, -20)
	windArrow.BackgroundTransparency = 1
	windArrow.TextColor3 = Color3.fromRGB(0, 200, 255)
	windArrow.TextScaled = true
	windArrow.Text = "↑"
	windArrow.Parent = windGauge
	
	-- Ballistic info (right side)
	local ballistics = Instance.new("TextLabel")
	ballistics.Name = "BallisticInfo"
	ballistics.Size = UDim2.new(0, 100, 0, 80)
	ballistics.Position = UDim2.new(1, -110, 0.5, -40)
	ballistics.BackgroundTransparency = 0.6
	ballistics.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ballistics.TextColor3 = Color3.fromRGB(255, 200, 0)
	ballistics.TextSize = 11
	ballistics.Font = Enum.Font.GothamMono
	ballistics.Text = "0m\n0m/s\n0°"
	ballistics.Parent = screenGui
	
	ScopeUI.Elements.ScopeOverlay = screenGui
	ScopeUI.Elements.ScopeReticle = scopeFrame
	ScopeUI.Elements.DistanceReadout = distanceReadout
	ScopeUI.Elements.WindGauge = windGauge
	ScopeUI.Elements.BallisticInfo = ballistics
	
	print("[ScopeUI] Scope overlay created")
end

-- ============================================================================
-- SCOPE UPDATES
-- ============================================================================

function ScopeUI:UpdateDistance(distance)
	if self.Elements.DistanceReadout then
		local meters = distance / 3 -- Convert studs to approximate meters (1 stud ≈ 0.28m)
		self.Elements.DistanceReadout.Text = string.format("%.0f m", meters)
	end
end

function ScopeUI:UpdateWind(windVector)
	if self.Elements.WindGauge then
		local windArrow = self.Elements.WindGauge:FindFirstChild("Arrow")
		if windArrow then
			-- Rotate arrow based on wind direction
			local angle = math.atan2(windVector.Z, windVector.X) * 180 / math.pi
			-- TODO: Apply rotation to arrow
			
			-- For now, update label with wind speed
			local windSpeed = windVector.Magnitude
			windArrow.Text = string.format("%.0f", windSpeed)
		end
	end
end

function ScopeUI:UpdateBallistics(distance, windIntensity, projectileSpeed)
	if self.Elements.BallisticInfo then
		-- Calculate bullet drop
		local gravity = 32.2
		local timeToTarget = distance / projectileSpeed
		local bulletDrop = 0.5 * gravity * timeToTarget * timeToTarget
		
		self.Elements.BallisticInfo.Text = string.format(
			"%.0fm\n%.0fm/s\n%.1f°",
			distance,
			projectileSpeed,
			math.deg(math.atan(bulletDrop / distance))
		)
	end
end

function ScopeUI:Show()
	if self.Elements.ScopeOverlay then
		self.Elements.ScopeOverlay.Enabled = true
	end
end

function ScopeUI:Hide()
	if self.Elements.ScopeOverlay then
		self.Elements.ScopeOverlay.Enabled = false
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ScopeUI:Initialize()
	CreateScopeOverlay()
	self:Hide() -- Hidden until scope is activated
	print("[ScopeUI] Scope UI initialized")
end

return ScopeUI
