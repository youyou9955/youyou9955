--!nolint
-- 08 : quartier des collines. Route en spirale qui monte jusqu'au plateau (pente douce), murets côté
-- colline, glissières côté vide, maisons sur terrasses, belvédère avec longue-vue, grandes lettres
-- WRONG WAY face à la ville, escalier piéton, rochers.
local Lib = require(script.Parent.Lib)
local Build = require(script.Parent.Build)
local Plan = require(script.Parent.Plan)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C

local rng = Random.new(808)

local function groundY(x, z, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(V(x, 400, z), V(0, -800, 0), params)
	return hit and hit.Position.Y or 0, hit
end

local function rock(parent, pos, s)
	local m = Lib.model(parent, "Rock")
	local col = rgb(150, 144, 136):Lerp(rgb(120, 112, 104), rng:NextNumber())
	Lib.part(m, CFrame.new(pos + V(0, s * 0.3, 0)) * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 6), rng:NextNumber(0, 1)), V(s, s * 0.7, s * 0.9), col, M.Slate, { Name = "Rock" })
	Lib.part(m, CFrame.new(pos + V(s * 0.4, s * 0.15, s * 0.2)) * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 6), 0), V(s * 0.6, s * 0.5, s * 0.6), col, M.Slate, { Name = "Rock" })
	return m
end

