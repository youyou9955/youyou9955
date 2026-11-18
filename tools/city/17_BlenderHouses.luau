--!nolint
-- 17 : maisons modélisées dans Blender (tools/blender/house_a.py), importées dans
-- ReplicatedStorage.Assets.Houses.HouseA_<largeur> (18, 21, 24 studs de façade).
-- Chaque modèle est un ensemble de MeshParts nommés par matériau (WALL_EXT, ROOF, TRIM...) sans
-- collision ; les collisions viennent du fichier assets/blender/HouseA_<W>.json (boîtes invisibles).
-- Repère : origine au sol au centre de la maison, façade vers -Z. Blender (x, y, z) -> Roblox (-x, z, y).
local Lib = require(script.Parent.Lib)
local CS = game:GetService("CollectionService")
local Http = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local city = RS.Assets.City
local houses = RS.Assets.Houses
local M = Enum.Material
local V = Vector3.new
local rgb = Color3.fromRGB

-- Styles : enduit clair, bardage bleu, brique, pierre, bardage vert sauge, enduit crème
local STYLES = {
	{ wall = { rgb(236, 230, 216), M.Plaster }, trim = rgb(250, 250, 246), roof = { rgb(70, 72, 78), M.Slate }, door = rgb(30, 52, 92) },
	{ wall = { rgb(132, 158, 182), M.WoodPlanks }, trim = rgb(248, 248, 244), roof = { rgb(58, 60, 66), M.Slate }, door = rgb(140, 36, 34) },
	{ wall = { rgb(150, 82, 62), M.Brick }, trim = rgb(238, 232, 220), roof = { rgb(52, 50, 52), M.Slate }, door = rgb(24, 60, 46) },
	{ wall = { rgb(184, 176, 160), M.Cobblestone }, trim = rgb(242, 238, 228), roof = { rgb(110, 62, 48), M.Slate }, door = rgb(90, 58, 36) },
	{ wall = { rgb(150, 168, 140), M.WoodPlanks }, trim = rgb(246, 244, 236), roof = { rgb(76, 70, 66), M.Slate }, door = rgb(220, 196, 120) },
	{ wall = { rgb(240, 222, 188), M.Plaster }, trim = rgb(252, 250, 244), roof = { rgb(150, 76, 54), M.Slate }, door = rgb(34, 34, 40) },
}

local FIXED = {
	PLASTER = { rgb(240, 236, 228), M.Plaster },
	GLASS = { rgb(150, 182, 200), M.Glass },
	FRAME = { rgb(246, 246, 242), M.SmoothPlastic },
	DOOR_GLASS = { rgb(170, 196, 210), M.Glass },
	FLOOR = { rgb(152, 112, 76), M.WoodPlanks },
	CEILING = { rgb(248, 246, 240), M.Plaster },
	STAIRS = { rgb(132, 96, 64), M.Wood },
	GUTTER = { rgb(232, 232, 228), M.Metal },
	STONE = { rgb(146, 142, 134), M.Slate },
	CONCRETE = { rgb(178, 176, 170), M.Concrete },
	BRICK = { rgb(132, 70, 54), M.Brick },
	ROOFCAP = { rgb(60, 60, 64), M.Metal },
	SLAB = { rgb(200, 198, 192), M.Concrete },
}

local function toR(p)
	return V(-p[1], p[3], p[2])
end

local cache = {}
local function info(base, W)
	local key = "HouseA_" .. W
	if not cache[key] then
		cache[key] = Http:JSONDecode(Http:GetAsync(base .. "assets/blender/" .. key .. ".json"))
	end
	return cache[key]
end

local function furn(parent, cf, f)
	local src = city:FindFirstChild(f.n .. "L") or city:FindFirstChild(f.n)
	if not src then
		return
	end
	local s = src.Size * (f.h / src.Size.Y)
	local m = src:Clone()
	for _, c in m:GetChildren() do
		if c:IsA("SurfaceAppearance") then
			c:Destroy()
		end
	end
	local p = toR(f.p)
	m.Size = s
	m.CFrame = cf * CFrame.new(p + V(0, s.Y / 2, 0)) * CFrame.lookAt(Vector3.zero, V(-f.f[1], 0, f.f[2]))
	m.Anchored, m.CanCollide, m.CanTouch = true, true, false
	pcall(function()
		m.CollisionFidelity = Enum.CollisionFidelity.Box
	end)
	m.Name = "Furniture_" .. f.n
	m.Parent = parent
end

