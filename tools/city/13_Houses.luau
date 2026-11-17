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
	{ name = "brique rouge", mat = M.Brick, colors = { rgb(150, 82, 64), rgb(132, 72, 58), rgb(160, 98, 78) }, trim = { rgb(236, 233, 224) }, roofs = { "gableX", "gableZ" }, base = M.Cobblestone },
	{ name = "brique claire", mat = M.Brick, colors = { rgb(196, 176, 146), rgb(182, 160, 128), rgb(205, 192, 168) }, trim = { rgb(245, 243, 236), rgb(70, 62, 54) }, roofs = { "gableX", "gableZ" }, base = M.Cobblestone },
	{ name = "bardage bois", mat = M.WoodPlanks, colors = { rgb(150, 170, 182), rgb(160, 175, 150), rgb(232, 228, 214), rgb(214, 196, 150), rgb(120, 128, 136), rgb(168, 112, 98) }, trim = { rgb(245, 245, 242) }, roofs = { "gableX", "gableZ" }, base = M.Concrete },
	{ name = "enduit", mat = M.Plaster, colors = { rgb(238, 228, 206), rgb(232, 218, 196), rgb(214, 170, 136), rgb(226, 204, 190), rgb(242, 240, 232) }, trim = { rgb(245, 245, 242), rgb(88, 70, 56) }, roofs = { "gableX", "gableZ" }, base = M.Concrete },
	{ name = "pierre", mat = M.Limestone, colors = { rgb(214, 204, 184), rgb(196, 186, 166) }, trim = { rgb(78, 70, 62), rgb(236, 234, 228) }, roofs = { "gableX", "gableZ" }, base = M.Cobblestone },
	{ name = "moderne", mat = M.SmoothPlastic, colors = { rgb(240, 240, 238), rgb(64, 66, 72), rgb(210, 208, 202) }, trim = { rgb(42, 42, 46) }, roofs = { "flat", "shed" }, modern = true, base = M.Concrete },
}
-- couvertures : bardeaux, tuiles en terre cuite, ardoise
local ROOFS = {
	{ M.RoofShingles, rgb(58, 58, 62) }, { M.RoofShingles, rgb(92, 76, 64) }, { M.RoofShingles, rgb(108, 110, 114) },
	{ M.ClayRoofTiles, rgb(168, 86, 62) }, { M.ClayRoofTiles, rgb(140, 92, 72) }, { M.Slate, rgb(72, 76, 86) },
}
local GUTTERS = { rgb(240, 240, 238), rgb(60, 60, 64), rgb(120, 90, 70) }
local DOOR_COLORS = { rgb(150, 40, 40), rgb(40, 70, 120), rgb(60, 40, 30), rgb(40, 110, 70), rgb(230, 190, 60), rgb(30, 30, 32), rgb(240, 240, 240) }
local SHUTTERS = { rgb(40, 80, 60), rgb(40, 60, 110), rgb(140, 40, 40), rgb(60, 60, 65), rgb(200, 190, 160) }
local WALLS_IN = { rgb(245, 240, 230), rgb(230, 225, 215), rgb(215, 230, 235), rgb(235, 225, 205), rgb(225, 235, 220), rgb(240, 225, 225) }
local FLOORS = { rgb(170, 130, 90), rgb(120, 85, 60), rgb(200, 170, 130), rgb(150, 150, 150) }
local GLASS = rgb(78, 102, 118)

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
	local rf = pick(rng, ROOFS)
	local roofC = st.modern and rgb(70, 72, 78) or rf[2]
	local roofM = st.modern and M.Concrete or rf[1]
	local gutC = pick(rng, GUTTERS)
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
	P(CFrame.new(0, Y1 / 2, 0), V(w + 0.6, Y1, d + 0.6), st.base == M.Cobblestone and rgb(120, 116, 110) or rgb(165, 160, 150), st.base, { Name = "Foundation" })
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
			-- enduit intérieur : la face intérieure d'un mur extérieur est peinte, pas en brique
			if outward then
				local off = fixed - outward * (thick / 2 + 0.03)
				if axis == "X" then
					D(CFrame.new((a + b) / 2, (ya + yb) / 2, off), V(b - a, yb - ya, 0.06), inC, M.Plaster, { Name = "InnerFinish" })
				else
					D(CFrame.new(off, (ya + yb) / 2, (a + b) / 2), V(0.06, yb - ya, b - a), inC, M.Plaster, { Name = "InnerFinish" })
				end
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
				P(at(o.c, mid, 0), V(o.w, h, 0.2), GLASS, M.Glass, { Name = "Window", Transparency = 0.42, Reflectance = 0.18, CastShadow = false })
				for _, sd in { -1, 1 } do
					D(at(o.c + sd * (o.w / 2 + 0.15), mid, thick / 2 + 0.1), V(0.3, h + 0.5, 0.22), trimC, M.SmoothPlastic, { Name = "Jamb" })
				end
				D(at(o.c, o.b + h * 0.58, 0.05), V(o.w, 0.15, 0.15), trimC, M.SmoothPlastic, { Name = "Muntin" })
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

	-- Habillage : planches d'angle, bandeau entre étages
	if not st.modern then
		for _, cx in { -1, 1 } do
			for _, cz in { -1, 1 } do
				D(CFrame.new(cx * (w / 2 + 0.05), (Y1 + yTop) / 2, cz * (d / 2 + 0.05)), V(0.55, yTop - Y1, 0.55), trimC, M.SmoothPlastic, { Name = "CornerBoard" })
			end
		end
		if two then
			local yb = yF(2) - SLAB / 2
			D(CFrame.new(0, yb, -d / 2 - 0.12), V(w + 0.3, 0.45, 0.25), trimC, M.SmoothPlastic, { Name = "Band" })
			D(CFrame.new(0, yb, d / 2 + 0.12), V(w + 0.3, 0.45, 0.25), trimC, M.SmoothPlastic, { Name = "Band" })
			D(CFrame.new(-w / 2 - 0.12, yb, 0), V(0.25, 0.45, d + 0.3), trimC, M.SmoothPlastic, { Name = "Band" })
			D(CFrame.new(w / 2 + 0.12, yb, 0), V(0.25, 0.45, d + 0.3), trimC, M.SmoothPlastic, { Name = "Band" })
		end
	end

	-- Porte d'entrée (pivote, voir HouseDoors) + encadrement
	local door = P(CFrame.new(doorX, Y1 + (DOOR_H - 0.1) / 2, -d / 2 + T / 2), V(DOOR_W - 0.1, DOOR_H - 0.1, 0.3), doorC, M.Wood, { Name = "HouseDoor" })
	CS:AddTag(door, "HouseDoor")
	local function onDoor(lcf, size, color, mat, name)
		local q = Instance.new("Part")
		q.Name = name
		q.Size = size
		q.CFrame = cf * lcf
		q.Color = color
		q.Material = mat
		q.Anchored = false
		q.CanCollide = false
		q.CanQuery = false
		q.CanTouch = false
		q.Massless = true
		q.TopSurface, q.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		local wc = Instance.new("WeldConstraint")
		wc.Part0, wc.Part1 = door, q
		wc.Parent = q
		q.Parent = m
	end
	local dz = -d / 2 + T / 2
	for _, sd in { -1, 1 } do
		onDoor(CFrame.new(doorX + DOOR_W / 2 - 0.6, Y1 + 3.7, dz + sd * 0.25), V(0.25, 0.25, 0.25), rgb(200, 170, 90), M.Metal, "Handle")
	end
	onDoor(CFrame.new(doorX, Y1 + 6.1, dz - 0.16), V(2.4, 1.8, 0.05), GLASS, M.Glass, "DoorGlass")
	onDoor(CFrame.new(doorX, Y1 + 2.6, dz - 0.16), V(2.8, 2.8, 0.05), doorC:Lerp(Color3.new(0, 0, 0), 0.15), M.Wood, "DoorPanel")
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
			P(CFrame.new(doorX + s * (pw / 2 - 0.3), Y1 + 3, -d / 2 - 2.2), V(0.3, 0.3, 4.2), trimC, M.Wood, { Name = "PorchRail" })
			D(CFrame.new(doorX + s * (pw / 2 - 0.3), Y1 + 1.6, -d / 2 - 2.2), V(0.12, 2.6, 4.2), trimC, M.WoodPlanks, { Name = "PorchBalusters", Transparency = 0.35 })
			P(CFrame.new(doorX + s * (pw / 4 + 0.75), Y1 + 3, -d / 2 - 4.2), V(pw / 2 - 1.5, 0.3, 0.3), trimC, M.Wood, { Name = "PorchRail" })
		end
		P(CFrame.new(doorX, 0.25, -d / 2 - 5), V(3, 0.5, 1.2), rgb(150, 115, 85), M.WoodPlanks, { Name = "PorchStep" })
	else
		P(CFrame.new(doorX, Y1 / 2, -d / 2 - 1), V(DOOR_W + 1.4, Y1, 2), rgb(165, 160, 150), M.Concrete, { Name = "Step" })
		D(CFrame.new(doorX, Y1 + DOOR_H + 0.9, -d / 2 - 0.9), V(DOOR_W + 1.6, 0.3, 1.8), trimC, M.SmoothPlastic, { Name = "DoorCanopy" })
	end

	-- Arbustes au pied de la façade
	local bx = doorX - (porch and 4 or DOOR_W / 2) - 1.8
	if bx > -w / 2 + 1.2 then
		furn(m, cf, "Bush", bx, 0, -d / 2 - 1.3, FRONT, V(0, 2.6, 0), "height", false)
	end
	if not opts.noSideWindows then
		furn(m, cf, "Bush", -w / 2 - 1.2, 0, -d / 4, FRONT, V(0, 2.4, 0), "height", false)
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
		local gx = roofKind == "gableX"
		local span = gx and d or w
		local len = gx and w or d
		local OV = 1.2
		local rh = math.clamp(span * 0.45, 5, 10)
		local depth = span / 2 + OV
		local lenT = len + 1.6
		local function L(l, y, sv)
			return gx and V(l, y, sv) or V(sv, y, l)
		end
		local function SZ(a, y, b)
			return gx and V(a, y, b) or V(b, y, a)
		end
		local ROT = gx and { [-1] = CFrame.identity, [1] = CFrame.Angles(0, math.pi, 0) } or { [-1] = CFrame.Angles(0, math.pi / 2, 0), [1] = CFrame.Angles(0, -math.pi / 2, 0) }
		local rhw = rh * (span / 2) / depth
		for _, sd in { -1, 1 } do
			-- pan de toit avec débord
			P(CFrame.new(L(0, yR + rh / 2, sd * depth / 2)) * ROT[sd], V(lenT, rh, depth), roofC, roofM, { Class = "WedgePart", Name = "Roof" })
			-- planche de rive, gouttière et descente
			D(CFrame.new(L(0, yR - 0.1, sd * (span / 2 + OV))), SZ(lenT, 0.5, 0.2), trimC, M.SmoothPlastic, { Name = "Fascia" })
			D(CFrame.new(L(0, yR - 0.05, sd * (span / 2 + OV + 0.25))), SZ(lenT, 0.4, 0.4), gutC, M.Metal, { Name = "Gutter" })
			D(CFrame.new(L(len / 2 - 0.5, (Y1 + yR) / 2, sd * (span / 2 + 0.3))), V(0.35, yR - Y1, 0.35), gutC, M.Metal, { Name = "Downspout" })
			-- pignons : triangle dans le matériau de façade + planches de rive inclinées
			for _, e in { -1, 1 } do
				local lx = e * (lenT / 2 + 0.05)
				P(CFrame.new(L(lx, yR + rhw / 2, sd * span / 4)) * ROT[sd], V(0.1, rhw, span / 2), wallC, st.mat, { Class = "WedgePart", Name = "GableWall" })
				Lib.beam(m, cf * L(lx, yR + 0.1, sd * (span / 2 + OV)), cf * L(lx, yR + rh + 0.1, 0), 0.3, 0.6, trimC, M.SmoothPlastic, { Name = "Rake", CanCollide = false, CanQuery = false, CanTouch = false })
			end
		end
		D(CFrame.new(L(0, yR + rh, 0)), SZ(lenT, 0.35, 0.9), roofC:Lerp(Color3.new(0, 0, 0), 0.25), roofM, { Name = "RidgeCap" })
		if rng:NextNumber() < 0.5 then
			local chx, chz = w / 3, d / 6
			D(CFrame.new(chx, yR + rh * 0.6, chz), V(2, rh + 1.5, 2), rgb(140, 80, 60), M.Brick, { Name = "Chimney" })
			D(CFrame.new(chx, yR + rh * 0.6 + (rh + 1.5) / 2 + 0.15, chz), V(2.4, 0.3, 2.4), rgb(120, 118, 112), M.Concrete, { Name = "ChimneyCap" })
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
local function garage(parent, cf, gx, frontZ, d, wallC, roofC, roofM)
	local m = Lib.model(parent, "Garage")
	local gd = d - 2
	local z = frontZ + gd / 2 + 0.5
	Lib.part(m, cf * CFrame.new(gx, 4.5, z), V(11, 9, gd), wallC, M.Plaster, { Name = "Garage" })
	Lib.deco(m, cf * CFrame.new(gx, 3.8, z - gd / 2 - 0.12), V(8.6, 6.6, 0.25), rgb(235, 235, 235), M.DiamondPlate, { Name = "GarageDoor" })
	for _, sd in { -1, 1 } do
		Lib.part(m, cf * CFrame.new(gx + sd * 3.15, 10.5, z) * CFrame.Angles(0, sd < 0 and math.pi / 2 or -math.pi / 2, 0), V(gd + 1, 3, 6.3), roofC, roofM or M.RoofShingles, { Class = "WedgePart", Name = "GarageRoof" })
	end
	for k = 1, 3 do
		Lib.deco(m, cf * CFrame.new(gx, 0.5 + k * 1.65, z - gd / 2 - 0.26), V(8.6, 0.08, 0.05), rgb(200, 200, 200), M.SmoothPlastic, { Name = "GarageDoorLine" })
	end
	Lib.deco(m, cf * CFrame.new(gx, 7.4, z - gd / 2 - 0.15), V(9.4, 0.4, 0.3), Color3.fromRGB(240, 240, 238), M.SmoothPlastic, { Name = "GarageFrame" })
	return m
