--!nolint
-- 06 : zone industrielle (x 300..900, z -720..0). Usine à cheminées, parc à conteneurs avec portique,
-- entrepôts et quais, parking poids lourds, hangars, palettes, clôtures, camions garés.
local Lib = require(script.Parent.Lib)
local Build = require(script.Parent.Build)
local Plan = require(script.Parent.Plan)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C

local rng = Random.new(606)
local function edge(v, kind, s)
	return v + s * (Plan.W[kind] / 2 + Plan.SW[kind])
end

local function yard(parent, x1, z1, x2, z2, gates)
	-- dalle béton + clôture avec ouvertures (gates = liste de { side, center, width })
	Lib.part(parent, CFrame.new((x1 + x2) / 2, 0.1, (z1 + z2) / 2), V(x2 - x1, 0.6, z2 - z1), rgb(170, 168, 160), M.Concrete, { Name = "Yard" })
	local sides = {
		N = { V(x1, 0.4, z1), V(x2, 0.4, z1) },
		S = { V(x1, 0.4, z2), V(x2, 0.4, z2) },
		W = { V(x1, 0.4, z1), V(x1, 0.4, z2) },
		E = { V(x2, 0.4, z1), V(x2, 0.4, z2) },
	}
	for name, s in sides do
		local a, b = s[1], s[2]
		local len = (b - a).Magnitude
		local dir = (b - a).Unit
		local cuts = {}
		for _, g in gates do
			if g[1] == name then
				table.insert(cuts, { g[2] - g[3] / 2, g[2] + g[3] / 2 })
			end
		end
		table.sort(cuts, function(p, q)
			return p[1] < q[1]
		end)
		local cur = 0
		for _, c in cuts do
			if c[1] > cur + 2 then
				Lib.fence(parent, a + dir * cur, a + dir * c[1], "chain", 8)
			end
			-- poteaux de portail rayés
			for _, t in { c[1], c[2] } do
				local p = a + dir * t
				Lib.part(parent, CFrame.new(p + V(0, 4.5, 0)), V(1.2, 9, 1.2), C.yellow, M.SmoothPlastic)
				Lib.fine(parent, CFrame.new(p + V(0, 3, 0)), V(1.3, 1.2, 1.3), C.dark, M.SmoothPlastic)
				Lib.fine(parent, CFrame.new(p + V(0, 6, 0)), V(1.3, 1.2, 1.3), C.dark, M.SmoothPlastic)
			end
			cur = c[2]
		end
		if len > cur + 2 then
			Lib.fence(parent, a + dir * cur, a + dir * len, "chain", 8)
		end
	end
end

local function chimney(parent, pos, h, d)
	local m = Lib.model(parent, "Chimney")
	local n = math.floor(h / 8)
	for k = 0, n - 1 do
		Lib.cyl(m, CFrame.new(pos + V(0, k * 8 + 4, 0)), 8, d - k * 0.25, k % 2 == 0 and rgb(220, 50, 50) or rgb(245, 245, 245), M.SmoothPlastic)
	end
	Lib.cylDeco(m, CFrame.new(pos + V(0, n * 8 + 0.5, 0)), 1, d - n * 0.25 + 1, C.dark, M.Metal)
	local top = Lib.part(m, CFrame.new(pos + V(0, n * 8 + 1.2, 0)), V(1, 1, 1), C.dark, M.SmoothPlastic, { Transparency = 1, CanCollide = false })
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(rgb(235, 235, 240))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 12) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(5, 7)
	pe.Rate = 4
	pe.Speed = NumberRange.new(4, 6)
	pe.Acceleration = V(2, 1, 0)
	pe.Parent = top
	return m
end