return function()
	local root = Lib.path("HillsideDistrict")
	local roads = Lib.path("Roads", "Asphalt")
	local marks = Lib.path("Roads", "Markings")
	local furniture = Lib.path("StreetFurniture")
	local pts = Plan.spiral
	local w = Plan.spiralW
	local hill = Plan.hill
	local road = Lib.model(roads, "RouteDeLaColline")
	local wall = rgb(186, 170, 148)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b)
		Lib.part(road, cf * CFrame.new(0, Lib.ROAD - 0.8, 0), V(w, 1.6, len + 1.2), C.asphalt, M.Asphalt, { Name = "Road" })
		-- lignes : rives blanches, axe jaune pointillé
		Lib.mark(marks, cf * CFrame.new(w / 2 - 1.3, Lib.ROAD + 0.03, 0), V(0.4, 0.05, len + 1.2), C.white)
		Lib.mark(marks, cf * CFrame.new(-w / 2 + 1.3, Lib.ROAD + 0.03, 0), V(0.4, 0.05, len + 1.2), C.white)
		if i % 2 == 0 then
			Lib.mark(marks, cf * CFrame.new(0, Lib.ROAD + 0.03, 0), V(0.45, 0.05, len * 0.6), C.yellow)
		end
		-- côté intérieur (vers le centre de la colline) : muret ; côté extérieur : glissière
		local mid = (a + b) / 2
		local inward = (hill.c - mid) * V(1, 0, 1)
		local right = cf.RightVector
		local sIn = (right:Dot(inward) > 0) and 1 or -1
		Lib.part(road, cf * CFrame.new(sIn * (w / 2 + 0.9), Lib.ROAD + 1.2, 0), V(1.8, 3.2, len + 1.2), wall, M.Cobblestone, { Name = "RetainingWall" })
		Lib.fine(road, cf * CFrame.new(sIn * (w / 2 + 0.9), Lib.ROAD + 2.95, 0), V(2.2, 0.4, len + 1.2), rgb(220, 210, 196), M.SmoothPlastic)
		local sOut = -sIn
		Lib.part(road, cf * CFrame.new(sOut * (w / 2 + 1), Lib.ROAD + 2, 0), V(0.4, 0.9, len + 1.2), rgb(210, 214, 220), M.Metal, { Name = "Guardrail" })
		Lib.fine(road, cf * CFrame.new(sOut * (w / 2 + 1), Lib.ROAD + 2.15, 0), V(0.45, 0.3, len + 1.2), rgb(230, 60, 50), M.SmoothPlastic)
		if i % 2 == 1 then
			Lib.part(road, cf * CFrame.new(sOut * (w / 2 + 1.2), Lib.ROAD + 1.1, 0), V(0.5, 2.6, 0.5), rgb(160, 164, 170), M.Metal)
		end
		if i % 10 == 5 then
			local lp = (cf * CFrame.new(sIn * (w / 2 - 0.5), Lib.ROAD, 0)).Position
			Lib.lamp(furniture, CFrame.lookAt(lp, (cf * CFrame.new(0, Lib.ROAD, 0)).Position))
		end
		if i % 3 == 0 then
			task.wait()
		end
	end
	-- raccord avec la rue Haute (début de la spirale) et panneau
	Lib.postSign(Lib.path("Roads", "Signs"), Lib.facing(V(-330, 0.8, -378), V(1, 0, 0)), "COLLINES  ↑  BELVÉDÈRE", rgb(40, 130, 80), C.white, 16, 3, 8)
	-- rond de retournement au sommet
	local last = pts[#pts]
	Lib.cyl(road, CFrame.new(last + V(0, Lib.ROAD - 0.8, 0)), 1.6, 40, C.asphalt, M.Asphalt, { Name = "Turnaround" })

	---------------------------------------------------------------- Maisons sur terrasses
	local n = 0
	for idx, pad in Plan.hillPads do
		local cf = CFrame.lookAt(V(pad.p.X, pad.y, pad.p.Z), V(pad.p.X, pad.y, pad.p.Z) + pad.face)
		local o = {
			w = math.floor(rng:NextNumber(18, 22)), d = 16, floors = rng:NextNumber() < 0.6 and 2 or 1,
			wall = Build.WALLS[rng:NextInteger(1, #Build.WALLS)], roof = Build.ROOFS[rng:NextInteger(1, #Build.ROOFS)],
			door = Build.DOORS[rng:NextInteger(1, #Build.DOORS)], porch = rng:NextNumber() < 0.5, chimney = true,
			shutters = rng:NextNumber() < 0.5 and rgb(255, 255, 255) or nil, flowerBoxes = true,
		}
		local h = Build.house(root, cf * CFrame.new(0, 0, 4), o)
		h.Name = "HillHouse_" .. idx
		-- terrasse en dalle + allée vers la route
		Lib.part(h, cf * CFrame.new(0, -0.2, 2), V(30, 0.8, 30), rgb(205, 196, 180), M.Pavement, { Name = "Terrace" })
		if not pad.plateau then
			Lib.part(h, cf * CFrame.new(0, -0.1, -12), V(4, 0.6, 10), rgb(200, 190, 176), M.Pavement, { Name = "Path" })
			Lib.mailbox(h, cf * CFrame.new(3, 0, -14))
			-- murets de terrasse côté pente
			Lib.part(h, cf * CFrame.new(0, -1.5, 17), V(30, 4, 1.4), wall, M.Cobblestone, { Name = "TerraceWall" })
		end
		Lib.tree(h, (cf * CFrame.new(12, 0, 10)).Position, "pine")
		n += 1
		task.wait()
	end

	---------------------------------------------------------------- Belvédère au sommet
	local top = hill.c + V(0, hill.top, 0)
	local view = Lib.model(Lib.path("Landmarks"), "Belvedere")
	local vcf = CFrame.lookAt(top + V(46, 0, 0), top + V(100, 0, 0)) -- tourné vers la ville (est)
	Lib.part(view, vcf * CFrame.new(0, 0.3, 0), V(30, 0.8, 18), rgb(220, 210, 190), M.Pavement)
	for k = -3, 3 do
		Lib.part(view, vcf * CFrame.new(k * 4.6, 2.2, -8.6), V(0.4, 3.4, 0.4), C.dark, M.Metal)
	end
	Lib.part(view, vcf * CFrame.new(0, 3.9, -8.6), V(30, 0.4, 0.5), C.dark, M.Metal, { Name = "Railing" })
	for _, s in { -1, 1 } do
		Lib.part(view, vcf * CFrame.new(s * 15, 2.2, 0), V(0.5, 3.4, 18), C.dark, M.Metal)
	end
	-- longue-vue
	local tel = vcf * CFrame.new(-5, 0.7, -6)
	Lib.part(view, tel * CFrame.new(0, 1.8, 0), V(0.5, 3.6, 0.5), rgb(40, 110, 200), M.Metal)
	Lib.cylDeco(view, tel * CFrame.new(0, 3.8, -0.4) * CFrame.Angles(math.rad(80), 0, 0), 2.4, 0.9, rgb(40, 110, 200), M.Metal)
	for _, x in { 4, 9 } do
		Lib.bench(view, vcf * CFrame.new(x, 0.7, -2) * CFrame.Angles(0, 0, 0))
	end
	local ps = Lib.sign(view, vcf * CFrame.new(0, 6, 9) * CFrame.Angles(0, math.pi, 0), V(14, 3, 0.4), "BELVÉDÈRE", rgb(40, 130, 80), C.white)
	-- grandes lettres sur le flanc est de la colline
	local letters = "WRONG WAY"
	local base = hill.c + V(222, 0, 0)
	for k = 1, #letters do
		local ch = letters:sub(k, k)
		if ch ~= " " then
			local x = base.X + 0
			local z = base.Z - 70 + k * 15
			local y = groundY(x, z)
			local lp = Lib.part(view, CFrame.lookAt(V(x, y + 7, z), V(x + 10, y + 9, z)), V(12, 14, 1.2), C.white, M.SmoothPlastic, { Name = "Letter" })
			Lib.label(lp, Enum.NormalId.Front, ch, rgb(230, 50, 50), nil, Enum.Font.FredokaOne)
			lp.Color = C.white
		end
	end

	---------------------------------------------------------------- Escalier piéton (raccourci vers le belvédère)
	local stairs = Lib.model(root, "EscalierDesCollines")
	local ang = math.rad(200)
	for r = 250, 80, -5 do
		local x, z = hill.c.X + math.cos(ang) * r, hill.c.Z + math.sin(ang) * r
		local y = groundY(x, z)
		local dir = V(-math.cos(ang), 0, -math.sin(ang))
		Lib.part(stairs, CFrame.lookAt(V(x, y + 0.3, z), V(x, y + 0.3, z) + dir), V(6, 0.8, 5.2), rgb(200, 186, 160), M.Cobblestone, { Name = "Step" })
	end

	---------------------------------------------------------------- Rochers et falaises
	for k = 1, 40 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(100, 270)
		local x, z = hill.c.X + math.cos(a) * r, hill.c.Z + math.sin(a) * r
		local y, hit = groundY(x, z)
		-- loin de la route et des maisons
		local ok = hit ~= nil
		for i = 1, #pts, 3 do
			if (V(pts[i].X, 0, pts[i].Z) - V(x, 0, z)).Magnitude < 24 then
				ok = false
				break
			end
		end
		for _, pad in Plan.hillPads do
			if (V(pad.p.X, 0, pad.p.Z) - V(x, 0, z)).Magnitude < 26 then
				ok = false
			end
		end
		if ok then
			rock(root, V(x, y - 1, z), rng:NextNumber(5, 12))
		end
	end
	return ("collines : %d maisons, route en spirale de %d tronçons"):format(n, #pts - 1)
end
