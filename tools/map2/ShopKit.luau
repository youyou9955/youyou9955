--!nolint
-- Kit de commerces visitables (même échelle et mêmes portes que HouseKit) :
--   vitrine sur toute la façade avec double porte vitrée à charnières (ProximityPrompt Ouvrir/Fermer),
--   surface de vente (gondoles, rayonnages muraux, comptoir et caisse, table de présentation),
--   réserve fermée par une porte, plafond éclairé, étages supérieurs fermés (fenêtres teintées).
-- Repère : origine au milieu de la façade, au sol ; -Z vers la rue, +Z vers le fond, +X à gauche vu de la rue.
local Lib = require(script.Parent.Lib)
local HK = require(script.Parent.HouseKit)
local V, rgb, M = Lib.V, Lib.rgb, Lib.M
local L = HK.lib
local mk, box, ax, wall, props = L.mk, L.box, L.ax, L.wall, L.props

local K = { GH = 12.5, EXT = 0.8, FH = 8 }
local GLASS = rgb(176, 206, 220)
local FRAME = rgb(46, 48, 54)
local CEIL = rgb(240, 238, 234)
local WHITE = rgb(242, 240, 234)

-- thèmes : couleurs des produits et mobilier spécifique
K.THEMES = {
	toys = { floor = rgb(214, 206, 192), floorMat = M.SmoothPlastic, wall = rgb(246, 240, 226), products = { rgb(230, 70, 60), rgb(60, 130, 230), rgb(250, 200, 40), rgb(70, 180, 90), rgb(240, 130, 200) }, shelf = rgb(236, 236, 232) },
	phones = { floor = rgb(196, 198, 200), floorMat = M.SmoothPlastic, wall = rgb(238, 240, 242), products = { rgb(30, 32, 36), rgb(210, 212, 216), rgb(60, 70, 90), rgb(130, 80, 200) }, shelf = rgb(250, 250, 250), tables = true },
	bikes = { floor = rgb(120, 122, 126), floorMat = M.Concrete, wall = rgb(232, 230, 224), products = { rgb(200, 50, 50), rgb(40, 90, 160), rgb(30, 30, 34), rgb(240, 180, 40) }, shelf = rgb(70, 72, 78), racks = true },
	boxes = { floor = rgb(150, 120, 90), floorMat = M.WoodPlanks, wall = rgb(236, 226, 206), products = { rgb(196, 150, 96), rgb(176, 130, 80), rgb(214, 176, 120) }, shelf = rgb(150, 112, 76), productMat = M.Cardboard },
	laundry = { floor = rgb(226, 230, 232), floorMat = M.CeramicTiles, wall = rgb(214, 236, 240), products = { rgb(240, 240, 240) }, shelf = rgb(240, 240, 240), laundry = true },
	grocery = { floor = rgb(220, 218, 212), floorMat = M.CeramicTiles, wall = rgb(244, 242, 236), products = { rgb(220, 60, 50), rgb(250, 200, 40), rgb(70, 160, 80), rgb(240, 130, 40), rgb(60, 110, 200), rgb(240, 240, 236) }, shelf = rgb(236, 236, 232), fridges = true },
}

local function P(h, parent, lcf, size, col, mat, collide, extra)
	return Lib.part(parent, h.cf * lcf, size, col, mat or M.SmoothPlastic, props(not collide, extra))
end

