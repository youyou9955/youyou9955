--!nolint
-- 02 : réseau routier complet. Routes droites découpées aux carrefours, arcs du périphérique,
-- ronds-points, passages piétons, lignes de stop, feux, STOP, plaques de rue, trottoirs avec
-- bordures, lampadaires et mobilier. Routes de campagne (hors périphérique) sans trottoir.
local Plan = require(script.Parent.Plan)
local Lib = require(script.Parent.Lib)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C
local Y, WALK = Lib.ROAD, Lib.WALK

local R = Lib.path("Roads")
local F = {
	asphalt = R.Asphalt,
	marks = R.Markings,
	walk = R.Sidewalks,
	inter = R.Intersections,
	rb = R.Roundabouts,
	sig = R.Signals,
	signs = R.Signs,
}
local furniture = Lib.path("StreetFurniture")
local rng = Random.new(7)

local function district(x, z)
	for name, r in Plan.districts do
		if name ~= "CommercialDistrict" and x >= r[1] and x <= r[3] and z >= r[2] and z <= r[4] then
			return name
		end
	end
	local r = Plan.districts.CommercialDistrict
	if x >= r[1] and x <= r[3] and z >= r[2] and z <= r[4] then
		return "CommercialDistrict"
	end
	return "Outskirts"
end

---------------------------------------------------------------- Pièces de base
local function asphalt(parent, cf, w, len)
	return Lib.part(parent, cf * CFrame.new(0, Y - 0.7, 0), V(w, 1.4, len), C.asphalt, M.Asphalt, { Name = "Road" })
end

local function line(cf, x, z, len, color, w)
	return Lib.mark(F.marks, cf * CFrame.new(x, Y + 0.025, z), V(w or 0.5, 0.05, len), color)
end

local function dashed(cf, x, z0, z1, color)
	local len = z1 - z0
	local n = math.floor((len + 10) / 18)
	for k = 0, n - 1 do
		local zc = z0 + 4 + k * 18
		if zc + 4 <= z1 then
			line(cf, x, zc, 8, color, 0.45)
		end
	end
end

local function sidewalk(cf, x, len, sw, side)
	-- x : bord côté route ; side : +1 vers +X local, -1 vers -X
	local p = Lib.part(F.walk, cf * CFrame.new(x + side * sw / 2, WALK - 0.7, 0), V(sw, 1.4, len), C.walk, M.Pavement, { Name = "Sidewalk" })
	Lib.part(F.walk, cf * CFrame.new(x + side * 0.4, WALK - 0.68, 0), V(0.8, 1.44, len), C.curb, M.Concrete, { Name = "Curb" })
	return p
end

-- Marquages d'une route droite (cf au centre, axe Z local). z0..z1 = zone marquée (local).
local function markings(cf, w, kind, z0, z1, rural)
	local len = z1 - z0
	if len < 4 then
		return
	end
	local zc = (z0 + z1) / 2
	if kind == "main" or kind == "ring" or kind == "ind" then
		line(cf, -0.45, zc, len, C.yellow)
		line(cf, 0.45, zc, len, C.yellow)
		if kind ~= "ind" then
			local lane = w / 4
			dashed(cf, lane, z0, z1, C.white)
			dashed(cf, -lane, z0, z1, C.white)
		end
		line(cf, w / 2 - 1.4, zc, len, C.white, 0.4)
		line(cf, -w / 2 + 1.4, zc, len, C.white, 0.4)
	elseif kind == "sec" then
		line(cf, 0, zc, len, C.yellow, 0.55)
		if rural then
			line(cf, w / 2 - 1.2, zc, len, C.white, 0.4)
			line(cf, -w / 2 + 1.2, zc, len, C.white, 0.4)
		end
	else
		dashed(cf, 0, z0, z1, C.yellow)
	end
end

