--!nolint
-- 16 : remplace les maisons des collines (HillHouse_*, anciennes maisons de Build.house) par des maisons HouseKit
-- (même style que le quartier résidentiel : portes qui s'ouvrent, intérieurs vides). Chaque maison est posée sur
-- un socle en pierre (terrasse) face à la route en spirale ; deux étages sur le plateau, plain-pied sur les pentes.
local Lib = require(script.Parent.Lib)
local Plan = require(script.Parent.Plan)
local HK = require(script.Parent.HouseKit)
local V, rgb, M = Lib.V, Lib.rgb, Lib.M

local rng = Random.new(1616)
local function pick(t)
	return t[rng:NextInteger(1, #t)]
end

return function()
	local root = Lib.path("HillsideDistrict")
	local removed = 0
	for _, c in root:GetChildren() do
		if c.Name:match("^HillHouse_") then
			c:Destroy()
			removed += 1
		end
	end
	task.wait()
	HK.installScript()
	local stone = rgb(176, 166, 150)
	local n, lastPal = 0, nil
	for idx, pad in Plan.hillPads do
		local base = V(pad.p.X, pad.y, pad.p.Z)
		local cf = CFrame.lookAt(base, base + pad.face) -- -Z local = vers la route
		local spec
		if pad.plateau then
			spec = { type = "twostory", floors = 2, W = rng:NextInteger(26, 28), D = 35, roof = pick({ "gable", "hip", "frontgable" }), porch = true, porchW = 10, chimney = rng:NextNumber() < 0.6 }
		else
			spec = { type = "small", floors = 1, W = rng:NextInteger(22, 24), D = 26, roof = pick({ "gable", "frontgable", "hip" }), porch = false, chimney = rng:NextNumber() < 0.5 }
		end
		spec.doorSide = rng:NextNumber() < 0.5 and -1 or 1
		spec.pitch = spec.roof == "hip" and 0.45 or nil
		local pals = { "white", "beige", "grey", "taupe", "brick", "slate", "cream", "wood", "brownbrick" }
		repeat
			spec.pal = pick(pals)
		until spec.pal ~= lastPal
		lastPal = spec.pal
		spec.name = "HillHouse_" .. idx
		spec.furnish = workspace:GetAttribute("FurnishAll") and true or nil
		local fz = pad.plateau and -12 or -8 -- façade
		local hm = HK.build(root, cf * CFrame.new(0, 0, fz), spec, rng)
		-- socle : dalle sur un massif en pierre qui descend dans la pente
		local z0, z1 = fz - (pad.plateau and 9 or 5), fz + spec.D + 3
		local dz, cz = z1 - z0, (z0 + z1) / 2
		local W = spec.W + 8
		local yard = Lib.model(hm, "Terrace")
		Lib.part(yard, cf * CFrame.new(0, -0.2, cz), V(W, 0.8, dz), rgb(106, 176, 70), M.Grass, { Name = "Lawn" })
		if not pad.plateau then
			Lib.part(yard, cf * CFrame.new(0, -7, cz + 0.3), V(W + 0.6, 12.6, dz + 0.6), stone, M.Cobblestone, { Name = "TerraceWall" })
			Lib.fine(yard, cf * CFrame.new(0, 0.25, z1 + 0.1), V(W + 0.8, 0.3, 0.9), rgb(220, 210, 196), M.Concrete)
		end
		-- allée jusqu'à la route + boîte aux lettres
		local hx = 0
		for _, d in hm:GetDescendants() do
			if d:IsA("Model") and d.Name == "Door" and d:FindFirstChild("Hinge") then
				local lp = cf:PointToObjectSpace(d.Hinge.Position)
				if math.abs(lp.Z - fz) < 1.5 then
					hx = lp.X
					break
				end
			end
		end
		local pz0 = -17
		Lib.part(yard, cf * CFrame.new(hx, 0.05, (pz0 + fz) / 2), V(4, 0.6, fz - pz0), rgb(200, 190, 176), M.Pavement, { Name = "Path" })
		Lib.mailbox(yard, cf * CFrame.new(hx + 3.5, 0, pz0 + 2))
		-- haie basse de part et d'autre de l'allée
		for _, s in { -1, 1 } do
			local a, b = s > 0 and hx + 2.6 or -W / 2 + 1, s > 0 and W / 2 - 1 or hx - 2.6
			if b - a > 2 then
				Lib.part(yard, cf * CFrame.new((a + b) / 2, 1, z0 + 0.8), V(b - a, 2, 1.4), rgb(70, 110, 52), M.LeafyGrass, { Name = "Hedge" })
			end
		end
		Lib.tree(yard, (cf * CFrame.new((spec.doorSide > 0 and -1 or 1) * (W / 2 - 2.5), 0, z0 + 4)).Position, rng:NextNumber() < 0.5 and "pine" or "round", rng:NextNumber(16, 22))
		n += 1
		task.wait()
	end
	return ("collines : %d anciennes maisons retirées, %d maisons HouseKit construites"):format(removed, n)
end
