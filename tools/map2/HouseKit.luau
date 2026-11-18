--!nolint
-- Kit de maisons en pièces, à l'échelle des personnages Roblox (R15 ≈ 5,2 studs de haut) :
--   porte d'entrée 4,5 x 8, portes intérieures 4 x 7,5, plafond 11,2, étage 12, marches 1 (hauteur) x 1,2,
--   escalier 4,5 de large, couloirs 5,5, fenêtres 4 x 5,4 (allège 3,2), garage 12 x 10,8 avec porte basculante.
-- Chaque maison a un intérieur meublé et des portes à charnière (modèles "Door", tag WWD_Door) animées par
-- le script serveur ServerScriptService.HouseDoors (ProximityPrompt "Ouvrir" / "Fermer").
-- Repère d'une maison : origine au milieu de la façade, au sol ; -Z vers la rue, +Z vers le fond, +X à gauche vu de la rue.
local Lib = require(script.Parent.Lib)
local V, rgb, M = Lib.V, Lib.rgb, Lib.M
local CS = game:GetService("CollectionService")

local K = {
	FH = 12, SLAB = 0.8, Y0 = 1, EXT = 0.8, OUT = 0.45, INT = 0.5,
	DOOR_W = 4.5, DOOR_H = 8, IDOOR_W = 4, IDOOR_H = 7.5,
	RISE = 1, RUN = 1.2, STAIR_W = 4.5, HALL = 5.5,
	GARAGE_H = 10.8, LIGHTS = true,
}

local WHITE = rgb(242, 240, 234)
local CEIL = rgb(244, 242, 238)
local GLASS = rgb(170, 198, 212)
local DARK = rgb(52, 54, 58)

-- Palettes : couleurs naturelles (blanc cassé, beige, gris, brique, bois), toitures gris foncé ou brunes
K.PAL = {
	white = { wall = rgb(236, 234, 226), mat = M.WoodPlanks, roof = rgb(68, 70, 74), trim = WHITE, door = rgb(112, 78, 52), shutter = rgb(62, 66, 70), garage = WHITE, inside = rgb(238, 234, 226), floor = rgb(170, 128, 90) },
	beige = { wall = rgb(214, 198, 170), mat = M.WoodPlanks, roof = rgb(96, 74, 58), trim = WHITE, door = rgb(86, 60, 42), shutter = rgb(110, 84, 62), garage = WHITE, inside = rgb(236, 230, 218), floor = rgb(156, 114, 80) },
	grey = { wall = rgb(188, 192, 194), mat = M.WoodPlanks, roof = rgb(56, 58, 62), trim = WHITE, door = rgb(150, 106, 68), garage = WHITE, inside = rgb(232, 232, 228), floor = rgb(176, 140, 104) },
	taupe = { wall = rgb(166, 152, 134), mat = M.WoodPlanks, roof = rgb(60, 60, 62), trim = rgb(236, 232, 222), door = rgb(70, 72, 74), garage = rgb(236, 232, 222), inside = rgb(234, 228, 216), floor = rgb(150, 110, 76) },
	brick = { wall = rgb(150, 76, 60), mat = M.Brick, roof = rgb(58, 58, 60), trim = WHITE, door = rgb(62, 64, 66), garage = WHITE, inside = rgb(238, 234, 226), floor = rgb(160, 118, 84) },
	brownbrick = { wall = rgb(122, 88, 70), mat = M.Brick, roof = rgb(82, 64, 54), trim = rgb(232, 224, 206), door = WHITE, garage = rgb(232, 224, 206), inside = rgb(234, 228, 214), floor = rgb(146, 106, 74) },
	brickup = { wall = rgb(144, 78, 62), mat = M.Brick, upper = rgb(232, 228, 216), upperMat = M.WoodPlanks, roof = rgb(62, 62, 64), trim = WHITE, door = rgb(64, 66, 68), shutter = rgb(60, 64, 68), garage = WHITE, inside = rgb(238, 234, 226), floor = rgb(166, 124, 88) },
	wood = { wall = rgb(168, 126, 86), mat = M.WoodPlanks, roof = rgb(70, 66, 62), trim = rgb(232, 226, 212), door = rgb(232, 226, 212), garage = rgb(232, 226, 212), inside = rgb(236, 230, 216), floor = rgb(150, 108, 72) },
	stucco = { wall = rgb(230, 222, 204), mat = M.Plaster, roof = rgb(140, 84, 62), roofMat = M.ClayRoofTiles, trim = rgb(246, 242, 232), door = rgb(96, 66, 44), garage = rgb(120, 86, 58), inside = rgb(240, 234, 222), floor = rgb(200, 188, 168), floorMat = M.Limestone },
	stone = { wall = rgb(196, 186, 168), mat = M.Limestone, upper = rgb(236, 232, 222), upperMat = M.Plaster, roof = rgb(58, 60, 64), trim = WHITE, door = rgb(76, 54, 40), garage = WHITE, inside = rgb(238, 234, 224), floor = rgb(162, 120, 84) },
	modernwhite = { wall = rgb(238, 238, 234), mat = M.Plaster, accent = rgb(84, 88, 92), accentMat = M.Plaster, wood = rgb(164, 118, 78), roof = rgb(72, 74, 78), trim = rgb(48, 50, 54), frame = rgb(42, 44, 48), door = rgb(150, 108, 70), garage = rgb(84, 88, 92), inside = rgb(242, 242, 238), floor = rgb(196, 170, 136), modern = true },
	moderngrey = { wall = rgb(184, 184, 180), mat = M.Concrete, accent = rgb(238, 236, 230), accentMat = M.Plaster, wood = rgb(150, 106, 68), roof = rgb(64, 66, 70), trim = rgb(48, 50, 54), frame = rgb(42, 44, 48), door = rgb(42, 44, 48), garage = rgb(150, 106, 68), inside = rgb(238, 238, 234), floor = rgb(180, 152, 118), modern = true },
	modernwood = { wall = rgb(90, 94, 98), mat = M.Plaster, accent = rgb(170, 124, 82), accentMat = M.WoodPlanks, wood = rgb(170, 124, 82), roof = rgb(60, 62, 66), trim = rgb(40, 42, 46), frame = rgb(36, 38, 42), door = rgb(170, 124, 82), garage = rgb(60, 62, 66), inside = rgb(240, 238, 232), floor = rgb(186, 156, 118), modern = true },
}

---------------------------------------------------------------- géométrie de base (repère de la maison)
local function props(deco, extra)
	local p = {}
	if extra then
		for k, v in extra do
			p[k] = v
		end
	end
	if deco then
		p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = false, false, false, false
	end
	return p
end

local function mk(h, parent, cx, cy, cz, sx, sy, sz, col, mat, deco, extra)
	if sx < 0.04 or sy < 0.04 or sz < 0.04 then
		return nil
	end
	return Lib.part(parent, h.cf * CFrame.new(cx, cy, cz), V(sx, sy, sz), col, mat or M.SmoothPlastic, props(deco, extra))
end

