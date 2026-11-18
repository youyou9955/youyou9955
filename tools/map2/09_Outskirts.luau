--!nolint
-- 09 : périphérie. Pont rouge en treillis (boulevard, à l'est), pont en arc (avenue, au sud), tunnel du Col
-- sous la crête nord, belvédère du nord, cascade sur la falaise, ferme, motel, plage du lac avec phare
-- et ponton, éoliennes, panneaux d'entrée et de direction.
local Lib = require(script.Parent.Lib)
local Build = require(script.Parent.Build)
local Plan = require(script.Parent.Plan)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C

local rng = Random.new(909)

local function groundY(x, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(V(x, 400, z), V(0, -800, 0), params)
	return hit and hit.Position.Y or 0
end

---------------------------------------------------------------- Ponts
-- Pont : a -> b (au niveau de la chaussée), largeur de chaussée w
local function trussBridge(parent, a, b, w, color)
	local m = Lib.model(parent, "PontRouge")
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	local half = w / 2 + 6
	-- tablier béton et trottoirs
	Lib.part(m, cf * CFrame.new(0, -1.8, 0), V(w + 14, 3, len), rgb(180, 178, 172), M.Concrete, { Name = "Deck" })
	for _, s in { -1, 1 } do
		Lib.part(m, cf * CFrame.new(s * (w / 2 + 3), 0.5, 0), V(6, 1, len), rgb(206, 202, 194), M.Concrete, { Name = "Walkway" })
		Lib.part(m, cf * CFrame.new(s * (w / 2 + 6.2), 2.2, 0), V(0.5, 0.5, len), C.white, M.Metal, { Name = "Railing" })
	end
	-- treillis
	local h = 16
	local n = math.floor(len / 12)
	for _, s in { -1, 1 } do
		local x = s * half
		Lib.part(m, cf * CFrame.new(x, h, 0), V(1.4, 1.4, len), color, M.Metal, { Name = "TopChord" })
		Lib.part(m, cf * CFrame.new(x, 0.9, 0), V(1.4, 1.4, len), color, M.Metal, { Name = "BottomChord" })
		for k = 0, n do
			local z = -len / 2 + k * len / n
			Lib.part(m, cf * CFrame.new(x, h / 2, z), V(1.2, h, 1.2), color, M.Metal)
			if k < n then
				local z2 = -len / 2 + (k + 1) * len / n
				local p0 = (cf * CFrame.new(x, 1, z)).Position
				local p1 = (cf * CFrame.new(x, h, z2)).Position
				if k % 2 == 1 then
					p0, p1 = (cf * CFrame.new(x, h, z)).Position, (cf * CFrame.new(x, 1, z2)).Position
				end
				Lib.beam(m, p0, p1, 0.8, 0.8, color, M.Metal, { CanCollide = false })
			end
		end
	end
	-- entretoises supérieures
	for k = 0, n, 2 do
		local z = -len / 2 + k * len / n
		Lib.fine(m, cf * CFrame.new(0, h, z), V(half * 2, 1, 1), color, M.Metal)
	end
	-- piles dans l'eau
	for _, t in { -0.25, 0.25 } do
		Lib.part(m, cf * CFrame.new(0, -12, t * len), V(w + 6, 18, 8), rgb(170, 166, 158), M.Concrete, { Name = "Pier" })
	end
	return m
end

local function archBridge(parent, a, b, w)
	local m = Lib.model(parent, "PontEnArc")
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	Lib.part(m, cf * CFrame.new(0, -1.8, 0), V(w + 14, 3, len), rgb(236, 232, 222), M.Concrete, { Name = "Deck" })
	for _, s in { -1, 1 } do
		Lib.part(m, cf * CFrame.new(s * (w / 2 + 3), 0.5, 0), V(6, 1, len), rgb(206, 202, 194), M.Concrete, { Name = "Walkway" })
		-- balustrade
		Lib.part(m, cf * CFrame.new(s * (w / 2 + 6.2), 3, 0), V(0.8, 0.6, len), C.white, M.SmoothPlastic)
		for k = 0, math.floor(len / 3) do
			Lib.fine(m, cf * CFrame.new(s * (w / 2 + 6.2), 1.7, -len / 2 + k * 3), V(0.5, 2.4, 0.5), C.white, M.SmoothPlastic)
		end
		-- arc sous le tablier
		local nA = 14
		for k = 0, nA - 1 do
			local t0, t1 = k / nA, (k + 1) / nA
			local function at(t)
				return (cf * CFrame.new(s * (w / 2 + 4), -3 - 14 * (1 - math.sin(t * math.pi)) - 2, -len / 2 + t * len)).Position
			end
			Lib.beam(m, at(t0), at(t1), 2.4, 2.4, rgb(236, 232, 222), M.Concrete)
		end
	end
	-- lampadaires du pont
	for k = -2, 2 do
		for _, s in { -1, 1 } do
			local p = (cf * CFrame.new(s * (w / 2 + 5.5), 1, k * len / 5)).Position
			Lib.lamp(m, CFrame.lookAt(p, (cf * CFrame.new(0, 1, k * len / 5)).Position))
		end
	end
	return m
end

---------------------------------------------------------------- Tunnel
---------------------------------------------------------------- Ferme
local function barn(parent, cf)
	local m = Lib.model(parent, "Grange")
	local red, white = rgb(190, 50, 40), C.white
	local w, d, h = 40, 56, 18
	Lib.part(m, cf * CFrame.new(0, h / 2, 0), V(w, h, d), red, M.WoodPlanks, { Name = "Body" })
	-- toit à la Mansart (deux pentes par côté)
	for _, s in { -1, 1 } do
		Lib.part(m, cf * CFrame.new(s * (w / 2 - 3), h + 5, 0) * CFrame.Angles(0, 0, s * math.rad(-60)), V(12, 1, d + 2), rgb(70, 70, 76), M.SmoothPlastic)
		Lib.part(m, cf * CFrame.new(s * (w / 4 - 1.5), h + 12.2, 0) * CFrame.Angles(0, 0, s * math.rad(-22)), V(w / 2 + 1, 1, d + 2), rgb(70, 70, 76), M.SmoothPlastic)
	end
	for _, sz in { -1, 1 } do
		Lib.part(m, cf * CFrame.new(0, h + 5, sz * (d / 2 - 0.3)), V(w - 6, 10, 0.6), red, M.WoodPlanks)
		Lib.part(m, cf * CFrame.new(0, h + 11, sz * (d / 2 - 0.3)), V(w * 0.6, 6, 0.6), red, M.WoodPlanks)
	end
	local f = Build.face(cf, w, d, 1)
	-- grande porte avec croix blanche
	Lib.fine(m, f * CFrame.new(0, 7, -0.2), V(16, 14, 0.3), white, M.SmoothPlastic)
	Lib.fine(m, f * CFrame.new(0, 7, -0.4), V(14, 12, 0.2), rgb(160, 40, 30), M.WoodPlanks)
	Lib.fine(m, f * CFrame.new(0, 7, -0.55) * CFrame.Angles(0, 0, math.rad(40)), V(0.8, 18, 0.1), white, M.SmoothPlastic)
	Lib.fine(m, f * CFrame.new(0, 7, -0.55) * CFrame.Angles(0, 0, math.rad(-40)), V(0.8, 18, 0.1), white, M.SmoothPlastic)
	Lib.fine(m, f * CFrame.new(0, h + 6, -0.4), V(6, 5, 0.2), white, M.SmoothPlastic)
	Lib.fine(m, f * CFrame.new(0, h + 6, -0.55), V(4.6, 3.6, 0.1), rgb(60, 40, 30), M.SmoothPlastic)
	for _, x in { -w / 2 + 0.3, w / 2 - 0.3 } do
		Lib.fine(m, f * CFrame.new(x, h / 2, -0.2), V(0.8, h, 0.3), white, M.SmoothPlastic)
	end
	local sg = Lib.fine(m, f * CFrame.new(0, h + 1, -0.5), V(26, 3, 0.3), rgb(240, 232, 214), M.SmoothPlastic)
	Lib.label(sg, Enum.NormalId.Front, "FERME DES COLIS FRAIS", rgb(150, 40, 30), nil, Enum.Font.FredokaOne)
	return m
end

local function silo(parent, pos)
	local m = Lib.model(parent, "Silo")
	Lib.cyl(m, CFrame.new(pos + V(0, 16, 0)), 32, 14, rgb(220, 224, 230), M.Metal)
	for k = 1, 4 do
		Lib.cylDeco(m, CFrame.new(pos + V(0, k * 7, 0)), 0.6, 14.4, rgb(180, 184, 190), M.Metal)
	end
	Lib.ball(m, pos + V(0, 32, 0), 14.2, rgb(190, 50, 40), M.SmoothPlastic)
	return m
end

local function tractor(parent, cf)
	local m = Lib.model(parent, "Tracteur")
	local g = rgb(60, 160, 60)
	Lib.part(m, cf * CFrame.new(0, 3, 0), V(5, 3, 10), g, M.SmoothPlastic)
	Lib.part(m, cf * CFrame.new(0, 6.5, 2), V(5, 4, 4.5), g, M.SmoothPlastic)
	Lib.fine(m, cf * CFrame.new(0, 7, 2), V(5.2, 2.6, 3.8), rgb(170, 215, 238), M.Glass)
	Lib.part(m, cf * CFrame.new(0, 9, 2), V(6, 0.6, 5.5), rgb(255, 200, 40), M.SmoothPlastic)
	Lib.cylDeco(m, cf * CFrame.new(0, 6, -3) , 4, 0.8, C.dark, M.Metal)
	for _, s in { -1, 1 } do
		Lib.part(m, cf * CFrame.new(s * 3.2, 3.2, 3) * CFrame.Angles(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), V(2, 6.4, 6.4), C.dark, M.Rubber, { Shape = Enum.PartType.Cylinder })
		Lib.part(m, cf * CFrame.new(s * 2.8, 1.8, -3.5) * CFrame.Angles(0, 0, math.rad(90)), V(1.4, 3.6, 3.6), C.dark, M.Rubber, { Shape = Enum.PartType.Cylinder })
		Lib.fine(m, cf * CFrame.new(s * 4.25, 3.2, 3) * CFrame.Angles(0, 0, math.rad(90)), V(0.1, 3.2, 3.2), rgb(255, 200, 40), M.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
	end
	return m
end

---------------------------------------------------------------- Divers
local function windTurbine(parent, pos)
	local m = Lib.model(parent, "Eolienne")
	local y = groundY(pos.X, pos.Z)
	local base = V(pos.X, y, pos.Z)
	Lib.cyl(m, CFrame.new(base + V(0, 30, 0)), 60, 3, C.white, M.SmoothPlastic)
	Lib.part(m, CFrame.new(base + V(0, 61, 1)), V(3.6, 3.6, 8), C.white, M.SmoothPlastic)
	local hub = base + V(0, 61, -3.4)
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2 + 0.3
		Lib.part(m, CFrame.new(hub) * CFrame.Angles(0, 0, a) * CFrame.new(0, 12, 0), V(2.2, 24, 0.5), C.white, M.SmoothPlastic, { CanCollide = false })
	end
	Lib.ball(m, hub, 3, rgb(230, 60, 50), M.SmoothPlastic)
	return m
end

local function lighthouse(parent, pos)
	local m = Lib.model(Lib.path("Landmarks"), "Phare")
	local y = groundY(pos.X, pos.Z)
	local b = V(pos.X, y, pos.Z)
	Lib.cyl(m, CFrame.new(b + V(0, 1.5, 0)), 3, 22, rgb(200, 196, 186), M.Cobblestone)
	for k = 0, 5 do
		Lib.cyl(m, CFrame.new(b + V(0, 3 + k * 6 + 3, 0)), 6, 12 - k * 0.6, k % 2 == 0 and rgb(230, 50, 50) or C.white, M.SmoothPlastic)
	end
	local top = b + V(0, 39, 0)
	Lib.cyl(m, CFrame.new(top + V(0, 0.5, 0)), 1, 13, C.dark, M.Metal)
	Lib.cyl(m, CFrame.new(top + V(0, 3.5, 0)), 5, 7, rgb(255, 236, 160), M.Neon)
	Lib.cyl(m, CFrame.new(top + V(0, 6.6, 0)), 1.2, 9, rgb(230, 50, 50), M.SmoothPlastic)
	Lib.part(m, CFrame.new(top + V(0, 8.5, 0)) * CFrame.Angles(0, math.rad(45), 0), V(5, 3, 5), rgb(230, 50, 50), M.SmoothPlastic)
	return m
end

return function()
	local root = Lib.path("Outskirts")
	local bridges = Lib.path("Roads", "Bridges")
	local signs = Lib.path("Roads", "Signs")

	-- Ponts
	trussBridge(bridges, V(978, Lib.ROAD, 0), V(1102, Lib.ROAD, 0), 48, rgb(210, 50, 40))
	archBridge(bridges, V(0, Lib.ROAD, 838), V(0, Lib.ROAD, 962), 48)

	---------------------------------------------------------------- Belvédère du nord (après le tunnel)
	do
		local m = Lib.model(root, "BelvedereDuNord")
		local c = V(0, 0, -1250)
		Lib.part(m, CFrame.new(c + V(0, 0.1, -20)), V(80, 0.6, 40), C.asphaltDark, M.Asphalt)
		for k = 0, 6 do
			Lib.mark(m, CFrame.new(c + V(-30 + k * 10, 0.42, -26)), V(0.35, 0.05, 16), C.white)
		end
		Build.shopBlock(m, Lib.facing(c + V(30, 0.3, -52), V(0, 0, 1)), 24, 16, 0, rgb(160, 120, 80), C.white, { "CAFÉ DU COL", rgb(140, 70, 40), C.white }, "Cafe")
		Lib.postSign(m, Lib.facing(c + V(-36, 0.4, -8), V(0, 0, 1)), "BELVÉDÈRE DU NORD", rgb(40, 130, 80), C.white, 16, 3, 8)
		for k = 0, 3 do
			Lib.bench(m, Lib.facing(c + V(-30 + k * 12, 0.4, -44), V(0, 0, -1)))
		end
	end

	---------------------------------------------------------------- Cascade
	do
		local m = Lib.model(Lib.path("Landmarks"), "Cascade")
		local top = groundY(1112, -420)
		local x0 = 1090
		local water = rgb(120, 200, 240)
		for k = 0, 2 do
			Lib.fine(m, CFrame.new(x0 + k * 1.2, top / 2 - 1, -420), V(1, top + 2, 30 - k * 6), k == 1 and rgb(235, 248, 255) or water, M.Glass, { Transparency = 0.15 + k * 0.1, Name = "Waterfall" })
		end
		-- ruisseau au sommet
		Lib.fine(m, CFrame.new(x0 + 30, top + 0.2, -420), V(60, 0.4, 24), water, M.Glass, { Transparency = 0.2 })
		local mist = Lib.part(m, CFrame.new(x0 - 6, -1, -420), V(20, 1, 30), water, M.SmoothPlastic, { Transparency = 1, CanCollide = false, Name = "Mist" })
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(C.white)
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 10) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
		pe.Lifetime = NumberRange.new(2, 3)
		pe.Rate = 18
		pe.Speed = NumberRange.new(3, 6)
		pe.SpreadAngle = Vector2.new(60, 60)
		pe.Parent = mist
	end

	---------------------------------------------------------------- Ferme
	do
		local m = Lib.model(root, "FermeDesColisFrais")
		barn(m, Lib.facing(V(1260, 0, -170), V(0, 0, 1)))
		silo(m, V(1300, 0, -200))
		silo(m, V(1318, 0, -176))
		-- champs
		for f = 0, 1 do
			local fc = V(1180 + f * 120, 0, -260 - f * 10)
			Lib.part(m, CFrame.new(fc + V(0, 0.2, 0)), V(90, 0.6, 50), rgb(140, 100, 64), M.Ground, { Name = "Field" })
			for r = 0, 7 do
				Lib.part(m, CFrame.new(fc + V(-40 + r * 11.4, 0.9, 0)), V(4, 1, 46), f == 0 and rgb(110, 190, 70) or rgb(240, 200, 70), M.Grass, { Name = "Crop", CanCollide = false })
			end
		end
		-- clôture en bois et vaches
		local fen = { V(1200, 0, -120), V(1200, 0, -60), V(1340, 0, -60), V(1340, 0, -120) }
		for k = 1, 3 do
			local a, b = fen[k], fen[k + 1]
			local mm = Lib.model(m, "WoodFence")
			local len = (b - a).Magnitude
			local cf = CFrame.lookAt((a + b) / 2, b)
			Lib.part(mm, cf * CFrame.new(0, 2.6, 0), V(0.4, 0.5, len), rgb(150, 105, 65), M.Wood)
			Lib.fine(mm, cf * CFrame.new(0, 1.4, 0), V(0.4, 0.5, len), rgb(150, 105, 65), M.Wood)
			for t = 0, math.floor(len / 8) do
				Lib.part(mm, cf * CFrame.new(0, 1.6, -len / 2 + t * 8), V(0.6, 3.2, 0.6), rgb(130, 90, 55), M.Wood)
			end
		end
		for k = 1, 6 do
			Lib.asset("Cow", m, CFrame.new(1220 + rng:NextNumber(0, 100), 0, -110 + rng:NextNumber(0, 40)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), 5, true, "Cow")
		end
		-- bottes de foin
		for k = 0, 5 do
			Lib.cyl(m, CFrame.new(1360 + (k % 3) * 7, 3, -230 + math.floor(k / 3) * 8) * CFrame.Angles(math.pi / 2, 0, 0), 6, 6, rgb(230, 200, 100), M.Grass)
		end
		tractor(m, CFrame.new(1230, 0, -140) * CFrame.Angles(0, math.rad(70), 0))
		-- chemin et boîte aux lettres
		Lib.part(m, CFrame.new(1260, 0.15, -90), V(14, 0.5, 120), rgb(170, 150, 120), M.Ground, { Name = "FarmTrack" })
		Lib.mailbox(m, Lib.facing(V(1250, 0, -34), V(0, 0, 1)))
		Lib.postSign(m, Lib.facing(V(1240, 0, -32), V(0, 0, 1)), "FERME DES COLIS FRAIS", rgb(150, 40, 30), C.white, 18, 3, 8)
	end

	---------------------------------------------------------------- Motel
	do
		local m = Lib.model(root, "MotelLeDernierVirage")
		local cf = Lib.facing(V(1210, 0, 80), V(0, 0, -1))
		local w, d, h = 90, 22, 11
		Lib.part(m, cf * CFrame.new(0, h / 2, 0), V(w, h, d), rgb(250, 220, 170), M.SmoothPlastic)
		Lib.part(m, cf * CFrame.new(0, h + 0.5, -3), V(w + 4, 1, d + 8), rgb(60, 140, 140), M.SmoothPlastic)
		local f = Build.face(cf, w, d, 1)
		for k = 0, 7 do
			local x = -w / 2 + 6 + k * 11
			Lib.fine(m, f * CFrame.new(x, 3.8, -0.2), V(3.4, 7, 0.3), ({ rgb(230, 80, 60), rgb(60, 140, 200), rgb(250, 190, 40) })[k % 3 + 1], M.SmoothPlastic)
			Build.window(m, f * CFrame.new(x + 4.4, 5, 0), 3.4, 3, C.white, C.glass)
		end
		for k = 0, 5 do
			Lib.part(m, f * CFrame.new(-w / 2 + 4 + k * 16.4, 5.5, -6.5), V(0.8, 11, 0.8), C.white, M.SmoothPlastic)
		end
		local pole = cf * CFrame.new(-w / 2 - 10, 0, -14)
		Lib.part(m, pole * CFrame.new(0, 11, 0), V(1.2, 22, 1.2), C.dark, M.Metal)
		local sg = Lib.part(m, pole * CFrame.new(0, 24, 0), V(16, 7, 1), rgb(230, 60, 90), M.Neon, { CanCollide = false })
		Lib.label(sg, Enum.NormalId.Front, "MOTEL\nLE DERNIER VIRAGE", C.white, nil, Enum.Font.FredokaOne, true)
		Lib.label(sg, Enum.NormalId.Back, "MOTEL\nLE DERNIER VIRAGE", C.white, nil, Enum.Font.FredokaOne, true)
		Lib.parking(m, CFrame.new(1210, 0, 52), 90, 30, 0.4)
	end

	---------------------------------------------------------------- Plage du lac, ponton, phare
	do
		local m = Lib.model(root, "PlageDuLac")
		local lake = Plan.river.lake
		local shore = lake.c + V(lake.r + 12, 0, 40)
		Lib.part(m, CFrame.new(-560, 0.1, 1060), V(60, 0.6, 50), C.asphaltDark, M.Asphalt, { Name = "BeachParking" })
		for k = 0, 5 do
			local p = shore + V(rng:NextNumber(-6, 14), 0, -60 + k * 22)
			local y = groundY(p.X, p.Z)
			local col = ({ rgb(240, 70, 70), rgb(60, 140, 240), rgb(255, 200, 40) })[k % 3 + 1]
			Lib.part(m, CFrame.new(p.X, y + 3, p.Z), V(0.4, 6, 0.4), C.white, M.SmoothPlastic, { CanCollide = false })
			Lib.cylDeco(m, CFrame.new(p.X, y + 6, p.Z), 0.5, 9, col, M.Fabric)
			Lib.fine(m, CFrame.new(p.X + 3, y + 0.1, p.Z), V(3, 0.1, 6), col:Lerp(C.white, 0.5), M.Fabric)
		end
		-- ponton
		local dp = lake.c + V(lake.r - 10, 0, -40)
		for k = 0, 9 do
			Lib.part(m, CFrame.new(dp.X - k * 4, 0.6, dp.Z), V(4.2, 0.6, 7), rgb(170, 125, 80), M.WoodPlanks)
			if k % 3 == 0 then
				for _, s in { -1, 1 } do
					Lib.part(m, CFrame.new(dp.X - k * 4, -3, dp.Z + s * 3.2), V(0.8, 8, 0.8), rgb(120, 85, 55), M.Wood)
				end
			end
		end
		-- kiosque
		Build.shopBlock(m, Lib.facing(V(-520, groundY(-520, 1100), 1100), V(-1, 0, 0)), 16, 12, 0, rgb(120, 210, 230), C.white, { "GLACES DU LAC", rgb(240, 90, 140), C.white }, "Kiosk")
		lighthouse(m, lake.c + V(lake.r + 30, 0, 140))
	end

	---------------------------------------------------------------- Éoliennes
	for k = 0, 4 do
		windTurbine(root, V(1300 + (k % 2) * 60, 0, 220 + k * 70))
	end

	---------------------------------------------------------------- Panneaux
	local function bill(cf, text, bg)
		local mm = Lib.model(signs, "WelcomeSign")
		for _, x in { -10, 10 } do
			Lib.part(mm, cf * CFrame.new(x, 5, 0.6), V(1.2, 10, 1.2), rgb(120, 80, 50), M.Wood)
		end
		local b = Lib.part(mm, cf * CFrame.new(0, 14, 0), V(32, 10, 1.2), rgb(40, 34, 30), M.Wood, { CanCollide = false })
		local s = Lib.fine(mm, cf * CFrame.new(0, 14, -0.65), V(30, 8.6, 0.1), bg, M.SmoothPlastic)
		Lib.label(s, Enum.NormalId.Front, text, C.white, nil, Enum.Font.FredokaOne, true)
	end
	bill(Lib.facing(V(1150, 0, -40), V(1, 0, 0)), "WRONG WAY DELIVERY\nBienvenue en ville !", rgb(30, 32, 40))
	bill(Lib.facing(V(40, 0, 1000), V(0, 0, 1)), "WRONG WAY DELIVERY\nBienvenue en ville !", rgb(30, 32, 40))
	bill(Lib.facing(V(-40, 0, -1150), V(0, 0, -1)), "WRONG WAY DELIVERY\nBienvenue en ville !", rgb(30, 32, 40))
	bill(Lib.facing(V(-1100, 0, -40), V(-1, 0, 0)), "WRONG WAY DELIVERY\nBienvenue en ville !", rgb(30, 32, 40))
	local dirs = {
		{ V(870, 0.8, -60), V(-1, 0, 0), "CENTRE-VILLE ←   FERME →" },
		{ V(-870, 0.8, 60), V(1, 0, 0), "QG WWD →   FORÊT ←" },
		{ V(60, 0.8, 690), V(0, 0, -1), "LAC ET PHARE ↓   ZONE COMMERCIALE ↑" },
		{ V(-60, 0.8, -690), V(0, 0, 1), "TUNNEL DU COL ↑   CENTRE-VILLE ↓" },
		{ V(-1020, 0, -60), V(1, 0, 0), "VILLE →" },
		{ V(1130, 0, 60), V(-1, 0, 0), "← VILLE   MOTEL ↓" },
	}
	for _, d in dirs do
		Lib.postSign(signs, Lib.facing(d[1], d[2]), d[3], rgb(30, 110, 70), C.white, 22, 3, 8)
	end
	return "périphérie construite"
end
