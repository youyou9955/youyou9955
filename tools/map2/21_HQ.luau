--!nolint
-- 21 : rez-de-chaussée visitable du QG WRONG WAY DELIVERY. Le volume plein (Body) devient une coque :
-- rez-de-chaussée creux (accueil, open space, salle de réunion, salle de pause, vestiaires, toilettes,
-- stockage, préparation des colis), étages supérieurs fermés au-dessus. Façade, enseigne, tour et toit
-- d'origine conservés (raccourcis au-dessus du rez-de-chaussée quand ils descendaient jusqu'au sol).
local Lib = require(script.Parent.Lib)
local HK = require(script.Parent.HouseKit)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C
local L = HK.lib
local box, ax, wall, props = L.box, L.ax, L.wall, L.props
local F = L.F

local RED, ORANGE, DARK = C.brandRed, C.brandOrange, rgb(38, 40, 50)
local WHITE = rgb(242, 240, 234)
local WALL_IN = rgb(238, 236, 230)
local GLASS = rgb(170, 210, 230)

local function P(h, parent, lcf, size, col, mat, collide, extra)
	return Lib.part(parent, h.cf * lcf, size, col, mat or M.SmoothPlastic, props(not collide, extra))
end
local function at(h, x, z, rot)
	return h.cf * CFrame.new(x, 0.36, z) * CFrame.Angles(0, rot or 0, 0)
end
local function light(h, parent, x, z, y, lit)
	local p = P(h, parent, CFrame.new(x, y - 0.1, z), V(2.4, 0.15, 6), rgb(255, 250, 238), M.Neon, false, { Transparency = 0.15 })
	if lit then
		local l = Instance.new("PointLight")
		l.Range, l.Brightness, l.Color, l.Shadows = 22, 0.4, rgb(255, 246, 230), false
		l.Parent = p
	end
end
local function sign(parent, part, text, col)
	Lib.label(part, Enum.NormalId.Front, text, col or WHITE, nil, Enum.Font.FredokaOne, true)
end

