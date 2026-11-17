--!nolint
-- Wrong Way Delivery : bibliothèque de construction de la ville (outil d'édition, pas du gameplay).
local Lib = {}

local Terrain = workspace.Terrain

Lib.ROAD = 0.2 -- dessus de la chaussée
Lib.WALK = 0.7 -- dessus des trottoirs
Lib.L = { -480, -320, -160, 0, 160, 320, 480 } -- axes de la grille
Lib.rng = Random.new(20261117)

Lib.C = {
	asphalt = Color3.fromRGB(54, 54, 60),
	asphaltLight = Color3.fromRGB(70, 70, 76),
	white = Color3.fromRGB(240, 240, 240),
	yellow = Color3.fromRGB(245, 200, 40),
	walk = Color3.fromRGB(196, 192, 184),
	curb = Color3.fromRGB(160, 158, 152),
	grass = Color3.fromRGB(104, 160, 76),
	concrete = Color3.fromRGB(176, 174, 168),
	metal = Color3.fromRGB(120, 124, 130),
	dark = Color3.fromRGB(35, 35, 40),
	glass = Color3.fromRGB(120, 170, 210),
	wood = Color3.fromRGB(120, 82, 50),
	brandOrange = Color3.fromRGB(255, 120, 30),
	brandBlue = Color3.fromRGB(30, 60, 140),
}

---------------------------------------------------------------- Bases
local budget = 0
function Lib.yield(n)
	budget += (n or 1)
	if budget >= 120 then
		budget = 0
		task.wait()
	end
end

function Lib.folder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

function Lib.model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function Lib.map()
	return workspace:WaitForChild("Map")
end

function Lib.path(...)
	local node = Lib.map()
	for _, name in { ... } do
		node = Lib.folder(node, name)
	end
	return node
end

function Lib.part(parent, cf, size, color, material, props)
	local p = Instance.new((props and props.Class) or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props and props.Shape then
		p.Shape = props.Shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if props then
		for k, v in props do
			if k ~= "Class" and k ~= "Shape" then
				p[k] = v
			end
		end
	end
	p.Parent = parent
	Lib.yield()
	return p
end

-- Objet purement décoratif : pas de collision, pas de requêtes.
function Lib.deco(parent, cf, size, color, material, props)
	props = props or {}
	props.CanCollide = false
	props.CanTouch = false
	props.CanQuery = false
	return Lib.part(parent, cf, size, color, material, props)
end

-- Marquage au sol : décoratif et sans ombre.
function Lib.mark(parent, cf, size, color)
	return Lib.deco(parent, cf, size, color or Lib.C.white, Enum.Material.SmoothPlastic, { CastShadow = false })
end

function Lib.fill(cf, size, material)
	Terrain:FillBlock(cf, size, material)
	Lib.yield(4)
end

function Lib.ball(pos, radius, material)
	Terrain:FillBall(pos, radius, material)
	Lib.yield(6)
end

---------------------------------------------------------------- Texte
function Lib.label(part, face, text, fg, bg, font, glow)
	local g = Instance.new("SurfaceGui")
	g.Face = face or Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 16
	g.LightInfluence = glow and 0 or 1
	pcall(function()
		g.MaxDistance = 400
	end)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = bg and 0 or 1
	t.BackgroundColor3 = bg or Color3.new(0, 0, 0)
	t.TextColor3 = fg or Color3.new(1, 1, 1)
	t.Font = font or Enum.Font.GothamBlack
	t.TextScaled = true
	t.Text = text
	t.Parent = g
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.PaddingTop = UDim.new(0.08, 0)
	pad.PaddingBottom = UDim.new(0.08, 0)
	pad.Parent = t
	g.Parent = part
	return g
end

-- Panneau texte (le texte est sur la face avant = LookVector).
function Lib.sign(parent, cf, size, text, bg, fg, opts)
	opts = opts or {}
	local p = Lib.deco(parent, cf, size, bg, opts.material or Enum.Material.SmoothPlastic, { Name = opts.name or "Sign" })
	Lib.label(p, Enum.NormalId.Front, text, fg, nil, opts.font, opts.glow)
	if opts.double then
		Lib.label(p, Enum.NormalId.Back, text, fg, nil, opts.font, opts.glow)
	end
	return p
end

-- Panneau sur poteau (cf = pied du poteau, le panneau regarde vers LookVector).
function Lib.postSign(parent, cf, text, bg, fg, w, h, poleH)
	local m = Lib.model(parent, "PostSign")
	w, h, poleH = w or 6, h or 3, poleH or 7
	Lib.part(m, cf * CFrame.new(0, poleH / 2, 0), Vector3.new(0.4, poleH, 0.4), Lib.C.metal, Enum.Material.Metal)
	Lib.sign(m, cf * CFrame.new(0, poleH + h / 2 - 0.5, -0.3), Vector3.new(w, h, 0.2), text, bg, fg, { double = false })
	return m
end

---------------------------------------------------------------- Grille routière
function Lib.roadWidth(lineValue, otherMid, isVertical)
	if lineValue == 0 then
		return 44
	end
	if math.abs(lineValue) == 480 then
		return 30
	end
	local x, z
	if isVertical then
		x, z = lineValue, otherMid
	else
		x, z = otherMid, lineValue
	end
	if x < 0 and z > 0 then
		return 20
	end
	return 26
end

function Lib.intersectionSize(a, b)
	local sx = math.max(Lib.roadWidth(a, b - 1, true), Lib.roadWidth(a, b + 1, true))
	local sz = math.max(Lib.roadWidth(b, a - 1, false), Lib.roadWidth(b, a + 1, false))
	return sx, sz
end

-- Cellule (i, j) : i = colonne en X (1..6), j = rangée en Z (1..6)
function Lib.cell(i, j)
	local L = Lib.L
	local xa, xb, za, zb = L[i], L[i + 1], L[j], L[j + 1]
	local xm, zm = (xa + xb) / 2, (za + zb) / 2
	local c = {}
	c.x1 = xa + Lib.roadWidth(xa, zm, true) / 2
	c.x2 = xb - Lib.roadWidth(xb, zm, true) / 2
	c.z1 = za + Lib.roadWidth(za, xm, false) / 2
	c.z2 = zb - Lib.roadWidth(zb, xm, false) / 2
	c.ix1, c.ix2, c.iz1, c.iz2 = c.x1 + 6, c.x2 - 6, c.z1 + 6, c.z2 - 6
	c.cx, c.cz = (c.x1 + c.x2) / 2, (c.z1 + c.z2) / 2
	c.w, c.d = c.ix2 - c.ix1, c.iz2 - c.iz1
	return c
end

function Lib.district(i, j)
	if i == 4 and j == 4 then
		return "Headquarters"
	end
	if i <= 3 and j <= 3 then
		return "Downtown"
	elseif i >= 4 and j <= 3 then
		return "Commercial"
	elseif i <= 3 and j >= 4 then
		return "Residential"
	else
		return "Industrial"
	end
end

-- CFrame d'un bâtiment dont la façade regarde vers la rue. side = "N","S","E","W"
-- (N = +Z, S = -Z, E = +X, W = -X). pos = position au sol.
function Lib.facing(pos, side)
	local dir = ({ N = Vector3.new(0, 0, 1), S = Vector3.new(0, 0, -1), E = Vector3.new(1, 0, 0), W = Vector3.new(-1, 0, 0) })[side]
	return CFrame.lookAt(pos, pos + dir)
end

---------------------------------------------------------------- Routes
-- Route droite de a à b (points au niveau du dessus de chaussée). style :
-- center = "double" | "solid" | "dashed" | nil ; laneLines = nombre de lignes pointillées par sens
function Lib.road(parent, a, b, width, style)
	style = style or {}
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	local road = Lib.part(parent, cf * CFrame.new(0, -0.5, 0), Vector3.new(width, 1, len), Lib.C.asphalt, Enum.Material.Asphalt, { Name = "Road" })
	local marks = parent
	local function solid(x, color)
		Lib.mark(marks, cf * CFrame.new(x, 0.03, 0), Vector3.new(0.5, 0.05, len), color)
	end
	local function dashed(x, color)
		local n = math.floor(len / 20)
		for k = 0, n - 1 do
			local zl = -len / 2 + 10 + k * 20
			Lib.mark(marks, cf * CFrame.new(x, 0.03, zl), Vector3.new(0.45, 0.05, 8), color)
		end
	end
	if style.center == "double" then
		solid(-0.5, Lib.C.yellow)
		solid(0.5, Lib.C.yellow)
	elseif style.center == "solid" then
		solid(0, Lib.C.yellow)
	elseif style.center == "dashed" then
		dashed(0, Lib.C.white)
	end
	local lanes = style.laneLines or 0
	if lanes > 0 then
		local half = width / 2
		for k = 1, lanes do
			local x = half * k / (lanes + 1)
			dashed(x, Lib.C.white)
			dashed(-x, Lib.C.white)
		end
	end
	if style.edges then
		solid(width / 2 - 1, Lib.C.white)
		solid(-width / 2 + 1, Lib.C.white)
	end
	return road, cf, len
end

-- Passage piéton : bandes perpendiculaires à "dir" (direction de la route), centré sur cf.
function Lib.crosswalk(parent, cf, roadWidth)
	local n = math.floor((roadWidth - 2) / 3)
	for k = 0, n - 1 do
		local x = -roadWidth / 2 + 2 + k * 3
		Lib.mark(parent, cf * CFrame.new(x, 0.03, 0), Vector3.new(1.6, 0.05, 6), Lib.C.white)
	end
end

function Lib.arrow(parent, cf)
	Lib.mark(parent, cf * CFrame.new(0, 0.03, 1.5), Vector3.new(0.8, 0.05, 5), Lib.C.white)
	Lib.mark(parent, cf * CFrame.new(-0.9, 0.03, -1.6) * CFrame.Angles(0, math.rad(-35), 0), Vector3.new(0.7, 0.05, 2.6), Lib.C.white)
	Lib.mark(parent, cf * CFrame.new(0.9, 0.03, -1.6) * CFrame.Angles(0, math.rad(35), 0), Vector3.new(0.7, 0.05, 2.6), Lib.C.white)
end

function Lib.parkingRow(parent, cf, count, spacing, depth)
	for k = 0, count do
		local x = (k - count / 2) * spacing
		Lib.mark(parent, cf * CFrame.new(x, 0.03, 0), Vector3.new(0.35, 0.05, depth), Lib.C.white)
	end
end

---------------------------------------------------------------- Mobilier urbain
function Lib.lamp(parent, cf, withLight)
	local m = Lib.model(parent, "StreetLamp")
	Lib.part(m, cf * CFrame.new(0, 7, 0), Vector3.new(0.6, 14, 0.6), Color3.fromRGB(60, 64, 70), Enum.Material.Metal)
	Lib.deco(m, cf * CFrame.new(0, 13.8, -2), Vector3.new(0.4, 0.4, 4), Color3.fromRGB(60, 64, 70), Enum.Material.Metal)
	local head = Lib.deco(m, cf * CFrame.new(0, 13.5, -3.8), Vector3.new(1.4, 0.4, 2), Color3.fromRGB(255, 236, 190), Enum.Material.Neon)
	if withLight then
		local l = Instance.new("SpotLight")
		l.Face = Enum.NormalId.Bottom
		l.Range = 26
		l.Angle = 110
		l.Brightness = 1.6
		l.Color = Color3.fromRGB(255, 222, 170)
		l.Parent = head
	end
	return m
end

function Lib.bench(parent, cf)
	local m = Lib.model(parent, "Bench")
	Lib.deco(m, cf * CFrame.new(0, 1.6, 0), Vector3.new(5, 0.3, 1.4), Lib.C.wood, Enum.Material.Wood)
	Lib.deco(m, cf * CFrame.new(0, 2.5, 0.6), Vector3.new(5, 1.2, 0.25), Lib.C.wood, Enum.Material.Wood)
	for _, x in { -2.1, 2.1 } do
		Lib.deco(m, cf * CFrame.new(x, 0.8, 0), Vector3.new(0.3, 1.6, 1.3), Lib.C.dark, Enum.Material.Metal)
	end
	return m
end

function Lib.trash(parent, cf, color)
	local m = Lib.model(parent, "TrashCan")
	Lib.deco(m, cf * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(2.6, 1.6, 1.6), color or Color3.fromRGB(40, 110, 70), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	Lib.deco(m, cf * CFrame.new(0, 2.7, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.3, 1.8, 1.8), Lib.C.dark, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	return m
end

function Lib.hydrant(parent, cf)
	local m = Lib.model(parent, "Hydrant")
	Lib.deco(m, cf * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(2, 0.9, 0.9), Color3.fromRGB(210, 40, 40), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	Lib.deco(m, cf * CFrame.new(0, 1.2, 0), Vector3.new(1.5, 0.4, 0.4), Color3.fromRGB(210, 40, 40), Enum.Material.Metal)
	return m
end

function Lib.bush(parent, pos, size, color)
	size = size or Lib.rng:NextNumber(2.5, 4)
	return Lib.deco(parent, CFrame.new(pos + Vector3.new(0, size * 0.35, 0)), Vector3.one * size, color or Color3.fromHSV(Lib.rng:NextNumber(0.25, 0.33), 0.55, Lib.rng:NextNumber(0.4, 0.55)), Enum.Material.Grass, { Shape = Enum.PartType.Ball, Name = "Bush" })
end

function Lib.flowerBed(parent, cf, w, d)
	local m = Lib.model(parent, "FlowerBed")
	Lib.deco(m, cf * CFrame.new(0, 0.5, 0), Vector3.new(w, 1, d), Color3.fromRGB(150, 110, 80), Enum.Material.Brick)
	Lib.deco(m, cf * CFrame.new(0, 1.05, 0), Vector3.new(w - 0.6, 0.2, d - 0.6), Color3.fromRGB(90, 60, 40), Enum.Material.Ground)
	local colors = { Color3.fromRGB(240, 80, 120), Color3.fromRGB(250, 210, 60), Color3.fromRGB(170, 90, 230), Color3.fromRGB(255, 140, 60) }
	for k = 1, math.max(2, math.floor(w * d / 8)) do
		local x = Lib.rng:NextNumber(-w / 2 + 0.8, w / 2 - 0.8)
		local z = Lib.rng:NextNumber(-d / 2 + 0.8, d / 2 - 0.8)
		Lib.deco(m, cf * CFrame.new(x, 1.5, z), Vector3.one * 0.9, colors[Lib.rng:NextInteger(1, #colors)], Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball, CastShadow = false })
	end
	return m
end

function Lib.tree(parent, pos, kind, scale)
	scale = scale or Lib.rng:NextNumber(0.85, 1.25)
	kind = kind or (Lib.rng:NextNumber() < 0.75 and "round" or "pine")
	local m = Lib.model(parent, "Tree")
	if kind == "pine" then
		local h = 6 * scale
		Lib.part(m, CFrame.new(pos + Vector3.new(0, h / 2, 0)), Vector3.new(1.2, h, 1.2) * Vector3.new(scale, 1, scale), Color3.fromRGB(95, 65, 40), Enum.Material.Wood)
		local green = Color3.fromHSV(Lib.rng:NextNumber(0.3, 0.38), 0.6, Lib.rng:NextNumber(0.3, 0.42))
		for k = 0, 2 do
			local s = (9 - k * 2.6) * scale
			Lib.deco(m, CFrame.new(pos + Vector3.new(0, h + k * 3.2 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(4 * scale, s, s), green, Enum.Material.Grass, { Shape = Enum.PartType.Cylinder })
		end
	elseif kind == "palm" then
		local h = 14 * scale
		Lib.part(m, CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(4)), Vector3.new(1, h, 1), Color3.fromRGB(150, 115, 75), Enum.Material.Wood)
		for k = 0, 4 do
			local a = k * math.pi * 2 / 5
			Lib.deco(m, CFrame.new(pos + Vector3.new(0, h, 0)) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -3) * CFrame.Angles(math.rad(-20), 0, 0), Vector3.new(2, 0.3, 7), Color3.fromRGB(70, 150, 60), Enum.Material.Grass)
		end
	else
		local h = 7 * scale
		Lib.part(m, CFrame.new(pos + Vector3.new(0, h / 2, 0)), Vector3.new(1.3 * scale, h, 1.3 * scale), Color3.fromRGB(110, 75, 45), Enum.Material.Wood)
		local green = Color3.fromHSV(Lib.rng:NextNumber(0.22, 0.32), Lib.rng:NextNumber(0.5, 0.7), Lib.rng:NextNumber(0.45, 0.65))
		Lib.deco(m, CFrame.new(pos + Vector3.new(0, h + 2 * scale, 0)), Vector3.one * 8 * scale, green, Enum.Material.Grass, { Shape = Enum.PartType.Ball })
		if Lib.rng:NextNumber() < 0.6 then
			Lib.deco(m, CFrame.new(pos + Vector3.new(2 * scale, h + 0.5 * scale, 1 * scale)), Vector3.one * 5.5 * scale, green, Enum.Material.Grass, { Shape = Enum.PartType.Ball })
		end
	end
	return m
end

function Lib.trafficLight(parent, cf)
	-- cf : pied du poteau, LookVector = vers les voitures qui arrivent
	local m = Lib.model(parent, "TrafficLight")
	Lib.part(m, cf * CFrame.new(0, 6, 0), Vector3.new(0.6, 12, 0.6), Lib.C.dark, Enum.Material.Metal)
	Lib.deco(m, cf * CFrame.new(-4, 11.6, 0), Vector3.new(8, 0.5, 0.5), Lib.C.dark, Enum.Material.Metal)
	Lib.deco(m, cf * CFrame.new(-7, 10.2, 0), Vector3.new(1.4, 4, 1.2), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
	local cols = { Color3.fromRGB(255, 50, 40), Color3.fromRGB(255, 190, 30), Color3.fromRGB(60, 230, 90) }
	for k = 1, 3 do
		Lib.deco(m, cf * CFrame.new(-7, 11.5 - (k - 1) * 1.25, -0.65), Vector3.new(0.9, 0.9, 0.2), cols[k], k == 3 and Enum.Material.Neon or Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Block })
	end
	return m
end

function Lib.stopSign(parent, cf)
	local m = Lib.model(parent, "StopSign")
	Lib.part(m, cf * CFrame.new(0, 3.5, 0), Vector3.new(0.3, 7, 0.3), Lib.C.metal, Enum.Material.Metal)
	local s = Lib.deco(m, cf * CFrame.new(0, 7, -0.2) * CFrame.Angles(0, 0, math.rad(22.5)), Vector3.new(2.6, 2.6, 0.15), Color3.fromRGB(200, 30, 30))
	local s2 = Lib.deco(m, cf * CFrame.new(0, 7, -0.2), Vector3.new(2.6, 2.6, 0.16), Color3.fromRGB(200, 30, 30))
	Lib.label(s2, Enum.NormalId.Front, "STOP", Color3.new(1, 1, 1), nil, Enum.Font.GothamBlack)
	return m
end

function Lib.fence(parent, a, b, height, color, collide, material)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	local f = (collide and Lib.part or Lib.deco)(parent, cf * CFrame.new(0, height / 2, 0), Vector3.new(0.3, height, len), color, material or Enum.Material.Wood, { Name = "Fence" })
	return f
end

function Lib.ac(parent, cf)
	Lib.deco(parent, cf * CFrame.new(0, 1, 0), Vector3.new(3, 2, 2.4), Color3.fromRGB(200, 200, 205), Enum.Material.Metal, { Name = "ACUnit" })
	Lib.deco(parent, cf * CFrame.new(0, 2.05, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.1, 1.8, 1.8), Lib.C.dark, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
end

function Lib.pallet(parent, cf, withBoxes)
	Lib.deco(parent, cf * CFrame.new(0, 0.4, 0), Vector3.new(4, 0.8, 4), Color3.fromRGB(170, 130, 85), Enum.Material.WoodPlanks, { Name = "Pallet" })
	if withBoxes then
		for k = 1, Lib.rng:NextInteger(1, 4) do
			local s = Lib.rng:NextNumber(1.4, 2)
			Lib.deco(parent, cf * CFrame.new(Lib.rng:NextNumber(-0.9, 0.9), 0.8 + s / 2 + (k - 1) * 1.6 * 0, Lib.rng:NextNumber(-0.9, 0.9)) * CFrame.new(0, (k > 2 and 1.8 or 0), 0) * CFrame.Angles(0, math.rad(Lib.rng:NextNumber(-20, 20)), 0), Vector3.new(s, s * 0.8, s), Color3.fromRGB(196, 150, 96), Enum.Material.Cardboard, { Name = "Parcel" })
		end
	end
end

function Lib.container(parent, cf, color)
	local p = Lib.part(parent, cf * CFrame.new(0, 4.25, 0), Vector3.new(8, 8.5, 20), color, Enum.Material.CorrodedMetal, { Name = "Container" })
	Lib.deco(parent, cf * CFrame.new(0, 4.25, -10.05), Vector3.new(7.4, 8, 0.1), color:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.DiamondPlate)
	return p
end

function Lib.cone(parent, cf)
	Lib.deco(parent, cf * CFrame.new(0, 0.1, 0), Vector3.new(1.4, 0.2, 1.4), Color3.fromRGB(255, 110, 20))
	Lib.deco(parent, cf * CFrame.new(0, 1.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(1.8, 0.9, 0.9), Color3.fromRGB(255, 110, 20), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
end

---------------------------------------------------------------- Bâtiments
-- Tour : cf au sol, LookVector = façade. style = { color, glass, trim, floorH, sign, signColor, top }
function Lib.tower(parent, cf, w, d, floors, style)
	style = style or {}
	local m = Lib.model(parent, style.name or "Tower")
	local fh = style.floorH or 10
	local h = floors * fh + 4
	local color = style.color or Color3.fromRGB(220, 215, 205)
	local glass = style.glass or Lib.C.glass
	Lib.part(m, cf * CFrame.new(0, h / 2, 0), Vector3.new(w, h, d), color, style.material or Enum.Material.Concrete, { Name = "Body" })
	-- Rez-de-chaussée vitré
	Lib.deco(m, cf * CFrame.new(0, 3.2, 0), Vector3.new(w + 0.3, 5.6, d + 0.3), glass:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.Glass, { Transparency = 0.15, Name = "Lobby" })
	-- Bandeaux de fenêtres (un par étage, visible sur les 4 faces)
	for f = 1, floors - 1 do
		local y = 4 + f * fh + fh * 0.1
		Lib.deco(m, cf * CFrame.new(0, y, 0), Vector3.new(w + 0.25, fh * 0.52, d + 0.25), glass, Enum.Material.Glass, { Transparency = 0.05, Name = "Windows", CastShadow = false })
	end
	-- Piliers verticaux sur la façade
	if style.pillars ~= false then
		for k = -1, 1, 2 do
			Lib.deco(m, cf * CFrame.new(k * (w / 2 - 0.4), h / 2, -d / 2 - 0.25), Vector3.new(1.2, h, 0.6), style.trim or color:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Concrete)
		end
	end
	-- Entrée
	Lib.deco(m, cf * CFrame.new(0, 6.4, -d / 2 - 3), Vector3.new(math.min(16, w * 0.6), 0.6, 6), style.trim or Lib.C.dark, Enum.Material.Metal, { Name = "Canopy" })
	Lib.deco(m, cf * CFrame.new(0, 3, -d / 2 - 0.2), Vector3.new(5, 6, 0.3), Color3.fromRGB(40, 50, 60), Enum.Material.Glass, { Name = "Door" })
	-- Toit
	Lib.deco(m, cf * CFrame.new(0, h + 0.6, 0), Vector3.new(w + 0.6, 1.2, d + 0.6), style.trim or color:Lerp(Color3.new(0, 0, 0), 0.2), Enum.Material.Concrete, { Name = "Parapet" })
	for k = 1, math.clamp(math.floor(w * d / 400), 1, 4) do
		Lib.ac(m, cf * CFrame.new(Lib.rng:NextNumber(-w / 2 + 3, w / 2 - 3), h + 1.2, Lib.rng:NextNumber(-d / 2 + 3, d / 2 - 3)))
	end
	if style.top == "antenna" then
		Lib.deco(m, cf * CFrame.new(0, h + 10, 0), Vector3.new(0.6, 18, 0.6), Lib.C.metal, Enum.Material.Metal)
		Lib.deco(m, cf * CFrame.new(0, h + 19.2, 0), Vector3.one * 1.2, Color3.fromRGB(255, 40, 40), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
	elseif style.top == "tank" then
		Lib.deco(m, cf * CFrame.new(w / 4, h + 4.5, d / 4), Vector3.new(6, 6, 6), Color3.fromRGB(140, 100, 70), Enum.Material.WoodPlanks, { Shape = Enum.PartType.Cylinder, CFrame = cf * CFrame.new(w / 4, h + 4.5, d / 4) * CFrame.Angles(0, 0, math.rad(90)) })
	elseif style.top == "crown" then
		Lib.deco(m, cf * CFrame.new(0, h + 4, 0), Vector3.new(w * 0.6, 6, d * 0.6), glass, Enum.Material.Glass)
		Lib.deco(m, cf * CFrame.new(0, h + 7.4, 0), Vector3.new(w * 0.62, 0.8, d * 0.62), style.trim or Lib.C.dark, Enum.Material.Metal)
	end
	if style.sign then
		Lib.sign(m, cf * CFrame.new(0, 9, -d / 2 - 0.35), Vector3.new(math.min(w - 4, 30), 3, 0.3), style.sign, style.signColor or Lib.C.dark, style.signText or Color3.new(1, 1, 1), { glow = true })
	end
	if style.roofSign then
		Lib.sign(m, cf * CFrame.new(0, h + 5, -d / 2 + 1), Vector3.new(math.min(w, 34), 7, 0.5), style.roofSign, style.signColor or Lib.C.dark, style.signText or Color3.new(1, 1, 1), { glow = true, double = true })
	end
	return m
end

-- Commerce de plain-pied : cf au sol, LookVector = vitrine.
function Lib.shop(parent, cf, w, d, name, color, awning, h)
	local m = Lib.model(parent, "Shop_" .. name)
	h = h or 12
	Lib.part(m, cf * CFrame.new(0, h / 2, 0), Vector3.new(w, h, d), color, Enum.Material.Plaster, { Name = "Body" })
	Lib.deco(m, cf * CFrame.new(0, 3.6, -d / 2 - 0.15), Vector3.new(w - 3, 6.4, 0.3), Color3.fromRGB(170, 210, 230), Enum.Material.Glass, { Transparency = 0.25, Name = "Storefront" })
	Lib.deco(m, cf * CFrame.new(w / 2 - 4, 3.2, -d / 2 - 0.3), Vector3.new(3.4, 6.2, 0.3), Color3.fromRGB(60, 45, 35), Enum.Material.Wood, { Name = "Door" })
	-- Auvent incliné
	Lib.deco(m, cf * CFrame.new(0, 7.6, -d / 2 - 2) * CFrame.Angles(math.rad(-18), 0, 0), Vector3.new(w - 1, 0.3, 4.2), awning, Enum.Material.Fabric, { Name = "Awning" })
	Lib.sign(m, cf * CFrame.new(0, 10, -d / 2 - 0.25), Vector3.new(w - 2, 2.6, 0.3), name, awning:Lerp(Color3.new(0, 0, 0), 0.35), Color3.new(1, 1, 1), { glow = true })
	Lib.deco(m, cf * CFrame.new(0, h + 0.4, 0), Vector3.new(w + 0.4, 0.8, d + 0.4), color:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.Concrete, { Name = "Cornice" })
	Lib.ac(m, cf * CFrame.new(-w / 4, h + 0.8, d / 4))
	return m
end

-- Maison : cf au sol (centre de la maison), LookVector = rue.
function Lib.house(parent, cf, style)
	style = style or {}
	local rng = Lib.rng
	local m = Lib.model(parent, style.name or "House")
	local w = style.w or rng:NextNumber(18, 24)
	local d = style.d or rng:NextNumber(16, 20)
	local floors = style.floors or rng:NextInteger(1, 2)
	local wallH = floors * 9
	local wall = style.color or Color3.fromHSV(rng:NextNumber(0, 1), rng:NextNumber(0.15, 0.4), rng:NextNumber(0.8, 0.97))
	local roofC = style.roof or ({ Color3.fromRGB(160, 70, 55), Color3.fromRGB(70, 75, 90), Color3.fromRGB(110, 80, 60), Color3.fromRGB(60, 100, 90) })[rng:NextInteger(1, 4)]
	Lib.part(m, cf * CFrame.new(0, 0.5, 0), Vector3.new(w + 1, 1, d + 1), Lib.C.concrete, Enum.Material.Concrete, { Name = "Foundation" })
	Lib.part(m, cf * CFrame.new(0, 1 + wallH / 2, 0), Vector3.new(w, wallH, d), wall, style.material or Enum.Material.Plaster, { Name = "Walls" })
	local top = 1 + wallH
	if style.flat then
		Lib.deco(m, cf * CFrame.new(0, top + 0.5, 0), Vector3.new(w + 1, 1, d + 1), roofC, Enum.Material.Concrete, { Name = "Roof" })
	else
		local rh = 6
		-- WedgePart : arête haute côté +Z local. Pan avant non tourné, pan arrière tourné de 180°.
		Lib.part(m, cf * CFrame.new(0, top + rh / 2, -d / 4 - 0.25), Vector3.new(w + 1.6, rh, d / 2 + 0.5), roofC, Enum.Material.Slate, { Class = "WedgePart", Name = "Roof" })
		Lib.part(m, cf * CFrame.new(0, top + rh / 2, d / 4 + 0.25) * CFrame.Angles(0, math.pi, 0), Vector3.new(w + 1.6, rh, d / 2 + 0.5), roofC, Enum.Material.Slate, { Class = "WedgePart", Name = "Roof" })
		if rng:NextNumber() < 0.6 then
			Lib.deco(m, cf * CFrame.new(w / 3, top + rh, d / 6), Vector3.new(2, 5, 2), Color3.fromRGB(140, 80, 60), Enum.Material.Brick, { Name = "Chimney" })
		end
	end
	-- Porte, fenêtres
	Lib.deco(m, cf * CFrame.new(-w / 5, 4.5, -d / 2 - 0.15), Vector3.new(3.4, 7, 0.3), ({ Color3.fromRGB(150, 40, 40), Color3.fromRGB(40, 70, 120), Color3.fromRGB(60, 40, 30), Color3.fromRGB(40, 110, 70) })[rng:NextInteger(1, 4)], Enum.Material.Wood, { Name = "Door" })
	Lib.deco(m, cf * CFrame.new(-w / 5, 8.4, -d / 2 - 1), Vector3.new(5, 0.4, 2.2), roofC, Enum.Material.Wood, { Name = "DoorCanopy" })
	for f = 0, floors - 1 do
		for _, x in { w / 5 + 1, (f == 1 and -w / 5 or nil) } do
			if x then
				Lib.deco(m, cf * CFrame.new(x, 5 + f * 9, -d / 2 - 0.12), Vector3.new(4.4, 4, 0.25), Color3.fromRGB(150, 200, 230), Enum.Material.Glass, { Transparency = 0.1, Name = "Window" })
				Lib.deco(m, cf * CFrame.new(x, 2.85 + f * 9, -d / 2 - 0.35), Vector3.new(5, 0.3, 0.7), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { Name = "Sill" })
			end
		end
		Lib.deco(m, cf * CFrame.new(0, 5 + f * 9, 0), Vector3.new(w + 0.2, 4, 4), Color3.fromRGB(150, 200, 230), Enum.Material.Glass, { Transparency = 0.1, Name = "SideWindows" })
	end
	-- Garage
	if style.garage ~= false then
		local gx = (w / 2 + 6) * (style.garageSide or 1)
		Lib.part(m, cf * CFrame.new(gx, 4.5, 1), Vector3.new(11, 8, d - 2), wall:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.Plaster, { Name = "Garage" })
		Lib.deco(m, cf * CFrame.new(gx, 3.8, -d / 2 + 1.9), Vector3.new(8.5, 6.4, 0.3), Color3.fromRGB(235, 235, 235), Enum.Material.DiamondPlate, { Name = "GarageDoor" })
		Lib.deco(m, cf * CFrame.new(gx, 8.7, 1), Vector3.new(11.6, 0.6, d - 1.4), roofC, Enum.Material.Slate, { Name = "GarageRoof" })
	end
	return m, w, d
end

---------------------------------------------------------------- Géométrie utile
-- Pièce entre deux points (poutre, câble, rampe). Le dessus passe par a et b si top = true.
function Lib.beam(parent, a, b, w, h, color, material, props, top)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	if top then
		cf = cf * CFrame.new(0, -h / 2, 0)
	end
	return Lib.part(parent, cf, Vector3.new(w, h, len), color, material, props)
end

-- Dalle rectangulaire alignée sur les axes, dessus à ytop.
function Lib.slab(parent, x1, x2, z1, z2, ytop, thick, color, material, props)
	thick = thick or 1
	return Lib.part(parent, CFrame.new((x1 + x2) / 2, ytop - thick / 2, (z1 + z2) / 2), Vector3.new(math.abs(x2 - x1), thick, math.abs(z2 - z1)), color, material, props)
end

-- Cylindre posé (disque) : centre au sol, dessus à ytop.
function Lib.disc(parent, pos, radius, ytop, thick, color, material, props)
	props = props or {}
	props.Shape = Enum.PartType.Cylinder
	return Lib.part(parent, CFrame.new(pos.X, ytop - thick / 2, pos.Z) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(thick, radius * 2, radius * 2), color, material, props)
end

function Lib.pick(t)
	return t[Lib.rng:NextInteger(1, #t)]
end

-- Le terrain lisse rend une surface 2 studs au-dessus d'un voxel plein. settle() met la couche
-- de voxels [-4, 0] à 50 % d'occupation partout où elle est pleine sous de l'air : le sol plat
-- se retrouve exactement à y = 0, sous les routes (0.2) et les trottoirs.
function Lib.settle(x1, z1, x2, z2)
	local T = workspace.Terrain
	for tx = x1, x2 - 1, 400 do
		for tz = z1, z2 - 1, 400 do
			local r = Region3.new(Vector3.new(tx, -4, tz), Vector3.new(math.min(tx + 400, x2), 4, math.min(tz + 400, z2))):ExpandToGrid(4)
			local mats, occ = T:ReadVoxels(r, 4)
			local sx, sz = occ.Size.X, occ.Size.Z
			for a = 1, sx do
				local ca, cb = occ[a][1], occ[a][2]
				for c = 1, sz do
					if ca[c] > 0.99 and cb[c] < 0.01 then
						ca[c] = 0.5
					end
				end
			end
			T:WriteVoxels(r, 4, mats, occ)
			task.wait()
		end
	end
end

-- Change la matière du terrain de surface sans changer sa forme.
function Lib.paint(x1, z1, x2, z2, from, to)
	workspace.Terrain:ReplaceMaterial(Region3.new(Vector3.new(x1, -8, z1), Vector3.new(x2, 4, z2)):ExpandToGrid(4), 4, from, to)
end

return Lib
