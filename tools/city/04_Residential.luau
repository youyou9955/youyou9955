--!nolint
-- 04 : quartier résidentiel (maisons variées, maisons de ville, parc et aire de jeux).
local Lib = require(script.Parent.Lib)
local M = Enum.Material
local C = Lib.C
local V = Vector3.new

local DIRS = { N = V(0, 0, 1), S = V(0, 0, -1), E = V(1, 0, 0), W = V(-1, 0, 0) }
local NAMES = { "Famille Dupneu", "M. Retour", "Mme Colissimo", "Les Demi-Tour", "Famille Klaxon", "M. Virage", "Mme Bosse", "Les Rétro" }

local function yardProps(parent, cf, w, d, rng)
	-- jardin arrière : piscine, trampoline, barbecue, balançoire (aléatoire)
	local r = rng:NextNumber()
	local back = cf * CFrame.new(0, 0, d / 2 + 14)
	if r < 0.35 then
		Lib.part(parent, back * CFrame.new(0, 0.3, 0), V(14, 0.6, 8), Color3.new(1, 1, 1), M.Concrete, { Name = "PoolRim" })
		Lib.deco(parent, back * CFrame.new(0, 0.62, 0), V(12.6, 0.1, 6.6), Color3.fromRGB(60, 170, 220), M.Glass, { Transparency = 0.2, Name = "PoolWater" })
		Lib.deco(parent, back * CFrame.new(5, 1, 6), V(2, 0.4, 5), Color3.fromRGB(250, 220, 90), M.Fabric, { Name = "Lounger" })
	elseif r < 0.6 then
		Lib.deco(parent, back * CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0, math.rad(90)), V(0.4, 10, 10), Color3.fromRGB(40, 40, 50), M.Fabric, { Shape = Enum.PartType.Cylinder, Name = "Trampoline" })
		for a = 0, 270, 90 do
			Lib.deco(parent, back * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(4.5, 1, 0), V(0.3, 2, 0.3), C.metal, M.Metal)
		end
	elseif r < 0.8 then
		Lib.deco(parent, back * CFrame.new(-3, 1.5, 0), V(2, 3, 2), C.dark, M.Metal, { Name = "BBQ" })
		Lib.deco(parent, back * CFrame.new(3, 1.4, 0), V(5, 0.3, 3), C.wood, M.Wood, { Name = "Table" })
		Lib.deco(parent, back * CFrame.new(3, 5, 0), V(0.2, 9, 0.2), C.wood, M.Wood)
		Lib.deco(parent, back * CFrame.new(3, 9, 0), V(7, 0.3, 7), Color3.fromRGB(230, 80, 60), M.Fabric, { Name = "Parasol" })
	else
		for _, x in { -4, 4 } do
			Lib.deco(parent, back * CFrame.new(x, 4, 0), V(0.4, 8, 0.4), C.wood, M.Wood)
		end
		Lib.deco(parent, back * CFrame.new(0, 8, 0), V(8.6, 0.4, 0.4), C.wood, M.Wood)
		Lib.deco(parent, back * CFrame.new(0, 2, 0), V(2.4, 0.3, 1.2), Color3.fromRGB(200, 60, 60), M.Wood, { Name = "Swing" })
	end
end

local function lot(parent, pos, side, rng, opts)
	opts = opts or {}
	local cf = Lib.facing(pos, side)
	local house, w, d = Lib.house(parent, cf, { garageSide = rng:NextNumber() < 0.5 and 1 or -1, floors = opts.floors, flat = opts.flat, garage = opts.garage, w = opts.w, d = opts.d })
	-- allée de garage / chemin d'entrée jusqu'au trottoir (cf * -Z = vers la rue)
	local front = d / 2
	local toWalk = opts.setback or 10
	if opts.garage ~= false then
		local side2 = 0
		for _, p in house:GetChildren() do
			if p.Name == "Garage" then
				side2 = cf:PointToObjectSpace(p.Position).X
			end
		end
		Lib.part(house, cf * CFrame.new(side2, 0.25, -front - toWalk / 2 + 1), V(9, 0.5, toWalk + 2), C.concrete, M.Concrete, { Name = "Driveway" })
	end
	Lib.part(house, cf * CFrame.new(-w / 5, 0.2, -front - toWalk / 2), V(3, 0.4, toWalk), Color3.fromRGB(190, 180, 165), M.Slate, { Name = "Path", CanCollide = false })
	-- boîte aux lettres, poubelles, haie, fleurs
	local mb = Lib.model(house, "Mailbox")
	Lib.deco(mb, cf * CFrame.new(-w / 5 - 3, 1.8, -front - toWalk + 1.5), V(0.3, 3.6, 0.3), C.wood, M.Wood)
	local box = Lib.deco(mb, cf * CFrame.new(-w / 5 - 3, 4, -front - toWalk + 1.5), V(1.2, 1.2, 2), Color3.fromHSV(rng:NextNumber(), 0.6, 0.7), M.Metal)
	Lib.label(box, Enum.NormalId.Left, Lib.pick(NAMES), Color3.new(1, 1, 1))
	Lib.trash(house, cf * CFrame.new(w / 2 - 1, 0, -front - 2), Color3.fromRGB(60, 60, 70))
	Lib.trash(house, cf * CFrame.new(w / 2 - 3.5, 0, -front - 2), Color3.fromRGB(230, 200, 40))
	Lib.flowerBed(house, cf * CFrame.new(w / 5 + 1, 0, -front - 2), 6, 2)
	if rng:NextNumber() < 0.6 then
		Lib.tree(Lib.path("Vegetation"), (cf * CFrame.new(rng:NextNumber(-w / 2, w / 2), 0, -front - toWalk + 4)).Position, "round")
	end
	if opts.yard ~= false then
		yardProps(house, cf, w, d, rng)
	end
	return house, cf, w, d
