--!nolint
-- 06 : zone industrielle (entrepôts, entrepôt géant, usine, port à conteneurs, parking camions, recyclage).
local Lib = require(script.Parent.Lib)
local M = Enum.Material
local C = Lib.C
local V = Vector3.new
local W = Lib.WALK

local CONT = { Color3.fromRGB(200, 60, 40), Color3.fromRGB(40, 90, 170), Color3.fromRGB(40, 140, 80), Color3.fromRGB(230, 160, 30), Color3.fromRGB(120, 120, 130), Color3.fromRGB(150, 50, 120) }

local function chainFence(parent, c, gapSide)
	local col = Color3.fromRGB(150, 155, 160)
	local x1, x2, z1, z2 = c.ix1 + 1, c.ix2 - 1, c.iz1 + 1, c.iz2 - 1
	local segs = {
		N = { V(x1, W, z2), V(x2, W, z2) }, S = { V(x1, W, z1), V(x2, W, z1) },
		W = { V(x1, W, z1), V(x1, W, z2) }, E = { V(x2, W, z1), V(x2, W, z2) },
	}
	for side, s in segs do
		if side == gapSide then
			local mid = (s[1] + s[2]) / 2
			local dir = (s[2] - s[1]).Unit
			Lib.fence(parent, s[1], mid - dir * 14, 7, col, true, M.DiamondPlate)
			Lib.fence(parent, mid + dir * 14, s[2], 7, col, true, M.DiamondPlate)
			-- barrière levée + guérite
			Lib.part(parent, CFrame.new(mid - dir * 16 + V(0, 4, 0)), V(4, 7, 4), Color3.fromRGB(230, 230, 220), M.Concrete, { Name = "GuardBooth" })
		else
			Lib.fence(parent, s[1], s[2], 7, col, true, M.DiamondPlate)
		end
	end
end

local function warehouse(parent, cf, w, d, h, color, name, docks)
	local m = Lib.model(parent, name or "Warehouse")
	Lib.part(m, cf * CFrame.new(0, h / 2, 0), V(w, h, d), color, M.Metal, { Name = "Body" })
	-- toit légèrement bombé
	Lib.deco(m, cf * CFrame.new(0, h + 0.6, 0), V(w + 1, 1.2, d + 1), color:Lerp(Color3.new(0, 0, 0), 0.3), M.Metal, { Name = "Roof" })
	for k = 1, 3 do
		Lib.deco(m, cf * CFrame.new(0, h + 1.4, -d / 2 + k * d / 4), V(w * 0.8, 0.6, 3), Color3.fromRGB(200, 230, 240), M.Glass, { Name = "Skylight", Transparency = 0.3 })
	end
	-- quais de chargement en façade
	docks = docks or math.floor(w / 14)
	for k = 0, docks - 1 do
		local x = -w / 2 + w / docks * (k + 0.5)
		Lib.deco(m, cf * CFrame.new(x, 5.5, -d / 2 - 0.15), V(9, 9, 0.3), Color3.fromRGB(200, 200, 205), M.DiamondPlate, { Name = "DockDoor" })
		Lib.part(m, cf * CFrame.new(x, 2, -d / 2 - 2), V(10, 4, 4), C.concrete, M.Concrete, { Name = "DockPlatform" })
		Lib.deco(m, cf * CFrame.new(x, 4.3, -d / 2 - 4.05), V(10, 0.6, 0.2), Color3.fromRGB(240, 200, 30), M.SmoothPlastic, { Name = "DockStripe" })
		Lib.deco(m, cf * CFrame.new(x, 10.6, -d / 2 - 0.6), V(1, 0.6, 1), Color3.fromRGB(255, 180, 60), M.Neon, { Name = "DockLight" })
	end
	Lib.sign(m, cf * CFrame.new(0, h - 4, -d / 2 - 0.2), V(math.min(w - 6, 60), 4.5, 0.3), name or "ENTREPÔT", C.dark, Color3.fromRGB(255, 220, 120))
	-- palettes devant
	for k = 1, 4 do
		Lib.pallet(m, cf * CFrame.new(Lib.rng:NextNumber(-w / 2 + 4, w / 2 - 4), 0, -d / 2 - Lib.rng:NextNumber(8, 14)), true)
	end
	return m
end

