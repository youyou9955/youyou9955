--!nolint
-- 07 : zone commerciale (x 0..900, z 0..720, hors QG). Supermarché, station-service, restaurants,
-- centre commercial et grande roue, galerie marchande, cinéma, magasin de bricolage, concession auto.
local Lib = require(script.Parent.Lib)
local Build = require(script.Parent.Build)
local Plan = require(script.Parent.Plan)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C

local rng = Random.new(707)
local function edge(v, kind, s)
	return v + s * (Plan.W[kind] / 2 + Plan.SW[kind])
end
local darker, lighter = Build.darker, Build.lighter

-- Grand magasin : boîte avec façade colorée, enseigne géante, entrée vitrée, auvent
local function bigStore(parent, cf, w, d, h, wall, accent, name, opts)
	opts = opts or {}
	local m = Lib.model(parent, opts.model or "Store")
	Lib.part(m, cf * CFrame.new(0, h / 2, 0), V(w, h, d), wall, M.SmoothPlastic, { Name = "Body" })
	local f = Build.face(cf, w, d, 1)
	-- fronton coloré
	Lib.part(m, f * CFrame.new(0, h - 4, -0.8), V(w + 2, 10, 1.6), accent, M.SmoothPlastic, { Name = "Fascia" })
	local sg = Lib.fine(m, f * CFrame.new(0, h - 4, -1.7), V(math.min(w * 0.6, 70), 8, 0.2), accent, M.SmoothPlastic)
	Lib.label(sg, Enum.NormalId.Front, name, C.white, nil, Enum.Font.FredokaOne, true)
	-- vitrine sur toute la largeur du rez-de-chaussée
	Lib.fine(m, f * CFrame.new(0, 6, -0.2), V(w - 8, 9, 0.3), rgb(40, 44, 52), M.SmoothPlastic)
	Lib.fine(m, f * CFrame.new(0, 6, -0.4), V(w - 10, 8, 0.1), rgb(170, 215, 238), M.Glass, { Transparency = 0.2, Reflectance = 0.2 })
	for k = -3, 3 do
		Lib.fine(m, f * CFrame.new(k * (w - 10) / 7, 6, -0.5), V(0.5, 8, 0.2), rgb(40, 44, 52), M.SmoothPlastic)
	end
	-- auvent sur poteaux
	Lib.part(m, f * CFrame.new(0, 11.5, -5), V(w * 0.5, 1, 10), accent, M.SmoothPlastic, { Name = "Canopy" })
	for _, s in { -1, 1 } do
		Lib.part(m, f * CFrame.new(s * (w * 0.25 - 1), 5.5, -9.5), V(1, 11, 1), darker(accent, 0.3), M.Metal)
	end
	-- détails de toit et côtés
	for i = 2, 4 do
		local sf, fw = Build.face(cf, w, d, i)
		Lib.fine(m, sf * CFrame.new(0, h - 1.5, -0.2), V(fw + 0.4, 3, 0.4), accent, M.SmoothPlastic)
	end
	for k = 1, 4 do
		Lib.part(m, cf * CFrame.new(rng:NextNumber(-w / 3, w / 3), h + 1.5, rng:NextNumber(-d / 3, d / 3)), V(6, 3, 5), rgb(190, 194, 200), M.Metal)
	end
	-- caddies alignés
	if opts.carts then
		for k = 0, 5 do
			local c = f * CFrame.new(w / 2 - 12 + k * 1.2, 1.4, -16)
			Lib.fine(m, c, V(2, 1.6, 3), rgb(200, 205, 210), M.DiamondPlate, { Transparency = 0.2 })
		end
	end
	return m
end

