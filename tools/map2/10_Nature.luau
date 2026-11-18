--!nolint
-- 10 : végétation hors ville (forêts en bosquets, pins sur les collines, buissons) et voitures-jouets
-- colorées en pièces, qui remplacent une partie des voitures Meshy identiques des parkings.
local Lib = require(script.Parent.Lib)
local Plan = require(script.Parent.Plan)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C

local rng = Random.new(1010)

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { workspace.Terrain }

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude
overlap.FilterDescendantsInstances = { workspace.Terrain }

-- point de sol libre : herbe, pente douce, hors eau, rien de construit autour
local function freeSpot(x, z, clear, maxH)
	local hit = workspace:Raycast(V(x, 500, z), V(0, -1000, 0), terrainOnly)
	if not hit then
		return nil
	end
	local mat = hit.Material
	if mat ~= M.Grass and mat ~= M.LeafyGrass and mat ~= M.Ground then
		return nil
	end
	if hit.Normal.Y < 0.82 or hit.Position.Y > (maxH or 150) or hit.Position.Y < 0.5 then
		return nil
	end
	-- au-dessus : rien (route, pont, bâtiment)
	local any = workspace:Raycast(V(x, hit.Position.Y + 300, z), V(0, -300, 0))
	if any and any.Instance ~= workspace.Terrain then
		return nil
	end
	if #workspace:GetPartBoundsInRadius(hit.Position, clear, overlap) > 0 then
		return nil
	end
	return hit.Position
end

local toyCar = Lib.toyCar

return function()
	local veg = Lib.path("Vegetation")
	local vehicles = Lib.path("DecorativeVehicles")
	local nTree, nCar, nRemoved = 0, 0, 0

	---------------------------------------------------------------- Parkings : variété de couleurs
	local parked = {}
	for _, m in vehicles:GetChildren() do
		if m.Name == "ParkedCar" then
			table.insert(parked, m)
		end
	end
	for i, m in parked do
		local r = rng:NextNumber()
		if r < 0.25 then
			m:Destroy()
			nRemoved += 1
		elseif r < 0.75 then
			local col = m:FindFirstChild("Collision")
			local base = col and (col.CFrame * CFrame.new(0, -col.Size.Y / 2, 0)) or m:GetPivot()
			local _, ry = base:ToOrientation()
			local p = base.Position
			m:Destroy()
			toyCar(vehicles, CFrame.new(p) * CFrame.Angles(0, ry, 0))
			nCar += 1
		end
		if i % 20 == 0 then
			task.wait()
		end
	end

	---------------------------------------------------------------- Forêts en bosquets hors du périphérique
	local centers = {}
	local tries = 0
	while #centers < 34 and tries < 400 do
		tries += 1
		local x, z = rng:NextNumber(-1450, 1450), rng:NextNumber(-1300, 1300)
		if Plan.rural(x, z) and freeSpot(x, z, 20, 140) then
			table.insert(centers, V(x, 0, z))
		end
	end
	for ci, c in centers do
		local n = rng:NextInteger(10, 22)
		local pineShare = c.Z < -800 and 0.85 or (c.X < -1000 and 0.6 or 0.3)
		for k = 1, n * 2 do
			local a, r = rng:NextNumber(0, 6.28), rng:NextNumber(0, 70)
			local p = freeSpot(c.X + math.cos(a) * r, c.Z + math.sin(a) * r, 8, 150)
			if p then
				local kind = rng:NextNumber() < pineShare and "pine" or "round"
				Lib.tree(veg, p - V(0, 0.3, 0), kind, kind == "pine" and rng:NextNumber(20, 34) or rng:NextNumber(16, 26))
				nTree += 1
				n -= 1
				if n <= 0 then
					break
				end
			end
		end
		task.wait()
	end
	-- arbres isolés et buissons dans la campagne
	for k = 1, 260 do
		local x, z = rng:NextNumber(-1450, 1450), rng:NextNumber(-1300, 1300)
		if Plan.rural(x, z) then
			local p = freeSpot(x, z, 9, 140)
			if p then
				if rng:NextNumber() < 0.55 then
					Lib.tree(veg, p - V(0, 0.3, 0))
					nTree += 1
				else
					Lib.bush(veg, p - V(0, 0.2, 0), rng:NextNumber(3, 6))
				end
			end
		end
		if k % 25 == 0 then
			task.wait()
		end
	end

	---------------------------------------------------------------- Pins sur les pentes des collines
	local hill = Plan.hill
	for k = 1, 220 do
		local a, r = rng:NextNumber(0, 6.28), rng:NextNumber(60, 280)
		local p = freeSpot(hill.c.X + math.cos(a) * r, hill.c.Z + math.sin(a) * r, 10, 120)
		if p then
			Lib.tree(veg, p - V(0, 0.3, 0), rng:NextNumber() < 0.8 and "pine" or "round")
			nTree += 1
		end
		if k % 25 == 0 then
			task.wait()
		end
	end

	return ("nature : %d arbres, %d voitures-jouets (%d voitures retirées)"):format(nTree, nCar, nRemoved)
end