return function()
	local hq = Lib.path("DeliveryHeadquarters")
	local main = hq:FindFirstChild("MainBuilding")
	local body = main and main:FindFirstChild("Body")
	if not body then
		return "QG : déjà transformé (pas de Body)"
	end
	local backups = game:GetService("ServerStorage"):FindFirstChild("Backups") or Instance.new("Folder")
	backups.Name = "Backups"
	backups.Parent = game:GetService("ServerStorage")
	if not backups:FindFirstChild("HQ_MainBuilding") then
		local b = main:Clone()
		b.Name = "HQ_MainBuilding"
		b.Parent = backups
	end
	HK.installScript()
	local W, D = body.Size.X, body.Size.Z
	local y0 = body.Position.Y - body.Size.Y / 2 -- dessus du socle
	local top = body.Position.Y + body.Size.Y / 2
	local ccf = body.CFrame - body.Position + V(body.Position.X, y0, body.Position.Z)
	local h = { cf = ccf * CFrame.new(0, 0, -D / 2) } -- origine : milieu de la façade, -Z vers la rue
	local GH, EXT = 12.5, 0.8
	local xa, xb, za, zb = -W / 2 + EXT, W / 2 - EXT, EXT, D - EXT

	-- 1. nettoyer ce qui occupait le rez-de-chaussée
	local function lpos(p)
		return h.cf:PointToObjectSpace(p.Position)
	end
	for _, p in main:GetDescendants() do
		if p:IsA("BasePart") and p ~= body then
			local lp = lpos(p)
			local inFoot = math.abs(lp.X) <= W / 2 + 1.2 and lp.Z >= -1.2 and lp.Z <= D + 1.2
			if p.Name == "Atrium" then
				p:Destroy()
			elseif p.Name == "SignWall" or p.Name == "Tower" then
				-- raccourcir au-dessus du rez-de-chaussée
				local bottom = p.Position.Y - p.Size.Y / 2
				local newBottom = y0 + GH + 1
				if bottom < newBottom then
					local topY = p.Position.Y + p.Size.Y / 2
					p.Size = V(p.Size.X, topY - newBottom, p.Size.Z)
					p.CFrame = p.CFrame + V(0, (newBottom - bottom) / 2, 0)
				end
			elseif math.abs(lp.X) < 14 and lp.Z > -14.5 and lp.Z < -1.2 and lp.Y < 10.5 and p.Name ~= "Steps" then
				p:Destroy() -- montants et porte peinte de l'ancien sas vitré
			elseif inFoot and lp.Y < GH - 0.5 and p.Size.Y < GH and p.Name ~= "Plinth" and p.Name ~= "Steps" then
				p:Destroy() -- fenêtres décoratives du rez-de-chaussée, portes peintes
			end
		end
	end
	do
		local nb = y0 + GH + 0.5
		local rot = body.CFrame - body.Position
		local bx, bz = body.Position.X, body.Position.Z
		body.Size = V(W, top - nb, D)
		body.CFrame = CFrame.new(bx, (top + nb) / 2, bz) * rot
	end

	local gf = Lib.model(main, "GroundFloor")
	local shell = Lib.model(gf, "Shell")
	local inter = Lib.model(gf, "Interior")
	local furn = Lib.model(gf, "Furniture")
	local doors = Lib.model(gf, "Doors")
	local concrete = rgb(214, 212, 206)

	-- 2. coque du rez-de-chaussée : sol, plafond, murs extérieurs percés
	box(h, inter, xa, 0, za, xb, 0.36, zb, rgb(200, 198, 194), M.SmoothPlastic, true, { Name = "Floor" })
	box(h, inter, xa, GH - 0.2, za, xb, GH + 0.5, zb, rgb(240, 238, 234), M.SmoothPlastic, true, { Name = "Ceiling" })
	local DW, DH = 7.2, 8.6
	local frontHoles = { { -DW / 2, DW / 2, 0, DH + 0.3 } }
	for _, s in { -1, 1 } do
		for k = 0, 4 do
			local u1 = s * (7 + k * 11)
			local u2 = s * (7 + k * 11 + 8)
			if math.abs(u2) < W / 2 - 3 then
				table.insert(frontHoles, { math.min(u1, u2), math.max(u1, u2), 2.4, 9.6 })
			end
		end
	end
	wall(h, shell, "x", -W / 2, W / 2, EXT / 2, EXT, 0, GH + 0.5, frontHoles, concrete, M.SmoothPlastic)
	local backHoles = { { 18, 30, 0, 10.5 } } -- grand passage vers l'aile logistique
	for x = -W / 2 + 8, W / 2 - 8, 12 do
		if x + 3 < 16 or x - 3 > 32 then
			table.insert(backHoles, { x - 2.5, x + 2.5, 3.5, 9 })
		end
	end
	wall(h, shell, "x", -W / 2, W / 2, D - EXT / 2, EXT, 0, GH + 0.5, backHoles, concrete, M.SmoothPlastic)
	for _, s in { -1, 1 } do
		local holes = {}
		for z = 8, D - 8, 12 do
			table.insert(holes, { z - 2.5, z + 2.5, 3.5, 9 })
		end
		wall(h, shell, "z", EXT, D - EXT, s * (W / 2 - EXT / 2), EXT, 0, GH + 0.5, holes, concrete, M.SmoothPlastic)
		for _, ho in holes do
			P(h, shell, CFrame.new(s * (W / 2 - EXT / 2), 6.25, (ho[1] + ho[2]) / 2), V(0.2, 5.5, 5), GLASS, M.Glass, false, { Transparency = 0.4 })
		end
	end
	for _, ho in frontHoles do
		if ho[3] > 0 then
			ax(h, shell, "x", (ho[1] + ho[2]) / 2, 6, EXT / 2, ho[2] - ho[1], 7.2, 0.2, GLASS, M.Glass, false, { Transparency = 0.4 })
			ax(h, shell, "x", (ho[1] + ho[2]) / 2, 2.25, -0.1, ho[2] - ho[1] + 0.4, 0.3, 0.6, DARK, M.Metal, true)
		end
	end
	for _, ho in backHoles do
		if ho[3] > 0 then
			ax(h, shell, "x", (ho[1] + ho[2]) / 2, 6.25, D - EXT / 2, ho[2] - ho[1], 5.5, 0.2, GLASS, M.Glass, false, { Transparency = 0.4 })
		end
	end
	-- entrée : double porte vitrée (portes de ShopKit) + porte de quai à l'arrière
	local function glass(u, c, w, hinge, label, axis)
		local d = L.door(h, doors, axis or "x", u, c, 0.36, w, DH, 1, hinge, DARK, label, false)
		local panel = d:FindFirstChild("Panel")
		for _, p in d:GetChildren() do
			if p:IsA("BasePart") and p ~= panel and p.Name ~= "Hinge" and p.Shape ~= Enum.PartType.Ball then
				p:Destroy()
			end
		end
		panel.Material, panel.Color, panel.Transparency = M.Glass, GLASS, 0.45
		return d
	end
	glass(-DW / 4, EXT / 2, DW / 2, -1, "Entrée du QG")
	glass(DW / 4, EXT / 2, DW / 2, 1, "Entrée du QG")
	L.garageDoor(h, doors, 24, D - EXT / 2, 10.5, 12, 10.2, -1, rgb(210, 214, 220))

	-- 3. cloisons : couloir est-ouest (z 22..28), pièces devant et derrière
	local CZ1, CZ2 = 22, 28
	local T = 0.5
	-- façade côté couloir des pièces de devant (ouvertures et portes)
	local function partition(axis, a, b, c, holes)
		wall(h, inter, axis, a, b, c, T, 0.36, GH - 0.56, holes, WALL_IN, M.Plaster)
	end
	-- devant : open space (x -63..-15, ouvert sur le couloir), accueil (x -15..15, ouvert), salle de pause (15..40), réunion (40..63)
	partition("x", -W / 2 + EXT, -15, CZ1, { { -40, -32, 0, 8 } })
	partition("x", 15, W / 2 - EXT, CZ1, { { 26, 30, 0, 7.5 }, { 50, 54, 0, 7.5 } })
	partition("z", za, CZ1, -15, { { 8, 16, 0, 8 } })
	partition("z", za, CZ1, 15, {})
	partition("z", za, CZ1, 40, {})
	L.door(h, doors, "x", 28, CZ1, 0.36, 4, 7.5, -1, 1, WHITE, "Salle de pause", false)
	L.door(h, doors, "x", 52, CZ1, 0.36, 4, 7.5, -1, 1, WHITE, "Salle de réunion", false)
	-- derrière : vestiaires (-63..-45), toilettes (-45..-30), stockage (-30..-10), préparation des colis (-10..63)
	partition("x", -W / 2 + EXT, W / 2 - EXT, CZ2, { { -56, -52, 0, 7.5 }, { -40, -36, 0, 7.5 }, { -22, -18, 0, 7.5 }, { 2, 14, 0, 9 } })
	partition("z", CZ2, zb, -45, {})
	partition("z", CZ2, zb, -30, {})
	partition("z", CZ2, zb, -10, {})
	L.door(h, doors, "x", -54, CZ2, 0.36, 4, 7.5, 1, 1, WHITE, "Vestiaires", false)
	L.door(h, doors, "x", -38, CZ2, 0.36, 4, 7.5, 1, 1, WHITE, "Toilettes", false)
	L.door(h, doors, "x", -20, CZ2, 0.36, 4, 7.5, 1, 1, WHITE, "Stockage", false)
	-- plaques de porte
	for _, s in { { -54, "VESTIAIRES" }, { -38, "TOILETTES" }, { -20, "STOCKAGE" }, { 8, "PRÉPARATION DES COLIS" } } do
		local p = ax(h, inter, "x", s[1], 9.2, CZ2 - 0.3, s[1] == 8 and 12 or 4.4, 1, 0.08, RED, M.SmoothPlastic, true)
		sign(inter, p, s[2])
	end
	for _, s in { { 28, "SALLE DE PAUSE" }, { 52, "RÉUNION" } } do
		local p = ax(h, inter, "x", s[1], 9.2, CZ1 + 0.3, 5, 1, 0.08, RED, M.SmoothPlastic, true)
		Lib.label(p, Enum.NormalId.Back, s[2], WHITE, nil, Enum.Font.FredokaOne, true)
	end
	-- bande aux couleurs de la marque dans le couloir
	for _, z in { CZ1 + 0.3, CZ2 - 0.3 } do
		ax(h, inter, "x", 0, 1.2, z, W - 2, 0.5, 0.06, ORANGE, M.SmoothPlastic, false)
	end

	-- 4. éclairage
	local n = 0
	for z = 5, D - 4, 8 do
		for x = -W / 2 + 7, W / 2 - 7, 12 do
			n += 1
			light(h, furn, x, z, GH - 0.2, n % 2 == 1)
		end
	end

	-- 5. accueil : comptoir, mur logo, attente
	P(h, furn, CFrame.new(0, 1.9, 13), V(12, 3.6, 2.4), RED, M.SmoothPlastic, true)
	P(h, furn, CFrame.new(0, 3.8, 13), V(12.4, 0.2, 2.8), rgb(240, 240, 236), M.Marble, false)
	for _, s in { -3, 3 } do
		P(h, furn, CFrame.new(s, 4.6, 13.4), V(1.6, 1.2, 0.15), rgb(30, 32, 36), M.SmoothPlastic, false)
		F.chair(furn, at(h, s, 15.2), DARK)
	end
	partition("x", -11, 11, CZ1, {})
	local logo = ax(h, inter, "x", 0, 6.6, CZ1 - 0.4, 18, 6, 0.2, DARK, M.SmoothPlastic, true)
	Lib.label(logo, Enum.NormalId.Front, "WRONG WAY\nDELIVERY", WHITE, nil, Enum.Font.FredokaOne, true)
	ax(h, inter, "x", 0, 3.3, CZ1 - 0.45, 18, 0.5, 0.1, RED, M.SmoothPlastic, false)
	local cbox = P(h, furn, CFrame.new(12, 2, 19) * CFrame.Angles(0, math.rad(20), 0), V(3.6, 3.6, 3.6), rgb(214, 160, 96), M.Cardboard, true)
	for _, s in { -1, 1 } do
		F.sofa(furn, at(h, s * 9, 4, math.pi), rgb(60, 64, 76))
		F.plant(furn, at(h, s * 13.5, 3))
	end
	F.coffee(furn, at(h, -9, 8))
	-- 6. open space : îlots de bureaux avec écrans
	for x = -58, -22, 9 do
		for _, z in { 6, 16.5 } do
			for _, side in { -1, 1 } do
				local b = at(h, x, z + side * 2, side > 0 and math.pi or 0)
				F.desk(furn, b)
				Lib.part(furn, b * CFrame.new(0, 4.1, 1.5), V(2, 1.3, 0.12), rgb(30, 32, 36), M.SmoothPlastic, props(true))
				Lib.part(furn, b * CFrame.new(0, 4.1, 1.43), V(1.8, 1.1, 0.02), rgb(90, 160, 220), M.Neon, props(true))
			end
		end
	end
	for _, z in { 6, 16.5 } do
		F.plant(furn, at(h, -18, z))
	end
	local ban = ax(h, inter, "x", -39, 8.6, za + 0.15, 20, 1.6, 0.06, ORANGE, M.SmoothPlastic, false)
	Lib.label(ban, Enum.NormalId.Back, "LIVRER À CONTRESENS, C'EST NOTRE MÉTIER", WHITE, nil, Enum.Font.FredokaOne, true)
	-- 7. salle de pause : cuisine, tables, canapé, distributeur
	F.kitchen(furn, at(h, 27.5, za + 1.4, math.pi), 18, 1, { cabinet = rgb(236, 234, 228) })
	for _, x in { 21, 33 } do
		F.table(furn, at(h, x, 12), 4, 3)
		for _, s in { -1, 1 } do
			F.chair(furn, at(h, x + s * 1.2, 12 - 2.6, math.pi), RED)
			F.chair(furn, at(h, x + s * 1.2, 12 + 2.6), RED)
		end
	end
	P(h, furn, CFrame.new(38, 3.6, 18.5), V(3, 7.2, 2.4), RED, M.SmoothPlastic, true)
	P(h, furn, CFrame.new(38, 4.4, 17.25), V(2.2, 4, 0.1), rgb(180, 210, 230), M.Glass, false, { Transparency = 0.3 })
	-- 8. salle de réunion : grande table, chaises, écran
	F.table(furn, at(h, 51.5, 11), 12, 4)
	for k = -2, 2 do
		F.chair(furn, at(h, 51.5 + k * 2.3, 11 - 3, math.pi), DARK)
		F.chair(furn, at(h, 51.5 + k * 2.3, 11 + 3), DARK)
	end
	local scr = P(h, furn, CFrame.new(W / 2 - EXT - 0.2, 6, 11) * CFrame.Angles(0, math.pi / 2, 0), V(8, 4.5, 0.2), rgb(20, 22, 26), M.SmoothPlastic, false)
	local scr2 = P(h, furn, CFrame.new(W / 2 - EXT - 0.32, 6, 11) * CFrame.Angles(0, math.pi / 2, 0), V(7.6, 4.1, 0.04), rgb(60, 140, 210), M.Neon, false)
	Lib.label(scr2, Enum.NormalId.Front, "OBJECTIF : 0 COLIS À L'ENDROIT", WHITE, nil, Enum.Font.FredokaOne, true)
	-- 9. vestiaires : casiers et bancs
	for z = CZ2 + 2, zb - 2, 2 do
		P(h, furn, CFrame.new(-W / 2 + EXT + 1, 3.5, z + 0.95), V(2, 7, 1.9), rgb(70, 110, 170), M.Metal, true)
		P(h, furn, CFrame.new(-W / 2 + EXT + 2.02, 4.6, z + 0.95), V(0.05, 0.6, 0.15), rgb(200, 200, 204), M.Metal, false)
	end
	for _, z in { 36, 46 } do
		P(h, furn, CFrame.new(-54, 1.3, z), V(2, 0.4, 7), rgb(150, 112, 76), M.Wood, true)
		P(h, furn, CFrame.new(-54, 0.8, z), V(0.6, 0.9, 6), rgb(80, 80, 84), M.Metal, false)
	end
	-- 10. toilettes : cabines fermées par une porte, lavabos
	for k = 0, 2 do
		local cx = -43 + k * 4.4
		if cx < -31.5 then
			wall(h, inter, "z", zb - 6, zb, cx - 2.2, 0.2, 0.36, 7, {}, rgb(200, 210, 220), M.SmoothPlastic)
			F.toilet(furn, at(h, cx, zb - 1.2))
			L.door(h, doors, "x", cx, zb - 6, 0.36, 2.8, 6.6, -1, 1, rgb(200, 210, 220), "Cabine", false)
		end
	end
	wall(h, inter, "x", -45 + T / 2, -30 - T / 2, zb - 6, 0.2, 0.36, 7, { { -43 - 1.4, -43 + 1.4, 0, 6.8 }, { -38.6 - 1.4, -38.6 + 1.4, 0, 6.8 }, { -34.2 - 1.4, -34.2 + 1.4, 0, 6.8 } }, rgb(200, 210, 220), M.SmoothPlastic)
	for _, x in { -41, -35 } do
		F.vanity(furn, at(h, x, CZ2 + 1.3, math.pi))
	end
	-- 11. stockage : étagères métalliques et cartons
	for _, x in { -26, -19, -14 } do
		F.shelf(furn, at(h, x, zb - 0.9))
	end
	for k = 0, 2 do
		P(h, furn, CFrame.new(-24 + k * 5, 0.6, 38), V(4, 0.5, 4), rgb(170, 130, 86), M.WoodPlanks, true)
		P(h, furn, CFrame.new(-24 + k * 5, 2.1, 38), V(3.6, 2.6, 3.6), rgb(196, 150, 96), M.Cardboard, true)
	end
	-- 12. préparation des colis : tapis roulant, tables d'emballage, balances, chariots
	P(h, furn, CFrame.new(25, 2, 40), V(56, 0.6, 3), rgb(60, 60, 64), M.Metal, true)
	P(h, furn, CFrame.new(25, 2.35, 40), V(56, 0.1, 2.4), rgb(30, 30, 32), M.Rubber, false)
	for x = -2, 52, 6 do
		P(h, furn, CFrame.new(x, 0.95, 40), V(0.3, 1.3, 2.6), rgb(90, 90, 96), M.Metal, false)
	end
	for x = 0, 50, 4.5 do
		P(h, furn, CFrame.new(x + Random.new(x * 7 + 1):NextNumber(-1, 1), 3.1, 40), V(1.6, 1.2, 1.6), rgb(196, 150, 96), M.Cardboard, false)
	end
	for _, x in { -2, 10, 22, 34, 46 } do
		F.table(furn, at(h, x + 3, 33), 6, 3)
		P(h, furn, CFrame.new(x + 1.5, 3.4, 33), V(1.6, 0.4, 1.6), rgb(200, 200, 204), M.Metal, false) -- balance
		P(h, furn, CFrame.new(x + 4.5, 3.6, 33), V(2, 1.2, 1.6), rgb(196, 150, 96), M.Cardboard, false)
		if x ~= 22 then -- passage vers la porte de quai
			F.table(furn, at(h, x + 3, 47), 6, 3)
			P(h, furn, CFrame.new(x + 3, 3.4, 47), V(1.2, 0.6, 0.6), RED, M.SmoothPlastic, false) -- dévidoir de ruban adhésif
		end
	end
	local prep = ax(h, inter, "x", 25, 9.8, zb - 0.15, 30, 2, 0.06, RED, M.SmoothPlastic, false)
	Lib.label(prep, Enum.NormalId.Front, "ZONE DE PRÉPARATION · VÉRIFIEZ QUE L'ADRESSE EST BIEN À L'ENVERS", WHITE, nil, Enum.Font.FredokaOne, true)
	for k = 0, 2 do
		local cx = 56 + (k % 2) * 3
		P(h, furn, CFrame.new(cx, 1.4, 50 - k * 3.5), V(2.4, 0.3, 3), rgb(70, 74, 80), M.Metal, true)
		P(h, furn, CFrame.new(cx, 2.4, 50 - k * 3.5), V(2, 1.8, 2.6), rgb(196, 150, 96), M.Cardboard, true)
	end
	local parts = 0
	for _, d in gf:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	return ("QG : rez-de-chaussée visitable (%d pièces, %dx%d)"):format(parts, W, D)
end
