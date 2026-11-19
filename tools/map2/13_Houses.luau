--!nolint
-- 13 : quartier résidentiel reconstruit avec des maisons en pièces (HouseKit) : architecture américaine
-- classique et moderne, couleurs naturelles, échelle des personnages, intérieurs meublés et portes qui s'ouvrent.
-- Les maisons Meshy (étape 12) sont conservées dans ServerStorage.Backups et ReplicatedStorage.Assets.Houses.
-- Repère d'un terrain : -Z local vers la rue, +X local = gauche vue depuis la rue.
local Lib = require(script.Parent.Lib)
local Plan = require(script.Parent.Plan)
local HK = require(script.Parent.HouseKit)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C

local rng = Random.new(1313)

-- tailles agrandies (intérieurs plus spacieux) ; 12 types dans le même style réaliste
local TYPES = {
	classic = { cat = "ClassicHouses", floors = { 1 }, W = { 38, 43 }, D = { 38, 41 }, roofs = { "gable", "gable", "frontgable" }, garage = 0.65, porch = 0.7, chimney = 0.5, pals = { "white", "beige", "grey", "brick", "brownbrick", "taupe", "sage" } },
	twostory = { cat = "TwoStoryHouses", floors = { 2 }, W = { 36, 41 }, D = { 42, 45 }, roofs = { "gable", "frontgable" }, garage = 0.75, porch = 0.6, chimney = 0.4, pals = { "white", "brickup", "grey", "beige", "taupe", "brownbrick", "navy" } },
	villa = { cat = "Villas", floors = { 2 }, W = { 48, 53 }, D = { 44, 47 }, roofs = { "gable", "hip" }, garage = 0, porch = 1, porchW = 22, chimney = 0.6, pals = { "stucco", "stone", "brick", "white", "sand" } },
	modern = { cat = "ModernHouses", floors = { 1, 2 }, W = { 38, 45 }, D = { 38, 41 }, roofs = { "flat" }, garage = 0.7, porch = 0, chimney = 0, pals = { "modernwhite", "moderngrey", "modernwood" } },
	colonial = { cat = "TwoStoryHouses", floors = { 2 }, W = { 42, 46 }, D = { 42, 44 }, roofs = { "hip" }, garage = 0.4, porch = 1, porchW = 12, portico = true, centerDoor = true, chimney = 0.7, pals = { "cream", "white", "brick", "slate", "navy" } },
	ranch = { cat = "ClassicHouses", floors = { 1 }, W = { 44, 49 }, D = { 34, 37 }, roofs = { "hip" }, pitch = 0.42, garage = 0.6, porch = 0.4, chimney = 0.3, pals = { "beige", "brownbrick", "taupe", "slate", "grey", "sand" } },
	farmhouse = { cat = "TwoStoryHouses", floors = { 2 }, W = { 38, 41 }, D = { 42, 44 }, roofs = { "frontgable", "gable" }, garage = 0.5, porch = 1, porchFull = true, chimney = 0.3, pals = { "farm", "sage" } },
	small = { cat = "SmallHouses", floors = { 1 }, W = { 30, 33 }, D = { 32, 35 }, roofs = { "gable", "frontgable" }, garage = 0, porch = 0.8, porchW = 11, chimney = 0.5, pals = { "white", "beige", "grey", "wood", "taupe", "sage" } },
	-- nouveaux modèles
	craftsman = { cat = "ClassicHouses", floors = { 1 }, W = { 38, 42 }, D = { 40, 43 }, roofs = { "frontgable" }, pitch = 0.5, garage = 0.5, porch = 1, porchFull = true, chimney = 0.6, pals = { "wood", "sage", "taupe", "charcoal" } },
	georgian = { cat = "TwoStoryHouses", floors = { 2 }, W = { 44, 48 }, D = { 42, 44 }, roofs = { "hip" }, pitch = 0.45, garage = 0.5, porch = 1, porchW = 9, portico = true, centerDoor = true, chimney = 0.9, pals = { "brick", "brownbrick", "sand" } },
	cape = { cat = "TwoStoryHouses", floors = { 2 }, W = { 36, 40 }, D = { 40, 42 }, roofs = { "gable" }, pitch = 0.7, garage = 0.6, porch = 0.5, porchW = 10, centerDoor = true, chimney = 0.8, pals = { "cream", "white", "grey", "navy", "charcoal" } },
	cottage = { cat = "SmallHouses", floors = { 1 }, W = { 32, 35 }, D = { 34, 36 }, roofs = { "hip", "frontgable" }, pitch = 0.55, garage = 0.3, porch = 1, porchW = 12, chimney = 0.9, pals = { "stucco", "stone", "sage", "cream" } },
}
local STYLE = {
	ClassicHouses = { fence = { "picket", "picket", "hedge" }, mailbox = "classic", tree = "round" },
	TwoStoryHouses = { fence = { "hedge", "picket", "lowwall" }, mailbox = "classic", tree = "round" },
	Villas = { fence = { "villa" }, mailbox = "stone", tree = "round" },
	ModernHouses = { fence = { "modern", "none" }, mailbox = "modern", tree = "pine" },
	SmallHouses = { fence = { "wood", "picket", "none" }, mailbox = "classic", tree = "round" },
}

