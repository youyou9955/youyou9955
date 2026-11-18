--!nolint
-- 14 : passe « réaliste ». Remplace les maillages Meshy au style cartoon (arbres, palmiers, buissons,
-- tours, boutiques) par la série réaliste (suffixe R dans ReplicatedStorage.Assets.City), en gardant
-- la même empreinte au sol et la même orientation. À lancer après 10, 12 et 13. Idempotent.
local Lib = require(script.Parent.Lib)
local city = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("City")
local V = Vector3.new

local function place(name, parent, cfGround, target, mode, collide, newName)
	local b = city[name].Size
	local sc
	if mode == "stretch" then
		sc = V(target.X / b.X, target.Y / b.Y, target.Z / b.Z)
	else
		sc = Vector3.one * (target.Y / b.Y)
	end
	local sz = b * sc
	local m = city[name]:Clone()
	m.Size = sz
	m.CFrame = cfGround * CFrame.new(0, sz.Y / 2, 0)
	m.Anchored = true
	m.CanCollide = collide
	m.CanTouch = false
	m.CanQuery = collide
	m.CastShadow = sz.Y > 1.5
	pcall(function()
		m.CollisionFidelity = Enum.CollisionFidelity.Box
	end)
	m.Name = newName
	m:SetAttribute("Realistic", true)
	m.Parent = parent
	Lib.yield(2)
	return m
end

local function swap(old, name, mode)
	local cfGround = old.CFrame * CFrame.new(0, -old.Size.Y / 2, 0)
	local m = place(name, old.Parent, cfGround, old.Size, mode, old.CanCollide, old.Name)
	old:Destroy()
	return m
end

return function()
	local map = workspace.Map
	local rng = Random.new(4242)
	local st = { tree = 0, pine = 0, palm = 0, bush = 0, tower = 0, shop = 0 }
	local pineId = city.TreePine.MeshId
	local k = 0
	for _, d in map:GetDescendants() do
		if d:IsA("MeshPart") and d.Parent and not d:GetAttribute("Realistic") then
			if d.Name == "MeshyTree" then
				if d.MeshId == pineId then
					swap(d, "TreePineR", "height")
					st.pine += 1
				else
					swap(d, rng:NextNumber() < 0.5 and "TreeOakR" or "TreeLindenR", "height")
					st.tree += 1
				end
			elseif d.Name == "MeshyPalm" then
				swap(d, "TreePalmR", "height")
				st.palm += 1
			elseif d.Name == "MeshyBush" then
				swap(d, "BushR", "stretch")
				st.bush += 1
			elseif d.Name == "MeshyTower" then
				k += 1
				local s = d.Size
				local slender = s.Y > 1.8 * math.max(s.X, s.Z)
				local pick
				if slender then
					pick = (k % 3 == 0) and "OfficeR2" or "OfficeR1"
				else
					pick = (k % 2 == 0) and "OfficeR3" or "OfficeR2"
				end
				swap(d, pick, "stretch")
				st.tower += 1
			elseif d.Name == "MeshyShop" then
				swap(d, rng:NextNumber() < 0.5 and "ShopR1" or "ShopR2", "stretch")
				st.shop += 1
			end
		end
	end
	return ("réaliste : %d arbres, %d sapins, %d palmiers, %d buissons, %d immeubles, %d boutiques"):format(st.tree, st.pine, st.palm, st.bush, st.tower, st.shop)
end
