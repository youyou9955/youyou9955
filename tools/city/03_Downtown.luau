--!nolint
-- 03 : centre-ville (tours, parc central, place publique, parking à étages).
local Lib = require(script.Parent.Lib)
local M = Enum.Material
local C = Lib.C
local V = Vector3.new
local W = Lib.WALK

local TOWER_COLORS = {
	Color3.fromRGB(225, 220, 210), Color3.fromRGB(190, 200, 210), Color3.fromRGB(210, 190, 170),
	Color3.fromRGB(150, 160, 175), Color3.fromRGB(235, 230, 220), Color3.fromRGB(170, 120, 100),
}
local GLASS = { Color3.fromRGB(110, 160, 200), Color3.fromRGB(90, 130, 150), Color3.fromRGB(140, 180, 210), Color3.fromRGB(80, 110, 130) }
local ROOF_ADS = {
	"OOPSIE EXPRESS — Livré... un jour", "BANQUE DU DEMI-TOUR", "ASSURANCE TOUS RISQUES\n(sauf les vôtres)",
	"GPS PERDU ? Nous aussi.", "CAFÉ CONTRESENS", "HÔTEL LE CUL-DE-SAC", "CARTONS & FILS depuis 1987",
}
local SHOP_SIGNS = { "Boulangerie Le Pain Perdu", "Pressing Express (lent)", "Kebab du Rond-Point", "Librairie Sens Dessus Dessous", "Pharmacie", "Fleuriste", "Opticien Vue Floue", "Coiffure Hair Bag" }

local function towerBlock(parent, c, adsLeft)
	-- dalle piétonne + 4 tours (une par quadrant), façade vers la rue la plus proche
	Lib.slab(parent, c.ix1, c.ix2, c.iz1, c.iz2, W, 1, Color3.fromRGB(200, 196, 188), M.Pavement, { Name = "Plaza" })
	local hw, hd = c.w / 2, c.d / 2
	for _, qx in { -1, 1 } do
		for _, qz in { -1, 1 } do
			local tw = Lib.rng:NextNumber(30, hw - 10)
			local td = Lib.rng:NextNumber(28, hd - 10)
			local px = c.cx + qx * (hw - tw / 2 - 4)
			local pz = c.cz + qz * (hd - td / 2 - 4)
			local side = Lib.rng:NextNumber() < 0.5 and (qx > 0 and "E" or "W") or (qz > 0 and "N" or "S")
			local cf = Lib.facing(V(px, W, pz), side)
			if side == "E" or side == "W" then
				tw, td = td, tw
			end
			local floors = Lib.rng:NextInteger(5, 15)
			local style = {
				color = Lib.pick(TOWER_COLORS), glass = Lib.pick(GLASS), floorH = 9,
				top = Lib.pick({ "antenna", "tank", "crown", "none" }),
			}
			if floors <= 7 then
				style.sign = Lib.pick(SHOP_SIGNS)
				style.signColor = Color3.fromHSV(Lib.rng:NextNumber(), 0.6, 0.55)
			end
			if adsLeft[1] and floors >= 9 and Lib.rng:NextNumber() < 0.7 then
				style.roofSign = table.remove(adsLeft, 1)
				style.signColor = C.dark
				style.signText = Color3.fromRGB(255, 220, 120)
			end
			Lib.tower(parent, cf, tw, td, floors, style)
		end
	end
	-- arbres en bacs et bancs au centre de l'îlot
	for k = 1, 4 do
		local p = V(c.cx + Lib.rng:NextNumber(-8, 8), W, c.cz + Lib.rng:NextNumber(-8, 8))
		Lib.part(parent, CFrame.new(p + V(0, 0.8, 0)), V(5, 1.6, 5), C.concrete, M.Concrete, { Name = "Planter" })
		Lib.tree(Lib.path("Vegetation"), p + V(0, 1.6, 0), "round", 0.8)
	end
	Lib.bench(parent, CFrame.new(c.cx, W, c.cz + 10))
	Lib.bench(parent, CFrame.new(c.cx, W, c.cz - 10) * CFrame.Angles(0, math.pi, 0))
	-- bennes dans les « ruelles »
	Lib.part(parent, CFrame.new(c.cx + 14, W + 2, c.cz), V(6, 4, 3.5), Color3.fromRGB(40, 90, 60), M.Metal, { Name = "Dumpster" })
end