local function arrow(cf)
	Lib.mark(F.marks, cf * CFrame.new(0, Y + 0.025, 1.5), V(0.8, 0.05, 5), C.white)
	Lib.mark(F.marks, cf * CFrame.new(-0.9, Y + 0.025, -1.6) * CFrame.Angles(0, math.rad(-35), 0), V(0.7, 0.05, 2.6), C.white)
	Lib.mark(F.marks, cf * CFrame.new(0.9, Y + 0.025, -1.6) * CFrame.Angles(0, math.rad(35), 0), V(0.7, 0.05, 2.6), C.white)
end

---------------------------------------------------------------- Signalisation
local function trafficLight(cf, reach, green)
	-- cf : pied du poteau sur le trottoir, LookVector = vers les voitures qui arrivent ; le bras part vers +X local
	local m = Lib.model(F.sig, "TrafficLight")
	local c = rgb(40, 44, 54)
	Lib.part(m, cf * CFrame.new(0, 7, 0), V(0.7, 14, 0.7), c, M.Metal)
	Lib.fine(m, cf * CFrame.new(reach / 2, 13.4, 0), V(reach, 0.5, 0.5), c, M.Metal)
	for _, x in { reach - 0.5, reach * 0.45 } do
		local head = cf * CFrame.new(x, 12, 0)
		Lib.fine(m, head, V(1.5, 4.2, 1.3), rgb(255, 200, 40), M.SmoothPlastic)
		local cols = { rgb(255, 50, 40), rgb(255, 180, 30), rgb(60, 230, 90) }
		for k = 1, 3 do
			local lit = (green and k == 3) or (not green and k == 1)
			local col = lit and cols[k] or cols[k]:Lerp(Color3.new(0, 0, 0), 0.65)
			Lib.fine(m, head * CFrame.new(0, 1.3 - (k - 1) * 1.3, -0.7), V(0.95, 0.95, 0.15), col, lit and M.Neon or M.SmoothPlastic)
		end
	end
	-- feu piéton sur le poteau
	Lib.fine(m, cf * CFrame.new(0, 8.5, -0.6), V(1, 1.4, 0.5), c, M.SmoothPlastic)
	Lib.fine(m, cf * CFrame.new(0, 8.5, -0.86), V(0.7, 1, 0.05), green and rgb(80, 240, 120) or rgb(255, 120, 60), M.Neon)
	return m
end

local function stopSign(cf)
	local m = Lib.model(F.signs, "StopSign")
	Lib.part(m, cf * CFrame.new(0, 3.6, 0), V(0.35, 7.2, 0.35), C.metal, M.Metal)
	local s = Lib.deco(m, cf * CFrame.new(0, 7.3, -0.25) * CFrame.Angles(0, 0, math.rad(22.5)), V(2.6, 2.6, 0.15), C.white, M.SmoothPlastic)
	local s2 = Lib.deco(m, cf * CFrame.new(0, 7.3, -0.34), V(2.3, 2.3, 0.05), rgb(210, 30, 30), M.SmoothPlastic)
	Lib.deco(m, cf * CFrame.new(0, 7.3, -0.34) * CFrame.Angles(0, 0, math.rad(45)), V(2.3, 2.3, 0.04), rgb(210, 30, 30), M.SmoothPlastic)
	local lab = Lib.deco(m, cf * CFrame.new(0, 7.3, -0.38), V(2.2, 0.9, 0.02), rgb(210, 30, 30), M.SmoothPlastic)
	Lib.label(lab, Enum.NormalId.Front, "STOP", C.white, nil, Enum.Font.GothamBlack)
	return m
end

local function streetSign(cf, a, b)
	local m = Lib.model(F.signs, "StreetNameSign")
	Lib.part(m, cf * CFrame.new(0, 5, 0), V(0.3, 10, 0.3), C.metal, M.Metal)
	local function plate(rot, text)
		local p = Lib.deco(m, cf * CFrame.Angles(0, rot, 0) * CFrame.new(0, 9.4 + (rot == 0 and 0 or 0.9), -2.2), V(0.12, 0.8, 4.2), rgb(30, 110, 70), M.SmoothPlastic)
		Lib.label(p, Enum.NormalId.Right, text, C.white, nil, Enum.Font.GothamBold)
		Lib.label(p, Enum.NormalId.Left, text, C.white, nil, Enum.Font.GothamBold)
	end
	local function pretty(s)
		return (s:gsub("(%l)(%u)", "%1 %2"):gsub("(%a)(%d)", "%1 %2"))
	end
	plate(0, pretty(a))
	plate(math.pi / 2, pretty(b))
	return m
