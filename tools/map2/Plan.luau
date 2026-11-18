--!nolint
-- Plan de la map v2 : réseau routier, quartiers, relief. Partagé par toutes les étapes.
--
--                 N (z-)      forêt du nord, tunnel sous la crête
--   +-----------------------------------------------+
--   |  COLLINES      |   CENTRE-VILLE   |  ZONE      |
--   |  (Hillside)    |   (Downtown)     |  INDUSTR.  |   rivière à l'est (x ~ 1040)
--   |----------------O(rond-point)------+------------|--pont-- campagne (ferme)
--   |  QUARTIER RÉSIDENTIEL   | QG |  ZONE COMMERCIALE|
--   +-----------------------------------------------+   périphérique (anneau)
--                 S (z+)   rivière -> lac, plage, phare
local Plan = {}
local V = Vector3.new

-- Largeurs de route (studs)
Plan.W = { main = 48, ring = 40, sec = 32, res = 26, ind = 36 }

-- Lignes droites : axis "X" = la route suit X (z fixe), "Z" = la route suit Z (x fixe)
-- kind : main | ring | sec | res | ind
local L = {}
local function add(axis, fixed, a, b, kind, name)
	table.insert(L, { axis = axis, fixed = fixed, a = math.min(a, b), b = math.max(a, b), kind = kind, w = Plan.W[kind], name = name })
end
Plan.lines = L

-- Axes principaux
add("X", 0, -1250, 1300, "main", "BoulevardCentral")
add("Z", 0, -720, 1060, "main", "AvenueDesLivreurs")
add("Z", 0, -1250, -720, "main", "RouteDuTunnel")
add("X", 1060, -600, 0, "sec", "RouteDuLac")
-- Périphérique : côtés droits (les coins sont des arcs, voir Plan.ringArcs)
local RX, RZ, RR = 900, 720, 140
Plan.ring = { x = RX, z = RZ, r = RR }
add("X", -RZ, -RX + RR, RX - RR, "ring", "PeripheriqueNord")
add("X", RZ, -RX + RR, RX - RR, "ring", "PeripheriqueSud")
add("Z", -RX, -RZ + RR, RZ - RR, "ring", "PeripheriqueOuest")
add("Z", RX, -RZ + RR, RZ - RR, "ring", "PeripheriqueEst")
Plan.ringArcs = {
	{ c = V(RX - RR, 0, -RZ + RR), a0 = -90, a1 = 0 },
	{ c = V(RX - RR, 0, RZ - RR), a0 = 0, a1 = 90 },
	{ c = V(-RX + RR, 0, RZ - RR), a0 = 90, a1 = 180 },
	{ c = V(-RX + RR, 0, -RZ + RR), a0 = 180, a1 = 270 },
}

-- Centre-ville : x [-300, 300], z [-720, 0]
add("Z", -300, -720, 0, "sec", "RueDesCollines")
add("Z", 300, -720, 720, "sec", "RueDuCommerce")
add("Z", -150, -720, 0, "sec", "RueDesTours")
add("Z", 150, -720, 0, "sec", "RueDuMarche")
add("X", -180, -300, 300, "sec", "RueDeLaPlace")
add("X", -360, -338, 300, "sec", "RueHaute") -- prolongée vers la route des collines
add("X", -540, -300, 300, "sec", "RueDuNord")

-- Zone industrielle : x [300, 900], z [-720, 0]
add("X", -360, 300, 900, "ind", "RouteDesUsines")
add("Z", 600, -720, 0, "ind", "AlleeDesConteneurs")

-- Quartier résidentiel : x [-900, 0], z [0, 720]
for _, z in { 180, 360, 540 } do
	add("X", z, -900, 0, "res", "RueResidentielle" .. z)
end
for _, x in { -240, -480, -720 } do
	add("Z", x, 0, 720, "res", "AlleeResidentielle" .. -x)
end

-- Zone commerciale : x [0, 900], z [0, 720] (le QG occupe x [0, 300], z [0, 300])
add("X", 300, 0, 900, "sec", "AvenueDesMagasins")
add("Z", 600, 0, 720, "sec", "RueDesRestaurants")
add("X", 520, 300, 900, "sec", "RueDuSupermarche")

-- Largeur des trottoirs par type de route
Plan.SW = { main = 12, ring = 12, sec = 10, res = 9, ind = 8 }

-- Hors de la ville (au-delà du périphérique) : routes de campagne sans trottoir
function Plan.rural(x, z)
	return math.abs(x) > RX + 22 or math.abs(z) > RZ + 22
