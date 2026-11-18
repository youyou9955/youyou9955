--!nolint
-- 03 : quartier général WRONG WAY DELIVERY (îlot x 36..274, z 36..274, au sud-est du rond-point central).
-- Bâtiment principal façade nord (vers le boulevard), tour à antenne, aile logistique et cour des camions au sud.
local Lib = require(script.Parent.Lib)
local Build = require(script.Parent.Build)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C

return function()
	local hq = Lib.path("DeliveryHeadquarters")
	local NORTH = V(0, 0, -1)
	local dark = rgb(38, 40, 50)
	local red = C.brandRed
	local orange = C.brandOrange
	local concrete = rgb(214, 212, 206)
	local glass = rgb(120, 190, 230)

	---------------------------------------------------------------- Bâtiment principal
	local main = Lib.model(hq, "MainBuilding")
	local cx, cz = 178, 128
	local W, D, H = 128, 56, 30
	local cf = Lib.facing(V(cx, 0, cz), NORTH)
	Lib.part(main, cf * CFrame.new(0, 0.5, 0), V(W + 2, 1, D + 2), rgb(170, 168, 162), M.Concrete, { Name = "Plinth" })
	Lib.part(main, cf * CFrame.new(0, H / 2 + 1, 0), V(W, H, D), concrete, M.SmoothPlastic, { Name = "Body" })
	-- façade : bandeau sombre sur toute la hauteur au centre, grandes baies sur les côtés
	local front = Build.face(cf, W, D, 1)
	Lib.part(main, front * CFrame.new(0, H / 2 + 1, -0.8), V(60, H + 2, 1.6), dark, M.SmoothPlastic, { Name = "SignWall" })
	for _, s in { -1, 1 } do
		for fl = 0, 2 do
			Lib.fine(main, front * CFrame.new(s * 47, 6 + fl * 9.5, -0.2), V(30, 6, 0.3), glass, M.Glass, { Reflectance = 0.2 })
			for k = -1, 1 do
				Lib.fine(main, front * CFrame.new(s * 47 + k * 10, 6 + fl * 9.5, -0.4), V(0.5, 6, 0.3), dark, M.SmoothPlastic)
			end
		end
		Lib.fine(main, front * CFrame.new(s * 47, H + 0.2, -0.6), V(34, 1.2, 1.2), red, M.SmoothPlastic)
	end
	-- grande enseigne
	local sign = Lib.part(main, front * CFrame.new(0, H - 6, -1.8), V(54, 11, 0.8), dark, M.SmoothPlastic, { Name = "HQSign", CanCollide = false })
	local g = Lib.label(sign, Enum.NormalId.Front, "", C.white, nil, Enum.Font.FredokaOne, true, 12)
	g.TextLabel.Text = "WRONG WAY\nDELIVERY"
	g.TextLabel.TextColor3 = C.white
	local stroke = g.TextLabel:FindFirstChildOfClass("UIStroke")
	stroke.Color, stroke.Thickness, stroke.Transparency = red, 4, 0
	-- logo : carton orange avec flèche à contresens
	local logo = Lib.part(main, front * CFrame.new(31, H - 4, -3) * CFrame.Angles(0, math.rad(20), math.rad(8)), V(8, 8, 8), rgb(214, 160, 96), M.Cardboard, { Name = "LogoBox", CanCollide = false })
	Lib.fine(main, logo.CFrame * CFrame.new(0, 4.02, 0), V(1.6, 0.05, 8), rgb(236, 214, 160), M.SmoothPlastic)
	local arrowP = Lib.fine(main, logo.CFrame * CFrame.new(0, 0, -4.03), V(6.6, 6.6, 0.05), rgb(214, 160, 96), M.SmoothPlastic)
	Lib.label(arrowP, Enum.NormalId.Front, "⇄", red, nil, Enum.Font.GothamBlack)
	-- bandeau rouge au-dessus du rez-de-chaussée
	Lib.fine(main, front * CFrame.new(0, 11.2, -2), V(W + 1, 1.6, 2.4), red, M.SmoothPlastic)
	-- entrée vitrée en avancée avec auvent
	local ent = front * CFrame.new(0, 0, -7)
	Lib.part(main, ent * CFrame.new(0, 5.5, 0), V(26, 10, 12), glass, M.Glass, { Name = "Atrium", Transparency = 0.3, Reflectance = 0.2 })
	for k = -2, 2 do
		Lib.fine(main, ent * CFrame.new(k * 6.5, 5.5, -6.05), V(0.6, 10, 0.3), dark, M.SmoothPlastic)
	end
	Lib.part(main, ent * CFrame.new(0, 11, -2), V(34, 1.2, 18), dark, M.SmoothPlastic, { Name = "Canopy" })
	Lib.fine(main, ent * CFrame.new(0, 11, -11.1), V(34, 1.2, 0.3), orange, M.Neon)
	for _, s in { -1, 1 } do
		Lib.part(main, ent * CFrame.new(s * 15.5, 5.5, -10), V(1, 10, 1), dark, M.Metal)
	end
	Lib.fine(main, ent * CFrame.new(0, 3.6, -6.2), V(8, 7, 0.2), rgb(30, 34, 40), M.SmoothPlastic)
	Lib.part(main, ent * CFrame.new(0, 0.6, -12), V(30, 1.2, 8), rgb(200, 196, 190), M.Concrete, { Name = "Steps" })
	-- tour à antenne (côté est)
	local tcf = cf * CFrame.new(W / 2 - 14, 0, 4)
	Lib.part(main, tcf * CFrame.new(0, (H + 26) / 2 + 1, 0), V(26, H + 26, 26), dark, M.SmoothPlastic, { Name = "Tower" })
	for i = 1, 4 do
		local f, fw = Build.face(tcf, 26, 26, i)
		for fl = 0, 4 do
			Lib.fine(main, f * CFrame.new(0, H + 2 + fl * 5, -0.15), V(20, 3, 0.3), glass, M.Glass, { Reflectance = 0.2 })
		end
		Lib.fine(main, f * CFrame.new(0, H + 26, -0.4), V(fw + 0.6, 1.4, 0.6), red, M.SmoothPlastic)
	end
	local tt = H + 27
	Lib.part(main, tcf * CFrame.new(0, tt + 3, 0), V(14, 6, 14), concrete, M.SmoothPlastic)
	Lib.cyl(main, tcf * CFrame.new(0, tt + 7, 0), 2, 10, rgb(200, 204, 210), M.Metal)
	Lib.cylDeco(main, tcf * CFrame.new(0, tt + 20, 0), 24, 1, C.metal, M.Metal)
	Lib.ball(main, (tcf * CFrame.new(0, tt + 32.5, 0)).Position, 1.4, red, M.Neon)
	local dish = Lib.cylDeco(main, tcf * CFrame.new(4, tt + 10, 0) * CFrame.Angles(math.rad(-40), 0, 0), 0.6, 6, rgb(235, 238, 242), M.SmoothPlastic)
	-- toit : équipements, panneaux solaires
	for k = 0, 5 do
		Lib.fine(main, cf * CFrame.new(-W / 2 + 14 + k * 11, H + 2, 8) * CFrame.Angles(math.rad(-15), 0, 0), V(9, 0.3, 14), rgb(40, 60, 110), M.Glass)
	end
	for k = 0, 2 do
		Lib.part(main, cf * CFrame.new(-20 + k * 12, H + 2.5, -14), V(6, 3, 5), rgb(190, 194, 200), M.Metal)
	end
	-- fenêtres latérales et arrière
	for i = 2, 4 do
		local f, fw = Build.face(cf, W, D, i)
		local n = math.floor(fw / 10)
		for fl = 0, 2 do
			for k = 1, n do
				local x = -fw / 2 + fw / n * (k - 0.5)
				if not (i == 2 and x > -fw / 2 + 4 and x < -fw / 2 + 30) then
					Build.window(main, f * CFrame.new(x, 6 + fl * 9.5, 0), 6, 5, dark, glass)
				end
			end
		end
	end

	---------------------------------------------------------------- Aile logistique et cour des camions
	local wcf = Lib.facing(V(178, 0, 196), V(0, 0, 1))
	local wh = Build.warehouse(hq, wcf, 128, 50, 20, rgb(236, 234, 228), rgb(70, 74, 84), red, "LogisticsWing", 6)
	local yard = Lib.model(hq, "TruckYard")
	Lib.part(yard, CFrame.new(178, 0.05, 246), V(190, 0.5, 52), Lib.C.asphaltDark, M.Asphalt, { Name = "Yard" })
	for k = 0, 5 do
		local x = 178 - 64 + 128 / 6 * (k + 0.5)
		Lib.mark(yard, CFrame.new(x, 0.32, 236), V(0.4, 0.05, 16), C.yellow)
		if k % 2 == 0 then
			Lib.vehicle("Truck", Lib.path("DecorativeVehicles"), CFrame.new(x, 0.3, 244) * CFrame.Angles(0, 0, 0))
		end
	end
	-- cartons et palettes devant les quais
	for k = 0, 9 do
		Lib.pallet(yard, CFrame.new(116 + k * 13, 0.3, 228 + (k % 3) * 2) * CFrame.Angles(0, math.rad(Lib.rng:NextNumber(-10, 10)), 0), Lib.rng:NextInteger(2, 8))
	end
	-- clôture et portail côté sud
	for _, seg in { { V(84, 0.3, 272), V(160, 0.3, 272) }, { V(196, 0.3, 272), V(272, 0.3, 272) }, { V(84, 0.3, 222), V(84, 0.3, 272) } } do
		Lib.fence(yard, seg[1], seg[2], "metal", 7)
	end
	local gate = Lib.model(yard, "Gate")
	for _, x in { 160, 196 } do
		Lib.part(gate, CFrame.new(x, 4.5, 272), V(1.6, 9, 1.6), red, M.SmoothPlastic)
	end
	Lib.fine(gate, CFrame.new(178, 8.6, 272), V(36, 1.6, 0.6), red, M.SmoothPlastic)
	local gs = Lib.fine(gate, CFrame.new(178, 8.6, 272.35), V(20, 1.4, 0.1), red, M.SmoothPlastic)
	Lib.label(gs, Enum.NormalId.Back, "LIVRAISONS", C.white, nil, Enum.Font.FredokaOne)
	Lib.driveway(yard, Lib.facing(V(178, 0, 300 - 16), V(0, 0, -1)), 36, 10)

	---------------------------------------------------------------- Parking des employés (côté ouest)
	Lib.parking(hq, CFrame.new(74, 0, 132) * CFrame.Angles(0, math.pi / 2, 0), 176, 66, 0.55, { "Van", "Van", "Car" })
	Lib.driveway(hq, Lib.facing(V(24, 0, 132), V(1, 0, 0)), 26, 12)
	Lib.driveway(hq, Lib.facing(V(74, 0, 24), V(0, 0, 1)), 26, 12)
	-- entrée côté rue du Commerce vers la cour
	Lib.driveway(hq, Lib.facing(V(284, 0, 246), V(-1, 0, 0)), 30, 10)

	---------------------------------------------------------------- Parvis, monument, drapeaux
	local gar = Lib.model(hq, "Forecourt")
	Lib.part(gar, CFrame.new(190, 0.3, 62), V(160, 0.6, 48), rgb(222, 216, 204), M.Pavement, { Name = "Plaza" })
	local mon = Lib.model(Lib.path("Landmarks"), "MonumentWWD")
	local mcf = Lib.facing(V(140, 0.6, 56), V(-0.5, 0, -1).Unit)
	Lib.part(mon, mcf * CFrame.new(0, 1, 0), V(26, 2, 8), concrete, M.SmoothPlastic)
	local ms = Lib.part(mon, mcf * CFrame.new(0, 6, 0), V(24, 8, 2), dark, M.SmoothPlastic, { Name = "MonumentSign" })
	Lib.label(ms, Enum.NormalId.Front, "WRONG WAY DELIVERY", C.white, nil, Enum.Font.FredokaOne, true)
	Lib.label(ms, Enum.NormalId.Back, "QUARTIER GÉNÉRAL", C.white, nil, Enum.Font.FredokaOne, true)
	Lib.fine(mon, mcf * CFrame.new(0, 10.4, 0), V(24, 0.8, 2.2), red, M.SmoothPlastic)
	Lib.flowers(mon, mcf * CFrame.new(0, 0, -6), 24, 3)
	for k = -1, 1 do
		local p = V(232 + k * 12, 0.6, 52)
		local fm = Lib.model(gar, "Flag")
		Lib.cyl(fm, CFrame.new(p + V(0, 13, 0)), 26, 0.6, C.white, M.Metal)
		local fl = Lib.fine(fm, CFrame.new(p + V(3.2, 23.5, 0)), V(6, 4, 0.15), k == 0 and red or (k < 0 and orange or dark), M.Fabric)
		Lib.label(fl, Enum.NormalId.Front, "WWD", C.white, nil, Enum.Font.FredokaOne)
		Lib.label(fl, Enum.NormalId.Back, "WWD", C.white, nil, Enum.Font.FredokaOne)
	end
	for _, x in { 120, 262 } do
		for _, z in { 46, 80 } do
			Lib.tree(gar, V(x, 0.6, z), "round", 15)
		end
	end
	for _, x in { 160, 200 } do
		Lib.bench(gar, Lib.facing(V(x, 0.6, 44), V(0, 0, 1)))
		Lib.planter(gar, CFrame.new(x + 10, 0.6, 44))
	end
	Lib.hedge(gar, V(112, 0.3, 88), V(150, 0.3, 88), 2.4, 2)
	Lib.hedge(gar, V(206, 0.3, 88), V(270, 0.3, 88), 2.4, 2)

	---------------------------------------------------------------- Point d'apparition
	local spawns = Lib.path("Spawns")
	local sp = Instance.new("SpawnLocation")
	sp.Name = "HQSpawn"
	sp.Anchored = true
	sp.Size = V(12, 1, 12)
	sp.CFrame = CFrame.new(178, 1.1, 70)
	sp.Material = M.SmoothPlastic
	sp.Color = red
	sp.TopSurface = Enum.SurfaceType.Smooth
	sp.Duration = 0
	sp.Neutral = true
	sp.Parent = spawns
	return "QG construit"
end
