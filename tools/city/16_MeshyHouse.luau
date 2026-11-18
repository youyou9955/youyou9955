--!nolint
-- 16 : maison Meshy visitable (essai sur une seule maison avant de généraliser).
-- L'extérieur est le modèle Meshy léger HouseL (~3000 triangles, sans collision). Dedans, une coque
-- en pièces : murs de collision invisibles avec l'ouverture de la porte, enduit intérieur, fenêtres,
-- sol, plafond, lumière et meubles. Une vraie porte (tag HouseDoor) recouvre la porte peinte du
-- modèle ; quand elle s'ouvre, un « DoorShade » sombre masque la porte peinte (voir HouseDoors).
-- Repère local : origine au sol au centre de la fondation, façade vers -Z.
local Lib = require(script.Parent.Lib)
local CS = game:GetService("CollectionService")
local city = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("City")
local M = Enum.Material
local V = Vector3.new
local rgb = Color3.fromRGB

-- Calage du modèle HouseL, mesuré à l'échelle 24 (en studs à cette échelle)
local SCALE = 24
local CAL = {
	doorX = -0.3, -- centre de la porte peinte
	facadeZ = -4.7, -- mur de façade principal
	backZ = 9.2,
	sideX = 10.7,
	floorY = 1.0, -- dessus de la fondation
	ceilY = 8.4,
	doorW = 3.0,
	doorH = 6.6,
}

local function furn(parent, cf, name, x, y, z, face, h)
	local src = city:FindFirstChild(name)
	if not src then
		return
	end
	local s = src.Size * (h / src.Size.Y)
	local m = src:Clone()
	for _, c in m:GetChildren() do
		if c:IsA("SurfaceAppearance") then
			c:Destroy()
		end
	end
	m.Size = s
	m.CFrame = cf * CFrame.new(x, y + s.Y / 2, z) * CFrame.lookAt(Vector3.zero, face)
	m.Anchored = true
	m.CanCollide = true
	m.CanTouch = false
	pcall(function()
		m.CollisionFidelity = Enum.CollisionFidelity.Box
	end)
	m.Name = "Furniture_" .. name
	m.Parent = parent
	return m
end

