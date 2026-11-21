local TweenService = game:GetService("TweenService")

local WOBBLE = 0.01
local HALF_PERIOD_SECONDS = 1.2
local SHEEN_DRIFT_SECONDS = 24

local assets = workspace:FindFirstChild("Assets")
local dome = workspace:FindFirstChild("BubbleDome")
	or (assets and assets:FindFirstChild("BubbleDome", true))

if not dome or not dome:IsA("UnionOperation") then
	warn("[DomeWobble] Expected a BubbleDome union in Workspace or under Workspace.Assets")
	return
end

if not dome.Anchored then
	warn("[DomeWobble] Anchor BubbleDome before animating it")
	return
end

local size = dome.Size
dome.Size = Vector3.new(size.X * (1 - WOBBLE), size.Y, size.Z * (1 + WOBBLE))

local tween = TweenService:Create(
	dome,
	TweenInfo.new(HALF_PERIOD_SECONDS, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Size = Vector3.new(size.X * (1 + WOBBLE), size.Y, size.Z * (1 - WOBBLE)) }
)
tween:Play()

-- Set BubbleSheenImage on the union to the Studio-uploaded bubble-sheen.png image ID.
local image = dome:GetAttribute("BubbleSheenImage")
if image == nil then
	return
end
if typeof(image) ~= "string" or not image:match("^rbxassetid://%d+$") then
	warn("[DomeWobble] BubbleSheenImage must be a string like rbxassetid://123456789")
	return
end

local tileSize = math.max(size.X, size.Y, size.Z)
local colorMap = Content.fromUri(image)
local drift = TweenInfo.new(SHEEN_DRIFT_SECONDS, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)

for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
	local sheen = Instance.new("Texture")
	sheen.Name = "BubbleSheen_" .. face.Name
	sheen.Face = face
	sheen.ColorMapContent = colorMap
	sheen.StudsPerTileU = tileSize
	sheen.StudsPerTileV = tileSize
	sheen.Parent = dome

	-- A full tile of travel makes the loop wrap without a jump.
	TweenService:Create(sheen, drift, { OffsetStudsU = tileSize }):Play()
end
