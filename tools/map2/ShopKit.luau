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
	hardware = { floor = rgb(150, 152, 156), floorMat = M.Concrete, wall = rgb(236, 236, 232), products = { rgb(250, 140, 20), rgb(60, 60, 64), rgb(200, 40, 40), rgb(40, 110, 200), rgb(220, 200, 60), rgb(150, 110, 70) }, shelf = rgb(70, 74, 80), aisles = { "OUTILS", "PEINTURE", "JARDIN", "VISSERIE", "BOIS", "PLOMBERIE" } },
	cinema = { floor = rgb(70, 30, 40), floorMat = M.Fabric, wall = rgb(60, 40, 70), products = { rgb(240, 200, 60), rgb(230, 50, 120), rgb(60, 140, 230) }, shelf = rgb(40, 30, 50), cinema = true },
	mall = { floor = rgb(226, 222, 214), floorMat = M.Marble, wall = rgb(244, 240, 234), products = { rgb(230, 70, 90), rgb(60, 130, 230), rgb(250, 190, 40), rgb(80, 170, 110), rgb(170, 90, 200), rgb(240, 240, 236) }, shelf = rgb(236, 236, 232), mall = true },
	restaurant = { floor = rgb(150, 104, 70), floorMat = M.WoodPlanks, wall = rgb(238, 222, 196), products = { rgb(220, 120, 40), rgb(200, 60, 40), rgb(80, 150, 70) }, shelf = rgb(120, 84, 58), restaurant = true },
	toys = { floor = rgb(214, 206, 192), floorMat = M.SmoothPlastic, wall = rgb(246, 240, 226), products = { rgb(230, 70, 60), rgb(60, 130, 230), rgb(250, 200, 40), rgb(70, 180, 90), rgb(240, 130, 200) }, shelf = rgb(236, 236, 232), balls = true, aisles = { "PELUCHES", "JEUX", "BALLONS", "VOITURES" } },
	phones = { floor = rgb(196, 198, 200), floorMat = M.SmoothPlastic, wall = rgb(238, 240, 242), products = { rgb(30, 32, 36), rgb(210, 212, 216), rgb(60, 70, 90), rgb(130, 80, 200) }, shelf = rgb(250, 250, 250), tables = true },
	bikes = { floor = rgb(120, 122, 126), floorMat = M.Concrete, wall = rgb(232, 230, 224), products = { rgb(200, 50, 50), rgb(40, 90, 160), rgb(30, 30, 34), rgb(240, 180, 40) }, shelf = rgb(70, 72, 78), racks = true },
	boxes = { floor = rgb(150, 120, 90), floorMat = M.WoodPlanks, wall = rgb(236, 226, 206), products = { rgb(196, 150, 96), rgb(176, 130, 80), rgb(214, 176, 120) }, shelf = rgb(150, 112, 76), productMat = M.Cardboard, aisles = { "CARTONS", "ADHÉSIFS", "EMBALLAGE" } },
	laundry = { floor = rgb(226, 230, 232), floorMat = M.CeramicTiles, wall = rgb(214, 236, 240), products = { rgb(240, 240, 240) }, shelf = rgb(240, 240, 240), laundry = true },
	grocery = { floor = rgb(220, 218, 212), floorMat = M.CeramicTiles, wall = rgb(244, 242, 236), products = { rgb(220, 60, 50), rgb(250, 200, 40), rgb(70, 160, 80), rgb(240, 130, 40), rgb(60, 110, 200), rgb(240, 240, 236) }, shelf = rgb(236, 236, 232), fridges = true, aisles = { "ÉPICERIE", "BOISSONS", "SNACKS", "PETIT-DÉJ", "CONSERVES", "HYGIÈNE", "PÂTES", "BÉBÉ" } },
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
		if th.balls and rng:NextNumber() < 0.22 then
			local d = math.min(w - 0.1, ht, depth, 1.1)
			local bc = alongX and CFrame.new(cx + x + w / 2, y + d / 2, cz) or CFrame.new(cx, y + d / 2, cz + x + w / 2)
			P(h, parent, bc, V(d, d, d), col, M.SmoothPlastic, false, { Shape = Enum.PartType.Ball })
		else
			P(h, parent, c, sz, col, th.productMat or M.SmoothPlastic, false)
		end
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

local function counter(h, parent, cx, cz, len, accent, alongZ)
	-- comptoir le long de Z (face client vers le centre du magasin)
	local function C(x, y, z, sx, sy, sz, col, mat, collide, extra)
		return P(h, parent, CFrame.new(cx + x, y, cz + z), alongZ and V(sz, sy, sx) or V(sx, sy, sz), col, mat, collide, extra)
	end
	local s = cx > 0 and -1 or 1 -- côté client (vers le centre)
	P(h, parent, CFrame.new(cx, 1.9, cz), V(2.6, 3.5, len), WHITE, M.SmoothPlastic, true)
	P(h, parent, CFrame.new(cx, 3.75, cz), V(2.9, 0.2, len + 0.3), rgb(70, 64, 58), M.Wood, false)
	P(h, parent, CFrame.new(cx + s * 1.31, 1.7, cz), V(0.04, 0.5, len), accent, M.SmoothPlastic, false)
	-- caisse enregistreuse, écran, terminal de paiement
	P(h, parent, CFrame.new(cx - s * 0.3, 4.15, cz - len / 4), V(1.2, 0.6, 1.6), rgb(40, 42, 46), M.SmoothPlastic, false)
	P(h, parent, CFrame.new(cx - s * 0.4, 4.95, cz - len / 4) * CFrame.Angles(0, s * math.pi / 2, 0) * CFrame.Angles(math.rad(-20), 0, 0), V(1.4, 1, 0.12), rgb(30, 32, 36), M.SmoothPlastic, false)
	P(h, parent, CFrame.new(cx - s * 0.33, 4.95, cz - len / 4) * CFrame.Angles(0, s * math.pi / 2, 0) * CFrame.Angles(math.rad(-20), 0, 0), V(1.2, 0.8, 0.02), rgb(90, 170, 220), M.Neon, false)
	P(h, parent, CFrame.new(cx + s * 0.6, 4.1, cz + len / 4), V(0.8, 0.5, 0.5), rgb(36, 38, 42), M.SmoothPlastic, false)
