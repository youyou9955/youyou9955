--!nolint
-- 12 : quartier résidentiel avec les 18 maisons Meshy (ReplicatedStorage.Assets.Houses). Remplace les maisons
-- en pièces de 05 ; les jardins, clôtures, allées, boîtes aux lettres, arbres et stationnements sont construits
-- ici, en pièces, avec un style propre à chaque catégorie de maison (classique, à étage, villa, moderne, petite).
-- Repère d'un terrain : -Z local vers la rue, +X local = gauche vue depuis la rue.
local Lib = require(script.Parent.Lib)
local Plan = require(script.Parent.Plan)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C

local rng = Random.new(1212)
local HOUSES = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Houses")

-- w : largeur de façade (studs) ; rot : rotation (degrés) pour tourner la façade du maillage vers -Z ;
-- garage : côté du garage vu depuis la rue ("left" / "right") et position (fraction de la largeur depuis le centre)
local META = {
	Classic1 = { cat = "ClassicHouses", w = 26, rot = 0 },
	Classic2 = { cat = "ClassicHouses", w = 28, rot = 0, garage = "right", gx = 0.32 },
	Classic3 = { cat = "ClassicHouses", w = 24, rot = 0 },
	Classic4 = { cat = "ClassicHouses", w = 32, rot = 0, garage = "left", gx = 0.3 },
	Classic5 = { cat = "ClassicHouses", w = 28, rot = 0 },
	TwoStory1 = { cat = "TwoStoryHouses", w = 28, rot = 0, garage = "right", gx = 0.3 },
	TwoStory2 = { cat = "TwoStoryHouses", w = 28, rot = 0 },
	TwoStory3 = { cat = "TwoStoryHouses", w = 26, rot = 0 },
	TwoStory4 = { cat = "TwoStoryHouses", w = 28, rot = 0, garage = "left", gx = 0.3 },
	Villa1 = { cat = "Villas", w = 38, rot = 0 },
	Villa2 = { cat = "Villas", w = 40, rot = 0, garage = "right", gx = 0.34 },
	Villa3 = { cat = "Villas", w = 34, rot = 0, garage = "right", gx = 0.22 },
	Modern1 = { cat = "ModernHouses", w = 30, rot = 0, garage = "left", gx = 0.3 },
	Modern2 = { cat = "ModernHouses", w = 26, rot = 0 },
	Modern3 = { cat = "ModernHouses", w = 28, rot = 0, garage = "right", gx = 0.15 },
	Small1 = { cat = "SmallHouses", w = 20, rot = 0 },
	Small2 = { cat = "SmallHouses", w = 20, rot = 0 },
	Small3 = { cat = "SmallHouses", w = 20, rot = 0 },
}
Lib.HOUSE_META = META

local XS = { { -900, "ring" }, { -720, "res" }, { -480, "res" }, { -240, "res" }, { 0, "main" } }
local ZS = { { 0, "main" }, { 180, "res" }, { 360, "res" }, { 540, "res" }, { 720, "ring" } }
local function edge(v, kind, s)
	return v + s * (Plan.W[kind] / 2 + Plan.SW[kind])