local XS = { { -900, "ring" }, { -720, "res" }, { -480, "res" }, { -240, "res" }, { 0, "main" } }
local ZS = { { 0, "main" }, { 180, "res" }, { 360, "res" }, { 540, "res" }, { 720, "ring" } }
local function edge(v, kind, s)
	return v + s * (Plan.W[kind] / 2 + Plan.SW[kind])
end
local function pick(t)
	return t[rng:NextInteger(1, #t)]
end
local function range(t)
	return t[1] + (t[2] - t[1]) * rng:NextNumber()
end

---------------------------------------------------------------- petits éléments
local function bins(parent, cf)
	for k, col in { rgb(40, 120, 60), rgb(250, 200, 40), rgb(60, 110, 200) } do
		if k < 3 or rng:NextNumber() < 0.4 then
			local b = Lib.part(parent, cf * CFrame.new((k - 2) * 2.1, 1.6, 0), V(1.8, 3.2, 1.8), col, M.SmoothPlastic, { Name = "Bin", CanTouch = false })
			Lib.fine(parent, b.CFrame * CFrame.new(0, 1.7, 0.1), V(2, 0.3, 2.1), col:Lerp(Color3.new(0, 0, 0), 0.2), M.SmoothPlastic)
		end
	end
end

local function mailbox(parent, cf, style)
	local m = Lib.model(parent, "Mailbox")
	if style == "modern" then
		Lib.part(m, cf * CFrame.new(0, 2, 0), V(1.6, 4, 1.2), rgb(70, 74, 82), M.Metal)
		Lib.fine(m, cf * CFrame.new(0, 3.2, -0.62), V(1.1, 0.2, 0.05), rgb(230, 230, 230), M.Metal)
	elseif style == "stone" then
		Lib.part(m, cf * CFrame.new(0, 1.8, 0), V(2.2, 3.6, 2.2), rgb(176, 166, 150), M.Cobblestone)
		Lib.part(m, cf * CFrame.new(0, 4, 0), V(1.6, 1.2, 1.8), rgb(40, 44, 50), M.Metal)
	else
		local col = pick({ rgb(40, 40, 44), rgb(46, 72, 56), rgb(236, 234, 228), rgb(110, 112, 116) })
		Lib.part(m, cf * CFrame.new(0, 1.8, 0), V(0.5, 3.6, 0.5), rgb(120, 86, 56), M.Wood)
		Lib.part(m, cf * CFrame.new(0, 3.9, 0), V(1.3, 1.1, 2), col, M.Metal)
		Lib.fine(m, cf * CFrame.new(0.72, 4.2, 0.4), V(0.1, 0.9, 0.25), rgb(230, 40, 40), M.SmoothPlastic)
	end
	return m
end

local function flowerRow(parent, a, b, w)
	local len = (b - a).Magnitude
	if len < 2 then
		return
	end
	local cf = CFrame.lookAt((a + b) / 2, b)
	Lib.flowers(parent, cf * CFrame.Angles(0, math.pi / 2, 0), len, w or 2)
end

local function gatePillars(parent, cf, half, col, mat, h)
	for _, s in { -1, 1 } do
		Lib.part(parent, cf * CFrame.new(s * half, (h or 4) / 2, 0), V(1.4, h or 4, 1.4), col, mat)
		Lib.fine(parent, cf * CFrame.new(s * half, (h or 4) + 0.2, 0), V(1.8, 0.4, 1.8), col:Lerp(C.white, 0.3), mat)
	end
end

local function lowWall(parent, a, b, h, col, mat)
	local len = (b - a).Magnitude
	if len < 0.5 then
		return
	end
	local cf = CFrame.lookAt((a + b) / 2, b)
	Lib.part(parent, cf * CFrame.new(0, h / 2, 0), V(1.2, h, len), col, mat, { Name = "LowWall" })
	Lib.fine(parent, cf * CFrame.new(0, h + 0.15, 0), V(1.5, 0.3, len), col:Lerp(C.white, 0.35), M.SmoothPlastic)
end

local function pool(parent, cf, w, d)
	local m = Lib.model(parent, "Pool")
	Lib.part(m, cf * CFrame.new(0, 0.35, 0), V(w + 4, 0.7, d + 4), rgb(236, 232, 222), M.Concrete)
	Lib.fine(m, cf * CFrame.new(0, 0.72, 0), V(w, 0.1, d), rgb(70, 200, 240), M.Glass, { Transparency = 0.1, Reflectance = 0.2 })
	Lib.fine(m, cf * CFrame.new(w / 2 + 0.8, 1.2, d / 2 - 2), V(1.2, 1.2, 0.2), C.white, M.Metal)
	-- transats
	for k = -1, 1, 2 do
		local tc = cf * CFrame.new(k * 3, 0.7, -d / 2 - 3.5)
		Lib.part(m, tc * CFrame.new(0, 0.6, 0), V(2.2, 0.4, 5), C.white, M.SmoothPlastic)
		Lib.fine(m, tc * CFrame.new(0, 1.2, 1.9) * CFrame.Angles(math.rad(-35), 0, 0), V(2.2, 0.3, 1.8), pick({ rgb(214, 204, 186), rgb(120, 130, 136), rgb(236, 232, 222) }), M.Fabric)
	end
	return m
end

local function swing(parent, cf)
	local m = Lib.model(parent, "Swing")
	local col = pick({ rgb(120, 86, 58), rgb(70, 90, 70), rgb(96, 98, 102) })
	for _, x in { -4, 4 } do
		Lib.part(m, cf * CFrame.new(x, 4, -1.5) * CFrame.Angles(math.rad(12), 0, 0), V(0.6, 8.4, 0.6), col, M.Metal)
		Lib.part(m, cf * CFrame.new(x, 4, 1.5) * CFrame.Angles(math.rad(-12), 0, 0), V(0.6, 8.4, 0.6), col, M.Metal)
	end
	Lib.fine(m, cf * CFrame.new(0, 8, 0), V(9, 0.5, 0.5), col, M.Metal)
	for _, x in { -1.8, 1.8 } do
		Lib.fine(m, cf * CFrame.new(x, 2.4, 0), V(1.8, 0.3, 1), rgb(250, 250, 250), M.SmoothPlastic)
		for _, s in { -0.8, 0.8 } do
			Lib.fine(m, cf * CFrame.new(x + s, 5.2, 0), V(0.1, 5.6, 0.1), C.dark, M.Metal)
		end
	end
end

local function trampoline(parent, cf)
	local m = Lib.model(parent, "Trampoline")
	Lib.cyl(m, cf * CFrame.new(0, 2.2, 0), 0.5, 11, rgb(54, 84, 62), M.SmoothPlastic)
	Lib.cylDeco(m, cf * CFrame.new(0, 2.5, 0), 0.1, 9.5, rgb(30, 30, 34), M.Fabric)
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		Lib.fine(m, cf * CFrame.new(math.cos(a) * 5, 1, math.sin(a) * 5), V(0.3, 2, 0.3), rgb(150, 150, 156), M.Metal)
	end
end

local function veggies(parent, cf, w, d)
	local m = Lib.model(parent, "VegetableGarden")
	Lib.part(m, cf * CFrame.new(0, 0.3, 0), V(w, 0.6, d), rgb(120, 84, 56), M.WoodPlanks)
	Lib.fine(m, cf * CFrame.new(0, 0.62, 0), V(w - 0.8, 0.1, d - 0.8), rgb(92, 62, 40), M.Ground)
	for x = -w / 2 + 1.5, w / 2 - 1.5, 2 do
		for z = -d / 2 + 1.5, d / 2 - 1.5, 2.2 do
			local col = pick({ rgb(70, 170, 60), rgb(90, 190, 70), rgb(230, 60, 40), rgb(250, 150, 30) })
			Lib.ball(m, (cf * CFrame.new(x, 1.1, z)).Position, 1, col, M.Grass, { CastShadow = false })
		end
	end
end

local function patioSet(parent, cf)
	local m = Lib.model(parent, "Patio")
	Lib.part(m, cf * CFrame.new(0, 0.15, 0), V(10, 0.3, 8), rgb(196, 172, 140), M.WoodPlanks)
	Lib.cylDeco(m, cf * CFrame.new(0, 2, 0), 0.25, 3.4, C.white, M.SmoothPlastic)
	Lib.fine(m, cf * CFrame.new(0, 1.1, 0), V(0.3, 1.8, 0.3), C.white, M.Metal)
	for _, s in { -1, 1 } do
		Lib.part(m, cf * CFrame.new(s * 2.6, 0.9, 0), V(1.4, 0.3, 1.4), rgb(70, 70, 76), M.Metal)
	end
	-- parasol
	Lib.fine(m, cf * CFrame.new(0, 3.5, 0), V(0.2, 3, 0.2), rgb(200, 200, 200), M.Metal)
	Lib.cylDeco(m, cf * CFrame.new(0, 5, 0), 0.4, 7, pick({ rgb(232, 226, 210), rgb(96, 110, 100), rgb(200, 190, 170) }), M.Fabric)
end

local function gardenLamp(parent, cf, modern)
	local m = Lib.model(parent, "GardenLamp")
	if modern then
		Lib.part(m, cf * CFrame.new(0, 1.2, 0), V(0.6, 2.4, 0.6), rgb(50, 52, 58), M.Metal)
		Lib.fine(m, cf * CFrame.new(0, 2.1, -0.32), V(0.4, 0.3, 0.05), rgb(255, 236, 190), M.Neon)
	else
		Lib.part(m, cf * CFrame.new(0, 2, 0), V(0.35, 4, 0.35), rgb(40, 44, 50), M.Metal)
		Lib.ball(m, (cf * CFrame.new(0, 4.3, 0)).Position, 1, rgb(255, 240, 200), M.Neon)
	end
end

---------------------------------------------------------------- une maison et son terrain
local function makeSpec(typ, lw, lastPal)
	local T = TYPES[typ]
	local floors = pick(T.floors)
	local spec = {
		type = typ,
		floors = floors,
		W = math.floor(range(T.W)),
		D = math.floor(range(T.D)),
		roof = pick(T.roofs),
		porch = rng:NextNumber() < T.porch,
		porchW = T.porchW,
		chimney = rng:NextNumber() < T.chimney,
		doorSide = rng:NextNumber() < 0.5 and -1 or 1,
		portico = T.portico,
		centerDoor = T.centerDoor,
		pitch = T.pitch,
	}
	if typ == "modern" and floors == 2 then
		spec.D = 43
	end
	repeat
		spec.pal = pick(T.pals)
	until spec.pal ~= lastPal or #T.pals == 1
	if rng:NextNumber() < T.garage then
		spec.garage = { side = -spec.doorSide, w = 12 }
	end
	local budget = lw - 8
	if spec.garage and spec.W + 12.8 > budget then
		spec.W = math.floor(budget - 12.8)
		if spec.W < T.W[1] - 2 then
			spec.garage = nil
			spec.W = math.floor(range(T.W))
		end
	end
	spec.W = math.min(spec.W, math.floor(budget))
	if T.porchFull then
		spec.porchW = spec.W * 2
	end
	return spec
end

local function buildLot(dirs, lotCf, lw, ld, typ, tag, extraSetback, lastPal)
	local spec = makeSpec(typ, lw, lastPal)
	local T = TYPES[typ]
	local style = STYLE[T.cat]
	local setback = rng:NextNumber(13, 16) + (extraSetback or 0)
	local gw = spec.garage and 12 + HK.EXT or 0
	local hx = spec.garage and -spec.garage.side * gw / 2 or 0
	if not spec.garage and spec.W < lw - 26 then
		hx = (rng:NextNumber() < 0.5 and -1 or 1) * rng:NextNumber(2, 4)
	end
	spec.name = tag .. "_" .. typ
	-- maison modèle (meublée) : première maison à étage avec garage ; HK.FURNISH_ALL meuble toutes les maisons
	if HK.FURNISH_ALL or workspace:GetAttribute("FurnishAll") or (not Lib.MODEL_HOUSE and typ == "twostory" and spec.garage) then
		spec.furnish = true
		if not (HK.FURNISH_ALL or workspace:GetAttribute("FurnishAll")) then
			Lib.MODEL_HOUSE = spec.name
		end
	end
	local hm, info = HK.build(dirs.houses[T.cat], lotCf * CFrame.new(hx, 0, setback), spec, rng)
	local w, depth = spec.W, spec.D
	local garden = Lib.model(dirs.gardens, tag)
	local L, R = -lw / 2 + 0.6, lw / 2 - 0.6
	local sw = Plan.SW.res
	local doorX = hx + info.doorX
	-- garage ou place de stationnement
	local gx, dw, dl
	if info.garage then
		gx = hx + info.garage.x
		dw = info.garage.w + 1
		dl = setback + info.garage.z0
	else
		local side = hx >= 0 and -1 or 1
		gx = hx + side * (w / 2 + 6)
		dw = 10
		dl = setback + depth * 0.6
		if math.abs(gx) > lw / 2 - 6 then
			gx = nil
		end
	end
	if gx then
		local col = typ == "villa" and rgb(214, 204, 186) or rgb(192, 190, 184)
		Lib.part(garden, lotCf * CFrame.new(gx, 0.15, dl / 2), V(dw, 0.3, dl), col, typ == "villa" and M.Pavement or M.Concrete, { Name = "Driveway" })
		Lib.driveway(garden, lotCf * CFrame.new(gx, 0, -sw) * CFrame.Angles(0, math.pi, 0), dw, sw)
		local cz = info.garage and math.max(8.5, dl - 8.5) or math.max(8.5, setback - 8.5)
		if rng:NextNumber() < 0.75 and (not info.garage or cz <= dl - 7.5) then
			local off = info.garage and (rng:NextNumber() < 0.5 and -1 or 1) * math.max(0, dw / 2 - 3.8) or 0 -- passage libre devant la porte du garage
			local ccf = lotCf * CFrame.new(gx + off, 0.3, cz) * CFrame.Angles(0, rng:NextNumber() < 0.5 and 0 or math.pi, 0)
			local car = Lib.meshyCar(Lib.path("DecorativeVehicles"), ccf)
			if car then
				car:SetAttribute("Lot", tag)
			end
		end
		bins(garden, lotCf * CFrame.new(gx + (gx >= hx and 1 or -1) * (dw / 2 + 2), 0, setback - 2) * CFrame.Angles(0, math.pi, 0))
	else
		bins(garden, lotCf * CFrame.new(hx + w / 2 + 3, 0, setback + 2))
	end

	-- allée piétonne jusqu'au perron
	local stepZ = setback - (info.porch and 6.7 or 4.2)
	local pathMat = pick({ M.Pavement, M.Slate, M.Brick })
	local pathCol = pathMat == M.Brick and rgb(170, 110, 90) or rgb(200, 194, 184)
	if typ == "modern" then
		for z = 1.5, stepZ - 1, 2.6 do
			Lib.fine(garden, lotCf * CFrame.new(doorX, 0.12, z), V(4, 0.25, 1.8), rgb(214, 214, 210), M.Concrete)
		end
	else
		Lib.fine(garden, lotCf * CFrame.new(doorX, 0.12, stepZ / 2), V(typ == "villa" and 5 or 3.8, 0.25, stepZ), pathCol, pathMat, { Name = "Path" })
	end

	-- boîte aux lettres
	Lib.yield(2)
	mailbox(dirs.mailboxes, lotCf * CFrame.new(doorX + 3.2, 0, 1.6) * CFrame.Angles(0, math.pi, 0), style.mailbox).Name = tag

	-- clôture avant (ouvertures pour l'allée et le garage)
	local ftype = pick(style.fence)
	local half = typ == "villa" and 3.2 or 2.2
	local cuts = { { doorX - half, doorX + half } }
	if gx then
		table.insert(cuts, { gx - dw / 2 - 0.5, gx + dw / 2 + 0.5 })
	end
	table.sort(cuts, function(a, b)
		return a[1] < b[1]
	end)
	local segs, cur = {}, L
	for _, c in cuts do
		if c[1] > cur + 1 then
			table.insert(segs, { cur, c[1] })
		end
		cur = math.max(cur, c[2])
	end
	if R > cur + 1 then
		table.insert(segs, { cur, R })
	end
	local fence = Lib.model(dirs.fences, tag)
	local fcol = pick({ C.white, C.white, rgb(236, 232, 220) })
	for _, s in segs do
		local a = (lotCf * CFrame.new(s[1], 0, 1.3)).Position
		local b = (lotCf * CFrame.new(s[2], 0, 1.3)).Position
		if ftype == "picket" then
			local f = Lib.fence(fence, a, b, "picket", 3)
			for _, p in f:GetDescendants() do
				if p:IsA("BasePart") and p.Transparency < 1 then
					p.Color = fcol
				end
			end
		elseif ftype == "hedge" then
			Lib.hedge(fence, a, b, 2.8, 1.8)
		elseif ftype == "lowwall" then
			lowWall(fence, a, b, 2, rgb(170, 120, 100), M.Brick)
		elseif ftype == "villa" then
			lowWall(fence, a, b, 2.2, rgb(206, 196, 178), M.Sandstone)
			Lib.fence(fence, a + V(0, 2.4, 0), b + V(0, 2.4, 0), "metal", 3)
		elseif ftype == "modern" then
			lowWall(fence, a, b, 1.4, rgb(200, 200, 196), M.Concrete)
		elseif ftype == "wood" then
			local f = Lib.fence(fence, a, b, "picket", 3.4)
			for _, p in f:GetDescendants() do
				if p:IsA("BasePart") and p.Transparency < 1 then
					p.Color = rgb(150, 112, 78)
					p.Material = M.WoodPlanks
				end
			end
		end
	end
	if ftype == "villa" then
		gatePillars(fence, lotCf * CFrame.new(doorX, 0, 1.4), 3.4, rgb(206, 196, 178), M.Sandstone, 5)
		gardenLamp(garden, lotCf * CFrame.new(doorX - 4.5, 0, 2.4), false)
		gardenLamp(garden, lotCf * CFrame.new(doorX + 4.5, 0, 2.4), false)
	elseif ftype == "picket" or ftype == "wood" then
		gatePillars(fence, lotCf * CFrame.new(doorX, 0, 1.4), 2.4, fcol, M.SmoothPlastic, 3.6)
	elseif ftype == "hedge" or ftype == "lowwall" then
		gatePillars(fence, lotCf * CFrame.new(doorX, 0, 1.4), 2.4, rgb(170, 120, 100), M.Brick, 3.4)
	end
	if rng:NextNumber() < 0.6 then
		Lib.hedge(fence, (lotCf * CFrame.new(R - 0.8, 0, 3)).Position, (lotCf * CFrame.new(R - 0.8, 0, ld - 2)).Position, 3.2, 1.6)
	end
	if rng:NextNumber() < 0.35 then
		Lib.fence(fence, (lotCf * CFrame.new(L + 0.4, 0, ld - 1)).Position, (lotCf * CFrame.new(R - 0.4, 0, ld - 1)).Position, "picket", 3.4)
	end

	-- massifs le long de la façade (hors perron et garage)
	local front = setback - 1.4
	local porchHalf = info.porch and ((spec.porchW or 11) / 2 + 0.8) or 3.8
	local hx1, hx2 = hx - w / 2 + 1, hx + w / 2 - 1
	for _, s in { -1, 1 } do
		local x0, x1 = doorX + s * porchHalf, s > 0 and hx2 or hx1
		if (x1 - x0) * s > 2 then
			if typ == "modern" then
				Lib.fine(garden, lotCf * CFrame.new((x0 + x1) / 2, 0.1, front), V(math.abs(x1 - x0), 0.2, 2.4), rgb(200, 198, 192), M.Pebble)
			else
				flowerRow(garden, (lotCf * CFrame.new(x0, 0, front)).Position, (lotCf * CFrame.new(x1, 0, front)).Position, 2)
			end
		end
	end
	for k = -1, 1, 2 do
		Lib.bush(garden, (lotCf * CFrame.new(doorX + k * 3.4, 0, 3)).Position, rng:NextNumber(2.2, 3))
	end
	if typ == "modern" then
		gardenLamp(garden, lotCf * CFrame.new(doorX - 2.6, 0, stepZ * 0.5), true)
		gardenLamp(garden, lotCf * CFrame.new(doorX + 2.6, 0, stepZ * 0.5), true)
	end

	-- arbres à l'échelle des maisons
	local tx = gx and (gx > hx and L + 6 or R - 6) or (hx > 0 and R - 6 or L + 6)
	if style.tree == "pine" then
		Lib.tree(dirs.trees, (lotCf * CFrame.new(tx, 0, setback * 0.55)).Position, "pine", rng:NextNumber(20, 28))
	else
		Lib.tree(dirs.trees, (lotCf * CFrame.new(tx, 0, setback * 0.5)).Position, "round", rng:NextNumber(18, 26))
	end

	-- jardin arrière
	local back = setback + depth + 3
	local room = ld - back
	local bx = -hx * 0.5
	if room > 12 then
		local r = rng:NextNumber()
		if typ == "villa" or (typ == "modern" and r < 0.6) then
			pool(garden, lotCf * CFrame.new(bx, 0, back + room / 2 + 1), math.min(16, lw - 18), math.min(9, room - 9))
		elseif typ == "small" then
			veggies(garden, lotCf * CFrame.new(bx - 6, 0, back + room / 2), 9, math.min(8, room - 4))
			Lib.bench(garden, lotCf * CFrame.new(bx + 8, 0, back + 3) * CFrame.Angles(0, math.pi, 0))
		elseif r < 0.3 then
			swing(garden, lotCf * CFrame.new(bx + lw / 5, 0, back + room / 2))
		elseif r < 0.5 then
			trampoline(garden, lotCf * CFrame.new(bx - lw / 6, 0, back + room / 2))
		elseif r < 0.85 then
			patioSet(garden, lotCf * CFrame.new(bx, 0, back + 4.5))
		else
			veggies(garden, lotCf * CFrame.new(bx, 0, back + room / 2), 10, math.min(8, room - 4))
		end
		if room > 18 then
			Lib.tree(dirs.trees, (lotCf * CFrame.new(rng:NextNumber() < 0.5 and L + 6 or R - 6, 0, ld - 6)).Position, rng:NextNumber() < 0.6 and "round" or "pine", rng:NextNumber(18, 26))
		end
	end
	return hm, spec.pal
end

---------------------------------------------------------------- terrains d'angle : rien ne doit empiéter sur les routes
local removedLog = {}
local roadOv = OverlapParams.new()
roadOv.FilterType = Enum.RaycastFilterType.Include
local function hitsRoad(p)
	return #workspace:GetPartBoundsInBox(p.CFrame, p.Size * 0.92, roadOv) > 0
end
local function houseHitsRoad(hm)
	for _, p in hm.Shell:GetChildren() do
		if p:IsA("BasePart") and p.CanCollide and hitsRoad(p) then
			return true
		end
	end
	return false
end
local function clearLot(dirs, tag)
	for _, v in Lib.path("DecorativeVehicles"):GetChildren() do
		if v:GetAttribute("Lot") == tag then
			v:Destroy()
		end
	end
	for _, f in { dirs.gardens, dirs.fences, dirs.mailboxes } do
		local m = f:FindFirstChild(tag)
		if m then
			m:Destroy()
		end
	end
	for _, cat in dirs.houses do
		for _, h in cat:GetChildren() do
			if h.Name:sub(1, #tag + 1) == tag .. "_" then
				h:Destroy()
			end
		end
	end
end
local function cleanLot(dirs, tag)
	local n = 0
	for _, f in { dirs.gardens, dirs.fences, dirs.mailboxes } do
		local m = f:FindFirstChild(tag)
		if m then
			for _, c in m:GetChildren() do
				local parts = c:IsA("BasePart") and { c } or c:GetDescendants()
				for _, p in parts do
					if p:IsA("BasePart") and p.Name ~= "Ramp" and p.Name ~= "Slab" and hitsRoad(p) then
						local hit = workspace:GetPartBoundsInBox(p.CFrame, p.Size * 0.92, roadOv)[1]
						local key = c.Name .. ">" .. hit.Name
						removedLog[key] = (removedLog[key] or 0) + 1
						c:Destroy()
						n += 1
						break
					end
				end
			end
		end
	end
	return n
end

return function()
	Lib.MODEL_HOUSE = nil
	local root = Lib.path("ResidentialDistrict")
	local roads = Lib.path("Roads")
	roadOv.FilterDescendantsInstances = { roads.Asphalt, roads.Intersections, roads.Roundabouts, roads.Sidewalks }
	-- sauvegarde des maisons existantes avant remplacement
	local bk = Lib.folder(game:GetService("ServerStorage"), "Backups")
	if not bk:FindFirstChild("ResidentialDistrict_Meshy") then
		local c = root:Clone()
		c.Name = "ResidentialDistrict_Meshy"
		c.Parent = bk
	end
	for _, c in root:GetChildren() do
		c:Destroy()
	end
	for _, v in Lib.path("DecorativeVehicles"):GetChildren() do
		local p = v:GetPivot().Position
		if v:GetAttribute("Lot") or (p.X > -880 and p.X < -20 and p.Z > 20 and p.Z < 700) then
			v:Destroy()
		end
	end
	task.wait()
	HK.installScript()
	local dirs = { houses = {} }
	local hf = Lib.folder(root, "Houses")
	for _, n in { "ClassicHouses", "TwoStoryHouses", "Villas", "ModernHouses", "SmallHouses" } do
		dirs.houses[n] = Lib.folder(hf, n)
	end
	dirs.gardens = Lib.folder(root, "Gardens")
	dirs.fences = Lib.folder(root, "Fences")
	dirs.mailboxes = Lib.folder(root, "Mailboxes")
	dirs.trees = Lib.folder(root, "Trees")

	local BAG = { "classic", "twostory", "twostory", "colonial", "ranch", "farmhouse", "villa", "modern", "modern", "small", "craftsman", "georgian", "cape", "cottage" }
	local bag, last = {}, nil
	local function draw(lw)
		if #bag == 0 then
			for _, n in BAG do
				table.insert(bag, n)
			end
		end
		for _ = 1, 30 do
			local i = rng:NextInteger(1, #bag)
			local n = bag[i]
			if n ~= last and TYPES[n].W[1] <= lw - 8 then
				table.remove(bag, i)
				last = n
				return n
			end
		end
		last = "classic"
		return "classic"
	end

	local n, used, fixed, lastPal = 0, {}, 0, nil
	for i = 1, #XS - 1 do
		for j = 1, #ZS - 1 do
			if not (i == 3 and j == 3) then
				local x1, x2 = edge(XS[i][1], XS[i][2], 1), edge(XS[i + 1][1], XS[i + 1][2], -1)
				local z1, z2 = edge(ZS[j][1], ZS[j][2], 1), edge(ZS[j + 1][1], ZS[j + 1][2], -1)
				local bw, bd = x2 - x1, z2 - z1
				local nLots = math.max(2, math.floor(bw / 58)) -- parcelles plus larges pour des maisons plus grandes
				local lw = bw / nLots
				local ld = bd / 2
				for row = 0, 1 do
					for k = 1, nLots do
						local x = x1 + lw * (k - 0.5)
						local lotCf = row == 0 and CFrame.lookAt(V(x, 0, z1), V(x, 0, z1 - 1)) or CFrame.lookAt(V(x, 0, z2), V(x, 0, z2 + 1))
						local typ = draw(lw)
						local tag = ("Lot_%d_%d_%d"):format(i, j, k + row * nLots)
						local hm, pal = buildLot(dirs, lotCf, lw, ld, typ, tag, 0, lastPal)
						local t = 0
						while hm and houseHitsRoad(hm) and t < 3 do
							t += 1
							clearLot(dirs, tag)
							typ = "small"
							hm, pal = buildLot(dirs, lotCf, lw, ld, typ, tag, t * 6, lastPal)
						end
						if hm and houseHitsRoad(hm) then
							clearLot(dirs, tag)
							removedLog["House"] = (removedLog["House"] or 0) + 1
						else
							used[typ] = (used[typ] or 0) + 1
							n += 1
						end
						lastPal = pal
						fixed += cleanLot(dirs, tag)
						task.wait()
					end
				end
			end
		end
	end
	for _, v in Lib.path("DecorativeVehicles"):GetChildren() do
		if v:GetAttribute("Lot") then
			local cf, sz = v:GetBoundingBox()
			if #workspace:GetPartBoundsInBox(cf, sz * 0.85, roadOv) > 0 then
				v:Destroy()
				removedLog["Car"] = (removedLog["Car"] or 0) + 1
			end
		end
	end
	local log, kinds = {}, {}
	for k, v in removedLog do
		table.insert(log, k .. "=" .. v)
	end
	for k, v in used do
		table.insert(kinds, k .. "=" .. v)
	end
	return ("modèle=" .. tostring(Lib.MODEL_HOUSE) .. " ; maisons : %d (%s), %d éléments retirés des routes (%s)"):format(n, table.concat(kinds, ", "), fixed, table.concat(log, ", "))
end