end

return function()
	local R = Lib.path("Districts", "Residential")
	local veg = Lib.path("Vegetation")
	local rng = Lib.rng
	local houses = 0
	for i = 1, 3 do
		for j = 4, 6 do
			local c = Lib.cell(i, j)
			local f = Lib.model(R, ("Block_%d_%d"):format(i, j))
			if i == 2 and j == 5 then
				----------------------------------------------------------- Parc et aire de jeux
				local p = Lib.model(f, "ParcDesPetitsLivreurs")
				Lib.slab(p, c.cx - 3, c.cx + 3, c.iz1, c.iz2, 0.3, 0.6, Color3.fromRGB(205, 185, 150), M.Ground, { Name = "Path" })
				-- aire de jeux sur sol souple
				local pg = V(c.cx - 30, 0, c.cz + 28)
				Lib.slab(p, pg.X - 20, pg.X + 20, pg.Z - 16, pg.Z + 16, 0.4, 0.8, Color3.fromRGB(200, 90, 70), M.Rubber, { Name = "PlaygroundFloor" })
				-- toboggan
				Lib.part(p, CFrame.new(pg + V(-10, 4, -6)), V(5, 8, 5), Color3.fromRGB(250, 200, 40), M.Plastic, { Name = "SlideTower" })
				Lib.beam(p, pg + V(-10, 8.4, -3.5), pg + V(-10, 0.6, 8), 3, 0.4, Color3.fromRGB(60, 140, 230), M.Plastic, { Name = "Slide" }, true)
				-- balançoires
				for _, x in { 4, 14 } do
					Lib.deco(p, CFrame.new(pg + V(x, 5, -8)), V(0.4, 10, 0.4), C.metal, M.Metal)
				end
				Lib.deco(p, CFrame.new(pg + V(9, 10, -8)), V(10.4, 0.4, 0.4), C.metal, M.Metal)
				for _, x in { 6.5, 11.5 } do
					Lib.deco(p, CFrame.new(pg + V(x, 2.2, -8)), V(2.4, 0.3, 1), Color3.fromRGB(230, 60, 60), M.Rubber)
				end
				-- bac à sable et tourniquet
				Lib.part(p, CFrame.new(pg + V(8, 0.9, 7)), V(12, 1, 10), C.wood, M.Wood, { Name = "SandboxFrame" })
				Lib.deco(p, CFrame.new(pg + V(8, 1.45, 7)), V(11, 0.2, 9), Color3.fromRGB(230, 210, 150), M.Sand)
				Lib.disc(p, pg + V(-8, 0, 8), 3, 1.4, 0.4, Color3.fromRGB(60, 180, 90), M.Metal, { Name = "Roundabout4Kids" })
				Lib.postSign(p, CFrame.lookAt(pg + V(0, 0.8, -16), pg + V(0, 0.8, -26)), "Aire de jeux — tourniquet à sens unique", Color3.fromRGB(30, 110, 60), Color3.new(1, 1, 1), 9, 2.5, 4)
				-- terrain de basket
				local bc = V(c.cx + 32, 0, c.cz - 26)
				Lib.slab(p, bc.X - 15, bc.X + 15, bc.Z - 24, bc.Z + 24, 0.5, 1, Color3.fromRGB(60, 110, 160), M.Concrete, { Name = "Court" })
				Lib.mark(p, CFrame.new(bc + V(0, 0.52, 0)), V(30, 0.05, 0.4))
				for _, z in { -1, 1 } do
					Lib.part(p, CFrame.new(bc + V(0, 5, z * 25)), V(0.5, 10, 0.5), C.metal, M.Metal)
					Lib.deco(p, CFrame.new(bc + V(0, 10, z * 24)), V(6, 4, 0.3), Color3.new(1, 1, 1), M.SmoothPlastic, { Name = "Backboard" })
				end
				Lib.fence(p, bc + V(-15, 0.5, -24), bc + V(-15, 0.5, 24), 8, Color3.fromRGB(110, 115, 120), true, M.DiamondPlate)
				-- arbres, bancs
				for k = 1, 26 do
					local tp = V(rng:NextNumber(c.ix1 + 4, c.ix2 - 4), 0, rng:NextNumber(c.iz1 + 4, c.iz2 - 4))
					if math.abs(tp.X - c.cx) > 6 and (tp - pg).Magnitude > 26 and (tp - bc).Magnitude > 30 then
						Lib.tree(veg, tp)
					end
				end
				for t = -40, 40, 20 do
					Lib.bench(p, CFrame.new(c.cx + 5, 0.3, c.cz + t) * CFrame.Angles(0, math.rad(90), 0))
				end
			elseif i == 3 and j == 4 then
				----------------------------------------------------------- Maisons de ville
				for _, side in { "N", "S" } do
					local n = 7
					local span = (c.w - 4) / n
					for k = 0, n - 1 do
						local x = c.ix1 + 2 + span * (k + 0.5)
						local z = side == "N" and (c.iz2 - 14) or (c.iz1 + 14)
						local cf = Lib.facing(V(x, 0, z), side)
						Lib.house(f, cf, { w = span - 0.4, d = 18, floors = rng:NextInteger(2, 3), flat = rng:NextNumber() < 0.5, garage = false, color = Color3.fromHSV(rng:NextNumber(), 0.3, 0.85), material = M.Brick })
						Lib.part(f, cf * CFrame.new(0, 0.2, -12), V(3, 0.4, 6), Color3.fromRGB(190, 180, 165), M.Slate, { Name = "Steps", CanCollide = false })
						houses += 1
					end
				end
				-- cour commune
				Lib.slab(f, c.ix1 + 4, c.ix2 - 4, c.cz - 16, c.cz + 16, 0.3, 0.6, Color3.fromRGB(205, 185, 150), M.Ground, { Name = "Courtyard" })
				for x = c.ix1 + 14, c.ix2 - 14, 22 do
					Lib.tree(veg, V(x, 0.3, c.cz), "round", 0.9)
					Lib.bench(f, CFrame.new(x + 8, 0.3, c.cz))
				end
			else
				----------------------------------------------------------- Îlot pavillonnaire
				local setN, setS = c.iz2 - 20, c.iz1 + 20
				for _, x in { c.cx - c.w / 4, c.cx + c.w / 4 } do
					lot(f, V(x + rng:NextNumber(-3, 3), 0, setN), "N", rng)
					lot(f, V(x + rng:NextNumber(-3, 3), 0, setS), "S", rng)
					houses += 2
				end
				lot(f, V(c.ix1 + 20, 0, c.cz), "W", rng, { garage = false, yard = false })
				lot(f, V(c.ix2 - 20, 0, c.cz), "E", rng, { garage = false, yard = false })
				houses += 2
				-- clôtures de fond de jardin
				Lib.fence(f, V(c.ix1 + 34, 0, c.cz), V(c.ix2 - 34, 0, c.cz), 4, Color3.fromRGB(235, 235, 230), false, M.WoodPlanks)
				Lib.fence(f, V(c.cx, 0, c.iz1 + 34), V(c.cx, 0, c.iz2 - 34), 4, Color3.fromRGB(235, 235, 230), false, M.WoodPlanks)
				-- haies le long du trottoir
				for _, z in { c.iz1 + 1, c.iz2 - 1 } do
					for x = c.ix1 + 4, c.ix2 - 4, 7 do
						if rng:NextNumber() < 0.45 then
							Lib.bush(veg, V(x, 0, z), 3)
						end
					end
				end
			end
			-- arbres d'alignement sur les trottoirs du quartier
			for _, z in { c.z1 + 3, c.z2 - 3 } do
				for x = c.x1 + 20, c.x2 - 20, 30 do
					Lib.tree(veg, V(x + 10, Lib.WALK, z), "round", 0.75)
				end
			end
		end
	end
	return ("résidentiel ok : %d maisons"):format(houses)
end