local function crane(parent, cf, span, h)
	-- portique à conteneurs jaune ; cf au sol au centre, la poutre suit X local
	local m = Lib.model(parent, "GantryCrane")
	local y = C.yellow
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Lib.part(m, cf * CFrame.new(sx * span / 2, h / 2, sz * 7), V(2, h, 2), y, M.Metal)
		end
		Lib.part(m, cf * CFrame.new(sx * span / 2, 1, 0), V(3, 2, 18), rgb(60, 60, 66), M.Metal)
		Lib.fine(m, cf * CFrame.new(sx * span / 2, h * 0.5, 0), V(1, 1, 14), y, M.Metal)
	end
	for _, sz in { -1, 1 } do
		Lib.part(m, cf * CFrame.new(0, h + 1.5, sz * 7), V(span + 18, 3, 2.4), y, M.Metal)
	end
	-- treillis
	for k = -3, 3 do
		Lib.fine(m, cf * CFrame.new(k * span / 7, h + 1.5, 0), V(0.8, 0.8, 14), y, M.Metal)
	end
	Lib.part(m, cf * CFrame.new(span / 5, h - 1, 0), V(6, 4, 10), rgb(240, 240, 236), M.SmoothPlastic)
	Lib.fine(m, cf * CFrame.new(span / 5, h - 7, 0), V(0.3, 10, 0.3), C.dark, M.Metal)
	Lib.part(m, cf * CFrame.new(span / 5, h - 12.5, 0), V(8, 1, 20), C.dark, M.Metal)
	return m
end

local function towerCrane(parent, pos, h)
	local m = Lib.model(parent, "TowerCrane")
	local y = rgb(255, 196, 30)
	Lib.part(m, CFrame.new(pos + V(0, 1, 0)), V(8, 2, 8), rgb(160, 160, 156), M.Concrete)
	Lib.part(m, CFrame.new(pos + V(0, h / 2, 0)), V(3, h, 3), y, M.Metal)
	for k = 0, math.floor(h / 6) do
		Lib.fine(m, CFrame.new(pos + V(0, k * 6, 0)) * CFrame.Angles(0, 0, math.rad(45)), V(0.4, 4.2, 3.2), y, M.Metal)
	end
	Lib.part(m, CFrame.new(pos + V(10, h + 1.5, 0)), V(46, 2.4, 2.4), y, M.Metal)
	Lib.part(m, CFrame.new(pos + V(-10, h + 1, 0)), V(6, 4, 4), rgb(150, 150, 146), M.Concrete)
	Lib.part(m, CFrame.new(pos + V(1, h - 1, 2.5)), V(3, 3, 3), rgb(240, 240, 236), M.SmoothPlastic)
	Lib.fine(m, CFrame.new(pos + V(24, h - 6, 0)), V(0.3, 12, 0.3), C.dark, M.Metal)
	Lib.pallet(m, CFrame.new(pos + V(24, h - 13, 0)), 4)
	return m
end