end

local function ceilingLight(h, parent, cx, y, cz, lit)
	local p = P(h, parent, CFrame.new(cx, y - 0.1, cz), V(2.4, 0.15, 6), rgb(255, 250, 238), M.Neon, false, { Transparency = 0.15 })
	if lit then
		local l = Instance.new("PointLight")
		l.Range = 22
		l.Brightness = 0.4
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


-- caisse de supermarché : tapis le long de Z, caissier côté +X
local function checkout(h, parent, cx, z1, len, accent)
	P(h, parent, CFrame.new(cx, 1.7, z1 + len / 2), V(1.8, 3.4, len), rgb(236, 236, 232), M.SmoothPlastic, true)
	P(h, parent, CFrame.new(cx, 3.45, z1 + len / 2 - 0.6), V(1.5, 0.1, len - 2), rgb(40, 40, 44), M.Rubber, false)
	P(h, parent, CFrame.new(cx + 0.3, 3.9, z1 + len - 0.9), V(1.1, 0.8, 1.2), rgb(40, 42, 46), M.SmoothPlastic, false)
	P(h, parent, CFrame.new(cx, 6.2, z1 + len - 0.9), V(0.15, 4, 0.15), rgb(90, 90, 96), M.Metal, false)
	local n = P(h, parent, CFrame.new(cx, 8.4, z1 + len - 0.9), V(0.25, 0.9, 1.2), accent, M.SmoothPlastic, false)
	return n
end

