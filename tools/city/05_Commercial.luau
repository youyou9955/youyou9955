--!nolint
-- 05 : quartier commercial (station-service, rue commerçante, supermarché, centre commercial, chantier, concurrent).
local Lib = require(script.Parent.Lib)
local M = Enum.Material
local C = Lib.C
local V = Vector3.new
local W = Lib.WALK

local SHOPS = {
	{ "BURGER RETOUR", Color3.fromRGB(220, 60, 40) }, { "PIZZA SENS UNIQUE", Color3.fromRGB(40, 150, 70) },
	{ "TACOS TOUT DROIT", Color3.fromRGB(240, 160, 30) }, { "SUSHI DÉRAPAGE", Color3.fromRGB(200, 40, 60) },
	{ "MAGASIN DE CARTONS VIDES", Color3.fromRGB(160, 120, 80) }, { "JOUETS ET KLAXONS", Color3.fromRGB(70, 110, 220) },
	{ "TÉLÉPHONES PERDUS", Color3.fromRGB(90, 90, 110) }, { "CRÊPES À CONTRESENS", Color3.fromRGB(230, 120, 160) },
	{ "VÉLOS SANS ROUES", Color3.fromRGB(50, 160, 170) }, { "CINÉMA LE RÉTROVISEUR", Color3.fromRGB(120, 40, 120) },
	{ "SALLE DE SPORT LE DÉTOUR", Color3.fromRGB(30, 30, 30) }, { "LAVERIE LA ROUE LIBRE", Color3.fromRGB(80, 170, 230) },
}

local function parkingLot(parent, x1, x2, z1, z2, rows)
	Lib.slab(parent, x1, x2, z1, z2, W, 1, C.asphalt, M.Asphalt, { Name = "ParkingLot" })
	local d = (z2 - z1) / rows
	for r = 0, rows - 1 do
		local n = math.floor((x2 - x1 - 8) / 10)
		Lib.parkingRow(parent, CFrame.new((x1 + x2) / 2, W, z1 + d * (r + 0.5)), n, 10, math.min(16, d * 0.6))
	end
	for k = 1, 3 do
		Lib.cone(parent, CFrame.new(Lib.rng:NextNumber(x1 + 4, x2 - 4), W, Lib.rng:NextNumber(z1 + 4, z2 - 4)))
	end
end

local function billboard(parent, pos, face, text, bg, fg)
	local m = Lib.model(parent, "Billboard")
	for _, x in { -8, 8 } do
		Lib.part(m, CFrame.lookAt(pos, pos + face) * CFrame.new(x, 9, 0), V(1, 18, 1), C.metal, M.Metal)
	end
	Lib.sign(m, CFrame.lookAt(pos, pos + face) * CFrame.new(0, 22, -0.6), V(28, 10, 0.6), text, bg, fg, { glow = true })
	Lib.deco(m, CFrame.lookAt(pos, pos + face) * CFrame.new(0, 16.6, -1.5), V(28, 0.4, 2), C.metal, M.DiamondPlate)
end