local function centralPark(parent, c)
	local veg = Lib.path("Vegetation")
	local park = Lib.model(parent, "ParcCentral")
	-- allées en croix et en diagonale
	Lib.slab(park, c.ix1, c.ix2, c.cz - 4, c.cz + 4, 0.3, 0.6, Color3.fromRGB(205, 185, 150), M.Ground, { Name = "Path" })
	Lib.slab(park, c.cx - 4, c.cx + 4, c.iz1, c.iz2, 0.3, 0.6, Color3.fromRGB(205, 185, 150), M.Ground, { Name = "Path" })
	-- étang (terrain) avec petit ponton
	local pond = V(c.cx + 30, 0, c.cz + 30)
	workspace.Terrain:FillCylinder(CFrame.new(pond.X, -2, pond.Z), 4, 22, M.Air)
	workspace.Terrain:FillCylinder(CFrame.new(pond.X, -3, pond.Z), 2, 22, M.Water)
	Lib.slab(park, pond.X - 22, pond.X - 8, pond.Z - 2, pond.Z + 2, 0.6, 0.6, C.wood, M.WoodPlanks, { Name = "Pier" })
	for k = 1, 3 do
		Lib.deco(park, CFrame.new(pond.X + Lib.rng:NextNumber(-10, 10), -0.7, pond.Z + Lib.rng:NextNumber(-10, 10)), V(1.2, 0.8, 1.6), Color3.fromRGB(250, 250, 250), M.SmoothPlastic, { Name = "Duck" })
	end
	-- fontaine centrale
	Lib.disc(park, V(c.cx, 0, c.cz), 9, 1.4, 1.4, C.concrete, M.Marble, { Name = "FountainBasin" })
	Lib.disc(park, V(c.cx, 0, c.cz), 8, 1.5, 0.3, Color3.fromRGB(70, 150, 200), M.Glass, { Name = "FountainWater", Transparency = 0.3, CanCollide = false })
	Lib.part(park, CFrame.new(c.cx, 3.5, c.cz), V(2, 5, 2), C.concrete, M.Marble)
	Lib.deco(park, CFrame.new(c.cx, 6.5, c.cz), V(2.2, 2, 2.2), Color3.fromRGB(196, 150, 96), M.Cardboard, { Name = "MiniParcel" })
	-- kiosque à musique
	local g = V(c.cx - 32, 0, c.cz - 30)
	Lib.disc(park, g, 10, 1.2, 1.2, C.wood, M.WoodPlanks, { Name = "Gazebo" })
	for a = 0, 300, 60 do
		Lib.part(park, CFrame.new(g + V(math.cos(math.rad(a)) * 8.5, 5.5, math.sin(math.rad(a)) * 8.5)), V(0.8, 8.6, 0.8), Color3.new(1, 1, 1), M.Wood)
	end
	Lib.deco(park, CFrame.new(g + V(0, 11, 0)) * CFrame.Angles(0, 0, math.rad(90)), V(2, 22, 22), Color3.fromRGB(150, 60, 50), M.Slate, { Shape = Enum.PartType.Cylinder, Name = "GazeboRoof" })
	-- arbres, massifs, bancs
	for k = 1, 34 do
		local p = V(Lib.rng:NextNumber(c.ix1 + 4, c.ix2 - 4), 0, Lib.rng:NextNumber(c.iz1 + 4, c.iz2 - 4))
		if math.abs(p.X - c.cx) > 8 and math.abs(p.Z - c.cz) > 8 and (p - pond).Magnitude > 28 and (p - g).Magnitude > 14 then
			Lib.tree(veg, p)
		end
	end
	for _, o in { { 12, 6 }, { -12, 6 }, { 12, -6 }, { -12, -6 } } do
		Lib.flowerBed(park, CFrame.new(c.cx + o[1] * 2, 0, c.cz + o[2] * 2.5), 8, 4)
	end
	for t = -40, 40, 20 do
		if math.abs(t) > 10 then
			Lib.bench(park, CFrame.new(c.cx + t, 0.3, c.cz + 6.5) * CFrame.Angles(0, math.pi, 0))
			Lib.trash(park, CFrame.new(c.cx + t + 4, 0.3, c.cz - 6.5))
		end
	end
	Lib.postSign(park, CFrame.lookAt(V(c.cx - 10, W, c.iz2 + 2), V(c.cx - 10, W, c.iz2 + 10)), "PARC CENTRAL — pelouse interdite aux camionnettes", Color3.fromRGB(30, 100, 50), Color3.new(1, 1, 1), 10, 3, 4)
end

