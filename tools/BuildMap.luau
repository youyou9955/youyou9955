-- Wrong Way Delivery : générateur de la map (à lancer une fois dans Studio, en mode Edit,
-- via la barre de commande ou le MCP). Recrée Workspace.Map à chaque exécution.
--
-- Autoroute le long de l'axe Z. La chaussée de gauche (x < 0) roule vers +Z :
-- le joueur part du dépôt vers -Z, donc à contresens.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LENGTH_START, LENGTH_END = 80, -1500
local ROAD_TOP = 0.2

local old = workspace:FindFirstChild("Map")
if old then
	old:Destroy()
end

local map = Instance.new("Folder")
map.Name = "Map"
map.Parent = workspace

local function folder(name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = map
	return f
end

local function part(parent: Instance, props: { [string]: any }): BasePart
	local p = Instance.new(props.ClassName or "Part")
	props.ClassName = nil
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function box(parent, name, center: Vector3, size: Vector3, color: Color3, material: Enum.Material?)
	return part(parent, {
		Name = name,
		Size = size,
		CFrame = CFrame.new(center),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	})
end

local ASPHALT = Color3.fromRGB(45, 45, 50)
local WHITE = Color3.fromRGB(235, 235, 235)
local YELLOW = Color3.fromRGB(240, 200, 40)
local CONCRETE = Color3.fromRGB(170, 170, 165)
local METAL = Color3.fromRGB(150, 155, 160)
local GRASS = Color3.fromRGB(96, 150, 70)

---------------------------------------------------------------- Sol
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	for _, c in baseplate:GetChildren() do
		if c:IsA("Texture") or c:IsA("Decal") then
			c:Destroy()
		end
	end
	baseplate.Size = Vector3.new(2048, 16, 3400)
	baseplate.CFrame = CFrame.new(0, -8, -700)
	baseplate.Color = GRASS
	baseplate.Material = Enum.Material.Grass
end

local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
if spawn then
	spawn.CFrame = CFrame.new(-80, ROAD_TOP + 0.5, 40)
	for _, c in spawn:GetChildren() do
		if c:IsA("Decal") then
			c:Destroy()
		end
	end
	spawn.Color = Color3.fromRGB(240, 170, 40)
end

---------------------------------------------------------------- Autoroute
local road = folder("Highway")
local totalLen = LENGTH_START - LENGTH_END
local SEG = 200

for z0 = LENGTH_START, LENGTH_END + 1, -SEG do
	local len = math.min(SEG, z0 - LENGTH_END)
	local zc = z0 - len / 2
	box(road, "Asphalt", Vector3.new(0, ROAD_TOP - 0.5, zc), Vector3.new(112, 1, len), ASPHALT, Enum.Material.Asphalt)
	-- Terre-plein central (béton)
	box(road, "Median", Vector3.new(0, ROAD_TOP + 1.25, zc), Vector3.new(3, 2.5, len), CONCRETE, Enum.Material.Concrete)
	-- Lignes continues : bords et terre-plein
	for _, x in { -49, -4.5, 4.5, 49 } do
		box(road, "EdgeLine", Vector3.new(x, ROAD_TOP + 0.02, zc), Vector3.new(0.6, 0.05, len), if math.abs(x) < 10 then YELLOW else WHITE)
	end
	-- Glissières
	for _, x in { -56, 56 } do
		box(road, "Guardrail", Vector3.new(x, ROAD_TOP + 2, zc), Vector3.new(0.6, 1.2, len), METAL, Enum.Material.Metal)
	end
	task.wait()
end

-- Pointillés entre les voies
local dashes = folder("LaneDashes")
local n = 0
for z = LENGTH_START - 10, LENGTH_END + 10, -24 do
	for _, x in { -34.5, -19.5, 19.5, 34.5 } do
		box(dashes, "Dash", Vector3.new(x, ROAD_TOP + 0.02, z), Vector3.new(0.5, 0.05, 10), WHITE)
	end
	n += 1
	if n % 20 == 0 then
		task.wait()
	end
end

-- Poteaux de glissière + lampadaires
local lights = folder("StreetLights")
for z = LENGTH_START - 20, LENGTH_END + 20, -80 do
	for _, side in { -1, 1 } do
		local x = side * 58
		local blocksExit = side < 0 and (z > 0 or math.abs(z + 420) < 16 or math.abs(z + 820) < 16 or math.abs(z + 1220) < 16)
		if blocksExit then
			continue
		end
		box(lights, "Pole", Vector3.new(x, ROAD_TOP + 9, z), Vector3.new(0.8, 18, 0.8), METAL, Enum.Material.Metal)
		box(lights, "Arm", Vector3.new(x - side * 4, ROAD_TOP + 17.6, z), Vector3.new(8, 0.5, 0.5), METAL, Enum.Material.Metal)
		local lamp = box(lights, "Lamp", Vector3.new(x - side * 7.5, ROAD_TOP + 17.2, z), Vector3.new(2.5, 0.5, 1.4), Color3.fromRGB(255, 240, 200), Enum.Material.Neon)
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Bottom
		light.Range = 30
		light.Angle = 100
		light.Brightness = 2
		light.Color = Color3.fromRGB(255, 225, 170)
		light.Parent = lamp
	end
end
task.wait()

---------------------------------------------------------------- Ponts
local bridges = folder("Overpasses")
for _, z in { -320, -720, -1120 } do
	box(bridges, "Deck", Vector3.new(0, 24, z), Vector3.new(170, 2, 22), CONCRETE, Enum.Material.Concrete)
	for _, side in { -1, 1 } do
		box(bridges, "Rail", Vector3.new(0, 26, z + side * 10.5), Vector3.new(170, 2, 1), CONCRETE, Enum.Material.Concrete)
	end
	for _, x in { -62, 0, 62 } do
		box(bridges, "Pillar", Vector3.new(x, 11.5, z), Vector3.new(4, 23, 6), CONCRETE, Enum.Material.Concrete)
	end
end

---------------------------------------------------------------- Dos-d'âne et tremplins (sur la voie à contresens)
local hazards = folder("Hazards")
for _, z in { -150, -480, -860, -1260 } do
	part(hazards, {
		Name = "SpeedBump",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(44, 1.6, 1.6),
		CFrame = CFrame.new(-27, ROAD_TOP, z),
		Color = YELLOW,
		Material = Enum.Material.SmoothPlastic,
	})
end
for _, rz in { { -42, -600 }, { -12, -1000 } } do
	local x, z = rz[1], rz[2]
	-- Pente qui monte vers -Z (dans le sens du joueur)
	part(hazards, {
		ClassName = "WedgePart",
		Name = "Ramp",
		Size = Vector3.new(12, 3, 16),
		CFrame = CFrame.new(x, ROAD_TOP + 1.5, z) * CFrame.Angles(0, math.pi, 0),
		Color = Color3.fromRGB(230, 120, 30),
		Material = Enum.Material.Metal,
	})
end

---------------------------------------------------------------- Dépôt de départ
local depot = folder("Depot")
box(depot, "Lot", Vector3.new(-92, ROAD_TOP - 0.45, 30), Vector3.new(72, 1, 70), Color3.fromRGB(70, 70, 75), Enum.Material.Asphalt)
local building = box(depot, "Warehouse", Vector3.new(-110, ROAD_TOP + 10, 50), Vector3.new(36, 20, 28), Color3.fromRGB(200, 90, 50), Enum.Material.Brick)
box(depot, "Roof", Vector3.new(-110, ROAD_TOP + 20.5, 50), Vector3.new(38, 1, 30), Color3.fromRGB(80, 80, 85), Enum.Material.Metal)
box(depot, "Door", Vector3.new(-110, ROAD_TOP + 5, 35.9), Vector3.new(14, 10, 0.4), Color3.fromRGB(60, 60, 60), Enum.Material.DiamondPlate)
-- Cartons empilés devant l'entrepôt (décor)
for i = 0, 5 do
	box(depot, "StackedBox", Vector3.new(-122 + (i % 3) * 2.2, ROAD_TOP + 0.75 + (i // 3) * 1.5, 32), Vector3.new(2, 1.5, 2), Color3.fromRGB(196, 150, 96), Enum.Material.Cardboard)
end
-- Ouverture dans la glissière gauche pour sortir du dépôt
for _, c in road:GetChildren() do
	if c.Name == "Guardrail" and c.Position.X < 0 and c.Position.Z > -150 then
		c.Size = Vector3.new(c.Size.X, c.Size.Y, c.Size.Z - 70)
		c.Position = c.Position - Vector3.new(0, 0, 35)
	end
end

local sign = Instance.new("BillboardGui")
sign.Size = UDim2.fromScale(40, 8)
sign.MaxDistance = 400
sign.StudsOffset = Vector3.new(0, 14, 0)
sign.AlwaysOnTop = false
sign.Parent = building
local signText = Instance.new("TextLabel")
signText.Size = UDim2.fromScale(1, 1)
signText.BackgroundTransparency = 1
signText.Text = "WRONG WAY DELIVERY"
signText.TextColor3 = Color3.new(1, 1, 1)
signText.TextStrokeTransparency = 0
signText.Font = Enum.Font.GothamBlack
signText.TextScaled = true
signText.Parent = sign

---------------------------------------------------------------- Zones de livraison
local zones = folder("DeliveryZones")
for i, z in { -420, -820, -1220 } do
	-- Bretelle de sortie + parking
	box(zones, "ExitRoad", Vector3.new(-80, ROAD_TOP - 0.45, z), Vector3.new(50, 1, 24), ASPHALT, Enum.Material.Asphalt)
	box(zones, "Lot", Vector3.new(-120, ROAD_TOP - 0.45, z), Vector3.new(40, 1, 40), Color3.fromRGB(70, 70, 75), Enum.Material.Asphalt)
	local pad = part(zones, {
		Name = "DeliveryZone" .. i,
		Size = Vector3.new(18, 0.3, 18),
		CFrame = CFrame.new(-120, ROAD_TOP + 0.15, z),
		Color = Color3.fromRGB(60, 230, 90),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
	})
	pad:AddTag("DeliveryZone")
	pad:SetAttribute("Index", i)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(22, 5)
	bb.MaxDistance = 350
	bb.StudsOffset = Vector3.new(0, 8, 0)
	bb.Parent = pad
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = "📦 LIVRAISON " .. i
	t.TextColor3 = Color3.fromRGB(120, 255, 140)
	t.TextStrokeTransparency = 0
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.Parent = bb
	-- Maison du client
	box(zones, "House", Vector3.new(-152, ROAD_TOP + 7, z), Vector3.new(20, 14, 26), Color3.fromHSV((i * 0.27) % 1, 0.35, 0.95), Enum.Material.Plaster)
	part(zones, {
		ClassName = "WedgePart",
		Name = "HouseRoof",
		Size = Vector3.new(22, 6, 14),
		CFrame = CFrame.new(-152, ROAD_TOP + 17, z - 6.5),
		Color = Color3.fromRGB(150, 60, 50),
	})
	part(zones, {
		ClassName = "WedgePart",
		Name = "HouseRoof",
		Size = Vector3.new(22, 6, 14),
		CFrame = CFrame.new(-152, ROAD_TOP + 17, z + 6.5) * CFrame.Angles(0, math.pi, 0),
		Color = Color3.fromRGB(150, 60, 50),
	})
	-- Ouverture dans la glissière
	local rail = nil
	for _, c in road:GetChildren() do
		if c.Name == "Guardrail" and c.Position.X < 0 and math.abs(c.Position.Z - z) <= c.Size.Z / 2 then
			rail = c
		end
	end
	if rail then
		local zTop, zBot = rail.Position.Z + rail.Size.Z / 2, rail.Position.Z - rail.Size.Z / 2
		local gapTop, gapBot = z + 12, z - 12
		local a = rail:Clone()
		a.Size = Vector3.new(a.Size.X, a.Size.Y, zTop - gapTop)
		a.Position = Vector3.new(a.Position.X, a.Position.Y, (zTop + gapTop) / 2)
		a.Parent = road
		rail.Size = Vector3.new(rail.Size.X, rail.Size.Y, gapBot - zBot)
		rail.Position = Vector3.new(rail.Position.X, rail.Position.Y, (gapBot + zBot) / 2)
	end
end
task.wait()

---------------------------------------------------------------- Décor : arbres et immeubles
local scenery = folder("Scenery")
local rng = Random.new(42)
local treeCount = 0
for z = LENGTH_START, LENGTH_END, -30 do
	for _, side in { -1, 1 } do
		local x = side * rng:NextNumber(70, 200)
		local nearZone = side < 0 and (math.abs(z + 420) < 40 or math.abs(z + 820) < 40 or math.abs(z + 1220) < 40 or z > -20)
		if not nearZone then
			local h = rng:NextNumber(6, 12)
			box(scenery, "Trunk", Vector3.new(x, h / 2, z), Vector3.new(1.4, h, 1.4), Color3.fromRGB(110, 75, 45), Enum.Material.Wood)
			part(scenery, {
				Name = "Leaves",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * rng:NextNumber(7, 11),
				CFrame = CFrame.new(x, h + 3, z),
				Color = Color3.fromHSV(rng:NextNumber(0.24, 0.32), 0.6, rng:NextNumber(0.45, 0.65)),
				Material = Enum.Material.Grass,
			})
			treeCount += 1
		end
	end
	if treeCount % 30 == 0 then
		task.wait()
	end
end
for z = -60, LENGTH_END, -110 do
	local h = rng:NextNumber(30, 90)
	local w = rng:NextNumber(30, 50)
	box(scenery, "Building", Vector3.new(rng:NextNumber(230, 300), h / 2, z), Vector3.new(w, h, w), Color3.fromHSV(rng:NextNumber(0.55, 0.65), 0.1, rng:NextNumber(0.6, 0.85)), Enum.Material.Concrete)
	box(scenery, "Building", Vector3.new(-rng:NextNumber(240, 310), h / 2, z - 50), Vector3.new(w, h * 0.8, w), Color3.fromHSV(rng:NextNumber(0.05, 0.12), 0.25, rng:NextNumber(0.6, 0.85)), Enum.Material.Brick)
end
task.wait()

---------------------------------------------------------------- Véhicules Meshy en obstacles (ils viennent en face)
local traffic = folder("Traffic")
local assets = ReplicatedStorage:FindFirstChild("Assets")
if assets then
	local lanes = { -42, -27, -12 }
	local placed = 0
	for z = -90, LENGTH_END + 60, -55 do
		local lane = lanes[rng:NextInteger(1, 3)]
		local kind = if rng:NextNumber() < 0.3 then "Truck" else "Car"
		local src = assets:FindFirstChild(kind)
		if src and not (z < -580 and z > -620) and not (z < -980 and z > -1020) then
			local m = src:Clone()
			local _, size = m:GetBoundingBox()
			-- Le modèle regarde vers -Z : on le retourne pour qu'il arrive en face (+Z).
			m:PivotTo(CFrame.new(lane, ROAD_TOP + size.Y / 2, z) * CFrame.Angles(0, math.pi, 0))
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") then
					p.Anchored = true
					p.CanCollide = true
				end
			end
			m:AddTag("TrafficVehicle")
			m.Parent = traffic
			placed += 1
		end
	end
end

return "Map OK"