local function restaurant(parent, cf, w, d, wall, roof, accent, name)
	local m = Lib.model(parent, "Restaurant")
	local h = 13
	Lib.part(m, cf * CFrame.new(0, h / 2, 0), V(w, h, d), wall, M.SmoothPlastic, { Name = "Body" })
	local f = Build.face(cf, w, d, 1)
	Lib.fine(m, f * CFrame.new(0, 5.5, -0.2), V(w - 4, 8, 0.3), rgb(40, 44, 52), M.SmoothPlastic)
	Lib.fine(m, f * CFrame.new(0, 5.5, -0.4), V(w - 6, 7, 0.1), rgb(170, 215, 238), M.Glass, { Transparency = 0.2 })
	-- toit incliné coloré
	Lib.wedge(m, cf * CFrame.new(0, h + 2.5, -d / 4) * CFrame.Angles(0, 0, 0), V(w + 2, 5, d / 2 + 1), roof, M.SmoothPlastic)
	Lib.wedge(m, cf * CFrame.new(0, h + 2.5, d / 4) * CFrame.Angles(0, math.pi, 0), V(w + 2, 5, d / 2 + 1), roof, M.SmoothPlastic)
	-- grande enseigne sur mât
	local pole = f * CFrame.new(-w / 2 - 6, 0, -8)
	Lib.part(m, pole * CFrame.new(0, 12, 0), V(1.4, 24, 1.4), darker(accent, 0.3), M.Metal)
	local sg = Lib.part(m, pole * CFrame.new(0, 26, 0), V(14, 7, 1.4), accent, M.SmoothPlastic, { CanCollide = false })
	Lib.label(sg, Enum.NormalId.Front, name, C.white, nil, Enum.Font.FredokaOne, true)
	Lib.label(sg, Enum.NormalId.Back, name, C.white, nil, Enum.Font.FredokaOne, true)
	local sg2 = Lib.fine(m, f * CFrame.new(0, h - 1.5, -0.4), V(w * 0.7, 2.6, 0.2), accent, M.SmoothPlastic)
	Lib.label(sg2, Enum.NormalId.Front, name, C.white, nil, Enum.Font.FredokaOne, true)
	-- terrasse avec parasols
	for k = -1, 1 do
		local t = f * CFrame.new(k * 9, 0, -9)
		Lib.cylDeco(m, t * CFrame.new(0, 1.5, 0), 0.3, 4, C.white, M.SmoothPlastic)
		Lib.part(m, t * CFrame.new(0, 0.8, 0), V(0.4, 1.4, 0.4), C.dark, M.Metal, { CanCollide = false })
		Lib.cylDeco(m, t * CFrame.new(0, 5, 0), 0.4, 8, k == 0 and accent or C.white, M.Fabric)
		Lib.part(m, t * CFrame.new(0, 3, 0), V(0.3, 4, 0.3), C.dark, M.Metal, { CanCollide = false })
	end
	return m
end

local function gasStation(parent, cf)
	local m = Lib.model(parent, "StationService")
	local red, yel = rgb(220, 40, 40), rgb(255, 200, 30)
	-- auvent
	local can = cf * CFrame.new(0, 0, -6)
	Lib.part(m, can * CFrame.new(0, 0.2, 0), V(70, 0.4, 40), rgb(200, 198, 192), M.Concrete)
	Lib.part(m, can * CFrame.new(0, 17, 0), V(64, 3, 32), C.white, M.SmoothPlastic, { Name = "Canopy" })
	Lib.fine(m, can * CFrame.new(0, 17, -16.1), V(64, 1.6, 0.3), red, M.SmoothPlastic)
	Lib.fine(m, can * CFrame.new(0, 15.6, -16.1), V(64, 0.8, 0.3), yel, M.SmoothPlastic)
	Lib.fine(m, can * CFrame.new(0, 17, 16.1), V(64, 1.6, 0.3), red, M.SmoothPlastic)
	for _, x in { -20, 0, 20 } do
		for _, z in { -6, 6 } do
			Lib.part(m, can * CFrame.new(x, 8, z), V(1.6, 15, 1.6), C.white, M.SmoothPlastic)
		end
		-- îlot et pompes
		Lib.part(m, can * CFrame.new(x, 0.6, 0), V(5, 0.8, 18), rgb(220, 218, 210), M.Concrete)
		for _, z in { -5, 5 } do
			Lib.part(m, can * CFrame.new(x, 3.4, z), V(3, 5, 2), red, M.SmoothPlastic, { Name = "Pump" })
			Lib.fine(m, can * CFrame.new(x, 4.6, z - 1.05), V(2.2, 1.4, 0.1), rgb(30, 34, 40), M.SmoothPlastic)
			Lib.fine(m, can * CFrame.new(x, 6.1, z), V(3.2, 0.6, 2.2), yel, M.SmoothPlastic)
		end
	end
	-- boutique
	local shop = cf * CFrame.new(0, 0, 30)
	Build.shopBlock(m, shop, 40, 18, 0, rgb(250, 250, 246), red, { "MINI MARCHÉ", red, C.white }, "StationShop")
	-- totem des prix
	local t = cf * CFrame.new(-40, 0, -30)
	Lib.part(m, t * CFrame.new(0, 10, 0), V(6, 20, 1.6), red, M.SmoothPlastic)
	local pz = Lib.fine(m, t * CFrame.new(0, 14, -0.85), V(5, 8, 0.1), C.white, M.SmoothPlastic)
	Lib.label(pz, Enum.NormalId.Front, "ESSENCE\nÀ L'ENVERS\n1,99", red, nil, Enum.Font.FredokaOne)
	local cs = Lib.fine(m, can * CFrame.new(0, 19.2, -16.2), V(30, 4, 0.2), red, M.SmoothPlastic)
	Lib.label(cs, Enum.NormalId.Front, "STATION CIEL", C.white, nil, Enum.Font.FredokaOne, true)
	return m