end

---------------------------------------------------------------- Mobilier le long d'un tronçon
local function furnish(cf, w, sw, len, kind, mid)
	local d = district(mid.X, mid.Z)
	local busy = d == "Downtown" or d == "CommercialDistrict" or d == "DeliveryHeadquarters"
	local step = 64
	local n = math.floor((len - 24) / step)
	for k = 0, n do
		local z = -len / 2 + 12 + k * step + (len - 24 - n * step) / 2
		local side = (k % 2 == 0) and 1 or -1
		local x = side * (w / 2 + 1.6)
		local pos = (cf * CFrame.new(x, WALK, z)).Position
		Lib.lamp(furniture, CFrame.lookAt(pos, (cf * CFrame.new(0, WALK, z)).Position))
		if busy and k % 2 == 1 then
			local p2 = (cf * CFrame.new(-side * (w / 2 + 1.8), WALK, z)).Position
			Lib.trash(furniture, CFrame.lookAt(p2, (cf * CFrame.new(0, WALK, z)).Position))
		end
		if k % 3 == 2 then
			local p3 = (cf * CFrame.new(side * (w / 2 + 2), WALK, z + 10)).Position
			Lib.hydrant(furniture, CFrame.lookAt(p3, (cf * CFrame.new(0, WALK, z + 10)).Position))
		end
		if busy and sw >= 10 and k % 4 == 1 then
			local p4 = (cf * CFrame.new(-side * (w / 2 + sw - 2.2), WALK, z - 14)).Position
			Lib.bench(furniture, CFrame.lookAt(p4, (cf * CFrame.new(0, WALK, z - 14)).Position))
		end
	end
	-- abribus sur les axes principaux
	if (kind == "main" or kind == "ring") and len > 140 then
		local p5 = (cf * CFrame.new(w / 2 + sw - 3, WALK, 0)).Position
		Lib.busStop(furniture, CFrame.lookAt(p5, (cf * CFrame.new(0, WALK, 0)).Position))
	end
end

local function reflectors(cf, w, len)
	local n = math.floor(len / 40)
	for k = 0, n do
		local z = -len / 2 + 6 + k * (len - 12) / math.max(n, 1)
		for _, s in { -1, 1 } do
			local m = Lib.model(furniture, "Reflector")
			Lib.part(m, cf * CFrame.new(s * (w / 2 + 2), 1.4, z), V(0.5, 2.8, 0.5), C.white, M.SmoothPlastic)
			Lib.fine(m, cf * CFrame.new(s * (w / 2 + 2), 2.4, z), V(0.55, 0.5, 0.55), C.brandOrange, M.Neon)
		end
	end
end

---------------------------------------------------------------- Carrefours
local nodes = {}
local function nodeKey(x, z)
	return math.floor(x + 0.5) .. ":" .. math.floor(z + 0.5)
end

local rbAt = {}
for _, rb in Plan.roundabouts do
	rbAt[nodeKey(rb.p.X, rb.p.Z)] = rb
end

for _, a in Plan.lines do
	if a.axis == "X" then
		for _, b in Plan.lines do
			if b.axis == "Z" and b.fixed >= a.a - 1 and b.fixed <= a.b + 1 and a.fixed >= b.a - 1 and a.fixed <= b.b + 1 then
				local x, z = b.fixed, a.fixed
				local key = nodeKey(x, z)
				local n = nodes[key]
				if not n then
					n = { x = x, z = z, wx = 0, wz = 0, kinds = {}, arms = {}, names = {}, armKind = {}, armW = {} }
					nodes[key] = n
				end
				n.wz = math.max(n.wz, a.w) -- largeur de la route qui suit X (dimension en z)
				n.wx = math.max(n.wx, b.w)
				n.swX = math.max(n.swX or 0, Plan.SW[a.kind])
				n.swZ = math.max(n.swZ or 0, Plan.SW[b.kind])
				n.kinds[a.kind], n.kinds[b.kind] = true, true
				n.names[a.name], n.names[b.name] = true, true
				local function arm(dir, cond, line)
					if cond then
						n.arms[dir] = true
						n.armKind[dir] = line.kind
						n.armW[dir] = line.w
					end
				end
				arm("E", a.b > x + 1, a)
				arm("W", a.a < x - 1, a)
				arm("S", b.b > z + 1, b)
				arm("N", b.a < z - 1, b)
				n.rb = rbAt[key]
			end
		end
	end
