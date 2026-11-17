--!nolint
-- 13 : maisons visitables. Remplace chaque maison (maisons, maisons de ville, maisons de la colline)
-- par une vraie maison en pièces : murs avec ouvertures, porte d'entrée qui s'ouvre (tag HouseDoor,
-- voir src/server/HouseDoors), fenêtres vitrées, pièces séparées, escalier et étage pour les maisons
-- à deux niveaux, plafonnier, meubles Meshy (ReplicatedStorage.Assets.City). Chaque maison tire son
-- propre style : façade (brique, bardage bois, enduit, pierre, moderne), toit (deux pans, pignon sur
-- rue, plat, monopente), couleurs, volets, porche, cheminée, jardinières, garage.
-- Repère local d'une maison : origine au sol au centre, façade vers -Z (LookVector), X vers la droite.
local Lib = require(script.Parent.Lib)
local CS = game:GetService("CollectionService")
local city = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("City")
local M = Enum.Material
local V = Vector3.new
local rgb = Color3.fromRGB

local T = 0.8 -- épaisseur des murs extérieurs
local H = 10 -- hauteur d'un étage
local SLAB = 0.6
local Y1 = 1 -- dessus du plancher du rez-de-chaussée
local DOOR_W, DOOR_H = 4.4, 8

local STYLES = {
	{ name = "brique rouge", mat = M.Brick, colors = { rgb(160, 78, 58), rgb(140, 70, 55), rgb(175, 95, 70) }, trim = { rgb(240, 238, 230) }, roofs = { "gableX", "gableZ" } },
	{ name = "brique claire", mat = M.Brick, colors = { rgb(205, 180, 140), rgb(190, 160, 120), rgb(215, 200, 170) }, trim = { rgb(250, 250, 245), rgb(70, 60, 50) }, roofs = { "gableX", "gableZ", "flat" } },
	{ name = "bardage bois", mat = M.WoodPlanks, colors = { rgb(150, 185, 205), rgb(170, 195, 160), rgb(240, 236, 220), rgb(235, 210, 140), rgb(200, 120, 110), rgb(120, 130, 140) }, trim = { rgb(250, 250, 250) }, roofs = { "gableX", "gableZ" } },
	{ name = "enduit", mat = M.Plaster, colors = { rgb(245, 235, 210), rgb(240, 225, 200), rgb(230, 170, 130), rgb(240, 200, 190), rgb(250, 250, 245) }, trim = { rgb(250, 250, 250), rgb(90, 70, 55) }, roofs = { "gableX", "gableZ", "shed" } },
	{ name = "pierre", mat = M.Limestone, colors = { rgb(220, 210, 190), rgb(200, 190, 170) }, trim = { rgb(80, 70, 60), rgb(240, 240, 235) }, roofs = { "gableX", "gableZ" } },
	{ name = "moderne", mat = M.SmoothPlastic, colors = { rgb(245, 245, 245), rgb(60, 62, 68), rgb(215, 215, 210) }, trim = { rgb(40, 40, 45) }, roofs = { "flat", "shed" }, modern = true },
}
local ROOF_COLORS = { rgb(150, 70, 55), rgb(70, 75, 90), rgb(105, 80, 62), rgb(60, 95, 85), rgb(45, 45, 50), rgb(130, 130, 135) }
local ROOF_MATS = { M.Slate, M.Slate, M.WoodPlanks, M.Concrete }
local DOOR_COLORS = { rgb(150, 40, 40), rgb(40, 70, 120), rgb(60, 40, 30), rgb(40, 110, 70), rgb(230, 190, 60), rgb(30, 30, 32), rgb(240, 240, 240) }
local SHUTTERS = { rgb(40, 80, 60), rgb(40, 60, 110), rgb(140, 40, 40), rgb(60, 60, 65), rgb(200, 190, 160) }
local WALLS_IN = { rgb(245, 240, 230), rgb(230, 225, 215), rgb(215, 230, 235), rgb(235, 225, 205), rgb(225, 235, 220), rgb(240, 225, 225) }
local FLOORS = { rgb(170, 130, 90), rgb(120, 85, 60), rgb(200, 170, 130), rgb(150, 150, 150) }
local GLASS = rgb(170, 205, 225)