end

local function ferrisWheel(parent, pos, r)
	local m = Lib.model(Lib.path("Landmarks"), "GrandeRoue")
	local hub = pos + V(0, r + 8, 0)
	local white = C.white
	for _, z in { -4, 4 } do
		-- pieds en A
		Lib.beam(m, pos + V(-r * 0.55, 0, z), hub + V(0, 0, z), 1.6, 1.6, white, M.Metal)
		Lib.beam(m, pos + V(r * 0.55, 0, z), hub + V(0, 0, z), 1.6, 1.6, white, M.Metal)
		-- jante
		local n = 24
		for k = 0, n - 1 do
			local a0, a1 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
			local p0 = hub + V(math.cos(a0) * r, math.sin(a0) * r, z * 0.6)
			local p1 = hub + V(math.cos(a1) * r, math.sin(a1) * r, z * 0.6)
			Lib.beam(m, p0, p1, 0.8, 0.8, rgb(250, 90, 140), M.SmoothPlastic, { CanCollide = false })
			if k % 2 == 0 then
				Lib.beam(m, hub + V(0, 0, z * 0.6), p0, 0.4, 0.4, white, M.Metal, { CanCollide = false })
			end
		end
	end
	Lib.cyl(m, CFrame.new(hub) * CFrame.Angles(math.pi / 2, 0, 0), 9, 3, rgb(255, 200, 40), M.SmoothPlastic)
	local cols = { rgb(240, 70, 70), rgb(60, 140, 240), rgb(255, 200, 40), rgb(80, 200, 120), rgb(170, 90, 230), rgb(255, 140, 40) }
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local p = hub + V(math.cos(a) * r, math.sin(a) * r - 3, 0)
		Lib.part(m, CFrame.new(p), V(4, 4, 5), cols[k % #cols + 1], M.SmoothPlastic, { CanCollide = false, Name = "Cabin" })
		Lib.fine(m, CFrame.new(p + V(0, 0.4, 0)), V(4.2, 1.8, 5.2), rgb(170, 215, 238), M.Glass)
		Lib.fine(m, CFrame.new(p + V(0, 2.4, 0)), V(4.6, 0.6, 5.6), cols[k % #cols + 1], M.SmoothPlastic)
	end
	Lib.part(m, CFrame.new(pos + V(0, 1, 0)), V(r * 1.4, 2, 16), rgb(230, 226, 216), M.Concrete)
	return m
end

return function()
	local root = Lib.path("CommercialDistrict")
	local A = { edge(300, "sec", 1), edge(600, "sec", -1) }
	local B = { edge(600, "sec", 1), edge(900, "ring", -1) }
	local Q = { edge(0, "main", 1), edge(300, "sec", -1) }
	local Z0 = { edge(0, "main", 1), edge(300, "sec", -1) }
	local Z1 = { edge(300, "sec", 1), edge(520, "sec", -1) }
	local Z2 = { edge(520, "sec", 1), edge(720, "ring", -1) }
	local ZQ = { edge(300, "sec", 1), edge(720, "ring", -1) }
	local veh = Lib.path("DecorativeVehicles")

	---------------------------------------------------------------- Supermarché
	do
		local m = Lib.model(root, "SuperMarche")
		local cx = (A[1] + A[2]) / 2
		bigStore(m, Lib.facing(V(cx, 0.3, Z0[2] - 42), V(0, 0, -1)), 170, 70, 24, rgb(250, 248, 240), rgb(220, 40, 40), "🛒 SUPER MARCHÉ", { carts = true, model = "Supermarket" })
		Lib.parking(m, CFrame.new(cx, 0, Z0[1] + 62), A[2] - A[1] - 16, 120, 0.55)
		Lib.driveway(m, Lib.facing(V(cx - 50, 0, 24), V(0, 0, 1)), 26, 12)
		Lib.driveway(m, Lib.facing(V(cx + 50, 0, 24), V(0, 0, 1)), 26, 12)
		-- zone de livraison à l'arrière (côté rue du Commerce)
		Lib.part(m, CFrame.new(A[1] + 14, 0.32, Z0[2] - 42), V(22, 0.1, 40), rgb(250, 200, 40), M.SmoothPlastic, { Name = "DeliveryBay", CanCollide = false })
		for k = 0, 3 do
			Lib.pallet(m, CFrame.new(A[1] + 10, 0.4, Z0[2] - 56 + k * 8), rng:NextInteger(2, 8))
		end
	end

	---------------------------------------------------------------- Station-service + burger
	do
		local m = Lib.model(root, "StationEtRestos")
		gasStation(m, Lib.facing(V(B[1] + 70, 0.3, Z0[1] + 50), V(0, 0, -1)))
		Lib.driveway(m, Lib.facing(V(B[1] + 40, 0, 24), V(0, 0, 1)), 26, 12)
		Lib.driveway(m, Lib.facing(V(B[1] + 100, 0, 24), V(0, 0, 1)), 26, 12)
		restaurant(m, Lib.facing(V(B[2] - 40, 0.3, Z0[1] + 60), V(-1, 0, 0)), 34, 28, rgb(255, 240, 210), rgb(240, 150, 30), rgb(230, 60, 40), "BURGER RETOUR")
		restaurant(m, Lib.facing(V(B[1] + 60, 0.3, Z0[2] - 40), V(0, 0, 1)), 32, 26, rgb(250, 250, 240), rgb(40, 150, 70), rgb(220, 50, 40), "PIZZA SENS UNIQUE")
		Lib.parking(m, CFrame.new(B[2] - 70, 0, Z0[2] - 50), 100, 64, 0.5)
	end

	---------------------------------------------------------------- Centre commercial + grande roue
	do
		local m = Lib.model(root, "CentreCommercial")
		local cx = (Q[1] + Q[2]) / 2
		local mall = bigStore(m, Lib.facing(V(cx, 0.3, ZQ[1] + 45), V(0, 0, 1)), 200, 80, 30, rgb(236, 230, 250), rgb(120, 70, 190), "CENTRE COMMERCIAL L'ENVERS", { model = "Mall" })
		-- verrière
		Lib.part(m, CFrame.new(cx, 32, ZQ[1] + 45), V(60, 6, 50), rgb(170, 215, 238), M.Glass, { Transparency = 0.3 })
		Lib.parking(m, CFrame.new(cx, 0, ZQ[1] + 160), Q[2] - Q[1] - 16, 120, 0.5)
		ferrisWheel(m, V(cx, 0.3, ZQ[2] - 70), 34)
		-- petits stands de fête foraine
		for k = 0, 3 do
			local x = cx - 90 + k * 26
			if math.abs(x - cx) > 30 then
				local sc = Lib.facing(V(x, 0.3, ZQ[2] - 40), V(0, 0, -1))
				Build.shopBlock(m, sc, 16, 12, 0, ({ rgb(255, 120, 160), rgb(120, 200, 255), rgb(255, 210, 80), rgb(140, 220, 140) })[k + 1], C.white, { ({ "BARBE À PAPA", "GLACES", "CHURROS", "JEUX" })[k + 1], rgb(200, 60, 120), C.white }, "Stand")
			end
		end
		Lib.driveway(m, Lib.facing(V(24, 0, ZQ[1] + 160), V(1, 0, 0)), 26, 12)
		Lib.driveway(m, Lib.facing(V(cx, 0, 300 + 16), V(0, 0, 1)), 26, 10)
	end

	---------------------------------------------------------------- Galerie marchande (rue des magasins)
	do
		local m = Lib.model(root, "GalerieMarchande")
		local names = { { "TACOS TOUT DROIT", rgb(240, 120, 30) }, { "JOUETS ET KLAXONS", rgb(60, 130, 230) }, { "LAVERIE LA ROUE LIBRE", rgb(40, 170, 170) }, { "VÉLOS SANS ROUES", rgb(220, 60, 60) }, { "CARTONS VIDES", rgb(180, 130, 70) }, { "TÉLÉPHONES PERDUS", rgb(130, 70, 200) } }
		local x0 = A[1] + 18
		local n = 0
		for k, nm in names do
			local w = 34
			local x = x0 + (k - 1) * (w + 2) + w / 2
			if x + w / 2 < A[2] - 8 then
				Build.shopBlock(m, Lib.facing(V(x, 0.3, Z1[2] - 20), V(0, 0, -1)), w, 30, k % 2 == 0 and 1 or 2, ({ rgb(250, 236, 210), rgb(210, 236, 250), rgb(236, 250, 210), rgb(250, 220, 230) })[k % 4 + 1], C.white, { nm[1], nm[2], C.white }, "Shop")
				n += 1
			end
		end
		Lib.parking(m, CFrame.new((A[1] + A[2]) / 2 - 20, 0, Z1[1] + 50), A[2] - A[1] - 60, 64, 0.6)
		Lib.driveway(m, Lib.facing(V((A[1] + A[2]) / 2 - 20, 0, 300 + 16), V(0, 0, 1)), 26, 10)
	end

	---------------------------------------------------------------- Cinéma et restaurants
	do
		local m = Lib.model(root, "CinemaEtRestos")
		local cx = (B[1] + B[2]) / 2
		local cin = bigStore(m, Lib.facing(V(cx + 30, 0.3, Z1[2] - 40), V(0, 0, -1)), 110, 60, 28, rgb(60, 40, 90), rgb(230, 50, 120), "CINÉMA LE RÉTROVISEUR", { model = "Cinema" })
		-- marquise lumineuse
		local mq = Lib.part(m, CFrame.new(cx + 30, 15, Z1[2] - 76), V(50, 4, 3), rgb(255, 210, 60), M.Neon, { CanCollide = false })
		restaurant(m, Lib.facing(V(B[1] + 40, 0.3, Z1[1] + 34), V(0, 0, -1)), 28, 24, rgb(250, 250, 250), rgb(200, 40, 40), rgb(30, 30, 30), "SUSHI DÉRAPAGE")
		restaurant(m, Lib.facing(V(B[2] - 30, 0.3, Z1[1] + 34), V(0, 0, -1)), 28, 24, rgb(255, 236, 200), rgb(70, 130, 200), rgb(240, 120, 30), "CRÊPES À CONTRESENS")
		Lib.driveway(m, Lib.facing(V(cx, 0, 300 + 16), V(0, 0, 1)), 26, 10)
	end

	---------------------------------------------------------------- Bricolage + zone de livraison
	do
		local m = Lib.model(root, "BricoDetour")
		local cx = (A[1] + A[2]) / 2
		bigStore(m, Lib.facing(V(cx + 20, 0.3, Z2[2] - 40), V(0, 0, -1)), 150, 60, 22, rgb(250, 250, 246), rgb(250, 140, 20), "BRICO LE DÉTOUR", { model = "Hardware" })
		Lib.parking(m, CFrame.new(cx, 0, Z2[1] + 30), A[2] - A[1] - 16, 50, 0.5, { "Car", "Van" })
		Lib.driveway(m, Lib.facing(V(cx, 0, 520 + 16), V(0, 0, 1)), 26, 10)
	end

	---------------------------------------------------------------- Concession automobile
	do
		local m = Lib.model(root, "ConcessionAuto")
		local cx = (B[1] + B[2]) / 2
		local show = Lib.facing(V(cx + 20, 0.3, Z2[2] - 40), V(0, 0, -1))
		Lib.part(m, show * CFrame.new(0, 9, 0), V(110, 18, 50), rgb(240, 244, 248), M.SmoothPlastic)
		local f = Build.face(show, 110, 50, 1)
		Lib.part(m, f * CFrame.new(0, 7.5, -0.3), V(100, 14, 0.4), rgb(170, 215, 238), M.Glass, { Transparency = 0.25 })
		local sg = Lib.fine(m, f * CFrame.new(0, 16.4, -0.6), V(60, 3, 0.3), rgb(30, 90, 200), M.SmoothPlastic)
		Lib.label(sg, Enum.NormalId.Front, "AUTOS MARCHE ARRIÈRE", C.white, nil, Enum.Font.FredokaOne, true)
		Lib.part(m, CFrame.new(cx, 0.35, Z2[1] + 34), V(B[2] - B[1] - 20, 0.4, 60), rgb(220, 220, 214), M.Concrete)
		for k = 0, 6 do
			Lib.vehicle("Car", veh, CFrame.new(B[1] + 30 + k * 30, 0.55, Z2[1] + 34) * CFrame.Angles(0, math.rad(30), 0))
		end
		for k = 0, 9 do
			local p = V(B[1] + 20 + k * 24, 0.5, Z2[1] + 6)
			local fl = Lib.model(m, "Flag")
			Lib.part(fl, CFrame.new(p + V(0, 7, 0)), V(0.3, 14, 0.3), C.white, M.Metal)
			Lib.fine(fl, CFrame.new(p + V(0, 11, 1.5)), V(0.1, 5, 3), ({ rgb(230, 50, 50), rgb(40, 110, 220), rgb(255, 200, 40) })[k % 3 + 1], M.Fabric)
		end
		Lib.driveway(m, Lib.facing(V(cx, 0, 520 + 16), V(0, 0, 1)), 26, 10)
	end

	Lib.postSign(root, Lib.facing(V(330, 0.8, 30), V(0, 0, -1)), "ZONE COMMERCIALE", rgb(220, 40, 40), C.white, 18, 3.4, 9)
	return "zone commerciale construite"
end
