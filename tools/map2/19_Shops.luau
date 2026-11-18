--!nolint
-- 19 : remplace les boutiques pleines de la galerie marchande (Build.shopBlock) par des commerces visitables
-- (ShopKit) : vitrine, double porte vitrée, rayons, caisse, réserve. Les anciens blocs sont sauvegardés dans
-- ServerStorage.Backups. Lib.SHOPS_ONLY (liste d'indices) limite le remplacement (boutique modèle).
local Lib = require(script.Parent.Lib)
local SK = require(script.Parent.ShopKit)
local HK = require(script.Parent.HouseKit)
local rgb, M = Lib.rgb, Lib.M

local rng = Random.new(1919)
-- index (ordre ouest -> est) : thème, enseigne, couleurs
local GALERIE = {
	{ theme = "grocery", label = "TACOS TOUT DROIT", accent = rgb(220, 110, 30), wall = rgb(214, 196, 170), wallMat = M.Brick },
	{ theme = "toys", label = "JOUETS ET KLAXONS", accent = rgb(50, 120, 210), wall = rgb(236, 230, 216), wallMat = M.Plaster },
	{ theme = "laundry", label = "LAVERIE LA ROUE LIBRE", accent = rgb(30, 150, 150), wall = rgb(150, 76, 60), wallMat = M.Brick },
	{ theme = "bikes", label = "VÉLOS SANS ROUES", accent = rgb(200, 50, 50), wall = rgb(188, 192, 194), wallMat = M.Concrete },
	{ theme = "boxes", label = "CARTONS VIDES", accent = rgb(150, 105, 60), wall = rgb(226, 214, 190), wallMat = M.Brick },
	{ theme = "phones", label = "TÉLÉPHONES PERDUS", accent = rgb(110, 60, 180), wall = rgb(236, 236, 232), wallMat = M.Plaster },
}

return function()
	local gal = Lib.path("CommercialDistrict", "GalerieMarchande")
	local backups = game:GetService("ServerStorage"):FindFirstChild("Backups") or Instance.new("Folder")
	backups.Name = "Backups"
	backups.Parent = game:GetService("ServerStorage")
	HK.installScript()
	-- boutiques existantes (anciens blocs ou ShopKit déjà posés), triées d'ouest en est
	local shops = {}
	for _, c in gal:GetChildren() do
		if c:IsA("Model") and (c.Name == "Shop" or c:GetAttribute("ShopIndex")) then
			local body = c:FindFirstChild("Body")
			local base
			if body then
				base = body.CFrame * CFrame.new(0, -body.Size.Y / 2, 0)
				c:SetAttribute("W", body.Size.X)
				c:SetAttribute("D", body.Size.Z)
				c:SetAttribute("Floors", math.floor((body.Size.Y - 11) / 8 + 0.5))
			else
				base = c:GetAttribute("BaseCF")
			end
			if base then
				table.insert(shops, { m = c, base = base })
			end
		end
	end
	table.sort(shops, function(a, b)
		return a.base.Position.X < b.base.Position.X
	end)
	-- workspace:SetAttribute("ShopsOnly", "2") limite le remplacement à certaines boutiques
	local only = Lib.SHOPS_ONLY
	local attr = workspace:GetAttribute("ShopsOnly")
	if attr and attr ~= "" then
		only = {}
		for v in tostring(attr):gmatch("%d+") do
			table.insert(only, tonumber(v))
		end
	end
	local n = 0
	for i, s in shops do
		if not only or table.find(only, i) then
			local g = GALERIE[i] or GALERIE[1]
			local W, D, floors = s.m:GetAttribute("W") or 34, s.m:GetAttribute("D") or 30, s.m:GetAttribute("Floors") or 1
			if s.m.Name == "Shop" and not backups:FindFirstChild("Galerie_" .. i) then
				local b = s.m:Clone()
				b.Name = "Galerie_" .. i
				b.Parent = backups
			end
			s.m:Destroy()
			local cf = s.base * CFrame.new(0, -0.3, -D / 2)
			local m = SK.build(gal, cf, { W = W, D = D, floors = floors, theme = g.theme, label = g.label, accent = g.accent, wall = g.wall, wallMat = g.wallMat, name = "Shop_" .. g.theme, doorX = (i % 2 == 0) and 5 or -5 }, rng)
			m:SetAttribute("ShopIndex", i)
			m:SetAttribute("BaseCF", s.base)
			m:SetAttribute("W", W)
			m:SetAttribute("D", D)
			m:SetAttribute("Floors", floors)
			n += 1
			task.wait()
		end
	end
	return ("commerces visitables : %d construits sur %d boutiques"):format(n, #shops)
end