return function()
	local root = Lib.path("IndustrialZone")
	local X1, XM, X2 = edge(300, "sec", 1), edge(600, "ind", -1), edge(600, "ind", 1)
	local X3 = edge(900, "ring", -1)
	local Z1, ZM, Z2 = edge(-720, "ring", 1), edge(-360, "ind", -1), edge(-360, "ind", 1)
	local Z3 = edge(0, "main", -1)
	local CONT = { rgb(220, 60, 50), rgb(40, 110, 200), rgb(250, 170, 30), rgb(40, 160, 90), rgb(230, 100, 30), rgb(120, 70, 170), rgb(30, 160, 170) }

	---------------------------------------------------------------- NO : usine
	do
		local m = Lib.model(root, "UsineDesCartons")
		yard(m, X1, Z1, XM, ZM, { { "E", 120, 30 }, { "S", 60, 30 } })
		local cx, cz = (X1 + XM) / 2, (Z1 + ZM) / 2
		local fcf = Lib.facing(V(cx - 10, 0.4, cz - 30), V(1, 0, 0))
		local f = Build.warehouse(m, fcf, 120, 90, 30, rgb(236, 226, 206), rgb(120, 60, 50), rgb(40, 110, 200), "Factory", 4)
		-- bâtiment de bureaux accolé
		Build.shopBlock(m, Lib.facing(V(cx + 40, 0.4, cz + 70), V(1, 0, 0)), 30, 36, 2, rgb(200, 210, 220), C.white, { "USINE DES CARTONS", rgb(40, 110, 200), C.white }, "FactoryOffice")
		chimney(m, V(cx - 60, 0.4, cz - 66), 64, 7)
		chimney(m, V(cx - 40, 0.4, cz - 70), 48, 6)
		-- silos
		for k = 0, 2 do
			local p = V(cx - 70 + k * 15, 0.4, cz + 70)
			Lib.cyl(m, CFrame.new(p + V(0, 14, 0)), 28, 12, rgb(220, 224, 230), M.Metal)
			Lib.cylDeco(m, CFrame.new(p + V(0, 28.5, 0)), 1, 13, rgb(200, 60, 50), M.SmoothPlastic)
		end
		-- tuyauteries
		Lib.beam(m, V(cx - 70, 22, cz + 70), V(cx - 40, 22, cz + 10), 1.6, 1.6, rgb(200, 200, 196), M.Metal, { CanCollide = false })
		for k = 0, 8 do
			Lib.pallet(m, CFrame.new(cx + 60, 0.4, cz - 90 + k * 9) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), rng:NextInteger(0, 8))
		end
		for k = 0, 3 do
			Lib.vehicle("Truck", Lib.path("DecorativeVehicles"), CFrame.new(cx + 82, 0.4, cz - 70 + k * 30) * CFrame.Angles(0, math.pi / 2, 0))
		end
	end

	---------------------------------------------------------------- NE : parc à conteneurs
	do
		local m = Lib.model(root, "PortConteneurs")
		yard(m, X2, Z1, X3, ZM, { { "W", 140, 30 }, { "S", 120, 34 } })
		local cx, cz = (X2 + X3) / 2, (Z1 + ZM) / 2
		for r = 0, 5 do
			for c = 0, 7 do
				if not (r == 2 or r == 3) or c > 5 then
					local stack = rng:NextInteger(1, 3)
					for s = 0, stack - 1 do
						Lib.container(m, CFrame.new(cx - 96 + c * 24, 0.4 + s * 8.5, cz - 110 + r * 26 + (r >= 3 and 20 or 0)) * CFrame.Angles(0, (r % 2) * 0.02, 0), CONT[rng:NextInteger(1, #CONT)])
					end
				end
				if c % 3 == 0 then
					task.wait()
				end
			end
		end
		crane(m, CFrame.new(cx - 20, 0.4, cz - 4), 110, 46)
		crane(m, CFrame.new(cx + 60, 0.4, cz + 92) * CFrame.Angles(0, math.pi / 2, 0), 70, 40)
		for k = 0, 2 do
			Lib.vehicle("Truck", Lib.path("DecorativeVehicles"), CFrame.new(cx - 80 + k * 50, 0.4, cz - 4) * CFrame.Angles(0, math.pi / 2, 0))
		end
		-- poste de garde
		local g = CFrame.new(X2 + 10, 0.4, Z1 + 160)
		Lib.part(m, g * CFrame.new(0, 4.5, 0), V(8, 9, 8), rgb(240, 240, 236), M.SmoothPlastic)
		Lib.fine(m, g * CFrame.new(0, 5, -4.05), V(6, 3.5, 0.1), C.glass, M.Glass)
		Lib.part(m, g * CFrame.new(0, 9.4, 0), V(10, 0.8, 10), rgb(40, 110, 200), M.SmoothPlastic)
		local bar = Lib.part(m, g * CFrame.new(-1, 3.5, -14), V(0.5, 0.5, 18), C.white, M.SmoothPlastic, { CanCollide = false })
		for k = -3, 3, 2 do
			Lib.fine(m, bar.CFrame * CFrame.new(0, 0, k * 2.4), V(0.55, 0.55, 2), rgb(220, 40, 40), M.SmoothPlastic)
		end
	end

	---------------------------------------------------------------- SO : entrepôts logistiques
	do
		local m = Lib.model(root, "Logistique")
		local cx, cz = (X1 + XM) / 2, (Z2 + Z3) / 2
		Lib.part(m, CFrame.new(cx, 0.1, cz), V(XM - X1, 0.6, Z3 - Z2), rgb(170, 168, 160), M.Concrete, { Name = "Yard" })
		Build.warehouse(m, Lib.facing(V(cx, 0.4, Z2 + 50), V(0, 0, 1)), 200, 80, 26, rgb(120, 160, 200), rgb(80, 86, 96), rgb(250, 170, 30), "EntrepotGeant", 8)
		Build.warehouse(m, Lib.facing(V(cx - 50, 0.4, Z3 - 50), V(0, 0, -1)), 110, 70, 20, rgb(230, 200, 120), rgb(150, 70, 50), rgb(40, 140, 90), "PetitEntrepot", 4)
		local sg = Lib.sign(m, Lib.facing(V(cx, 22, Z2 + 90.7), V(0, 0, 1)), V(80, 8, 0.6), "LOGISTIQUE EXPRESS", rgb(250, 170, 30), C.white)
		-- remorques et camions devant les quais
		for k = 0, 5 do
			Lib.vehicle("Truck", Lib.path("DecorativeVehicles"), CFrame.new(cx - 85 + k * 33, 0.4, Z2 + 112) * CFrame.Angles(0, 0, 0))
		end
		for k = 0, 11 do
			Lib.pallet(m, CFrame.new(cx + 20 + (k % 6) * 9, 0.4, Z3 - 70 + math.floor(k / 6) * 10), rng:NextInteger(1, 8))
		end
		for k = 0, 5 do
			Lib.cone(m, CFrame.new(cx + 40 + k * 6, 0.4, Z3 - 20))
		end
		Lib.driveway(m, Lib.facing(V(cx - 20, 0, Z3 + 12), V(0, 0, -1)), 30, 12)
		Lib.driveway(m, Lib.facing(V(XM + 8, 0, cz), V(-1, 0, 0)), 30, 8)
	end

	---------------------------------------------------------------- SE : parking poids lourds et hangars
	do
		local m = Lib.model(root, "ParkingCamions")
		local cx, cz = (X2 + X3) / 2, (Z2 + Z3) / 2
		Lib.part(m, CFrame.new(cx, 0.1, cz), V(X3 - X2, 0.6, Z3 - Z2), rgb(150, 150, 146), M.Concrete, { Name = "Yard" })
		-- emplacements camions (lignes jaunes)
		for k = 0, 8 do
			local x = X2 + 20 + k * 24
			Lib.mark(m, CFrame.new(x, 0.42, Z3 - 40), V(0.5, 0.05, 50), C.yellow)
			if k < 8 and rng:NextNumber() < 0.7 then
				Lib.vehicle("Truck", Lib.path("DecorativeVehicles"), CFrame.new(x + 12, 0.4, Z3 - 40) * CFrame.Angles(0, math.pi, 0))
			end
		end
		-- deux hangars cintrés
		for k = 0, 1 do
			local hc = CFrame.new(X2 + 60 + k * 120, 0.4, Z2 + 70)
			local hm = Lib.model(m, "Hangar")
			Lib.cyl(hm, hc * CFrame.Angles(math.pi / 2, 0, 0), 70, 50, k == 0 and rgb(200, 210, 220) or rgb(230, 140, 60), M.CorrodedMetal, { Name = "Vault" })
			Lib.part(hm, hc * CFrame.new(0, 10, -35.2), V(32, 20, 0.6), rgb(90, 96, 106), M.Metal)
		end
		Lib.driveway(m, Lib.facing(V(cx, 0, Z3 + 12), V(0, 0, -1)), 36, 12)
		-- grue de chantier (extension en cours)
		towerCrane(m, V(X3 - 30, 0.4, Z2 + 30), 70)
	end

	-- panneau d'entrée de zone
	Lib.postSign(root, Lib.facing(V(330, 0.8, -30), V(0, 0, 1)), "ZONE INDUSTRIELLE", rgb(40, 110, 200), C.white, 18, 3.4, 9)
	return "zone industrielle construite"
end