end

local DIRS = { E = V(1, 0, 0), W = V(-1, 0, 0), S = V(0, 0, 1), N = V(0, 0, -1) }

-- demi-taille d'un carrefour dans la direction d'un bras
local function halfAlong(n, dir)
	if n.rb then
		return n.rb.r - 3
	end
	return (dir == "E" or dir == "W") and n.wx / 2 or n.wz / 2
end

local function buildNode(n)
	local c = V(n.x, 0, n.z)
	if n.rb then
		return
	end
	local hx, hz = n.wx / 2, n.wz / 2
	local swX, swZ = n.swX, n.swZ
	local g = Lib.model(F.inter, "Intersection")
	Lib.part(g, CFrame.new(n.x, Y - 0.7, n.z), V(n.wx, 1.4, n.wz), C.asphalt, M.Asphalt, { Name = "Road" })
	-- coins de trottoir et trottoirs qui traversent les bras absents
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Lib.part(F.walk, CFrame.new(n.x + sx * (hx + swZ / 2), WALK - 0.7, n.z + sz * (hz + swX / 2)), V(swZ, 1.4, swX), C.walk, M.Pavement, { Name = "Sidewalk" })
		end
	end
	if not n.arms.E then
		Lib.part(F.walk, CFrame.new(n.x + hx + swZ / 2, WALK - 0.7, n.z), V(swZ, 1.4, n.wz), C.walk, M.Pavement, { Name = "Sidewalk" })
		Lib.part(F.walk, CFrame.new(n.x + hx + 0.4, WALK - 0.68, n.z), V(0.8, 1.44, n.wz), C.curb, M.Concrete, { Name = "Curb" })
	end
	if not n.arms.W then
		Lib.part(F.walk, CFrame.new(n.x - hx - swZ / 2, WALK - 0.7, n.z), V(swZ, 1.4, n.wz), C.walk, M.Pavement, { Name = "Sidewalk" })
		Lib.part(F.walk, CFrame.new(n.x - hx - 0.4, WALK - 0.68, n.z), V(0.8, 1.44, n.wz), C.curb, M.Concrete, { Name = "Curb" })
	end
	if not n.arms.S then
		Lib.part(F.walk, CFrame.new(n.x, WALK - 0.7, n.z + hz + swX / 2), V(n.wx, 1.4, swX), C.walk, M.Pavement, { Name = "Sidewalk" })
		Lib.part(F.walk, CFrame.new(n.x, WALK - 0.68, n.z + hz + 0.4), V(n.wx, 1.44, 0.8), C.curb, M.Concrete, { Name = "Curb" })
	end
	if not n.arms.N then
		Lib.part(F.walk, CFrame.new(n.x, WALK - 0.7, n.z - hz - swX / 2), V(n.wx, 1.4, swX), C.walk, M.Pavement, { Name = "Sidewalk" })
		Lib.part(F.walk, CFrame.new(n.x, WALK - 0.68, n.z - hz - 0.4), V(n.wx, 1.44, 0.8), C.curb, M.Concrete, { Name = "Curb" })
	end
	-- signalisation
	local allRes = true
	local anyRes = false
	for k in n.kinds do
		if k ~= "res" then
			allRes = false
		else
			anyRes = true
		end
	end
	local useLights = not anyRes
	for dirName, present in n.arms do
		local dir = DIRS[dirName]
		local w = n.armW[dirName]
		local half = halfAlong(n, dirName)
		local right = V(dir.Z, 0, -dir.X) -- côté des voitures qui arrivent
		local acf = CFrame.lookAt(c + dir * (half + 5), c + dir * (half + 6)) -- axe Z local = vers l'extérieur
		-- passage piéton (bandes parallèles à la circulation)
		local nb = math.floor((w - 3) / 3.2)
		for k = 0, nb - 1 do
			local x = -w / 2 + 2.4 + k * 3.2
			Lib.mark(F.marks, acf * CFrame.new(x, Y + 0.025, 0), V(1.7, 0.05, 6.5), C.white)
		end
		-- ligne d'arrêt sur la moitié des voitures qui arrivent
		local stopCf = CFrame.new(c + dir * (half + 9.6) + right * (w / 4))
		Lib.mark(F.marks, CFrame.lookAt(stopCf.Position, stopCf.Position + dir), V(w / 2 - 1, 0.05, 1), C.white)
		-- flèches sur les grands axes
		local kind = n.armKind[dirName]
		if kind == "main" or kind == "ring" then
			for _, off in { w / 8, w * 3 / 8 } do
				local p = c + dir * (half + 22) + right * off
				arrow(CFrame.lookAt(p, p - dir))
			end
		end
		-- feux ou STOP
		local corner = c + dir * (half + 3.5) + right * (w / 2 + 2.5)
		if useLights then
			-- feux posés par placeLights
		elseif kind == "res" or allRes then
			stopSign(CFrame.lookAt(corner, corner + dir))
		end
	end
	-- plaque de rue
	local names = {}
	for k in n.names do
		table.insert(names, k)
	end
	if #names >= 2 then
		local p = V(n.x + hx + swZ - 1.5, WALK, n.z + hz + swX - 1.5)
		streetSign(CFrame.lookAt(p, p + V(0, 0, -1)), names[1], names[2])
	end