end

-- Ronds-points (centre, rayon extérieur de chaussée)
Plan.roundabouts = {
	{ p = V(0, 0, 0), r = 50, name = "RondPointCentral", fountain = true },
	{ p = V(RX, 0, 0), r = 38, name = "RondPointEst" },
	{ p = V(-RX, 0, 0), r = 38, name = "RondPointOuest" },
	{ p = V(0, 0, RZ), r = 38, name = "RondPointSud" },
	{ p = V(0, 0, -RZ), r = 38, name = "RondPointNord" },
	{ p = V(600, 0, 300), r = 34, name = "RondPointDesMagasins" },
}

-- Quartiers (rectangles x1, z1, x2, z2)
Plan.districts = {
	Downtown = { -300, -720, 300, 0 },
	IndustrialZone = { 300, -720, 900, 0 },
	HillsideDistrict = { -900, -720, -300, 0 },
	ResidentialDistrict = { -900, 0, 0, 720 },
	DeliveryHeadquarters = { 0, 0, 300, 300 },
	CommercialDistrict = { 0, 0, 900, 720 },
}

---------------------------------------------------------------- Relief
local function smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end
Plan.smooth = smooth

-- Colline (Hillside) : dôme avec plateau
Plan.hill = { c = V(-600, 0, -360), r = 270, top = 58, plateau = 72 }
function Plan.domeAt(d)
	local h = Plan.hill
	return h.top * smooth(1 - (d - h.plateau) / (h.r - h.plateau))
end

-- Route en spirale autour de la colline (points 3D, y = dessus de chaussée)
do
	local h = Plan.hill
	local pts = {}
	local r0, r1, turns = 262, 92, 2.1
	local n = 260
	for i = 0, n do
		local t = i / n
		local th = -t * turns * math.pi * 2 -- sens anti-horaire vu du dessus
		local r = r0 + (r1 - r0) * t
		local y = Plan.domeAt(r)
		table.insert(pts, V(h.c.X + math.cos(th) * r, y, h.c.Z + math.sin(th) * r))
	end
	Plan.spiral = pts
	Plan.spiralW = 28
	-- Terrains des maisons des collines : côté extérieur de la spirale
	local pads = {}
	for i = 22, n - 18, 15 do
		local p, q = pts[i], pts[i + 1]
		local dir = (q - p) * V(1, 0, 1)
		dir = dir.Unit
		local out = (p - h.c) * V(1, 0, 1)
		out = out.Unit
		table.insert(pads, { p = V(p.X, p.Y, p.Z) + out * 31, y = p.Y, face = -out, along = dir })
	end
	-- Maisons sur le plateau
	for k = 0, 3 do
		local a = math.rad(45 + k * 90)
		local o = V(math.cos(a), 0, math.sin(a))
		table.insert(pads, { p = h.c + o * 44 + V(0, h.top, 0), y = h.top, face = -o, along = V(-o.Z, 0, o.X), plateau = true })
	end
	Plan.hillPads = pads
end

-- Rivière : nord -> sud à x = 1040, puis vers l'ouest à z = 900 jusqu'au lac
Plan.river = {
	pts = { V(1040, 0, -1500), V(1040, 0, 700), V(1000, 0, 820), V(880, 0, 900), V(-500, 0, 900), V(-640, 0, 960) },
	w = 90,
	lake = { c = V(-800, 0, 1010), r = 170 },
}

local function segDist(p, a, b)
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (p - (a + ab * t)).Magnitude, t
end
Plan.segDist = segDist

function Plan.riverDist(x, z)
	local p = V(x, 0, z)
	local best = math.huge
	local pts = Plan.river.pts
	for i = 1, #pts - 1 do
		best = math.min(best, (segDist(p, pts[i], pts[i + 1])))
	end
	return best
end

-- Routes hors de la ville qui doivent rester à plat
local flatRoads = {
	{ V(-1250, 0, 0), V(-900, 0, 0), 48 },
	{ V(900, 0, 0), V(1300, 0, 0), 48 },
	{ V(0, 0, 720), V(0, 0, 1060), 48 },
	{ V(0, 0, -720), V(0, 0, -860), 48 }, -- entrée du tunnel (la crête reste au-dessus du tunnel)
	{ V(0, 0, -1080), V(0, 0, -1250), 48 },
	{ V(-600, 0, 1060), V(0, 0, 1060), 32 },
	{ V(-60, 0, -1250), V(60, 0, -1250), 90 }, -- belvédère du nord
	{ V(1180, 0, -40), V(1360, 0, -260), 120 }, -- ferme
}
Plan.flatRoads = flatRoads
Plan.tunnel = { x = 0, z1 = -860, z2 = -1080 }

