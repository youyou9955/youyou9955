--!nolint
-- 02 : réseau routier (grille, rond-point, carrefours, trottoirs, feux, STOP, ponts, routes périphériques, panneaux).
local Lib = require(script.Parent.Lib)
local M = Enum.Material
local C = Lib.C
local L = Lib.L
local V = Vector3.new
local UP = V(0, 1, 0)
local R0 = Lib.ROAD

local function isMain(v)
	return v == 0 or math.abs(v) == 480
end

local function styleFor(w)
	if w >= 44 then
		return { center = "double", laneLines = 1, edges = true }
	elseif w >= 30 then
		return { center = "double", edges = true }
	else
		return { center = "dashed" }
	end
end

return function()
	local main = Lib.path("Roads", "MainRoads")
	local sec = Lib.path("Roads", "SecondaryRoads")
	local inter = Lib.path("Roads", "Intersections")
	local walks = Lib.path("Roads", "Sidewalks")
	local marks = Lib.path("Roads", "RoadMarkings")
	local bridges = Lib.path("Roads", "Bridges")
	local signs = Lib.path("Roads", "Signs")
	local furn = Lib.path("StreetFurniture")
	local lights = Lib.path("LightingObjects")
	local lightCount = 0

	-- Arms of each node: arms[key] = { {dir=Vector3, w=width} }
	local arms = {}
	local function key(x, z)
		return x .. "," .. z
	end
	local function addArm(x, z, dir, w)
		local k = key(x, z)
		arms[k] = arms[k] or {}
		table.insert(arms[k], { dir = dir, w = w })
	end
	local function nodeExtent(x, z)
		if x == 0 and z == 0 then
			return 60, 60
		end
		return Lib.intersectionSize(x, z)
	end

	-- Segment de route entre deux nœuds de grille (ou vers l'extérieur)
	local function segment(a, b, w, folder, startTrim, endTrim)
		local dir = (b - a).Unit
		local pa = a + dir * startTrim
		local pb = b - dir * endTrim
		local _, cf, len = Lib.road(folder, pa, pb, w, styleFor(w))
		-- flèches de voie près des extrémités
		if len > 60 then
			local right = dir:Cross(UP)
			Lib.arrow(marks, CFrame.lookAt(pb - dir * 22 + right * (w / 4), pb - dir * 22 + right * (w / 4) - dir) * CFrame.Angles(0, math.pi, 0))
			Lib.arrow(marks, CFrame.lookAt(pa + dir * 22 - right * (w / 4), pa + dir * 22 - right * (w / 4) + dir) * CFrame.Angles(0, math.pi, 0))
		end
		return cf, len
	end

	---------------------------------------------------------------- Grille
	for _, x in L do
		for k = 1, #L - 1 do
			local za, zb = L[k], L[k + 1]
			local w = Lib.roadWidth(x, (za + zb) / 2, true)
			local _, ea = nodeExtent(x, za)
			local _, eb = nodeExtent(x, zb)
			if x == 0 and za == 0 then
				ea = 60
			end
			segment(V(x, R0, za), V(x, R0, zb), w, isMain(x) and main or sec, ea / 2, eb / 2)
			addArm(x, za, V(0, 0, 1), w)
			addArm(x, zb, V(0, 0, -1), w)
		end
	end
	for _, z in L do
		for k = 1, #L - 1 do
			local xa, xb = L[k], L[k + 1]
			local w = Lib.roadWidth(z, (xa + xb) / 2, false)
			local ea = nodeExtent(xa, z)
			local eb = nodeExtent(xb, z)
			segment(V(xa, R0, z), V(xb, R0, z), w, isMain(z) and main or sec, ea / 2, eb / 2)
			addArm(xa, z, V(1, 0, 0), w)
			addArm(xb, z, V(-1, 0, 0), w)
		end
	end

	---------------------------------------------------------------- Routes vers l'extérieur
	local OUT = { -- {nœud x, nœud z, direction, longueur jusqu'à l'axe de la périphérique, largeur}
		{ 0, 480, V(0, 0, 1), 520, 30 },
		{ -320, 480, V(0, 0, 1), 520, 24 },
		{ 320, 480, V(0, 0, 1), 520, 24 },
		{ -480, 0, V(-1, 0, 0), 420, 30 },
		{ -480, 320, V(-1, 0, 0), 420, 24 },
		{ -480, -320, V(-1, 0, 0), 420, 24 },
		{ 480, 320, V(1, 0, 0), 420, 24 },
		{ 480, -320, V(1, 0, 0), 420, 24 },
		{ -320, -480, V(0, 0, -1), 570, 24 },
		{ 320, -480, V(0, 0, -1), 570, 24 },
		{ 0, -480, V(0, 0, -1), 265, 30 }, -- vers la colline (spirale construite dans Hillside)
	}
	for _, o in OUT do
		local x, z, dir, len, w = o[1], o[2], o[3], o[4], o[5]
		local ex, ez = nodeExtent(x, z)
		local trim = (dir.X ~= 0) and ex / 2 or ez / 2
		local a = V(x, R0, z)
		local endTrim = (len == 265) and 0 or 12
		segment(a, a + dir * len, w, sec, trim, endTrim)
		addArm(x, z, dir, w)
	end

	-- Grand pont haubané (z = 0, vers l'est)
	do
		local w = 30
		local function piece(a, b)
			Lib.road(main, a, b, w, styleFor(w))
		end
		local nx = nodeExtent(480, 0)
		piece(V(480 + nx / 2, R0, 0), V(505, R0, 0))
		piece(V(505, R0, 0), V(555, 10.2, 0))
		piece(V(555, 10.2, 0), V(665, 10.2, 0))
		piece(V(665, 10.2, 0), V(715, R0, 0))
		piece(V(715, R0, 0), V(888, R0, 0))
		addArm(480, 0, V(1, 0, 0), w)
		local br = Lib.model(bridges, "PontDuGrandDetour")
		-- remblais sous les rampes (WedgePart : arête haute côté +Z local)
		Lib.part(br, CFrame.lookAt(V(530, 4.2, 0), V(530, 4.2, 0) - V(1, 0, 0)), V(w, 10, 50), C.concrete, M.Concrete, { Class = "WedgePart", Name = "Ramp" })
		Lib.part(br, CFrame.lookAt(V(690, 4.2, 0), V(690, 4.2, 0) + V(1, 0, 0)), V(w, 10, 50), C.concrete, M.Concrete, { Class = "WedgePart", Name = "Ramp" })
		-- caisson sous le tablier, piles
		Lib.part(br, CFrame.new(610, 7.6, 0), V(110, 3.2, w - 4), C.concrete, M.Concrete, { Name = "Girder" })
		for _, x in { 585, 635 } do
			Lib.part(br, CFrame.new(x, -4, 0), V(8, 20, w - 6), C.concrete, M.Concrete, { Name = "Pier" })
		end
		-- pylônes et haubans
		local white = Color3.fromRGB(235, 235, 240)
		for _, x in { 585, 635 } do
			for _, s in { -1, 1 } do
				local zp = s * (w / 2 + 2)
				Lib.part(br, CFrame.new(x, 35, zp), V(3.5, 94.4, 3.5), white, M.Concrete, { Name = "Pylon" })
				Lib.deco(br, CFrame.new(x, 10.2 + 72.6, zp), V(4.2, 1.2, 4.2), C.brandOrange, M.Neon, { Name = "PylonCap" })
				for _, d in { -45, -30, -15, 15, 30, 45 } do
					Lib.beam(br, V(x, 10.2 + 68 - math.abs(d) * 0.25, zp), V(x + d, 11.2, zp), 0.35, 0.35, white, M.Metal, { CanCollide = false, CanTouch = false, CanQuery = false, Name = "Cable" })
				end
			end
			Lib.deco(br, CFrame.new(x, 10.2 + 58, 0), V(2.5, 3, w + 4), white, M.Concrete, { Name = "PylonBeam" })
		end
		Lib.sign(br, CFrame.new(610, 10.2 + 58, -w / 2 - 2.2) * CFrame.Angles(0, math.pi, 0), V(46, 5, 0.4), "PONT DU GRAND DÉTOUR", C.brandBlue, Color3.new(1, 1, 1), { glow = true, double = true })
		-- garde-corps
		for _, s in { -1, 1 } do
			Lib.part(br, CFrame.new(610, 11.7, s * (w / 2 + 0.4)), V(110, 3, 0.8), white, M.Metal, { Name = "Rail" })
			for _, seg in { { 505, 555 }, { 665, 715 } } do
				local y1 = seg[1] < 600 and R0 or 10.2
				local y2 = seg[1] < 600 and 10.2 or R0
				Lib.beam(br, V(seg[1], y1 + 1.5, s * (w / 2 + 0.4)), V(seg[2], y2 + 1.5, s * (w / 2 + 0.4)), 0.8, 3, white, M.Metal, { Name = "Rail" })
			end
		end
	end

	-- Ponts bas (z = ±320) : garde-corps et piles
	for _, z in { 320, -320 } do
		local br = Lib.model(bridges, "PontBas_" .. z)
		for _, s in { -1, 1 } do
			Lib.part(br, CFrame.new(610, R0 + 1.5, z + s * 12.4), V(140, 3, 0.8), Color3.fromRGB(80, 90, 110), M.Metal, { Name = "Rail" })
		end
		for _, x in { 575, 610, 645 } do
			Lib.part(br, CFrame.new(x, -8, z), V(5, 16, 20), C.concrete, M.Concrete, { Name = "Pier" })
		end
		Lib.part(br, CFrame.new(610, -1.6, z), V(130, 2.2, 22), C.concrete, M.Concrete, { Name = "Girder" })
	end

	---------------------------------------------------------------- Périphérique extérieur
	do
		local w = 24
		Lib.road(main, V(-912, R0, 1000), V(912, R0, 1000), w, styleFor(w))
		Lib.road(main, V(-912, R0, -1050), V(912, R0, -1050), w, styleFor(w))
		Lib.road(main, V(900, R0, -1038), V(900, R0, 988), w, styleFor(w))
		Lib.road(main, V(-900, R0, -1038), V(-900, R0, 988), w, styleFor(w))
		for _, x in { -900, 900 } do
			for _, z in { 1000, -1050 } do
				Lib.disc(inter, V(x, 0, z), 12, R0 + 0.01, 1, C.asphalt, M.Asphalt) -- coins arrondis
			end
		end
	end

	---------------------------------------------------------------- Carrefours
	local function corner(x, z, s, r, ex, ez)
		local ext_s = (math.abs(s.X) > 0) and ex or ez
		local ext_r = (math.abs(r.X) > 0) and ex or ez
		return V(x, R0, z) + s * (ext_s / 2 + 2.5) + r * (ext_r / 2 + 2.5)
	end
	local function trafficLight(pos, face, armDir, armLen)
		local m = Lib.model(inter, "TrafficLight")
		Lib.part(m, CFrame.new(pos + V(0, 0.5 + 6, 0)), V(0.6, 12, 0.6), C.dark, M.Metal)
		local tip = pos + armDir * armLen + V(0, 12, 0)
		Lib.beam(m, pos + V(0, 12, 0), tip, 0.45, 0.45, C.dark, M.Metal, { CanCollide = false, CanTouch = false, CanQuery = false })
		local head = CFrame.lookAt(tip + V(0, -1.6, 0), tip + V(0, -1.6, 0) + face)
		Lib.deco(m, head, V(1.4, 4, 1.2), Color3.fromRGB(28, 28, 28), M.Metal)
		local cols = { Color3.fromRGB(120, 25, 20), Color3.fromRGB(120, 90, 15), Color3.fromRGB(60, 240, 100) }
		for k = 1, 3 do
			Lib.deco(m, head * CFrame.new(0, 1.25 - (k - 1) * 1.25, -0.65), V(0.9, 0.9, 0.15), cols[k], k == 3 and M.Neon or M.SmoothPlastic)
		end
		-- petit feu piéton sur le poteau
		Lib.deco(m, CFrame.lookAt(pos + V(0, 3.5, 0), pos + V(0, 3.5, 0) + face) * CFrame.new(0, 0, -0.5), V(0.9, 1.4, 0.5), Color3.fromRGB(28, 28, 28), M.Metal)
	end

	local nodeCount = 0
	for k, list in arms do
		local x, z = string.match(k, "(-?%d+),(-?%d+)")
		x, z = tonumber(x), tonumber(z)
		if x == 0 and z == 0 then
			continue
		end
		local ex, ez = nodeExtent(x, z)
		Lib.part(inter, CFrame.new(x, R0 - 0.5, z), V(ex, 1, ez), C.asphalt, M.Asphalt, { Name = "Intersection" })
		local major = isMain(x) or isMain(z)
		for _, arm in list do
			local s = arm.dir -- vers l'extérieur
			local h = -s -- sens des voitures qui arrivent
			local r = h:Cross(UP) -- droite du conducteur
			local ext_s = (math.abs(s.X) > 0) and ex or ez
			local base = V(x, R0, z) + s * (ext_s / 2 + 3.5)
			Lib.crosswalk(marks, CFrame.lookAt(base, base + s), arm.w)
			local sl = V(x, R0, z) + s * (ext_s / 2 + 7.5) + r * (arm.w / 4)
			Lib.mark(marks, CFrame.lookAt(sl, sl + s) * CFrame.new(0, 0.03, 0), V(arm.w / 2 - 1, 0.05, 0.8))
			local c = corner(x, z, s, r, ex, ez)
			if major then
				trafficLight(c, s, -r, math.min(arm.w / 2 + 1, 12))
			else
				Lib.stopSign(signs, CFrame.lookAt(c, c + s))
			end
		end
		nodeCount += 1
	end

	---------------------------------------------------------------- Rond-point central
	do
		local rp = Lib.model(inter, "RondPointDuColis")
		Lib.disc(rp, V(0, 0, 0), 30, R0, 1, C.asphalt, M.Asphalt, { Name = "Ring" })
		Lib.disc(rp, V(0, 0, 0), 12.5, R0 + 0.6, 1.6, C.curb, M.Concrete, { Name = "IslandCurb" })
		Lib.disc(rp, V(0, 0, 0), 11.5, R0 + 0.8, 1.6, C.grass, M.Grass, { Name = "Island" })
		-- monument : colis géant posé de travers
		local mon = Lib.model(Lib.path("Landmarks"), "MonumentColisGeant")
		Lib.part(mon, CFrame.new(0, 2.5, 0), V(8, 3, 8), C.concrete, M.Marble)
		Lib.part(mon, CFrame.new(0, 10, 0) * CFrame.Angles(math.rad(12), math.rad(30), math.rad(8)), V(10, 9, 10), Color3.fromRGB(196, 150, 96), M.Cardboard, { Name = "GiantParcel" })
		Lib.deco(mon, CFrame.new(0, 10, 0) * CFrame.Angles(math.rad(12), math.rad(30), math.rad(8)), V(10.1, 1.6, 10.1), Color3.fromRGB(230, 200, 140), M.Fabric, { Name = "Tape" })
		local tag = Lib.deco(mon, CFrame.new(0, 3, -4.05), V(7, 1.6, 0.1), C.brandOrange)
		Lib.label(tag, Enum.NormalId.Front, "ROND-POINT DU COLIS — on tourne dans quel sens ?", Color3.new(1, 1, 1))
		-- marquage : pointillés circulaires et cédez-le-passage
		for a = 0, 355, 10 do
			local p = V(math.cos(math.rad(a)) * 21, R0, math.sin(math.rad(a)) * 21)
			Lib.mark(marks, CFrame.lookAt(p, p + V(-math.sin(math.rad(a)), 0, math.cos(math.rad(a)))) * CFrame.new(0, 0.03, 0), V(0.45, 0.05, 2.2))
		end
		for _, s in { V(1, 0, 0), V(-1, 0, 0), V(0, 0, 1), V(0, 0, -1) } do
			local r = (-s):Cross(UP)
			for t = 0, 4 do
				local p = s * 31 + r * (2 + t * 4)
				Lib.mark(marks, CFrame.lookAt(p + V(0, R0, 0), p + V(0, R0, 0) + s) * CFrame.new(0, 0.03, 0), V(2, 0.05, 0.6))
			end
			local base = s * 34
			Lib.crosswalk(marks, CFrame.lookAt(base + V(0, R0, 0), base + V(0, R0, 0) + s), 44)
		end
	end

	---------------------------------------------------------------- Trottoirs
	for i = 1, 6 do
		for j = 1, 6 do
			local c = Lib.cell(i, j)
			local cellF = Lib.model(walks, ("Block_%d_%d"):format(i, j))
			Lib.slab(cellF, c.x1, c.x2, c.z1, c.z1 + 6, Lib.WALK, 1, C.walk, M.Concrete, { Name = "Sidewalk" })
			Lib.slab(cellF, c.x1, c.x2, c.z2 - 6, c.z2, Lib.WALK, 1, C.walk, M.Concrete, { Name = "Sidewalk" })
			Lib.slab(cellF, c.x1, c.x1 + 6, c.z1 + 6, c.z2 - 6, Lib.WALK, 1, C.walk, M.Concrete, { Name = "Sidewalk" })
			Lib.slab(cellF, c.x2 - 6, c.x2, c.z1 + 6, c.z2 - 6, Lib.WALK, 1, C.walk, M.Concrete, { Name = "Sidewalk" })
			-- bordures
			for _, b in { { c.x1, c.x2, c.z1, c.z1 + 0.6 }, { c.x1, c.x2, c.z2 - 0.6, c.z2 }, { c.x1, c.x1 + 0.6, c.z1, c.z2 }, { c.x2 - 0.6, c.x2, c.z1, c.z2 } } do
				Lib.slab(cellF, b[1], b[2], b[3], b[4], Lib.WALK + 0.02, 0.2, C.curb, M.Concrete, { Name = "Curb", CanCollide = false, CanQuery = false, CanTouch = false })
			end
			-- lampadaires tous les ~40 studs, tournés vers la rue
			local function line(p1, p2, face)
				local len = (p2 - p1).Magnitude
				local n = math.floor((len - 30) / 40)
				for t = 0, n do
					local p = p1 + (p2 - p1).Unit * (15 + t * (len - 30) / math.max(n, 1))
					local withLight = (lightCount < 170) and ((t + i + j) % 3 == 0)
					if withLight then
						lightCount += 1
					end
					Lib.lamp(lights, CFrame.lookAt(V(p.X, Lib.WALK, p.Z), V(p.X, Lib.WALK, p.Z) + face), withLight)
				end
			end
			line(V(c.x1, 0, c.z1 + 1.5), V(c.x2, 0, c.z1 + 1.5), V(0, 0, -1))
			line(V(c.x1, 0, c.z2 - 1.5), V(c.x2, 0, c.z2 - 1.5), V(0, 0, 1))
			line(V(c.x1 + 1.5, 0, c.z1), V(c.x1 + 1.5, 0, c.z2), V(-1, 0, 0))
			line(V(c.x2 - 1.5, 0, c.z1), V(c.x2 - 1.5, 0, c.z2), V(1, 0, 0))
		end
	end

	---------------------------------------------------------------- Panneaux
	local blue, green, white, red = Color3.fromRGB(30, 80, 170), Color3.fromRGB(20, 110, 60), Color3.new(1, 1, 1), Color3.fromRGB(200, 30, 30)
	local function sign(pos, face, text, bg, fg, w, h)
		Lib.postSign(signs, CFrame.lookAt(pos, pos + face), text, bg or blue, fg or white, w, h, 8)
	end
	-- Directions
	sign(V(-30, Lib.WALK, -40), V(0, 0, -1), "↑ CENTRE-VILLE   → QG WRONG WAY", blue, white, 14, 4)
	sign(V(30, Lib.WALK, 40), V(0, 0, 1), "↑ ZONE INDUSTRIELLE   ← RÉSIDENTIEL", blue, white, 14, 4)
	sign(V(40, Lib.WALK, -30), V(1, 0, 0), "↑ PONT DU GRAND DÉTOUR   → COMMERCES", blue, white, 14, 4)
	sign(V(-40, Lib.WALK, 30), V(-1, 0, 0), "↑ PÉRIPHÉRIQUE   ← COLLINES", blue, white, 14, 4)
	sign(V(-10, Lib.WALK, -500), V(0, 0, 1), "COLLINES ↓  (ça monte)", green, white, 10, 3)
	sign(V(334, Lib.WALK, -510), V(0, 0, 1), "TUNNEL DU DEMI-TOUR ↓", green, white, 10, 3)
	sign(V(497, Lib.WALK, -16), V(-1, 0, 0), "PLAGE → par le pont", green, white, 10, 3)
	-- Limitations et humour
	local speeds = { { -20, -200, "50" }, { 20, 200, "30" }, { -200, 26, "50" }, { 200, -26, "70" }, { -240, 330, "20" } }
	for _, s in speeds do
		local m = Lib.model(signs, "SpeedLimit")
		local p = V(s[1], Lib.WALK, s[2])
		Lib.part(m, CFrame.new(p + V(0, 3.5, 0)), V(0.3, 7, 0.3), C.metal, M.Metal)
		Lib.deco(m, CFrame.new(p + V(0, 7.6, 0)) * CFrame.Angles(0, math.rad(90), 0), V(0.15, 2.8, 2.8), white, M.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
		local face = Lib.deco(m, CFrame.new(p + V(0, 7.6, -0.1)), V(2.2, 2.2, 0.05), white)
		Lib.label(face, Enum.NormalId.Front, s[3], Color3.new(0, 0, 0), nil, Enum.Font.GothamBlack)
		Lib.deco(m, CFrame.new(p + V(0, 7.6, 0)) * CFrame.Angles(0, math.rad(90), 0), V(0.1, 3, 3), red, M.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
	end
	local funny = {
		{ V(-170, Lib.WALK, -30), V(0, 0, -1), "SENS INTERDIT\n(sauf livreurs pressés)", red },
		{ V(170, Lib.WALK, 30), V(0, 0, 1), "ATTENTION : cartons volants", Color3.fromRGB(240, 190, 30) },
		{ V(30, Lib.WALK, 330), V(0, 0, 1), "VOUS ÊTES ICI\n(probablement)", blue },
		{ V(-30, Lib.WALK, -330), V(0, 0, -1), "DEMI-TOUR AUTORISÉ\nPARTOUT. VRAIMENT.", green },
		{ V(330, Lib.WALK, -170), V(1, 0, 0), "FIN DE LA LIMITATION\nDE LA LIMITATION", blue },
		{ V(-330, Lib.WALK, 170), V(-1, 0, 0), "RALENTIR : ÉCOLE\nDE CONDUITE À CONTRESENS", Color3.fromRGB(240, 190, 30) },
	}
	for _, f in funny do
		Lib.postSign(signs, CFrame.lookAt(f[1], f[1] + f[2]), f[3], f[4], f[4] == Color3.fromRGB(240, 190, 30) and Color3.new(0, 0, 0) or white, 9, 4, 7)
	end
	return ("routes ok : %d carrefours, %d lumières"):format(nodeCount, lightCount)
end
