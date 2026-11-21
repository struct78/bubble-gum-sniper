local TweenService = game:GetService("TweenService")

local BubbleWobble = require(script.Parent["bubble-wobble"])

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
dome.Size = BubbleWobble.SizeAtPhase(size, -1)

local tween = TweenService:Create(
	dome,
	TweenInfo.new(BubbleWobble.HalfPeriod, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Size = BubbleWobble.SizeAtPhase(size, 1) }
)
tween:Play()