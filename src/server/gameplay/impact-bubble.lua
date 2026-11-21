local RunService = game:GetService("RunService")
local BubbleWobble = require(script.Parent.Parent["bubble-wobble"])

local START_DIAMETER = 0.4
local FULL_DIAMETER = 3
local INFLATION_SECONDS = 1.2
local LIFETIME_SECONDS = 10
local POP_SECONDS = 0.15
local POP_STRETCH = 1.25

local ImpactBubble = {}
local liveBubbles = {}

local function InBubbleSpace(vector, size)
	return Vector3.new(2 * vector.X / size.X, 2 * vector.Y / size.Y, 2 * vector.Z / size.Z)
end

local function CrossesBubble(step, bubble)
	-- Scale the current visual ellipsoid to a unit sphere and test the closest
	-- point on the finite segment. No world query or collision filter changes.
	local start = InBubbleSpace(step.Origin - bubble.Position, bubble.Size)
	local delta = InBubbleSpace(step.Displacement, bubble.Size)
	local fraction = math.max(0, math.min(1, -start:Dot(delta) / delta:Dot(delta)))
	local closest = start + delta * fraction
	return closest:Dot(closest) <= 1
end

function ImpactBubble.PopAlongStep(step, shot)
	if not (step.Displacement.Magnitude > 0) then return end
	local now = time()
	for part, effect in pairs(liveBubbles) do
		if part.Parent ~= workspace then
			effect.Cleanup()
		elseif now >= effect.Deadline or (effect.Owner ~= shot and CrossesBubble(step, part)) then
			effect.Pop(now)
		end
	end
end

function ImpactBubble.Spawn(contact, owner)
	local deadline = contact.Time + LIFETIME_SECONDS
	if time() >= deadline then return end

	local bubble, heartbeat, ancestry
	local popStarted, popSize
	local function Cleanup()
		if heartbeat then
			heartbeat:Disconnect()
			heartbeat = nil
		end
		if ancestry then
			ancestry:Disconnect()
			ancestry = nil
		end
		if bubble then
			local part = bubble
			bubble = nil
			liveBubbles[part] = nil
			part:Destroy()
		end
	end

	local function HandleFailure(err)
		Cleanup()
		warn("[ImpactBubble] " .. tostring(err))
	end

	local function Pop(now)
		liveBubbles[bubble] = nil
		popStarted = now
		popSize = bubble.Size
	end

	local function AdvancePop(now)
		if now >= popStarted + POP_SECONDS then
			Cleanup()
			return
		end
		local progress = (now - popStarted) / POP_SECONDS
		bubble.Size = popSize * (1 + (POP_STRETCH - 1) * progress)
		bubble.Transparency = 0.5 + 0.5 * progress
	end

	local function Update(elapsed)
		local progress = math.min(elapsed / INFLATION_SECONDS, 1)
		local diameter = START_DIAMETER + (FULL_DIAMETER - START_DIAMETER) * progress
		local phase = -math.cos(math.pi * elapsed / BubbleWobble.HalfPeriod)
		bubble.Size = BubbleWobble.SizeAtPhase(Vector3.new(diameter, diameter, diameter), phase)

		if contact.LocalPoint and contact.Part:IsDescendantOf(workspace) then
			bubble.Position = contact.Part.CFrame:PointToWorldSpace(contact.LocalPoint)
		end
	end

	local ok, err = pcall(function()
		bubble = Instance.new("Part")
		bubble.Name = "GumImpactBubble"
		bubble.Shape = Enum.PartType.Ball
		bubble.Color = Color3.fromRGB(255, 105, 180)
		bubble.Material = Enum.Material.SmoothPlastic
		bubble.Transparency = 0.5
		bubble.Anchored = true
		bubble.CanCollide = false
		bubble.CanTouch = false
		bubble.CanQuery = false
		bubble.CastShadow = false
		bubble.Position = contact.Position
		Update(time() - contact.Time)
		ancestry = bubble.AncestryChanged:Connect(function()
			if bubble and bubble.Parent ~= workspace then Cleanup() end
		end)
		-- One writer owns inflation, wobble and pop, even after the level ends.
		heartbeat = RunService.Heartbeat:Connect(function()
			if not bubble then return end
			local now = time()
			if bubble.Parent ~= workspace then
				Cleanup()
			else
				local updated, updateError
				if popStarted then
					updated, updateError = pcall(AdvancePop, now)
				elseif now >= deadline then
					updated, updateError = pcall(Pop, now)
				else
					updated, updateError = pcall(Update, now - contact.Time)
				end
				if not updated then HandleFailure(updateError) end
			end
		end)
		liveBubbles[bubble] = { Owner = owner, Deadline = deadline, Cleanup = Cleanup, Pop = Pop }
		bubble.Parent = workspace
	end)
	if not ok then HandleFailure(err) end
end

return ImpactBubble