end

-- feux : version définitive avec le bras au-dessus des voies
local function placeLights(n)
	if n.rb then
		return
	end
	for k in n.kinds do
		if k == "res" then
			return
		end
	end
	local c = V(n.x, 0, n.z)
	for dirName in n.arms do
		local dir = DIRS[dirName]
		local w = n.armW[dirName]
		local half = halfAlong(n, dirName)
		local right = V(dir.Z, 0, -dir.X)
		local corner = c + dir * (half + 3.5) + right * (w / 2 + 2.5)
		-- repère : LookVector = dir (face aux voitures qui arrivent), +X local = -right (vers la route)
		local f = CFrame.fromMatrix(corner, -right, V(0, 1, 0))
		trafficLight(f, w / 2 - 2, dirName == "N" or dirName == "S")
	end
end

---------------------------------------------------------------- Ronds-points
local function buildRoundabout(rb, n)
	local p = rb.p
	local r = rb.r
	local g = Lib.model(F.rb, rb.name)
	Lib.cyl(g, CFrame.new(p + V(0, Y - 0.69, 0)), 1.4, r * 2, C.asphalt, M.Asphalt, { Name = "Road" })
	local ri = r - 20
	Lib.cyl(g, CFrame.new(p + V(0, 0.5, 0)), 1.0, ri * 2, C.curb, M.Concrete, { Name = "Island" })
	Lib.cyl(g, CFrame.new(p + V(0, 0.55, 0)), 1.0, ri * 2 - 1.6, C.grass, M.Grass, { Name = "IslandGrass" })
	-- marquages : bord intérieur plein, séparation des voies en pointillés
	local function ring(rad, dash, gap, w)
		local circ = 2 * math.pi * rad
		local n2 = math.floor(circ / (dash + gap))
		for k = 0, n2 - 1 do
			local a = k / n2 * math.pi * 2
			local q = p + V(math.cos(a) * rad, 0, math.sin(a) * rad)
			Lib.mark(F.marks, CFrame.lookAt(q + V(0, Y + 0.035, 0), q + V(0, Y + 0.035, 0) + V(-math.sin(a), 0, math.cos(a))), V(w, 0.05, dash), C.white)
		end
	end
	ring(ri + 1.5, 5.5, 0.6, 0.45)
	ring(ri + 10, 6, 7, 0.45)
	-- trottoir circulaire, interrompu par les bras
	local sw = 12
	local arms = {}
	for dirName in n.arms do
		local d = DIRS[dirName]
		table.insert(arms, { a = math.atan2(d.Z, d.X), half = math.asin(math.min(1, (n.armW[dirName] / 2 + 0.5) / (r + sw / 2))) })
	end
	local steps = math.floor(2 * math.pi * (r + sw / 2) / 7)
	for k = 0, steps - 1 do
		local a = (k + 0.5) / steps * math.pi * 2
		local blocked = false
		for _, arm in arms do
			local da = math.abs(((a - arm.a + math.pi) % (2 * math.pi)) - math.pi)
			if da < arm.half then
				blocked = true
			end
		end
		if not blocked then
			local rr = r + sw / 2
			local q = p + V(math.cos(a) * rr, 0, math.sin(a) * rr)
			local t = V(-math.sin(a), 0, math.cos(a))
			local len = 2 * math.pi * rr / steps + 0.4
			local cf = CFrame.lookAt(q, q + t)
			Lib.part(F.walk, cf * CFrame.new(0, WALK - 0.7, 0), V(sw, 1.4, len), C.walk, M.Pavement, { Name = "Sidewalk" })
			Lib.part(F.walk, cf * CFrame.new(-sw / 2 + 0.4, WALK - 0.68, 0), V(0.8, 1.44, len * (r / rr) + 0.3), C.curb, M.Concrete, { Name = "Curb" })
			if k % 6 == 0 then
				local lp = p + V(math.cos(a) * (r + 1.6), WALK, math.sin(a) * (r + 1.6))
				Lib.lamp(furniture, CFrame.lookAt(lp, p + V(0, WALK, 0)))
			end
		end
	end
	-- cédez-le-passage sur chaque bras
	for dirName in n.arms do
		local dir = DIRS[dirName]
		local w = n.armW[dirName]
		local right = V(dir.Z, 0, -dir.X)
		for k = 0, math.floor(w / 2 / 2.2) - 1 do
			local q = p + dir * (r + 1.5) + right * (1.5 + k * 2.2)
			Lib.mark(F.marks, CFrame.lookAt(q + V(0, Y + 0.03, 0), q + V(0, Y + 0.03, 0) + dir), V(1.1, 0.05, 1.1) , C.white)
		end
	end
	-- décor central
	local top = 1.05
	if rb.fountain then
		local cm = Lib.model(Lib.path("Landmarks"), "FontaineCentrale")
		local stone = rgb(236, 232, 222)
		local water = rgb(70, 180, 230)
		Lib.cyl(cm, CFrame.new(p + V(0, top + 1.3, 0)), 2.6, ri * 1.3, stone, M.SmoothPlastic, { Name = "Basin" })
		Lib.cylDeco(cm, CFrame.new(p + V(0, top + 2.4, 0)), 0.4, ri * 1.3 - 2.4, water, M.Glass, { Transparency = 0.25 })
		Lib.cyl(cm, CFrame.new(p + V(0, top + 6, 0)), 8, 4, stone, M.SmoothPlastic)
		Lib.cylDeco(cm, CFrame.new(p + V(0, top + 10.2, 0)), 1.2, 14, stone, M.SmoothPlastic)
		Lib.cylDeco(cm, CFrame.new(p + V(0, top + 10.9, 0)), 0.3, 12.4, water, M.Glass, { Transparency = 0.25 })
		Lib.cylDeco(cm, CFrame.new(p + V(0, top + 13.5, 0)), 4.4, 2, stone, M.SmoothPlastic)
		Lib.cylDeco(cm, CFrame.new(p + V(0, top + 16, 0)), 0.8, 6, stone, M.SmoothPlastic)
		local spout = Lib.ball(cm, p + V(0, top + 17.2, 0), 1.6, water, M.Glass, { Transparency = 0.2 })
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(rgb(210, 240, 255))
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.4) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		pe.Lifetime = NumberRange.new(1.2, 1.6)
		pe.Rate = 60
		pe.Speed = NumberRange.new(12, 16)
		pe.SpreadAngle = Vector2.new(18, 18)
		pe.Acceleration = V(0, -24, 0)
		pe.Parent = spout
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			Lib.flowers(cm, CFrame.new(p + V(math.cos(a) * (ri - 3.5), top - 0.4, math.sin(a) * (ri - 3.5))) * CFrame.Angles(0, -a, 0), 3, 6)
		end
	elseif rb.name == "RondPointSud" or rb.name == "RondPointNord" then
		local cm = Lib.model(Lib.path("Landmarks"), "Sculpture_" .. rb.name)
		-- grand carton de livraison en équilibre (sculpture)
		Lib.cyl(cm, CFrame.new(p + V(0, top + 1, 0)), 2, 10, rgb(236, 232, 222), M.SmoothPlastic)
		local box = Lib.part(cm, CFrame.new(p + V(0, top + 7.5, 0)) * CFrame.Angles(math.rad(18), math.rad(30), math.rad(14)), V(9, 9, 9), rgb(206, 156, 96), M.Cardboard)
		Lib.fine(cm, box.CFrame * CFrame.new(0, 4.52, 0), V(1.8, 0.05, 9), rgb(230, 210, 160), M.SmoothPlastic)
		local lab = Lib.fine(cm, box.CFrame * CFrame.new(0, 0, -4.52), V(6.5, 3, 0.05), rgb(206, 156, 96), M.SmoothPlastic)
		Lib.label(lab, Enum.NormalId.Front, "FRAGILE ?", rgb(200, 40, 40), nil, Enum.Font.GothamBlack)
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			Lib.bush(cm, p + V(math.cos(a) * (ri - 4), top - 0.4, math.sin(a) * (ri - 4)))
		end
	else
		local cm = Lib.model(Lib.path("Landmarks"), "Jardin_" .. rb.name)
		Lib.tree(cm, p + V(0, top - 0.4, 0), "round", 20)
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			Lib.flowers(cm, CFrame.new(p + V(math.cos(a) * (ri - 4), top - 0.4, math.sin(a) * (ri - 4))) * CFrame.Angles(0, -a, 0), 3, 5)
		end
	end
