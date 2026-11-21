local RunService = game:GetService("RunService")
local BubbleWobble = require(script.Parent.Parent["bubble-wobble"])
local BubblePopEvent = require(script.Parent.Parent.networking["remote-events"]).Events.BubblePop

local START_DIAMETER = 0.4
local FULL_DIAMETER = 3
local INFLATION_SECONDS = 1.2
local LIFETIME_SECONDS = 10

local ImpactBubble = {}
local liveBubbles = {}

local function InBubbleSpace(vector, size)
	return Vector3.new(2 * vector.X / size.X, 2 * vector.Y / size.Y, 2 * vector.Z / size.Z)
end

local function PunctureDirection(step, bubble)
	-- Solve the finite segment in unit-sphere space, using the entry root first.
	local start = InBubbleSpace(step.Origin - bubble.Position, bubble.Size)
	local delta = InBubbleSpace(step.Displacement, bubble.Size)
	local a = delta:Dot(delta)
	if a == 0 then return nil end
	local b = start:Dot(delta)
	local c = start:Dot(start) - 1
	local discriminant = b * b - a * c
	if discriminant < 0 then return nil end
	local root = math.sqrt(discriminant)
	local entry, exit = (-b - root) / a, (-b + root) / a
	if entry > 1 or exit < 0 then return nil end
	if entry >= 0 then return (start + delta * entry).Unit end
	if exit <= 1 then return (start + delta * exit).Unit end
	return start.Magnitude > 0 and start.Unit or delta.Unit * -1
end

function ImpactBubble.PopAlongStep(step, shot)
	if not (step.Displacement.Magnitude > 0) then return end
	local now = time()
	for part, effect in pairs(liveBubbles) do
		if part.Parent ~= workspace then
			effect.Cleanup()
		elseif now >= effect.Deadline then
			effect.Pop(Vector3.new(0, 1, 0))
		elseif effect.Owner ~= shot then
			local direction = PunctureDirection(step, part)
			if direction then effect.Pop(direction) end
		end
	end
end

function ImpactBubble.Spawn(contact, owner)
	local deadline = contact.Time + LIFETIME_SECONDS
	if time() >= deadline then return end

	local bubble, heartbeat, ancestry
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

	local function Pop(direction)
		local position, size = bubble.Position, bubble.Size
		Cleanup()
		local ok, err = pcall(function()
			BubblePopEvent:FireAllClients(position, size, direction)
		end)
		if not ok then warn("[ImpactBubble] " .. tostring(err)) end
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
		-- Expiry is independent of the level loop.
		heartbeat = RunService.Heartbeat:Connect(function()
			if not bubble then return end
			local now = time()
			if bubble.Parent ~= workspace then
				Cleanup()
			elseif now >= deadline then
				Pop(Vector3.new(0, 1, 0))
			else
				local updated, updateError = pcall(Update, now - contact.Time)
				if not updated then HandleFailure(updateError) end
			end
		end)
		liveBubbles[bubble] = { Owner = owner, Deadline = deadline, Cleanup = Cleanup, Pop = Pop }
		bubble.Parent = workspace
	end)
	if not ok then HandleFailure(err) end
end

return ImpactBubble