return function()
	local D = Lib.path("Districts", "Commercial")
	local rng = Lib.rng
	local shopIdx = 1
	local function nextShop()
		local s = SHOPS[(shopIdx - 1) % #SHOPS + 1]
		shopIdx += 1
		return s
	end

	-- (4,3) Station-service « ESSENCE-CIEL »
	do
		local c = Lib.cell(4, 3)
		local f = Lib.model(D, "StationEssenceCiel")
		Lib.slab(f, c.ix1, c.ix2, c.iz1, c.iz2, W, 1, Color3.fromRGB(150, 150, 150), M.Concrete, { Name = "Forecourt" })
		local cz = c.cz + 10
		Lib.part(f, CFrame.new(c.cx, W + 14.5, cz), V(60, 2, 34), Color3.new(1, 1, 1), M.Metal, { Name = "Canopy" })
		Lib.deco(f, CFrame.new(c.cx, W + 14.5, cz - 17.1), V(60, 2, 0.2), Color3.fromRGB(40, 170, 90), M.Neon, { Name = "CanopyStripe" })
		for _, x in { -24, 24 } do
			for _, z in { -12, 12 } do
				Lib.part(f, CFrame.new(c.cx + x, W + 7, cz + z), V(1.4, 14, 1.4), Color3.new(1, 1, 1), M.Metal, { Name = "Pillar" })
			end
		end
		for _, x in { -14, 0, 14 } do
			Lib.part(f, CFrame.new(c.cx + x, W + 0.3, cz), V(4, 0.6, 18), C.concrete, M.Concrete, { Name = "PumpIsland" })
			for _, z in { -5, 5 } do
				local pump = Lib.part(f, CFrame.new(c.cx + x, W + 3.3, cz + z), V(2, 5.4, 3), Color3.fromRGB(40, 170, 90), M.Metal, { Name = "Pump" })
				Lib.label(pump, Enum.NormalId.Left, "SANS PLOMB\n(sans garantie)", Color3.new(1, 1, 1))
				Lib.label(pump, Enum.NormalId.Right, "DIESEL\n1,99 € / litre / virage", Color3.new(1, 1, 1))
			end
		end
		Lib.shop(f, Lib.facing(V(c.cx, W, c.iz1 + 14), "N"), 40, 20, "ESSENCE-CIEL MARKET", Color3.fromRGB(235, 235, 225), Color3.fromRGB(40, 170, 90))
		-- totem prix
		local tot = V(c.ix1 + 6, W, c.iz2 - 6)
		Lib.part(f, CFrame.new(tot + V(0, 9, 0)), V(4, 18, 1.2), Color3.fromRGB(40, 170, 90), M.Metal, { Name = "PriceTotem" })
		Lib.sign(f, CFrame.lookAt(tot + V(0, 13, 0), tot + V(0, 13, 1)) * CFrame.new(0, 0, -0.7), V(3.6, 8, 0.2), "ESSENCE\nCIEL\n\n1,99\n2,09", Color3.fromRGB(20, 30, 30), Color3.fromRGB(255, 230, 80), { glow = true, double = true })
		-- station de lavage
		local cw = V(c.ix2 - 16, W, c.cz - 30)
		Lib.part(f, CFrame.new(cw + V(0, 7, -9)), V(16, 14, 1), Color3.fromRGB(60, 140, 220), M.Concrete, { Name = "CarWash" })
		Lib.part(f, CFrame.new(cw + V(0, 7, 9)), V(16, 14, 1), Color3.fromRGB(60, 140, 220), M.Concrete, { Name = "CarWash" })
		Lib.part(f, CFrame.new(cw + V(0, 14.5, 0)), V(16, 1, 19), Color3.fromRGB(60, 140, 220), M.Concrete, { Name = "CarWashRoof" })
		for _, x in { -5, 5 } do
			Lib.deco(f, CFrame.new(cw + V(x, 7, 0)) * CFrame.Angles(0, 0, 0), V(2, 12, 2), Color3.fromRGB(250, 80, 160), M.Fabric, { Name = "Brush", Shape = Enum.PartType.Block })
		end
		Lib.sign(f, CFrame.lookAt(cw + V(0, 16.5, -9.6), cw + V(0, 16.5, -20)), V(16, 3, 0.3), "LAVAGE (sens au choix)", Color3.fromRGB(60, 140, 220), Color3.new(1, 1, 1), { glow = true })
	end

	-- (5,3) Rue commerçante : boutiques sur les 4 côtés
	do
		local c = Lib.cell(5, 3)
		local f = Lib.model(D, "RueCommercante")
		Lib.slab(f, c.ix1, c.ix2, c.iz1, c.iz2, W, 1, Color3.fromRGB(205, 198, 188), M.Pavement, { Name = "Plaza" })
		for _, side in { "N", "S" } do
			local n = 4
			local span = c.w / n
			for k = 0, n - 1 do
				local s = nextShop()
				local x = c.ix1 + span * (k + 0.5)
				local z = side == "N" and (c.iz2 - 13) or (c.iz1 + 13)
				Lib.shop(f, Lib.facing(V(x, W, z), side), span - 1.5, 24, s[1], Color3.fromHSV(rng:NextNumber(), 0.15, 0.92), s[2], rng:NextInteger(12, 18))
			end
		end
		-- terrasses au centre
		for x = c.ix1 + 16, c.ix2 - 16, 18 do
			Lib.deco(f, CFrame.new(x, W + 1.6, c.cz), V(3, 0.3, 3), Color3.new(1, 1, 1), M.Metal, { Name = "Table" })
			Lib.deco(f, CFrame.new(x, W + 0.8, c.cz), V(0.3, 1.6, 0.3), C.dark, M.Metal)
			Lib.deco(f, CFrame.new(x, W + 4, c.cz), V(0.2, 6.6, 0.2), C.dark, M.Metal)
			Lib.deco(f, CFrame.new(x, W + 7.2, c.cz), V(7, 0.3, 7), Color3.fromHSV(rng:NextNumber(), 0.6, 0.9), M.Fabric, { Name = "Parasol" })
		end
		-- guirlandes lumineuses
		for x = c.ix1 + 8, c.ix2 - 8, 6 do
			Lib.deco(f, CFrame.new(x, W + 14, c.cz), V(0.6, 0.6, 0.6), Color3.fromRGB(255, 220, 150), M.Neon, { Shape = Enum.PartType.Ball, CastShadow = false })
		end
	end

	-- (6,3) Le concurrent : OOPSIE EXPRESS
	do
		local c = Lib.cell(6, 3)
		local f = Lib.model(D, "OopsieExpress")
		Lib.slab(f, c.ix1, c.ix2, c.iz1, c.iz2, W, 1, Color3.fromRGB(140, 140, 135), M.Concrete, { Name = "Lot" })
		local b = Lib.tower(f, Lib.facing(V(c.cx, W, c.cz + 10), "S"), 70, 40, 3, { color = Color3.fromRGB(150, 150, 165), glass = Color3.fromRGB(110, 120, 130), name = "OopsieHQ", roofSign = "OOPSIE EXPRESS — Livré... un jour", signColor = Color3.fromRGB(120, 70, 160), signText = Color3.new(1, 1, 1) })
		-- logo escargot
		local snail = V(c.cx, W + 34 + 9, c.cz + 22)
		Lib.deco(f, CFrame.new(snail), V(10, 10, 4), Color3.fromRGB(190, 130, 60), M.SmoothPlastic, { Shape = Enum.PartType.Ball, Name = "SnailShell" })
		Lib.deco(f, CFrame.new(snail + V(-7, -3, 0)), V(9, 3, 3), Color3.fromRGB(150, 200, 120), M.SmoothPlastic, { Name = "SnailBody" })
		-- camionnettes en panne (décor statique) et panneaux moqueurs
		for k = 0, 3 do
			local p = V(c.ix1 + 14 + k * 16, W, c.iz1 + 16)
			Lib.part(f, CFrame.new(p + V(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(k == 2 and 8 or 0)), V(7, 5, 13), Color3.fromRGB(150, 110, 180), M.Metal, { Name = "BrokenVan" })
			Lib.deco(f, CFrame.new(p + V(0, 6.2, 0)), V(1, 1, 1), Color3.fromRGB(80, 80, 80), M.Neon, { Name = "Smoke", Transparency = 0.6 })
		end
		Lib.postSign(f, CFrame.lookAt(V(c.ix1 + 6, W, c.iz1 + 3), V(c.ix1 + 6, W, c.iz1 - 5)), "OOPSIE EXPRESS : « On arrive bientôt »\n(depuis 2019)", Color3.fromRGB(120, 70, 160), Color3.new(1, 1, 1), 12, 4, 4)
		billboard(f, V(c.ix2 - 18, W, c.iz2 - 8), V(0, 0, 1), "WRONG WAY DELIVERY\nPlus rapide qu'Oopsie. Dans l'autre sens.", C.brandOrange, Color3.new(1, 1, 1))
	end

	-- (4,2) Supermarché MÉGA-MARCHÉ + grand parking
	do
		local c = Lib.cell(4, 2)
		local f = Lib.model(D, "MegaMarche")
		parkingLot(f, c.ix1, c.ix2, c.iz2 - 50, c.iz2, 2)
		Lib.slab(f, c.ix1, c.ix2, c.iz1, c.iz2 - 50, W, 1, C.concrete, M.Concrete)
		local m = Lib.tower(f, Lib.facing(V(c.cx, W, c.iz1 + 32), "N"), c.w - 8, 56, 2, { color = Color3.fromRGB(240, 240, 235), glass = Color3.fromRGB(170, 210, 230), floorH = 12, roofSign = "MÉGA-MARCHÉ — Tout. Sauf le parking.", signColor = Color3.fromRGB(220, 40, 40), signText = Color3.new(1, 1, 1), name = "Supermarket", pillars = false })
		for k = 0, 5 do
			Lib.deco(f, CFrame.new(c.ix1 + 10 + k * 3, W + 1.6, c.iz2 - 54), V(2.4, 2.6, 4), Color3.fromRGB(180, 180, 190), M.DiamondPlate, { Name = "Cart" })
		end
	end

	-- (5,2) Centre commercial « LES 4 CHEMINS »
	do
		local c = Lib.cell(5, 2)
		local f = Lib.model(D, "CentreCommercial")
		Lib.slab(f, c.ix1, c.ix2, c.iz1, c.iz2, W, 1, C.asphalt, M.Asphalt)
		Lib.tower(f, Lib.facing(V(c.cx, W, c.cz + 14), "S"), c.w - 10, c.d - 46, 3, { color = Color3.fromRGB(230, 220, 200), glass = Color3.fromRGB(150, 190, 220), floorH = 11, top = "crown", roofSign = "CENTRE COMMERCIAL LES 4 CHEMINS\n(tous mènent à la sortie)", signColor = Color3.fromRGB(30, 60, 140), signText = Color3.fromRGB(255, 230, 120), name = "Mall" })
		Lib.parkingRow(f, CFrame.new(c.cx, W, c.iz1 + 12), math.floor((c.w - 10) / 10), 10, 14)
	end

	-- (6,2) Chantier avec grue à tour
	do
		local c = Lib.cell(6, 2)
		local f = Lib.model(D, "Chantier")
		Lib.slab(f, c.ix1, c.ix2, c.iz1, c.iz2, 0.4, 0.8, Color3.fromRGB(150, 120, 90), M.Ground, { Name = "Dirt" })
		-- palissade
		for _, s in { { V(c.ix1, 0, c.iz1), V(c.ix2, 0, c.iz1) }, { V(c.ix1, 0, c.iz2), V(c.ix2, 0, c.iz2) }, { V(c.ix1, 0, c.iz1), V(c.ix1, 0, c.iz2 - 20) }, { V(c.ix2, 0, c.iz1), V(c.ix2, 0, c.iz2) } } do
			Lib.fence(f, s[1], s[2], 8, Color3.fromRGB(240, 240, 240), true, M.Plastic)
		end
		Lib.sign(f, CFrame.lookAt(V(c.cx, 5, c.iz1 - 0.3), V(c.cx, 5, c.iz1 - 5)), V(40, 4, 0.2), "CHANTIER : FUTUR SIÈGE D'OOPSIE EXPRESS (livraison prévue : jamais)", Color3.fromRGB(240, 190, 30), Color3.new(0, 0, 0))
		-- immeuble en construction (squelette)
		local b = V(c.cx - 10, 0.8, c.cz)
		for fl = 0, 4 do
			Lib.slab(f, b.X - 25, b.X + 25, b.Z - 20, b.Z + 20, b.Y + fl * 10 + 0.6, 0.8, C.concrete, M.Concrete, { Name = "Floor" })
			if fl < 4 then
				for _, x in { -24, -8, 8, 24 } do
					for _, z in { -19, 0, 19 } do
						Lib.part(f, CFrame.new(b.X + x, b.Y + fl * 10 + 5.6, b.Z + z), V(1.2, 10, 1.2), C.concrete, M.Concrete, { Name = "Column" })
					end
				end
			end
		end
		-- échafaudage
		for y = 2, 40, 6 do
			Lib.deco(f, CFrame.new(b.X, b.Y + y, b.Z - 22.5), V(52, 0.3, 2), C.wood, M.WoodPlanks, { Name = "Scaffold" })
		end
		-- grue à tour
		local g = V(c.cx + 38, 0.8, c.cz - 30)
		local yellow = Color3.fromRGB(245, 190, 30)
		Lib.part(f, CFrame.new(g + V(0, 1, 0)), V(8, 2, 8), C.concrete, M.Concrete)
		Lib.part(f, CFrame.new(g + V(0, 46, 0)), V(3, 90, 3), yellow, M.Metal, { Name = "CraneMast" })
		Lib.deco(f, CFrame.new(g + V(0, 92, 0)), V(4, 4, 4), yellow, M.Metal, { Name = "CraneCab" })
		Lib.deco(f, CFrame.new(g + V(-28, 94.5, 0)), V(70, 1.6, 1.6), yellow, M.Metal, { Name = "CraneJib" })
		Lib.deco(f, CFrame.new(g + V(18, 94, 0)), V(6, 4, 4), C.concrete, M.Concrete, { Name = "Counterweight" })
		Lib.deco(f, CFrame.new(g + V(-48, 70, 0)), V(0.2, 48, 0.2), C.dark, M.Metal, { Name = "Cable" })
		Lib.deco(f, CFrame.new(g + V(-48, 45, 0)), V(5, 4, 5), Color3.fromRGB(196, 150, 96), M.Cardboard, { Name = "HangingParcel" })
		-- tas de sable, cônes, bétonnière, toilettes de chantier
		Lib.ball(V(c.ix1 + 20, -2, c.iz2 - 20), 9, M.Sand)
		Lib.ball(V(c.ix1 + 32, -3, c.iz2 - 14), 7, M.Ground)
		for k = 0, 8 do
			Lib.cone(f, CFrame.new(c.ix1 + 6, 0.8, c.iz2 - 4 - k * 2.4))
		end
		Lib.part(f, CFrame.new(c.ix2 - 8, 4.5, c.iz2 - 8), V(4, 7.5, 4), Color3.fromRGB(40, 120, 200), M.Plastic, { Name = "PortableToilet" })
		Lib.part(f, CFrame.new(c.ix2 - 20, 3.5, c.iz2 - 10) * CFrame.Angles(0, 0, math.rad(90)), V(7, 5, 5), Color3.fromRGB(230, 120, 30), M.Metal, { Shape = Enum.PartType.Cylinder, Name = "CementMixer" })
	end

	-- (4..6, 1) Commerces + restos drive + parkings
	for i = 4, 6 do
		local c = Lib.cell(i, 1)
		local f = Lib.model(D, ("Block_%d_1"):format(i))
		parkingLot(f, c.ix1, c.ix2, c.cz - 18, c.cz + 18, 2)
		Lib.slab(f, c.ix1, c.ix2, c.iz1, c.cz - 18, W, 1, C.concrete, M.Concrete)
		Lib.slab(f, c.ix1, c.ix2, c.cz + 18, c.iz2, W, 1, C.concrete, M.Concrete)
		for _, side in { "N", "S" } do
			local n = 3
			local span = c.w / n
			for k = 0, n - 1 do
				local s = nextShop()
				local x = c.ix1 + span * (k + 0.5)
				local z = side == "N" and (c.iz2 - 14) or (c.iz1 + 14)
				Lib.shop(f, Lib.facing(V(x, W, z), side), span - 2, 26, s[1], Color3.fromHSV(rng:NextNumber(), 0.2, 0.9), s[2], rng:NextInteger(12, 16))
			end
		end
		if i == 5 then
			billboard(f, V(c.cx, W, c.cz), V(0, 0, 1), "ASSURANCE TOUS RISQUES\n(sauf les vôtres)", Color3.fromRGB(30, 60, 140), Color3.new(1, 1, 1))
		elseif i == 4 then
			billboard(f, V(c.cx, W, c.cz), V(-1, 0, 0), "GPS « TOUT DROIT »\nIl ne connaît qu'un mot.", Color3.fromRGB(20, 20, 20), Color3.fromRGB(120, 255, 140))
		end
	end
	return "commercial ok"
end