local function publicPlaza(parent, c)
	local pl = Lib.model(parent, "PlaceDuColisPerdu")
	Lib.slab(pl, c.ix1, c.ix2, c.iz1, c.iz2, W, 1, Color3.fromRGB(215, 205, 190), M.Pavement, { Name = "Plaza" })
	-- motif en damier
	for x = c.ix1 + 10, c.ix2 - 10, 20 do
		for z = c.iz1 + 10, c.iz2 - 10, 20 do
			if ((x + z) / 20) % 2 < 1 then
				Lib.mark(pl, CFrame.new(x, W + 0.02, z), V(10, 0.05, 10), Color3.fromRGB(190, 175, 160))
			end
		end
	end
	-- statue : le livreur qui tient son colis à l'envers
	local s = V(c.cx, W, c.cz)
	Lib.part(pl, CFrame.new(s + V(0, 2, 0)), V(10, 4, 10), C.concrete, M.Marble, { Name = "Pedestal" })
	local bronze = Color3.fromRGB(150, 110, 60)
	Lib.part(pl, CFrame.new(s + V(0, 7, 0)), V(3, 6, 2), bronze, M.Metal, { Name = "StatueBody" })
	Lib.part(pl, CFrame.new(s + V(0, 11, 0)), V(2.2, 2.2, 2.2), bronze, M.Metal, { Name = "StatueHead", Shape = Enum.PartType.Ball })
	Lib.deco(pl, CFrame.new(s + V(0, 12.4, 0)), V(2.6, 0.6, 2.8), bronze, M.Metal, { Name = "Cap" })
	Lib.deco(pl, CFrame.new(s + V(0, 14.5, -0.5)) * CFrame.Angles(0, 0, math.rad(180)), V(3.4, 2.6, 3), bronze, M.Metal, { Name = "UpsideDownParcel" })
	for _, x in { -1.9, 1.9 } do
		Lib.deco(pl, CFrame.new(s + V(x, 11, -0.3)) * CFrame.Angles(0, 0, math.rad(x > 0 and -15 or 15)), V(0.8, 4.4, 0.8), bronze, M.Metal)
	end
	local plaque = Lib.deco(pl, CFrame.new(s + V(0, 2, -5.05)), V(8, 2, 0.1), Color3.fromRGB(60, 50, 40))
	Lib.label(plaque, Enum.NormalId.Front, "AU LIVREUR INCONNU\nqui a livré dans le bon sens (une fois)", Color3.fromRGB(240, 210, 140))
	-- 4 fontaines-jets, bancs, arbres en bac, kiosques
	for _, o in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
		local p = s + V(o[1] * 30, 0, o[2] * 30)
		Lib.disc(pl, p, 6, W + 1, 1, C.concrete, M.Marble, { Name = "Basin" })
		Lib.disc(pl, p, 5.3, W + 1.1, 0.2, Color3.fromRGB(70, 150, 200), M.Glass, { Transparency = 0.3, CanCollide = false, Name = "Water" })
		Lib.part(pl, CFrame.new(p + V(0, 2.5, 0)), V(4, 1.4, 4), Color3.fromRGB(120, 200, 230), M.Glass, { Transparency = 0.5, CanCollide = false, CanQuery = false, CanTouch = false, Name = "Jet" })
		Lib.bench(pl, CFrame.lookAt(p + V(-o[1] * 10, 0, 0), p))
		Lib.bench(pl, CFrame.lookAt(p + V(0, 0, -o[2] * 10), p))
		local tp = s + V(o[1] * 48, 0, o[2] * 48)
		Lib.part(pl, CFrame.new(tp + V(0, 0.8, 0)), V(6, 1.6, 6), C.concrete, M.Concrete, { Name = "Planter" })
		Lib.tree(Lib.path("Vegetation"), tp + V(0, 1.6, 0), "round", 1)
	end
	for _, k in { { -42, 0, "GLACES À L'ENVERS", Color3.fromRGB(240, 120, 170) }, { 42, 0, "JOURNAUX D'HIER", Color3.fromRGB(60, 120, 200) } } do
		local p = s + V(k[1], 0, k[2])
		Lib.part(pl, CFrame.new(p + V(0, 3, 0)), V(8, 6, 6), Color3.new(1, 1, 1), M.Plaster, { Name = "Kiosk" })
		Lib.deco(pl, CFrame.new(p + V(0, 6.6, 0)), V(10, 0.6, 8), k[4], M.Fabric)
		Lib.sign(pl, CFrame.lookAt(p + V(0, 5, 0), p + V(0, 5, -1)) * CFrame.new(0, 0, 3.2), V(7, 1.6, 0.2), k[3], k[4], Color3.new(1, 1, 1))
	end
	for _, z in { -1, 1 } do
		local p = s + V(0, 0, z * 50)
		Lib.part(pl, CFrame.new(p + V(0, 10, 0)), V(0.5, 20, 0.5), Color3.new(1, 1, 1), M.Metal, { Name = "Flagpole" })
		Lib.deco(pl, CFrame.new(p + V(2.5, 17.5, 0)), V(5, 3, 0.1), C.brandOrange, M.Fabric, { Name = "Flag" })
	end
end

