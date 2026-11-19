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
			spec = { type = "twostory", floors = 2, W = rng:NextInteger(32, 34), D = 41, roof = pick({ "gable", "hip", "frontgable" }), porch = true, porchW = 10, chimney = rng:NextNumber() < 0.6 }
		else
			spec = { type = "small", floors = 1, W = rng:NextInteger(27, 29), D = 31, roof = pick({ "gable", "frontgable", "hip" }), porch = false, chimney = rng:NextNumber() < 0.5 }
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
		-- plus grande possible sans empiéter sur un monument voisin (belvédère...)
		local function clash(m)
			local op = OverlapParams.new()
			op.FilterType = Enum.RaycastFilterType.Include
			op.FilterDescendantsInstances = { Lib.path("Landmarks") }
			for _, p in m.Shell:GetChildren() do
				if p:IsA("BasePart") and #workspace:GetPartsInPart(p, op) > 0 then
					return true
				end
			end
			return false
		end
		while clash(hm) and spec.W > 24 do
			hm:Destroy()
			spec.W -= 2
			hm = HK.build(root, cf * CFrame.new(0, 0, fz), spec, rng)
		end
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
			if d:IsA("Model") and d.Name == "Door" and d:FindFirstChild("Panel") then
				local lp = cf:PointToObjectSpace(d.Panel.Position) -- centre du vantail (pas la charnière)
				if math.abs(lp.Z - fz) < 1.5 then
					hx = lp.X
					break
				end
			end
		end
		local pz0 = -17
		Lib.part(yard, cf * CFrame.new(hx, 0.05, (pz0 + fz) / 2), V(4, 0.6, fz - pz0), rgb(200, 190, 176), M.Pavement, { Name = "Path" })
		Lib.mailbox(yard, cf * CFrame.new(hx + (hx > 0 and -5.6 or 5.6), 0, pz0 + 1.5))
		-- ouverture dans la glissière / le mur de soutènement au bout de l'allée (accès à pied), marches si besoin
		local op = OverlapParams.new()
		op.FilterType = Enum.RaycastFilterType.Include
		op.FilterDescendantsInstances = { Lib.path("Roads") }
		local cut = 0
		for _, g in workspace:GetPartBoundsInBox(cf * CFrame.new(hx, 1, pz0 - 2.5), V(5.5, 10, 9), op) do
			if g.Size.Y >= 0.25 and math.min(g.Size.X, g.Size.Z) <= 2.3 and (math.max(g.Size.X, g.Size.Z) > 3 or (g.Size.Y > 1.5 and math.max(g.Size.X, g.Size.Z) < 1)) then -- glissière, mur, poteaux
				g:Destroy()
				cut += 1
			end
		end
		-- éléments décoratifs non interrogeables (bande rouge, chaperon) dans la même ouverture
		local boxCf = cf * CFrame.new(hx, 1, pz0 - 2.5)
		for _, g in Lib.path("Roads"):GetDescendants() do
			if g:IsA("BasePart") and not g.CanQuery and math.min(g.Size.X, g.Size.Z) <= 2.3 and math.max(g.Size.X, g.Size.Z) > 3 then
				local lp = boxCf:PointToObjectSpace(g.Position)
				if math.abs(lp.X) < 2.75 + math.max(g.Size.X, g.Size.Z) / 2 and math.abs(lp.Z) < 4.5 and math.abs(lp.Y) < 6 then
					local rail = g.CFrame
					-- seulement si la pièce traverse l'ouverture (même alignement qu'une glissière coupée)
					g:Destroy()
					cut += 1
				end
			end
		end
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Include
		rp.FilterDescendantsInstances = { Lib.path("Roads") }
		local hit = workspace:Raycast((cf * CFrame.new(hx, 12, pz0 - 7)).Position, V(0, -40, 0), rp)
		if hit then
			local drop = base.Y - hit.Position.Y
			if drop > 0.9 then
				local n = math.ceil(drop / 0.9)
				for k = 1, n - 1 do
					local ht = drop * (n - k) / n + 0.35
					Lib.part(yard, cf * CFrame.new(hx, hit.Position.Y - base.Y + ht / 2, pz0 - 1.2 * (k - 0.5)), V(4, ht, 1.2), rgb(190, 184, 172), M.Concrete, { Name = "Step" })
				end
			end
		end
		yard:SetAttribute("RailCut", cut)
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
