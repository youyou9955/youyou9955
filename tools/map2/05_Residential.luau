--!nolint
-- 05 : quartier résidentiel (x -900..0, z 0..720). Maisons individuelles toutes différentes (taille, étages,
-- toit, couleurs, garage, porche, volets), jardins, allées, boîtes aux lettres, clôtures, haies, poubelles,
-- voitures garées, piscines, balançoires. Un îlot devient le parc des Petits Livreurs.
local Lib = require(script.Parent.Lib)
local Build = require(script.Parent.Build)
local Plan = require(script.Parent.Plan)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C

local rng = Random.new(505)
local XS = { { -900, "ring" }, { -720, "res" }, { -480, "res" }, { -240, "res" }, { 0, "main" } }
local ZS = { { 0, "main" }, { 180, "res" }, { 360, "res" }, { 540, "res" }, { 720, "ring" } }
local function edge(v, kind, s)
	return v + s * (Plan.W[kind] / 2 + Plan.SW[kind])
end
local function pick(t)
	return t[rng:NextInteger(1, #t)]
end

local function bins(parent, cf)
	for k, col in { rgb(40, 120, 60), rgb(250, 200, 40) } do
		local b = Lib.part(parent, cf * CFrame.new((k - 1.5) * 2, 1.6, 0), V(1.8, 3.2, 1.8), col, M.SmoothPlastic, { Name = "Bin", CanTouch = false })
		Lib.fine(parent, b.CFrame * CFrame.new(0, 1.7, 0.1), V(2, 0.3, 2.1), col:Lerp(Color3.new(0, 0, 0), 0.2), M.SmoothPlastic)
	end
end

local function swing(parent, cf)
	local m = Lib.model(parent, "Swing")
	local col = rgb(220, 70, 60)
	for _, x in { -4, 4 } do
		Lib.part(m, cf * CFrame.new(x, 4, -1.5) * CFrame.Angles(math.rad(12), 0, 0), V(0.6, 8.4, 0.6), col, M.Metal)
		Lib.part(m, cf * CFrame.new(x, 4, 1.5) * CFrame.Angles(math.rad(-12), 0, 0), V(0.6, 8.4, 0.6), col, M.Metal)
	end
	Lib.fine(m, cf * CFrame.new(0, 8, 0), V(9, 0.5, 0.5), col, M.Metal)
	for _, x in { -1.8, 1.8 } do
		Lib.fine(m, cf * CFrame.new(x, 2.4, 0), V(1.8, 0.3, 1), rgb(60, 120, 220), M.SmoothPlastic)
		for _, s in { -0.8, 0.8 } do
			Lib.fine(m, cf * CFrame.new(x + s, 5.2, 0), V(0.1, 5.6, 0.1), C.dark, M.Metal)
		end
	end
end

local function pool(parent, cf, w, d)
	local m = Lib.model(parent, "Pool")
	Lib.part(m, cf * CFrame.new(0, 0.35, 0), V(w + 3, 0.7, d + 3), rgb(236, 232, 222), M.Concrete)
	Lib.fine(m, cf * CFrame.new(0, 0.72, 0), V(w, 0.1, d), rgb(70, 200, 240), M.Glass, { Transparency = 0.1, Reflectance = 0.2 })
	Lib.fine(m, cf * CFrame.new(w / 2 + 0.8, 1.2, d / 2 - 2), V(1.2, 1.2, 0.2), C.white, M.Metal)
	return m
end

local function house(block, lotCf, lw, ld, idx)
	-- lotCf : centre du bord avant du terrain (au sol), LookVector vers la rue
	local floors = rng:NextNumber() < 0.55 and 2 or 1
	local garage = rng:NextNumber() < 0.55 and (rng:NextNumber() < 0.5 and "left" or "right") or nil
	local maxW = lw - 8 - (garage and 12 or 0)
	local w = math.clamp(math.floor(rng:NextNumber(18, 24)), 16, maxW)
	local d = math.floor(rng:NextNumber(15, 19))
	local setback = rng:NextNumber(13, 17)
	local hx = garage == "left" and 6 or (garage == "right" and -6 or 0)
	local o = {
		w = w, d = d, floors = floors,
		wall = pick(Build.WALLS), roof = pick(Build.ROOFS), door = pick(Build.DOORS),
		trim = C.trim,
		garage = garage,
		porch = rng:NextNumber() < 0.5,
		chimney = rng:NextNumber() < 0.5,
		ridgeZ = floors == 1 and rng:NextNumber() < 0.35,
		wing = floors == 2 and not garage and rng:NextNumber() < 0.5,
		shutters = rng:NextNumber() < 0.45 and pick({ rgb(255, 255, 255), rgb(60, 110, 160), rgb(60, 120, 80), rgb(150, 60, 50) }) or nil,
		flowerBoxes = rng:NextNumber() < 0.4,
	}
	if o.wing then
		o.doorX = w / 4
	end
	local hcf = lotCf * CFrame.new(hx, 0, setback + d / 2 + (o.wing and 6 or 0)) * CFrame.Angles(0, math.pi, 0)
	-- hcf : façade (LookVector) vers la rue
	hcf = CFrame.lookAt(hcf.Position, hcf.Position + lotCf.LookVector)
	local h = Build.house(block, hcf, o)
	h.Name = "House_" .. idx
	local yard = Lib.model(h, "Yard")
	-- allée piétonne
	local doorX = hx + (o.doorX or 0)
	local pathLen = setback + (o.wing and 6 or 0) - (o.porch and 6 or 1.6)
	Lib.fine(yard, lotCf * CFrame.new(doorX, 0.12, pathLen / 2), V(3.4, 0.25, pathLen), rgb(200, 190, 176), M.Pavement)
	-- boîte aux lettres
	Lib.mailbox(yard, lotCf * CFrame.new(doorX + 3.5, 0, 1.6))
	-- garage : allée carrossable + rampe dans le trottoir + voiture
	local gx
	if garage then
		gx = hx + (garage == "left" and -1 or 1) * (w / 2 + 6)
		local dl = setback + 1
		Lib.fine(yard, lotCf * CFrame.new(gx, 0.15, dl / 2), V(10, 0.3, dl), rgb(190, 188, 182), M.Concrete)
		local sw = Plan.SW.res
		Lib.driveway(yard, lotCf * CFrame.new(gx, 0, -sw) * CFrame.Angles(0, math.pi, 0), 10, sw)
		if rng:NextNumber() < 0.6 then
			Lib.vehicle("Car", Lib.path("DecorativeVehicles"), lotCf * CFrame.new(gx, 0.3, setback - 6) * CFrame.Angles(0, rng:NextNumber() < 0.5 and 0 or math.pi, 0))
		end
		bins(yard, lotCf * CFrame.new(gx + (garage == "left" and -6.5 or 6.5), 0, setback - 2))
	else
		bins(yard, lotCf * CFrame.new(hx + w / 2 + 3, 0, setback + 2))
	end
	-- clôture avant ou haie (avec portail)
	local style = rng:NextNumber()
	local L, R = -lw / 2 + 0.6, lw / 2 - 0.6
	local segs = {}
	local cuts = { { doorX - 2, doorX + 2 } }
	if gx then
		table.insert(cuts, { gx - 5.5, gx + 5.5 })
	end
	table.sort(cuts, function(a, b)
		return a[1] < b[1]
	end)
	local cur = L
	for _, c in cuts do
		if c[1] > cur + 1 then
			table.insert(segs, { cur, c[1] })
		end
		cur = c[2]
	end
	if R > cur + 1 then
		table.insert(segs, { cur, R })
	end
	for _, s in segs do
		local a = (lotCf * CFrame.new(s[1], 0, 0.8)).Position
		local b = (lotCf * CFrame.new(s[2], 0, 0.8)).Position
		if style < 0.45 then
			Lib.fence(yard, a, b, "picket", 3)
		elseif style < 0.85 then
			Lib.hedge(yard, a, b, 2.6, 1.8)
		end
	end
	if style < 0.45 then
		-- portail : deux piliers
		for _, s in { -2, 2 } do
			Lib.part(yard, lotCf * CFrame.new(doorX + s, 1.8, 0.8), V(0.8, 3.6, 0.8), C.white, M.SmoothPlastic)
		end
	end
	-- haies de séparation (côté droit du terrain)
	if idx % 2 == 0 then
		Lib.hedge(yard, (lotCf * CFrame.new(R, 0, 2)).Position, (lotCf * CFrame.new(R, 0, ld - 2)).Position, 3, 1.6)
	end
	-- jardin : arbre devant, buissons, arbre au fond, piscine ou balançoire
	Lib.tree(yard, (lotCf * CFrame.new(gx and -gx * 0.6 or (doorX - 9), 0, setback * 0.5)).Position, "round", rng:NextNumber(12, 17))
	for k = -1, 1, 2 do
		Lib.bush(yard, (lotCf * CFrame.new(doorX + k * 4.5, 0, setback - 0.8)).Position, 2.6)
	end
	local back = setback + d + (o.wing and 6 or 0) + 4
	local room = ld - back
	if room > 12 then
		local r = rng:NextNumber()
		if r < 0.25 then
			pool(yard, lotCf * CFrame.new(-hx * 0.5, 0, back + room / 2), math.min(14, lw - 14), math.min(8, room - 5))
		elseif r < 0.4 then
			swing(yard, lotCf * CFrame.new(lw / 4, 0, back + room / 2))
		end
		Lib.tree(yard, (lotCf * CFrame.new(-lw / 3, 0, ld - 5)).Position, rng:NextNumber() < 0.6 and "round" or "pine")
	end
end

return function()
	local root = Lib.path("ResidentialDistrict")
	local n = 0
	for i = 1, #XS - 1 do
		for j = 1, #ZS - 1 do
			local x1, x2 = edge(XS[i][1], XS[i][2], 1), edge(XS[i + 1][1], XS[i + 1][2], -1)
			local z1, z2 = edge(ZS[j][1], ZS[j][2], 1), edge(ZS[j + 1][1], ZS[j + 1][2], -1)
			local bw, bd = x2 - x1, z2 - z1
			local cx, cz = (x1 + x2) / 2, (z1 + z2) / 2
			local block = Lib.model(root, ("Block_%d_%d"):format(i, j))
			if i == 3 and j == 3 then
				-- Parc des Petits Livreurs
				local pm = Lib.model(Lib.path("Landmarks"), "ParcDesPetitsLivreurs")
				Lib.part(pm, CFrame.new(cx, 0.3, cz), V(bw, 0.6, bd), C.grass, M.Grass)
				-- étang
				Lib.cyl(pm, CFrame.new(cx - bw / 4, 0.55, cz), 0.6, 44, rgb(226, 212, 170), M.Sand)
				Lib.cylDeco(pm, CFrame.new(cx - bw / 4, 0.7, cz), 0.5, 38, rgb(60, 170, 220), M.Glass, { Transparency = 0.15, Reflectance = 0.2 })
				-- allées
				Lib.fine(pm, CFrame.new(cx, 0.65, cz), V(bw - 4, 0.12, 6), rgb(226, 206, 160), M.Sand)
				Lib.fine(pm, CFrame.new(cx + bw / 5, 0.65, cz), V(6, 0.12, bd - 4), rgb(226, 206, 160), M.Sand)
				-- aire de jeux
				local pg = CFrame.new(cx + bw / 3, 0.6, cz - bd / 4)
				Lib.part(pm, pg * CFrame.new(0, 0.1, 0), V(36, 0.3, 30), rgb(236, 120, 80), M.Rubber)
				swing(pm, pg * CFrame.new(-8, 0.25, -6))
				-- toboggan
				Lib.part(pm, pg * CFrame.new(8, 4, 4), V(4, 8, 4), rgb(60, 140, 230), M.SmoothPlastic)
				Lib.part(pm, pg * CFrame.new(8, 4, -2.5) * CFrame.Angles(math.rad(-50), 0, 0), V(2.6, 0.4, 11), rgb(255, 200, 40), M.SmoothPlastic)
				Lib.part(pm, pg * CFrame.new(8, 8.6, 4), V(5, 1.2, 5), rgb(230, 60, 60), M.SmoothPlastic)
				-- bac à sable
				Lib.part(pm, pg * CFrame.new(-8, 0.5, 8), V(10, 0.6, 8), rgb(240, 220, 160), M.Sand)
				for k = 1, 22 do
					local p = V(cx + rng:NextNumber(-bw / 2 + 6, bw / 2 - 6), 0.6, cz + rng:NextNumber(-bd / 2 + 6, bd / 2 - 6))
					if math.abs(p.Z - cz) > 6 and math.abs(p.X - cx - bw / 5) > 6 and (p - V(cx - bw / 4, 0.6, cz)).Magnitude > 26 and (p - (pg.Position)).Magnitude > 24 then
						Lib.tree(pm, p, rng:NextNumber() < 0.75 and "round" or "pine")
					end
				end
				for k = 0, 5 do
					Lib.bench(pm, Lib.facing(V(cx - bw / 2 + 20 + k * 30, 0.6, cz + 5), V(0, 0, -1)))
				end
				local s = Lib.sign(pm, Lib.facing(V(cx, 6, z1 + 3), V(0, 0, -1)), V(26, 4, 0.6), "PARC DES PETITS LIVREURS", rgb(60, 140, 60), C.white)
				for _, x in { -11, 11 } do
					Lib.part(pm, CFrame.new(cx + x, 2.5, z1 + 3), V(0.8, 5, 0.8), rgb(120, 80, 50), M.Wood)
				end
			else
				-- deux rangées : nord (façades vers le nord) et sud (vers le sud)
				local nLots = math.max(2, math.floor(bw / 46))
				local lw = bw / nLots
				local ld = bd / 2
				for row = 0, 1 do
					for k = 1, nLots do
						local x = x1 + lw * (k - 0.5)
						local lotCf
						if row == 0 then
							lotCf = Lib.facing(V(x, 0, z1), V(0, 0, -1)) * CFrame.Angles(0, math.pi, 0)
							lotCf = CFrame.lookAt(V(x, 0, z1), V(x, 0, z1 - 1)) -- regarde la rue nord
						else
							lotCf = CFrame.lookAt(V(x, 0, z2), V(x, 0, z2 + 1)) -- regarde la rue sud
						end
						-- repère du terrain : +Z local = vers l'intérieur de l'îlot
						house(block, lotCf, lw, ld, k + row * nLots)
						n += 1
						task.wait()
					end
				end
			end
		end
	end
	return ("quartier résidentiel : %d maisons"):format(n)
end
