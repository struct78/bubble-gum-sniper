--[[
	Shop UI interface
	Displays cosmetics catalog, purchases, inventory
]]

local ShopUI = {}

-- UI elements
ShopUI.ShopGui = nil
ShopUI.CurrentCategory = "Scope"

-- ============================================================================
-- SHOP INTERFACE CREATION
-- ============================================================================

local function CreateShopInterface()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	
	-- Main panel
	local mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(1, 0, 1, 0)
	mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	mainPanel.BorderSizePixel = 0
	mainPanel.Parent = screenGui
	
	-- Header
	local headerLabel = Instance.new("TextLabel")
	headerLabel.Name = "Header"
	headerLabel.Size = UDim2.new(1, 0, 0, 60)
	headerLabel.Position = UDim2.new(0, 0, 0, 0)
	headerLabel.BackgroundColor3 = Color3.fromRGB(255, 20, 147)
	headerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	headerLabel.TextSize = 32
	headerLabel.Font = Enum.Font.GothamBold
	headerLabel.Text = "COSMETICS SHOP"
	headerLabel.Parent = mainPanel
	
	-- Currency display (top right)
	local currencyLabel = Instance.new("TextLabel")
	currencyLabel.Name = "Currency"
	currencyLabel.Size = UDim2.new(0, 200, 0, 40)
	currencyLabel.Position = UDim2.new(1, -210, 0, 10)
	currencyLabel.BackgroundTransparency = 0.5
	currencyLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	currencyLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
	currencyLabel.TextSize = 16
	currencyLabel.Font = Enum.Font.RobotoMono
	currencyLabel.Text = "Bubbles: 100"
	currencyLabel.Parent = mainPanel
	
	-- Category buttons (left sidebar)
	local categories = { "Scope", "Ammunition", "Outfit", "GunSkin" }
	
	for i, category in ipairs(categories) do
		local button = Instance.new("TextButton")
		button.Name = category .. "Button"
		button.Size = UDim2.new(0, 150, 0, 50)
		button.Position = UDim2.new(0, 10, 0, 70 + (i - 1) * 60)
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		button.TextColor3 = Color3.fromRGB(255, 200, 0)
		button.TextSize = 14
		button.Font = Enum.Font.Gotham
		button.Text = category
		button.Parent = mainPanel
		
		button.MouseButton1Click:Connect(function()
			ShopUI:ShowCategory(category)
		end)
	end
	
	-- Cosmetics grid (center)
	local gridContainer = Instance.new("ScrollingFrame")
	gridContainer.Name = "GridContainer"
	gridContainer.Size = UDim2.new(1, -180, 1, -80)
	gridContainer.Position = UDim2.new(0, 170, 0, 70)
	gridContainer.BackgroundTransparency = 1
	gridContainer.ScrollBarThickness = 10
	gridContainer.Parent = mainPanel
	
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 150, 0, 150)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = gridContainer
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 100, 0, 40)
	closeButton.Position = UDim2.new(1, -110, 1, -50)
	closeButton.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
	closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
	closeButton.TextSize = 16
	closeButton.Font = Enum.Font.Gotham
	closeButton.Text = "Close"
	closeButton.Parent = mainPanel
	
	closeButton.MouseButton1Click:Connect(function()
		ShopUI:Close()
	end)
	
	ShopUI.ShopGui = screenGui
	ShopUI.GridContainer = gridContainer
	
	print("[ShopUI] Shop interface created")
end

-- ============================================================================
-- SHOW CATEGORY
-- ============================================================================

function ShopUI:ShowCategory(category)
	ShopUI.CurrentCategory = category
	print("[ShopUI] Showing category:", category)
	
	-- Clear grid
	ShopUI.GridContainer:ClearAllChildren()
	
	-- TODO: Load and display cosmetics for this category
end

-- ============================================================================
-- DISPLAY ITEM
-- ============================================================================

function ShopUI:DisplayItem(cosmeticItem)
	local itemFrame = Instance.new("TextButton")
	itemFrame.Name = cosmeticItem.Id
	itemFrame.Size = UDim2.new(0, 150, 0, 150)
	itemFrame.BackgroundColor3 = cosmeticItem.Color
	itemFrame.TextColor3 = Color3.fromRGB(255, 255, 255)
	itemFrame.TextSize = 12
	itemFrame.Font = Enum.Font.Gotham
	itemFrame.Text = cosmeticItem.Name .. "\n" .. cosmeticItem.Price .. " Bubbles"
	itemFrame.Parent = ShopUI.GridContainer
	
	itemFrame.MouseButton1Click:Connect(function()
		-- TODO: Show purchase dialog
		print("[ShopUI] Selected:", cosmeticItem.Name)
	end)
end

-- ============================================================================
-- CONTROL
-- ============================================================================

function ShopUI:Open()
	if self.ShopGui then
		self.ShopGui.Enabled = true
	end
end

function ShopUI:Close()
	if self.ShopGui then
		self.ShopGui.Enabled = false
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ShopUI:Initialize()
	CreateShopInterface()
	print("[ShopUI] Shop UI initialized")
end

return ShopUI