local function box(h, parent, x1, y1, z1, x2, y2, z2, col, mat, deco, extra)
	if x2 < x1 then
		x1, x2 = x2, x1
	end
	if y2 < y1 then
		y1, y2 = y2, y1
	end
	if z2 < z1 then
		z1, z2 = z2, z1
	end
	return mk(h, parent, (x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2, x2 - x1, y2 - y1, z2 - z1, col, mat, deco, extra)
end

-- pièce positionnée le long d'un mur : u le long du mur, n perpendiculaire
local function ax(h, parent, axis, u, y, n, su, sy, sn, col, mat, deco, extra)
	if axis == "x" then
		return mk(h, parent, u, y, n, su, sy, sn, col, mat, deco, extra)
	end
	return mk(h, parent, n, y, u, sn, sy, su, col, mat, deco, extra)
end

-- mur droit le long de X (centré en z = c) ou de Z (centré en x = c), de a à b, troué (holes = { u1, u2, v1, v2 })
local function wall(h, parent, axis, a, b, c, t, yb, ht, holes, col, mat)
	local function seg(u1, u2, v1, v2)
		if u2 - u1 < 0.04 or v2 - v1 < 0.04 then
			return
		end
		if axis == "x" then
			box(h, parent, u1, yb + v1, c - t / 2, u2, yb + v2, c + t / 2, col, mat, false, { Name = "Wall" })
		else
			box(h, parent, c - t / 2, yb + v1, u1, c + t / 2, yb + v2, u2, col, mat, false, { Name = "Wall" })
		end
	end
	local hs = {}
	for _, o in holes or {} do
		if o[2] > a and o[1] < b then
			table.insert(hs, { math.max(a, o[1]), math.min(b, o[2]), math.max(0, o[3]), math.min(ht, o[4]) })
		end
	end
	table.sort(hs, function(p, q)
		return p[1] < q[1]
	end)
	local cur = a
	for _, o in hs do
		seg(cur, o[1], 0, ht)
		seg(math.max(cur, o[1]), o[2], 0, o[3])
		seg(math.max(cur, o[1]), o[2], o[4], ht)
		cur = math.max(cur, o[2])
	end
	seg(cur, b, 0, ht)
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

local function prompt(parent, object, dist)
	local att = Instance.new("Attachment")
	att.Parent = parent
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = "Ouvrir"
	pr.ObjectText = object
	pr.HoldDuration = 0
	pr.MaxActivationDistance = dist or 8
	pr.RequiresLineOfSight = true
	pr.KeyboardKeyCode = Enum.KeyCode.E
	pr.Parent = att
	return pr
end

local MOVING = { Anchored = false, Massless = true, CanTouch = false }

-- porte à charnière verticale. axis : direction du mur ; u : centre de la baie le long du mur ; c : centre du mur ;
-- swing : côté (±1, perpendiculaire au mur) vers lequel elle s'ouvre ; hinge : extrémité (±1) portant la charnière
local function hingedDoor(h, parent, axis, u, c, yb, w, ht, swing, hinge, col, label, front)
	local d = Instance.new("Model")
	d.Name = "Door"
	local hu = u + hinge * (w / 2 - 0.05)
	local hl = axis == "x" and V(hu, yb + ht / 2, c) or V(c, yb + ht / 2, hu)
	local hp = Lib.part(d, h.cf * CFrame.new(hl), V(0.2, 0.2, 0.2), col, M.SmoothPlastic, { Name = "Hinge", Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	local off = -hinge * (w / 2 - 0.05)
	local pw, ph, pt = w - 0.2, ht - 0.12, 0.3
	local function rel(du, dy, dn, su, sy, sn, colr, mat, collide, extra)
		local p = props(not collide, extra)
		for k, v in MOVING do
			p[k] = v
		end
		local lp = axis == "x" and V(hu + du, yb + ht / 2 + dy, c + dn) or V(c + dn, yb + ht / 2 + dy, hu + du)
		local sz = axis == "x" and V(su, sy, sn) or V(sn, sy, su)
		local part = Lib.part(d, h.cf * CFrame.new(lp), sz, colr, mat, p)
		weld(hp, part)
		return part
	end
	local panel = rel(off, 0.03, 0, pw, ph, pt, col, front and M.Wood or M.SmoothPlastic, true, { Name = "Panel" })
	-- moulures (deux panneaux) des deux côtés, poignées
	local mould = col:Lerp(Color3.new(0, 0, 0), 0.12)
	for _, s in { -1, 1 } do
		local n = s * (pt / 2 + 0.03)
		rel(off, ht * 0.2, n, pw - 1.2, ht * 0.32, 0.06, mould, M.SmoothPlastic, false)
		rel(off, -ht * 0.2, n, pw - 1.2, ht * 0.32, 0.06, mould, M.SmoothPlastic, false)
		rel(off * 2 + hinge * 0.6, -ht / 2 + 3.4, s * (pt / 2 + 0.15), 0.3, 0.3, 0.3, rgb(196, 176, 120), M.Metal, false, { Shape = Enum.PartType.Ball })
	end
	if front then
		rel(off, ht * 0.2, -pt / 2 - 0.05, pw - 1.8, ht * 0.22, 0.04, GLASS, M.Glass, false, { Transparency = 0.3 })
	end
	local theta
	if axis == "x" then
		theta = -swing * math.sign(off) * 90
	else
		theta = swing * math.sign(off) * 90
	end
	d:SetAttribute("OpenAngle", theta)
	d:SetAttribute("Axis", "Y")
	d:SetAttribute("Open", false)
	prompt(panel, label, 8)
	d.PrimaryPart = hp
	d.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	CS:AddTag(d, "WWD_Door")
	d.Parent = parent
	return d
end

-- porte de garage basculante : charnière en haut de la baie (axe X), s'escamote à l'horizontale sous le plafond
local function garageDoor(h, parent, u, c, yTop, w, ht, swing, col)
	local d = Instance.new("Model")
	d.Name = "GarageDoor"
	local hl = V(u, yTop, c)
	local hp = Lib.part(d, h.cf * CFrame.new(hl), V(0.2, 0.2, 0.2), col, M.SmoothPlastic, { Name = "Hinge", Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	local function rel(dx, dy, dz, sx, sy, sz, colr, mat, collide, extra)
		local p = props(not collide, extra)
		for k, v in MOVING do
			p[k] = v
		end
		local part = Lib.part(d, h.cf * CFrame.new(hl + V(dx, dy, dz)), V(sx, sy, sz), colr, mat, p)
		weld(hp, part)
		return part
	end
	local panel = rel(0, -ht / 2 - 0.05, 0, w - 0.2, ht - 0.1, 0.35, col, M.SmoothPlastic, true, { Name = "Panel" })
	local groove = col:Lerp(Color3.new(0, 0, 0), 0.15)
	for k = 1, 3 do
		rel(0, -ht * k / 4, -swing * 0.2, w - 0.4, 0.12, 0.05, groove, M.SmoothPlastic, false)
	end
	rel(0, -ht * 0.17, -swing * 0.2, w - 1.6, 0.9, 0.04, GLASS, M.Glass, false, { Transparency = 0.25 })
	d:SetAttribute("OpenAngle", -swing * 88)
	d:SetAttribute("Axis", "X")
	d:SetAttribute("Open", false)
	local pr = prompt(panel, "Garage", 10)
	pr.Parent.Position = V(0, -ht / 2 + 4, 0)
	d.PrimaryPart = hp
	d.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	CS:AddTag(d, "WWD_Door")
	d.Parent = parent
	return d
end

-- encadrement de baie (chambranle) sur les deux faces d'un mur
local function doorTrim(h, parent, axis, u, c, t, yb, w, ht, col, sides)
	for _, s in sides or { -1, 1 } do
		local n = c + s * (t / 2 + 0.06)
		ax(h, parent, axis, u - w / 2 - 0.22, yb + ht / 2, n, 0.45, ht, 0.12, col, M.SmoothPlastic, true)
		ax(h, parent, axis, u + w / 2 + 0.22, yb + ht / 2, n, 0.45, ht, 0.12, col, M.SmoothPlastic, true)
		ax(h, parent, axis, u, yb + ht + 0.22, n, w + 0.9, 0.45, 0.12, col, M.SmoothPlastic, true)
	end
end

-- fenêtre : vitre dans l'épaisseur du mur, cadre et appui côté extérieur (outward = ±1)
local function window(h, parent, axis, u, c, outward, yb, w, v1, v2, pal, kind)
	local hgt = v2 - v1
	local yc = yb + (v1 + v2) / 2
	local fr = pal.frame or pal.trim
	local fo = c + outward * (K.EXT / 2 + 0.08)
	ax(h, parent, axis, u, yc, c, w, hgt, 0.2, GLASS, M.Glass, false, { Transparency = 0.35, Name = "Glass" })
	ax(h, parent, axis, u, yb + v2 + 0.2, fo, w + 0.8, 0.4, 0.22, fr, M.SmoothPlastic, true)
	ax(h, parent, axis, u, yb + v1 - 0.15, c + outward * (K.EXT / 2 + 0.3), w + 0.9, 0.3, 0.7, fr, M.SmoothPlastic, true)
	ax(h, parent, axis, u - w / 2 - 0.2, yc, fo, 0.4, hgt, 0.22, fr, M.SmoothPlastic, true)
	ax(h, parent, axis, u + w / 2 + 0.2, yc, fo, 0.4, hgt, 0.22, fr, M.SmoothPlastic, true)
	-- petits bois (maisons classiques) ou montant central (modernes)
	if not pal.modern then
		ax(h, parent, axis, u, yc, c, 0.16, hgt, 0.3, fr, M.SmoothPlastic, true)
		ax(h, parent, axis, u, yc, c, w, 0.16, 0.3, fr, M.SmoothPlastic, true)
		if pal.shutter and hgt < 7 and kind ~= "bath" then
			for _, s in { -1, 1 } do
				ax(h, parent, axis, u + s * (w / 2 + 1.25), yc, c + outward * (K.EXT / 2 + 0.06), 1.6, hgt + 0.3, 0.14, pal.shutter, M.WoodPlanks, true)
			end
		end
	elseif w > 5 then
		ax(h, parent, axis, u, yc, c, 0.2, hgt, 0.3, fr, M.SmoothPlastic, true)
	end
end

-- toit à deux pans. lc : repère local (X = faîtage) au centre de l'emprise, à la hauteur du haut des murs
local function gableRoof(h, parent, lc, len, span, pitch, ohE, ohG, pal, wallCol, wallMat)
	local base = h.cf * lc
	local rise = span / 2 * pitch
	local t = 0.6
	local roofMat = pal.roofMat or M.RoofShingles
	for _, s in { -1, 1 } do
		local eave = V(0, -ohE * pitch, s * (span / 2 + ohE))
		local ridge = V(0, rise, 0)
		local mid = (eave + ridge) / 2
		local L = (ridge - eave).Magnitude
		local pcf = CFrame.lookAt(mid, ridge) * CFrame.new(0, t / 2, 0)
		Lib.part(parent, base * pcf, V(len + 2 * ohG, t, L + 0.3), pal.roof, roofMat, { Name = "Roof" })
		-- planche de rive le long de l'égout
		Lib.part(parent, base * CFrame.lookAt(eave, ridge) * CFrame.new(0, -0.1, 0.15), V(len + 2 * ohG, 0.7, 0.3), pal.trim, M.SmoothPlastic, props(true))
	end
	Lib.part(parent, base * CFrame.new(0, rise + 0.4, 0), V(len + 2 * ohG + 0.1, 0.4, 1.1), pal.roof:Lerp(Color3.new(0, 0, 0), 0.2), roofMat, props(true))
	for _, sx in { -1, 1 } do
		local x = sx * (len / 2 - K.EXT / 2)
		Lib.part(parent, base * CFrame.new(x, rise / 2, -span / 4), V(K.EXT, rise, span / 2), wallCol, wallMat, { Class = "WedgePart", Name = "Gable" })
		Lib.part(parent, base * CFrame.new(x, rise / 2, span / 4) * CFrame.Angles(0, math.pi, 0), V(K.EXT, rise, span / 2), wallCol, wallMat, { Class = "WedgePart", Name = "Gable" })
		-- planches de rive le long des pignons
		for _, s in { -1, 1 } do
			local a = V(sx * (len / 2 + ohG), -ohE * pitch, s * (span / 2 + ohE))
			local b = V(sx * (len / 2 + ohG), rise, 0)
			Lib.part(parent, base * CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, 0.05, 0), V(0.3, 0.8, (b - a).Magnitude), pal.trim, M.SmoothPlastic, props(true))
		end
	end
	return rise
end

---------------------------------------------------------------- mobilier (repère : X largeur, Z profondeur, façade vers -Z, dos +Z)
local function fp(parent, base, x, y, z, sx, sy, sz, col, mat, collide, extra)
	return Lib.part(parent, base * CFrame.new(x, y, z), V(sx, sy, sz), col, mat or M.SmoothPlastic, props(not collide, extra))
end
local WOOD_D, WOOD_L = rgb(110, 78, 54), rgb(176, 138, 98)
local F = {}
function F.sofa(p, b, col)
	fp(p, b, 0, 0.75, 0.1, 7.5, 1.5, 3, col, M.Fabric, true)
	fp(p, b, 0, 2.4, 1.2, 7.5, 1.8, 0.8, col, M.Fabric, true)
	for _, s in { -1, 1 } do
		fp(p, b, s * 3.35, 1.9, 0.1, 0.8, 0.8, 3, col, M.Fabric, false)
		fp(p, b, s * 1.6, 1.62, -0.25, 3.1, 0.25, 2.3, col:Lerp(WHITE, 0.12), M.Fabric, false)
	end
	fp(p, b, -2.4, 2.2, 0.65, 1.4, 1.2, 0.4, rgb(214, 204, 186), M.Fabric, false)
end
function F.armchair(p, b, col)
	fp(p, b, 0, 0.75, 0.1, 3.6, 1.5, 3, col, M.Fabric, true)
	fp(p, b, 0, 2.4, 1.2, 3.6, 1.8, 0.8, col, M.Fabric, true)
	fp(p, b, 0, 1.62, -0.25, 2.4, 0.25, 2.3, col:Lerp(WHITE, 0.12), M.Fabric, false)
end
function F.coffee(p, b)
	fp(p, b, 0, 1.5, 0, 4.4, 0.25, 2.4, WOOD_L, M.WoodPlanks, true)
	fp(p, b, 0, 0.7, 0, 3.8, 1.4, 1.8, WOOD_D, M.Wood, false)
end
function F.tv(p, b)
	fp(p, b, 0, 1, 0, 6, 2, 1.6, WOOD_D, M.Wood, true)
	fp(p, b, 0, 3.7, 0.35, 5, 2.8, 0.25, rgb(22, 22, 26), M.SmoothPlastic, false)
	fp(p, b, 0, 3.7, 0.2, 4.7, 2.5, 0.05, rgb(44, 52, 62), M.Glass, false, { Reflectance = 0.15 })
end
function F.plant(p, b)
	fp(p, b, 0, 0.9, 0, 1.6, 1.8, 1.6, rgb(196, 190, 180), M.Concrete, true)
	Lib.ball(p, (b * CFrame.new(0, 3, 0)).Position, 2.6, rgb(74, 128, 66), M.Grass)
end
function F.lamp(p, b)
	fp(p, b, 0, 2.6, 0, 0.25, 5.2, 0.25, rgb(60, 60, 64), M.Metal, false)
	fp(p, b, 0, 5.4, 0, 1.4, 1.1, 1.4, rgb(240, 230, 206), M.Fabric, false)
end
function F.table(p, b, w, d)
	fp(p, b, 0, 2.85, 0, w, 0.3, d, WOOD_L, M.WoodPlanks, true)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			fp(p, b, sx * (w / 2 - 0.4), 1.35, sz * (d / 2 - 0.4), 0.35, 2.7, 0.35, WOOD_D, M.Wood, false)
		end
	end
end
function F.chair(p, b, col)
	fp(p, b, 0, 1.75, 0, 1.8, 0.3, 1.8, WOOD_L, M.Wood, true)
	fp(p, b, 0, 2.95, 0.8, 1.8, 2.1, 0.25, col or WOOD_D, M.Wood, true)
	fp(p, b, 0, 0.8, 0, 1.3, 1.6, 1.3, WOOD_D, M.Wood, false)
end
function F.kitchen(p, b, L, fridge, pal)
	local cab = pal.cabinet or rgb(232, 230, 224)
	local top = rgb(70, 72, 76)
	local c1, c2 = -L / 2, L / 2
	if fridge then
		local fx = fridge * (L / 2 - 1.6)
		fp(p, b, fx, 3.6, 0, 3.2, 7.2, 2.8, rgb(214, 218, 220), M.Metal, true)
		fp(p, b, fx - fridge * 1.2, 4.2, -1.45, 0.15, 2.4, 0.15, rgb(150, 154, 158), M.Metal, false)
		if fridge > 0 then
			c2 = L / 2 - 3.3
		else
			c1 = -L / 2 + 3.3
		end
	end
	local cl, cm = c2 - c1, (c1 + c2) / 2
	if cl < 2 then
		return
	end
	fp(p, b, cm, 1.5, 0.05, cl, 3, 2.7, cab, M.WoodPlanks, true)
	fp(p, b, cm, 3.1, -0.05, cl + 0.1, 0.2, 2.9, top, M.Granite, false)
	fp(p, b, cm, 0.15, -1.32, cl, 0.3, 0.05, rgb(60, 60, 64), M.SmoothPlastic, false)
	local sx, st = c1 + cl * 0.3, c1 + cl * 0.72
	fp(p, b, sx, 3.21, -0.1, 2.4, 0.05, 1.6, rgb(186, 190, 194), M.Metal, false)
	fp(p, b, sx, 3.75, 0.95, 0.2, 1.1, 0.2, rgb(186, 190, 194), M.Metal, false)
	if cl > 6 then
		fp(p, b, st, 3.21, -0.1, 2.6, 0.05, 2, rgb(30, 30, 34), M.Glass, false)
	end
	for x = c1 + 1.5, c2 - 1, 3 do
		fp(p, b, x, 2.3, -1.38, 0.08, 1.2, 0.05, rgb(150, 150, 150), M.Metal, false)
	end
end
function F.bed(p, b, w, len, col)
	fp(p, b, 0, 0.6, 0, w, 1.2, len, WOOD_L, M.Wood, true)
	fp(p, b, 0, 1.55, -0.1, w - 0.3, 0.7, len - 0.6, rgb(246, 244, 240), M.Fabric, true)
	fp(p, b, 0, 1.97, -0.9, w - 0.1, 0.16, len - 2.2, col, M.Fabric, false)
	if w > 5 then
		for _, s in { -1, 1 } do
			fp(p, b, s * w / 4, 2.1, len / 2 - 1.3, w / 2 - 0.5, 0.45, 1.3, WHITE, M.Fabric, false)
		end
	else
		fp(p, b, 0, 2.1, len / 2 - 1.3, w - 1, 0.45, 1.3, WHITE, M.Fabric, false)
	end
	fp(p, b, 0, 2.3, len / 2 - 0.25, w + 0.2, 4.6, 0.5, WOOD_D, M.Wood, true)
end
function F.nightstand(p, b)
	fp(p, b, 0, 1.1, 0, 1.8, 2.2, 1.6, WOOD_D, M.Wood, true)
	fp(p, b, 0, 2.75, 0.1, 0.8, 1.1, 0.8, rgb(240, 230, 206), M.Fabric, false)
end
function F.wardrobe(p, b)
	fp(p, b, 0, 3.75, 0, 5, 7.5, 2.4, WOOD_L, M.WoodPlanks, true)
	fp(p, b, 0, 3.8, -1.21, 0.08, 7.1, 0.03, WOOD_D, M.SmoothPlastic, false)
	for _, s in { -1, 1 } do
		fp(p, b, s * 0.45, 3.9, -1.25, 0.12, 1.4, 0.1, rgb(160, 160, 160), M.Metal, false)
	end
end
function F.desk(p, b)
	fp(p, b, 0, 2.95, 0.9, 4.5, 0.2, 2.2, WOOD_L, M.WoodPlanks, true)
	for _, s in { -1, 1 } do
		fp(p, b, s * 2.1, 1.42, 0.9, 0.2, 2.85, 2, WOOD_D, M.Wood, false)
	end
	F.chair(p, b * CFrame.new(0, 0, -0.9) * CFrame.Angles(0, math.pi, 0), WOOD_D)
end
function F.dresser(p, b)
	fp(p, b, 0, 1.6, 0, 4, 3.2, 1.8, WOOD_L, M.WoodPlanks, true)
	for y = 0.9, 2.5, 0.8 do
		fp(p, b, 0, y, -0.91, 3.6, 0.06, 0.03, WOOD_D, M.SmoothPlastic, false)
	end
end
function F.tub(p, b)
	fp(p, b, 0, 1.1, 0, 7, 2.2, 3.2, rgb(246, 246, 244), M.SmoothPlastic, true)
	fp(p, b, 0, 2.06, -0.05, 6.2, 0.12, 2.4, rgb(186, 214, 226), M.Glass, false, { Transparency = 0.2 })
	fp(p, b, 2.9, 2.8, 1.3, 0.25, 1.2, 0.25, rgb(190, 192, 196), M.Metal, false)
end
function F.toilet(p, b)
	fp(p, b, 0, 0.8, -0.3, 1.6, 1.6, 2, rgb(248, 248, 246), M.SmoothPlastic, true)
	fp(p, b, 0, 2.2, 1, 2, 1.8, 0.8, rgb(248, 248, 246), M.SmoothPlastic, true)
	fp(p, b, 0, 1.66, -0.3, 1.6, 0.12, 2, rgb(236, 236, 234), M.SmoothPlastic, false)
end
function F.vanity(p, b)
	fp(p, b, 0, 1.5, 0, 3.6, 3, 2, WOOD_L, M.WoodPlanks, true)
	fp(p, b, 0, 3.07, 0, 3.8, 0.15, 2.1, WHITE, M.Marble, false)
	fp(p, b, 0, 3.16, -0.1, 1.8, 0.04, 1.2, rgb(214, 222, 226), M.SmoothPlastic, false)
	fp(p, b, 0, 6, 0.95, 3, 2.8, 0.1, rgb(200, 216, 224), M.Glass, false, { Reflectance = 0.35 })
end
function F.shelf(p, b)
	fp(p, b, 0, 3.5, 0, 6, 7, 1.6, rgb(120, 124, 130), M.Metal, true)
	fp(p, b, -1.4, 4.4, -0.2, 2, 1.4, 1.2, rgb(196, 150, 96), M.Cardboard, false)
	fp(p, b, 1.5, 1.6, -0.2, 2.2, 1.6, 1.2, rgb(196, 150, 96), M.Cardboard, false)
end
function F.workbench(p, b)
	fp(p, b, 0, 1.55, 0, 5, 3.1, 2.4, rgb(150, 112, 76), M.WoodPlanks, true)
	fp(p, b, 0, 5.2, 1.1, 5, 3, 0.2, rgb(110, 114, 120), M.DiamondPlate, false)
end

---------------------------------------------------------------- placement du mobilier dans une pièce
local function ovl(a, b)
	return a[1] < b[2] and b[1] < a[2] and a[3] < b[4] and b[3] < a[4]
end
local function free(room, r, tall)
	if r[1] < room.x1 - 0.01 or r[2] > room.x2 + 0.01 or r[3] < room.z1 - 0.01 or r[4] > room.z2 + 0.01 then
		return false
	end
	for _, k in room.keep do
		if ovl(r, k) then
			return false
		end
	end
	for _, k in room.items do
		if ovl(r, k) then
			return false
		end
	end
	if tall then
		for _, k in room.win do
			if ovl(r, k) then
				return false
			end
		end
	end
	return true
end
local OPP = { z1 = "z2", z2 = "z1", x1 = "x2", x2 = "x1" }
-- objet w x d adossé au mur `side`, centré à la coordonnée `at` le long du mur (ou à la fraction t)
local function wallSpot(room, side, t, w, d, at)
	local rect, cx, cz, ang
	if side == "z1" or side == "z2" then
		cx = at or (room.x1 + w / 2 + (room.x2 - room.x1 - w) * t)
		if side == "z1" then
			cz, ang = room.z1 + 0.05 + d / 2, math.pi
		else
			cz, ang = room.z2 - 0.05 - d / 2, 0
		end
		rect = { cx - w / 2, cx + w / 2, cz - d / 2, cz + d / 2 }
	else
		cz = at or (room.z1 + w / 2 + (room.z2 - room.z1 - w) * t)
		if side == "x1" then
			cx, ang = room.x1 + 0.05 + d / 2, -math.pi / 2
		else
			cx, ang = room.x2 - 0.05 - d / 2, math.pi / 2
		end
		rect = { cx - d / 2, cx + d / 2, cz - w / 2, cz + w / 2 }
	end
	return rect, CFrame.new(cx, 0, cz) * CFrame.Angles(0, ang, 0)
end
local function sideOrder(room, rng)
	local first, rest = {}, {}
	for _, s in { "z1", "z2", "x1", "x2" } do
		if room.doorSides[OPP[s]] and not room.doorSides[s] then
			table.insert(first, s)
		elseif not room.doorSides[s] then
			table.insert(rest, s)
		end
	end
	for _, s in { "z1", "z2", "x1", "x2" } do
		if room.doorSides[s] then
			table.insert(rest, s)
		end
	end
	for _, s in rest do
		table.insert(first, s)
	end
	return first
end

local function furnish(h, room, rng, pal)
	local p = h.furn
	local function world(lcf)
		return h.cf * CFrame.new(0, room.y, 0) * lcf
	end
	local function put(builder, rect, lcf, tall, ...)
		if not free(room, rect, tall) then
			return false
		end
		table.insert(room.items, { rect[1] - 0.15, rect[2] + 0.15, rect[3] - 0.15, rect[4] + 0.15 })
		builder(p, world(lcf), ...)
		return true
	end
	local function onWall(builder, w, d, sides, ts, tall, ...)
		for _, s in sides do
			for _, t in ts do
				local rect, lcf = wallSpot(room, s, t, w, d)
				if put(builder, rect, lcf, tall, ...) then
					return rect, lcf, s
				end
			end
		end
	end
	local function rug(cx, cz, sx, sz, col)
		Lib.part(p, h.cf * CFrame.new(cx, room.y + 0.08, cz), V(sx, 0.05, sz), col, M.Fabric, props(true))
	end
	local sides = sideOrder(room, rng)
	local kind = room.kind
	local fabric = Lib.pick({ rgb(150, 150, 146), rgb(118, 126, 134), rgb(176, 162, 140), rgb(96, 108, 98), rgb(130, 110, 96) }, rng)
	if kind == "living" then
		local r, lcf, s = onWall(F.sofa, 7.5, 3.2, sides, { 0.5, 0.35, 0.65, 0.2, 0.8 }, false, fabric)
		if r then
			local fwd = lcf.LookVector
			local c = lcf.Position + fwd * (1.6 + 2.2 + 1.2)
			local tcf = CFrame.new(c) * lcf.Rotation
			local horiz = s == "z1" or s == "z2"
			local tr = horiz and { c.X - 2.2, c.X + 2.2, c.Z - 1.2, c.Z + 1.2 } or { c.X - 1.2, c.X + 1.2, c.Z - 2.2, c.Z + 2.2 }
			rug(c.X, c.Z, horiz and 9 or 6.5, horiz and 6.5 or 9, Lib.pick({ rgb(200, 190, 172), rgb(170, 176, 180), rgb(150, 120, 100) }, rng))
			put(F.coffee, tr, tcf, false)
			local along = horiz and lcf.Position.X or lcf.Position.Z
			local rr, tl = wallSpot(room, OPP[s], 0.5, 6, 1.6, along)
			put(F.tv, rr, tl, false)
			-- fauteuil sur le côté, tourné vers la table basse
			local side = lcf.RightVector
			for _, k in { 1, -1 } do
				local ap = c + side * k * 5
				local acf = CFrame.lookAt(ap, c)
				if put(F.armchair, { ap.X - 1.8, ap.X + 1.8, ap.Z - 1.8, ap.Z + 1.8 }, acf, false, fabric:Lerp(WHITE, 0.2)) then
					break
				end
			end
			local lp = lcf.Position + side * 4.9
			put(F.lamp, { lp.X - 0.6, lp.X + 0.6, lp.Z - 0.6, lp.Z + 0.6 }, CFrame.new(lp), false)
		end
		onWall(F.plant, 1.8, 1.8, sides, { 0, 1 }, false)
		onWall(F.dresser, 4, 1.8, sides, { 0.5, 0.25, 0.75 }, false)
	elseif kind == "kitchen" or kind == "dining" then
		if kind == "kitchen" then
			local ok = false
			for _, s in sides do
				local along = (s == "z1" or s == "z2") and (room.x2 - room.x1) or (room.z2 - room.z1)
				local L = math.clamp(along - 1.5, 8, 15)
				if along >= 8.5 and not (room.avoidSide == s) then
					for _, t in { 0, 1, 0.5 } do
						local rect, lcf = wallSpot(room, s, t, L, 2.8)
						if free(room, rect, false) then
							-- frigo du côté qui ne masque pas une fenêtre
							local fridge
							for _, fs in { -1, 1 } do
								local fc = (lcf * CFrame.new(fs * (L / 2 - 1.6), 0, 0)).Position
								local fr = (s == "z1" or s == "z2") and { fc.X - 1.6, fc.X + 1.6, fc.Z - 1.4, fc.Z + 1.4 } or { fc.X - 1.4, fc.X + 1.4, fc.Z - 1.6, fc.Z + 1.6 }
								if free(room, fr, true) then
									fridge = fs
									break
								end
							end
							put(F.kitchen, rect, lcf, false, L, fridge, pal)
							ok = true
							break
						end
					end
				end
				if ok then
					break
				end
			end
		end
		-- table à manger + 4 chaises (emprise 6,5 x 8)
		local cx, cz = (room.x1 + room.x2) / 2, (room.z1 + room.z2) / 2
		local alongX = (room.x2 - room.x1) >= (room.z2 - room.z1)
		local done = false
		for _, dd in { 0, 2, -2, 4, -4, 6, -6 } do
			for _, rot in { alongX, not alongX } do
				local tw, td = 6.5, 3.6
				local fx, fz = rot and tw or td + 4.6, rot and td + 4.6 or tw
				local px, pz = cx + (rot and dd or 0), cz + (rot and 0 or dd)
				local rect = { px - fx / 2, px + fx / 2, pz - fz / 2, pz + fz / 2 }
				if free(room, rect, false) then
					table.insert(room.items, rect)
					local base = world(CFrame.new(px, 0, pz) * CFrame.Angles(0, rot and 0 or math.pi / 2, 0))
					F.table(p, base, tw, td)
					for _, sx in { -1.6, 1.6 } do
						F.chair(p, base * CFrame.new(sx, 0, -2.6) * CFrame.Angles(0, math.pi, 0))
						F.chair(p, base * CFrame.new(sx, 0, 2.6))
					end
					done = true
					break
				end
			end
			if done then
				break
			end
		end
		if kind == "dining" then
			onWall(F.dresser, 4, 1.8, sides, { 0.5, 0.3, 0.7 }, false)
		end
		onWall(F.plant, 1.8, 1.8, sides, { 0, 1 }, false)
	elseif kind == "bedroom" then
		local bw = room.master and 6.2 or 4.6
		local blanket = Lib.pick({ rgb(120, 136, 150), rgb(176, 160, 136), rgb(200, 196, 188), rgb(110, 124, 108), rgb(150, 118, 104) }, rng)
		local r, lcf, s = onWall(F.bed, bw, 8.4, sides, { 0.5, 0.3, 0.7, 0.15, 0.85 }, false, bw, 8.4, blanket)
		if not r then
			bw = 4.6
			r, lcf, s = onWall(F.bed, bw, 8.4, sides, { 0.5, 0.2, 0.8, 0, 1 }, false, bw, 8.4, blanket)
		end
		if r then
			local horiz = s == "z1" or s == "z2"
			local along = horiz and lcf.Position.X or lcf.Position.Z
			for _, k in { -1, 1 } do
				local rr, nl = wallSpot(room, s, 0.5, 1.8, 1.6, along + k * (bw / 2 + 1.15))
				put(F.nightstand, rr, nl, false)
			end
			local fc = lcf.Position + lcf.LookVector * 5.5
			rug(fc.X, fc.Z, horiz and bw + 2 or 3, horiz and 3 or bw + 2, rgb(206, 198, 186))
		end
		onWall(F.wardrobe, 5, 2.4, sides, { 0.5, 0.2, 0.8, 0, 1 }, true)
		onWall(F.desk, 4.5, 4, sides, { 0.5, 0.3, 0.7, 0, 1 }, false)
	elseif kind == "bath" then
		onWall(F.tub, 7, 3.2, sides, { 0, 1, 0.5 }, false)
		onWall(F.toilet, 2.2, 2.8, sides, { 0, 1, 0.5, 0.3, 0.7 }, false)
		onWall(F.vanity, 3.6, 2, sides, { 0.5, 0.3, 0.7, 0, 1 }, false)
	elseif kind == "hall" then
		local lx, lz = room.x2 - room.x1, room.z2 - room.z1
		rug((room.x1 + room.x2) / 2, (room.z1 + room.z2) / 2, lx > lz and lx - 3 or 2.8, lx > lz and 2.8 or lz - 3, rgb(150, 120, 100))
	elseif kind == "garage" then
		onWall(F.shelf, 6, 1.6, { "z2" }, { 0.5, 0.2, 0.8 }, true)
		onWall(F.workbench, 5, 2.4, sides, { 1, 0.8, 0 }, false)
	end
end

---------------------------------------------------------------- une maison
-- spec : { W, D, floors, roof ("gable" | "frontgable" | "flat"), pal (nom), garage = { side = ±1, w = 12 } | nil,
--          porch (bool), porchW, doorSide (±1), chimney (bool), name, type }
function K.build(parent, cf, spec, rng)
	local W, D, nF = spec.W, spec.D, spec.floors
	local pal = K.PAL[spec.pal] or K.PAL.white
	local EXT, INT, FH, SL, Y0, OUT = K.EXT, K.INT, K.FH, K.SLAB, K.Y0, K.OUT
	local model = Instance.new("Model")
	model.Name = spec.name or "House"
	local h = { cf = cf }
	h.shell = Lib.model(model, "Shell")
	h.inter = Lib.model(model, "Interior")
	h.furn = Lib.model(model, "Furniture")
	h.doors = Lib.model(model, "Doors")
	local xa, xb, za, zb = -W / 2 + EXT, W / 2 - EXT, EXT, D - EXT
	local function fy(k)
		return Y0 + k * FH
	end
	local ds = spec.doorSide or 1
	local gar = spec.garage
	local gs = gar and gar.side or -ds
	local rooms, iwalls, keeps = {}, {}, {}
	local ext = {}
	for f = 0, nF - 1 do
		ext[f] = { front = {}, back = {}, L = {}, R = {} }
	end
	local function room(kind, f, x1, x2, z1, z2)
		local r = { kind = kind, f = f, x1 = x1, x2 = x2, z1 = z1, z2 = z2, y = fy(f), keep = {}, win = {}, items = {}, doorSides = {} }
		table.insert(rooms, r)
		return r
	end
	local function iwall(f, axis, c, a, b)
		local w = { f = f, axis = axis, c = c, a = a, b = b, doors = {}, holes = {} }
		table.insert(iwalls, w)
		return w
	end
	local function R4(x1, x2, z1, z2)
		return { math.min(x1, x2), math.max(x1, x2), math.min(z1, z2), math.max(z1, z2) }
	end
	local function keep(f, r)
		table.insert(keeps, { f, r })
	end
	local function perp(wl, u, w, n1, n2)
		if wl.axis == "x" then
			return R4(u - w / 2, u + w / 2, wl.c + n1, wl.c + n2)
		end
		return R4(wl.c + n1, wl.c + n2, u - w / 2, u + w / 2)
	end
	local function idoor(wl, u, swing, hinge)
		table.insert(wl.doors, { u = u, swing = swing, hinge = hinge })
		table.insert(wl.holes, { u - K.IDOOR_W / 2, u + K.IDOOR_W / 2, 0, K.IDOOR_H })
		keep(wl.f, perp(wl, u, K.IDOOR_W + 0.8, 0, swing * (K.IDOOR_W + 0.8)))
		keep(wl.f, perp(wl, u, K.IDOOR_W, 0, -swing * 3))
	end
	local function opening(wl, u, w)
		table.insert(wl.holes, { u - w / 2, u + w / 2, 0, 8.6 })
		keep(wl.f, perp(wl, u, w + 1, -3.5, 3.5))
	end

	---------------------------------------------------------------- plan
	local stair, doorX, gdoorU
	if nF == 1 then
		local zf = za + math.floor((zb - za - K.HALL) * 0.52 + 0.5)
		local zh = zf + INT + K.HALL
		local xm = -ds * 1
		if ds > 0 then
			room("living", 0, xm, xb, za, zf - INT / 2)
			room("kitchen", 0, xa, xm, za, zf - INT / 2).avoidSide = nil
		else
			room("living", 0, xa, xm, za, zf - INT / 2)
			room("kitchen", 0, xm, xb, za, zf - INT / 2)
		end
		room("hall", 0, xa, xb, zf + INT / 2, zh - INT / 2)
		local w1 = iwall(0, "x", zf, xa, xb)
		opening(w1, xm, 5)
		local w2 = iwall(0, "x", zh, xa, xb)
		local Wi = xb - xa
		local backs
		if Wi >= 29 then
			local bw = (Wi - 9 - 2 * INT) / 2
			local p1 = xa + bw + INT / 2
			local p2 = p1 + INT + 9
			backs = { { "bedroom", xa, p1 - INT / 2 }, { "bath", p1 + INT / 2, p2 - INT / 2 }, { "bedroom", p2 + INT / 2, xb } }
			iwall(0, "z", p1, zh + INT / 2, zb)
			iwall(0, "z", p2, zh + INT / 2, zb)
		else
			local p1
			if ds < 0 then
				p1 = xa + 8.5 + INT / 2
				backs = { { "bath", xa, p1 - INT / 2 }, { "bedroom", p1 + INT / 2, xb } }
			else
				p1 = xb - 8.5 - INT / 2
				backs = { { "bedroom", xa, p1 - INT / 2 }, { "bath", p1 + INT / 2, xb } }
			end
			iwall(0, "z", p1, zh + INT / 2, zb)
		end
		local first = true
		for _, b in backs do
			local r = room(b[1], 0, b[2], b[3], zh + INT / 2, zb)
			if b[1] == "bedroom" and first then
				r.master = true
				first = false
			end
			idoor(w2, b[2] + 0.9 + K.IDOOR_W / 2, 1, -1)
		end
		doorX = xm + ds * 5.5
		gdoorU = (zf + zh) / 2
	else
		local sx1, sx2
		if gs > 0 then
			sx1, sx2 = xb - K.STAIR_W, xb
		else
			sx1, sx2 = xa, xa + K.STAIR_W
		end
		local zs0 = za + 3
		local zs1 = zs0 + (FH / K.RISE) * K.RUN
		stair = { sx1, sx2, zs0, zs1 }
		local zc1 = zs1 + INT / 2
		local zc2 = zc1 + INT + K.HALL
		-- rez-de-chaussée : séjour (et salle à manger si large) devant, cuisine au fond
		local wg = iwall(0, "x", zc1, xa, xb)
		local liv
		if (xb - xa) >= 34 then
			if ds > 0 then
				liv = room("living", 0, 0, xb, za, zc1 - INT / 2)
				room("dining", 0, xa, 0, za, zc1 - INT / 2)
			else
				liv = room("living", 0, xa, 0, za, zc1 - INT / 2)
				room("dining", 0, 0, xb, za, zc1 - INT / 2)
			end
			opening(wg, ds * (xb - xa) / 4, 6)
		else
			liv = room("living", 0, xa, xb, za, zc1 - INT / 2)
			opening(wg, gs > 0 and (xa + sx1) / 2 or (sx2 + xb) / 2, 6)
		end
		local kit = room("kitchen", 0, xa, xb, zc1 + INT / 2, zb)
		kit.avoidSide = gar and (gs > 0 and "x2" or "x1") or nil
		keep(0, R4(gs > 0 and sx1 - 2.8 or sx1, gs > 0 and sx2 or sx2 + 2.8, za, zs1))
		-- étage
		local w1 = iwall(1, "x", zc1, xa, xb)
		table.insert(w1.holes, { sx1, sx2, 0, FH })
		local px = gs > 0 and sx1 - INT / 2 or sx2 + INT / 2
		iwall(1, "z", px, za, zc1 - INT / 2)
		local rx1, rx2 = gs > 0 and xa or px + INT / 2, gs > 0 and px - INT / 2 or xb
		local fronts = {}
		if rx2 - rx1 >= 26 then
			local pm = (rx1 + rx2) / 2
			iwall(1, "z", pm, za, zc1 - INT / 2)
			fronts = { { rx1, pm - INT / 2 }, { pm + INT / 2, rx2 } }
		else
			fronts = { { rx1, rx2 } }
		end
		for i, fr in fronts do
			local r = room("bedroom", 1, fr[1], fr[2], za, zc1 - INT / 2)
			r.master = (i == 1)
			idoor(w1, fr[1] + 0.9 + K.IDOOR_W / 2, -1, -1)
		end
		room("hall", 1, xa, xb, zc1 + INT / 2, zc2 - INT / 2)
		local w2 = iwall(1, "x", zc2, xa, xb)
		local Wi = xb - xa
		local backs
		if Wi >= 29 then
			local bw = (Wi - 9 - 2 * INT) / 2
			local p1 = xa + bw + INT / 2
			local p2 = p1 + INT + 9
			backs = { { "bedroom", xa, p1 - INT / 2 }, { "bath", p1 + INT / 2, p2 - INT / 2 }, { "bedroom", p2 + INT / 2, xb } }
			iwall(1, "z", p1, zc2 + INT / 2, zb)
			iwall(1, "z", p2, zc2 + INT / 2, zb)
		else
			local p1 = gs > 0 and xa + 9 + INT / 2 or xb - 9 - INT / 2
			if gs > 0 then
				backs = { { "bath", xa, p1 - INT / 2 }, { "bedroom", p1 + INT / 2, xb } }
			else
				backs = { { "bedroom", xa, p1 - INT / 2 }, { "bath", p1 + INT / 2, xb } }
			end
			iwall(1, "z", p1, zc2 + INT / 2, zb)
		end
		for _, b in backs do
			room(b[1], 1, b[2], b[3], zc2 + INT / 2, zb)
			idoor(w2, b[2] + 0.9 + K.IDOOR_W / 2, 1, -1)
		end
		doorX = ds * math.min(6, (xb - xa) / 2 - K.STAIR_W - 4)
		if (xb - xa) >= 34 then
			doorX = ds * 7
		end
		gdoorU = (zc1 + zb) / 2
	end
	-- porte d'entrée
	table.insert(ext[0].front, { doorX - K.DOOR_W / 2, doorX + K.DOOR_W / 2, 0, K.DOOR_H })
	keep(0, R4(doorX - 2.8, doorX + 2.8, za, za + 5.4))
	-- garage
	local gz0, Dg, gcx, gDoorW = 1, 0, 0, 0
	if gar then
		Dg = math.clamp(gdoorU + 4.5 - gz0, 22, D - gz0)
		local sideKey = gs > 0 and "L" or "R"
		table.insert(ext[0][sideKey], { gdoorU - K.IDOOR_W / 2, gdoorU + K.IDOOR_W / 2, 0, K.IDOOR_H })
		keep(0, R4(gs > 0 and xb - 3 or xa, gs > 0 and xb or xa + 3, gdoorU - 2.2, gdoorU + 2.2))
	end
	-- répartit les zones réservées dans les pièces, repère les côtés munis de portes
	for _, kp in keeps do
		for _, r in rooms do
			if r.f == kp[1] then
				table.insert(r.keep, kp[2])
			end
		end
	end
	for _, wl in iwalls do
		local list = {}
		for _, d in wl.doors do
			table.insert(list, d.u)
		end
		for _, o in wl.holes do
			if o[4] < FH then
				table.insert(list, (o[1] + o[2]) / 2)
			end
		end
		for _, u in list do
			for _, r in rooms do
				if r.f == wl.f then
					if wl.axis == "x" and u > r.x1 and u < r.x2 then
						if math.abs(r.z1 - wl.c) < 0.6 then
							r.doorSides.z1 = true
						elseif math.abs(r.z2 - wl.c) < 0.6 then
							r.doorSides.z2 = true
						end
					elseif wl.axis == "z" and u > r.z1 and u < r.z2 then
						if math.abs(r.x1 - wl.c) < 0.6 then
							r.doorSides.x1 = true
						elseif math.abs(r.x2 - wl.c) < 0.6 then
							r.doorSides.x2 = true
						end
					end
				end
			end
		end
	end
	for _, r in rooms do
		if r.f == 0 and r.z1 <= za + 0.05 and doorX > r.x1 and doorX < r.x2 then
			r.doorSides.z1 = true
		end
	end

	---------------------------------------------------------------- fenêtres
	local wins = {} -- { f, key, u, w, v1, v2, kind }
	local function wspec(kind)
		if pal.modern then
			if kind == "bath" then
				return 3, 5.6, 8.6
			elseif kind == "living" or kind == "dining" then
				return 7, 1.4, 9.4
			elseif kind == "kitchen" then
				return 6, 4.2, 8.8
			end
			return 6, 2.6, 9
		end
		if kind == "bath" then
			return 3, 5.6, 8.4
		elseif kind == "kitchen" then
			return 4, 4.2, 8.6
		elseif kind == "hall" then
			return 3, 3.4, 8.4
		end
		return 4, 3.2, 8.6
	end
	for _, r in rooms do
		local f = r.f
		local ww, v1, v2 = wspec(r.kind)
		local sides = {}
		if r.z1 <= za + 0.05 then
			table.insert(sides, { "front", r.x1, r.x2 })
		end
		if r.z2 >= zb - 0.05 then
			table.insert(sides, { "back", r.x1, r.x2 })
		end
		if r.x2 >= xb - 0.05 then
			table.insert(sides, { "L", r.z1, r.z2 })
		end
		if r.x1 <= xa + 0.05 then
			table.insert(sides, { "R", r.z1, r.z2 })
		end
		for _, sd in sides do
			local key, s1, s2 = sd[1], sd[2] + 0.8, sd[3] - 0.8
			local isG = (key == "L" and gs > 0) or (key == "R" and gs < 0)
			if stair and f == 0 and isG and r.kind ~= "kitchen" then
				s1 = math.max(s1, stair[4] + 0.8)
			end
			if gar and isG and f == 0 then
				s1 = math.max(s1, gz0 + Dg + 0.8)
			end
			-- retire les baies déjà présentes (portes) du segment
			local segs = { { s1, s2 } }
			for _, o in ext[f][key] do
				local out = {}
				for _, sg in segs do
					if o[2] + 0.8 <= sg[1] or o[1] - 0.8 >= sg[2] then
						table.insert(out, sg)
					else
						table.insert(out, { sg[1], o[1] - 0.8 })
						table.insert(out, { o[2] + 0.8, sg[2] })
					end
				end
				segs = out
			end
			for _, sg in segs do
				local L = sg[2] - sg[1]
				if L >= ww + 1.6 then
					local n = L >= 3 * ww + 10 and 3 or (L >= 2 * ww + 6 and 2 or 1)
					if r.kind == "bath" or r.kind == "hall" then
						n = 1
					end
					for i = 1, n do
						local u = sg[1] + L * (i - 0.5) / n
						table.insert(ext[f][key], { u - ww / 2, u + ww / 2, v1, v2 })
						table.insert(wins, { f, key, u, ww, v1, v2, r.kind })
						local wr
						if key == "front" then
							wr = R4(u - ww / 2 - 0.6, u + ww / 2 + 0.6, za, za + 2.6)
						elseif key == "back" then
							wr = R4(u - ww / 2 - 0.6, u + ww / 2 + 0.6, zb - 2.6, zb)
						elseif key == "L" then
							wr = R4(xb - 2.6, xb, u - ww / 2 - 0.6, u + ww / 2 + 0.6)
						else
							wr = R4(xa, xa + 2.6, u - ww / 2 - 0.6, u + ww / 2 + 0.6)
						end
						table.insert(r.win, wr)
					end
				end
			end
		end
	end

	---------------------------------------------------------------- gros œuvre
	local found = box(h, h.shell, -W / 2, 0, 0, W / 2, Y0, D, rgb(150, 146, 140), M.Concrete, false, { Name = "Foundation" })
	local walls = {
		front = { "x", -W / 2, W / 2, 0, -1 },
		back = { "x", -W / 2, W / 2, D, 1 },
		L = { "z", OUT, D - OUT, W / 2, 1 },
		R = { "z", OUT, D - OUT, -W / 2, -1 },
	}
	for f = 0, nF - 1 do
		local col = (f >= 1 and pal.upper) or pal.wall
		local mat = (f >= 1 and pal.upperMat) or pal.mat
		for key, wd in walls do
			local axis, a, b, edge, o = wd[1], wd[2], wd[3], wd[4], wd[5]
			local cOut = edge - o * OUT / 2
			local cIn = edge - o * (OUT + (EXT - OUT) / 2)
			local wcol, wmat = col, mat
			-- façade moderne : un volume d'accent (côté porte / étage)
			if pal.modern and pal.accent and ((f == 1 and key == "front") or (nF == 1 and key == "L")) then
				wcol, wmat = pal.accent, pal.accentMat
			end
			wall(h, h.shell, axis, a, b, cOut, OUT, fy(f), FH, ext[f][key], wcol, wmat)
			local ia, ib = a, b
			if axis == "x" then
				ia, ib = -W / 2 + EXT, W / 2 - EXT
			end
			wall(h, h.inter, axis, ia, ib, cIn, EXT - OUT, fy(f), FH, ext[f][key], pal.inside, M.Plaster)
		end
	end
	for _, wn in wins do
		local wd = walls[wn[2]]
		window(h, h.shell, wd[1], wn[3], wd[4] - wd[5] * EXT / 2, wd[5], fy(wn[1]), wn[4], wn[5], wn[6], pal, wn[7])
	end
	-- cloisons et portes intérieures
	for _, wl in iwalls do
		wall(h, h.inter, wl.axis, wl.a, wl.b, wl.c, INT, fy(wl.f), FH - SL, wl.holes, pal.inside, M.Plaster)
		for _, d in wl.doors do
			hingedDoor(h, h.doors, wl.axis, d.u, wl.c, fy(wl.f), K.IDOOR_W, K.IDOOR_H, d.swing, d.hinge, WHITE, "Porte", false)
			doorTrim(h, h.inter, wl.axis, d.u, wl.c, INT, fy(wl.f), K.IDOOR_W, K.IDOOR_H, WHITE)
		end
	end
	-- dalles, plafond, finitions de sol
	for f = 1, nF do
		local y1, y2 = fy(f) - SL, fy(f)
		if f < nF and stair then
			local s = stair
			box(h, h.inter, xa, y1, za, xb, y2, s[3], CEIL, M.SmoothPlastic, false, { Name = "Slab" })
			box(h, h.inter, xa, y1, s[4], xb, y2, zb, CEIL, M.SmoothPlastic, false, { Name = "Slab" })
			if s[1] > xa + 0.1 then
				box(h, h.inter, xa, y1, s[3], s[1], y2, s[4], CEIL, M.SmoothPlastic, false, { Name = "Slab" })
			end
			if s[2] < xb - 0.1 then
				box(h, h.inter, s[2], y1, s[3], xb, y2, s[4], CEIL, M.SmoothPlastic, false, { Name = "Slab" })
			end
		else
			box(h, h.inter, xa, y1, za, xb, y2, zb, CEIL, M.SmoothPlastic, false, { Name = "Slab" })
		end
	end
	for _, r in rooms do
		local col, mat = pal.floor, pal.floorMat or M.WoodPlanks
		if r.kind == "bath" or r.kind == "kitchen" then
			col, mat = rgb(224, 222, 216), M.CeramicTiles
		elseif r.kind == "bedroom" then
			col, mat = rgb(200, 192, 180), M.Carpet
		end
		box(h, h.inter, r.x1, r.y, r.z1, r.x2, r.y + 0.06, r.z2, col, mat, true)
		-- plafonnier
		local ceil = r.y + FH - SL
		local cx, cz = (r.x1 + r.x2) / 2, (r.z1 + r.z2) / 2
		local lp = mk(h, h.inter, cx, ceil - 0.15, cz, 2.2, 0.3, 2.2, rgb(255, 246, 226), M.SmoothPlastic, true)
		if K.LIGHTS and lp and (r.kind == "living" or r.kind == "kitchen" or r.kind == "hall") then
			local l = Instance.new("PointLight")
			l.Range = 18
			l.Brightness = 0.7
			l.Color = rgb(255, 236, 206)
			l.Shadows = false
			l.Parent = lp
		end
	end
	-- escalier
	if stair then
		local s = stair
		local n = math.floor(FH / K.RISE + 0.5)
		for i = 1, n do
			box(h, h.inter, s[1], fy(0), s[3] + (i - 1) * K.RUN, s[2], fy(0) + i * K.RISE, s[3] + i * K.RUN, pal.floor, M.WoodPlanks, false, { Name = "Step" })
			box(h, h.inter, s[1], fy(0) + i * K.RISE - 0.02, s[3] + (i - 1) * K.RUN - 0.06, s[2], fy(0) + i * K.RISE + 0.06, s[3] + (i - 1) * K.RUN + 0.2, pal.floor:Lerp(Color3.new(0, 0, 0), 0.2), M.Wood, true)
		end
		-- rampe côté pièce
		local xe = gs > 0 and s[1] - 0.15 or s[2] + 0.15
		local a = h.cf * CFrame.new(xe, fy(0) + 3.6, s[3])
		local b = h.cf * CFrame.new(xe, fy(0) + FH + 3.4, s[4])
		Lib.part(h.inter, CFrame.lookAt((a.Position + b.Position) / 2, b.Position), V(0.3, 0.3, (b.Position - a.Position).Magnitude), WOOD_D, M.Wood, props(true))
		for i = 0, 3 do
			local z = s[3] + 0.4 + i * (s[4] - s[3] - 0.8) / 3
			local top = fy(0) + (z - s[3]) / K.RUN * K.RISE
			box(h, h.inter, xe - 0.15, top, z - 0.15, xe + 0.15, top + 3.6, z + 0.15, WHITE, M.SmoothPlastic, true)
		end
		-- garde-corps à l'étage, le long de la trémie côté couloir n'est pas nécessaire (accès) ; côté avant : mur plein
	end
	-- habillage extérieur : chaînes d'angle, bandeau d'étage
	local top = fy(nF)
	if not pal.modern then
		for _, x in { -W / 2, W / 2 } do
			for _, z in { 0, D } do
				box(h, h.shell, x - 0.4, Y0, z - 0.4, x + 0.4, top, z + 0.4, pal.trim, M.SmoothPlastic, true)
			end
		end
		if nF > 1 then
			local y1, y2 = fy(1) - 0.35, fy(1) + 0.35
			box(h, h.shell, -W / 2 - 0.15, y1, -0.15, W / 2 + 0.15, y2, 0.2, pal.trim, M.SmoothPlastic, true)
			box(h, h.shell, -W / 2 - 0.15, y1, D - 0.2, W / 2 + 0.15, y2, D + 0.15, pal.trim, M.SmoothPlastic, true)
			box(h, h.shell, -W / 2 - 0.15, y1, 0.2, -W / 2 + 0.2, y2, D - 0.2, pal.trim, M.SmoothPlastic, true)
			box(h, h.shell, W / 2 - 0.2, y1, 0.2, W / 2 + 0.15, y2, D - 0.2, pal.trim, M.SmoothPlastic, true)
		end
	end
	-- encadrement porte d'entrée et porte
	doorTrim(h, h.shell, "x", doorX, EXT / 2, EXT, Y0, K.DOOR_W, K.DOOR_H, pal.frame or pal.trim, { -1 })
	doorTrim(h, h.inter, "x", doorX, EXT / 2, EXT, Y0, K.DOOR_W, K.DOOR_H, WHITE, { 1 })
	hingedDoor(h, h.doors, "x", doorX, EXT / 2, Y0, K.DOOR_W, K.DOOR_H, 1, ds, pal.door, "Porte d'entrée", true)
	-- perron / porche
	local deck = pal.modern and rgb(196, 194, 190) or rgb(168, 130, 94)
	if spec.porch then
		local pw = spec.porchW or 11
		local x1, x2 = math.max(-W / 2 + 0.4, doorX - pw / 2), math.min(W / 2 - 0.4, doorX + pw / 2)
		box(h, h.shell, x1, 0, -5.5, x2, Y0, 0, deck, M.WoodPlanks, false, { Name = "Porch" })
		box(h, h.shell, doorX - 2.6, 0, -6.7, doorX + 2.6, Y0 / 2, -5.5, rgb(186, 182, 176), M.Concrete, false, { Name = "Step" })
		for _, x in { x1 + 0.5, x2 - 0.5 } do
			box(h, h.shell, x - 0.35, Y0, -5.4, x + 0.35, Y0 + 9, -4.7, pal.trim, M.SmoothPlastic, false, { Name = "Post" })
		end
		box(h, h.shell, x1 - 0.6, Y0 + 9, -6.2, x2 + 0.6, Y0 + 9.5, 0, pal.roof, pal.roofMat or M.RoofShingles, false, { Name = "PorchRoof" })
		box(h, h.shell, x1 - 0.6, Y0 + 8.6, -6.3, x2 + 0.6, Y0 + 9.1, -5.9, pal.trim, M.SmoothPlastic, true)
		-- garde-corps latéraux
		for _, x in { x1 + 0.5, x2 - 0.5 } do
			box(h, h.shell, x - 0.12, Y0 + 2.6, -4.7, x + 0.12, Y0 + 2.9, 0, pal.trim, M.SmoothPlastic, false)
		end
	else
		box(h, h.shell, doorX - 3, 0, -3, doorX + 3, Y0, 0, rgb(186, 182, 176), M.Concrete, false, { Name = "Stoop" })
		box(h, h.shell, doorX - 3, 0, -4.2, doorX + 3, Y0 / 2, -3, rgb(186, 182, 176), M.Concrete, false, { Name = "Step" })
		box(h, h.shell, doorX - 3.2, Y0 + 8.8, -2.6, doorX + 3.2, Y0 + 9.2, 0, pal.modern and pal.trim or pal.roof, M.SmoothPlastic, false, { Name = "Canopy" })
	end
	-- appliques de part et d'autre de la porte
	for _, s in { -1, 1 } do
		mk(h, h.shell, doorX + s * 3.2, Y0 + 6, -0.15, 0.5, 0.9, 0.3, rgb(255, 238, 200), M.Neon, true)
	end
	-- toiture
	local rise = 0
	if spec.roof == "flat" then
		box(h, h.shell, -W / 2, top, 0, W / 2, top + 0.3, D, pal.roof, M.Slate, false, { Name = "Roof" })
		for _, b4 in { { -W / 2, 0, W / 2, 0.6 }, { -W / 2, D - 0.6, W / 2, D }, { -W / 2, 0.6, -W / 2 + 0.6, D - 0.6 }, { W / 2 - 0.6, 0.6, W / 2, D - 0.6 } } do
			box(h, h.shell, b4[1], top, b4[2], b4[3], top + 1.6, b4[4], pal.accent or pal.wall, pal.accentMat or pal.mat, false, { Name = "Parapet" })
		end
		box(h, h.shell, -W / 2 - 0.1, top + 1.6, -0.1, W / 2 + 0.1, top + 1.85, 0.7, pal.trim, M.Metal, true)
		box(h, h.shell, -W / 2 - 0.1, top + 1.6, D - 0.7, W / 2 + 0.1, top + 1.85, D + 0.1, pal.trim, M.Metal, true)
	else
		local pitch = spec.pitch or 0.58
		local wcol = (nF > 1 and pal.upper) or pal.wall
		local wmat = (nF > 1 and pal.upperMat) or pal.mat
		if spec.roof == "frontgable" then
			rise = gableRoof(h, h.shell, CFrame.new(0, top, D / 2) * CFrame.Angles(0, math.pi / 2, 0), D, W, pitch, 1.2, 1, pal, wcol, wmat)
			-- œil-de-bœuf sur le pignon avant
			mk(h, h.shell, 0, top + rise * 0.42, -0.1, 2.6, 2.6, 0.2, pal.trim, M.SmoothPlastic, true)
			mk(h, h.shell, 0, top + rise * 0.42, -0.15, 1.9, 1.9, 0.2, GLASS, M.Glass, true)
		else
			rise = gableRoof(h, h.shell, CFrame.new(0, top, D / 2), W, D, pitch, 1.2, 1, pal, wcol, wmat)
		end
		if spec.chimney then
			local cx = (spec.roof == "frontgable") and (W / 4) * -ds or (W / 2 - 3.5) * -ds
			local cz = spec.roof == "frontgable" and D * 0.7 or D / 2 + 2.5
			box(h, h.shell, cx - 1.3, top - 1, cz - 1.3, cx + 1.3, top + rise + 2.2, cz + 1.3, rgb(140, 84, 66), M.Brick, false, { Name = "Chimney" })
			box(h, h.shell, cx - 1.5, top + rise + 2.2, cz - 1.5, cx + 1.5, top + rise + 2.6, cz + 1.5, rgb(120, 120, 118), M.Concrete, true)
		end
	end
	-- garage attenant
	local ginfo
	if gar then
		local gw = gar.w
		local gx1, gx2
		if gs > 0 then
			gx1, gx2 = W / 2, W / 2 + gw + EXT
		else
			gx1, gx2 = -W / 2 - gw - EXT, -W / 2
		end
		local ix1, ix2 = gs > 0 and gx1 or gx1 + EXT, gs > 0 and gx2 - EXT or gx2
		gcx = (ix1 + ix2) / 2
		gDoorW = gw - 2
		local gz1, gz2 = gz0, gz0 + Dg
		local Hg = K.GARAGE_H
		local gcol, gmat = pal.wall, pal.mat
		box(h, h.shell, ix1, 0, gz1 + EXT, ix2, 0.3, gz2 - EXT, rgb(176, 174, 170), M.Concrete, false, { Name = "GarageFloor" })
		wall(h, h.shell, "x", gx1, gx2, gz1 + EXT / 2, EXT, 0, Hg, { { gcx - gDoorW / 2, gcx + gDoorW / 2, 0, 8.7 } }, gcol, gmat)
		wall(h, h.shell, "x", gx1, gx2, gz2 - EXT / 2, EXT, 0, Hg, {}, gcol, gmat)
		local farX = gs > 0 and gx2 - EXT / 2 or gx1 + EXT / 2
		local gm = (gz1 + gz2) / 2 + 3
		wall(h, h.shell, "z", gz1 + EXT, gz2 - EXT, farX, EXT, 0, Hg, { { gm - 1.5, gm + 1.5, 4.5, 7.5 } }, gcol, gmat)
		window(h, h.shell, "z", gm, farX, gs, 0, 3, 4.5, 7.5, pal, "garage")
		box(h, h.shell, ix1, Hg - 0.6, gz1 + EXT, ix2, Hg, gz2 - EXT, CEIL, M.SmoothPlastic, false, { Name = "GarageCeiling" })
		-- encadrement + porte basculante
		doorTrim(h, h.shell, "x", gcx, gz1 + EXT / 2, EXT, 0, gDoorW, 8.7, pal.trim, { -1 })
		garageDoor(h, h.doors, gcx, gz1 + EXT / 2, 8.7, gDoorW, 8.7, 1, pal.garage or WHITE)
		-- porte de service garage -> maison, avec marche côté garage
		local hwc = gs * (W / 2 - EXT / 2)
		hingedDoor(h, h.doors, "z", gdoorU, hwc, Y0, K.IDOOR_W, K.IDOOR_H, gs, -1, WHITE, "Porte", false)
		doorTrim(h, h.inter, "z", gdoorU, hwc, EXT, Y0, K.IDOOR_W, K.IDOOR_H, WHITE)
		box(h, h.shell, gs > 0 and W / 2 or -W / 2, 0.3, gdoorU - 2.6, gs > 0 and W / 2 + 1.6 or -W / 2 - 1.6, Y0, gdoorU + 2.6, rgb(176, 174, 170), M.Concrete, false, { Name = "Step" })
		-- toit du garage
		if spec.roof == "flat" then
			box(h, h.shell, gx1, Hg, gz1, gx2, Hg + 0.4, gz2, pal.roof, M.Slate, false, { Name = "Roof" })
			box(h, h.shell, gx1 - 0.1, Hg + 0.4, gz1 - 0.1, gx2 + 0.1, Hg + 0.7, gz1 + 0.5, pal.trim, M.Metal, true)
		else
			gableRoof(h, h.shell, CFrame.new((gx1 + gx2) / 2, Hg, (gz1 + gz2) / 2) * CFrame.Angles(0, math.pi / 2, 0), Dg, gw + EXT, 0.5, 0.6, 0.8, pal, gcol, gmat)
		end
		local gr = room("garage", 0, ix1, ix2, gz1 + EXT, gz2 - EXT)
		gr.y = 0.3
		table.insert(gr.keep, R4(gcx - gDoorW / 2, gcx + gDoorW / 2, gz1, gz1 + 9.5)) -- porte basculante
		table.insert(gr.keep, R4(gs > 0 and ix1 or ix2 - 6.5, gs > 0 and ix1 + 6.5 or ix2, gdoorU - 3, gdoorU + 3)) -- porte de service
		gr.doorSides[gs > 0 and "x1" or "x2"] = true
		gr.doorSides.z1 = true
		ginfo = { x = gcx, w = gDoorW, z0 = gz0 }
	end
	-- mobilier
	for _, r in rooms do
		furnish(h, r, rng, pal)
	end
	model.PrimaryPart = found
	model:SetAttribute("HouseType", spec.type or "")
	model:SetAttribute("Palette", spec.pal)
	model:SetAttribute("Floors", nF)
	model.Parent = parent
	return model, { W = W, D = D, doorX = doorX, garage = ginfo, top = top + rise, porch = spec.porch }
end

---------------------------------------------------------------- script serveur des portes
K.DOOR_SCRIPT = [[
-- Portes des maisons (Wrong Way Delivery) : ProximityPrompt "Ouvrir" / "Fermer".
-- Chaque modèle tagué WWD_Door contient une charnière ancrée "Hinge" (sur l'axe réel de rotation) et
-- un panneau soudé ; le serveur anime la charnière, ce qui est répliqué à tous les joueurs.
local CS = game:GetService("CollectionService")
local TS = game:GetService("TweenService")
local INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local function setup(door)
	if door:GetAttribute("Ready") then
		return
	end
	local hinge = door:FindFirstChild("Hinge")
	local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not (hinge and prompt) then
		return
	end
	door:SetAttribute("Ready", true)
	local closed = hinge.CFrame
	local a = math.rad(door:GetAttribute("OpenAngle") or 90)
	local opened = closed * (door:GetAttribute("Axis") == "X" and CFrame.Angles(a, 0, 0) or CFrame.Angles(0, a, 0))
	local solid = {}
	for _, p in door:GetDescendants() do
		if p:IsA("BasePart") and p ~= hinge and p.CanCollide then
			table.insert(solid, p)
		end
	end
	local busy = false
	local function set(open)
		if busy then
			return
		end
		busy = true
		door:SetAttribute("Open", open)
		prompt.ActionText = open and "Fermer" or "Ouvrir"
		prompt.Enabled = false
		for _, p in solid do
			p.CanCollide = false
		end
		local tw = TS:Create(hinge, INFO, { CFrame = open and opened or closed })
		tw:Play()
		tw.Completed:Wait()
		hinge.CFrame = open and opened or closed
		for _, p in solid do
			p.CanCollide = true
		end
		prompt.Enabled = true
		busy = false
	end
	prompt.Triggered:Connect(function()
		set(not door:GetAttribute("Open"))
	end)
	-- commande serveur (tests) : changer l'attribut Request
	door:GetAttributeChangedSignal("Request"):Connect(function()
		set(not door:GetAttribute("Open"))
	end)
end

for _, d in CS:GetTagged("WWD_Door") do
	task.spawn(setup, d)
end
CS:GetInstanceAddedSignal("WWD_Door"):Connect(setup)
]]

function K.installScript()
	local sss = game:GetService("ServerScriptService")
	local s = sss:FindFirstChild("HouseDoors")
	if not s then
		s = Instance.new("Script")
		s.Name = "HouseDoors"
		s.Parent = sss
	end
	s.Source = K.DOOR_SCRIPT
	return s
end

return K
