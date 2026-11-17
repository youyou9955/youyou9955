--!nolint
-- 10 : remplace les blocs simples par les modèles 3D Meshy AI (ReplicatedStorage.Assets.City).
-- Maisons, maisons de ville, tours, boutiques, entrepôts, arbres, lampadaires, bancs.
-- Les modèles ont leur façade vers -Z (sauf Warehouse et StreetLamp : façade / bras vers +X).
local Lib = require(script.Parent.Lib)
local city = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("City")
local V = Vector3.new

local ROT = { Warehouse = CFrame.Angles(0, math.pi / 2, 0), StreetLamp = CFrame.Angles(0, math.pi / 2, 0) }

-- Taille dans le repère « façade » (X = largeur, Z = profondeur)
local function baseSize(name)
	local s = city[name].Size
	if ROT[name] then
		return V(s.Z, s.Y, s.X)
	end
	return s
end

-- cfGround : centre au sol, LookVector = façade. target = (largeur, hauteur, profondeur).
-- mode "fit" : échelle uniforme qui tient dans la largeur/profondeur ; "stretch" : taille exacte ;
-- "height" : échelle uniforme réglée sur la hauteur.
local function place(name, parent, cfGround, target, mode, collide)
	local b = baseSize(name)
	local sc
	if mode == "stretch" then
		sc = V(target.X / b.X, target.Y / b.Y, target.Z / b.Z)
	elseif mode == "height" then
		sc = Vector3.one * (target.Y / b.Y)
	else
		sc = Vector3.one * math.min(target.X / b.X, target.Z / b.Z)
	end
	local sz = b * sc
	local m = city[name]:Clone()
	m.Size = ROT[name] and V(sz.Z, sz.Y, sz.X) or sz
	m.CFrame = cfGround * CFrame.new(0, sz.Y / 2, 0) * (ROT[name] or CFrame.identity)
	m.Anchored = true
	m.CanCollide = collide
	m.CanTouch = false
	m.CanQuery = collide
	pcall(function()
		m.CollisionFidelity = Enum.CollisionFidelity.Box
	end)
	m.Parent = parent
	Lib.yield(3)
	return m, sz
end

local function flatRot(cf)
	local look = cf.LookVector
	look = V(look.X, 0, look.Z)
	if look.Magnitude < 1e-3 then
		look = V(0, 0, -1)
	end
	return CFrame.lookAt(Vector3.zero, look.Unit)
end

local function destroyNamed(model, names)
	for _, c in model:GetChildren() do
		if c:IsA("BasePart") and names[c.Name] then
			c:Destroy()
		end
	end
end