end
local function pick(t)
	return t[rng:NextInteger(1, #t)]
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
		local col = pick({ rgb(220, 50, 40), rgb(40, 90, 180), rgb(40, 130, 70), rgb(240, 240, 240), rgb(40, 40, 46) })
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
		Lib.fine(m, tc * CFrame.new(0, 1.2, 1.9) * CFrame.Angles(math.rad(-35), 0, 0), V(2.2, 0.3, 1.8), pick({ rgb(250, 120, 60), rgb(60, 160, 230), rgb(250, 210, 60) }), M.Fabric)
	end
	return m
end

local function swing(parent, cf)
	local m = Lib.model(parent, "Swing")
	local col = pick({ rgb(220, 70, 60), rgb(60, 140, 220), rgb(240, 180, 40) })
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
	Lib.cyl(m, cf * CFrame.new(0, 2.2, 0), 0.5, 11, rgb(40, 120, 220), M.SmoothPlastic)
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
	Lib.cylDeco(m, cf * CFrame.new(0, 5, 0), 0.4, 7, pick({ rgb(240, 90, 70), rgb(60, 170, 220), rgb(250, 210, 70) }), M.Fabric)
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

---------------------------------------------------------------- une maison Meshy sur son terrain
local function placeMesh(folder, name, cf, w)
	local src = HOUSES:FindFirstChild(name)
	local meta = META[name]
	local rot = CFrame.Angles(0, math.rad(meta.rot or 0), 0)
	local m = src:Clone()
	-- taille : la largeur de façade (axe X après rotation) vaut w
	local s = src.Size
	local facadeX = ((meta.rot or 0) % 180 == 0) and s.X or s.Z
	local k = w / facadeX
	m.Size = s * k
	local depth = ((meta.rot or 0) % 180 == 0) and m.Size.Z or m.Size.X
	m.CFrame = cf * CFrame.new(0, m.Size.Y / 2 - 0.15, 0) * rot
	m.Anchored = true
	m.CanCollide = false
	m.CanTouch = false
	m.CanQuery = true
	m.CastShadow = true
	pcall(function()
		m.RenderFidelity = Enum.RenderFidelity.Automatic
		m.CollisionFidelity = Enum.CollisionFidelity.Box
	end)
	m.Name = "Mesh"
	local hm = Instance.new("Model")
	hm.Name = name
	m.Parent = hm
	-- collision simple : une boîte invisible un peu plus petite que l'emprise (laisse passer sous les avancées)
	Lib.part(hm, cf * CFrame.new(0, m.Size.Y * 0.4, 0), V(w * 0.86, m.Size.Y * 0.8, depth * 0.82), Color3.new(), M.SmoothPlastic, { Transparency = 1, Name = "Collision", CastShadow = false, CanTouch = false })
	hm.PrimaryPart = m
	hm.Parent = folder
	hm:SetAttribute("Source", "Meshy AI")
	return hm, depth, m.Size.Y
end

local STYLE = {
	ClassicHouses = { fence = { "picket", "picket", "hedge" }, mailbox = "classic", tree = "round" },
	TwoStoryHouses = { fence = { "hedge", "picket", "lowwall" }, mailbox = "classic", tree = "round" },
	Villas = { fence = { "villa" }, mailbox = "stone", tree = "palm" },
	ModernHouses = { fence = { "modern", "none" }, mailbox = "modern", tree = "pine" },
	SmallHouses = { fence = { "wood", "picket", "none" }, mailbox = "classic", tree = "round" },
}

local function buildLot(dirs, lotCf, lw, ld, name, tag, extraSetback)
	local meta = META[name]
	local style = STYLE[meta.cat]
	local w = math.min(meta.w, lw - 12)
	local setback = (meta.cat == "Villas" and rng:NextNumber(14, 16) or rng:NextNumber(12, 16)) + (extraSetback or 0)
	-- garage : décale la maison pour laisser l'allée
	local garage = meta.garage
	local hx = 0
	if not garage and w < lw - 26 then
		hx = (rng:NextNumber() < 0.5 and -1 or 1) * rng:NextNumber(2, 5)
	end
	local tmpCf = lotCf * CFrame.new(hx, 0, 0)
	-- façade vers la rue : on place d'abord pour connaître la profondeur
	local houseFolder = dirs.houses[meta.cat]
	local hm, depth, height = placeMesh(houseFolder, name, CFrame.new(), w)
	local center = lotCf * CFrame.new(hx, 0, setback + depth / 2)
	local face = CFrame.lookAt(center.Position, center.Position + lotCf.LookVector)
	hm:PivotTo(face * CFrame.new(0, hm.PrimaryPart.Size.Y / 2 - 0.15, 0) * CFrame.Angles(0, math.rad(meta.rot or 0), 0))
	hm.Name = tag .. "_" .. name

	local garden = Lib.model(dirs.gardens, tag)
	local L, R = -lw / 2 + 0.6, lw / 2 - 0.6
	local sw = Plan.SW.res
	-- garage ou place de stationnement : x local du garage (+X = gauche vu de la rue)
	local gx
	if garage then
		gx = hx + (garage == "left" and 1 or -1) * (meta.gx or 0.3) * w
	else
		local side = hx >= 0 and -1 or 1
		gx = hx + side * (w / 2 + 6)
		if math.abs(gx) > lw / 2 - 6 then
			gx = nil
		end
	end
	local dw = meta.cat == "Villas" and 14 or 10
	if gx then
		local dl = setback + (garage and 0.5 or depth * 0.6)
		local mat = meta.cat == "ModernHouses" and M.Concrete or (meta.cat == "Villas" and M.Pavement or M.Concrete)
		local col = meta.cat == "Villas" and rgb(214, 200, 178) or rgb(192, 190, 184)
		Lib.part(garden, lotCf * CFrame.new(gx, 0.15, dl / 2), V(dw, 0.3, dl), col, mat, { Name = "Driveway" })
		Lib.driveway(garden, lotCf * CFrame.new(gx, 0, -sw) * CFrame.Angles(0, math.pi, 0), dw, sw)
		if rng:NextNumber() < 0.7 then
			local ccf = lotCf * CFrame.new(gx, 0.3, setback - 7.5) * CFrame.Angles(0, rng:NextNumber() < 0.5 and 0 or math.pi, 0)
			local car
			if rng:NextNumber() < 0.5 then
				car = Lib.toyCar(Lib.path("DecorativeVehicles"), ccf)
			else
				car = Lib.vehicle("Car", Lib.path("DecorativeVehicles"), ccf)
			end
			if car then
				car:SetAttribute("Lot", tag)
			end
		end
		bins(garden, lotCf * CFrame.new(gx + (gx >= hx and 1 or -1) * (dw / 2 + 2), 0, setback - 2) * CFrame.Angles(0, math.pi, 0))
	else
		bins(garden, lotCf * CFrame.new(hx + w / 2 + 3, 0, setback + 2))
	end

	-- allée piétonne vers la porte (au centre de la façade, hors garage)
	local doorX = hx
	if garage then
		doorX = hx - (garage == "left" and 1 or -1) * 0.12 * w
	end
	local pathMat = pick({ M.Pavement, M.Slate, M.Brick })
	local pathCol = pathMat == M.Brick and rgb(196, 120, 96) or rgb(206, 196, 180)
	if meta.cat == "ModernHouses" then
		-- dalles espacées
		for z = 1.5, setback - 1, 2.6 do
			Lib.fine(garden, lotCf * CFrame.new(doorX, 0.12, z), V(4, 0.25, 1.8), rgb(220, 220, 216), M.Concrete)
		end
	else
		Lib.fine(garden, lotCf * CFrame.new(doorX, 0.12, setback / 2), V(meta.cat == "Villas" and 5 or 3.6, 0.25, setback), pathCol, pathMat, { Name = "Path" })
	end

	-- boîte aux lettres
	Lib.yield(2)
	mailbox(dirs.mailboxes, lotCf * CFrame.new(doorX + 3.2, 0, 1.6) * CFrame.Angles(0, math.pi, 0), style.mailbox).Name = tag

	-- clôture avant (avec ouvertures pour l'allée et le garage)
	local ftype = pick(style.fence)
	local cuts = { { doorX - (meta.cat == "Villas" and 3.2 or 2.2), doorX + (meta.cat == "Villas" and 3.2 or 2.2) } }
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
	local fcol = pick({ C.white, C.white, rgb(250, 236, 200), rgb(200, 226, 240) })
	for _, s in segs do
		local a = (lotCf * CFrame.new(s[1], 0, 0.8)).Position
		local b = (lotCf * CFrame.new(s[2], 0, 0.8)).Position
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
			lowWall(fence, a, b, 2, rgb(196, 150, 120), M.Brick)
		elseif ftype == "villa" then
			lowWall(fence, a, b, 2.2, rgb(214, 200, 176), M.Sandstone)
			Lib.fence(fence, a + V(0, 2.4, 0), b + V(0, 2.4, 0), "metal", 3)
		elseif ftype == "modern" then
			lowWall(fence, a, b, 1.4, rgb(210, 210, 206), M.Concrete)
		elseif ftype == "wood" then
			local f = Lib.fence(fence, a, b, "picket", 3.4)
			for _, p in f:GetDescendants() do
				if p:IsA("BasePart") and p.Transparency < 1 then
					p.Color = rgb(150, 104, 66)
					p.Material = M.WoodPlanks
				end
			end
		end
	end
	if ftype == "villa" then
		gatePillars(fence, lotCf * CFrame.new(doorX, 0, 0.8), 3.4, rgb(214, 200, 176), M.Sandstone, 5)
		gardenLamp(garden, lotCf * CFrame.new(doorX - 4.5, 0, 2.4), false)
		gardenLamp(garden, lotCf * CFrame.new(doorX + 4.5, 0, 2.4), false)
	elseif ftype == "picket" or ftype == "wood" then
		gatePillars(fence, lotCf * CFrame.new(doorX, 0, 0.8), 2.4, fcol, M.SmoothPlastic, 3.6)
	elseif ftype == "hedge" or ftype == "lowwall" then
		gatePillars(fence, lotCf * CFrame.new(doorX, 0, 0.8), 2.4, rgb(196, 150, 120), M.Brick, 3.4)
	end

	-- haies de séparation latérales (une sur deux) et haie du fond
	if rng:NextNumber() < 0.6 then
		Lib.hedge(fence, (lotCf * CFrame.new(R, 0, 3)).Position, (lotCf * CFrame.new(R, 0, ld - 2)).Position, 3.2, 1.6)
	end
	if rng:NextNumber() < 0.35 then
		Lib.fence(fence, (lotCf * CFrame.new(L + 0.4, 0, ld - 1)).Position, (lotCf * CFrame.new(R - 0.4, 0, ld - 1)).Position, "picket", 3.4)
	end

	-- plantations devant la maison
	local front = setback - 1.2
	if meta.cat == "ModernHouses" then
		-- bande de gravier et jardinières
		Lib.fine(garden, lotCf * CFrame.new(hx, 0.1, front), V(w * 0.9, 0.2, 2.4), rgb(200, 198, 192), M.Pebble)
		for _, x in { -w * 0.3, w * 0.3 } do
			if not gx or math.abs(hx + x - gx) > dw / 2 + 2 then
				Lib.planter(garden, lotCf * CFrame.new(hx + x, 0, front - 2) * CFrame.Angles(0, math.pi, 0))
			end
		end
		gardenLamp(garden, lotCf * CFrame.new(doorX - 2.6, 0, setback * 0.5), true)
		gardenLamp(garden, lotCf * CFrame.new(doorX + 2.6, 0, setback * 0.5), true)
	else
		for _, s in { -1, 1 } do
			local x0, x1 = doorX + s * 2.6, doorX + s * (w / 2 - 1)
			if gx and ((s > 0 and gx > doorX) or (s < 0 and gx < doorX)) then
				x1 = gx - s * (dw / 2 + 0.8)
			end
			if math.abs(x1 - x0) > 2 then
				flowerRow(garden, (lotCf * CFrame.new(x0, 0, front)).Position, (lotCf * CFrame.new(x1, 0, front)).Position, 2)
			end
		end
		for k = -1, 1, 2 do
			Lib.bush(garden, (lotCf * CFrame.new(doorX + k * 3.2, 0, 2.6)).Position, rng:NextNumber(2.2, 3))
		end
	end

	-- arbres
	local tx = gx and (gx > hx and L + 6 or R - 6) or (hx > 0 and R - 6 or L + 6)
	if style.tree == "palm" then
		Lib.tree(dirs.trees, (lotCf * CFrame.new(tx, 0, setback * 0.5)).Position, "palm", rng:NextNumber(18, 24))
		Lib.tree(dirs.trees, (lotCf * CFrame.new(tx * 0.7, 0, setback + depth + 6)).Position, "palm", rng:NextNumber(16, 22))
	elseif style.tree == "pine" then
		Lib.tree(dirs.trees, (lotCf * CFrame.new(tx, 0, setback * 0.55)).Position, "pine", rng:NextNumber(16, 22))
	else
		Lib.tree(dirs.trees, (lotCf * CFrame.new(tx, 0, setback * 0.5)).Position, "round", rng:NextNumber(12, 17))
	end

	-- jardin arrière : un aménagement selon la catégorie
	local back = setback + depth + 3
	local room = ld - back
	local bx = -hx * 0.5
	if room > 12 then
		local r = rng:NextNumber()
		local cat = meta.cat
		if cat == "Villas" or (cat == "ModernHouses" and r < 0.6) then
			pool(garden, lotCf * CFrame.new(bx, 0, back + room / 2 + 1), math.min(16, lw - 18), math.min(9, room - 9))
		elseif cat == "SmallHouses" then
			veggies(garden, lotCf * CFrame.new(bx - 6, 0, back + room / 2), 9, math.min(8, room - 4))
			Lib.bench(garden, lotCf * CFrame.new(bx + 8, 0, back + 3) * CFrame.Angles(0, math.pi, 0))
		elseif r < 0.35 then
			swing(garden, lotCf * CFrame.new(bx + lw / 5, 0, back + room / 2))
		elseif r < 0.6 then
			trampoline(garden, lotCf * CFrame.new(bx - lw / 6, 0, back + room / 2))
		elseif r < 0.85 then
			patioSet(garden, lotCf * CFrame.new(bx, 0, back + 4.5))
		else
			veggies(garden, lotCf * CFrame.new(bx, 0, back + room / 2), 10, math.min(8, room - 4))
		end
		if room > 18 then
			Lib.tree(dirs.trees, (lotCf * CFrame.new(rng:NextNumber() < 0.5 and L + 6 or R - 6, 0, ld - 6)).Position, rng:NextNumber() < 0.6 and "round" or "pine")
		end
	end
	return hm
end


---------------------------------------------------------------- terrains d'angle : rien ne doit empiéter sur les routes
local roadOv = OverlapParams.new()
roadOv.FilterType = Enum.RaycastFilterType.Include
local function hitsRoad(p)
	return #workspace:GetPartBoundsInBox(p.CFrame, p.Size * 0.92, roadOv) > 0
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
	-- supprime les éléments de jardin, clôtures, boîte aux lettres qui touchent une chaussée ou un trottoir
	local n = 0
	for _, f in { dirs.gardens, dirs.fences, dirs.mailboxes } do
		local m = f:FindFirstChild(tag)
		if m then
			for _, c in m:GetChildren() do
				local parts = c:IsA("BasePart") and { c } or c:GetDescendants()
				for _, p in parts do
					if p:IsA("BasePart") and p.Name ~= "Ramp" and p.Name ~= "Slab" and hitsRoad(p) then
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
	local root = Lib.path("ResidentialDistrict")
	local roads = Lib.path("Roads")
	roadOv.FilterDescendantsInstances = { roads.Asphalt, roads.Intersections, roads.Roundabouts, roads.Sidewalks }
	-- retire les maisons en pièces de 05 (et les voitures garées dans leurs allées)
	for _, c in root:GetChildren() do
		c:Destroy()
	end
	for _, v in Lib.path("DecorativeVehicles"):GetChildren() do
		local p = v:GetPivot().Position
		if p.X > -880 and p.X < -20 and p.Z > 20 and p.Z < 700 then
			v:Destroy()
		end
	end
	task.wait()
	local dirs = { houses = {} }
	local hf = Lib.folder(root, "Houses")
	for _, n in { "ClassicHouses", "TwoStoryHouses", "Villas", "ModernHouses", "SmallHouses" } do
		dirs.houses[n] = Lib.folder(hf, n)
	end
	dirs.gardens = Lib.folder(root, "Gardens")
	dirs.fences = Lib.folder(root, "Fences")
	dirs.mailboxes = Lib.folder(root, "Mailboxes")
	dirs.trees = Lib.folder(root, "Trees")

	-- sac de modèles : chaque maison sort au moins une fois avant de se répéter, sans voisins identiques
	local names = {}
	for n in META do
		if HOUSES:FindFirstChild(n) then
			table.insert(names, n)
		end
	end
	table.sort(names)
	local bag, last = {}, nil
	local function draw(lw)
		if #bag == 0 then
			for _, n in names do
				table.insert(bag, n)
			end
		end
		for tries = 1, 20 do
			local i = rng:NextInteger(1, #bag)
			local n = bag[i]
			if n ~= last and META[n].w <= lw - 10 then
				table.remove(bag, i)
				last = n
				return n
			end
		end
		local n = table.remove(bag, 1)
		last = n
		return n
	end

	local n, used, fixed = 0, {}, 0
	for i = 1, #XS - 1 do
		for j = 1, #ZS - 1 do
			if not (i == 3 and j == 3) then
				local x1, x2 = edge(XS[i][1], XS[i][2], 1), edge(XS[i + 1][1], XS[i + 1][2], -1)
				local z1, z2 = edge(ZS[j][1], ZS[j][2], 1), edge(ZS[j + 1][1], ZS[j + 1][2], -1)
				local bw, bd = x2 - x1, z2 - z1
				local nLots = math.max(2, math.floor(bw / 46))
				local lw = bw / nLots
				local ld = bd / 2
				for row = 0, 1 do
					for k = 1, nLots do
						local x = x1 + lw * (k - 0.5)
						local lotCf = row == 0 and CFrame.lookAt(V(x, 0, z1), V(x, 0, z1 - 1)) or CFrame.lookAt(V(x, 0, z2), V(x, 0, z2 + 1))
						local name = draw(lw)
						local tag = ("Lot_%d_%d_%d"):format(i, j, k + row * nLots)
						local hm = buildLot(dirs, lotCf, lw, ld, name, tag)
						-- terrain d'angle : maison qui touche la route -> petite maison plus en retrait
						local tries = { { "Small1", 6 }, { "Small2", 12 }, { "Small3", 18 } }
						local t = 0
						while hm and hitsRoad(hm.Collision) and t < #tries do
							t += 1
							clearLot(dirs, tag)
							name = tries[t][1]
							hm = buildLot(dirs, lotCf, lw, ld, name, tag, tries[t][2])
						end
						if hm and hitsRoad(hm.Collision) then
							hm:Destroy()
						end
						fixed += cleanLot(dirs, tag)
						used[name] = (used[name] or 0) + 1
						n += 1
						task.wait()
					end
				end
			end
		end
	end
	local kinds = 0
	for _ in used do
		kinds += 1
	end
	return ("maisons Meshy : %d terrains, %d modèles différents, %d éléments retirés des routes"):format(n, kinds, fixed)
end