-- rangée de produits sur une tablette (segments de couleurs variées)
local function products(h, parent, cx, y, cz, len, depth, alongX, th, rng)
	local x = -len / 2 + 0.1
	while x < len / 2 - 0.4 do
		local w = math.min(rng:NextNumber(0.8, 2.2), len / 2 - x - 0.1)
		local ht = rng:NextNumber(0.7, 1.3)
		local col = th.products[rng:NextInteger(1, #th.products)]
		local c = alongX and CFrame.new(cx + x + w / 2, y + ht / 2, cz) or CFrame.new(cx, y + ht / 2, cz + x + w / 2)
		local sz = alongX and V(w - 0.1, ht, depth) or V(depth, ht, w - 0.1)
		P(h, parent, c, sz, col, th.productMat or M.SmoothPlastic, false)
		x += w
	end
end

-- gondole double face le long de Z
local function gondola(h, parent, cx, z1, z2, th, rng)
	local len = z2 - z1
	local cz = (z1 + z2) / 2
	P(h, parent, CFrame.new(cx, 0.6, cz), V(3.2, 1.2, len), th.shelf, M.SmoothPlastic, true)
	P(h, parent, CFrame.new(cx, 3.6, cz), V(0.3, 6, len), th.shelf:Lerp(Color3.new(0, 0, 0), 0.08), M.SmoothPlastic, true)
	for _, s in { -1, 1 } do
		for k, y in { 1.2, 2.9, 4.6 } do
			if k > 1 then
				P(h, parent, CFrame.new(cx + s * 0.85, y - 0.06, cz), V(1.4, 0.12, len), th.shelf, M.SmoothPlastic, false)
			end
			products(h, parent, cx + s * 0.85, y, cz, len, 1.1, false, th, rng)
		end
		-- étiquettes de prix
		P(h, parent, CFrame.new(cx + s * 1.6, 1.1, cz), V(0.05, 0.25, len), rgb(250, 230, 80), M.SmoothPlastic, false)
	end
	-- têtes de gondole
	for _, s in { -1, 1 } do
		P(h, parent, CFrame.new(cx, 3.2, cz + s * (len / 2 + 0.05)), V(3.2, 6.4, 0.1), th.shelf:Lerp(Color3.new(0, 0, 0), 0.12), M.SmoothPlastic, false)
	end
end

-- rayonnage mural (côté s = ±1 : mur gauche/droit), de z1 à z2
local function wallShelf(h, parent, x, s, z1, z2, th, rng)
	local len, cz = z2 - z1, (z1 + z2) / 2
	P(h, parent, CFrame.new(x - s * 0.8, 3.75, cz), V(1.6, 7.5, len), th.shelf, M.SmoothPlastic, true)
	for _, y in { 1, 2.8, 4.6, 6.3 } do
		products(h, parent, x - s * 1.75, y, cz, len, 0.4, false, th, rng)
	end
end

local function counter(h, parent, cx, cz, w, accent)
	P(h, parent, CFrame.new(cx, 1.75, cz), V(w, 3.5, 2.6), WHITE, M.SmoothPlastic, true)
	P(h, parent, CFrame.new(cx, 3.6, cz), V(w + 0.3, 0.2, 2.9), rgb(70, 64, 58), M.Wood, false)
	P(h, parent, CFrame.new(cx, 1.6, cz - 1.31), V(w, 0.5, 0.04), accent, M.SmoothPlastic, false)
	-- caisse enregistreuse et terminal
	P(h, parent, CFrame.new(cx - w / 4, 4, cz + 0.3), V(1.6, 0.6, 1.2), rgb(40, 42, 46), M.SmoothPlastic, false)
	P(h, parent, CFrame.new(cx - w / 4, 4.8, cz + 0.5) * CFrame.Angles(math.rad(-20), 0, 0), V(1.4, 1, 0.12), rgb(30, 32, 36), M.SmoothPlastic, false)
	P(h, parent, CFrame.new(cx - w / 4, 4.8, cz + 0.43) * CFrame.Angles(math.rad(-20), 0, 0), V(1.2, 0.8, 0.02), rgb(90, 170, 220), M.Neon, false)
	P(h, parent, CFrame.new(cx + w / 4, 3.95, cz - 0.4), V(0.5, 0.5, 0.8), rgb(36, 38, 42), M.SmoothPlastic, false)
end

local function ceilingLight(h, parent, cx, y, cz, lit)
	local p = P(h, parent, CFrame.new(cx, y - 0.1, cz), V(2.4, 0.15, 6), rgb(255, 250, 238), M.Neon, false, { Transparency = 0.15 })
	if lit then
		local l = Instance.new("PointLight")
		l.Range = 26
		l.Brightness = 0.9
		l.Color = rgb(255, 246, 230)
		l.Shadows = false
		l.Parent = p
	end
	return p
end

-- porte vitrée : modèle HouseKit (charnière + panneau soudé), panneau en verre, cadre aluminium
local function glassDoor(h, parent, u, c, w, ht, hinge, label)
	local d = L.door(h, parent, "x", u, c, 0.3, w, ht, 1, hinge, FRAME, label, false)
	local panel = d:FindFirstChild("Panel")
	for _, p in d:GetChildren() do
		if p:IsA("BasePart") and p ~= panel and p.Name ~= "Hinge" and p.Shape ~= Enum.PartType.Ball then
			p:Destroy()
		end
	end
	panel.Material = M.Glass
	panel.Color = GLASS
	panel.Transparency = 0.45
	local cf, sz = panel.CFrame, panel.Size
	local hinge0 = d:FindFirstChild("Hinge")
	local function bar(off, size)
		local b = Lib.part(d, cf * CFrame.new(off), size, FRAME, M.Metal, { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Anchored = false, Massless = true })
		L.weld(hinge0, b)
	end
	bar(V(0, sz.Y / 2 - 0.25, 0), V(sz.X, 0.5, sz.Z + 0.06))
	bar(V(0, -sz.Y / 2 + 0.4, 0), V(sz.X, 0.8, sz.Z + 0.06))
	bar(V(sz.X / 2 - 0.2, 0, 0), V(0.4, sz.Y, sz.Z + 0.06))
	bar(V(-sz.X / 2 + 0.2, 0, 0), V(0.4, sz.Y, sz.Z + 0.06))
	bar(V(-hinge * (sz.X / 2 - 0.7), 0, 0), V(0.25, 2.2, sz.Z + 0.5))
	return d
end

-- spec : { W, D, floors, theme, wall, wallMat, accent, name }
function K.build(parent, cf, spec, rng)
	local W, D, floors = spec.W, spec.D, spec.floors or 0
	local th = K.THEMES[spec.theme] or K.THEMES.toys
	local EXT, GH = K.EXT, K.GH
	local H = GH + floors * K.FH
	local wcol, wmat = spec.wall or rgb(236, 230, 218), spec.wallMat or M.Brick
	local accent = spec.accent or rgb(60, 130, 230)
	local model = Instance.new("Model")
	model.Name = spec.name or "Shop"
	local h = { cf = cf }
	local shell = Lib.model(model, "Shell")
	local inter = Lib.model(model, "Interior")
	local furn = Lib.model(model, "Furniture")
	local doors = Lib.model(model, "Doors")
	local xa, xb, za, zb = -W / 2 + EXT, W / 2 - EXT, EXT, D - EXT

	-- dalle et sol
	local found = box(h, shell, -W / 2, 0, 0, W / 2, 0.3, D, rgb(150, 146, 140), M.Concrete, false, { Name = "Foundation" })
	box(h, inter, xa, 0.3, za, xb, 0.36, zb, th.floor, th.floorMat, true)
	-- murs latéraux et arrière (rez-de-chaussée + étages)
	wall(h, shell, "z", 0, D, -W / 2 + EXT / 2, EXT, 0, H, {}, wcol, wmat)
	wall(h, shell, "z", 0, D, W / 2 - EXT / 2, EXT, 0, H, {}, wcol, wmat)
	wall(h, shell, "x", -W / 2 + EXT, W / 2 - EXT, D - EXT / 2, EXT, 0, H, {}, wcol, wmat)
	-- doublage intérieur (couleur du thème)
	for _, s in { -1, 1 } do
		box(h, inter, s * (W / 2 - EXT) - s * 0.1, 0.36, za, s * (W / 2 - EXT), GH, zb, th.wall, M.Plaster, true)
	end
	box(h, inter, xa, 0.36, zb - 0.1, xb, GH, zb, th.wall, M.Plaster, true)

	-- façade : soubassement, vitrines, double porte, imposte et bandeau d'enseigne
	local DW, DH = 7.2, 8.6
	local dx = spec.doorX or 0
	local holes = { { dx - DW / 2, dx + DW / 2, 0, DH + 0.3 } }
	-- vitrines de part et d'autre de la porte
	local winL = { xa + 1.2, dx - DW / 2 - 1.2 }
	local winR = { dx + DW / 2 + 1.2, xb - 1.2 }
	for _, wv in { winL, winR } do
		if wv[2] - wv[1] > 2 then
			table.insert(holes, { wv[1], wv[2], 2.2, 10 })
		end
	end
	wall(h, shell, "x", -W / 2 + EXT, W / 2 - EXT, EXT / 2, EXT, 0, H, holes, wcol, wmat)
	for _, wv in { winL, winR } do
		local len = wv[2] - wv[1]
		if len > 2 then
			local u = (wv[1] + wv[2]) / 2
			ax(h, shell, "x", u, 6.1, EXT / 2, len, 7.8, 0.2, GLASS, M.Glass, false, { Transparency = 0.4, Name = "Glass" })
			-- cadre aluminium et meneaux
			ax(h, shell, "x", u, 10.1, -0.05, len + 0.5, 0.3, 0.4, FRAME, M.Metal, true)
			ax(h, shell, "x", u, 2.1, -0.05, len + 0.5, 0.3, 0.6, FRAME, M.Metal, true)
			local n = math.max(1, math.floor(len / 6))
			for k = 0, n do
				ax(h, shell, "x", wv[1] + k * len / n, 6.1, -0.05, 0.3, 8, 0.4, FRAME, M.Metal, true)
			end
			-- allège en pierre côté rue
			ax(h, shell, "x", u, 1.1, -0.15, len + 0.6, 2.2, 0.3, rgb(120, 116, 110), M.Slate, true)
		end
	end
	-- encadrement de porte
	ax(h, shell, "x", dx - DW / 2 - 0.2, (DH + 0.3) / 2, -0.05, 0.4, DH + 0.3, EXT + 0.2, FRAME, M.Metal, true)
	ax(h, shell, "x", dx + DW / 2 + 0.2, (DH + 0.3) / 2, -0.05, 0.4, DH + 0.3, EXT + 0.2, FRAME, M.Metal, true)
	ax(h, shell, "x", dx, DH + 0.45, -0.05, DW + 0.8, 0.3, EXT + 0.2, FRAME, M.Metal, true)
	glassDoor(h, doors, dx - DW / 4, EXT / 2, DW / 2, DH, -1, "Porte du magasin")
	glassDoor(h, doors, dx + DW / 4, EXT / 2, DW / 2, DH, 1, "Porte du magasin")
	-- paillasson et seuil
	box(h, inter, dx - 3.5, 0.36, za, dx + 3.5, 0.4, za + 4, rgb(60, 56, 54), M.Fabric, true)
	box(h, shell, dx - 4, 0, -2.2, dx + 4, 0.3, 0, rgb(170, 166, 160), M.Concrete, false)
	-- bandeau d'enseigne et auvent
	local sg = ax(h, shell, "x", 0, GH - 0.9, -0.35, W * 0.78, 2.2, 0.3, accent, M.SmoothPlastic, true)
	Lib.label(sg, Enum.NormalId.Front, spec.label or "MAGASIN", WHITE, nil, Enum.Font.FredokaOne, true)
	local awn = Lib.part(shell, h.cf * CFrame.new(0, 10.6, -1.6) * CFrame.Angles(0, math.pi, 0), V(W - 1.5, 1.2, 3.2), accent, M.Fabric, { Class = "WedgePart", Name = "Awning", CanCollide = false, CanQuery = false, CanTouch = false })
	-- pilastres d'angle et corniche
	for _, s in { -1, 1 } do
		box(h, shell, s * W / 2 - 0.6, 0, -0.3, s * W / 2 + 0.6, H, 0.6, wcol:Lerp(Color3.new(0, 0, 0), 0.12), wmat, true)
	end
	box(h, shell, -W / 2 - 0.5, H, -0.6, W / 2 + 0.5, H + 1, D + 0.5, rgb(214, 210, 202), M.Concrete, false, { Name = "Cornice" })
	box(h, shell, -W / 2, H + 1, -0.3, W / 2, H + 2.4, 0.4, rgb(214, 210, 202), M.Concrete, true)
	-- appliques extérieures
	for _, s in { -1, 1 } do
		local lp = mk(h, shell, s * (W / 2 - 1.6), 9, -0.5, 0.6, 0.9, 0.6, rgb(255, 236, 190), M.Neon, true)
	end
	-- étages : plancher fermé + fenêtres teintées sur la façade
	if floors > 0 then
		box(h, shell, xa, GH, za, xb, GH + 0.8, zb, CEIL, M.SmoothPlastic, false, { Name = "Slab" })
		local n = math.max(1, math.floor(W / 8))
		for f = 1, floors do
			local yb = GH + (f - 1) * K.FH
			for k = 1, n do
				local u = -W / 2 + W / n * (k - 0.5)
				ax(h, shell, "x", u, yb + 4.4, -0.05, 3.6, 4.6, 0.3, rgb(70, 86, 98), M.Glass, true, { Transparency = 0.1, Reflectance = 0.2 })
				ax(h, shell, "x", u, yb + 4.4, -0.12, 4.2, 5.2, 0.15, WHITE, M.SmoothPlastic, true)
				ax(h, shell, "x", u, yb + 1.9, -0.3, 4.6, 0.3, 0.6, WHITE, M.SmoothPlastic, true)
			end
		end
	end
	-- plafond suspendu et éclairage
	box(h, inter, xa, GH - 0.2, za, xb, GH, zb, CEIL, M.SmoothPlastic, true, { Name = "Ceiling" })
	local nl = 0
	for z = 6, D - 4, 8 do
		for _, x in { -W / 4, W / 4 } do
			nl += 1
			ceilingLight(h, furn, x, GH - 0.2, z, (nl % 2 == 1))
		end
	end
	-- toit : climatiseurs
	for k = 1, 2 do
		box(h, shell, -4 + (k - 1) * 8, H + 1, D / 2 - 2, -1 + (k - 1) * 8, H + 3.4, D / 2 + 2, rgb(190, 194, 200), M.Metal, true)
	end

	---------------------------------------------------------------- réserve au fond
	local RZ = D - 9
	local rdx = xb - 4
	wall(h, inter, "x", xa, xb, RZ, 0.5, 0.36, GH - 0.56, { { rdx - 2, rdx + 2, 0, 7.5 } }, th.wall, M.Plaster)
	L.door(h, doors, "x", rdx, RZ, 0.36, 4, 7.5, 1, 1, WHITE, "Réserve", false)
	local sign = ax(h, inter, "x", rdx, 8.5, RZ - 0.3, 3.2, 0.9, 0.08, rgb(40, 120, 60), M.SmoothPlastic, true)
	Lib.label(sign, Enum.NormalId.Front, "RÉSERVE", WHITE, nil, Enum.Font.GothamBold)
	local F = L.F
	F.shelf(furn, h.cf * CFrame.new(xa + 4, 0.36, zb - 0.9) * CFrame.Angles(0, 0, 0))
	F.shelf(furn, h.cf * CFrame.new(xa + 11, 0.36, zb - 0.9))
	-- palette de cartons
	P(h, furn, CFrame.new(xa + 3, 0.6, RZ + 3), V(4, 0.5, 4), rgb(170, 130, 86), M.WoodPlanks, true)
	for i = 0, 3 do
		P(h, furn, CFrame.new(xa + 2.1 + (i % 2) * 1.8, 1.7 + math.floor(i / 2) * 1.6, RZ + 3), V(1.7, 1.5, 3.6), rgb(196, 150, 96), M.Cardboard, true)
	end
	local rl = Instance.new("PointLight")
	rl.Range, rl.Brightness, rl.Color, rl.Shadows = 16, 0.6, rgb(255, 246, 230), false
	rl.Parent = ceilingLight(h, furn, 0, GH - 0.2, (RZ + zb) / 2, false)

	---------------------------------------------------------------- surface de vente
	-- comptoir et caisse côté opposé à la porte, près de l'entrée
	local cs = dx >= 0 and -1 or 1
	local cw = 8
	local ccx = cs * (W / 2 - EXT - 3 - cw / 2) + (cs > 0 and 0 or 0)
	counter(h, furn, ccx, 8.5, cw, accent)
	-- présentoir derrière la caisse
	wallShelf(h, furn, cs * (W / 2 - EXT - 0.1), cs, 5, 12, th, rng)
	-- rayonnages muraux de l'autre côté
	wallShelf(h, furn, -cs * (W / 2 - EXT - 0.1), -cs, 4, RZ - 1, th, rng)
	wallShelf(h, furn, cs * (W / 2 - EXT - 0.1), cs, 15, RZ - 1, th, rng)
	-- gondoles centrales (allées de 4,5 studs minimum)
	local inner = W - 2 * EXT - 2 * 1.6 -- largeur entre rayonnages muraux
	local ng = math.max(1, math.floor((inner - 4.5) / (3.2 + 4.8)))
	local gz1, gz2 = 15, RZ - 4.5
	if th.laundry then
		-- laverie : machines en rangées
		for i = 0, math.floor((gz2 - gz1) / 3.4) - 1 do
			for _, s in { -1, 1 } do
				local x = -cs * 0 + s * 3
				P(h, furn, CFrame.new(x, 1.8, gz1 + i * 3.4 + 1.6), V(3, 3.6, 3), rgb(244, 244, 244), M.SmoothPlastic, true)
				P(h, furn, CFrame.new(x - s * 1.52, 2.1, gz1 + i * 3.4 + 1.6), V(0.06, 1.8, 1.8), rgb(110, 130, 150), M.Glass, false, { Transparency = 0.3 })
			end
		end
	elseif th.racks then
		-- vélos accrochés au mur (cadres simplifiés) et vélos posés au sol
		for i = 0, 3 do
			local z = gz1 + i * 4
			local col = th.products[i % #th.products + 1]
			for _, s in { -1, 1 } do
				P(h, furn, CFrame.new(s * 1.8, 1.5, z) * CFrame.Angles(0, 0, 0), V(0.3, 3, 0.3), rgb(40, 40, 44), M.Metal, false)
			end
			P(h, furn, CFrame.new(0, 2.4, z), V(3.4, 0.25, 0.25), col, M.Metal, false)
			for _, s in { -1, 1 } do
				Lib.cylDeco(furn, h.cf * CFrame.new(s * 2.2, 1.3, z) * CFrame.Angles(math.pi / 2, 0, 0), 0.2, 2.6, rgb(30, 30, 32), M.Rubber)
			end
		end
	else
		for i = 0, ng - 1 do
			local x = -inner / 2 + 4.5 + 1.6 + i * (inner - 9) / math.max(1, ng - 1)
			if ng == 1 then
				x = 0
			end
			gondola(h, furn, x, gz1, gz2, th, rng)
		end
	end
	-- table de présentation devant la vitrine (côté porte), produits vedettes
	local tx = -cs * (W / 4 + 1)
	if math.abs(tx - dx) > DW / 2 + 3 then
		P(h, furn, CFrame.new(tx, 1.4, 5), V(5, 2.8, 3), th.shelf:Lerp(Color3.new(0, 0, 0), 0.15), M.Wood, true)
		products(h, furn, tx, 2.8, 5, 4.6, 2.4, true, th, rng)
	end
	-- plantes et poubelle près de l'entrée
	L.F.plant(furn, h.cf * CFrame.new(dx + cs * -(DW / 2 + 1.6), 0.36, za + 1.4))

	model.PrimaryPart = found
	model:SetAttribute("ShopTheme", spec.theme or "")
	model.Parent = parent
	return model, { W = W, D = D, doorX = dx, H = H }
end

return K
