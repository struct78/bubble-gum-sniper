-- From the repo root: lua specs/projectile-impact-bubble/behavior.lua [scenario]
local scenario = (arg or {})[1]
local function test(name, run)
	if not scenario or scenario == name then
		run()
		print("PASS " .. name)
	end
end

local vector = {}
local vectorMeta = {}
function vector.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vectorMeta)
end
Vector3 = vector
function vectorMeta.__sub(a, b)
	return vector.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
function vectorMeta.__add(a, b)
	return vector.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
function vectorMeta.__mul(v, n)
	return vector.new(v.X * n, v.Y * n, v.Z * n)
end
function vectorMeta.__index(v, key)
	if key == "Magnitude" then
		return math.sqrt(v.X ^ 2 + v.Y ^ 2 + v.Z ^ 2)
	elseif key == "Unit" then
		return v * (1 / v.Magnitude)
	elseif key == "Dot" then
		return function(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
	end
end
local function near(actual, expected)
	assert(math.abs(actual - expected) < 0.000001, tostring(actual) .. " ~= " .. expected)
end

local function signal()
	local event = {}
	function event:Connect(callback)
		self.callback = callback
		return { Disconnect = function() self.callback = nil end }
	end
	function event:Fire(...)
		if self.callback then self.callback(...) end
	end
	return event
end

local function popModules(events)
	return function(module)
		if module == "pop-remote" then
			return { Events = { BubblePop = { FireAllClients = function(_, position, size, axis)
				table.insert(events, { Position = position, Size = size, Axis = axis })
			end } } }
		end
		return dofile("src/server/bubble-wobble.lua")
	end
end

local popScript = { Parent = { Parent = { networking = { ["remote-events"] = "pop-remote" } } } }

local function popFixture()
	local clock = { Now = 9 }
	local world, parts, listeners, events = {}, {}, {}, {}
	local heartbeat = {}
	function heartbeat:Connect(callback)
		listeners[callback] = true
		return { Disconnect = function() listeners[callback] = nil end }
	end
	local environment = setmetatable({
		workspace = world,
		time = function() return clock.Now end,
		warn = error,
		game = { GetService = function() return { Heartbeat = heartbeat } end },
		script = popScript,
		require = popModules(events),
		Enum = { PartType = { Ball = "Ball" }, Material = { SmoothPlastic = "SmoothPlastic" } },
		Color3 = { fromRGB = function() return "pink" end },
		Instance = { new = function()
			local part = { AncestryChanged = signal(), DestroyCount = 0 }
			function part:Destroy()
				self.DestroyCount = self.DestroyCount + 1
				self.Parent = nil
				self.AncestryChanged:Fire()
			end
			table.insert(parts, part)
			return part
		end },
	}, { __index = _G })
	local bubble = assert(loadfile("src/server/gameplay/impact-bubble.lua", "t", environment))()
	return bubble, world, parts, clock, listeners, events
end

test("visual", function()
	local now, part, warnings, failConnection = 10, nil, 0, false
	local heartbeat = signal()
	local connect = heartbeat.Connect
	function heartbeat:Connect(callback)
		if failConnection then error("fixture connection failure") end
		return connect(self, callback)
	end
	local world = {}
	local events = {}
	local environment = setmetatable({
		workspace = world,
		time = function() return now end,
		warn = function() warnings = warnings + 1 end,
		game = { GetService = function() return { Heartbeat = heartbeat } end },
		script = popScript,
		require = popModules(events),
		Enum = { PartType = { Ball = "Ball" }, Material = { SmoothPlastic = "SmoothPlastic" } },
		Color3 = { fromRGB = function() return "pink" end },
		Instance = { new = function()
			part = { AncestryChanged = signal(), Destroy = function(self)
				self.Parent = nil
				self.Destroyed = true
			end }
			return part
		end },
	}, { __index = _G })
	local bubble = assert(loadfile("src/server/gameplay/impact-bubble.lua", "t", environment))()
	local contact = { Position = vector.new(2, 3, 4), Time = now }
	bubble.Spawn(contact)
	assert(part.Parent == world and part.Position == contact.Position)
	assert(part.Anchored and part.Transparency == 0.5)
	assert(not part.CanCollide and not part.CanTouch and not part.CanQuery)
	local initial = part.Size.Y
	assert(initial < 1)
	now = 11.2
	heartbeat:Fire()
	assert(part.Size.Y > initial and part.Size.X > part.Size.Z)
	local full = part.Size.Y
	now = 12.4
	heartbeat:Fire()
	near(part.Size.Y, full)
	assert(part.Size.X < part.Size.Z)
	now = 19.99
	heartbeat:Fire()
	assert(part.Parent == world and part.Transparency == 0.5)
	now = 20
	heartbeat:Fire()
	assert(part.Destroyed and not heartbeat.callback)
	assert(#events == 1 and events[1].Position == contact.Position)
	near(events[1].Size.Y, full)
	near(events[1].Axis.Y, 1)

	contact.Time = now
	local moving = true
	local translation = vector.new()
	contact.LocalPoint = contact.Position
	contact.Part = {
		IsDescendantOf = function() return moving end,
		CFrame = { PointToWorldSpace = function(_, point) return point + translation end },
	}
	bubble.Spawn(contact)
	translation = vector.new(5, 0, 0)
	heartbeat:Fire()
	near(part.Position.X, 7)
	moving = false
	translation = vector.new(12, 0, 0)
	heartbeat:Fire()
	near(part.Position.X, 7)
	part.Parent = nil
	part.AncestryChanged:Fire()
	assert(part.Destroyed and not heartbeat.callback)
	failConnection = true
	bubble.Spawn(contact)
	assert(part.Destroyed and not heartbeat.callback and warnings == 1)
end)

test("wobble", function()
	local wobble = dofile("src/server/bubble-wobble.lua")
	local size = vector.new(100, 50, 100)
	local a = wobble.SizeAtPhase(size, -1)
	local b = wobble.SizeAtPhase(size, 1)
	assert(wobble.HalfPeriod == 1.2)
	near(a.X, 99)
	near(a.Z, 101)
	near(b.X, 101)
	near(b.Z, 99)
	assert(a.Y == size.Y and b.Y == size.Y)
end)

test("session-score", function()
	local function container(children)
		return {
			FindFirstChild = function(_, name) return (children or {})[name] end,
			IsA = function(_, class) return class == "Folder" end,
		}
	end
	Instance = { new = function() return container() end }
	warn = function() end
	local session = dofile("src/server/player/session-score.lua")
	local shooter = { UserId = 10 }
	local victim = { UserId = 20 }
	local shooterScore = session.Create(container())
	local victimScore = session.Create(container({ leaderstats = container() }))
	assert(victimScore.Name == "Score" and victimScore.Value == 0)
	shooterScore.Value, victimScore.Value = 40, 70
	local active = {
		[10] = { Player = shooter, SessionScore = shooterScore },
		[20] = { Player = victim, SessionScore = victimScore },
	}
	local shot = { ShooterUserId = 10 }
	session.AwardHit(shot, nil, active)
	session.AwardHit(shot, shooter, active)
	session.AwardHit(shot, { UserId = victim.UserId }, active)
	assert(not shot.PlayerAwardCommitted and shooterScore.Value == 40 and victimScore.Value == 70)
	session.AwardHit(shot, victim, active)
	session.AwardHit(shot, victim, active)
	assert(victimScore.Value == 75 and shooterScore.Value == 40)
	session.AwardHit({ ShooterUserId = 10, ImpactVisualClaimed = true }, victim, active)
	assert(victimScore.Value == 80)

	local prior = { Value = 700 }
	assert(not session.Create(container({ leaderstats = container({ Score = prior }) })))
	assert(prior.Value == 700)
end)

test("physics", function()
	local projectileModule = { StickToSurface = function(_, shot)
		shot.Stuck = true
		shot.Velocity = vector.new()
	end }
	local physics = assert(loadfile("src/server/gameplay/physics.lua", "t", setmetatable({
		game = { GetService = function() return { Server = { gameplay = {} } } end },
		require = function() return projectileModule end,
		print = function() end,
	}, { __index = _G })))()
	local hit = { Instance = { CanCollide = true }, Position = vector.new(4, 0, 0) }
	local shot = { Position = vector.new(), Velocity = vector.new(10, 0, 0) }
	RaycastParams = { new = function() return {} end }
	Enum = { RaycastFilterType = { Blacklist = "Blacklist" } }
	time = function() return 15 end
	workspace = { Raycast = function(_, origin, direction, params)
		assert(origin == shot.Position and params.FilterType == "Blacklist")
		near(direction.X, 10)
		return hit
	end }
	local returned, step = physics:SimulateProjectile(shot, 1, vector.new(), 0)
	assert(returned == shot and step.Surface == hit and step.Time == 15)
	assert(shot.Stuck and shot.Position == hit.Position)
	near(shot.Velocity.Magnitude, 0)
	near(step.Displacement.X, 4)
	local _, stuckStep = physics:SimulateProjectile(shot, 1, vector.new(), 0)
	assert(not stuckStep)

	hit.Instance.CanCollide = false
	shot = { Position = vector.new(), Velocity = vector.new(10, 0, 0) }
	_, step = physics:SimulateProjectile(shot, 1, vector.new(), 0)
	assert(not step.Surface and not shot.Stuck)
	near(shot.Position.X, 10)
	near(step.Displacement.X, 10)
end)

test("contacts", function()
	local victim = { UserId = 20 }
	local character = { IsA = function(_, class) return class == "Model" end }
	victim.Character = character
	local handle = { Parent = { Parent = character, IsA = function() return false end } }
	game = { GetService = function() return {
		GetPlayerFromCharacter = function(_, model) return model == character and victim or nil end,
	} end }
	local contact = dofile("src/server/gameplay/impact-contact.lua")
	assert(contact.FindVictim(nil, 10) == nil)
	local surface = { Instance = handle, Position = vector.new(5, 0, 0) }
	assert(contact.FindVictim(surface, 10) == victim)
	assert(contact.FindVictim(surface, 20) == nil)
	victim.Character = {}
	assert(contact.FindVictim(surface, 10) == nil)

	local targetPart = {
		IsA = function(_, class) return class == "BasePart" end,
		CFrame = { PointToObjectSpace = function(_, point) return point end },
	}
	local targetModel = { Parent = {}, FindFirstChild = function(_, name)
		return name == "Head" and targetPart or nil
	end }
	local target = { Instance = targetModel }
	local targetHit = { Instance = targetPart, Position = vector.new(3, 0, 0) }
	function handle:IsA() return false end
	RaycastParams = { new = function() return {} end }
	Enum = { RaycastFilterType = { Include = "Include" } }
	workspace = { Raycast = function(_, _, displacement, params)
		assert(params.FilterType == "Include" and params.FilterDescendantsInstances[1] == targetPart)
		return targetHit.Position.X <= displacement.X and targetHit or nil
	end }
	local step = { Origin = vector.new(), Displacement = surface.Position, Surface = surface, Time = 2 }
	assert(contact.FindVisual(step, { target }).Position == targetHit.Position)
	targetHit.Position = surface.Position
	assert(contact.FindVisual(step, { target }).Part == handle)
	targetHit.Position = vector.new(7, 0, 0)
	assert(contact.FindVisual(step, { target }).Part == handle)
	step.Surface = nil
	assert(contact.FindVisual(step, { target }) == nil)
	step.Displacement = vector.new(10, 0, 0)
	assert(contact.FindVisual(step, { target }).Time == 2)
	target.IsDefeated = true
	assert(contact.FindVisual(step, { target }) == nil)
end)

local function runLiveLoop(mode)
	local popping = mode ~= nil
	local function node(fields)
		fields.WaitForChild = function(self, name) return self[name] end
		fields.FindFirstChild = fields.WaitForChild
		return fields
	end
	local character = node({ Parent = {}, Head = { Position = vector.new() } })
	local shooter = { UserId = 10, Character = character, CharacterAdded = signal() }
	local victim = { UserId = 20, Character = node({ Parent = {}, Head = { Position = vector.new() } }), CharacterAdded = signal() }
	local scores = { [shooter] = { Value = 40, Parent = {} }, [victim] = { Value = 70, Parent = {} } }
	local target = { Position = vector.new(popping and 30 or 8, 0, 0), Instance = { Destroy = function() end } }
	local hitCount, spawnCount, hideCount, warnings, frame = 0, 0, 0, 0, 0
	local shot = { Instance = { Parent = {} }, IsActive = true, Position = vector.new(), Velocity = vector.new(10, 0, 0), CreatedAt = 0 }
	local bubbles, world, parts, clock, listeners, events = popFixture()
	local full, inflating, later, own, beyond, miss, expired, removed
	if mode == "with-bubbles" then
		local function place(x, y, contactTime, owner)
			bubbles.Spawn({ Position = vector.new(x, y, 0), Time = contactTime }, owner)
			return parts[#parts]
		end
		expired = place(3, 0, 0)
		clock.Now = 10 -- deadline has passed but the visual Heartbeat hasn't run
		full = place(2, 1.4, 8, { ShooterUserId = shooter.UserId })
		inflating = place(6, 0, 10)
		later = place(15, 0, 10)
		own = place(10, 0, 10, shot)
		beyond = place(30, 0, 10)
		miss = place(6, 0.3, 10)
		removed = place(8, 0, 10)
		removed.Parent = nil -- defer the ancestry event until after the shot step
	end
	local fire = { OnServerEvent = signal(), FireAllClients = function() end }
	local broadcast = { FireAllClients = function() end, FireClient = function() end }
	local hit = { FireAllClients = function(_, position, points)
		assert(position == target.Position and points == (popping and 145 or 134))
		hitCount = hitCount + 1
	end }
	local start, loop
	local noOp = function() end
	local session = dofile("src/server/player/session-score.lua")
	session.Create = function(player) return scores[player] end
	local modules = node({
		gameplay = node({
			weapon = { Initialize = noOp, State = {} },
			wind = { Initialize = noOp, UpdateWind = noOp, State = {}, GetWindAtPosition = function() return vector.new() end },
			targeting = dofile("src/server/gameplay/targeting.lua"),
			physics = {
				CalculateDistanceToTarget = function(_, a, b) return (a - b).Magnitude end,
				SimulateProjectile = function(_, projectile)
					frame = frame + 1
					if popping then
						local origin = projectile.Position
						local surface = frame == 3 and {} or nil
						local displacement = vector.new(surface and 8 or 10, 0, 0)
						projectile.Position = origin + displacement
						if surface then
							projectile.Stuck, projectile.Velocity = true, vector.new()
						end
						return projectile, { Origin = origin, Displacement = displacement, Surface = surface }
					end
					if frame == 1 then return projectile, {} end
					projectile.Position = vector.new(6, 0, 0)
					projectile.Stuck, projectile.IsActive = true, false
					return projectile, { Surface = {} }
				end,
			},
			projectile = {
				Create = function() return shot end,
				HideSplat = function()
					hideCount = hideCount + 1
					if not popping then error("fixture splat cleanup failure") end
				end,
			},
			["impact-contact"] = {
				FindVictim = function(surface, shooterId)
					assert(shooterId == shooter.UserId)
					return surface and victim
				end,
				FindVisual = function(step)
					if popping then
						if step.Surface then return { Position = shot.Position, Time = clock.Now } end
						return nil
					end
					if frame == 1 then error("fixture lookup failure before contact") end
					return {}
				end,
			},
			["impact-bubble"] = { Spawn = function()
				assert(scores[victim].Value == 75 and scores[shooter].Value == 40 and hitCount == 1)
				spawnCount = spawnCount + 1
				error("fixture renderer failure")
			end, PopAlongStep = noOp },
			["target-spawner"] = { SpawnTargetsForLevel = function() return { target } end },
			["game-controller"] = { Initialize = noOp },
			target = {},
		}),
		player = node({ ["session-score"] = session }),
		levels = node({ ["level-data"] = {
			Levels = { {} },
			Load = function() return { WindProfile = {} } end,
		} }),
		networking = node({ ["remote-events"] = {
			GetFireEvent = function() return fire end,
			GetHitEvent = function() return hit end,
			GetUpdateHUDEvent = function() return broadcast end,
			GetLevelCompleteEvent = function() return broadcast end,
		} }),
	})
	if popping then modules.gameplay["impact-bubble"] = bubbles end
	local services = {
		Players = { PlayerAdded = signal(), PlayerRemoving = signal(), GetPlayers = function() return { shooter, victim } end },
		RunService = { Heartbeat = { Wait = coroutine.yield } },
		ReplicatedStorage = node({ Shared = node({
			constants = { Projectile = { Velocity = 10, Gravity = 0, MaxLifetime = 30 }, Debug = {} },
			config = { Environment = { IsServer = true } },
		}) }),
		ServerScriptService = node({ Server = modules }),
	}
	local environment = setmetatable({
		game = { GetService = function(_, name) return services[name] end },
		require = function(module) return assert(module) end,
		task = {
			delay = function(_, startLevel) start = startLevel end,
			spawn = function(gameLoop) loop = coroutine.wrap(gameLoop) end,
		},
		tick = function() return 1 end,
		typeof = function() return "Vector3" end,
		print = noOp,
		warn = function() warnings = warnings + 1 end,
	}, { __index = _G })
	assert(loadfile("src/server/main.server.lua", "t", environment))()
	start()
	fire.OnServerEvent:Fire(shooter, character, { Position = vector.new(), Direction = vector.new(1, 0, 0) })
	if popping then
		for i = 1, 2 do
			loop()
			near(shot.Position.X, 10 * i)
			near(shot.Velocity.X, 10)
			assert(not shot.Stuck and shot.IsActive and hitCount == 0 and hideCount == 0)
			assert(scores[victim].Value == 70 and scores[shooter].Value == 40)
			if full then
				assert(full.DestroyCount == 1 and inflating.DestroyCount == 1)
				assert(later.DestroyCount == i - 1 and own.Parent == world and miss.Parent == world)
				assert(expired.Parent == nil and removed.Parent == nil)
				assert(#events == i + 2)
			end
		end
		loop()
		near(shot.Position.X, 28)
		near(shot.Velocity.Magnitude, 0)
		assert(shot.Stuck and not shot.IsActive and target.IsDefeated and hitCount == 1 and hideCount == 1)
		assert(scores[victim].Value == 75 and scores[shooter].Value == 40 and warnings == 2)
		local wallBubble = parts[#parts]
		assert(wallBubble.Parent == world and wallBubble.Position == shot.Position and not wallBubble.CanQuery)
		assert(#parts == (full and 9 or 1))
		if full then
			assert(beyond.Parent == world and miss.Parent == world and own.Parent == world)
			removed.AncestryChanged:Fire()
			bubbles.PopAlongStep({ Origin = vector.new(), Displacement = vector.new(17, 0, 0) }, shot)
			assert(#events == 4)
			for _, event in ipairs(events) do
				if event.Position == expired.Position then
					near(event.Axis.Y, 1)
				elseif event.Position == full.Position then
					local y = -full.Position.Y * 2 / full.Size.Y
					near(event.Axis.Y, y)
					near(event.Axis.X, -math.sqrt(1 - y * y))
				else
					near(event.Axis.X, -1)
				end
			end
			assert(full.DestroyCount == 1 and inflating.DestroyCount == 1 and later.DestroyCount == 1)
			assert(expired.DestroyCount == 1 and removed.DestroyCount == 1)
			local liveConnections = 0
			for _ in pairs(listeners) do liveConnections = liveConnections + 1 end
			assert(liveConnections == 4)
		end
		return
	end
	loop()
	assert(hitCount == 0 and scores[victim].Value == 70 and warnings == 3) -- two missing spawn roots and the lookup
	loop()
	assert(scores[victim].Value == 75 and scores[shooter].Value == 40)
	assert(target.IsDefeated and hitCount == 1 and hideCount == 1 and spawnCount == 1)
	assert(warnings == 5)
end

test("live-loop", function() runLiveLoop() end)
test("shoot-through", function()
	runLiveLoop("empty")
	runLiveLoop("with-bubbles")
end)

test("pop-renderer", function()
	for _, allowMesh in ipairs({ true, false }) do
		local remote, frame = signal(), signal()
		local world, parts, vertices = {}, {}, {}
		local warnings = 0
		local mesh = {
			AddVertex = function(_, point)
				table.insert(vertices, point)
				return #vertices
			end,
			SetPosition = function(_, id, point) vertices[id] = point end,
			AddTriangle = function() end,
			Destroy = function(self) self.Destroyed = true end,
		}
		local function newPart()
			local part = { Destroy = function(self) self.Parent = nil end }
			table.insert(parts, part)
			return part
		end
		local remoteFolder = { WaitForChild = function() return { OnClientEvent = remote } end }
		local services = {
			AssetService = {
				CreateEditableMesh = function()
					if not allowMesh then error("Mesh APIs disabled") end
					return mesh
				end,
				CreateMeshPartAsync = newPart,
			},
			ReplicatedStorage = { WaitForChild = function() return remoteFolder end },
			RunService = { RenderStepped = frame },
		}
		local environment = setmetatable({
			workspace = world,
			game = { GetService = function(_, name) return services[name] end },
			Vector3 = setmetatable({ zero = vector.new(), one = vector.new(1, 1, 1), yAxis = vector.new(0, 1, 0) }, { __index = vector }),
			CFrame = { lookAt = function() return { VectorToWorldSpace = function(_, point) return point end } end },
			Random = { new = function() return { NextNumber = function(_, min, max) return (min + max) / 2 end } end },
			Color3 = { fromRGB = function() return "pink" end },
			Content = { fromObject = function(object) return object end },
			Enum = { CollisionFidelity = {}, RenderFidelity = {}, Material = {}, PartType = {} },
			Instance = { new = newPart },
			warn = function() warnings = warnings + 1 end,
		}, { __index = _G })
		assert(loadfile("src/client/rendering/bubble-pop.client.lua", "t", environment))()
		remote:Fire(vector.new(), vector.new(2, 2, 2), vector.new(0, 0, -1))
		if allowMesh then
			assert(vertices[1].Z < -0.95 and parts[1].Parent == world)
		end
		frame:Fire(0.14)
		if allowMesh then
			assert(vertices[1].Z > 0 and parts[1].Transparency > 0.5)
		end
		local visibleDrops = 0
		for _, part in ipairs(parts) do
			if part.Name == "GumPopDroplet" and part.Parent == world then
				visibleDrops = visibleDrops + 1
				assert(not part.CanCollide and not part.CanQuery and not part.CanTouch)
			end
		end
		assert(visibleDrops == 24)
		frame:Fire(0.15)
		assert(not frame.callback and (not allowMesh or mesh.Destroyed))
		for _, part in ipairs(parts) do assert(not part.Parent) end
		assert(warnings == (allowMesh and 0 or 1))
	end
end)
