--!nolint
-- 09 : zones de livraison, panneaux de quartier, mobilier urbain, arrêts de bus, bilan.
local Lib = require(script.Parent.Lib)
local M = Enum.Material
local C = Lib.C
local V = Vector3.new
local W = Lib.WALK
local CS = game:GetService("CollectionService")

local function surfaceY(x, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { Lib.path("DeliveryZones"), Lib.path("Vegetation"), Lib.path("LightingObjects") }
	local r = workspace:Raycast(V(x, 300, z), V(0, -400, 0), params)
	return r and r.Position.Y or 0
end

return function()
	local zones = Lib.path("DeliveryZones")
	local furn = Lib.path("StreetFurniture")
	local signs = Lib.path("Roads", "Signs")
	local white = Color3.new(1, 1, 1)

	---------------------------------------------------------------- Zones de livraison (repères, sans logique)
	local function zone(name, district, x, z)
		local y = surfaceY(x, z)
		local m = Lib.model(zones, "DeliveryZone_" .. name)
		local pad = Lib.deco(m, CFrame.new(x, y + 0.06, z), V(14, 0.1, 14), C.brandOrange, M.SmoothPlastic, { Transparency = 0.45, CastShadow = false, Name = "Pad" })
		Lib.label(pad, Enum.NormalId.Top, "LIVRAISON\n" .. name, white)
		for _, o in { { -7, 0, 0.4, 14 }, { 7, 0, 0.4, 14 }, { 0, -7, 14, 0.4 }, { 0, 7, 14, 0.4 } } do
			Lib.mark(m, CFrame.new(x + o[1], y + 0.08, z + o[2]), V(o[3], 0.05, o[4]), Color3.fromRGB(255, 230, 80))
		end
		local post = Lib.postSign(m, CFrame.new(x + 6.5, y, z + 6.5), "📦 " .. name, C.brandOrange, white, 6, 2, 6)
		pad:SetAttribute("DeliveryZone", name)
		pad:SetAttribute("District", district)
		CS:AddTag(pad, "DeliveryZone")
	end
	local dz = {
		{ "Place du Colis Perdu", "Downtown", Lib.cell(3, 3).ix1 + 12, Lib.cell(3, 3).iz1 + 12 },
		{ "Tours du Centre", "Downtown", Lib.cell(1, 1).cx, Lib.cell(1, 1).cz },
		{ "Parking Étagé", "Downtown", Lib.cell(3, 2).cx + 10, Lib.cell(3, 2).iz2 - 8 },
		{ "Rue des Lilas", "Residential", Lib.cell(1, 4).cx, Lib.cell(1, 4).iz2 - 6 },
		{ "Maisons de Ville", "Residential", Lib.cell(3, 4).cx, Lib.cell(3, 4).cz },
		{ "Méga-Marché", "Commercial", Lib.cell(4, 2).cx, Lib.cell(4, 2).iz2 - 25 },
		{ "Rue Commerçante", "Commercial", Lib.cell(5, 3).cx, Lib.cell(5, 3).cz + 10 },
		{ "Entrepôt Logistique", "Industrial", Lib.cell(5, 4).cx, Lib.cell(5, 4).cz },
		{ "Port à Conteneurs", "Industrial", Lib.cell(6, 4).ix1 + 10, Lib.cell(6, 4).iz2 - 10 },
		{ "Belvédère", "Hillside", 8, -870 },
		{ "Ferme", "Outskirts", -80, 580 },
		{ "Plage", "Outskirts", 874, 700 },
		{ "Motel", "Outskirts", 760, 346 },
	}
	for _, d in dz do
		zone(d[1], d[2], d[3], d[4])
	end

	---------------------------------------------------------------- Panneaux d'entrée de quartier
	local welcome = {
		{ V(-180, W, -25), V(1, 0, 0), "DOWNTOWN", Color3.fromRGB(40, 60, 120) },
		{ V(-25, W, 180), V(0, 0, -1), "QUARTIER RÉSIDENTIEL", Color3.fromRGB(40, 120, 70) },
		{ V(180, W, -25), V(-1, 0, 0), "QUARTIER COMMERCIAL", Color3.fromRGB(190, 60, 60) },
		{ V(184, W, 176), V(0, 0, -1), "ZONE INDUSTRIELLE", Color3.fromRGB(90, 90, 100) },
		{ V(26, 0.2, -520), V(0, 0, 1), "HILLSIDE — LES COLLINES", Color3.fromRGB(60, 110, 60) },
		{ V(26, 0.2, 520), V(0, 0, -1), "LA PÉRIPHÉRIE", Color3.fromRGB(120, 100, 60) },
		{ V(-520, 0.2, 28), V(1, 0, 0), "WRONG WAY CITY\njumelée avec Nulle-Part", C.brandBlue },
	}
	for _, s in welcome do
		local m = Lib.model(signs, "Welcome")
		local cf = CFrame.lookAt(s[1], s[1] - s[2])
		for _, x in { -5, 5 } do
			Lib.part(m, cf * CFrame.new(x, 4, 0), V(0.6, 8, 0.6), C.metal, M.Metal)
		end
		Lib.sign(m, cf * CFrame.new(0, 9, 0), V(14, 4, 0.4), s[3], s[4], white, { double = true })
	end

	---------------------------------------------------------------- Mobilier des trottoirs (centre-ville, commerces, QG)
	local count = 0
	for i = 1, 6 do
		for j = 1, 6 do
			local district = Lib.district(i, j)
			if district == "Downtown" or district == "Commercial" or district == "Headquarters" then
				local c = Lib.cell(i, j)
				local edges = {
					{ V(c.x1, 0, c.z1 + 4.6), V(c.x2, 0, c.z1 + 4.6), V(0, 0, -1) },
					{ V(c.x1, 0, c.z2 - 4.6), V(c.x2, 0, c.z2 - 4.6), V(0, 0, 1) },
					{ V(c.x1 + 4.6, 0, c.z1), V(c.x1 + 4.6, 0, c.z2), V(-1, 0, 0) },
					{ V(c.x2 - 4.6, 0, c.z1), V(c.x2 - 4.6, 0, c.z2), V(1, 0, 0) },
				}
				for e, ed in edges do
					local len = (ed[2] - ed[1]).Magnitude
					local dir = (ed[2] - ed[1]).Unit
					local k = 0
					for t = 24, len - 24, 26 do
						local p = ed[1] + dir * t + V(0, W, 0)
						local cf = CFrame.lookAt(p, p + ed[3])
						local kind = (k + i + j + e) % 5
						if kind == 0 then
							Lib.bench(furn, cf)
						elseif kind == 1 then
							Lib.trash(furn, cf)
						elseif kind == 2 then
							Lib.hydrant(furn, cf * CFrame.new(0, 0, -2))
						elseif kind == 3 and district == "Downtown" then
							Lib.part(furn, CFrame.new(p + V(0, 0.8, 0)), V(4, 1.6, 4), C.concrete, M.Concrete, { Name = "Planter" })
							Lib.tree(Lib.path("Vegetation"), p + V(0, 1.6, 0), "round", 0.7)
						end
						k += 1
						count += 1
					end
				end
			end
		end
	end

	-- Arrêts de bus
	local function busStop(pos, face, name)
		local m = Lib.model(furn, "BusStop")
		local cf = CFrame.lookAt(pos, pos + face)
		Lib.deco(m, cf * CFrame.new(0, 4, 1.6), V(10, 8, 0.3), Color3.fromRGB(170, 210, 230), M.Glass, { Transparency = 0.5, Name = "BackGlass" })
		Lib.deco(m, cf * CFrame.new(0, 8.2, 0), V(11, 0.4, 4), Color3.fromRGB(60, 64, 70), M.Metal, { Name = "Roof" })
		for _, x in { -5, 5 } do
			Lib.part(m, cf * CFrame.new(x, 4, 1.6), V(0.4, 8, 0.4), Color3.fromRGB(60, 64, 70), M.Metal)
		end
		Lib.bench(m, cf * CFrame.new(0, 0, 0.6))
		Lib.sign(m, cf * CFrame.new(0, 9, -1.9), V(10, 1.2, 0.2), "ARRÊT : " .. name, Color3.fromRGB(30, 80, 170), white, { double = true })
	end
	busStop(V(-60, W, -25.5), V(0, 0, 1), "PLACE DU COLIS PERDU")
	busStop(V(60, W, 25.5), V(0, 0, -1), "QG WRONG WAY (demi-tour)")
	busStop(V(-240, W, -176), V(0, 0, 1), "PARC CENTRAL")
	busStop(V(250, W, -144), V(0, 0, -1), "RUE COMMERÇANTE")
	busStop(V(-25.5, W, 260), V(1, 0, 0), "LES LILAS")

	---------------------------------------------------------------- Dégager les chaussées : déplace tout panneau posé sur une route
	do
		local roadsF = { workspace.Map.Roads.MainRoads, workspace.Map.Roads.SecondaryRoads, workspace.Map.Roads.Intersections }
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = roadsF
		local function onRoad(m)
			local cf, size = m:GetBoundingBox()
			local ws = cf:VectorToWorldSpace(size)
			local box = CFrame.new(cf.Position.X, Lib.ROAD - 0.3, cf.Position.Z)
			for _, h in workspace:GetPartBoundsInBox(box, Vector3.new(math.abs(ws.X) + 1, 0.4, math.abs(ws.Z) + 1), params) do
				if h.Name == "Road" or h.Name == "Intersection" or h.Name == "Ring" then
					return true
				end
			end
			return false
		end
		for _, m in signs:GetChildren() do
			if m:IsA("Model") and onRoad(m) then
				local base = m:GetPivot()
				local done = false
				for dist = 2, 40, 2 do
					for _, d in { V(1, 0, 0), V(-1, 0, 0), V(0, 0, 1), V(0, 0, -1) } do
						m:PivotTo(base + d * dist)
						if not onRoad(m) then
							done = true
							break
						end
					end
					if done then
						break
					end
				end
				if not done then
					m:PivotTo(base)
				end
			end
		end
	end

	---------------------------------------------------------------- Bilan et vérifications
	local parts, lights, colliders = 0, 0, 0
	for _, d in workspace.Map:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
			if d.CanCollide then
				colliders += 1
			end
			d.Locked = false
		elseif d:IsA("Light") then
			lights += 1
		end
	end
	workspace.Map:SetAttribute("Parts", parts)
	workspace.Map:SetAttribute("Lights", lights)
	return ("finitions ok : %d mobiliers, %d pièces (%d avec collision), %d lumières"):format(count, parts, colliders, lights)
end
