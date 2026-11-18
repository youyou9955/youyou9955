--!nolint
-- 15 : reprise après retour joueur. Modèles Meshy légers (suffixe L, ~500 à 3000 triangles, sans PBR).
--  * tours du centre : modèle choisi selon la proportion hauteur/largeur pour ne pas déformer
--  * ferme : grange et silo Meshy, tracteur garé à côté, zone de livraison posée au sol
--  * arbres, sapins, buissons : versions légères (la série R à 8000 triangles faisait ramer)
-- À lancer après 14. Idempotent.
local Lib = require(script.Parent.Lib)
local city = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("City")
local V = Vector3.new

local function place(name, parent, cfGround, size, collide, newName)
	local m = city[name]:Clone()
	for _, c in m:GetChildren() do
		if c:IsA("SurfaceAppearance") then
			c:Destroy()
		end
	end
	m.Size = size
	m.CFrame = cfGround * CFrame.new(0, size.Y / 2, 0)
	m.Anchored = true
	m.CanCollide = collide
	m.CanTouch = false
	m.CanQuery = collide
	m.CastShadow = size.Y > 1.5
	m.RenderFidelity = Enum.RenderFidelity.Automatic
	pcall(function()
		m.CollisionFidelity = Enum.CollisionFidelity.Box
	end)
	m.Name = newName
	m:SetAttribute("Light", true)
	m.Parent = parent
	Lib.yield(4)
	return m
end

local function ground(old)
	return old.CFrame * CFrame.new(0, -old.Size.Y / 2, 0)
end

local function uniform(name, h)
	return city[name].Size * (h / city[name].Size.Y)
end

---------------------------------------------------------------- Tours
local TOWERS = { "OfficeL1", "OfficeL2", "OfficeL3" }
local function towers(map)
	local n = 0
	for _, d in map:GetDescendants() do
		if d:IsA("MeshPart") and d.Name == "MeshyTower" then
			local s = d.Size
			local want = s.Y / math.max(s.X, s.Z)
			-- modèle selon la proportion : moins d'étirement des fenêtres
			-- (L1 tour de verre ~1.8, L2 brique ~0.85, L3 pierre ~0.6)
			local best = want >= 1.5 and "OfficeL1" or (want >= 0.75 and "OfficeL2" or "OfficeL3")
			place(best, d.Parent, ground(d), s, true, "MeshyTower")
			d:Destroy()
			n += 1
		end
	end
	return n
end

---------------------------------------------------------------- Ferme
local function farm(map)
	local f = map.Districts.Outskirts:FindFirstChild("FermeDesColisFrais")
	if not f or f:FindFirstChild("MeshyBarn") then
		return false
	end
	local sign = f:FindFirstChild("Sign")
	local gui = sign and sign:FindFirstChildOfClass("SurfaceGui")
	for _, n in { "Barn", "BarnRoof", "BarnDoor", "Silo", "SiloTop" } do
		for _, c in f:GetChildren() do
			if c.Name == n then
				c:Destroy()
			end
		end
	end
	-- grange : façade (portes) vers +X, côté route
	local face = CFrame.lookAt(Vector3.zero, V(1, 0, 0))
	local barnSize = uniform("BarnL", 22)
	local k = math.min(36 / barnSize.X, 50 / barnSize.Z, 1.4)
	barnSize *= k
	local barn = place("BarnL", f, CFrame.new(-122, 0, 606) * face, barnSize, true, "MeshyBarn")
	place("SiloL", f, CFrame.new(-128, 0, 646), uniform("SiloL", 34), true, "MeshySilo")
	if sign then
		sign.Size = V(16, 2.6, 0.3)
		sign.CFrame = barn.CFrame * CFrame.new(0, barnSize.Y * 0.18, -barnSize.Z / 2 - 0.4)
		sign.Material = Enum.Material.Wood
		sign.Color = Color3.fromRGB(240, 232, 214)
	end
	-- tracteur garé contre la grange, hors de la zone de livraison
	local parts = {}
	for _, c in f:GetChildren() do
		if c:IsA("BasePart") and (c.Name == "Tractor" or c.Name == "TractorCab" or (c.Name == "Part" and c.Material == Enum.Material.Rubber)) then
			table.insert(parts, c)
		end
	end
	for _, p in parts do
		p.CFrame = p.CFrame + V(-6, 0, -34)
	end
	-- zone de livraison au sol devant la grange
	local zone = map.DeliveryZones:FindFirstChild("DeliveryZone_Ferme")
	if zone then
		local pad = zone:FindFirstChild("Pad")
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { zone, f }
		local hit = workspace:Raycast(V(-80, 100, 580), V(0, -200, 0), params)
		local y = hit and hit.Position.Y or 0
		if pad then
			local dy = (y + 0.06) - pad.Position.Y
			for _, d in zone:GetDescendants() do
				if d:IsA("BasePart") then
					d.CFrame = d.CFrame + V(0, dy, 0)
				end
			end
		end
	end
	return true
end

---------------------------------------------------------------- Végétation légère
local function trees(map)
	local st = { tree = 0, bush = 0 }
	local pineIds = { [city.TreePine.MeshId] = true, [city.TreePineR.MeshId] = true }
	for _, d in map:GetDescendants() do
		if d:IsA("MeshPart") and d.Parent and not d:GetAttribute("Light") then
			if d.Name == "MeshyTree" or d.Name == "MeshyPalm" then
				local name = pineIds[d.MeshId] and "PineL" or "TreeL"
				local cf = ground(d)
				place(name, d.Parent, cf, uniform(name, d.Size.Y), false, d.Name)
				d:Destroy()
				st.tree += 1
			elseif d.Name == "MeshyBush" or d.Name == "Furniture_Bush" then
				place("BushL", d.Parent, ground(d), V(d.Size.X, d.Size.Y, d.Size.Z), false, d.Name)
				d:Destroy()
				st.bush += 1
			end
		end
	end
	return st
end

return function(only)
	local map = workspace.Map
	local out = {}
	if not only or only == "towers" then
		table.insert(out, ("%d tours"):format(towers(map)))
	end
	if not only or only == "farm" then
		table.insert(out, farm(map) and "ferme refaite" or "ferme déjà faite")
	end
	if not only or only == "trees" then
		local st = trees(map)
		table.insert(out, ("%d arbres, %d buissons allégés"):format(st.tree, st.bush))
	end
	return "reprise : " .. table.concat(out, ", ")
end
