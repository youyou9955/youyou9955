--!nolint
-- Wrong Way Delivery, map v2 : bibliothèque de construction (outil d'édition, pas du gameplay).
-- Repère : X ouest(-) -> est(+), Z nord(-) -> sud(+). Sol de la ville à y = 0.
local Lib = {}

local V = Vector3.new
local rgb = Color3.fromRGB
local M = Enum.Material
Lib.V, Lib.rgb, Lib.M = V, rgb, M

Lib.ROAD = 0.2 -- dessus de la chaussée
Lib.WALK = 0.8 -- dessus des trottoirs
Lib.rng = Random.new(20261118)

-- Palette cartoon (couleurs franches, matières lisses)
Lib.C = {
	asphalt = rgb(62, 64, 72),
	asphaltDark = rgb(52, 54, 62),
	white = rgb(245, 245, 240),
	yellow = rgb(255, 200, 40),
	walk = rgb(206, 202, 194),
	curb = rgb(176, 172, 166),
	grass = rgb(104, 178, 72),
	concrete = rgb(188, 186, 180),
	metal = rgb(120, 126, 136),
	dark = rgb(44, 46, 54),
	glass = rgb(126, 196, 236),
	glassDark = rgb(70, 120, 170),
	wood = rgb(140, 96, 60),
	brandRed = rgb(222, 46, 46),
	brandOrange = rgb(255, 140, 30),
	brandDark = rgb(30, 32, 40),
	trim = rgb(250, 248, 240),
}

---------------------------------------------------------------- Bases
local budget = 0
function Lib.yield(n)
	budget += (n or 1)
	if budget >= 150 then
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
	p.Material = material or M.SmoothPlastic
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

-- Décor pur : pas de collision ni de requêtes
function Lib.deco(parent, cf, size, color, material, props)
	props = props or {}
	props.CanCollide = false
	props.CanTouch = false
	props.CanQuery = false
	return Lib.part(parent, cf, size, color, material, props)
end

-- Détail fin : décor sans ombre
function Lib.fine(parent, cf, size, color, material, props)
	props = props or {}
	props.CastShadow = false
	return Lib.deco(parent, cf, size, color, material, props)
end

function Lib.mark(parent, cf, size, color)
	return Lib.fine(parent, cf, size, color or Lib.C.white, M.SmoothPlastic)
end

function Lib.wedge(parent, cf, size, color, material, props)
	props = props or {}
	props.Class = "WedgePart"
	return Lib.part(parent, cf, size, color, material, props)
end

-- Cylindre vertical (axe Y) : cf = centre
function Lib.cyl(parent, cf, h, d, color, material, props)
	props = props or {}
	props.Shape = Enum.PartType.Cylinder
	return Lib.part(parent, cf * CFrame.Angles(0, 0, math.rad(90)), V(h, d, d), color, material, props)
end

function Lib.cylDeco(parent, cf, h, d, color, material, props)
	props = props or {}
	props.CanCollide, props.CanTouch, props.CanQuery = false, false, false
	return Lib.cyl(parent, cf, h, d, color, material, props)
end

function Lib.ball(parent, pos, d, color, material, props)
	props = props or {}
	props.Shape = Enum.PartType.Ball
	props.CanCollide, props.CanTouch, props.CanQuery = false, false, false
	return Lib.part(parent, CFrame.new(pos), V(d, d, d), color, material, props)
end

-- Poutre de a à b (largeur w, hauteur h)
function Lib.beam(parent, a, b, w, h, color, material, props)
	local len = (b - a).Magnitude
	return Lib.part(parent, CFrame.lookAt((a + b) / 2, b), V(w, h, len), color, material, props)
end

-- Bâtiment orienté : pos au sol, façade vers dir (unitaire, horizontal)
function Lib.facing(pos, dir)
	return CFrame.lookAt(pos, pos + V(dir.X, 0, dir.Z))
end

function Lib.pick(t, rng)
	return t[(rng or Lib.rng):NextInteger(1, #t)]
end

---------------------------------------------------------------- Texte et panneaux
function Lib.label(part, face, text, fg, bg, font, glow, ppS)
	local g = Instance.new("SurfaceGui")
	g.Face = face or Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = ppS or 20
	g.LightInfluence = glow and 0 or 1
	pcall(function()
		g.MaxDistance = 600
	end)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = bg and 0 or 1
	t.BackgroundColor3 = bg or Color3.new(0, 0, 0)
	t.TextColor3 = fg or Color3.new(1, 1, 1)
	t.Font = font or Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = text
	t.Parent = g
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.PaddingTop = UDim.new(0.08, 0)
	pad.PaddingBottom = UDim.new(0.08, 0)
	pad.Parent = t
	local st = Instance.new("UIStroke")
	st.Thickness = 2
	st.Color = Color3.new(0, 0, 0)
	st.Transparency = 0.6
	st.Parent = t
	g.Parent = part
	return g
end

-- Panneau texte : le texte est sur la face avant (LookVector du cf)
function Lib.sign(parent, cf, size, text, bg, fg, opts)
	opts = opts or {}
	local p = Lib.deco(parent, cf, size, bg, opts.material or M.SmoothPlastic, { Name = opts.name or "Sign" })
	Lib.label(p, Enum.NormalId.Front, text, fg, nil, opts.font, opts.glow)
	if opts.double then
		Lib.label(p, Enum.NormalId.Back, text, fg, nil, opts.font, opts.glow)
	end
	return p
end

-- Panneau directionnel sur poteau (cf = pied, panneau tourné vers LookVector)
function Lib.postSign(parent, cf, text, bg, fg, w, h, poleH)
	local m = Lib.model(parent, "DirectionSign")
	w, h, poleH = w or 8, h or 2.6, poleH or 8
	for _, x in { -w / 2 + 0.8, w / 2 - 0.8 } do
		Lib.part(m, cf * CFrame.new(x, poleH / 2, 0), V(0.35, poleH, 0.35), Lib.C.metal, M.Metal)
	end
	local s = Lib.sign(m, cf * CFrame.new(0, poleH + h / 2 - 1, -0.25), V(w, h, 0.25), text, bg, fg)
	Lib.fine(m, s.CFrame * CFrame.new(0, 0, 0.18), V(w + 0.3, h + 0.3, 0.1), Lib.C.white, M.SmoothPlastic)
	return m
end

---------------------------------------------------------------- Modèles Meshy (props)
local city = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("City")
local assets = game:GetService("ReplicatedStorage"):WaitForChild("Assets")

-- Pose un MeshPart de Assets.City : cfGround = pied, h = hauteur (taille uniforme)
function Lib.asset(name, parent, cfGround, h, collide, newName)
	local src = city:FindFirstChild(name)
	if not src then
		return nil
	end
	local m = src:Clone()
	for _, c in m:GetChildren() do
		if c:IsA("SurfaceAppearance") then
			c:Destroy()
		end
	end
	local s = src.Size * (h / src.Size.Y)
	m.Size = s
	m.CFrame = cfGround * CFrame.new(0, s.Y / 2, 0)
	m.Anchored = true
	m.CanCollide = collide and true or false
	m.CanQuery = collide and true or false
	m.CanTouch = false
	m.CastShadow = h > 2
	pcall(function()
		m.CollisionFidelity = Enum.CollisionFidelity.Box
		m.RenderFidelity = Enum.RenderFidelity.Automatic
	end)
	m.Name = newName or name
	m.Parent = parent
	Lib.yield(3)
	return m
end

-- Véhicule décoratif (Assets.Car / Truck / Van), ancré, cfGround = au sol, avant vers LookVector
function Lib.vehicle(kind, parent, cfGround, color)
	local src = assets:FindFirstChild(kind)
	if not src then
		return nil
	end
	local m = src:Clone()
	m.Name = "Parked" .. kind
	local cf, size = m:GetBoundingBox()
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			if d.Transparency < 1 then
				d.CanCollide = false
			end
		elseif d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Constraint") or d:IsA("Attachment") or d:IsA("Seat") then
			d:Destroy()
		end
	end
	local pivotOffset = m:GetPivot():ToObjectSpace(cf)
	m:PivotTo(cfGround * CFrame.new(0, size.Y / 2, 0) * pivotOffset:Inverse())
	-- collision simple : une boîte invisible
	local box = Lib.part(m, cfGround * CFrame.new(0, size.Y / 2, 0), V(math.min(size.X, size.Z), size.Y, math.max(size.X, size.Z)), Color3.new(), M.SmoothPlastic, { Transparency = 1, Name = "Collision", CastShadow = false, CanTouch = false })
	m.Parent = parent
	Lib.yield(4)
	return m
end

---------------------------------------------------------------- Mobilier urbain (pièces, style cartoon)
function Lib.lamp(parent, cf, light)
	local m = Lib.model(parent, "StreetLamp")
	local c = rgb(48, 56, 72)
	Lib.part(m, cf * CFrame.new(0, 0.4, 0), V(1.2, 0.8, 1.2), c, M.Metal)
	Lib.part(m, cf * CFrame.new(0, 7, 0), V(0.55, 13, 0.55), c, M.Metal)
	Lib.fine(m, cf * CFrame.new(0, 13.4, -1.6), V(0.4, 0.4, 3.4), c, M.Metal)
	Lib.fine(m, cf * CFrame.new(0, 13.2, -3.4), V(1.6, 0.5, 1.6), c, M.Metal)
	local head = Lib.fine(m, cf * CFrame.new(0, 12.9, -3.4), V(1.3, 0.15, 1.3), rgb(255, 240, 200), M.Neon)
	if light then
		local l = Instance.new("SpotLight")
		l.Face = Enum.NormalId.Bottom
		l.Range, l.Angle, l.Brightness = 24, 110, 1.4
		l.Color = rgb(255, 226, 176)
		l.Shadows = false
		l.Parent = head
	end
	return m
end

function Lib.bench(parent, cf)
	return Lib.asset("Bench", parent, cf, 2.8, true, "Bench")
end

function Lib.trash(parent, cf)
	return Lib.asset("TrashCan", parent, cf, 3.2, true, "TrashCan")
end

function Lib.hydrant(parent, cf)
	return Lib.asset("Hydrant", parent, cf, 2.4, true, "Hydrant")
end

function Lib.mailbox(parent, cf)
	return Lib.asset("Mailbox", parent, cf, 4, true, "Mailbox")
end

function Lib.planter(parent, cf)
	return Lib.asset("Planter", parent, cf, 3, true, "Planter")
end

function Lib.busStop(parent, cf)
	return Lib.asset("BusStop", parent, cf, 8, true, "BusStop")
end

function Lib.bush(parent, pos, h)
	return Lib.asset("BushL", parent, CFrame.new(pos) * CFrame.Angles(0, Lib.rng:NextNumber(0, 6.28), 0), h or Lib.rng:NextNumber(2.6, 4), false, "Bush")
end

function Lib.tree(parent, pos, kind, h)
	kind = kind or (Lib.rng:NextNumber() < 0.78 and "round" or "pine")
	local name = kind == "pine" and "PineL" or (kind == "palm" and "TreePalm" or "TreeL")
	h = h or (kind == "pine" and Lib.rng:NextNumber(18, 28) or Lib.rng:NextNumber(14, 22))
	local t = Lib.asset(name, parent, CFrame.new(pos) * CFrame.Angles(0, Lib.rng:NextNumber(0, 6.28), 0), h, false, "Tree")
	if t then
		-- tronc : seule partie avec collision
		local trunk = Lib.part(parent, CFrame.new(pos + V(0, 3, 0)), V(1.4, 6, 1.4), Lib.C.wood, M.Wood, { Transparency = 1, Name = "TreeTrunk", CastShadow = false, CanTouch = false })
		trunk.Parent = t
	end
	return t
end

function Lib.flowers(parent, cf, w, d)
	local m = Lib.model(parent, "FlowerBed")
	Lib.deco(m, cf * CFrame.new(0, 0.45, 0), V(w, 0.9, d), rgb(170, 120, 84), M.Brick)
	Lib.fine(m, cf * CFrame.new(0, 0.95, 0), V(w - 0.6, 0.15, d - 0.6), rgb(96, 64, 44), M.Ground)
	local cols = { rgb(255, 92, 140), rgb(255, 214, 60), rgb(180, 100, 240), rgb(255, 150, 60), rgb(250, 250, 250) }
	for k = 1, math.clamp(math.floor(w * d / 6), 2, 14) do
		local x = Lib.rng:NextNumber(-w / 2 + 0.8, w / 2 - 0.8)
		local z = Lib.rng:NextNumber(-d / 2 + 0.8, d / 2 - 0.8)
		Lib.ball(m, (cf * CFrame.new(x, 1.35, z)).Position, 0.9, cols[Lib.rng:NextInteger(1, #cols)], M.SmoothPlastic, { CastShadow = false })
	end
	return m
end

-- Clôture de a à b (au sol). style : "picket" (blanche), "metal", "chain"
function Lib.fence(parent, a, b, style, h)
	local m = Lib.model(parent, "Fence")
	local len = (b - a).Magnitude
	if len < 0.5 then
		return m
	end
	local cf = CFrame.lookAt((a + b) / 2, b)
	if style == "picket" then
		h = h or 3
		local col = Lib.C.white
		Lib.part(m, cf * CFrame.new(0, h * 0.35, 0), V(0.25, 0.3, len), col, M.SmoothPlastic)
		Lib.fine(m, cf * CFrame.new(0, h * 0.75, 0), V(0.25, 0.3, len), col, M.SmoothPlastic)
		local n = math.floor(len / 1.2)
		for k = 0, n do
			Lib.fine(m, cf * CFrame.new(0, h / 2, -len / 2 + k * len / math.max(n, 1)), V(0.2, h, 0.5), col, M.SmoothPlastic)
		end
		-- collision : un seul pan invisible
		Lib.part(m, cf * CFrame.new(0, h / 2, 0), V(0.4, h, len), col, M.SmoothPlastic, { Transparency = 1, CastShadow = false, CanTouch = false, Name = "Collision" })
	else
		h = h or 7
		local col = style == "chain" and rgb(150, 156, 164) or rgb(60, 66, 76)
		local n = math.max(1, math.floor(len / 8))
		for k = 0, n do
			Lib.part(m, cf * CFrame.new(0, h / 2, -len / 2 + k * len / n), V(0.4, h, 0.4), col, M.Metal)
		end
		Lib.fine(m, cf * CFrame.new(0, h - 0.2, 0), V(0.25, 0.25, len), col, M.Metal)
		Lib.fine(m, cf * CFrame.new(0, 0.6, 0), V(0.25, 0.25, len), col, M.Metal)
		local mesh = Lib.part(m, cf * CFrame.new(0, h / 2, 0), V(0.1, h - 0.6, len), col, style == "chain" and M.DiamondPlate or M.Metal, { Transparency = style == "chain" and 0.55 or 0.35, CastShadow = false, CanTouch = false, Name = "Mesh" })
		if style ~= "chain" then
			local n2 = math.floor(len / 0.9)
			for k = 1, n2 - 1 do
				Lib.fine(m, cf * CFrame.new(0, h / 2, -len / 2 + k * len / n2), V(0.12, h - 0.8, 0.12), col, M.Metal)
			end
			mesh.Transparency = 1
		end
	end
	return m
end

function Lib.hedge(parent, a, b, h, w)
	h, w = h or 3, w or 2.2
	local len = (b - a).Magnitude
	return Lib.part(parent, CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, h / 2, 0), V(w, h, len), rgb(70, 150, 60), M.Grass, { Name = "Hedge", CanTouch = false })
end

function Lib.pallet(parent, cf, boxes)
	local m = Lib.model(parent, "Pallet")
	Lib.part(m, cf * CFrame.new(0, 0.3, 0), V(4, 0.6, 4), rgb(176, 132, 84), M.WoodPlanks)
	if boxes then
		local kraft = rgb(196, 150, 96)
		for k = 0, boxes - 1 do
			local x, z, y = (k % 2) * 2 - 1, (math.floor(k / 2) % 2) * 2 - 1, math.floor(k / 4)
			local b = Lib.part(m, cf * CFrame.new(x * 0.95, 1.5 + y * 1.8, z * 0.95) * CFrame.Angles(0, math.rad(Lib.rng:NextNumber(-6, 6)), 0), V(1.8, 1.8, 1.8), kraft, M.Cardboard)
			Lib.fine(m, b.CFrame * CFrame.new(0, 0.91, 0), V(0.4, 0.02, 1.8), rgb(220, 200, 150), M.SmoothPlastic)
		end
	end
	return m
end

function Lib.cone(parent, cf)
	local m = Lib.model(parent, "Cone")
	Lib.part(m, cf * CFrame.new(0, 0.1, 0), V(1.6, 0.2, 1.6), rgb(255, 110, 20), M.SmoothPlastic)
	Lib.cylDeco(m, cf * CFrame.new(0, 1.1, 0), 1.8, 0.9, rgb(255, 110, 20), M.SmoothPlastic)
	Lib.cylDeco(m, cf * CFrame.new(0, 1.2, 0), 0.35, 0.95, Lib.C.white, M.SmoothPlastic)
	return m
end

function Lib.container(parent, cf, color)
	local m = Lib.model(parent, "Container")
	local b = Lib.part(m, cf * CFrame.new(0, 4.25, 0), V(8, 8.5, 20), color, M.CorrodedMetal)
	for k = -4, 4 do
		Lib.fine(m, cf * CFrame.new(4.05, 4.25, k * 2.1), V(0.15, 8, 0.6), color:Lerp(Color3.new(0, 0, 0), 0.18), M.Metal)
		Lib.fine(m, cf * CFrame.new(-4.05, 4.25, k * 2.1), V(0.15, 8, 0.6), color:Lerp(Color3.new(0, 0, 0), 0.18), M.Metal)
	end
	Lib.fine(m, cf * CFrame.new(0, 4.25, 10.05), V(7.4, 8, 0.15), color:Lerp(Color3.new(0, 0, 0), 0.12), M.Metal)
	return m
end


---------------------------------------------------------------- Parkings et entrées
-- Parking : cf au centre (au sol), w x d ; places de 10 x 18 de part et d'autre d'allées
function Lib.parking(parent, cf, w, d, fill, kinds)
	local m = Lib.model(parent, "Parking")
	Lib.part(m, cf * CFrame.new(0, 0.05, 0), V(w, 0.5, d), Lib.C.asphaltDark, M.Asphalt, { Name = "Lot" })
	local rows = math.floor(d / 60)
	local nSpots = math.floor((w - 4) / 10)
	local zs = {}
	for r = 0, math.max(rows, 1) - 1 do
		local zc = -d / 2 + 30 + r * 60
		if rows == 0 then
			zc = 0
		end
		table.insert(zs, { zc - 12 - 9, 1 })
		table.insert(zs, { zc + 12 + 9, -1 })
	end
	for _, row in zs do
		local zc, face = row[1], row[2]
		if math.abs(zc) + 9 <= d / 2 then
			for k = 0, nSpots do
				local x = -w / 2 + 2 + k * 10 + (w - 4 - nSpots * 10) / 2
				Lib.mark(m, cf * CFrame.new(x, 0.32, zc), V(0.35, 0.05, 17), Lib.C.white)
				if k < nSpots and Lib.rng:NextNumber() < (fill or 0.5) then
					local kind = kinds and kinds[Lib.rng:NextInteger(1, #kinds)] or "Car"
					Lib.vehicle(kind, Lib.path("DecorativeVehicles"), cf * CFrame.new(x + 5, 0.3, zc) * CFrame.Angles(0, face > 0 and 0 or math.pi, 0))
				end
			end
		end
	end
	return m
end

-- Entrée charretière : rampe à travers le trottoir. cf au bord de la chaussée, LookVector vers le terrain
function Lib.driveway(parent, cf, width, depth)
	depth = depth or 12
	local m = Lib.model(parent, "Driveway")
	Lib.part(m, cf * CFrame.new(0, 0.42, -depth / 2), V(width, 0.9, depth), rgb(196, 192, 184), M.Concrete, { Name = "Slab" })
	Lib.wedge(m, cf * CFrame.new(0, 0.52, 0.9) * CFrame.Angles(0, math.pi, 0), V(width, 0.7, 1.8), rgb(196, 192, 184), M.Concrete, { Name = "Ramp" })
	return m
end

---------------------------------------------------------------- Terrain
function Lib.fill(cf, size, material)
	workspace.Terrain:FillBlock(cf, size, material)
	Lib.yield(4)
end

return Lib