-- grand rayonnage industriel (bricolage) le long de Z
local function rack(h, parent, cx, z1, z2, th, rng)
	local len, cz = z2 - z1, (z1 + z2) / 2
	local ORANGE = rgb(240, 120, 20)
	for z = z1, z2 + 0.01, math.max(4, len / math.max(1, math.floor(len / 6))) do
		for _, s in { -1, 1 } do
			P(h, parent, CFrame.new(cx + s * 1.5, 5, z), V(0.3, 10, 0.3), rgb(40, 80, 160), M.Metal, true)
		end
	end
	for _, y in { 0.6, 3.6, 6.6, 9.6 } do
		for _, s in { -1, 1 } do
			P(h, parent, CFrame.new(cx + s * 1.5, y, cz), V(0.3, 0.4, len), ORANGE, M.Metal, false)
		end
		P(h, parent, CFrame.new(cx, y + 0.25, cz), V(3, 0.1, len), rgb(150, 120, 90), M.WoodPlanks, false)
		if y < 9 then
			local z = z1 + 0.3
			while z < z2 - 1 do
				local w = math.min(rng:NextNumber(1.2, 2.6), z2 - z - 0.3)
				local ht = rng:NextNumber(1, 2.4)
				P(h, parent, CFrame.new(cx, y + 0.3 + ht / 2, z + w / 2), V(2.6, ht, w - 0.15), rng:NextNumber() < 0.5 and rgb(196, 150, 96) or th.products[rng:NextInteger(1, #th.products)], rng:NextNumber() < 0.5 and M.Cardboard or M.SmoothPlastic, false)
				z += w
			end
		end
	end
	P(h, parent, CFrame.new(cx, 1.6, cz), V(2.7, 2, len), rgb(80, 80, 84), M.Metal, true)
end

-- intérieur des grandes surfaces (supermarché, bricolage, cinéma, centre commercial)
function K.bigInterior(c)
	local h, furn, inter, doors, th, spec, rng = c.h, c.furn, c.inter, c.doors, c.th, c.spec, c.rng
	local W, D, xa, xb, za, zb, GH, dx, DW, accent = c.W, c.D, c.xa, c.xb, c.za, c.zb, c.GH, c.dx, c.DW, c.accent
	local F = L.F
	local xin = W / 2 - K.EXT
	-- éclairage en grille
	local nl = 0
	for z = 6, D - 4, 9 do
		for x = -W / 2 + 8, W / 2 - 8, 14 do
			nl += 1
			ceilingLight(h, furn, x, GH - 0.2, z, (nl % 2 == 1))
		end
	end
	if th.mall then
		-- galerie intérieure : boutiques ouvertes (sans porte) de part et d'autre d'une allée centrale
		local BD = math.min(14, (D - 2 * K.EXT) / 2 - 6) -- profondeur d'une boutique
		local bw = 16
		local cols = th.products
		local names = { "MODE INVERSE", "CHAUSSURES GAUCHES", "LIBRAIRIE DU RETOUR", "PARFUMS PERDUS", "SPORT EN ARRIÈRE", "BIJOUX TORDUS", "MUSIQUE À L'ENVERS", "GOURMANDISES" }
		local k = 0
		for x = xa + 1, xb - bw - 0.5, bw do
			if math.abs(x + bw / 2 - dx) > DW / 2 + bw / 2 + 2 then
				-- rangée du fond seulement (le côté façade garde les vitrines vers l'extérieur)
				k += 1
				local z0 = zb - BD
				local col = cols[(k - 1) % #cols + 1]
				-- cloisons latérales
				box(h, inter, x, 0.36, z0, x + 0.4, GH - 0.2, zb, th.wall, M.Plaster, true)
				box(h, inter, x + bw - 0.4, 0.36, z0, x + bw, GH - 0.2, zb, th.wall, M.Plaster, true)
				-- imposte avec enseigne au-dessus de l'ouverture
				local sg = box(h, inter, x + 0.4, 9.4, z0 - 0.3, x + bw - 0.4, GH - 0.2, z0, col, M.SmoothPlastic, true)
				local lb = ax(h, inter, "x", x + bw / 2, 10.6, z0 - 0.4, bw - 2, 1.6, 0.1, col:Lerp(Color3.new(0, 0, 0), 0.2), M.SmoothPlastic, false)
				Lib.label(lb, Enum.NormalId.Front, names[(k - 1) % #names + 1], WHITE, nil, Enum.Font.FredokaOne, true)
				-- rayonnages au fond et présentoir central
				for _, y in { 1.2, 3.2, 5.2 } do
					P(h, furn, CFrame.new(x + bw / 2, y, zb - 0.9), V(bw - 2, 0.15, 1.2), rgb(236, 232, 226), M.Wood, false)
					products(h, furn, x + bw / 2, y + 0.08, zb - 0.9, bw - 2.4, 0.9, true, { products = { col, col:Lerp(WHITE, 0.4), rgb(60, 60, 64) } }, rng)
				end
				P(h, furn, CFrame.new(x + bw / 2, 1.5, z0 + BD / 2 - 1), V(4, 2.4, 2.4), rgb(236, 232, 226), M.Wood, true)
				products(h, furn, x + bw / 2, 2.7, z0 + BD / 2 - 1, 3.6, 2, true, { products = { col, col:Lerp(WHITE, 0.4) } }, rng)
				-- comptoir
				P(h, furn, CFrame.new(x + bw - 2.4, 1.8, z0 + 2.2), V(2.6, 3.4, 1.4), col, M.SmoothPlastic, true)
			end
		end
		-- atrium central : fontaine, bancs, plantes
		local az = (za + zb - BD) / 2 + 2
		Lib.cylDeco(furn, h.cf * CFrame.new(0, 1, az) * CFrame.Angles(0, 0, math.pi / 2), 1.3, 12, rgb(214, 210, 202), M.Marble)
		local water = Lib.cylDeco(furn, h.cf * CFrame.new(0, 1.55, az) * CFrame.Angles(0, 0, math.pi / 2), 0.2, 11, rgb(90, 160, 210), M.Glass)
		water.Transparency = 0.3
		Lib.cylDeco(furn, h.cf * CFrame.new(0, 3, az) * CFrame.Angles(0, 0, math.pi / 2), 3, 1.6, rgb(214, 210, 202), M.Marble)
		for _, sx in { -1, 1 } do
			for _, off in { 14, 30, 46 } do
				local bx = sx * off
				if math.abs(bx) < xin - 6 then
					P(h, furn, CFrame.new(bx, 1.2, az), V(6, 0.4, 2), rgb(120, 84, 58), M.Wood, true)
					P(h, furn, CFrame.new(bx, 0.75, az), V(5.4, 0.8, 1.4), rgb(80, 80, 84), M.Metal, false)
					F.plant(furn, h.cf * CFrame.new(bx + 5, 0.36, az))
				end
			end
		end
		return
	end
	-- cloison de réserve au fond
	local RZ = th.cinema and math.floor(D * 0.42) or (D - 12)
	local rdx = th.cinema and 0 or (xb - 5)
	local backName = th.cinema and "Salle 1" or "Réserve"
	wall(h, inter, "x", xa, xb, RZ, 0.5, 0.36, GH - 0.56, { { rdx - 2.5, rdx + 2.5, 0, 7.5 } }, th.wall, M.Plaster)
	L.door(h, doors, "x", rdx - 1.25, RZ, 0.36, 2.5, 7.5, 1, -1, th.cinema and rgb(120, 30, 40) or WHITE, backName, false)
	L.door(h, doors, "x", rdx + 1.25, RZ, 0.36, 2.5, 7.5, 1, 1, th.cinema and rgb(120, 30, 40) or WHITE, backName, false)
	local sign = ax(h, inter, "x", rdx, 8.6, RZ - 0.3, 4, 1, 0.08, th.cinema and accent or rgb(40, 120, 60), M.SmoothPlastic, true)
	Lib.label(sign, Enum.NormalId.Front, string.upper(backName), WHITE, nil, Enum.Font.GothamBold, true)
	if th.cinema then
		-- hall : comptoir confiserie parallèle à la façade, affiches, salle de projection au fond
		local cz = RZ - 6
		P(h, furn, CFrame.new(-W / 4, 1.9, cz), V(W * 0.3, 3.6, 2.6), accent, M.SmoothPlastic, true)
		P(h, furn, CFrame.new(-W / 4, 3.8, cz), V(W * 0.3 + 0.3, 0.2, 2.9), rgb(30, 30, 34), M.SmoothPlastic, false)
		for k = -1, 1 do
			P(h, furn, CFrame.new(-W / 4 + k * 5, 5, cz + 0.2), V(2.2, 2.2, 1.8), rgb(250, 240, 200), M.Glass, false, { Transparency = 0.3 })
			P(h, furn, CFrame.new(-W / 4 + k * 5, 4.5, cz + 0.2), V(2, 1, 1.6), rgb(250, 220, 120), M.SmoothPlastic, false)
		end
		local mb = ax(h, inter, "x", -W / 4, 8.6, RZ - 0.3, W * 0.28, 2.4, 0.1, rgb(20, 20, 24), M.SmoothPlastic, false)
		Lib.label(mb, Enum.NormalId.Front, "POP-CORN  BOISSONS  BONBONS", rgb(255, 210, 60), nil, Enum.Font.FredokaOne, true)
		for _, s in { -1, 1 } do
			for z = 6, RZ - 4, 7 do
				F.painting(furn, h.cf * CFrame.new(s * (xin - 0.15), 5.8, z) * CFrame.Angles(0, s > 0 and -math.pi / 2 or math.pi / 2, 0), 3.4, 5, th.products[rng:NextInteger(1, #th.products)])
			end
		end
		for x = W / 8, W / 2 - 8, 9 do
			P(h, furn, CFrame.new(x, 1.2, RZ / 2), V(6, 0.4, 2), rgb(120, 30, 40), M.Fabric, true)
			P(h, furn, CFrame.new(x, 0.75, RZ / 2), V(5.4, 0.8, 1.4), rgb(30, 30, 34), M.Metal, false)
		end
		-- salle : écran, gradins, fauteuils
		local SZ = zb - 0.4
		local scr = ax(h, inter, "x", 0, 6.6, SZ - 0.2, W * 0.7, 8.4, 0.1, rgb(250, 250, 250), M.Neon, false)
		scr.Transparency = 0.25
		local rows = math.floor((zb - 10 - (RZ + 6)) / 3.2)
		for r = 0, rows - 1 do
			local z = RZ + 6 + r * 3.2
			local step = math.max(0, (rows - 1 - r)) * 0.6
			if step > 0 then
				box(h, inter, xa + 4, 0.36, z - 1.6, xb - 4, 0.36 + step, z + 1.6, th.floor, M.Fabric, true)
			end
			for x = xa + 6, xb - 6, 2.4 do
				if math.abs(x) > 2.4 then
					P(h, furn, CFrame.new(x, 0.36 + step + 0.9, z), V(2.1, 1.2, 1.8), rgb(170, 30, 40), M.Fabric, true)
					P(h, furn, CFrame.new(x, 0.36 + step + 2.2, z - 0.8), V(2.1, 2, 0.4), rgb(150, 26, 36), M.Fabric, true)
				end
			end
		end
		return
	end
	-- réserve : étagères métalliques et palettes
	for x = xa + 4, xb - 12, 8 do
		F.shelf(furn, h.cf * CFrame.new(x, 0.36, zb - 0.9))
	end
	for k = 0, 2 do
		local px = xa + 6 + k * 7
		P(h, furn, CFrame.new(px, 0.6, RZ + 4), V(4, 0.5, 4), rgb(170, 130, 86), M.WoodPlanks, true)
		P(h, furn, CFrame.new(px, 2.1, RZ + 4), V(3.6, 2.6, 3.6), rgb(196, 150, 96), M.Cardboard, true)
	end
	-- caisses alignées près de l'entrée (côté opposé à la porte), allées de 3 studs
	local cs = dx >= 0 and -1 or 1
	local x1 = dx + cs * (DW / 2 + 5)
	local x2 = cs * (xin - 6)
	local lanes = 0
	for x = math.min(x1, x2), math.max(x1, x2), 5.5 do
		checkout(h, furn, x, 5, 7, accent)
		lanes += 1
	end
	-- caddies près de la porte
	for k = 0, 3 do
		local cx = dx - cs * (DW / 2 + 3)
		P(h, furn, CFrame.new(cx, 1.6, 4 + k * 1.1), V(2, 1.8, 2.6), rgb(200, 205, 210), M.DiamondPlate, true, { Transparency = 0.15 })
	end
	-- rayonnages muraux et zone de rayons
	wallShelf(h, furn, xin, 1, 16, RZ - 1, th, rng)
	wallShelf(h, furn, -xin, -1, 16, RZ - 1, th, rng)
	local gz1, gz2 = 17, RZ - (th.fridges and 7 or 4.5)
	local lo, hi = -(xin - 1.6 - 4.5), xin - 1.6 - 4.5
	local pitch = th.aisles == K.THEMES.hardware.aisles and (3 + 5) or (3.2 + 4.5)
	local ng = math.max(1, math.floor((hi - lo + 4.5) / pitch))
	for i = 0, ng - 1 do
		local x = ng == 1 and 0 or (lo + 1.6 + i * (hi - lo - 3.2) / (ng - 1))
		if spec.theme == "hardware" then
			rack(h, furn, x, gz1, gz2, th, rng)
		else
			gondola(h, furn, x, gz1, gz2, th, rng)
		end
		if th.aisles then
			local b = P(h, furn, CFrame.new(x, 10.4, gz1 - 0.5), V(4.6, 1.2, 0.12), accent, M.SmoothPlastic, false)
			Lib.label(b, Enum.NormalId.Front, th.aisles[(i % #th.aisles) + 1], WHITE, nil, Enum.Font.FredokaOne, true)
			Lib.label(b, Enum.NormalId.Back, th.aisles[(i % #th.aisles) + 1], WHITE, nil, Enum.Font.FredokaOne, true)
			P(h, furn, CFrame.new(x, 11.5, gz1 - 0.5), V(0.06, 1.4, 0.06), rgb(90, 90, 96), M.Metal, false)
		end
	end
	-- vitrines réfrigérées le long de la cloison de réserve
	if th.fridges then
		for x = xa + 3, rdx - 6, 4.2 do
			P(h, furn, CFrame.new(x + 2, 3.9, RZ - 1.8), V(4, 7.6, 2.8), rgb(230, 232, 236), M.SmoothPlastic, true)
			P(h, furn, CFrame.new(x + 2, 4.1, RZ - 3.25), V(3.6, 6.6, 0.1), rgb(190, 225, 240), M.Glass, false, { Transparency = 0.35 })
			for _, y in { 1.6, 3.4, 5.2 } do
				products(h, furn, x + 2, y, RZ - 2.2, 3.4, 1.4, true, th, rng)
			end
			P(h, furn, CFrame.new(x + 2, 7.5, RZ - 3.2), V(3.6, 0.15, 0.1), rgb(220, 240, 255), M.Neon, false)
		end
	end
	return lanes
end

-- spec : { W, D, floors, theme, wall, wallMat, accent, name, big, H, bigSign }
function K.build(parent, cf, spec, rng)
	local W, D, floors = spec.W, spec.D, spec.floors or 0
	local th = K.THEMES[spec.theme] or K.THEMES.toys
	local EXT, GH = K.EXT, K.GH
	local H = spec.H or (GH + floors * K.FH)
	if spec.H then
		floors = 0
	end
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
	-- joints de carrelage (grille de 4 studs)
	local seam = th.floor:Lerp(Color3.new(0, 0, 0), 0.14)
	for x = xa + 4, xb - 1, 4 do
		box(h, inter, x - 0.04, 0.36, za, x + 0.04, 0.37, zb, seam, M.SmoothPlastic, false)
	end
	for z = za + 4, zb - 1, 4 do
		box(h, inter, xa, 0.36, z - 0.04, xb, 0.37, z + 0.04, seam, M.SmoothPlastic, false)
	end
	-- plinthes et frise de couleur sur les murs intérieurs
	local skirt = th.wall:Lerp(Color3.new(0, 0, 0), 0.35)
	for _, s in { -1, 1 } do
		local xw = s * (W / 2 - EXT) - s * 0.1
		box(h, inter, xw - s * 0.12, 0.36, za, xw, 1.1, zb - 0.1, skirt, M.SmoothPlastic, false)
		box(h, inter, xw - s * 0.08, 9.2, za, xw, 9.6, zb - 0.1, spec.accent or rgb(60, 130, 230), M.SmoothPlastic, false)
	end
	box(h, inter, xa, 0.36, zb - 0.22, xb, 1.1, zb - 0.1, skirt, M.SmoothPlastic, false)

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
	if spec.H and spec.H > GH + 3 then
		-- grande surface : façade pleine au-dessus du rez-de-chaussée, grand fronton avec enseigne
		box(h, shell, xa, GH, za, xb, GH + 0.8, zb, CEIL, M.SmoothPlastic, false, { Name = "Slab" })
		ax(h, shell, "x", 0, H - 4, -0.8, W + 1, 8, 1.2, accent, M.SmoothPlastic, true, { Name = "Fascia" })
		local big = ax(h, shell, "x", 0, H - 4, -1.5, math.min(W * 0.6, 70), 6.5, 0.2, accent:Lerp(Color3.new(0, 0, 0), 0.15), M.SmoothPlastic, true)
		Lib.label(big, Enum.NormalId.Front, spec.label or "MAGASIN", WHITE, nil, Enum.Font.FredokaOne, true)
		ax(h, shell, "x", 0, GH + 0.6, -0.4, W - 1, 0.5, 0.6, rgb(214, 210, 202), M.Concrete, true)
	else
		local sg = ax(h, shell, "x", 0, 11.4, -0.35, W * 0.74, 1.8, 0.3, accent, M.SmoothPlastic, true)
		Lib.label(sg, Enum.NormalId.Front, spec.label or "MAGASIN", WHITE, nil, Enum.Font.FredokaOne, true)
	end
	local awW = spec.big and (DW + 10) or (W - 1.5)
	local awn = Lib.part(shell, h.cf * CFrame.new(spec.big and dx or 0, 9.75, -1.6) * CFrame.Angles(0, math.pi, 0), V(awW, 1.2, 3.2), accent, M.Fabric, { Class = "WedgePart", Name = "Awning", CanCollide = false, CanQuery = false, CanTouch = false })
	-- pilastres d'angle et corniche
	for _, s in { -1, 1 } do
		box(h, shell, s * W / 2 - 0.6, 0, -0.3, s * W / 2 + 0.6, H, 0.6, wcol:Lerp(Color3.new(0, 0, 0), 0.12), wmat, true)
	end
	box(h, shell, -W / 2 - 0.5, H, -0.6, W / 2 + 0.5, H + 1, D + 0.5, rgb(214, 210, 202), M.Concrete, false, { Name = "Cornice" })
	box(h, shell, -W / 2, H + 1, -0.3, W / 2, H + 2.4, 0.4, rgb(214, 210, 202), M.Concrete, true)
	-- appliques extérieures
	for _, s in { -1, 1 } do
		local lp = mk(h, shell, s * (W / 2 - 1.6), 11.4, -0.5, 0.6, 0.9, 0.6, rgb(255, 236, 190), M.Neon, true)
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
			if not spec.big then
				ceilingLight(h, furn, x, GH - 0.2, z, (nl % 2 == 1))
			end
		end
	end
	-- toit : climatiseurs
	for k = 1, 2 do
		box(h, shell, -4 + (k - 1) * 8, H + 1, D / 2 - 2, -1 + (k - 1) * 8, H + 3.4, D / 2 + 2, rgb(190, 194, 200), M.Metal, true)
	end

	if spec.big then
		K.bigInterior({ h = h, furn = furn, inter = inter, doors = doors, th = th, spec = spec, rng = rng, W = W, D = D, xa = xa, xb = xb, za = za, zb = zb, GH = GH, dx = dx, DW = DW, accent = accent })
	else
	---------------------------------------------------------------- réserve au fond
	local RZ = D - 9
	local rdx = xb - 4
	wall(h, inter, "x", xa, xb, RZ, 0.5, 0.36, GH - 0.56, { { rdx - 2, rdx + 2, 0, 7.5 } }, th.wall, M.Plaster)
	local backName = th.restaurant and "Cuisine" or "Réserve"
	L.door(h, doors, "x", rdx, RZ, 0.36, 4, 7.5, 1, 1, WHITE, backName, false)
	local sign = ax(h, inter, "x", rdx, 8.5, RZ - 0.3, 3.2, 0.9, 0.08, th.restaurant and rgb(170, 50, 40) or rgb(40, 120, 60), M.SmoothPlastic, true)
	Lib.label(sign, Enum.NormalId.Front, string.upper(backName == "Cuisine" and "CUISINE" or "RÉSERVE"), WHITE, nil, Enum.Font.GothamBold)
	local F = L.F
	if th.restaurant then
		-- cuisine professionnelle : plans de travail inox le long du fond, fourneau + hotte, frigo, plonge, table de préparation
		local STEEL, DARK = rgb(196, 200, 204), rgb(40, 40, 44)
		local kz = zb - 1.4
		P(h, furn, CFrame.new((xa + xb) / 2 - 2, 1.8, kz), V(xb - xa - 8, 3.5, 2.6), STEEL, M.Metal, true)
		P(h, furn, CFrame.new((xa + xb) / 2 - 2, 3.6, kz), V(xb - xa - 8, 0.12, 2.7), rgb(214, 218, 222), M.DiamondPlate, false)
		-- fourneau
		local sx = xa + 6
		P(h, furn, CFrame.new(sx, 1.8, kz), V(5, 3.6, 2.7), DARK, M.Metal, true)
		for _, o in { { -1.2, -0.6 }, { 1.2, -0.6 }, { -1.2, 0.6 }, { 1.2, 0.6 } } do
			P(h, furn, CFrame.new(sx + o[1], 3.63, kz + o[2]), V(1, 0.06, 1), rgb(70, 70, 74), M.Metal, false)
		end
		P(h, furn, CFrame.new(sx, 8.6, kz - 0.2), V(6, 1.6, 3.2), STEEL, M.Metal, false)
		P(h, furn, CFrame.new(sx, 10.8, kz + 0.6), V(1.6, 2.8, 1.6), STEEL, M.Metal, false)
		-- plonge
		local px = (xa + xb) / 2 + 2
		P(h, furn, CFrame.new(px, 3.5, kz), V(3, 0.2, 1.8), rgb(120, 126, 132), M.Metal, false)
		P(h, furn, CFrame.new(px, 4.4, kz + 1), V(0.2, 1.6, 0.2), STEEL, M.Metal, false)
		-- frigo double
		P(h, furn, CFrame.new(xb - 2.4, 3.9, kz - 0.1), V(4, 7.8, 2.8), STEEL, M.Metal, true)
		P(h, furn, CFrame.new(xb - 2.4, 3.9, kz - 1.53), V(0.06, 7.4, 0.06), DARK, M.Metal, false)
		for _, o in { -0.5, 0.5 } do
			P(h, furn, CFrame.new(xb - 2.4 + o, 4.3, kz - 1.62), V(0.12, 1.6, 0.12), DARK, M.Metal, false)
		end
		-- étagère murale et casseroles
		P(h, furn, CFrame.new((xa + xb) / 2, 6.2, zb - 0.6), V(10, 0.15, 1.2), STEEL, M.Metal, false)
		for k = -2, 2 do
			Lib.cylDeco(furn, h.cf * CFrame.new((xa + xb) / 2 + k * 1.9, 6.75, zb - 0.6) * CFrame.Angles(0, 0, math.pi / 2), 0.5, 0.9, STEEL, M.Metal)
		end
		-- table de préparation centrale (passage de 3 studs autour)
		local tz = (RZ + kz - 1.3) / 2
		if kz - 1.3 - RZ > 5.5 then
			P(h, furn, CFrame.new(xa + 7, 3.4, tz), V(5, 0.15, 2), STEEL, M.Metal, true)
			P(h, furn, CFrame.new(xa + 7, 1.7, tz), V(4.6, 0.12, 1.6), STEEL, M.Metal, false)
			for _, ox in { -2.2, 2.2 } do
				for _, oz in { -0.8, 0.8 } do
					P(h, furn, CFrame.new(xa + 7 + ox, 1.7, tz + oz), V(0.15, 3.3, 0.15), STEEL, M.Metal, false)
				end
			end
		end
	else
		F.shelf(furn, h.cf * CFrame.new(xa + 4, 0.36, zb - 0.9) * CFrame.Angles(0, 0, 0))
		F.shelf(furn, h.cf * CFrame.new(xa + 11, 0.36, zb - 0.9))
		-- palette de cartons
		P(h, furn, CFrame.new(xa + 3, 0.6, RZ + 3), V(4, 0.5, 4), rgb(170, 130, 86), M.WoodPlanks, true)
		for i = 0, 3 do
			P(h, furn, CFrame.new(xa + 2.1 + (i % 2) * 1.8, 1.7 + math.floor(i / 2) * 1.6, RZ + 3), V(1.7, 1.5, 3.6), rgb(196, 150, 96), M.Cardboard, true)
		end
	end
	local rl = Instance.new("PointLight")
	rl.Range, rl.Brightness, rl.Color, rl.Shadows = 14, 0.3, rgb(255, 246, 230), false
	rl.Parent = ceilingLight(h, furn, 0, GH - 0.2, (RZ + zb) / 2, false)

	---------------------------------------------------------------- surface de vente
	-- comptoir perpendiculaire à la façade, côté opposé à la porte, avec présentoir mural derrière
	local cs = dx >= 0 and -1 or 1
	local xin = W / 2 - EXT -- face intérieure des murs latéraux
	local cl = math.min(9, RZ - 9)
	local ccx = cs * (xin - 1.6 - 2.6 - 1.3)
	counter(h, furn, ccx, 4.5 + cl / 2, cl, accent, true)
	if th.restaurant then
		-- tableau-menu derrière le comptoir, vitrine réfrigérée sur le comptoir
		local mb = P(h, furn, CFrame.new(cs * (xin - 0.08), 7, 4.5 + cl / 2) * CFrame.Angles(0, cs > 0 and -math.pi / 2 or math.pi / 2, 0), V(cl - 1, 3.6, 0.12), rgb(32, 30, 30), M.Slate, false)
		Lib.label(mb, Enum.NormalId.Front, "MENU\nTACO SENS UNIQUE  4€\nBURRITO DEMI-TOUR  6€\nNACHOS RAPPEL  3€", rgb(250, 230, 170), nil, Enum.Font.FredokaOne, true)
		P(h, furn, CFrame.new(cs * (xin - 0.8), 1.8, 4.5 + cl / 2), V(1.6, 3.5, cl - 1), rgb(196, 200, 204), M.Metal, true)
		P(h, furn, CFrame.new(ccx, 4.6, 4.5 + cl * 0.7), V(2.2, 1.5, cl * 0.35), rgb(190, 220, 230), M.Glass, false, { Transparency = 0.4 })
		-- tableaux sur le mur opposé
		local wx = -cs * (xin - 0.12)
		for z = 6, RZ - 4, 6 do
			F.painting(furn, h.cf * CFrame.new(wx, 6.4, z) * CFrame.Angles(0, -cs > 0 and -math.pi / 2 or math.pi / 2, 0), 3.2, 2.4, th.products[rng:NextInteger(1, #th.products)])
		end
	else
		wallShelf(h, furn, cs * xin, cs, 4, 4.5 + cl + 0.5, th, rng)
		if RZ - 1 - (5.5 + cl) > 3 then
			wallShelf(h, furn, cs * xin, cs, 5.5 + cl, RZ - 1, th, rng)
		end
		-- rayonnage mural de l'autre côté
		wallShelf(h, furn, -cs * xin, -cs, 4, RZ - 1, th, rng)
	end
	-- zone centrale : gondoles avec allées d'au moins 4,5 studs
	local zx1 = -cs > 0 and (xin - 1.6 - 4.5) or -(xin - 1.6 - 4.5) -- bord côté rayonnage mural opposé
	local zx2 = ccx - cs * (1.3 + 4.5) -- bord côté comptoir
	local lo, hi = math.min(zx1, zx2), math.max(zx1, zx2)
	local gz1, gz2 = 7, RZ - 4.5
	if th.restaurant then
		-- salle : tables de 4 avec allées de 3 studs, suspensions au-dessus
		local zxw = -cs * (xin - 0.3)
		local x1, x2 = math.min(zxw, ccx - cs * (1.3 + 4)), math.max(zxw, ccx - cs * (1.3 + 4))
		local cellX, cellZ = 6.5, 7 -- tables de 2 (chaises dos à dos entre rangées), allées de 3,5 studs entre colonnes
		local nx = math.max(1, math.floor((x2 - x1) / cellX))
		local nz = math.max(1, math.floor((RZ - 1.5 - 5.5) / cellZ))
		for ix = 0, nx - 1 do
			for iz = 0, nz - 1 do
				local tx = x1 + (x2 - x1) * (ix + 0.5) / nx
				local tz = 5.5 + (RZ - 1.5 - 5.5) * (iz + 0.5) / nz
				local b = h.cf * CFrame.new(tx, 0.36, tz)
				F.table(furn, b, 3, 3)
				for _, k in { 0, 2 } do
					local a = k * math.pi / 2
					F.chair(furn, b * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -2.4) * CFrame.Angles(0, math.pi, 0), accent)
				end
				local lamp = P(h, furn, CFrame.new(tx, 9.4, tz), V(1.6, 0.8, 1.6), accent, M.SmoothPlastic, false)
				P(h, furn, CFrame.new(tx, 9.0, tz), V(1.1, 0.06, 1.1), rgb(255, 236, 190), M.Neon, false)
				P(h, furn, CFrame.new(tx, 11.0, tz), V(0.06, 2.6, 0.06), rgb(40, 40, 44), M.Metal, false)
				if (ix + iz) % 2 == 0 then
					local pl = Instance.new("PointLight")
					pl.Range, pl.Brightness, pl.Color, pl.Shadows = 13, 0.35, rgb(255, 226, 180), false
					pl.Parent = lamp
				end
			end
		end
	elseif th.laundry then
		-- laverie : rangée double de machines au centre, bancs le long du mur
		local cxm = (lo + hi) / 2
		for z = gz1, gz2 - 3, 3.4 do
			for _, s in { -1, 1 } do
				local x = cxm + s * 1.55
				P(h, furn, CFrame.new(x, 1.8, z + 1.6), V(3, 3.6, 3), rgb(244, 244, 244), M.SmoothPlastic, true)
				P(h, furn, CFrame.new(x + s * 1.52, 2.1, z + 1.6), V(0.06, 1.8, 1.8), rgb(110, 130, 150), M.Glass, false, { Transparency = 0.3 })
				P(h, furn, CFrame.new(x + s * 1.53, 3.3, z + 2.5), V(0.05, 0.3, 0.5), rgb(60, 200, 120), M.Neon, false)
			end
		end
	elseif th.racks then
		-- vélos exposés en rangée au centre
		local cxm = (lo + hi) / 2
		for z = gz1, gz2 - 2, 3 do
			local col = th.products[rng:NextInteger(1, #th.products)]
			local b = h.cf * CFrame.new(cxm, 0.36, z + 1) * CFrame.Angles(0, math.pi / 2, 0)
			Lib.part(furn, b * CFrame.new(0, 2.3, 0), V(3.2, 0.25, 0.25), col, M.Metal, props(true))
			Lib.part(furn, b * CFrame.new(1.2, 1.7, 0) * CFrame.Angles(0, 0, math.rad(60)), V(1.6, 0.22, 0.22), col, M.Metal, props(true))
			Lib.part(furn, b * CFrame.new(-1.3, 2.9, 0), V(0.2, 1.2, 0.2), rgb(40, 40, 44), M.Metal, props(true))
			Lib.part(furn, b * CFrame.new(1.4, 3, 0), V(0.25, 0.2, 1.6), rgb(40, 40, 44), M.Metal, props(true))
			for _, s2 in { -1, 1 } do
				Lib.cylDeco(furn, b * CFrame.new(s2 * 1.7, 1.25, 0) * CFrame.Angles(math.pi / 2, 0, 0), 0.25, 2.5, rgb(30, 30, 32), M.Rubber)
			end
			P(h, furn, CFrame.new(cxm, 0.8, z + 1), V(0.6, 0.9, 3.8), rgb(80, 82, 88), M.Metal, true)
		end
	elseif th.tables then
		-- tables d'exposition (téléphones) en îlots
		local cxm = (lo + hi) / 2
		for z = gz1 + 2, gz2 - 2, 6 do
			P(h, furn, CFrame.new(cxm, 1.7, z), V(4, 3.4, 3), rgb(236, 232, 226), M.Wood, true)
			for k = -1, 1 do
				for _, s2 in { -1, 1 } do
					P(h, furn, CFrame.new(cxm + k * 1.2, 3.47, z + s2 * 0.8), V(0.5, 0.06, 0.9), th.products[rng:NextInteger(1, #th.products)], M.SmoothPlastic, false)
				end
			end
		end
	else
		local ng = math.max(1, math.floor((hi - lo + 4.5) / (3.2 + 4.5)))
		for i = 0, ng - 1 do
			local x = ng == 1 and (lo + hi) / 2 or (lo + 1.6 + i * (hi - lo - 3.2) / (ng - 1))
			gondola(h, furn, x, gz1, gz2, th, rng)
			if th.aisles then
				local sz = (gz1 + gz2) / 2
				local name = th.aisles[(i % #th.aisles) + 1]
				local b = P(h, furn, CFrame.new(x, 9.3, sz), V(4.2, 1.1, 0.12), spec.accent or rgb(60, 130, 230), M.SmoothPlastic, false)
				Lib.label(b, Enum.NormalId.Front, name, WHITE, nil, Enum.Font.FredokaOne, true)
				Lib.label(b, Enum.NormalId.Back, name, WHITE, nil, Enum.Font.FredokaOne, true)
				for _, o in { -1.8, 1.8 } do
					P(h, furn, CFrame.new(x + o, 11.08, sz), V(0.06, 2.45, 0.06), rgb(90, 90, 96), M.Metal, false)
				end
			end
		end
	end
	-- podiums de vitrine (derrière le verre, hors passage de la porte)
	for _, wv in { winL, winR } do
		local x1, x2 = wv[1] + 0.3, wv[2] - 0.3
		if wv[2] <= dx then
			x2 = math.min(x2, dx - DW / 2 - 1.5)
		else
			x1 = math.max(x1, dx + DW / 2 + 1.5)
		end
		-- pas de podium devant le comptoir
		if cs * ((x1 + x2) / 2) > 0 then
			x2 = cs > 0 and math.min(x2, ccx - 1.3 - 1) or x2
			x1 = cs < 0 and math.max(x1, ccx + 1.3 + 1) or x1
		end
		if x2 - x1 > 2.5 and not th.restaurant then
			P(h, furn, CFrame.new((x1 + x2) / 2, 0.85, 2.1), V(x2 - x1, 1, 2.2), th.shelf:Lerp(Color3.new(0, 0, 0), 0.1), M.Wood, true)
			products(h, furn, (x1 + x2) / 2, 1.35, 2.1, x2 - x1 - 0.4, 1.6, true, th, rng)
		end
	end
	-- plante près de l'entrée
	L.F.plant(furn, h.cf * CFrame.new(dx - cs * (DW / 2 + 1.6), 0.36, za + 4.2))

	end
	model.PrimaryPart = found
	model:SetAttribute("ShopTheme", spec.theme or "")
	model.Parent = parent
	return model, { W = W, D = D, doorX = dx, H = H }
end

return K