local function parkingGarage(parent, c)
	local pk = Lib.model(parent, "ParkingEtage")
	local x1, x2, z1, z2 = c.ix1 + 3, c.ix2 - 3, c.iz1 + 6, c.iz1 + 86
	local col = Color3.fromRGB(185, 185, 180)
	Lib.slab(pk, c.ix1, c.ix2, c.iz1, c.iz2, W, 1, C.asphaltLight, M.Asphalt, { Name = "Ground" })
	local L1, L2 = 12, 24
	local s = 12 -- largeur des voies de rampe
	-- niveau 1 (trou au-dessus de la rampe 1, côté ouest)
	Lib.slab(pk, x1 + s, x2, z1, z2, L1, 1, col, M.Concrete, { Name = "Level1" })
	Lib.slab(pk, x1, x1 + s, z1, z1 + 20, L1, 1, col, M.Concrete, { Name = "Level1" })
	-- niveau 2 / toit (trou au-dessus de la rampe 2, côté est)
	Lib.slab(pk, x1, x2 - s, z1, z2, L2, 1, col, M.Concrete, { Name = "Roof" })
	Lib.slab(pk, x2 - s, x2, z2 - 20, z2, L2, 1, col, M.Concrete, { Name = "Roof" })
	-- rampes : 1 (sol -> N1) monte vers -Z ; 2 (N1 -> N2) monte vers +Z
	Lib.beam(pk, V(x1 + s / 2, W, z2 - 10), V(x1 + s / 2, L1, z1 + 20), s, 1, C.asphalt, M.Asphalt, { Name = "Ramp1" }, true)
	Lib.beam(pk, V(x2 - s / 2, L1, z1 + 10), V(x2 - s / 2, L2, z2 - 20), s, 1, C.asphalt, M.Asphalt, { Name = "Ramp2" }, true)
	-- poteaux
	for x = x1 + s + 8, x2 - s - 4, 18 do
		for z = z1 + 6, z2 - 6, 20 do
			Lib.part(pk, CFrame.new(x, (W + L2) / 2, z), V(1.6, L2 - W, 1.6), col, M.Concrete, { Name = "Column" })
		end
	end
	-- garde-corps périphériques aux niveaux 1 et 2 (avec ouverture d'entrée au sol)
	for _, y in { L1, L2 } do
		Lib.part(pk, CFrame.new((x1 + x2) / 2, y + 1.5, z1 + 0.4), V(x2 - x1, 3, 0.8), Color3.fromRGB(230, 120, 40), M.Concrete, { Name = "Wall" })
		Lib.part(pk, CFrame.new(x1 + 0.4, y + 1.5, (z1 + z2) / 2), V(0.8, 3, z2 - z1), Color3.fromRGB(230, 120, 40), M.Concrete, { Name = "Wall" })
		Lib.part(pk, CFrame.new(x2 - 0.4, y + 1.5, (z1 + z2) / 2), V(0.8, 3, z2 - z1), Color3.fromRGB(230, 120, 40), M.Concrete, { Name = "Wall" })
		Lib.part(pk, CFrame.new((x1 + x2) / 2 + s / 2, y + 1.5, z2 - 0.4), V(x2 - x1 - s, 3, 0.8), Color3.fromRGB(230, 120, 40), M.Concrete, { Name = "Wall" })
	end
	-- places
	for _, y in { W, L1, L2 } do
		Lib.parkingRow(pk, CFrame.new((x1 + x2) / 2, y, z1 + 9), 8, 10, 14)
		Lib.parkingRow(pk, CFrame.new((x1 + x2) / 2, y, z2 - 9), 8, 10, 14)
	end
	Lib.sign(pk, CFrame.lookAt(V((x1 + x2) / 2, L1 + 7, z2 + 0.4), V((x1 + x2) / 2, L1 + 7, z2 + 5)), V(40, 5, 0.4), "PARKING ÉTAGÉ — 3 niveaux, 0 place", Color3.fromRGB(30, 80, 170), Color3.new(1, 1, 1), { glow = true })
	-- tour de bureaux sur le reste de l'îlot
	Lib.tower(parent, Lib.facing(V(c.cx, W, (z2 + c.iz2) / 2 + 2), "N"), c.w - 30, (c.iz2 - z2) - 14, 11, { color = Lib.pick(TOWER_COLORS), top = "antenna", roofSign = "CARTONS & FILS depuis 1987", signColor = C.dark, signText = Color3.fromRGB(255, 220, 120) })
end

return function()
	local D = Lib.path("Districts", "Downtown")
	local ads = table.clone(ROOF_ADS)
	for i = 1, 3 do
		for j = 1, 3 do
			local c = Lib.cell(i, j)
			local f = Lib.model(D, ("Block_%d_%d"):format(i, j))
			if i == 2 and j == 2 then
				centralPark(f, c)
			elseif i == 3 and j == 3 then
				publicPlaza(f, c)
			elseif i == 3 and j == 2 then
				parkingGarage(f, c)
			else
				towerBlock(f, c, ads)
			end
		end
	end
	return "downtown ok"
end