return function()
	local map = workspace.Map
	local rng = Random.new(77)
	local stats = { house = 0, tower = 0, shop = 0, warehouse = 0, tree = 0, lamp = 0, bench = 0 }
	local all = map:GetDescendants()

	---------------------------------------------------------------- Maisons
	local HOUSE_PARTS = { Foundation = 1, Walls = 1, Roof = 1, Chimney = 1, Door = 1, DoorCanopy = 1, Window = 1, Sill = 1, SideWindows = 1, Garage = 1, GarageDoor = 1, GarageRoof = 1 }
	for _, m in all do
		if m:IsA("Model") and (m.Name == "House" or m.Name == "HillHouse") and m:FindFirstChild("Walls") and m:FindFirstChild("Foundation") then
			local walls, found = m.Walls, m.Foundation
			local ground = found.Position.Y - found.Size.Y / 2
			local frame = CFrame.new(walls.Position.X, ground, walls.Position.Z) * flatRot(walls.CFrame)
			local minX, maxX, minZ, maxZ, maxY = math.huge, -math.huge, math.huge, -math.huge, 0
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") and HOUSE_PARTS[p.Name] and p.Name ~= "SideWindows" then
					local o = frame:PointToObjectSpace(p.Position)
					local hs = p.Size / 2
					minX, maxX = math.min(minX, o.X - hs.X), math.max(maxX, o.X + hs.X)
					minZ, maxZ = math.min(minZ, o.Z - hs.Z), math.max(maxZ, o.Z + hs.Z)
					maxY = math.max(maxY, o.Y + hs.Y)
				end
			end
			local w, d = maxX - minX, maxZ - minZ
			local cf = frame * CFrame.new((minX + maxX) / 2, 0, (minZ + maxZ) / 2)
			local kind
			if m.Parent and m.Parent.Name == "Block_3_4" then
				kind = "Townhouse"
			elseif m:FindFirstChild("Garage") then
				kind = "HouseA"
			elseif m.Name == "HillHouse" then
				kind = "HouseB"
			else
				kind = rng:NextNumber() < 0.5 and "HouseB" or "HouseC"
			end
			local mesh = place(kind, m, cf, V(w, maxY, d), kind == "Townhouse" and "stretch" or "fit", true)
			mesh.Name = "MeshyHouse"
			destroyNamed(m, HOUSE_PARTS)
			stats.house += 1
		end
	end

	---------------------------------------------------------------- Tours de bureaux (centre-ville)
	for _, m in all do
		if m:IsA("Model") and m.Name == "Tower" and m:FindFirstChild("Body") then
			local body = m.Body
			local h = body.Size.Y
			local cf = CFrame.new(body.Position.X, body.Position.Y - h / 2, body.Position.Z) * flatRot(body.CFrame)
			place("Office", m, cf, V(body.Size.X, h, body.Size.Z), "stretch", true).Name = "MeshyTower"
			for _, c in m:GetChildren() do
				if c:IsA("BasePart") and (({ Body = 1, Lobby = 1, Windows = 1, Canopy = 1, Door = 1, Parapet = 1 })[c.Name] or (c.Name == "Part" and math.abs(c.Size.Y - h) < 0.5)) then
					c:Destroy()
				end
			end
			stats.tower += 1
		end
	end

	---------------------------------------------------------------- Boutiques
	for _, m in all do
		if m:IsA("Model") and string.sub(m.Name, 1, 5) == "Shop_" and m:FindFirstChild("Body") then
			local body = m.Body
			local s = body.Size
			local cf = CFrame.new(body.Position.X, body.Position.Y - s.Y / 2, body.Position.Z) * flatRot(body.CFrame)
			place("Shop", m, cf, V(s.X, s.Y + 2, s.Z), "stretch", true).Name = "MeshyShop"
			local sign = m:FindFirstChild("Sign")
			if sign then
				sign.Size = V(math.min(sign.Size.X, s.X * 0.7), 2.2, 0.3)
				sign.CFrame = cf * CFrame.new(0, (s.Y + 2) * 0.66, -s.Z / 2 - 0.6)
			end
			destroyNamed(m, { Body = 1, Storefront = 1, Door = 1, Awning = 1, Cornice = 1 })
			stats.shop += 1
		end
	end

	---------------------------------------------------------------- Entrepôts
	for _, m in all do
		if m:IsA("Model") and m:FindFirstChild("Body") and m:FindFirstChild("DockDoor") then
			local body = m.Body
			local s = body.Size
			local cf = CFrame.new(body.Position.X, body.Position.Y - s.Y / 2, body.Position.Z) * flatRot(body.CFrame)
			place("Warehouse", m, cf, V(s.X, s.Y + 1, s.Z), "stretch", true).Name = "MeshyWarehouse"
			destroyNamed(m, { Body = 1, Roof = 1, Skylight = 1, DockDoor = 1, DockLight = 1, DockStripe = 1 })
			stats.warehouse += 1
		end
	end

	---------------------------------------------------------------- Arbres (sauf palmiers)
	for _, m in map.Vegetation:GetChildren() do
		if m:IsA("Model") and m.Name == "Tree" then
			local trunk, isPine, isPalm = nil, false, false
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") then
					if p.Material == Enum.Material.Wood and not trunk then
						trunk = p
					elseif p:IsA("Part") and p.Shape == Enum.PartType.Cylinder then
						isPine = true
					elseif p:IsA("Part") and p.Shape == Enum.PartType.Block and p.Material == Enum.Material.Grass then
						isPalm = true
					end
				end
			end
			if trunk and not isPalm then
				local _, size = m:GetBoundingBox()
				local base = V(trunk.Position.X, trunk.Position.Y - trunk.Size.Y / 2, trunk.Position.Z)
				local cf = CFrame.new(base) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
				local mesh = place(isPine and "TreePine" or "TreeRound", m, cf, V(0, size.Y * 1.05, 0), "height", false)
				mesh.Name = "MeshyTree"
				for _, p in m:GetChildren() do
					if p:IsA("BasePart") and p ~= mesh and p ~= trunk then
						p:Destroy()
					end
				end
				trunk.Transparency = 1 -- garde une collision de tronc simple
				trunk.CastShadow = false
				stats.tree += 1
			end
		end
	end

	---------------------------------------------------------------- Lampadaires
	for _, m in map.LightingObjects:GetChildren() do
		if m:IsA("Model") and m.Name == "StreetLamp" then
			local pole, head
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") then
					if p.Size.Y > 10 then
						pole = p
					elseif p.Material == Enum.Material.Neon then
						head = p
					else
						p:Destroy()
					end
				end
			end
			if pole then
				local base = pole.CFrame * CFrame.new(0, -pole.Size.Y / 2, 0)
				place("StreetLamp", m, CFrame.new(base.Position) * flatRot(pole.CFrame), V(0, 14, 0), "height", false).Name = "MeshyLamp"
				pole.Transparency = 1
				pole.CastShadow = false
				if head then
					head.Transparency = 1
				end
				stats.lamp += 1
			end
		end
	end

	---------------------------------------------------------------- Bancs
	for _, m in map:GetDescendants() do
		if m:IsA("Model") and m.Name == "Bench" then
			local seat
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") and math.abs(p.Size.X - 5) < 0.1 and math.abs(p.Size.Y - 0.3) < 0.1 then
					seat = p
				end
			end
			if seat then
				local cf = seat.CFrame * CFrame.new(0, -1.6, 0)
				place("Bench", m, CFrame.new(cf.Position) * flatRot(cf), V(5, 0, 2.2), "fit", false).Name = "MeshyBench"
				for _, p in m:GetChildren() do
					if p:IsA("BasePart") and p.Name ~= "MeshyBench" then
						p:Destroy()
					end
				end
				stats.bench += 1
			end
		end
	end

	return ("Meshy : %d maisons, %d tours, %d boutiques, %d entrepôts, %d arbres, %d lampadaires, %d bancs"):format(stats.house, stats.tower, stats.shop, stats.warehouse, stats.tree, stats.lamp, stats.bench)
end
