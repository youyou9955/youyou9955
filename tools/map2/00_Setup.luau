--!nolint
-- 00 : efface l'ancienne map (une copie complète du jeu est faite avant), prépare l'arborescence
-- et règle l'éclairage cartoon. Ne touche ni aux scripts ni à ReplicatedStorage.
local Lib = require(script.Parent.Lib)
local rgb = Color3.fromRGB

return function()
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
	-- anciennes sauvegardes internes (le fichier WrongWayDelivery_ancienne_map.rbxl les contient)
	for _, n in { "HouseBody_Backup", "Sauvegarde_MaisonsArbres" } do
		local o = game.ServerStorage:FindFirstChild(n)
		if o then
			o:Destroy()
		end
	end
	workspace.Terrain:Clear()

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace
	for _, n in { "Terrain", "Roads", "Downtown", "ResidentialDistrict", "IndustrialZone", "CommercialDistrict", "HillsideDistrict", "Outskirts", "DeliveryHeadquarters", "Vegetation", "StreetFurniture", "Landmarks", "DecorativeVehicles", "LightingReferences", "Spawns", "Boundaries" } do
		Lib.folder(map, n)
	end
	for _, n in { "Asphalt", "Markings", "Sidewalks", "Intersections", "Roundabouts", "Bridges", "Tunnels", "Signals", "Signs" } do
		Lib.folder(map.Roads, n)
	end

	-- Éclairage : journée ensoleillée, couleurs franches
	local L = game:GetService("Lighting")
	for _, c in L:GetChildren() do
		if c:IsA("Atmosphere") or c:IsA("Sky") or c:IsA("PostEffect") then
			c:Destroy()
		end
	end
	L.ClockTime = 14.2
	L.GeographicLatitude = 38
	L.Brightness = 3
	L.Ambient = rgb(118, 118, 132)
	L.OutdoorAmbient = rgb(150, 150, 165)
	L.EnvironmentDiffuseScale = 0.5
	L.EnvironmentSpecularScale = 0.4
	L.ExposureCompensation = 0
	L.GlobalShadows = true
	L.ShadowSoftness = 0.3
	pcall(function()
		L.Technology = Enum.Technology.ShadowMap
	end)
	local atm = Instance.new("Atmosphere")
	atm.Density, atm.Offset, atm.Glare, atm.Haze = 0.26, 0.1, 0.15, 1.2
	atm.Color = rgb(196, 220, 245)
	atm.Decay = rgb(120, 150, 190)
	atm.Parent = L
	local sky = Instance.new("Sky")
	sky.SunAngularSize = 12
	sky.Parent = L
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity, bloom.Size, bloom.Threshold = 0.35, 26, 1.7
	bloom.Parent = L
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation, cc.Contrast, cc.Brightness = 0.22, 0.08, 0.02
	cc.TintColor = rgb(255, 251, 242)
	cc.Parent = L
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity, rays.Spread = 0.05, 0.7
	rays.Parent = L

	local T = workspace.Terrain
	local clouds = T:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover, clouds.Density = 0.5, 0.75
	clouds.Color = Color3.new(1, 1, 1)
	clouds.Parent = T
	T.Decoration = false
	T.WaterColor = rgb(30, 150, 190)
	T.WaterTransparency = 0.45
	T.WaterWaveSize = 0.1
	T.WaterWaveSpeed = 8
	T.WaterReflectance = 0.5
	local M = Enum.Material
	T:SetMaterialColor(M.Grass, rgb(106, 176, 70))
	T:SetMaterialColor(M.LeafyGrass, rgb(92, 160, 62))
	T:SetMaterialColor(M.Sand, rgb(236, 214, 158))
	T:SetMaterialColor(M.Rock, rgb(150, 140, 128))
	T:SetMaterialColor(M.Ground, rgb(128, 98, 70))
	T:SetMaterialColor(M.Snow, rgb(245, 248, 252))
	T:SetMaterialColor(M.Asphalt, rgb(70, 72, 80))
	return "setup ok"
end