local function build(lot, cf, scale)
	local k = scale / SCALE
	local c = {}
	for key, v in CAL do
		c[key] = v * k
	end
	local m = Lib.model(lot, "MeshyHouseBody")
	m:SetAttribute("Kind", "HouseL")

	-- extérieur Meshy
	local src = city.HouseL
	local shell = src:Clone()
	shell.Size = src.Size * scale
	shell.CFrame = cf * CFrame.new(0, shell.Size.Y / 2, 0)
	shell.Anchored = true
	shell.CanCollide = false
	shell.CanQuery = false
	shell.CanTouch = false
	shell.Name = "Shell"
	shell.Parent = m

	local function P(lcf, size, color, mat, props)
		return Lib.part(m, cf * lcf, size, color, mat, props)
	end
	local function D(lcf, size, color, mat, props)
		return Lib.deco(m, cf * lcf, size, color, mat, props)
	end
	local INV = { Transparency = 1, CastShadow = false, Name = "Collision" }

	local x1, x2 = -c.sideX + 0.6, c.sideX - 0.6
	local z1, z2 = c.facadeZ + 0.35, c.backZ - 0.6
	local y0, y1 = c.floorY, c.ceilY
	local hh = y1 - y0
	local wallC = rgb(238, 234, 224)

	-- sol, plafond, socle (collision)
	P(CFrame.new(0, y0 / 2, (z1 + z2) / 2), V(x2 - x1 + 1.4, y0, z2 - z1 + 1.4), rgb(120, 116, 110), M.Concrete, INV)
	P(CFrame.new(0, y0 + 0.05, (z1 + z2) / 2), V(x2 - x1, 0.1, z2 - z1), rgb(150, 112, 78), M.WoodPlanks, { Name = "Floor" })
	P(CFrame.new(0, y1 + 0.15, (z1 + z2) / 2), V(x2 - x1, 0.3, z2 - z1), rgb(248, 246, 240), M.Plaster, { Name = "Ceiling" })
	local lamp = D(CFrame.new(0, y1 - 0.1, (z1 + z2) / 2), V(1.6, 0.2, 1.6), rgb(255, 244, 220), M.Neon, { Name = "CeilingLight" })
	local light = Instance.new("PointLight")
	light.Range, light.Brightness, light.Color = 26, 1.2, rgb(255, 236, 205)
	light.Parent = lamp

	-- murs intérieurs : collision + enduit, avec ouvertures (porte en façade, fenêtres)
	local function wall(axis, fixed, a1, a2, holes, inward)
		table.sort(holes, function(p, q)
			return p.c < q.c
		end)
		local function seg(a, b, ya, yb)
			if b - a < 0.05 or yb - ya < 0.05 then
				return
			end
			local mid, h = (ya + yb) / 2, yb - ya
			if axis == "X" then
				P(CFrame.new((a + b) / 2, mid, fixed), V(b - a, h, 0.4), wallC, M.Plaster, { Name = "InnerWall" })
			else
				P(CFrame.new(fixed, mid, (a + b) / 2), V(0.4, h, b - a), wallC, M.Plaster, { Name = "InnerWall" })
			end
		end
		local cur = a1
		for _, o in holes do
			local a, b = o.c - o.w / 2, o.c + o.w / 2
			seg(cur, a, y0, y1)
			seg(a, b, y0, o.b)
			seg(a, b, o.t, y1)
			cur = b
			if o.glass then
				local gcf = axis == "X" and CFrame.new(o.c, (o.b + o.t) / 2, fixed) or CFrame.new(fixed, (o.b + o.t) / 2, o.c) * CFrame.Angles(0, math.pi / 2, 0)
				D(gcf, V(o.w, o.t - o.b, 0.08), rgb(160, 190, 205), M.Glass, { Transparency = 0.7, Name = "WindowGlass" })
				D(gcf * CFrame.new(0, -(o.t - o.b) / 2 - 0.1, inward * 0.25), V(o.w + 0.4, 0.15, 0.5), rgb(245, 245, 240), M.SmoothPlastic, { Name = "InnerSill" })
			end
		end
		seg(cur, a2, y0, y1)
	end
	local dx = c.doorX
	wall("X", z1, x1, x2, {
		{ c = dx, w = c.doorW + 0.4, b = y0, t = y0 + c.doorH + 0.2 },
		{ c = -6.5 * k, w = 3.6 * k, b = y0 + 2.4, t = y0 + 5.8, glass = true },
		{ c = 6.2 * k, w = 3.6 * k, b = y0 + 2.4, t = y0 + 5.8, glass = true },
	}, 1)
	wall("X", z2, x1, x2, { { c = -4 * k, w = 4 * k, b = y0 + 2.4, t = y0 + 5.8, glass = true }, { c = 5 * k, w = 4 * k, b = y0 + 2.4, t = y0 + 5.8, glass = true } }, -1)
	wall("Z", x1, z1, z2, { { c = (z1 + z2) / 2, w = 3.6 * k, b = y0 + 2.4, t = y0 + 5.8, glass = true } }, 1)
	wall("Z", x2, z1, z2, { { c = (z1 + z2) / 2, w = 3.6 * k, b = y0 + 2.4, t = y0 + 5.8, glass = true } }, -1)
	-- couloir entre la porte peinte et le mur intérieur (le porche Meshy n'a pas de collision)
	local fz = c.facadeZ
	P(CFrame.new(dx, y0 / 2, (fz + z1) / 2), V(c.doorW + 0.4, y0, z1 - fz + 0.2), rgb(150, 112, 78), M.WoodPlanks, { Name = "Threshold" })
	P(CFrame.new(dx, y0 / 2, fz - 1.6 * k), V(c.doorW + 2, y0, 3.2 * k), rgb(120, 116, 110), M.Concrete, INV) -- porche
	P(CFrame.new(dx, y0 / 4, fz - 3.6 * k), V(c.doorW + 2, y0 / 2, 1 * k), rgb(120, 116, 110), M.Concrete, INV) -- marche

	-- porte d'entrée : devant la porte peinte, s'ouvre vers l'intérieur
	local doorCF = CFrame.new(dx, y0 + c.doorH / 2, fz - 0.12)
	local door = P(doorCF, V(c.doorW, c.doorH, 0.2), rgb(28, 44, 78), M.Wood, { Name = "HouseDoor" })
	CS:AddTag(door, "HouseDoor")
	for _, sd in { -1, 1 } do
		local h = Lib.part(m, cf * doorCF * CFrame.new(c.doorW / 2 - 0.35, -0.3, sd * 0.16), V(0.14, 0.14, 0.14), rgb(212, 175, 55), M.Metal, { Name = "Handle", Anchored = false, CanCollide = false, Massless = true })
		local wc = Instance.new("WeldConstraint")
		wc.Part0, wc.Part1 = door, h
		wc.Parent = h
	end
	local shade = D(CFrame.new(dx, y0 + c.doorH / 2, fz - 0.04), V(c.doorW - 0.05, c.doorH - 0.05, 0.05), rgb(58, 46, 36), M.SmoothPlastic, { Name = "DoorShade", Transparency = 1 })
	local ov = Instance.new("ObjectValue")
	ov.Name = "Shade"
	ov.Value = shade
	ov.Parent = door

	-- meubles : salon à gauche (vu de la rue, côté +X), cuisine au fond à droite
	local FRONT, BACK, LEFT, RIGHT = V(0, 0, -1), V(0, 0, 1), V(-1, 0, 0), V(1, 0, 0)
	furn(m, cf, "Sofa", x2 - 1.6, y0, (z1 + z2) / 2, LEFT, 2.8)
	furn(m, cf, "TV", 2.6 * k, y0, (z1 + z2) / 2, RIGHT, 3.6)
	furn(m, cf, "Plant", x2 - 1, y0, z1 + 1.2, LEFT, 3.6)
	furn(m, cf, "Kitchen", x1 + 4.2, y0, z2 - 1.3, FRONT, 3.8)
	furn(m, cf, "Fridge", x1 + 0.9, y0, z2 - 3.6, RIGHT, 6.6)
	furn(m, cf, "Dining", x1 + 4.2, y0, z1 + 4.2, FRONT, 3.2)
	furn(m, cf, "Bookshelf", x2 - 1, y0, z2 - 1.2, FRONT, 6.4)
	return m
end

-- Construit la maison test sur le terrain désigné (attribut TestHouseCF posé sur le modèle House)
return function(lotPath)
	local lot = lotPath or workspace.Map.Districts.Residential.Block_1_4.House
	local cf = lot:GetAttribute("TestHouseCF")
	if not cf then
		local body = lot:FindFirstChild("HouseBody")
		local f = body and body:FindFirstChild("Foundation")
		if not f then
			return "pas de maison sur ce terrain"
		end
		cf = f.CFrame * CFrame.new(0, -f.Size.Y / 2, 0)
		lot:SetAttribute("TestHouseCF", cf)
	end
	for _, ch in lot:GetChildren() do
		if ch.Name == "HouseBody" or ch.Name == "MeshyHouseBody" or ch.Name == "MeshyHouseL" then
			ch:Destroy()
		end
	end
	build(lot, cf, SCALE)
	-- l'allée et la boîte aux lettres suivent la porte (au centre du modèle)
	local path = lot:FindFirstChild("Path")
	if path then
		local p = cf:PointToObjectSpace(path.Position)
		path.CFrame = cf * CFrame.new(CAL.doorX, p.Y, p.Z)
	end
	local mb = lot:FindFirstChild("Mailbox")
	if mb then
		local p = cf:PointToObjectSpace(mb:GetPivot().Position)
		mb:PivotTo(cf * CFrame.new(CAL.doorX - 3, p.Y, p.Z) * (cf.Rotation:Inverse() * mb:GetPivot().Rotation))
	end
	return "maison test Meshy construite"
end
