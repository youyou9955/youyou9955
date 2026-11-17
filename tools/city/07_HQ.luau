--!nolint
-- 07 : QG Wrong Way Delivery (îlot 4,4 : x 22..147, z 22..147), face à l'avenue z = 0.
local Lib = require(script.Parent.Lib)
local M = Enum.Material
local C = Lib.C
local V = Vector3.new
local W = Lib.WALK

return function()
	local HQ = Lib.path("Headquarters")
	local c = Lib.cell(4, 4)
	local O, B = C.brandOrange, C.brandBlue
	local white = Color3.new(1, 1, 1)

	-- sol : parking devant (sud), cour de quais à l'est
	Lib.slab(HQ, c.ix1, c.ix2, c.iz1, c.iz2, W, 1, C.asphalt, M.Asphalt, { Name = "Ground" })
	local zFront = c.iz1 + 44 -- façade du bâtiment
	local bx1, bx2 = c.ix1 + 6, c.ix2 - 30
	local bz2 = c.iz2 - 6
	local bw, bd = bx2 - bx1, bz2 - zFront
	local bcx, bcz = (bx1 + bx2) / 2, (zFront + bz2) / 2
	local h = 34

	-- bâtiment principal
	local b = Lib.model(HQ, "MainBuilding")
	Lib.part(b, CFrame.new(bcx, W + h / 2, bcz), V(bw, h, bd), Color3.fromRGB(245, 245, 245), M.Concrete, { Name = "Body" })
	for f = 0, 2 do
		Lib.deco(b, CFrame.new(bcx, W + 6 + f * 10.5, bcz), V(bw + 0.3, 5.2, bd + 0.3), Color3.fromRGB(70, 110, 160), M.Glass, { Transparency = 0.05, Name = "Windows", CastShadow = false })
	end
	-- bande orange diagonale (flèche géante à l'envers sur la façade)
	Lib.deco(b, CFrame.new(bcx, W + h / 2, zFront - 0.35) * CFrame.Angles(0, 0, math.rad(-18)), V(bw * 1.05, 4, 0.4), O, M.SmoothPlastic, { Name = "Stripe" })
	Lib.deco(b, CFrame.new(bcx, W + h + 0.8, bcz), V(bw + 1, 1.6, bd + 1), B, M.Concrete, { Name = "Parapet" })
	-- entrée imposante : portique bleu + auvent + colonnes orange
	local ex = bcx
	Lib.part(b, CFrame.new(ex, W + 9, zFront - 8), V(36, 1.4, 16), B, M.Metal, { Name = "EntranceCanopy" })
	for _, x in { -16, 16 } do
		Lib.part(b, CFrame.new(ex + x, W + 4.5, zFront - 14.5), V(2.2, 9, 2.2), O, M.SmoothPlastic, { Name = "Column" })
	end
	Lib.deco(b, CFrame.new(ex, W + 4, zFront - 0.3), V(14, 8, 0.4), Color3.fromRGB(40, 50, 60), M.Glass, { Name = "RevolvingDoor", Transparency = 0.2 })
	Lib.slab(b, ex - 18, ex + 18, zFront - 16, zFront, W + 0.4, 0.4, Color3.fromRGB(220, 215, 205), M.Marble, { Name = "EntranceFloor" })
	local mat = Lib.deco(b, CFrame.new(ex, W + 0.45, zFront - 4), V(10, 0.1, 4), O)
	Lib.label(mat, Enum.NormalId.Top, "BIENVENUE / EUNEVNEIB", white)

	-- enseigne géante sur le toit + flèche qui pointe vers l'arrière
	local sign = Lib.sign(b, CFrame.new(bcx, W + h + 10, zFront + 2), V(bw - 4, 14, 1.2), "WRONG WAY DELIVERY", O, white, { glow = true, double = true, name = "GiantSign" })
	sign.CFrame = CFrame.lookAt(sign.Position, sign.Position - V(0, 0, 1))
	for _, x in { -bw / 3, 0, bw / 3 } do
		Lib.deco(b, CFrame.new(bcx + x, W + h + 2.5, zFront + 2.5), V(1, 5, 1), C.metal, M.Metal)
	end
	Lib.deco(b, CFrame.new(bcx, W + h + 19.5, zFront + 2), V(26, 4, 1), B, M.Neon, { Name = "ArrowShaft" })
	Lib.deco(b, CFrame.new(bcx + 15, W + h + 19.5, zFront + 2) * CFrame.Angles(0, 0, math.rad(45)), V(6, 6, 1), B, M.Neon, { Name = "ArrowHead" })
	local tag = Lib.deco(b, CFrame.new(bcx, W + h + 1.6, zFront + 1.4), V(bw - 10, 2.2, 0.2), B)
	Lib.label(tag, Enum.NormalId.Front, "Livraison express... dans l'autre sens", white)
	-- colis géant à l'envers sur le toit
	Lib.deco(b, CFrame.new(bx2 - 18, W + h + 9, bz2 - 14) * CFrame.Angles(math.rad(180), math.rad(20), 0), V(14, 12, 14), Color3.fromRGB(196, 150, 96), M.Cardboard, { Name = "UpsideDownParcel" })
	local arrow = Lib.deco(b, CFrame.new(bx2 - 18, W + h + 9, bz2 - 21.1) * CFrame.Angles(0, math.rad(20), 0), V(8, 8, 0.1), Color3.fromRGB(196, 150, 96))
	Lib.label(arrow, Enum.NormalId.Front, "↓ HAUT ↓", Color3.fromRGB(60, 30, 10))
	Lib.ac(b, CFrame.new(bx1 + 12, W + h + 1.6, bz2 - 10))
	Lib.ac(b, CFrame.new(bx1 + 20, W + h + 1.6, bz2 - 10))
	-- tour de contrôle (radar de livraison)
	Lib.part(b, CFrame.new(bx1 + 10, W + h + 8, bcz + 6), V(8, 16, 8), B, M.Concrete)
	Lib.deco(b, CFrame.new(bx1 + 10, W + h + 18, bcz + 6) * CFrame.Angles(0, 0, math.rad(90)), V(1, 12, 12), white, M.Metal, { Shape = Enum.PartType.Cylinder, Name = "RadarDish" })

	-- quais de chargement (côté est, face à la rue x = 160)
	local docks = Lib.model(HQ, "LoadingDocks")
	for k = 0, 4 do
		local z = zFront + 10 + k * 16
		Lib.part(docks, CFrame.new(bx2 + 2, W + 2, z), V(4, 4, 12), C.concrete, M.Concrete, { Name = "DockPlatform" })
		Lib.deco(docks, CFrame.new(bx2 + 0.2, W + 6, z), V(0.3, 9, 10), O, M.DiamondPlate, { Name = "DockDoor" })
		local n = Lib.deco(docks, CFrame.new(bx2 + 0.4, W + 12, z), V(0.2, 2, 4), C.dark)
		Lib.label(n, Enum.NormalId.Right, "QUAI " .. (5 - k), Color3.fromRGB(255, 220, 120))
		Lib.mark(docks, CFrame.new(bx2 + 14, W + 0.03, z - 6.5), V(20, 0.05, 0.4), Color3.fromRGB(240, 200, 30))
		for p = 1, 2 do
			Lib.pallet(docks, CFrame.new(bx2 + 6 + p * 5, W, z + 3), true)
		end
	end
	local dz = Lib.deco(docks, CFrame.new(bx2 + 15, W + 0.04, bcz), V(18, 0.05, 82), O, M.SmoothPlastic, { Transparency = 0.55, Name = "DeliveryZone_HQ" })
	dz:SetAttribute("DeliveryZone", "QG")
	game:GetService("CollectionService"):AddTag(dz, "DeliveryZone")
	dz.Parent = Lib.path("DeliveryZones")

	-- parking du personnel (devant)
	local pk = Lib.model(HQ, "StaffParking")
	Lib.parkingRow(pk, CFrame.new(bcx - 30, W, c.iz1 + 12), 5, 10, 14)
	Lib.parkingRow(pk, CFrame.new(bcx + 30, W, c.iz1 + 12), 5, 10, 14)
	local emp = Lib.deco(pk, CFrame.new(bcx - 30, W + 0.04, c.iz1 + 12), V(9.5, 0.05, 13), O)
	Lib.label(emp, Enum.NormalId.Top, "EMPLOYÉ DU MOIS : LE GPS", white)
	-- flèches contradictoires
	Lib.arrow(pk, CFrame.new(bcx - 8, W, c.iz1 + 26) * CFrame.Angles(0, math.rad(90), 0))
	Lib.arrow(pk, CFrame.new(bcx + 8, W, c.iz1 + 26) * CFrame.Angles(0, math.rad(-90), 0))

	-- panneaux d'humour
	local function post(pos, face, text, bg, fg, w, hh)
		Lib.postSign(HQ, CFrame.lookAt(pos, pos + face), text, bg, fg, w, hh, 5)
	end
	post(V(bcx + 22, W, zFront - 18), V(0, 0, -1), "0 JOUR SANS ACCIDENT\n(record : 0)", Color3.fromRGB(240, 190, 30), Color3.new(0, 0, 0), 9, 3.5)
	post(V(bcx - 22, W, zFront - 18), V(0, 0, -1), "← SORTIE     SORTIE →", Color3.fromRGB(20, 120, 60), white, 9, 2.5)
	post(V(c.ix1 + 4, W, c.iz1 + 30), V(-1, 0, 0), "QG WRONG WAY DELIVERY\nEntrée par la sortie", B, white, 10, 3.5)
	post(V(c.ix2 - 4, W, c.iz1 + 4), V(0, 0, -1), "Service client :\nfaites demi-tour au rond-point", O, white, 9, 3)
	post(V(bx2 + 26, W, c.iz2 - 6), V(1, 0, 0), "Quais : marche arrière\nOBLIGATOIRE (en avant)", Color3.fromRGB(200, 30, 30), white, 9, 3)
	-- drapeaux, jardinières, boîte à idées
	for k = 0, 2 do
		local p = V(bcx - 34 + k * 5, W, zFront - 20)
		Lib.part(HQ, CFrame.new(p + V(0, 11, 0)), V(0.4, 22, 0.4), white, M.Metal, { Name = "Flagpole" })
		Lib.deco(HQ, CFrame.new(p + V(2.4, 19.5, 0)), V(4.4, 2.8, 0.1), k == 1 and B or O, M.Fabric, { Name = "Flag" })
	end
	for _, x in { -26, 26 } do
		Lib.flowerBed(HQ, CFrame.new(ex + x, W, zFront - 4), 12, 4)
	end
	local box = Lib.part(HQ, CFrame.new(ex + 20, W + 2, zFront - 2), V(2, 4, 1.4), Color3.fromRGB(200, 40, 40), M.Metal, { Name = "IdeaBox" })
	Lib.label(box, Enum.NormalId.Front, "BOÎTE À IDÉES\n(vide depuis 2003)", white)
	-- grand totem côté avenue
	local tot = V(c.ix1 + 14, W, c.iz1 + 4)
	Lib.part(HQ, CFrame.new(tot + V(0, 12, 0)), V(6, 24, 2), B, M.Metal, { Name = "Totem" })
	Lib.sign(HQ, CFrame.lookAt(tot + V(0, 16, -1.1), tot + V(0, 16, -5)), V(5.6, 14, 0.2), "W\nW\nD", B, O, { glow = true })

	-- spawn joueur devant l'entrée
	local sp = Instance.new("SpawnLocation")
	sp.Name = "HQSpawn"
	sp.Anchored = true
	sp.Size = V(10, 1, 10)
	sp.CFrame = CFrame.new(ex - 26, W + 0.5, zFront - 26)
	sp.Color = O
	sp.Material = M.SmoothPlastic
	sp.Duration = 0
	sp.Parent = Lib.path("Spawns")
	return ("QG ok (façade z=%.0f)"):format(zFront)
end