-- Hauteur du sol (avant lissage) en (x, z)
function Plan.height(x, z)
	local p = V(x, 0, z)
	local h = 0
	-- colline des collines (Hillside)
	local d = (p - Plan.hill.c).Magnitude
	if d < Plan.hill.r then
		h = Plan.domeAt(d)
	end
	-- crête du nord (le tunnel la traverse)
	if z < -820 then
		local t = smooth((-820 - z) / 170)
		local back = smooth((z + 1200) / 110)
		local peak = 105 + 35 * math.noise(x / 260, 3.1)
		local ridge = peak * t * back + 10 * math.noise(x / 70, z / 70, 3.3) * t * back
		h = math.max(h, ridge)
	end
	-- vallée boisée au nord de la crête
	if z < -1160 then
		h = math.max(h, 8 + 10 * math.noise(x / 160, z / 160, 1.7))
	end
	-- campagne vallonnée à l'est de la rivière et à l'ouest du périphérique
	if x > 1120 or x < -960 then
		local k = x > 1120 and smooth((x - 1120) / 120) or smooth((-960 - x) / 80)
		h = math.max(h, k * (6 + 14 * (math.noise(x / 210, z / 210, 4.2) + 0.5)))
	end
	-- plage et collines au sud de la rivière
	if z > 960 then
		local k = smooth((z - 960) / 120)
		h = math.max(h, k * (4 + 20 * (math.noise(x / 180, z / 180, 7.3) + 0.5)))
	end
	-- falaise de la cascade, rive est
	local dc = (p - V(1150, 0, -420)).Magnitude
	if dc < 140 then
		h = math.max(h, 70 * smooth((140 - dc) / 60))
	end
	-- montagnes de bordure
	local ex = math.max(math.abs(x) - 1380, 0)
	local ez = math.max(math.abs(z) - 1260, 0)
	local e = math.sqrt(ex * ex + ez * ez)
	if e > 0 then
		h = math.max(h, math.min(e * 0.85, 210) + 26 * math.noise(x / 160, z / 160, 9.9) * math.min(e / 60, 1))
	end
	-- routes extérieures : sol à plat
	for _, r in flatRoads do
		local dd = segDist(p, r[1], r[2])
		if dd < r[3] / 2 + 30 then
			local k = smooth((dd - r[3] / 2 - 6) / 24)
			h = h * k
		end
	end
	-- spirale et terrains des collines
	if d < Plan.hill.r + 30 then
		local best, by = math.huge, 0
		local s = Plan.spiral
		for i = 1, #s - 1, 2 do
			local a, b = s[i], s[math.min(i + 2, #s)]
			local dd, t = segDist(V(x, 0, z), V(a.X, 0, a.Z), V(b.X, 0, b.Z))
			if dd < best then
				best, by = dd, a.Y + (b.Y - a.Y) * t
			end
		end
		local half = Plan.spiralW / 2 + 5
		if best < half + 12 then
			local k = smooth((best - half) / 12)
			h = by + (h - by) * k
		end
		for _, pad in Plan.hillPads do
			local dd = (V(x, 0, z) - V(pad.p.X, 0, pad.p.Z)).Magnitude
			if dd < 30 then
				local k = smooth((dd - 18) / 12)
				h = pad.y + (h - pad.y) * k
			end
		end
	end
	-- rivière et lac (fond à -9)
	local rd = Plan.riverDist(x, z)
	local half = Plan.river.w / 2
	if rd < half + 30 then
		local bank = math.min(h, 1.5)
		local k = smooth((rd - half + 12) / 40)
		local bed = -9 * smooth((half - rd) / 22)
		h = (rd < half) and math.min(bed, 0) or bank * k
		if rd < half then
			h = bed
		end
	end
	local ld = (p - Plan.river.lake.c).Magnitude
	if ld < Plan.river.lake.r + 40 then
		local rr = Plan.river.lake.r
		if ld < rr then
			h = -10 * smooth((rr - ld) / 40)
		else
			h = math.min(h, 1.5 * smooth((ld - rr) / 40))
		end
	end
	return h
end

Plan.WATER = -4.5 -- niveau de l'eau (surface à y = -4)

return Plan
