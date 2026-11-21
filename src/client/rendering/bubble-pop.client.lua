local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local POP_SECONDS = 0.085
local SIDES = 48
local RINGS = 16
local DROPLETS = 96
local MAX_ACTIVE = 8
local PINK = Color3.fromRGB(255, 105, 180)
local active = 0
local meshWarningShown = false

local function Style(part)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Color = PINK
	part.Material = Enum.Material.SmoothPlastic
end

local function RenderPop(center, size, axis)
	if active >= MAX_ACTIVE then return end
	active = active + 1
	local up = math.abs(axis.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis
	local frame = CFrame.lookAt(Vector3.zero, axis, up)
	local radius = size * 0.5
	local mesh, shell, heartbeat
	local droplets = {}

	local function Surface(angle, heading)
		local sinAngle = math.sin(angle)
		local point = frame:VectorToWorldSpace(Vector3.new(
			sinAngle * math.cos(heading), sinAngle * math.sin(heading), -math.cos(angle)
		))
		return Vector3.new(point.X * radius.X, point.Y * radius.Y, point.Z * radius.Z)
	end

	local function Cleanup()
		if heartbeat then heartbeat:Disconnect() end
		if shell then shell:Destroy() end
		if mesh then mesh:Destroy() end
		for _, drop in ipairs(droplets) do drop.Part:Destroy() end
		active = active - 1
	end

	local ok, err = pcall(function()
		local vertices = {}
		local function HoleAngle(progress)
			return 0.08 + 2.95 * (1 - (1 - progress) ^ 1.5)
		end

		local function UpdateShell(progress)
			local opening = HoleAngle(progress)
			for ring, row in ipairs(vertices) do
				local angle = opening + (math.pi - opening) * (ring - 1) / RINGS
				for side, vertex in ipairs(row) do
					mesh:SetPosition(vertex, Surface(angle, (side - 1) * 2 * math.pi / SIDES))
				end
			end
			shell.Transparency = 0.5 + 0.5 * progress ^ 3
		end

		local meshOk, meshError = pcall(function()
			mesh = AssetService:CreateEditableMesh()
			if not mesh then error("EditableMesh memory budget exhausted") end
			local opening = HoleAngle(0)
			for ring = 1, RINGS do
				local row = {}
				vertices[ring] = row
				local angle = opening + (math.pi - opening) * (ring - 1) / RINGS
				for side = 1, SIDES do
					row[side] = mesh:AddVertex(Surface(angle, (side - 1) * 2 * math.pi / SIDES))
				end
			end
			local pole = mesh:AddVertex(Surface(math.pi, 0))
			for ring, row in ipairs(vertices) do
				local nextRow = vertices[ring + 1]
				for side, vertex in ipairs(row) do
					local nextSide = side % SIDES + 1
					if nextRow then
						mesh:AddTriangle(vertex, row[nextSide], nextRow[side])
						mesh:AddTriangle(row[nextSide], nextRow[nextSide], nextRow[side])
					else
						mesh:AddTriangle(vertex, row[nextSide], pole)
					end
				end
			end
			shell = AssetService:CreateMeshPartAsync(Content.fromObject(mesh), {
				CollisionFidelity = Enum.CollisionFidelity.Box,
				RenderFidelity = Enum.RenderFidelity.Precise,
			})
			Style(shell)
			shell.Name = "GumPopShell"
			shell.DoubleSided = true
			shell.Transparency = 0.5
			shell.Position = center
			shell.Parent = workspace
		end)
		if not meshOk then
			if shell then shell:Destroy(); shell = nil end
			if mesh then mesh:Destroy(); mesh = nil end
			if not meshWarningShown then
				meshWarningShown = true
				warn("[BubblePop] Shell unavailable; showing rim droplets only: " .. tostring(meshError))
			end
		end

		local random = Random.new()
		for i = 1, DROPLETS do
			local heading = (i - 1) * 2 * math.pi / DROPLETS + random:NextNumber(-0.08, 0.08)
			local release = (i - 1) % 4 * 0.11 + random:NextNumber(0, 0.07)
			local point = Surface(HoleAngle(release), heading)
			local part = Instance.new("Part")
			local diameter = math.max(0.05, size.Y * random:NextNumber(0.025, 0.065))
			table.insert(droplets, { Part = part, Point = point, Release = release })
			Style(part)
			part.Name = "GumPopDroplet"
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.one * diameter
		end

		local elapsed = 0
		heartbeat = RunService.RenderStepped:Connect(function(dt)
			elapsed = elapsed + dt
			local progress = elapsed / POP_SECONDS
			if progress >= 1 then Cleanup(); return end
			local updated, updateError = pcall(function()
				if shell then UpdateShell(progress) end
				for _, drop in ipairs(droplets) do
					if progress >= drop.Release then
						local age = (progress - drop.Release) / (1 - drop.Release)
						local part = drop.Part
						part.Position = center + drop.Point * (1 + age * 0.75)
							+ Vector3.new(0, -size.Y * 0.16 * age ^ 2, 0)
						part.Transparency = 0.35 + 0.65 * age
						if not part.Parent then part.Parent = workspace end
					end
				end
			end)
			if not updated then
				Cleanup()
				warn("[BubblePop] " .. tostring(updateError))
			end
		end)
	end)
	if not ok then
		Cleanup()
		warn("[BubblePop] " .. tostring(err))
	end
end

ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("BubblePop").OnClientEvent:Connect(RenderPop)
