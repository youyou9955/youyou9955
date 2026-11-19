--!nolint
-- 22 : maison test MeshyAI (une seule, au bord de la ville). Le modèle Meshy (MeshPart "HouseMesh" dans
-- ResidentialDistrict.MeshyTest, porte peinte retirée du maillage) sert d'enveloppe visible ; ce module ajoute :
-- collisions invisibles qui épousent la façade, perron, vraie porte à charnière, et un intérieur complet
-- (murs intérieurs doublés, fenêtres vitrées, plafond, 5 pièces meublées, portes intérieures, lumières).
-- Repère : origine au sol au centre du modèle, façade vers -Z, +X à gauche vu de la rue (comme HouseKit).
-- Relançable : l'ancien contenu "Build" est supprimé à chaque fois.
local Lib = require(script.Parent.Lib)
local HK = require(script.Parent.HouseKit)
local V, rgb, M = Lib.V, Lib.rgb, Lib.M
local L = HK.lib
local F = L.F

-- mesures relevées sur le maillage (studs)
local Y = 1.9 -- dessus du plancher (= perron)
local CEIL = 11.3
local X1, X2 = -19.65, 19.85 -- faces intérieures des murs latéraux
local Z1, Z2 = -10.85, 17.35 -- faces intérieures façade / fond
local DOOR_U, DOOR_W, DOOR_H = -0.3, 4.2, 7.9
local WIN = { -- { u1, u2 } le long du mur, allège 4.4, linteau 10.8
	front = { { -15.6, -8.6 }, { 8.6, 15.6 } },
	back = { { -15.6, -8.6 }, { -2.6, 2.6 }, { 8.6, 15.6 } },
}
local WIN_V1, WIN_V2 = 4.5, 10.6

local WALL = rgb(242, 238, 228)
local WALL_BED = rgb(214, 226, 222)
local WALL_BATH = rgb(232, 240, 244)
local TRIM = rgb(246, 244, 240)
local FLOOR = rgb(176, 132, 92)
local TILE = rgb(226, 224, 218)
local DOOR_COL = rgb(168, 88, 36)
local GLASS = rgb(186, 210, 222)