end

---------------------------------------------------------------- Tronçons droits
local count = { seg = 0, node = 0, rb = 0 }
for _, ln in Plan.lines do
	local along = {}
	for _, n in nodes do
		local onLine = (ln.axis == "X" and math.abs(n.z - ln.fixed) < 1 and n.x >= ln.a - 1 and n.x <= ln.b + 1) or (ln.axis == "Z" and math.abs(n.x - ln.fixed) < 1 and n.z >= ln.a - 1 and n.z <= ln.b + 1)
		if onLine then
			table.insert(along, { t = ln.axis == "X" and n.x or n.z, n = n })
		end
	end
	table.sort(along, function(p, q)
		return p.t < q.t
	end)
	local function pt(t)
		return ln.axis == "X" and V(t, 0, ln.fixed) or V(ln.fixed, 0, t)
	end
	local cuts = {}
	local cur, curIsNode = ln.a, false
	for _, e in along do
		local half = halfAlong(e.n, ln.axis == "X" and "E" or "S")
		local s0 = e.t - half
		if s0 > cur + 0.5 then
			table.insert(cuts, { cur, s0, curIsNode, true })
		end
		cur = e.t + half
		curIsNode = true
	end
	if ln.b > cur + 0.5 then
		table.insert(cuts, { cur, ln.b, curIsNode, false })
	end
	for _, cseg in cuts do
		local t0, t1 = cseg[1], cseg[2]
		local a, b = pt(t0), pt(t1)
		local len = t1 - t0
		local mid = (a + b) / 2
		local cf = CFrame.lookAt(mid, b)
		local rural = Plan.rural(mid.X, mid.Z)
		local g = Lib.model(F.asphalt, ln.name)
		asphalt(g, cf, ln.w, len + 0.02)
		local z0 = -len / 2 + (cseg[3] and 13 or 0)
		local z1 = len / 2 - (cseg[4] and 13 or 0)
		markings(cf, ln.w, ln.kind, z0, z1, rural)
		if rural then
			reflectors(cf, ln.w, len)
			-- accotement en gravier
			for _, s in { -1, 1 } do
				Lib.part(g, cf * CFrame.new(s * (ln.w / 2 + 2), Y - 0.75, 0), V(4, 1.4, len), rgb(150, 140, 120), M.Ground, { Name = "Shoulder" })
			end
		else
			local sw = Plan.SW[ln.kind]
			sidewalk(cf, ln.w / 2, len, sw, 1)
			sidewalk(cf, -ln.w / 2, len, sw, -1)
			furnish(cf, ln.w, sw, len, ln.kind, mid)
		end
		count.seg += 1
	end
