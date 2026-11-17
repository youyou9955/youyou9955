--!nolint
-- 12 : deuxième vague Meshy AI. Variantes de tours / boutiques / maisons (casse la répétition),
-- palmiers, poubelles, bouches d'incendie, boîtes aux lettres, vaches, buissons, jardinières,
-- abris de bus, socles des panneaux d'entrée et conteneurs bleus. À lancer après 10 et 11.
-- Toutes les façades Meshy regardent -Z (LookVector) ; le conteneur est long en X (rotation 90°).
local Lib = require(script.Parent.Lib)
local city = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("City")
local V = Vector3.new

local ROT = { Container = CFrame.Angles(0, math.pi / 2, 0) }

local function baseSize(name)
	local s = city[name].Size
	if ROT[name] then
		return V(s.Z, s.Y, s.X)
	end
	return s
end

-- cfGround : centre au sol, LookVector = façade ; target = (largeur, hauteur, profondeur)
local function place(name, parent, cfGround, target, mode, collide, newName)
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
	m.CastShadow = sz.Y > 1.5
	pcall(function()
		m.CollisionFidelity = Enum.CollisionFidelity.Box
	end)
	m.Name = newName or ("Meshy" .. name)
	m.Parent = parent
	Lib.yield(2)
	return m, sz
end

local function flat(cf)
	local look = cf.LookVector
	look = V(look.X, 0, look.Z)
	if look.Magnitude < 1e-3 then
		look = V(0, 0, -1)
	end
	return CFrame.lookAt(Vector3.zero, look.Unit)
end

-- Remplace un maillage Meshy existant par une variante (même empreinte au sol)
local function swap(old, name, mode)
	local h = old.Size.Y
	local cfGround = old.CFrame * CFrame.new(0, -h / 2, 0)
	local m = place(name, old.Parent, cfGround, old.Size, mode, old.CanCollide, old.Name)
	old:Destroy()
	return m
end

local function lowestY(model)
	local y = math.huge
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			local e = p.CFrame:VectorToWorldSpace(p.Size / 2)
			local ext = math.abs(p.CFrame.RightVector.Y) * p.Size.X / 2 + math.abs(p.CFrame.UpVector.Y) * p.Size.Y / 2 + math.abs(p.CFrame.LookVector.Y) * p.Size.Z / 2
			y = math.min(y, p.Position.Y - ext)
		end
	end
	return y
end

local function clearParts(model, keep)
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") and p ~= keep then
			p:Destroy()
		end
	end
end