return function()
	local root = Lib.path("ResidentialDistrict", "MeshyTest")
	local mesh = root:FindFirstChild("HouseMesh")
	assert(mesh, "HouseMesh introuvable dans MeshyTest")
	local old = root:FindFirstChild("Build")
	if old then
		old:Destroy()
	end
	HK.installScript()
	mesh.Anchored = true
	mesh.CanCollide = false
	mesh.CanTouch = false
	mesh.CanQuery = false
	mesh.CastShadow = true
	local base = mesh.CFrame * CFrame.new(0, -mesh.Size.Y / 2, 0)
	local h = { cf = base }
	local build = Lib.model(root, "Build")
	local function grp(name)
		return Lib.model(build, name)
	end
	local col = grp("Collision")
	local shell = grp("Interior")
	local furn = grp("Furniture")
	local doors = grp("Doors")
	local hidden = { Transparency = 1, CastShadow = false, Name = "Collision" }
	local function inv(x1, y1, z1, x2, y2, z2)
		return L.box(h, col, x1, y1, z1, x2, y2, z2, WALL, M.SmoothPlastic, false, hidden)
	end
	local function bx(p, x1, y1, z1, x2, y2, z2, c, mat, deco, extra)
		return L.box(h, p, x1, y1, z1, x2, y2, z2, c, mat, deco, extra)
	end
	local function at(x, z, ang)
		return base * CFrame.new(x, Y, z) * CFrame.Angles(0, ang or 0, 0)
	end

	------------------------------------------------------------ enveloppe : collisions extérieures invisibles
	inv(-20.6, 0, 17.9, 20.8, 12, 18.5) -- fond
	inv(-20.9, 0, -11.5, -20.3, 12, 18.5) -- côtés
	inv(20.5, 0, -11.5, 21.1, 12, 18.5)
	inv(-20.9, 0, -12.1, DOOR_U - DOOR_W / 2, 12, -11.5) -- façade, trouée pour la porte
	inv(DOOR_U + DOOR_W / 2, 0, -12.1, 21.1, 12, -11.5)
	inv(DOOR_U - DOOR_W / 2, Y + DOOR_H + 0.1, -12.1, DOOR_U + DOOR_W / 2, 12, -11.5)
	inv(-20.3, 0, -11.5, 20.5, Y - 0.3, 17.9) -- socle sous le plancher
	-- perron et marches (le maillage dessine trois marches de ~0,65)
	inv(-4.6, 0, -17.6, 4.6, Y, -11.5)
	inv(-5.4, 0, -18.7, 5.4, 1.25, -17.6)
	inv(-5.8, 0, -19.8, 5.8, 0.6, -18.7)

	------------------------------------------------------------ porte d'entrée (vraie porte à charnière, s'ouvre vers l'intérieur)
	L.door(h, doors, "x", DOOR_U, -11.05, Y, DOOR_W, DOOR_H, 1, -1, DOOR_COL, "Porte d'entrée", true)
	-- chambranle blanc des deux côtés (cache les bords du découpage) et tableau de la baie
	local du1, du2 = DOOR_U - DOOR_W / 2, DOOR_U + DOOR_W / 2
	for _, zz in { { -11.95, -11.55 }, { Z1 + 0.38, Z1 + 0.7 } } do
		bx(shell, du1 - 0.55, Y, zz[1], du1, Y + DOOR_H + 0.55, zz[2], TRIM, M.SmoothPlastic, false, { Name = "DoorTrim" })
		bx(shell, du2, Y, zz[1], du2 + 0.55, Y + DOOR_H + 0.55, zz[2], TRIM, M.SmoothPlastic, false, { Name = "DoorTrim" })
		bx(shell, du1 - 0.55, Y + DOOR_H, zz[1], du2 + 0.55, Y + DOOR_H + 0.6, zz[2], TRIM, M.SmoothPlastic, false, { Name = "DoorTrim" })
	end
	bx(shell, du1 - 0.05, Y, -11.6, du1, Y + DOOR_H, Z1 + 0.4, TRIM, M.SmoothPlastic, true)
	bx(shell, du2, Y, -11.6, du2 + 0.05, Y + DOOR_H, Z1 + 0.4, TRIM, M.SmoothPlastic, true)
	bx(shell, du1, Y + DOOR_H, -11.6, du2, Y + DOOR_H + 0.05, Z1 + 0.4, TRIM, M.SmoothPlastic, true)
	bx(shell, du1, Y - 0.05, -11.9, du2, Y + 0.06, Z1 + 0.4, rgb(150, 112, 78), M.Wood, false, { Name = "Threshold" })
	-- applique murale extérieure allumée de part et d'autre (les lanternes du maillage)
	for _, s in { -1, 1 } do
		local lp = L.box(h, shell, DOOR_U + s * 3.2 - 0.2, Y + 6.6, -11.75, DOOR_U + s * 3.2 + 0.2, Y + 7.2, -11.6, rgb(255, 226, 170), M.Neon, true, { Transparency = 1 })
		local pl = Instance.new("PointLight")
		pl.Color, pl.Brightness, pl.Range, pl.Shadows = rgb(255, 214, 160), 0.8, 9, false
		pl.Parent = lp
	end

	------------------------------------------------------------ murs intérieurs doublés, plancher, plafond
	local T = 0.4
	local function holesOf(list)
		local hs = {}
		for _, w in list do
			table.insert(hs, { w[1], w[2], WIN_V1, WIN_V2 })
		end
		return hs
	end
	local fh = holesOf(WIN.front)
	table.insert(fh, { du1, du2, 0, DOOR_H })
	L.wall(h, shell, "x", X1, X2, Z1 + T / 2, T, Y, CEIL - Y, fh, WALL, M.Plaster)
	L.wall(h, shell, "x", X1, X2, Z2 - T / 2, T, Y, CEIL - Y, holesOf(WIN.back), WALL, M.Plaster)
	L.wall(h, shell, "z", Z1, Z2, X1 + T / 2, T, Y, CEIL - Y, {}, WALL, M.Plaster)
	L.wall(h, shell, "z", Z1, Z2, X2 - T / 2, T, Y, CEIL - Y, {}, WALL, M.Plaster)
	-- fenêtres : vitre (collision), cadre et appui côté intérieur
	local function windowsOn(list, zc, inward)
		for _, w in list do
			local u1, u2 = w[1], w[2]
			bx(shell, u1, Y + WIN_V1, zc - 0.05, u2, Y + WIN_V2, zc + 0.05, GLASS, M.Glass, false, { Name = "WindowGlass", Transparency = 0.82 })
			local zi = zc + inward * (T / 2 + 0.06)
			bx(shell, u1 - 0.35, Y + WIN_V1 - 0.35, zi - 0.08, u2 + 0.35, Y + WIN_V1, zi + 0.08 + inward * 0.5, TRIM, M.SmoothPlastic, true)
			bx(shell, u1 - 0.35, Y + WIN_V2, zi - 0.08, u2 + 0.35, Y + WIN_V2 + 0.35, zi + 0.08, TRIM, M.SmoothPlastic, true)
			bx(shell, u1 - 0.35, Y + WIN_V1, zi - 0.08, u1, Y + WIN_V2, zi + 0.08, TRIM, M.SmoothPlastic, true)
			bx(shell, u2, Y + WIN_V1, zi - 0.08, u2 + 0.35, Y + WIN_V2, zi + 0.08, TRIM, M.SmoothPlastic, true)
			bx(shell, (u1 + u2) / 2 - 0.08, Y + WIN_V1, zc - 0.1, (u1 + u2) / 2 + 0.08, Y + WIN_V2, zc + 0.1, TRIM, M.SmoothPlastic, true)
			-- rideaux
			for _, s in { -1, 1 } do
				local cu = s < 0 and u1 - 0.9 or u2 + 0.9
				bx(shell, cu - 0.7, Y + WIN_V1 - 1.2, zi + inward * 0.25, cu + 0.7, Y + WIN_V2 + 0.4, zi + inward * 0.45, rgb(214, 200, 176), M.Fabric, true)
			end
			bx(shell, u1 - 1.8, Y + WIN_V2 + 0.55, zi + inward * 0.3, u2 + 1.8, Y + WIN_V2 + 0.7, zi + inward * 0.42, rgb(70, 60, 52), M.Metal, true)
		end
	end
	windowsOn(WIN.front, Z1 + T / 2, 1)
	windowsOn(WIN.back, Z2 - T / 2, -1)

	-- cloisons : pièces de devant (séjour | cuisine-salle à manger), de fond (chambre | salle de bain | bureau)
	local ZP = 6 -- cloison longitudinale
	local XK = 7 -- séjour / cuisine (grande baie ouverte)
	local XB1, XB2 = -4, 4 -- salle de bain
	local IW, IH = 3.8, 7.6
	local DB, DBA, DO = -8, 0, 7.2 -- portes : chambre, salle de bain, bureau
	L.wall(h, shell, "x", X1 + T, X2 - T, ZP, T, Y, CEIL - Y, { { DB - IW / 2, DB + IW / 2, 0, IH }, { DBA - IW / 2, DBA + IW / 2, 0, IH }, { DO - IW / 2, DO + IW / 2, 0, IH } }, WALL, M.Plaster)
	L.wall(h, shell, "z", Z1 + T, ZP - T / 2, XK, T, Y, CEIL - Y, { { -7.5, 2.5, 0, 8.4 } }, WALL, M.Plaster)
	L.wall(h, shell, "z", ZP + T / 2, Z2 - T, XB1, T, Y, CEIL - Y, {}, WALL_BATH, M.Plaster)
	L.wall(h, shell, "z", ZP + T / 2, Z2 - T, XB2, T, Y, CEIL - Y, {}, WALL_BATH, M.Plaster)
	-- peinture des pièces du fond (fines couches sur les doublages)
	bx(shell, X1 + T, Y, Z2 - T - 0.02, XB1 - T / 2, CEIL, Z2 - T, WALL_BED, M.Plaster, true)
	bx(shell, X1 + T, Y, ZP + T / 2, X1 + T + 0.02, CEIL, Z2 - T, WALL_BED, M.Plaster, true)
	-- portes intérieures (s'ouvrent vers les pièces du fond)
	for _, d in { { DB, "Chambre" }, { DBA, "Salle de bain" }, { DO, "Bureau" } } do
		L.door(h, doors, "x", d[1], ZP, Y, IW, IH, 1, -1, rgb(246, 244, 238), d[2], false)
		for _, s in { -1, 1 } do
			bx(shell, d[1] + s * (IW / 2) - 0.3, Y, ZP - T / 2 - 0.06, d[1] + s * (IW / 2) + 0.3, Y + IH + 0.3, ZP + T / 2 + 0.06, TRIM, M.SmoothPlastic, true)
		end
		bx(shell, d[1] - IW / 2 - 0.3, Y + IH, ZP - T / 2 - 0.06, d[1] + IW / 2 + 0.3, Y + IH + 0.35, ZP + T / 2 + 0.06, TRIM, M.SmoothPlastic, true)
	end
	-- encadrement de la baie séjour/cuisine
	bx(shell, XK - T / 2 - 0.06, Y + 8.4, -7.5, XK + T / 2 + 0.06, Y + 8.75, 2.5, TRIM, M.SmoothPlastic, true)

	-- sols : parquet, carrelage cuisine et salle de bain ; plafond ; plinthes
	bx(shell, X1, Y - 0.4, Z1, X2, Y, Z2, FLOOR, M.WoodPlanks, false, { Name = "Floor" })
	bx(shell, XK + T / 2, Y, Z1, X2, Y + 0.03, ZP - T / 2, TILE, M.CeramicTiles, true)
	bx(shell, XB1 + T / 2, Y, ZP + T / 2, XB2 - T / 2, Y + 0.03, Z2, rgb(214, 226, 232), M.CeramicTiles, true)
	bx(shell, X1, CEIL, Z1, X2, CEIL + 0.3, Z2, rgb(246, 244, 240), M.SmoothPlastic, false, { Name = "Ceiling" })
	local BB = rgb(236, 232, 224)
	bx(shell, X1 + T, Y, Z1 + T, X1 + T + 0.1, Y + 0.5, Z2 - T, BB, M.SmoothPlastic, true)
	bx(shell, X2 - T - 0.1, Y, Z1 + T, X2 - T, Y + 0.5, Z2 - T, BB, M.SmoothPlastic, true)
	bx(shell, X1 + T, Y, Z2 - T - 0.1, X2 - T, Y + 0.5, Z2 - T, BB, M.SmoothPlastic, true)

	-- plafonniers (néon + lumière chaude) dans chaque pièce
	for _, p in { { -10, -2.5 }, { 13, -2.5 }, { -12, 11.7 }, { 0, 11.7 }, { 12, 11.7 }, { 0.5, -7 } } do
		local lp = L.box(h, shell, p[1] - 0.9, CEIL - 0.25, p[2] - 0.9, p[1] + 0.9, CEIL, p[2] + 0.9, rgb(255, 244, 222), M.Neon, true, { Name = "CeilingLight" })
		local pl = Instance.new("PointLight")
		pl.Color, pl.Brightness, pl.Range, pl.Shadows = rgb(255, 228, 190), 1.1, 20, true
		pl.Parent = lp
	end

	------------------------------------------------------------ mobilier
	local P = math.pi
	-- séjour (x -19.6..7, z -10.9..6) : canapé face à la télé, tapis, fauteuil, bibliothèque, plantes, tableaux
	F.tv(furn, at(X1 + T + 0.9, -2.5, -P / 2))
	F.sofa(furn, at(-9.6, -2.5, P / 2), rgb(84, 108, 132))
	F.coffee(furn, at(-14.2, -2.5, P / 2))
	bx(furn, -17.2, Y, -7, -11.2, Y + 0.05, 2, rgb(188, 170, 142), M.Fabric, true)
	F.armchair(furn, at(-14.2, -8.2, 0 + P), rgb(150, 96, 70))
	F.lamp(furn, at(-11.2, 2.6))
	F.bookshelf(furn, at(-4.9, Z1 + T + 0.75, P))
	F.plant(furn, at(-18.2, 4.4))
	F.plant(furn, at(5.6, 4.4))
	F.painting(furn, at(X1 + T + 0.1, -2.5, -P / 2) * CFrame.new(0, 7.3, 0), 4.4, 2.8, rgb(86, 132, 170))
	F.painting(furn, at(-13.5, ZP - T / 2 - 0.1, 0) * CFrame.new(0, 6.6, 0), 3.2, 2.2, rgb(196, 120, 76))
	-- entrée : console et tapis
	F.dresser(furn, at(4.65, Z1 + T + 0.95, P))
	bx(furn, DOOR_U - 2, Y, -10.3, DOOR_U + 2, Y + 0.05, -7.6, rgb(120, 70, 52), M.Fabric, true)
	-- cuisine / salle à manger (x 7..19.8)
	F.kitchen(furn, at(X2 - T - 1.5, -3, P / 2), 14, 1, { cabinet = rgb(236, 234, 226) })
	F.upper(furn, at(X2 - T - 1.35, -1, P / 2), 9, { cabinet = rgb(236, 234, 226) })
	F.table(furn, at(11.6, -2.5, P / 2), 6, 3.6)
	for _, c in { { 9.3, -4, -P / 2 }, { 9.3, -1, -P / 2 }, { 13.9, -4, P / 2 }, { 13.9, -1, P / 2 } } do
		F.chair(furn, at(c[1], c[2], c[3]))
	end
	F.plant(furn, at(8.6, 4.4))
	-- chambre (x -19.6..-4, z 6..17.4)
	F.bed(furn, at(X1 + T + 4.3, 11.9, -P / 2), 6.4, 8.2, rgb(96, 128, 112))
	F.nightstand(furn, at(X1 + T + 1, 7.5, -P / 2))
	F.nightstand(furn, at(X1 + T + 1, 16.3, -P / 2))
	F.wardrobe(furn, at(XB1 - T / 2 - 1.3, 13.6, P / 2))
	bx(furn, -16.4, Y, 9, -9.2, Y + 0.05, 14.8, rgb(206, 196, 178), M.Fabric, true)
	F.painting(furn, at(X1 + T + 0.1, 11.9, -P / 2) * CFrame.new(0, 7.6, 0), 4, 2.4, rgb(96, 140, 92))
	-- salle de bain (x -4..4)
	F.tub(furn, at(0, Z2 - T - 1.7, 0))
	F.toilet(furn, at(XB1 + T / 2 + 1.5, 11.5, -P / 2))
	F.vanity(furn, at(XB2 - T / 2 - 1.1, 11.2, P / 2))
	F.towel(furn, at(XB2 - T / 2 - 0.2, 8, P / 2))
	-- bureau (x 4..19.8)
	F.desk(furn, at(X2 - T - 2.05, 9.8, P / 2))
	F.bed(furn, at(12.8, Z2 - T - 4.1, 0), 4.4, 7.6, rgb(170, 90, 80))
	F.bookshelf(furn, at(XB2 + T / 2 + 0.75, 14.2, -P / 2))
	F.plant(furn, at(18.4, 16))

	-- streaming : la maison et son intérieur restent groupés
	build.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local n = 0
	for _, d in build:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return ("maison Meshy : %d pièces, %d portes"):format(n, #doors:GetChildren())
end