end

local function addGarage(m, cf, d, body)
	local drive = m:FindFirstChild("Driveway")
	if not drive then
		return
	end
	local dl = cf:PointToObjectSpace(drive.Position)
	local wallC = Color3.new(0.9, 0.9, 0.88)
	for _, p in body:GetChildren() do
		if p.Name == "Wall" then
			wallC = p.Color
			break
		end
	end
	local roofP = body:FindFirstChild("Roof")
	garage(m, cf, dl.X, -d / 2 + 1, d, wallC, roofP and roofP.Color or rgb(80, 80, 90), roofP and roofP.Material or M.RoofShingles)
end

-- Repère d'une maison déjà construite (passe précédente) : relu depuis sa fondation
local function fromBody(body)
	local f = body:FindFirstChild("Foundation")
	if not f then
		return nil
	end
	return f.CFrame * CFrame.new(0, -Y1 / 2, 0), f.Size.X - 0.6, f.Size.Z - 0.6, body:GetAttribute("Floors") or 1
end

return function()
	local map = workspace.Map
	local count = { house = 0, hill = 0, town = 0, two = 0 }
	local list = {}
	for _, m in map:GetDescendants() do
		if m:IsA("Model") and (m.Name == "House" or m.Name == "HillHouse") and (m:FindFirstChild("MeshyHouse") or m:FindFirstChild("HouseBody")) then
			table.insert(list, m)
		end
	end
	for n, m in list do
		local isTown = m.Parent and m.Parent.Name == "Block_3_4"
		local old = m:FindFirstChild("HouseBody")
		local cf, w, d, floors
		if old then
			cf, w, d, floors = fromBody(old)
		end
		if cf then
			local r = Random.new(math.floor(cf.Position.X * 7 + cf.Position.Z * 13) + 5)
			for _, c in m:GetChildren() do
				if c.Name == "HouseBody" or (c.Name == "Garage" and c:IsA("Model")) then
					c:Destroy()
				end
			end
			local opts = { number = n }
			if isTown then
				opts = { doorX = -w / 5, noSideWindows = true, porch = false, style = r:NextNumber() < 0.7 and STYLES[r:NextInteger(1, 2)] or nil, number = n }
				count.town += 1
			elseif m.Name == "HillHouse" then
				count.hill += 1
			else
				count.house += 1
			end
			local body = build(m, cf, w, d, floors, r, opts)
			if not isTown and m.Name ~= "HillHouse" then
				addGarage(m, cf, d, body)
			end
			if floors == 2 then
				count.two += 1
			end
		elseif m:FindFirstChild("MeshyHouse") then
			local mesh = m.MeshyHouse
			local rot = mesh.CFrame.Rotation
			local bottom = mesh.Position - V(0, mesh.Size.Y / 2, 0)
			local r = Random.new(math.floor(bottom.X * 7 + bottom.Z * 13))
			if isTown then
				local w2 = math.max(14, mesh.Size.X - 1.4)
				local cf2 = CFrame.new(bottom) * rot * CFrame.new(0, 0, 0.925)
				build(m, cf2, w2, 18, 2, r, { doorX = -w2 / 5, noSideWindows = true, porch = false, style = r:NextNumber() < 0.7 and STYLES[r:NextInteger(1, 2)] or nil, number = n })
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
				local fl = r:NextNumber() < 0.5 and 2 or 1
				build(m, CFrame.new(c) * rot, 18, 16, fl, r, { number = n })
				count.hill += 1
				if fl == 2 then
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
					local w2 = trash and math.clamp((trash.X - pl.X + 1) / 0.7, 16, 26) or 20
					local d2 = 18
					local ox, oz = pl.X + w2 / 5, pl.Z + d2 / 2 + 5
					local cf2 = CFrame.new(rot * V(ox, 0, oz)) * rot
					cf2 = CFrame.new(cf2.Position.X, path.Position.Y - path.Size.Y / 2, cf2.Position.Z) * rot
					local fl = w2 >= 19 and r:NextNumber() < 0.45 and 2 or 1
					local body = build(m, cf2, w2, d2, fl, r, { number = n })
					addGarage(m, cf2, d2, body)
					count.house += 1
					if fl == 2 then
						count.two += 1
					end
				end
			end
			mesh:Destroy()
		end
		task.wait()
	end
	return ("maisons visitables : %d maisons, %d maisons de ville, %d sur la colline (%d à étage)"):format(count.house, count.town, count.hill, count.two)
end
