local Players = game:GetService("Players")

local ImpactContact = {}

function ImpactContact.FindVictim(surface, shooterUserId)
	if not surface or not shooterUserId then return nil end

	local ancestor = surface.Instance.Parent
	while ancestor do
		if ancestor:IsA("Model") then
			local player = Players:GetPlayerFromCharacter(ancestor)
			if player and player.Character == ancestor and player.UserId ~= shooterUserId then
				return player
			end
		end
		ancestor = ancestor.Parent
	end
	return nil
end

local function FindTargetContact(step, targets)
	if step.Displacement.Magnitude <= 0 then return nil end

	local parts = {}
	for _, target in ipairs(targets) do
		local model = target.Instance
		if not target.IsDefeated and model and model.Parent then
			for _, name in ipairs({ "TargetPart", "Head" }) do
				local part = model:FindFirstChild(name)
				if part and part:IsA("BasePart") then
					table.insert(parts, part)
				end
			end
		end
	end
	if #parts == 0 then return nil end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = parts
	return workspace:Raycast(step.Origin, step.Displacement, params)
end

function ImpactContact.FindVisual(step, targets)
	local hit = step.Surface
	local targetHit = FindTargetContact(step, targets)
	if targetHit and (not hit
		or (targetHit.Position - step.Origin).Magnitude < step.Displacement.Magnitude) then
		hit = targetHit
	end
	if not hit then return nil end

	local part = hit.Instance
	return {
		Position = hit.Position,
		Time = step.Time,
		Part = part,
		LocalPoint = part:IsA("BasePart") and part.CFrame:PointToObjectSpace(hit.Position) or nil,
	}
end

return ImpactContact
