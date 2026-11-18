--!nolint
-- 04 : centre-ville. Îlots entre les rues (x -300..300, z -720..0) : tours de bureaux avec commerces
-- au rez-de-chaussée, tour emblématique, place de la Ville, parc, parking à étages, panneaux publicitaires.
local Lib = require(script.Parent.Lib)
local Build = require(script.Parent.Build)
local Plan = require(script.Parent.Plan)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C

local rng = Random.new(404)
local XS = { { -300, "sec" }, { -150, "sec" }, { 0, "main" }, { 150, "sec" }, { 300, "sec" } }
local ZS = { { -720, "ring" }, { -540, "sec" }, { -360, "sec" }, { -180, "sec" }, { 0, "main" } }
local function edge(v, kind, s)
	return v + s * (Plan.W[kind] / 2 + Plan.SW[kind])
end

local STYLES = {
	{ body = rgb(236, 214, 176), kind = "grid", trim = rgb(250, 246, 236) },
	{ body = rgb(90, 160, 220), glass = rgb(120, 196, 240), kind = "glass", trim = rgb(235, 245, 255) },
	{ body = rgb(196, 86, 66), kind = "brick", trim = rgb(246, 236, 220) },
	{ body = rgb(120, 200, 190), kind = "bands", trim = rgb(250, 250, 246) },
	{ body = rgb(250, 230, 160), kind = "bands", trim = rgb(255, 255, 250) },
	{ body = rgb(70, 110, 170), glass = rgb(100, 170, 230), kind = "glass", trim = rgb(220, 235, 250) },
	{ body = rgb(230, 160, 120), kind = "grid", trim = rgb(255, 248, 236) },
	{ body = rgb(170, 150, 220), kind = "bands", trim = rgb(250, 248, 255) },
}
local SHOPS = {
	{ "CAFÉ CONTRESENS", rgb(200, 60, 50) }, { "LIBRAIRIE", rgb(40, 110, 190) }, { "PHARMACIE", rgb(40, 170, 90) }, { "BANQUE", rgb(30, 70, 140) },
	{ "BOULANGERIE", rgb(200, 120, 40) }, { "FLEURISTE", rgb(220, 70, 140) }, { "OPTICIEN", rgb(90, 90, 180) }, { "GLACIER", rgb(80, 190, 220) },
	{ "SUSHI DÉRAPAGE", rgb(230, 70, 70) }, { "MODE", rgb(60, 60, 70) }, { "JOUETS", rgb(250, 160, 30) }, { "TÉLÉPHONES", rgb(100, 60, 160) },
}
local function shops(n)
	local t = {}
	for k = 1, n do
		t[k] = SHOPS[rng:NextInteger(1, #SHOPS)]
	end
	return t
end

-- étages selon la distance au cœur (0, -360)
local function floorsAt(p)
	local d = (p - V(0, 0, -360)).Magnitude
	return math.clamp(math.floor(26 - d / 16 + rng:NextInteger(-3, 3)), 6, 26)
end

local function billboard(parent, cf, text, bg, fg)
	local m = Lib.model(parent, "Billboard")
	for _, x in { -6, 6 } do
		Lib.part(m, cf * CFrame.new(x, 4, 0.5), V(0.8, 8, 0.8), C.metal, M.Metal)
	end
	local b = Lib.part(m, cf * CFrame.new(0, 11, 0), V(26, 8, 1), C.white, M.SmoothPlastic, { CanCollide = false })
	local s = Lib.fine(m, cf * CFrame.new(0, 11, -0.55), V(25, 7, 0.1), bg, M.SmoothPlastic)
	Lib.label(s, Enum.NormalId.Front, text, fg, nil, Enum.Font.FredokaOne, true)
	return m
end

local ADS = {
	{ "WRONG WAY DELIVERY\nOn livre (presque) partout !", rgb(30, 32, 40), rgb(255, 255, 255) },
	{ "BURGER RETOUR\nLe burger qui revient", rgb(240, 150, 30), rgb(255, 255, 255) },
	{ "CINÉMA LE RÉTROVISEUR", rgb(140, 40, 160), rgb(255, 230, 120) },
	{ "SUPER MARCHÉ\nOuvert 7j/7", rgb(220, 40, 40), rgb(255, 255, 255) },
	{ "VÉLOS SANS ROUES\n-50 %", rgb(40, 140, 200), rgb(255, 255, 255) },
}

return function()
	local root = Lib.path("Downtown")
	local nb = 0
	for i = 1, #XS - 1 do
		for j = 1, #ZS - 1 do
			local x1, x2 = edge(XS[i][1], XS[i][2], 1), edge(XS[i + 1][1], XS[i + 1][2], -1)
			local z1, z2 = edge(ZS[j][1], ZS[j][2], 1), edge(ZS[j + 1][1], ZS[j + 1][2], -1)
			local cx, cz = (x1 + x2) / 2, (z1 + z2) / 2
			local bw, bd = x2 - x1, z2 - z1
			local block = Lib.model(root, ("Block_%d_%d"):format(i, j))
			-- trottoir intérieur de l'îlot (dalle)
			Lib.part(block, CFrame.new(cx, 0.35, cz), V(bw, 0.7, bd), rgb(214, 210, 202), M.Pavement, { Name = "BlockPaving" })
			local special = (i == 2 and j == 3) and "plaza" or ((i == 3 and j == 3) and "landmark" or ((i == 4 and j == 4) and "parking" or ((i == 1 and j == 1) and "park" or nil)))
			if special == "plaza" then
				-- Place de la Ville : dallage, fontaine, arbres, bancs, kiosque
				local pm = Lib.model(Lib.path("Landmarks"), "PlaceDeLaVille")
				Lib.part(pm, CFrame.new(cx, 0.75, cz), V(bw - 8, 0.2, bd - 8), rgb(232, 222, 200), M.Pavement)
				Lib.cyl(pm, CFrame.new(cx, 1.6, cz), 1.8, 26, rgb(240, 236, 226), M.SmoothPlastic)
				Lib.cylDeco(pm, CFrame.new(cx, 2.4, cz), 0.3, 23, rgb(70, 180, 230), M.Glass, { Transparency = 0.25 })
				Lib.cyl(pm, CFrame.new(cx, 5, cz), 6, 3, rgb(240, 236, 226), M.SmoothPlastic)
				local st = Lib.part(pm, CFrame.new(cx, 10, cz), V(3, 4, 3), rgb(214, 160, 96), M.Cardboard, { CanCollide = false })
				for k = 0, 7 do
					local a = k / 8 * math.pi * 2
					local p = V(cx + math.cos(a) * 32, 0.85, cz + math.sin(a) * 38)
					Lib.tree(pm, p, "round", 16)
					local b = V(cx + math.cos(a + 0.4) * 22, 0.85, cz + math.sin(a + 0.4) * 26)
					Lib.bench(pm, CFrame.lookAt(b, V(cx, 0.85, cz)))
				end
				for _, s in { -1, 1 } do
					Lib.flowers(pm, CFrame.new(cx + s * 36, 0.85, cz), 4, 30)
				end
				-- kiosque à musique
				local k0 = CFrame.new(cx, 0.85, cz - bd / 2 + 16)
				Lib.cyl(pm, k0 * CFrame.new(0, 0.6, 0), 1.2, 14, rgb(240, 236, 226), M.SmoothPlastic)
				for k = 0, 5 do
					local a = k / 6 * math.pi * 2
					Lib.part(pm, k0 * CFrame.new(math.cos(a) * 6, 4.5, math.sin(a) * 6), V(0.6, 7, 0.6), C.white, M.SmoothPlastic)
				end
				Lib.part(pm, k0 * CFrame.new(0, 8.6, 0), V(15, 1.2, 15), rgb(60, 140, 120), M.SmoothPlastic)
				Lib.part(pm, k0 * CFrame.new(0, 10, 0) * CFrame.Angles(0, math.rad(45), 0), V(9, 2, 9), rgb(60, 140, 120), M.SmoothPlastic)
			elseif special == "park" then
				local pm = Lib.model(Lib.path("Landmarks"), "SquareDuNord")
				Lib.part(pm, CFrame.new(cx, 0.75, cz), V(bw - 6, 0.3, bd - 6), C.grass, M.Grass)
				Lib.part(pm, CFrame.new(cx, 0.92, cz), V(8, 0.1, bd - 6), rgb(226, 206, 160), M.Sand)
				Lib.part(pm, CFrame.new(cx, 0.92, cz), V(bw - 6, 0.1, 8), rgb(226, 206, 160), M.Sand)
				for k = 1, 14 do
					local p = V(cx + rng:NextNumber(-bw / 2 + 8, bw / 2 - 8), 0.9, cz + rng:NextNumber(-bd / 2 + 8, bd / 2 - 8))
					if math.abs(p.X - cx) > 8 and math.abs(p.Z - cz) > 8 then
						Lib.tree(pm, p, rng:NextNumber() < 0.7 and "round" or "pine")
					end
				end
				for _, s in { -1, 1 } do
					Lib.bench(pm, Lib.facing(V(cx + 7, 0.9, cz + s * 20), V(-1, 0, 0)))
					Lib.bench(pm, Lib.facing(V(cx + s * 20, 0.9, cz - 7), V(0, 0, 1)))
				end
			elseif special == "parking" then
				-- parking à étages
				local pk = Lib.model(block, "ParkingEtage")
				local h = 3
				for fl = 0, h do
					Lib.part(pk, CFrame.new(cx, 0.9 + fl * 9, cz), V(bw - 10, 1, bd - 30), rgb(200, 198, 192), M.Concrete, { Name = "Deck" })
					if fl > 0 then
						for _, s in { -1, 1 } do
							Lib.part(pk, CFrame.new(cx, 0.9 + fl * 9 + 1.8, cz + s * (bd - 30) / 2), V(bw - 10, 2.6, 0.8), rgb(250, 200, 50), M.SmoothPlastic)
							Lib.part(pk, CFrame.new(cx + s * (bw - 10) / 2, 0.9 + fl * 9 + 1.8, cz), V(0.8, 2.6, bd - 30), rgb(250, 200, 50), M.SmoothPlastic)
						end
					end
				end
				for _, px in { -1, 1 } do
					for _, pz in { -1, 0, 1 } do
						Lib.part(pk, CFrame.new(cx + px * (bw / 2 - 8), 14, cz + pz * (bd / 2 - 18)), V(2, 27, 2), rgb(190, 188, 182), M.Concrete)
					end
				end
				local ps = Lib.part(pk, CFrame.new(cx, 32, cz - bd / 2 + 15), V(10, 10, 1), rgb(30, 90, 200), M.SmoothPlastic, { CanCollide = false })
				Lib.label(ps, Enum.NormalId.Front, "P", C.white, nil, Enum.Font.GothamBlack, true)
				-- rampe d'accès
				Lib.wedge(pk, CFrame.new(cx, 0.9 + 4.5, cz + bd / 2 - 14) * CFrame.Angles(0, math.pi, 0), V(16, 9, 28), rgb(200, 198, 192), M.Concrete)
				Lib.parking(pk, CFrame.new(cx, 0.75, cz), bw - 12, bd - 32, 0.5)
				Lib.driveway(block, Lib.facing(V(cx, 0, z2 + 12), V(0, 0, -1)), 18, 12)
			else
				-- 2 x 2 parcelles ; la tour emblématique occupe tout l'îlot "landmark"
				if special == "landmark" then
					Build.tower(block, Lib.facing(V(cx, 0.7, cz), V(0, 0, 1)), 56, 56, 34, { body = rgb(40, 60, 100), glass = rgb(110, 190, 245), kind = "glass", crown = "spire", trim = rgb(230, 240, 255) }, { { "WRONG WAY BANK", rgb(30, 32, 40) }, { "CAFÉ", rgb(200, 60, 50) }, { "HALL", rgb(40, 110, 190) }, corner = true }, "TourDesLivreurs")
					for _, s in { -1, 1 } do
						for _, t in { -1, 1 } do
							Lib.tree(block, V(cx + s * (bw / 2 - 8), 0.7, cz + t * (bd / 2 - 8)), "round", 16)
						end
					end
				else
					for a = 0, 1 do
						for b = 0, 1 do
							local lw, ld = bw / 2, bd / 2
							local lx, lz = x1 + lw * (a + 0.5), z1 + ld * (b + 0.5)
							local fw, fd = lw - 8 - rng:NextNumber(0, 6), ld - 8 - rng:NextNumber(0, 8)
							-- façade vers la rue la plus proche en z (nord ou sud), commerces aussi sur le côté
							local dir = b == 0 and V(0, 0, -1) or V(0, 0, 1)
							local cf = Lib.facing(V(lx, 0.7, lz), dir)
							local px = (a == 0) and -(lw - fw) / 2 + 2 or (lw - fw) / 2 - 2
							cf = Lib.facing(V(lx + px, 0.7, lz + (b == 0 and -1 or 1) * ((ld - fd) / 2 - 2)), dir)
							local st = STYLES[rng:NextInteger(1, #STYLES)]
							local floors = floorsAt(V(lx, 0, lz))
							local style = { body = st.body, glass = st.glass, kind = st.kind, trim = st.trim, setback = floors > 14 and rng:NextNumber() < 0.6, crown = ({ "flat", "flat", "stepped", "pyramid", "helipad" })[rng:NextInteger(1, 5)], roof = rgb(60, 140, 120) }
							local s = shops(4)
							s.corner = true
							local t = Build.tower(block, cf, fw, fd, floors, style, s, "Tower")
							nb += 1
							if floors <= 12 and rng:NextNumber() < 0.5 then
								local top = t:GetAttribute("Height")
								local ad = ADS[rng:NextInteger(1, #ADS)]
								billboard(block, cf * CFrame.new(0, top, 0), ad[1], ad[2], ad[3])
							end
							task.wait()
						end
					end
				end
			end
			-- arbres d'alignement sur le pourtour de l'îlot (dans des fosses)
			for _, s in { -1, 1 } do
				for k = 1, math.floor(bw / 30) do
					local x = x1 + bw / (math.floor(bw / 30) + 1) * k
					local z = s < 0 and z1 + 3 or z2 - 3
					if special ~= "plaza" and special ~= "park" then
						Lib.planter(block, CFrame.new(x, 0.7, z))
					end
				end
			end
			task.wait()
		end
	end
	-- panneaux publicitaires au bord du périphérique
	for k, x in { -220, 70, 230 } do
		local ad = ADS[(k % #ADS) + 1]
		billboard(root, Lib.facing(V(x, 0.8, -770), V(0, 0, 1)), ad[1], ad[2], ad[3])
	end
	return ("centre-ville : %d tours"):format(nb)
end