local function pick(rng, t)
	return t[rng:NextInteger(1, #t)]
end

---------------------------------------------------------------- Meubles
local function furn(parent, cf, name, lx, ly, lz, face, target, mode, collide)
	local src = city:FindFirstChild(name)
	if not src then
		return
	end
	local b = src.Size
	local sc
	if mode == "stretch" then
		sc = V(target.X / b.X, target.Y / b.Y, target.Z / b.Z)
	elseif mode == "height" then
		sc = Vector3.one * (target.Y / b.Y)
	else
		sc = Vector3.one * math.min(target.X / b.X, target.Y / b.Y, target.Z / b.Z)
	end
	local sz = b * sc
	local m = src:Clone()
	m.Size = sz
	m.CFrame = cf * CFrame.new(lx, ly + sz.Y / 2, lz) * CFrame.lookAt(Vector3.zero, face)
	m.Anchored = true
	m.CanCollide = collide ~= false
	m.CanQuery = collide ~= false
	m.CanTouch = false
	pcall(function()
		m.CollisionFidelity = Enum.CollisionFidelity.Box
	end)
	m.Name = "Furniture_" .. name
	m.Parent = parent
	Lib.yield(1)
end
local FRONT, BACK, LEFT, RIGHT = V(0, 0, -1), V(0, 0, 1), V(-1, 0, 0), V(1, 0, 0)

---------------------------------------------------------------- Maison
local function build(parent, cf, w, d, floors, rng, opts)
	opts = opts or {}
	local st = opts.style or pick(rng, STYLES)
	local wallC = pick(rng, st.colors)
	local trimC = pick(rng, st.trim)
	local roofKind = opts.roof or pick(rng, st.roofs)
	local roofC = st.modern and rgb(70, 72, 78) or pick(rng, ROOF_COLORS)
	local roofM = st.modern and M.Concrete or pick(rng, ROOF_MATS)
	local inC = pick(rng, WALLS_IN)
	local floorC = pick(rng, FLOORS)
	local doorC = pick(rng, DOOR_COLORS)
	local shutters = not st.modern and rng:NextNumber() < 0.45 and pick(rng, SHUTTERS)
	local boxes = rng:NextNumber() < 0.35
	local porch = opts.porch ~= false and rng:NextNumber() < 0.4
	local m = Lib.model(parent, "HouseBody")
	m:SetAttribute("Style", st.name)
	m:SetAttribute("Roof", roofKind)
	m:SetAttribute("Floors", floors)

	local function P(lcf, size, color, mat, props)
		return Lib.part(m, cf * lcf, size, color, mat, props)
	end
	local function D(lcf, size, color, mat, props)
		return Lib.deco(m, cf * lcf, size, color, mat, props)
	end

	local xi1, xi2, zi1, zi2 = -w / 2 + T, w / 2 - T, -d / 2 + T, d / 2 - T
	local doorX = opts.doorX or -w / 5
	local yTop = Y1 + floors * H + (floors - 1) * SLAB
	local function yF(i)
		return Y1 + (i - 1) * (H + SLAB)
	end
	local two = floors >= 2
	local stairX1 = xi2 - 3.4
	local zs = zi1 + 1.2 -- départ de l'escalier
	local NST, RUN = 12, 1
	local holeZ1, holeZ2 = zs + 3.5, zs + NST * RUN

	-- Socle et planchers
	P(CFrame.new(0, Y1 / 2, 0), V(w + 0.6, Y1, d + 0.6), rgb(165, 160, 150), M.Concrete, { Name = "Foundation" })
	D(CFrame.new(0, Y1 + 0.05, 0), V(w - 2 * T, 0.1, d - 2 * T), floorC, floorC == FLOORS[4] and M.Marble or M.WoodPlanks, { Name = "Floor" })

	-- Murs extérieurs avec ouvertures. ops = { {c, w, bas, haut, kind} } ; axe X (façade/arrière) ou Z (côtés)
	local function wall(axis, fixed, a1, a2, y0, y1, ops, color, mat, thick, outward)
		table.sort(ops, function(p, q)
			return p.c < q.c
		end)
		local function seg(a, b, ya, yb)
			if b - a < 0.05 or yb - ya < 0.05 then
				return
			end
			if axis == "X" then
				P(CFrame.new((a + b) / 2, (ya + yb) / 2, fixed), V(b - a, yb - ya, thick), color, mat, { Name = "Wall" })
			else
				P(CFrame.new(fixed, (ya + yb) / 2, (a + b) / 2), V(thick, yb - ya, b - a), color, mat, { Name = "Wall" })
			end
		end
		local cur = a1
		for _, o in ops do
			local a, b = o.c - o.w / 2, o.c + o.w / 2
			seg(cur, a, y0, y1)
			seg(a, b, y0, o.b)
			seg(a, b, o.t, y1)
			cur = b
			if o.kind == "window" and outward then
				local mid, h = (o.b + o.t) / 2, o.t - o.b
				local function at(u, y, off)
					if axis == "X" then
						return CFrame.new(u, y, fixed + outward * off)
					else
						return CFrame.new(fixed + outward * off, y, u) * CFrame.Angles(0, math.pi / 2, 0)
					end
				end
				P(at(o.c, mid, 0), V(o.w, h, 0.2), GLASS, M.Glass, { Name = "Window", Transparency = 0.55, CastShadow = false })
				D(at(o.c, o.t + 0.2, thick / 2 + 0.12), V(o.w + 0.6, 0.4, 0.25), trimC, M.SmoothPlastic, { Name = "Lintel" })
				D(at(o.c, o.b - 0.15, thick / 2 + 0.25), V(o.w + 0.8, 0.3, 0.6), trimC, M.SmoothPlastic, { Name = "Sill" })
				D(at(o.c, mid, 0.05), V(0.2, h, 0.15), trimC, M.SmoothPlastic, { Name = "Mullion" })
				if shutters then
					for _, s in { -1, 1 } do
						D(at(o.c + s * (o.w / 2 + 0.7), mid, thick / 2 + 0.1), V(1.2, h + 0.2, 0.15), shutters, M.WoodPlanks, { Name = "Shutter" })
					end
				end
				if boxes and o.b < 6 then
					D(at(o.c, o.b - 0.7, thick / 2 + 0.5), V(o.w, 0.7, 0.7), rgb(110, 75, 50), M.Wood, { Name = "WindowBox" })
					D(at(o.c, o.b - 0.25, thick / 2 + 0.5), V(o.w - 0.2, 0.4, 0.5), pick(rng, { rgb(230, 70, 110), rgb(250, 200, 60), rgb(180, 90, 230), rgb(250, 120, 60) }), M.Grass, { Name = "Flowers" })
				end
			end
		end
		seg(cur, a2, y0, y1)
	end
	local function win(c, b, t, wdt)
		return { c = c, w = wdt or 4.4, b = b, t = t, kind = "window" }
	end

	for f = 1, floors do
		local y0 = f == 1 and Y1 or yF(f) - SLAB
		local y1 = yF(f) + H
		local yb, yt = yF(f) + 3, yF(f) + 7.6
		-- façade
		local front = {}
		if f == 1 then
			table.insert(front, { c = doorX, w = DOOR_W, b = Y1, t = Y1 + DOOR_H, kind = "door" })
			local rx1, rx2 = doorX + DOOR_W / 2 + 1.2, xi2 - 1
			if rx2 - rx1 >= 4.4 then
				table.insert(front, win((rx1 + rx2) / 2, yb, yt, math.min(6.5, rx2 - rx1)))
			end
			local lx1, lx2 = xi1 + 1, doorX - DOOR_W / 2 - 1.2
			if lx2 - lx1 >= 3.4 then
				table.insert(front, win((lx1 + lx2) / 2, yb, yt, math.min(5, lx2 - lx1)))
			end
		else
			table.insert(front, win(-w / 4, yb, yt))
			table.insert(front, win(w / 4, yb, yt))
		end
		wall("X", -d / 2 + T / 2, -w / 2, w / 2, y0, y1, front, wallC, st.mat, T, -1)
		-- arrière
		local back = { win(-w / 4, f == 1 and yF(f) + 4.4 or yb, yt, 4.4), win(w / 4, yb, yt, 4) }
		wall("X", d / 2 - T / 2, -w / 2, w / 2, y0, y1, back, wallC, st.mat, T, 1)
		-- côtés
		local sideOps = { win(-d / 4, yb, yt, 4) }
		if d >= 16 then
			table.insert(sideOps, win(d / 4 + 0.5, yb, yt, 3.6))
		end
		local rightOps = (two and f == 1) and { win(-d / 4 - 1, yb + 1, yt, 3) } or table.clone(sideOps)
		if opts.noSideWindows then
			sideOps, rightOps = {}, {}
		end
		wall("Z", -w / 2 + T / 2, -d / 2 + T, d / 2 - T, y0, y1, sideOps, wallC, st.mat, T, -1)
		wall("Z", w / 2 - T / 2, -d / 2 + T, d / 2 - T, y0, y1, rightOps, wallC, st.mat, T, 1)
	end

	-- Porte d'entrée (pivote, voir HouseDoors) + encadrement
	local door = P(CFrame.new(doorX, Y1 + (DOOR_H - 0.1) / 2, -d / 2 + T / 2), V(DOOR_W - 0.1, DOOR_H - 0.1, 0.3), doorC, M.Wood, { Name = "HouseDoor" })
	CS:AddTag(door, "HouseDoor")
	D(CFrame.new(doorX, Y1 + DOOR_H + 0.25, -d / 2 - 0.12), V(DOOR_W + 1, 0.5, 0.25), trimC, M.SmoothPlastic, { Name = "DoorFrame" })
	for _, s in { -1, 1 } do
		D(CFrame.new(doorX + s * (DOOR_W / 2 + 0.25), Y1 + DOOR_H / 2, -d / 2 - 0.12), V(0.5, DOOR_H, 0.25), trimC, M.SmoothPlastic, { Name = "DoorFrame" })
	end
	-- applique et numéro
	D(CFrame.new(doorX + DOOR_W / 2 + 1.2, Y1 + 6.5, -d / 2 - 0.2), V(0.5, 0.8, 0.4), rgb(255, 235, 170), M.Neon, { Name = "PorchLight" })
	local num = D(CFrame.new(doorX - DOOR_W / 2 - 1.3, Y1 + 6.2, -d / 2 - 0.08), V(1.4, 1, 0.1), rgb(40, 40, 45), M.SmoothPlastic, { Name = "HouseNumber" })
	Lib.label(num, Enum.NormalId.Front, tostring(opts.number or rng:NextInteger(1, 99)), rgb(255, 255, 255), nil, Enum.Font.Arimo)

	-- Perron ou porche
	if porch then
		local pw = 8
		P(CFrame.new(doorX, Y1 / 2, -d / 2 - 2.2), V(pw, Y1, 4.4), rgb(150, 115, 85), M.WoodPlanks, { Name = "PorchDeck" })
		D(CFrame.new(doorX, Y1 + 8.9, -d / 2 - 2.3), V(pw + 0.6, 0.5, 4.8), roofC, roofM, { Name = "PorchRoof" })
		for _, s in { -1, 1 } do
			P(CFrame.new(doorX + s * (pw / 2 - 0.4), Y1 + 4.3, -d / 2 - 4), V(0.5, 8.6, 0.5), trimC, M.Wood, { Name = "PorchPost" })
		end
	else
		P(CFrame.new(doorX, Y1 / 2, -d / 2 - 1), V(DOOR_W + 1.4, Y1, 2), rgb(165, 160, 150), M.Concrete, { Name = "Step" })
		D(CFrame.new(doorX, Y1 + DOOR_H + 0.9, -d / 2 - 0.9), V(DOOR_W + 1.6, 0.3, 1.8), trimC, M.SmoothPlastic, { Name = "DoorCanopy" })
	end

	-- Cloisons intérieures
	local function partition(axis, fixed, a1, a2, y0, ops)
		wall(axis, fixed, a1, a2, y0, y0 + H, ops, inC, M.Plaster, 0.4, nil)
	end
	local function doorway(c)
		return { c = c, w = 3.8, b = -1e3, t = 0, kind = "doorway" }
	end
	local zP
	if two then
		-- RDC : séjour devant, cuisine/salle à manger derrière ; escalier le long du mur droit
		zP = 0
		local ops = { doorway(xi1 + 2.4) }
		ops[1].b, ops[1].t = Y1, Y1 + 8
		partition("X", zP, xi1, stairX1, Y1, ops)
		-- escalier
		local rise = (H + SLAB) / NST
		for k = 1, NST do
			P(CFrame.new((stairX1 + xi2) / 2, Y1 + k * rise / 2, zs + (k - 0.5) * RUN), V(xi2 - stairX1, k * rise, RUN), floorC, M.WoodPlanks, { Name = "Stair" })
		end
		-- dalle de l'étage avec trémie au-dessus de l'escalier
		local yS = yF(2) - SLAB / 2
		P(CFrame.new((xi1 + stairX1) / 2, yS, 0), V(stairX1 - xi1, SLAB, zi2 - zi1), floorC, M.WoodPlanks, { Name = "UpperFloor" })
		if holeZ1 - zi1 > 0.1 then
			P(CFrame.new((stairX1 + xi2) / 2, yS, (zi1 + holeZ1) / 2), V(xi2 - stairX1, SLAB, holeZ1 - zi1), floorC, M.WoodPlanks, { Name = "UpperFloor" })
		end
		if zi2 - holeZ2 > 0.1 then
			P(CFrame.new((stairX1 + xi2) / 2, yS, (holeZ2 + zi2) / 2), V(xi2 - stairX1, SLAB, zi2 - holeZ2), floorC, M.WoodPlanks, { Name = "UpperFloor" })
		end
		-- garde-corps
		P(CFrame.new(stairX1 - 0.15, yF(2) + 1.6, (holeZ1 + holeZ2) / 2), V(0.3, 3.2, holeZ2 - holeZ1), trimC, M.Wood, { Name = "Railing" })
		P(CFrame.new((stairX1 + xi2) / 2, yF(2) + 1.6, holeZ1 - 0.15), V(xi2 - stairX1, 3.2, 0.3), trimC, M.Wood, { Name = "Railing" })
		-- étage : chambre devant, salle de bain / bureau derrière
		local ops2 = { doorway((xi1 + stairX1) / 2 - 1) }
		ops2[1].b, ops2[1].t = yF(2), yF(2) + 8
		partition("X", 1.5, xi1, stairX1, yF(2), ops2)
	else
		-- plain-pied : séjour devant ; cuisine (gauche) et chambre (droite) derrière
		zP = 0.5
		local xs = -w / 10
		local ops = { doorway((xi1 + xs) / 2), doorway(xs + 2.6) }
		for _, o in ops do
			o.b, o.t = Y1, Y1 + 8
		end
		partition("X", zP, xi1, xi2, Y1, ops)
		partition("Z", xs, zP + 0.2, zi2, Y1, {})
	end

	-- Plafond, éclairage
	P(CFrame.new(0, yTop + 0.25, 0), V(w, 0.5, d), rgb(245, 245, 242), M.SmoothPlastic, { Name = "Ceiling" })
	local lamp = D(CFrame.new(0, yF(1) + H - 0.15, (zi1 + zP) / 2), V(1.6, 0.25, 1.6), rgb(255, 245, 220), M.Neon, { Name = "CeilingLight", Shape = Enum.PartType.Block })
	local light = Instance.new("PointLight")
	light.Range = 22
	light.Brightness = 1.1
	light.Color = rgb(255, 236, 205)
	light.Shadows = false
	light.Parent = lamp

	-- Toit
	local yR = yTop + 0.5
	if roofKind == "gableX" or roofKind == "gableZ" then
		local span = roofKind == "gableX" and d or w
		local len = roofKind == "gableX" and w or d
		local rh = math.clamp(span * 0.38, 5, 8)
		if roofKind == "gableX" then
			P(CFrame.new(0, yR + rh / 2, -span / 4 - 0.25), V(len + 1.6, rh, span / 2 + 0.5), roofC, roofM, { Class = "WedgePart", Name = "Roof" })
			P(CFrame.new(0, yR + rh / 2, span / 4 + 0.25) * CFrame.Angles(0, math.pi, 0), V(len + 1.6, rh, span / 2 + 0.5), roofC, roofM, { Class = "WedgePart", Name = "Roof" })
		else
			P(CFrame.new(-span / 4 - 0.25, yR + rh / 2, 0) * CFrame.Angles(0, math.pi / 2, 0), V(len + 1.6, rh, span / 2 + 0.5), roofC, roofM, { Class = "WedgePart", Name = "Roof" })
			P(CFrame.new(span / 4 + 0.25, yR + rh / 2, 0) * CFrame.Angles(0, -math.pi / 2, 0), V(len + 1.6, rh, span / 2 + 0.5), roofC, roofM, { Class = "WedgePart", Name = "Roof" })
		end
		if rng:NextNumber() < 0.5 then
			D(CFrame.new(w / 3, yR + rh * 0.6, d / 6), V(2, rh + 1.5, 2), rgb(140, 80, 60), M.Brick, { Name = "Chimney" })
		end
	elseif roofKind == "shed" then
		local rh = 3.5
		P(CFrame.new(0, yR + rh / 2, 0), V(w + 1.2, rh, d + 1.2), roofC, roofM, { Class = "WedgePart", Name = "Roof" })
	else
		P(CFrame.new(0, yR + 0.3, 0), V(w + 0.4, 0.6, d + 0.4), roofC, roofM, { Name = "Roof" })
		for _, e in { { 0, -d / 2, w + 0.4, 0.4 }, { 0, d / 2, w + 0.4, 0.4 }, { -w / 2, 0, 0.4, d + 0.4 }, { w / 2, 0, 0.4, d + 0.4 } } do
			D(CFrame.new(e[1], yR + 1, e[2]), V(e[3], 1.4, e[4]), trimC, M.SmoothPlastic, { Name = "Parapet" })
		end
		if st.modern then
			D(CFrame.new(-w / 2 + 0.1, Y1 + 5, -d / 4), V(0.3, 9, d / 2 - 1), rgb(150, 105, 70), M.WoodPlanks, { Name = "WoodAccent" })
		end
		D(CFrame.new(w / 5, yR + 1.4, d / 5), V(3, 2, 2.4), rgb(180, 180, 185), M.Metal, { Name = "RoofAC" })
	end

	-- Meubles
	local y = Y1 + 0.1
	if two then
		local zl = (zi1 + zP) / 2
		furn(m, cf, "TV", xi1 + 0.9, y, zl, RIGHT, V(5, 4.5, 1.6), "fit")
		furn(m, cf, "Sofa", (doorX + DOOR_W / 2 + stairX1) / 2, y, zP - 1.8, FRONT, V(6.5, 3.2, 3), "fit")
		furn(m, cf, "Plant", stairX1 - 1.2, y, zi1 + 1.2, FRONT, V(0, 4.5, 0), "height", false)
		-- cuisine
		local L = math.max(4, stairX1 - xi1 - 4.2)
		furn(m, cf, "Kitchen", xi1 + 0.3 + L / 2, y, zi2 - 1.3, FRONT, V(L, 3.8, 2.4), "stretch")
		furn(m, cf, "Fridge", xi1 + L + 2.1, y, zi2 - 1.4, FRONT, V(3, 7, 2.6), "stretch")
		furn(m, cf, "Dining", (xi1 + stairX1) / 2, y, (zP + zi2) / 2 - 1, FRONT, V(5.5, 3.4, 4.2), "fit")
		-- étage
		local y2 = yF(2)
		furn(m, cf, "Bed", xi1 + 3.8, y2, (zi1 + 1.5) / 2, RIGHT, V(5.5, 3.2, 7), "fit")
		furn(m, cf, "Wardrobe", stairX1 - 2.6, y2, 1.5 - 1.2, FRONT, V(4.4, 7.4, 2), "stretch")
		furn(m, cf, "Desk", stairX1 - 2.6, y2, zi1 + 1.4, BACK, V(4.5, 4.5, 2.6), "fit")
		furn(m, cf, "Bathroom", xi1 + 3, y2, zi2 - 1.4, FRONT, V(5, 6, 2.6), "fit")
		furn(m, cf, "Bookshelf", stairX1 - 4, y2, zi2 - 0.9, FRONT, V(4, 7, 1.4), "stretch")
	else
		local xs = -w / 10
		local zl = (zi1 + zP) / 2
		furn(m, cf, "TV", xi2 - 0.9, y, zl, LEFT, V(5, 4.5, 1.6), "fit")
		furn(m, cf, "Sofa", xi2 - 7.2, y, zl, RIGHT, V(7, 3.2, 3), "fit")
		furn(m, cf, "Dining", xi1 + 3.4, y, zl + 0.5, FRONT, V(5, 3.4, 4.6), "fit")
		furn(m, cf, "Plant", xi1 + 1.1, y, zi1 + 1.1, FRONT, V(0, 4.5, 0), "height", false)
		local L = math.max(3, xs - xi1 - 3.6)
		furn(m, cf, "Kitchen", xi1 + 0.2 + L / 2, y, zi2 - 1.3, FRONT, V(L, 3.8, 2.4), "stretch")
		furn(m, cf, "Fridge", xs - 1.8, y, zi2 - 1.4, FRONT, V(3, 7, 2.6), "stretch")
		furn(m, cf, "Bed", (xs + xi2) / 2 + 1, y, zi2 - 3.3, FRONT, V(5, 3, 6.4), "fit")
		furn(m, cf, "Wardrobe", xi2 - 1.1, y, zP + 2.4, LEFT, V(3.6, 7.2, 1.8), "stretch")
	end
	return m
end

---------------------------------------------------------------- Garage fermé (allée existante)
local function garage(parent, cf, gx, frontZ, d, wallC, roofC)
	local m = Lib.model(parent, "Garage")
	local gd = d - 2
	local z = frontZ + gd / 2 + 0.5
	Lib.part(m, cf * CFrame.new(gx, 4.5, z), V(11, 9, gd), wallC, M.Plaster, { Name = "Garage" })
	Lib.deco(m, cf * CFrame.new(gx, 3.8, z - gd / 2 - 0.12), V(8.6, 6.6, 0.25), rgb(235, 235, 235), M.DiamondPlate, { Name = "GarageDoor" })
	Lib.deco(m, cf * CFrame.new(gx, 9.25, z), V(11.6, 0.5, gd + 0.6), roofC, M.Slate, { Name = "GarageRoof" })
	return m
end

return function()
	local map = workspace.Map
	local rng = Random.new(2027)
	local count = { house = 0, hill = 0, town = 0, two = 0 }
	local list = {}
	for _, m in map:GetDescendants() do
		if m:IsA("Model") and (m.Name == "House" or m.Name == "HillHouse") and m:FindFirstChild("MeshyHouse") then
			table.insert(list, m)
		end
	end
	for n, m in list do
		local mesh = m.MeshyHouse
		local rot = mesh.CFrame.Rotation
		local bottom = mesh.Position - V(0, mesh.Size.Y / 2, 0)
		local r = Random.new(math.floor(bottom.X * 7 + bottom.Z * 13))
		if m.Parent and m.Parent.Name == "Block_3_4" then
			-- maison de ville : 2 niveaux, façade alignée sur la rue, pas de fenêtres latérales (mitoyennes)
			local w = math.max(14, mesh.Size.X - 1.4)
			local cf = CFrame.new(bottom) * rot * CFrame.new(0, 0, 0.925)
			build(m, cf, w, 18, 2, r, { doorX = -w / 5, noSideWindows = true, porch = false, style = r:NextNumber() < 0.7 and STYLES[r:NextInteger(1, 2)] or nil, number = n })
			count.town += 1
			count.two += 1
		elseif m.Name == "HillHouse" then
			local pad
			local best = math.huge
			for _, p in m.Parent:GetChildren() do
				if p.Name == "HousePad" then
					local dist = (V(p.Position.X, 0, p.Position.Z) - V(bottom.X, 0, bottom.Z)).Magnitude
					if dist < best then
						best, pad = dist, p
					end
				end
			end
			local c = pad and V(pad.Position.X, pad.Position.Y + pad.Size.Y / 2, pad.Position.Z) or bottom
			local floors = r:NextNumber() < 0.5 and 2 or 1
			build(m, CFrame.new(c) * rot, 18, 16, floors, r, { number = n })
			count.hill += 1
			if floors == 2 then
				count.two += 1
			end
		else
			local path = m:FindFirstChild("Path")
			local trash
			for _, c in m:GetChildren() do
				if c.Name == "TrashCan" and c:IsA("Model") then
					local p = rot:PointToObjectSpace(c:GetPivot().Position)
					if not trash or p.X > trash.X then
						trash = p
					end
				end
			end
			if path then
				local pl = rot:PointToObjectSpace(path.Position)
				local w = trash and math.clamp((trash.X - pl.X + 1) / 0.7, 16, 26) or 20
				local d = 18
				local ox, oz = pl.X + w / 5, pl.Z + d / 2 + 5
				local cf = CFrame.new(rot * V(ox, 0, oz)) * rot
				cf = CFrame.new(cf.Position.X, path.Position.Y - path.Size.Y / 2, cf.Position.Z) * rot
				local floors = w >= 19 and r:NextNumber() < 0.45 and 2 or 1
				local body = build(m, cf, w, d, floors, r, { number = n })
				local drive = m:FindFirstChild("Driveway")
				if drive then
					local dl = cf:PointToObjectSpace(drive.Position)
					local wallC = Color3.new(0.9, 0.9, 0.88)
					for _, p in body:GetChildren() do
						if p.Name == "Wall" then
							wallC = p.Color
							break
						end
					end
					local roofP = body:FindFirstChild("Roof")
					garage(m, cf, dl.X, -d / 2 + 1, d, wallC:Lerp(Color3.new(1, 1, 1), 0.15), roofP and roofP.Color or rgb(80, 80, 90))
				end
				count.house += 1
				if floors == 2 then
					count.two += 1
				end
			end
		end
		mesh:Destroy()
		task.wait()
	end
	return ("maisons visitables : %d maisons, %d maisons de ville, %d sur la colline (%d à étage)"):format(count.house, count.town, count.hill, count.two)
end