-- Construit une maison Blender de largeur W dans lot, origine au sol cf
local function build(lot, cf, W, style, data)
	local tpl = houses:FindFirstChild("HouseA_" .. W)
	assert(tpl, "modèle HouseA_" .. W .. " absent")
	local m = Instance.new("Model")
	m.Name = "BlenderHouseBody"
	m:SetAttribute("Kind", "HouseA_" .. W)
	m:SetAttribute("Style", style)
	local st = STYLES[style]
	local door
	for _, src in tpl:GetChildren() do
		if src:IsA("MeshPart") then
			local p = src:Clone()
			p.CFrame = cf * src.CFrame
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
			local n = src.Name
			local look = FIXED[n]
			if n == "WALL_EXT" then
				look = st.wall
			elseif n == "ROOF" then
				look = st.roof
			elseif n == "TRIM" then
				look = { st.trim, M.SmoothPlastic }
			elseif n == "DOOR" then
				look = { st.door, M.Wood }
			end
			if look then
				p.Color, p.Material = look[1], look[2]
			end
			if n == "GLASS" or n == "DOOR_GLASS" then
				p.Transparency = 0.55
				p.CastShadow = false
			end
			p.Parent = m
			if n == "DOOR" then
				door = p
			end
		end
	end
	-- porte d'entrée fonctionnelle
	if door then
		door.Name = "HouseDoor"
		door.CanCollide, door.CanQuery = true, true
		pcall(function()
			door.CollisionFidelity = Enum.CollisionFidelity.Box
		end)
		local g = m:FindFirstChild("DOOR_GLASS")
		if g then
			g.Anchored = false
			g.Massless = true
			local wc = Instance.new("WeldConstraint")
			wc.Part0, wc.Part1 = door, g
			wc.Parent = g
		end
		for _, sd in { -1, 1 } do
			local h = Lib.part(m, door.CFrame * CFrame.new(door.Size.X / 2 - 0.4, -0.3, sd * (door.Size.Z / 2 + 0.05)), V(0.16, 0.16, 0.16), rgb(212, 175, 55), M.Metal, { Name = "Handle", Anchored = false, CanCollide = false, Massless = true })
			local wc = Instance.new("WeldConstraint")
			wc.Part0, wc.Part1 = door, h
			wc.Parent = h
		end
		CS:AddTag(door, "HouseDoor")
	end
	-- collisions invisibles
	for _, b in data.collision do
		local p = Instance.new("Part")
		p.Name = "Collision"
		p.Size = V(b.s[1], b.s[3], b.s[2])
		p.CFrame = cf * CFrame.new(toR(b.c))
		p.Anchored, p.CanCollide, p.CanTouch = true, true, false
		p.Transparency, p.CastShadow = 1, false
		p.Parent = m
	end
	-- lumières de plafond
	for _, l in data.lights do
		local p = Instance.new("Part")
		p.Name = "CeilingLight"
		p.Size = V(1.4, 0.15, 1.4)
		p.CFrame = cf * CFrame.new(toR(l) - V(0, 0.08, 0))
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Material, p.Color = M.Neon, rgb(255, 244, 222)
		p.CastShadow = false
		local pl = Instance.new("PointLight")
		pl.Range, pl.Brightness, pl.Color, pl.Shadows = 20, 0.9, rgb(255, 236, 205), false
		pl.Parent = p
		p.Parent = m
	end
	for _, f in data.furniture do
		furn(m, cf, f)
	end
	m.Parent = lot
	return m
end

local WIDTHS = { 24, 21, 18 }
local function pickWidth(avail)
	for _, w in WIDTHS do
		if w <= avail + 0.6 then
			return w
		end
	end
	return 18
end

-- opts = { base = "https://raw.githubusercontent.com/<repo>/<sha>/", lot = <Model>, style = n }
return function(opts)
	local lot = opts.lot or workspace.Map.Districts.Residential.Block_1_4.House
	local cf = lot:GetAttribute("TestHouseCF")
	local avail = lot:GetAttribute("LotWidth")
	if not cf then
		local body = lot:FindFirstChild("HouseBody")
		local f = body and body:FindFirstChild("Foundation")
		if not f then
			return "pas de maison sur ce terrain"
		end
		cf = f.CFrame * CFrame.new(0, -f.Size.Y / 2, 0)
		avail = f.Size.X
		lot:SetAttribute("TestHouseCF", cf)
		lot:SetAttribute("LotWidth", avail)
	end
	local W = opts.width or pickWidth(avail or 21)
	local style = opts.style or ((#lot:GetFullName() + W) % #STYLES + 1)
	local data = info(opts.base, W)
	for _, ch in lot:GetChildren() do
		if ch.Name == "HouseBody" or ch.Name == "MeshyHouseBody" or ch.Name == "BlenderHouseBody" or ch.Name == "Garage" then
			ch:Destroy()
		end
	end
	build(lot, cf, W, style, data)
	-- l'allée suit la porte (Blender x = door.x -> Roblox x = -door.x)
	local dx = -data.door.x
	local path = lot:FindFirstChild("Path")
	if path then
		local p = cf:PointToObjectSpace(path.Position)
		path.CFrame = cf * CFrame.new(dx, p.Y, p.Z)
	end
	local mb = lot:FindFirstChild("Mailbox")
	if mb then
		local p = cf:PointToObjectSpace(mb:GetPivot().Position)
		mb:PivotTo(cf * CFrame.new(dx - 6, p.Y, p.Z) * (cf.Rotation:Inverse() * mb:GetPivot().Rotation))
	end
	return ("maison Blender HouseA_%d style %d construite"):format(W, style)
end