return function()
	local map = workspace.Map
	local rng = Random.new(1234)
	local st = { tower = 0, shop = 0, house = 0, palm = 0, trash = 0, hydrant = 0, mailbox = 0, cow = 0, bush = 0, planter = 0, bus = 0, welcome = 0, container = 0 }
	local all = map:GetDescendants()

	---------------------------------------------------------------- Variantes de bâtiments
	local houseB, houseC = city.HouseB.MeshId, city.HouseC.MeshId
	local k = 0
	for _, d in all do
		if d:IsA("MeshPart") and d.Parent then
			if d.Name == "MeshyTower" then
				k += 1
				local s = d.Size
				local slender = s.Y > 1.8 * math.max(s.X, s.Z)
				local pick = k % 3
				if pick == 1 then
					swap(d, slender and "OfficeB" or "OfficeC", "stretch")
					st.tower += 1
				elseif pick == 2 then
					swap(d, slender and "OfficeC" or "OfficeB", "stretch")
					st.tower += 1
				end
			elseif d.Name == "MeshyShop" then
				local r = rng:NextInteger(0, 2)
				if r > 0 then
					swap(d, r == 1 and "ShopB" or "ShopC", "stretch")
					st.shop += 1
				end
			elseif d.Name == "MeshyHouse" and (d.MeshId == houseB or d.MeshId == houseC) then
				if rng:NextNumber() < 0.5 then
					swap(d, rng:NextNumber() < 0.5 and "HouseD" or "HouseE", "fit")
					st.house += 1
				end
			end
		end
	end

	---------------------------------------------------------------- Palmiers (les arbres restants)
	for _, m in map.Vegetation:GetChildren() do
		if m:IsA("Model") and m.Name == "Tree" and not m:FindFirstChild("MeshyTree") and not m:FindFirstChild("MeshyPalm") then
			local trunk
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") and p.Material == Enum.Material.Wood and (not trunk or p.Position.Y < trunk.Position.Y) then
					trunk = p
				end
			end
			if trunk then
				local _, size = m:GetBoundingBox()
				local y = lowestY(m)
				local cf = CFrame.new(trunk.Position.X, y, trunk.Position.Z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
				place("TreePalm", m, cf, V(0, size.Y * 1.05, 0), "height", false, "MeshyPalm")
				clearParts(m, trunk)
				trunk.Transparency = 1
				trunk.CastShadow = false
				st.palm += 1
			end
		end
	end

	---------------------------------------------------------------- Petit mobilier (modèles)
	local PROPS = {
		TrashCan = { mesh = "TrashCan", h = 3.1, key = "trash", spin = true },
		Hydrant = { mesh = "Hydrant", h = 2.3, key = "hydrant", spin = true },
		Mailbox = { mesh = "Mailbox", key = "mailbox" },
		Cow = { mesh = "Cow", key = "cow" },
	}
	for _, m in map:GetDescendants() do
		local def = m:IsA("Model") and PROPS[m.Name]
		if def and not m:FindFirstChild("Meshy" .. def.mesh) then
			local cf, size = m:GetBoundingBox()
			local y = lowestY(m)
			local rot
			if def.spin then
				rot = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
			else
				-- orientation : la plus grande pièce donne l'axe long (Z de la vache, X de la boîte)
				local big
				for _, p in m:GetChildren() do
					if p:IsA("BasePart") and (not big or p.Size.Magnitude > big.Size.Magnitude) then
						big = p
					end
				end
				rot = big and flat(big.CFrame) or CFrame.identity
				if big and def.mesh == "Cow" and big.Size.X > big.Size.Z then
					rot *= CFrame.Angles(0, math.pi / 2, 0)
				end
			end
			local h = def.h or size.Y
			place(def.mesh, m, CFrame.new(cf.Position.X, y, cf.Position.Z) * rot, V(0, h, 0), "height", false)
			clearParts(m, m:FindFirstChild("Meshy" .. def.mesh))
			st[def.key] += 1
		end
	end

	---------------------------------------------------------------- Buissons et jardinières (pièces)
	for _, p in map:GetDescendants() do
		if p:IsA("BasePart") and p.Parent and not p:IsA("MeshPart") then
			if p.Name == "Bush" then
				local s = p.Size.X
				local ground = p.Position.Y - s * 0.35
				place("Bush", p.Parent, CFrame.new(p.Position.X, ground, p.Position.Z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), V(s * 1.15, s * 0.95, s * 1.15), "stretch", false, "MeshyBush")
				p:Destroy()
				st.bush += 1
			elseif p.Name == "Planter" then
				local s = p.Size
				place("Planter", p.Parent, CFrame.new(p.Position.X, p.Position.Y - s.Y / 2, p.Position.Z) * flat(p.CFrame), V(s.X + 0.2, s.Y * 1.7, s.Z + 0.2), "stretch", true, "MeshyPlanter")
				p:Destroy()
				st.planter += 1
			end
		end
	end

	---------------------------------------------------------------- Abris de bus
	for _, m in map:GetDescendants() do
		if m:IsA("Model") and m.Name == "BusStop" and m:FindFirstChild("BackGlass") then
			local roof = m:FindFirstChild("Roof")
			local cf = CFrame.new(roof.Position.X, roof.Position.Y - 8.2, roof.Position.Z) * flat(roof.CFrame)
			place("BusStop", m, cf * CFrame.new(0, 0, 0.3), V(11, 8.4, 4.4), "stretch", true)
			for _, c in m:GetChildren() do
				if c.Name == "Bench" or (c:IsA("BasePart") and c.Name ~= "Sign" and c.Name ~= "MeshyBusStop") then
					c:Destroy()
				end
			end
			st.bus += 1
		end
	end

	---------------------------------------------------------------- Socles des panneaux d'entrée
	for _, m in map.Roads.Signs:GetChildren() do
		if m:IsA("Model") and m.Name == "Welcome" and not m:FindFirstChild("MeshyWelcomeBase") then
			local sign = m:FindFirstChild("Sign")
			if sign then
				local cf = CFrame.new(sign.Position.X, lowestY(m), sign.Position.Z) * flat(sign.CFrame)
				place("WelcomeBase", m, cf, V(16, 2.6, 3.4), "stretch", true)
				st.welcome += 1
			end
		end
	end

	---------------------------------------------------------------- Conteneurs bleus
	for _, p in map:GetDescendants() do
		if p:IsA("BasePart") and p.Name == "Container" and not p:IsA("MeshPart") then
			local h, s, v = p.Color:ToHSV()
			if h > 0.52 and h < 0.72 and s > 0.35 then
				local cfG = p.CFrame * CFrame.new(0, -p.Size.Y / 2, 0)
				for _, q in p.Parent:GetChildren() do
					if q:IsA("BasePart") and q.Name == "Part" and math.abs(q.Size.X - 7.4) < 0.05 and math.abs(q.Size.Z - 0.1) < 0.05 and (q.Position - p.Position).Magnitude < 11 then
						q:Destroy()
					end
				end
				place("Container", p.Parent, CFrame.new(cfG.Position) * flat(cfG), V(p.Size.X, p.Size.Y, p.Size.Z), "stretch", true, "MeshyContainer")
				p:Destroy()
				st.container += 1
			end
		end
	end

	return ("Meshy 2 : %d tours, %d boutiques, %d maisons (variantes), %d palmiers, %d poubelles, %d bouches, %d boîtes aux lettres, %d vaches, %d buissons, %d jardinières, %d abris de bus, %d socles, %d conteneurs"):format(
		st.tower, st.shop, st.house, st.palm, st.trash, st.hydrant, st.mailbox, st.cow, st.bush, st.planter, st.bus, st.welcome, st.container)
end