return function()
	local D = Lib.path("Districts", "Industrial")
	local rng = Lib.rng

	local function ground(f, c, mat, col)
		Lib.slab(f, c.ix1, c.ix2, c.iz1, c.iz2, W, 1, col or Color3.fromRGB(120, 120, 118), mat or M.Concrete, { Name = "Yard" })
	end

	-- (5,4) Entrepôts logistiques + zone de livraison
	do
		local c = Lib.cell(5, 4)
		local f = Lib.model(D, "Logistique")
		ground(f, c)
		warehouse(f, Lib.facing(V(c.cx, W, c.iz2 - 26), "S"), c.w - 10, 40, 22, Color3.fromRGB(80, 110, 150), "LOGISTIQUE APPROXIMATIVE", 6)
		warehouse(f, Lib.facing(V(c.cx, W, c.iz1 + 20), "N"), c.w - 30, 30, 18, Color3.fromRGB(170, 160, 140), "STOCK DES COLIS ÉGARÉS", 4)
		chainFence(f, c, "W")
	end

	-- (6,4) Port à conteneurs avec portique
	do
		local c = Lib.cell(6, 4)
		local f = Lib.model(D, "PortConteneurs")
		ground(f, c, M.Asphalt, C.asphaltLight)
		for row = 0, 3 do
			for col = 0, 4 do
				local h = rng:NextInteger(1, 3)
				for s = 0, h - 1 do
					local p = V(c.ix1 + 16 + col * 20, W + s * 8.5, c.iz1 + 18 + row * 26)
					Lib.container(f, CFrame.new(p) * CFrame.Angles(0, math.rad(rng:NextNumber(-2, 2)), 0), Lib.pick(CONT))
				end
			end
		end
		local yellow = Color3.fromRGB(240, 180, 30)
		local gx = c.ix2 - 12
		for _, z in { c.iz1 + 6, c.iz2 - 6 } do
			Lib.part(f, CFrame.new(gx, W + 22, z), V(3, 44, 3), yellow, M.Metal, { Name = "GantryLeg" })
			Lib.part(f, CFrame.new(gx - 18, W + 22, z), V(3, 44, 3), yellow, M.Metal, { Name = "GantryLeg" })
		end
		Lib.deco(f, CFrame.new(gx - 9, W + 45, c.cz), V(24, 3, c.d - 8), yellow, M.Metal, { Name = "GantryBeam" })
		Lib.deco(f, CFrame.new(gx - 9, W + 41, c.cz + 10), V(6, 5, 6), C.dark, M.Metal, { Name = "Trolley" })
		chainFence(f, c, "W")
	end

	-- (4,5) Parking poids lourds + atelier
	do
		local c = Lib.cell(4, 5)
		local f = Lib.model(D, "ParkingCamions")
		ground(f, c, M.Asphalt, C.asphalt)
		for k = 0, 5 do
			local x = c.ix1 + 12 + k * 17
			Lib.mark(f, CFrame.new(x - 8.5, W + 0.03, c.cz + 10), V(0.4, 0.05, 60))
			if rng:NextNumber() < 0.6 then
				local tr = Lib.model(f, "ParkedTrailer")
				Lib.part(tr, CFrame.new(x, W + 6, c.cz + 14), V(9, 9, 34), Lib.pick({ Color3.new(1, 1, 1), Color3.fromRGB(40, 70, 150), Color3.fromRGB(180, 40, 40) }), M.Metal)
				Lib.part(tr, CFrame.new(x, W + 1.5, c.cz + 14), V(7, 1, 30), C.dark, M.Metal)
			end
		end
		Lib.mark(f, CFrame.new(c.cx, W + 0.03, c.cz + 10), V(102, 0.05, 0.4))
		warehouse(f, Lib.facing(V(c.cx, W, c.iz1 + 16), "N"), 60, 24, 16, Color3.fromRGB(150, 90, 60), "GARAGE POIDS LOURDS — vidange & regrets", 3)
		Lib.postSign(f, CFrame.lookAt(V(c.ix1 + 4, W, c.iz2 - 4), V(c.ix1 - 4, W, c.iz2 - 4)), "Parking réservé aux camions\nqui reculent bien", Color3.fromRGB(30, 80, 170), Color3.new(1, 1, 1), 10, 3, 4)
	end

	-- (5,5) ENTREPÔT GÉANT
	do
		local c = Lib.cell(5, 5)
		local f = Lib.model(D, "EntrepotGeant")
		ground(f, c)
		local m = warehouse(f, Lib.facing(V(c.cx, W, c.cz + 8), "S"), c.w - 6, c.d - 30, 44, Color3.fromRGB(235, 235, 230), "ENTREPÔT GÉANT — 1 000 000 de cartons, 0 étiquette", 8)
		Lib.deco(m, CFrame.new(c.cx, W + 44 + 7, c.cz + 8) * CFrame.Angles(0, math.rad(15), math.rad(10)), V(14, 12, 14), Color3.fromRGB(196, 150, 96), M.Cardboard, { Name = "RoofParcel" })
		Lib.deco(m, CFrame.new(c.cx - 30, W + 44 + 10, c.cz + 8), V(1, 20, 1), C.metal, M.Metal)
		Lib.deco(m, CFrame.new(c.cx - 26, W + 44 + 17, c.cz + 8), V(8, 5, 0.2), C.brandOrange, M.Fabric, { Name = "Flag" })
	end

	-- (6,5) + (6,6) Usine : cheminées, cuves, tuyaux
	for _, j in { 5, 6 } do
		local c = Lib.cell(6, j)
		local f = Lib.model(D, "Usine_" .. j)
		ground(f, c)
		local b = Lib.model(f, "Factory")
		Lib.part(b, CFrame.new(c.cx - 14, W + 15, c.cz), V(70, 30, c.d - 30), Color3.fromRGB(150, 85, 70), M.Brick, { Name = "Hall" })
		for k = 0, 3 do
			Lib.part(b, CFrame.new(c.cx - 40 + k * 17, W + 33, c.cz) * CFrame.Angles(0, 0, math.rad(0)), V(16, 6, c.d - 30), Color3.fromRGB(120, 70, 60), M.Brick, { Class = "WedgePart", CFrame = CFrame.new(c.cx - 40 + k * 17, W + 33, c.cz) * CFrame.Angles(0, math.rad(90), 0) })
		end
		for k = 0, 2 do
			local ch = V(c.cx - 34 + k * 20, W + 30, c.cz + 20)
			Lib.part(b, CFrame.new(ch + V(0, 25, 0)) * CFrame.Angles(0, 0, math.rad(90)), V(50, 7, 7), Color3.fromRGB(170, 90, 70), M.Brick, { Shape = Enum.PartType.Cylinder, Name = "Chimney" })
			Lib.deco(b, CFrame.new(ch + V(0, 44, 0)) * CFrame.Angles(0, 0, math.rad(90)), V(1.2, 7.4, 7.4), Color3.new(1, 1, 1), M.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
			local smoke = Instance.new("Smoke")
			smoke.Color = Color3.fromRGB(220, 220, 225)
			smoke.Opacity = 0.12
			smoke.RiseVelocity = 6
			smoke.Size = 6
			smoke.Parent = b:GetChildren()[#b:GetChildren() - 1]
		end
		for k = 0, 2 do
			local t = V(c.ix2 - 16, W, c.iz1 + 20 + k * 38)
			Lib.part(b, CFrame.new(t + V(0, 12, 0)) * CFrame.Angles(0, 0, math.rad(90)), V(24, 18, 18), Color3.fromRGB(220, 220, 215), M.Metal, { Shape = Enum.PartType.Cylinder, Name = "Tank" })
			Lib.deco(b, CFrame.new(t + V(0, 24.4, 0)), V(19, 1, 19), Color3.fromRGB(200, 200, 200), M.Metal, { Shape = Enum.PartType.Ball })
			Lib.beam(b, t + V(-9, 18, 0), V(c.cx + 21, W + 18, t.Z), 1.6, 1.6, Color3.fromRGB(200, 120, 40), M.Metal, { CanCollide = false, CanTouch = false, CanQuery = false, Name = "Pipe" })
		end
		Lib.sign(b, CFrame.lookAt(V(c.cx - 14, W + 22, c.cz - (c.d - 30) / 2 - 0.3), V(c.cx - 14, W + 22, c.cz - 100)), V(50, 5, 0.3), j == 5 and "USINE DE PAPIER BULLE (à éclater)" or "FABRIQUE DE SCOTCH QUI COLLE PAS", C.dark, Color3.fromRGB(255, 220, 120))
		chainFence(f, c, "S")
	end

	-- (4,6) Recyclage / casse ; (5,6) petits entrepôts
	do
		local c = Lib.cell(4, 6)
		local f = Lib.model(D, "Recyclage")
		ground(f, c, M.Ground, Color3.fromRGB(120, 105, 85))
		for k = 1, 10 do
			Lib.ball(V(rng:NextNumber(c.ix1 + 12, c.ix2 - 40), -3, rng:NextNumber(c.iz1 + 12, c.iz2 - 12)), rng:NextNumber(6, 10), M.Slate)
		end
		for k = 1, 14 do
			local p = V(rng:NextNumber(c.ix1 + 6, c.ix2 - 6), W, rng:NextNumber(c.iz1 + 6, c.iz2 - 6))
			Lib.part(f, CFrame.new(p + V(0, 2, 0)) * CFrame.Angles(math.rad(rng:NextNumber(-20, 20)), rng:NextNumber(0, 6), math.rad(rng:NextNumber(-25, 25))), V(6, 3.5, 11), Color3.fromHSV(rng:NextNumber(), 0.5, 0.5), M.CorrodedMetal, { Name = "Wreck" })
		end
		warehouse(f, Lib.facing(V(c.ix2 - 22, W, c.cz), "W"), 50, 30, 16, Color3.fromRGB(90, 130, 90), "RECYCLAGE : on refait des cartons avec vos cartons", 2)
		chainFence(f, c, "S")
	end
	do
		local c = Lib.cell(5, 6)
		local f = Lib.model(D, "PetitsEntrepots")
		ground(f, c)
		warehouse(f, Lib.facing(V(c.cx - c.w / 4, W, c.cz), "S"), c.w / 2 - 8, 60, 16, Color3.fromRGB(190, 120, 70), "BOXES À LOUER", 3)
		warehouse(f, Lib.facing(V(c.cx + c.w / 4, W, c.cz), "S"), c.w / 2 - 8, 60, 20, Color3.fromRGB(110, 110, 140), "PALETTES & CIE", 3)
	end
	return "industriel ok"
end
