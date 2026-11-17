--!nolint
-- 08 : collines (route en spirale, maisons perchées, belvédère, tunnel, petit pont) et périphérie
-- (ferme, champs, forêts, terrain vague, éoliennes, plage, motel).
local Lib = require(script.Parent.Lib)
local M = Enum.Material
local C = Lib.C
local V = Vector3.new
local T = workspace.Terrain

local function groundY(x, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { T }
	local r = workspace:Raycast(V(x, 300, z), V(0, -400, 0), params)
	if r then
		return r.Position.Y, r.Material
	end
	return 0, M.Grass
end

local function blocked(x, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { T }
	return workspace:Blockcast(CFrame.new(x, 200, z), V(10, 1, 10), V(0, -260, 0), params) ~= nil
end

local function scatterTrees(parent, x1, x2, z1, z2, n, kinds)
	local placed = 0
	for k = 1, n do
		local x, z = Lib.rng:NextNumber(x1, x2), Lib.rng:NextNumber(z1, z2)
		local y, mat = groundY(x, z)
		if mat ~= M.Water and mat ~= M.Sand and mat ~= M.Snow and y > -1 and not blocked(x, z) then
			Lib.tree(parent, V(x, y - 0.3, z), Lib.pick(kinds))
			placed += 1
		end
	end
	return placed
end

return function()
	local H = Lib.path("Districts", "Hillside")
	local O = Lib.path("Districts", "Outskirts")
	local veg = Lib.path("Vegetation")
	local roads = Lib.path("Roads", "SecondaryRoads")
	local bridges = Lib.path("Roads", "Bridges")
	local rng = Lib.rng
	local white = Color3.new(1, 1, 1)

	---------------------------------------------------------------- Route en spirale de la colline
	local center = V(0, 0, -880)
	local pts = {}
	local N = 45
	for k = 0, N do
		local t = k / N
		local phi = t * 3 * math.pi
		local r = 120 - 90 * t
		table.insert(pts, V(center.X + r * math.sin(phi), 0.2 + 56 * t, center.Z + r * math.cos(phi)))
	end
	local hill = Lib.model(H, "RouteDeLaColline")
	Lib.road(hill, V(0, 0.2, -745), pts[1], 20, { center = "dashed" })
	-- 1) creuser au-dessus de la route
	for k = 1, N do
		local a, b = pts[k], pts[k + 1]
		local yaw = CFrame.lookAt(V(a.X, 0, a.Z), V(b.X, 0, b.Z))
		T:FillBlock(CFrame.new((a + b) / 2 + V(0, 13, 0)) * (yaw - yaw.Position), V(32, 25, (b - a).Magnitude + 6), M.Air)
		Lib.yield(4)
	end
	-- 2) remblai sous la route, chaussée, glissières côté extérieur
	for k = 1, N do
		local a, b = pts[k], pts[k + 1]
		local mid = (a + b) / 2
		local yaw = CFrame.lookAt(V(a.X, 0, a.Z), V(b.X, 0, b.Z))
		local hgt = mid.Y + 7
		T:FillBlock(CFrame.new(mid.X, mid.Y - 1 - hgt / 2, mid.Z) * (yaw - yaw.Position), V(26, hgt, (b - a).Magnitude + 4), M.Grass)
		Lib.road(hill, a, b, 20, { center = "dashed" })
		Lib.disc(hill, V(b.X, 0, b.Z), 10, b.Y, 1, C.asphalt, M.Asphalt, { Name = "Joint" })
		local outA = a + (V(a.X, 0, a.Z) - V(center.X, 0, center.Z)).Unit * 10.6
		local outB = b + (V(b.X, 0, b.Z) - V(center.X, 0, center.Z)).Unit * 10.6
		if k > 2 and k < N - 1 then
			Lib.beam(hill, outA + V(0, 1.4, 0), outB + V(0, 1.4, 0), 0.5, 1.2, Color3.fromRGB(200, 200, 205), M.Metal, { Name = "GuardRail" })
		end
		if k % 3 == 0 then
			Lib.part(hill, CFrame.new(outA + V(0, 0.8, 0)), V(0.4, 1.6, 0.4), C.metal, M.Metal, { Name = "RailPost" })
		end
	end
	-- maisons perchées côté extérieur, sur plateformes avec murs de soutènement
	local houses = 0
	for k = 6, N - 6, 4 do
		local p = pts[k]
		local out = (V(p.X, 0, p.Z) - V(center.X, 0, center.Z)).Unit
		local hp = p + out * 27
		T:FillBlock(CFrame.new(hp.X, (p.Y - 7) / 2 - 0.2, hp.Z), V(30, p.Y + 7, 30), M.Grass)
		T:FillBlock(CFrame.new(hp.X, p.Y + 14, hp.Z), V(30, 28, 30), M.Air)
		Lib.part(H, CFrame.lookAt(V(hp.X, 0, hp.Z), V(hp.X, 0, hp.Z) + out) * CFrame.new(0, (p.Y - 7) / 2, -15.5), V(31, p.Y + 7, 1.6), Color3.fromRGB(150, 140, 125), M.Cobblestone, { Name = "RetainingWall" })
		local cf = CFrame.lookAt(V(hp.X, p.Y - 0.2, hp.Z), V(hp.X, p.Y - 0.2, hp.Z) - out)
		Lib.house(H, cf, { w = 18, d = 16, floors = rng:NextInteger(1, 2), garage = false, name = "HillHouse" })
		-- escalier qui descend dans le jardin en contrebas
		for s = 0, 7 do
			Lib.part(H, cf * CFrame.new(10, -0.5 - s * 1, 10 + s * 1.4), V(4, 1, 1.4), C.concrete, M.Concrete, { Name = "Stair" })
		end
		houses += 1
	end
	-- belvédère au sommet
	do
		local top = pts[#pts]
		local bv = Lib.model(Lib.path("Landmarks"), "Belvedere")
		T:FillBlock(CFrame.new(center.X, top.Y + 15, center.Z), V(70, 30, 70), M.Air)
		T:FillCylinder(CFrame.new(center.X, (top.Y - 8) / 2, center.Z), top.Y + 8, 32, M.Grass)
		Lib.disc(bv, center, 30, top.Y, 1, Color3.fromRGB(205, 195, 180), M.Pavement, { Name = "Plaza" })
		for a = 0, 350, 10 do
			local p = center + V(math.cos(math.rad(a)) * 29.5, top.Y + 1.5, math.sin(math.rad(a)) * 29.5)
			local dirTo = V(math.cos(math.rad(a + 10)) * 29.5, 0, math.sin(math.rad(a + 10)) * 29.5) + center
			if not (a > 245 and a < 345) then
				Lib.beam(bv, p, V(dirTo.X, top.Y + 1.5, dirTo.Z), 0.6, 3, Color3.fromRGB(120, 90, 60), M.Wood, { Name = "Railing" })
			end
		end
		Lib.part(bv, CFrame.new(center + V(20, top.Y + 2, 10)), V(0.6, 4, 0.6), C.metal, M.Metal, { Name = "TelescopePost" })
		Lib.deco(bv, CFrame.new(center + V(20, top.Y + 4.4, 10.6)) * CFrame.Angles(math.rad(10), 0, 0), V(0.9, 0.9, 2.6), C.dark, M.Metal, { Name = "Telescope" })
		Lib.postSign(bv, CFrame.lookAt(center + V(-16, top.Y, -18), center + V(-16, top.Y, -40)), "VUE IMPRENABLE\n(sur les bouchons)", Color3.fromRGB(20, 110, 60), white, 10, 4, 4)
		for _, a in { 20, 60, 120, 160 } do
			local p = center + V(math.cos(math.rad(a)) * 24, top.Y, math.sin(math.rad(a)) * 24)
			Lib.bench(bv, CFrame.lookAt(p, V(center.X, top.Y, center.Z)) * CFrame.Angles(0, math.pi, 0))
		end
		Lib.shop(bv, Lib.facing(center + V(-12, top.Y, 6), "S"), 14, 10, "CAFÉ DU SOMMET", Color3.fromRGB(240, 230, 210), Color3.fromRGB(180, 60, 40), 10)
		Lib.parkingRow(bv, CFrame.new(center + V(8, top.Y, 10)), 3, 9, 12)
	end
	scatterTrees(veg, -125, 125, -1005, -760, 70, { "pine", "round" })

	---------------------------------------------------------------- Tunnel du Demi-Tour (x = 320)
	do
		local tn = Lib.model(Lib.path("Landmarks"), "TunnelDuDemiTour")
		T:FillBlock(CFrame.new(320, 9, -650), V(32, 18, 140), M.Air)
		local grey = Color3.fromRGB(150, 150, 150)
		for _, s in { -1, 1 } do
			Lib.part(tn, CFrame.new(320 + s * 13.5, 8, -650), V(3, 16, 132), grey, M.Concrete, { Name = "Wall" })
			Lib.deco(tn, CFrame.new(320 + s * 11.9, 3, -650), V(0.2, 1, 132), Color3.fromRGB(240, 200, 30), M.SmoothPlastic, { Name = "Stripe" })
		end
		Lib.part(tn, CFrame.new(320, 17, -650), V(30, 2, 132), grey, M.Concrete, { Name = "Ceiling" })
		for z = -705, -595, 22 do
			local l = Lib.deco(tn, CFrame.new(320, 15.8, z), V(6, 0.4, 1.2), Color3.fromRGB(255, 225, 170), M.Neon, { Name = "TunnelLight" })
			local pl = Instance.new("PointLight")
			pl.Range = 22
			pl.Brightness = 1.4
			pl.Color = Color3.fromRGB(255, 220, 170)
			pl.Parent = l
		end
		for _, z in { -584, -716 } do
			Lib.part(tn, CFrame.new(320, 21, z), V(40, 10, 4), Color3.fromRGB(120, 115, 110), M.Cobblestone, { Name = "PortalTop" })
			for _, s in { -1, 1 } do
				Lib.part(tn, CFrame.new(320 + s * 17.5, 8, z), V(5, 16, 4), Color3.fromRGB(120, 115, 110), M.Cobblestone, { Name = "PortalSide" })
			end
			local face = z > -650 and V(0, 0, 1) or V(0, 0, -1)
			local sgn = Lib.sign(tn, CFrame.lookAt(V(320, 21, z) + face * 2.1, V(320, 21, z) + face * 10), V(34, 5, 0.3), "TUNNEL DU DEMI-TOUR", Color3.fromRGB(20, 110, 60), white, { glow = true })
			-- remblai au-dessus du portail
			T:FillBlock(CFrame.new(320, 30, z - face.Z * 6), V(46, 12, 10), M.Grass)
		end
		Lib.postSign(tn, CFrame.lookAt(V(337, Lib.WALK, -560), V(337, Lib.WALK, -550)), "Allumez vos phares\n(ou pas, on n'est pas vos parents)", Color3.fromRGB(30, 80, 170), white, 9, 3, 6)
	end

	---------------------------------------------------------------- Ruisseau et petit pont (x = -320, z = -800)
	do
		T:FillBlock(CFrame.new(-560, -3, -800), V(620, 6, 24), M.Air)
		T:FillBlock(CFrame.new(-560, -4.5, -800), V(620, 3, 24), M.Water)
		T:FillBlock(CFrame.new(-560, -7, -800), V(620, 2, 32), M.Mud)
		local pb = Lib.model(bridges, "PetitPontDuRuisseau")
		for _, s in { -1, 1 } do
			Lib.part(pb, CFrame.new(-320 + s * 12.6, 1.6, -800), V(0.8, 2.8, 30), Color3.fromRGB(120, 85, 55), M.Wood, { Name = "Rail" })
		end
		Lib.part(pb, CFrame.new(-320, -1.2, -800), V(24, 1.6, 28), Color3.fromRGB(140, 130, 120), M.Cobblestone, { Name = "Arch" })
		Lib.postSign(pb, CFrame.lookAt(V(-336, 0.2, -780), V(-336, 0.2, -770)), "PETIT PONT DU RUISSEAU\n(cartons : ne pas lancer)", Color3.fromRGB(20, 110, 60), white, 9, 3, 6)
	end

	---------------------------------------------------------------- Ferme et champs (nord-ouest)
	do
		local farm = Lib.model(O, "FermeDesColisFrais")
		local crops = { M.Ground, M.LeafyGrass, M.Mud, M.Grass }
		for fx = 0, 3 do
			for fz = 0, 3 do
				local x1, z1 = -300 + fx * 70, 540 + fz * 105
				if not (fx >= 2 and fz <= 1) then
					T:FillBlock(CFrame.new(x1 + 32, -1, z1 + 48), V(60, 2, 92), crops[(fx + fz) % #crops + 1])
					for k = 1, 3 do
						Lib.deco(farm, CFrame.new(x1 + rng:NextNumber(8, 56), 1.4, z1 + rng:NextNumber(8, 88)) * CFrame.Angles(0, 0, math.rad(90)), V(4, 3, 3), Color3.fromRGB(220, 190, 90), M.Fabric, { Shape = Enum.PartType.Cylinder, Name = "HayBale" })
					end
				end
			end
		end
		local bp = V(-120, 0, 610)
		Lib.part(farm, CFrame.new(bp + V(0, 10, 0)), V(36, 20, 50), Color3.fromRGB(170, 40, 35), M.WoodPlanks, { Name = "Barn" })
		Lib.part(farm, CFrame.new(bp + V(-9.5, 24, 0)), V(19, 8, 52), Color3.fromRGB(60, 60, 65), M.Slate, { Class = "WedgePart", Name = "BarnRoof", CFrame = CFrame.new(bp + V(-9.5, 24, 0)) * CFrame.Angles(0, math.rad(-90), 0) })
		Lib.part(farm, CFrame.new(bp + V(9.5, 24, 0)), V(19, 8, 52), Color3.fromRGB(60, 60, 65), M.Slate, { Class = "WedgePart", Name = "BarnRoof", CFrame = CFrame.new(bp + V(9.5, 24, 0)) * CFrame.Angles(0, math.rad(90), 0) })
		Lib.deco(farm, CFrame.new(bp + V(18.15, 8, 0)), V(0.3, 14, 16), white, M.WoodPlanks, { Name = "BarnDoor" })
		Lib.part(farm, CFrame.new(bp + V(0, 20, 34)) * CFrame.Angles(0, 0, math.rad(90)), V(40, 14, 14), Color3.fromRGB(200, 200, 205), M.Metal, { Shape = Enum.PartType.Cylinder, Name = "Silo" })
		Lib.deco(farm, CFrame.new(bp + V(0, 40, 34)), V(14, 6, 14), Color3.fromRGB(170, 40, 35), M.Metal, { Shape = Enum.PartType.Ball, Name = "SiloTop" })
		local s = Lib.sign(farm, CFrame.lookAt(bp + V(18.4, 17, 0), bp + V(30, 17, 0)), V(30, 4, 0.3), "FERME DES COLIS FRAIS", Color3.fromRGB(240, 230, 200), Color3.fromRGB(120, 30, 25))
		-- tracteur, vaches, clôtures
		local tr = bp + V(40, 0, -30)
		Lib.part(farm, CFrame.new(tr + V(0, 3, 0)), V(5, 4, 9), Color3.fromRGB(40, 140, 60), M.Metal, { Name = "Tractor" })
		Lib.part(farm, CFrame.new(tr + V(0, 6.5, 1.5)), V(4.4, 3.5, 4), Color3.fromRGB(40, 140, 60), M.Glass, { Transparency = 0.3, Name = "TractorCab" })
		for _, o in { { -2.8, 2.5, 5 }, { 2.8, 2.5, 5 }, { -2.6, -2.5, 3 }, { 2.6, -2.5, 3 } } do
			Lib.deco(farm, CFrame.new(tr + V(o[1], o[3] / 2, o[2])) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(0, 0, 0), V(1.2, o[3], o[3]), C.dark, M.Rubber, { Shape = Enum.PartType.Cylinder })
		end
		for k = 1, 6 do
			local cp = V(-260 + rng:NextNumber(0, 120), 0, 880 + rng:NextNumber(-40, 40))
			local cow = Lib.model(farm, "Cow")
			local yaw = CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
			Lib.part(cow, CFrame.new(cp + V(0, 3.2, 0)) * yaw, V(2.6, 2.4, 5), white, M.SmoothPlastic)
			Lib.deco(cow, CFrame.new(cp + V(0, 3.2, 0)) * yaw * CFrame.new(0, 0.6, -3), V(1.6, 1.6, 1.8), white, M.SmoothPlastic)
			Lib.deco(cow, CFrame.new(cp + V(0, 3.2, 0)) * yaw * CFrame.new(0.8, 0.4, 0.5), V(1.2, 1.2, 1.6), C.dark, M.SmoothPlastic)
			for _, l in { { -0.9, -1.8 }, { 0.9, -1.8 }, { -0.9, 1.8 }, { 0.9, 1.8 } } do
				Lib.deco(cow, CFrame.new(cp + V(0, 3.2, 0)) * yaw * CFrame.new(l[1], -2, l[2]), V(0.5, 2, 0.5), white, M.SmoothPlastic)
			end
		end
		Lib.fence(farm, V(-300, 0, 830), V(-30, 0, 830), 3, Color3.fromRGB(150, 110, 70), true, M.Wood)
		Lib.fence(farm, V(-300, 0, 830), V(-300, 0, 960), 3, Color3.fromRGB(150, 110, 70), true, M.Wood)
		Lib.fence(farm, V(-30, 0, 830), V(-30, 0, 960), 3, Color3.fromRGB(150, 110, 70), true, M.Wood)
		Lib.postSign(farm, CFrame.lookAt(V(-14, 0.2, 640), V(-4, 0.2, 640)), "Œufs frais — livrés à l'envers\n(c'est plus sûr)", Color3.fromRGB(240, 230, 200), Color3.fromRGB(120, 30, 25), 9, 3, 5)
	end

	---------------------------------------------------------------- Terrain vague, éoliennes (ouest)
	do
		local tv = Lib.model(O, "TerrainVague")
		local c = V(-700, 0, -160)
		T:FillBlock(CFrame.new(c.X, -1, c.Z), V(220, 2, 200), M.Ground)
		for k = 1, 12 do
			local p = c + V(rng:NextNumber(-100, 100), 0, rng:NextNumber(-90, 90))
			Lib.part(tv, CFrame.new(p + V(0, 2, 0)) * CFrame.Angles(math.rad(rng:NextNumber(-15, 15)), rng:NextNumber(0, 6), math.rad(rng:NextNumber(-160, 160) * (rng:NextNumber() < 0.3 and 1 or 0.1))), V(6, 3.5, 11), Color3.fromHSV(rng:NextNumber(), 0.4, 0.45), M.CorrodedMetal, { Name = "AbandonedCar" })
		end
		for k = 1, 20 do
			local p = c + V(rng:NextNumber(-100, 100), 0, rng:NextNumber(-90, 90))
			Lib.deco(tv, CFrame.new(p + V(0, 0.6, 0)) * CFrame.Angles(0, 0, 0), V(1.2, 3, 3), C.dark, M.Rubber, { Shape = Enum.PartType.Cylinder, Name = "Tire" })
		end
		for k = 1, 6 do
			local p = c + V(rng:NextNumber(-90, 90), 0, rng:NextNumber(-80, 80))
			local w = Lib.part(tv, CFrame.new(p + V(0, 5, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), V(20, 10, 1.4), Color3.fromRGB(160, 150, 140), M.Concrete, { Name = "GraffitiWall" })
			Lib.label(w, Enum.NormalId.Front, Lib.pick({ "LIVRER C'EST TOURNER", "OOPSIE = 0", "WWD 4EVER", "ICI ON RECULE", "TOUT DROIT ?" }), Color3.fromHSV(rng:NextNumber(), 0.8, 1), nil, Enum.Font.FredokaOne)
		end
		local bb = Lib.model(tv, "BrokenBillboard")
		Lib.part(bb, CFrame.new(c + V(0, 10, 95)), V(1, 20, 1), C.metal, M.Metal)
		Lib.sign(bb, CFrame.new(c + V(4, 18, 95)) * CFrame.Angles(0, 0, math.rad(-12)), V(26, 9, 0.5), "VOTRE PUB ICI\n(personne ne la verra)", Color3.fromRGB(200, 200, 190), C.dark)
		for k = 0, 4 do
			local p = V(-780 + (k % 2) * 90, 0, 150 + k * 70)
			local y = groundY(p.X, p.Z)
			local wt = Lib.model(O, "WindTurbine")
			Lib.part(wt, CFrame.new(p.X, y + 40, p.Z), V(3, 80, 3), white, M.SmoothPlastic, { Name = "Mast" })
			Lib.deco(wt, CFrame.new(p.X, y + 80, p.Z - 1), V(4, 4, 8), white, M.SmoothPlastic, { Name = "Nacelle" })
			for b = 0, 2 do
				Lib.deco(wt, CFrame.new(p.X, y + 80, p.Z - 5.5) * CFrame.Angles(0, 0, math.rad(b * 120 + k * 17)) * CFrame.new(0, 13, 0), V(2, 26, 0.5), white, M.SmoothPlastic, { Name = "Blade" })
			end
		end
	end

	---------------------------------------------------------------- Plage du lac (est)
	do
		local bch = Lib.model(Lib.path("Landmarks"), "PlageDuLac")
		local cols = { Color3.fromRGB(240, 70, 70), Color3.fromRGB(250, 210, 60), Color3.fromRGB(60, 150, 230), Color3.fromRGB(80, 200, 120) }
		for k = 1, 9 do
			local p = V(770 + rng:NextNumber(0, 60), 0, 620 + rng:NextNumber(0, 140))
			local y = groundY(p.X, p.Z)
			local col = Lib.pick(cols)
			Lib.deco(bch, CFrame.new(p.X, y + 4, p.Z), V(0.3, 8, 0.3), white, M.Metal, { Name = "UmbrellaPole" })
			Lib.deco(bch, CFrame.new(p.X, y + 8, p.Z), V(1.2, 9, 9), col, M.Fabric, { Shape = Enum.PartType.Cylinder, Name = "Umbrella", CFrame = CFrame.new(p.X, y + 8, p.Z) * CFrame.Angles(0, 0, math.rad(90)) })
			Lib.deco(bch, CFrame.new(p.X + 3, y + 0.1, p.Z + 1) * CFrame.Angles(0, rng:NextNumber(0, 1), 0), V(3, 0.1, 6), Lib.pick(cols), M.Fabric, { Name = "Towel" })
		end
		local lg = V(790, groundY(790, 700), 700)
		for _, o in { { -2, -2 }, { 2, -2 }, { -2, 2 }, { 2, 2 } } do
			Lib.part(bch, CFrame.new(lg + V(o[1], 5, o[2])), V(0.6, 10, 0.6), Color3.new(1, 1, 1), M.Wood)
		end
		Lib.part(bch, CFrame.new(lg + V(0, 10.5, 0)), V(6, 1, 6), Color3.fromRGB(240, 70, 70), M.WoodPlanks, { Name = "LifeguardTower" })
		Lib.deco(bch, CFrame.new(lg + V(0, 14, 0)), V(6.6, 0.5, 6.6), Color3.fromRGB(240, 70, 70), M.Fabric)
		Lib.beam(bch, lg + V(0, 10, -3), lg + V(0, 0, -9), 3, 0.5, C.wood, M.WoodPlanks, { Name = "Ladder" }, true)
		local bar = Lib.shop(bch, Lib.facing(V(852, groundY(852, 690), 690), "W"), 22, 14, "BAR LA MARCHE ARRIÈRE", Color3.fromRGB(240, 220, 170), Color3.fromRGB(40, 160, 160), 10)
		local net = V(810, groundY(810, 760), 770)
		for _, z in { -10, 10 } do
			Lib.part(bch, CFrame.new(net + V(0, 4, z)), V(0.4, 8, 0.4), white, M.Metal)
		end
		Lib.deco(bch, CFrame.new(net + V(0, 6.5, 0)), V(0.1, 3, 20), white, M.Fabric, { Transparency = 0.4, Name = "VolleyNet" })
		for k = 1, 10 do
			local p = V(760 + rng:NextNumber(0, 110), 0, 600 + rng:NextNumber(0, 200))
			Lib.tree(veg, V(p.X, groundY(p.X, p.Z) - 0.3, p.Z), "palm")
		end
		-- ponton
		Lib.slab(bch, 690, 770, 676, 684, 0.8, 0.8, C.wood, M.WoodPlanks, { Name = "Boardwalk" })
		for x = 694, 766, 12 do
			Lib.part(bch, CFrame.new(x, -4, 680), V(1, 9, 1), C.wood, M.Wood)
		end
		-- parking de la plage le long de la périphérique
		Lib.slab(bch, 862, 886, 620, 760, 0.6, 1, C.asphalt, M.Asphalt, { Name = "BeachParking" })
		Lib.postSign(bch, CFrame.lookAt(V(884, 0.6, 610), V(894, 0.6, 610)), "PLAGE DU LAC\nbaignade interdite aux cartons", Color3.fromRGB(40, 160, 160), white, 10, 3.5, 6)
	end

	---------------------------------------------------------------- Motel (est, route z = 320)
	do
		local mo = Lib.model(O, "MotelLeDernierVirage")
		for k = 0, 5 do
			Lib.house(mo, Lib.facing(V(740 + k * 22, 0, 370), "S"), { w = 20, d = 18, floors = 1, flat = true, garage = false, color = Color3.fromRGB(240, 200, 160), name = "MotelRoom" })
		end
		Lib.slab(mo, 728, 872, 336, 356, 0.6, 1, C.asphalt, M.Asphalt, { Name = "MotelParking" })
		Lib.part(mo, CFrame.new(720, 12, 345), V(1.2, 24, 1.2), C.metal, M.Metal)
		Lib.sign(mo, CFrame.lookAt(V(720, 26, 345), V(720, 26, 330)), V(16, 6, 0.6), "MOTEL LE DERNIER VIRAGE\nCHAMBRES LIBRES (vraiment toutes)", Color3.fromRGB(200, 50, 90), Color3.fromRGB(255, 240, 150), { glow = true, double = true })
	end

	---------------------------------------------------------------- Forêts (diffusion avec raycast)
	local trees = 0
	for _, r in {
		{ -880, -340, 540, 980, 90 }, { 20, 300, 540, 980, 80 }, { 340, 520, 540, 980, 40 },
		{ -880, -500, -1030, -340, 90 }, { -880, -500, 20, 140, 25 }, { -880, -500, 340, 480, 30 },
		{ 700, 880, -1030, -340, 70 }, { 700, 880, -300, -20, 40 }, { 700, 880, 20, 300, 35 },
		{ -300, -140, -1030, -520, 40 }, { 130, 300, -1030, -760, 40 }, { 360, 540, -1030, -520, 50 },
		{ -480, 480, -1030, -980, 30 },
	} do
		trees += scatterTrees(veg, r[1], r[2], r[3], r[4], r[5], { "pine", "pine", "round" })
	end
	return ("collines + périphérie ok : %d maisons perchées, %d arbres"):format(houses, trees)
end