end

for _, n in nodes do
	if n.rb then
		buildRoundabout(n.rb, n)
		count.rb += 1
	else
		buildNode(n)
		placeLights(n)
		count.node += 1
	end
	task.wait()
end

---------------------------------------------------------------- Arcs du périphérique
for _, arc in Plan.ringArcs do
	local w, sw, RR = Plan.W.ring, Plan.SW.ring, Plan.ring.r
	local g = Lib.model(F.asphalt, "PeripheriqueVirage")
	local step = 5
	for a = arc.a0, arc.a1 - step, step do
		local function at(rad, deg)
			local t = math.rad(deg)
			return arc.c + V(math.cos(t) * rad, 0, math.sin(t) * rad)
		end
		local function chord(rad, wd, ytop, h, col, mat, parent, name)
			local p0, p1 = at(rad, a), at(rad, a + step)
			local len = (p1 - p0).Magnitude + 0.5
			return Lib.part(parent, CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.new(0, ytop - h / 2, 0), V(wd, h, len), col, mat, { Name = name })
		end
		chord(RR, w, Y, 1.4, C.asphalt, M.Asphalt, g, "Road")
		local function markChord(rad, wd, col)
			local p0, p1 = at(rad, a), at(rad, a + step)
			Lib.mark(F.marks, CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.new(0, Y + 0.025, 0), V(wd, 0.05, (p1 - p0).Magnitude + 0.1), col)
		end
		markChord(RR - 0.45, 0.5, C.yellow)
		markChord(RR + 0.45, 0.5, C.yellow)
		markChord(RR - w / 2 + 1.4, 0.4, C.white)
		markChord(RR + w / 2 - 1.4, 0.4, C.white)
		if (a / step) % 2 == 0 then
			local function dash(rad)
				local p0, p1 = at(rad, a), at(rad, a + step * 0.55)
				Lib.mark(F.marks, CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.new(0, Y + 0.025, 0), V(0.45, 0.05, (p1 - p0).Magnitude), C.white)
			end
			dash(RR - w / 4)
			dash(RR + w / 4)
		end
		chord(RR - w / 2 - sw / 2, sw, WALK, 1.4, C.walk, M.Pavement, F.walk, "Sidewalk")
		chord(RR + w / 2 + sw / 2, sw, WALK, 1.4, C.walk, M.Pavement, F.walk, "Sidewalk")
		chord(RR - w / 2 - 0.4, 0.8, WALK + 0.02, 1.44, C.curb, M.Concrete, F.walk, "Curb")
		chord(RR + w / 2 + 0.4, 0.8, WALK + 0.02, 1.44, C.curb, M.Concrete, F.walk, "Curb")
		if (a / step) % 3 == 0 then
			local lp = at(RR + w / 2 + 1.6, a + step / 2)
			Lib.lamp(furniture, CFrame.lookAt(lp + V(0, WALK, 0), arc.c + V(0, WALK, 0)))
		end
	end
end

return ("routes : %d tronçons, %d carrefours, %d ronds-points"):format(count.seg, count.node, count.rb)
