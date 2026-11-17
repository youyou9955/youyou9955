--!nolint
-- 01 : nettoyage, arborescence, terrain (sol, rivière, lac, collines, montagnes), éclairage.
local Lib = require(script.Parent.Lib)
local M = Enum.Material

return function()
	-- Ancienne map, baseplate et spawns
	for _, name in { "Map", "Baseplate" } do
		local o = workspace:FindFirstChild(name)
		if o then
			o:Destroy()
		end
	end
	for _, o in workspace:GetChildren() do
		if o:IsA("SpawnLocation") then
			o:Destroy()
		end
	end
	local T = workspace.Terrain
	T:Clear()

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace
	Lib.folder(map, "Terrain")
	for _, n in { "MainRoads", "SecondaryRoads", "Intersections", "Sidewalks", "RoadMarkings", "Bridges", "Signs" } do
		Lib.path("Roads", n)
	end
	for _, n in { "Downtown", "Residential", "Industrial", "Commercial", "Hillside", "Outskirts" } do
		Lib.path("Districts", n)
	end
	for _, n in { "Headquarters", "Landmarks", "Vegetation", "StreetFurniture", "Decorations", "LightingObjects", "DeliveryZones", "Spawns" } do
		Lib.folder(map, n)
	end

	-- Sol : herbe de -16 à 0 sur 2800 x 2800
	for x = -1400, 1000, 400 do
		for z = -1400, 1000, 400 do
			Lib.fill(CFrame.new(x + 200, -8, z + 200), Vector3.new(400, 16, 400), M.Grass)
		end
	end
	-- Couche de fond (évite les trous sous la rivière)
	Lib.fill(CFrame.new(0, -20, 0), Vector3.new(2800, 8, 2800), M.Rock)

	-- Rivière (x 560..660) de la source (z -950) jusqu'au lac (z 680)
	local rz1, rz2 = -950, 600
	local rcz, rlen = (rz1 + rz2) / 2, rz2 - rz1
	Lib.fill(CFrame.new(610, -2, rcz), Vector3.new(130, 4, rlen), M.Sand) -- berges
	Lib.fill(CFrame.new(610, -8, rcz), Vector3.new(100, 16, rlen), M.Air)
	Lib.fill(CFrame.new(610, -7, rcz), Vector3.new(100, 10, rlen), M.Water)
	Lib.fill(CFrame.new(610, -14, rcz), Vector3.new(100, 4, rlen), M.Sand)
	for _, x in { 566, 654 } do -- bords peu profonds
		Lib.fill(CFrame.new(x, -8, rcz), Vector3.new(12, 4, rlen), M.Sand)
	end

	-- Source (étang) et lac avec plage
	local function basin(pos, r, sandR)
		T:FillCylinder(CFrame.new(pos.X, -2, pos.Z), 4, sandR, M.Sand)
		T:FillCylinder(CFrame.new(pos.X, -8, pos.Z), 16, r, M.Air)
		T:FillCylinder(CFrame.new(pos.X, -7, pos.Z), 10, r, M.Water)
		T:FillCylinder(CFrame.new(pos.X, -14, pos.Z), 4, r, M.Sand)
		Lib.yield(10)
	end
	basin(Vector3.new(610, 0, -950), 60, 74)
	basin(Vector3.new(660, 0, 690), 120, 150)
	-- Grande plage à l'est du lac
	Lib.fill(CFrame.new(800, -2, 690), Vector3.new(90, 4, 170), M.Sand)

	-- Collines du sud (Hillside)
	Lib.ball(Vector3.new(0, -100, -880), 160, M.Grass) -- colline principale (route en spirale)
	Lib.ball(Vector3.new(-200, -60, -680), 95, M.Grass)
	Lib.ball(Vector3.new(200, -70, -930), 110, M.Grass)
	Lib.ball(Vector3.new(320, -40, -650), 70, M.Grass) -- colline du tunnel
	-- Rochers sur les sommets
	Lib.ball(Vector3.new(-200, 28, -680), 14, M.Rock)
	Lib.ball(Vector3.new(220, 30, -950), 16, M.Rock)

	-- Montagnes de bordure (anneau autour de la carte)
	local rng = Random.new(42)
	for t = -1300, 1300, 110 do
		for _, p in { Vector3.new(t, 0, 1270), Vector3.new(t, 0, -1280), Vector3.new(1260, 0, t), Vector3.new(-1260, 0, t) } do
			local r = rng:NextNumber(150, 210)
			Lib.ball(Vector3.new(p.X + rng:NextNumber(-20, 20), -60 + rng:NextNumber(-20, 30), p.Z + rng:NextNumber(-20, 20)), r, M.Grass)
			Lib.ball(Vector3.new(p.X, r * 0.55, p.Z), r * 0.35, rng:NextNumber() < 0.5 and M.Rock or M.Snow)
		end
	end

	-- Murs invisibles de limite
	local bounds = Lib.folder(map, "Boundaries")
	for _, b in { { 0, 1200, 2500, 4 }, { 0, -1210, 2500, 4 }, { 1200, 0, 4, 2500 }, { -1200, 0, 4, 2500 } } do
		Lib.part(bounds, CFrame.new(b[1], 100, b[2]), Vector3.new(b[3], 220, b[4]), Color3.new(1, 1, 1), M.SmoothPlastic, { Transparency = 1, CanTouch = false, CastShadow = false, Name = "Boundary" })
	end

	-- Sol plat exactement à y = 0
	Lib.settle(-1400, -1400, 1400, 1400)

	-- Éclairage et ambiance
	local L = game:GetService("Lighting")
	for _, c in L:GetChildren() do
		if c:IsA("Atmosphere") or c:IsA("Sky") or c:IsA("PostEffect") then
			c:Destroy()
		end
	end
	L.ClockTime = 14.6
	L.GeographicLatitude = 35
	L.Brightness = 2.6
	L.Ambient = Color3.fromRGB(110, 110, 120)
	L.OutdoorAmbient = Color3.fromRGB(135, 135, 145)
	L.EnvironmentDiffuseScale = 0.6
	L.EnvironmentSpecularScale = 0.6
	L.GlobalShadows = true
	pcall(function()
		L.Technology = Enum.Technology.Future
	end)
	local atm = Instance.new("Atmosphere")
	atm.Density = 0.28
	atm.Offset = 0.15
	atm.Color = Color3.fromRGB(200, 215, 235)
	atm.Decay = Color3.fromRGB(110, 130, 160)
	atm.Glare = 0.3
	atm.Haze = 1.4
	atm.Parent = L
	local sky = Instance.new("Sky")
	sky.SunAngularSize = 14
	sky.Parent = L
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.4
	bloom.Size = 30
	bloom.Threshold = 1.6
	bloom.Parent = L
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.12
	cc.Contrast = 0.06
	cc.Brightness = 0.02
	cc.TintColor = Color3.fromRGB(255, 250, 240)
	cc.Parent = L
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.06
	rays.Spread = 0.8
	rays.Parent = L
	local clouds = T:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.55
	clouds.Density = 0.6
	clouds.Parent = T
	T.Decoration = false -- pas de brins d'herbe qui traversent les routes (et mieux pour mobile)
	T.WaterColor = Color3.fromRGB(40, 120, 150)
	T.WaterTransparency = 0.6
	T.WaterWaveSize = 0.12
	T.WaterReflectance = 0.6
	return "setup ok"
end
