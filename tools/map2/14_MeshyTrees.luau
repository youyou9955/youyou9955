--!nolint
-- 14 : remplace tous les arbres déjà posés (MeshPart « Tree » issus de TreeL / PineL) par les arbres
-- générés avec Meshy AI (Assets.City.MeshyOak / MeshyMaple / MeshyBirch / MeshyPine). Même pied, même hauteur,
-- rotation aléatoire ; le collisionneur TreeTrunk est conservé. Les palmiers restent tels quels.
local Lib = require(script.Parent.Lib)
local city = game:GetService("ReplicatedStorage").Assets.City
local rng = Random.new(1414)

local function meshOf(n)
	local p = city:FindFirstChild(n)
	return p and p.MeshId or nil
end
local ROUND, PINE = meshOf("TreeL"), meshOf("PineL")
local ROUNDS = { "MeshyOak", "MeshyMaple", "MeshyBirch" }
assert(city:FindFirstChild("MeshyPine") and city:FindFirstChild("MeshyOak"), "arbres Meshy absents de Assets.City")

local list = {}
for _, d in workspace:GetDescendants() do
	if d:IsA("MeshPart") and d.Name == "Tree" and (d.MeshId == ROUND or d.MeshId == PINE) then
		table.insert(list, d)
	end
end

local n, np = 0, 0
for i, t in list do
	local pine = t.MeshId == PINE
	local name = pine and "MeshyPine" or ROUNDS[rng:NextInteger(1, #ROUNDS)]
	local src = city[name]
	local h = t.Size.Y
	local base = t.Position - Vector3.new(0, h / 2, 0)
	local m = src:Clone()
	for _, c in m:GetChildren() do
		if c:IsA("SurfaceAppearance") then
			c:Destroy()
		end
	end
	local s = src.Size * (h / src.Size.Y)
	m.Size = s
	m.CFrame = CFrame.new(base + Vector3.new(0, s.Y / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
	m.Anchored = true
	m.CanCollide = false
	m.CanQuery = false
	m.CanTouch = false
	m.CastShadow = true
	pcall(function()
		m.CollisionFidelity = Enum.CollisionFidelity.Box
		m.RenderFidelity = Enum.RenderFidelity.Automatic
	end)
	m.Name = "Tree"
	for _, c in t:GetChildren() do
		c.Parent = m
	end
	m.Parent = t.Parent
	t:Destroy()
	n += 1
	if pine then
		np += 1
	end
	if i % 60 == 0 then
		task.wait()
	end
end
print(("[14] arbres Meshy : %d remplacés (%d sapins, %d feuillus)"):format(n, np, n - np))
