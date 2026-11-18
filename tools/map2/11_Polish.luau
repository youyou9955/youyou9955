--!nolint
-- 11 : finitions. Vitrages du centre-ville variés (un ton par tour au lieu du cyan partout).
local Lib = require(script.Parent.Lib)
local rgb = Lib.rgb

local PALETTE = {
	rgb(126, 196, 236), -- bleu ciel (d'origine)
	rgb(120, 214, 196), -- turquoise
	rgb(242, 204, 128), -- ambre
	rgb(184, 170, 240), -- lavande
	rgb(92, 140, 220), -- bleu profond
	rgb(168, 228, 180), -- menthe
	rgb(240, 176, 196), -- rose
	rgb(200, 216, 226), -- argent
}

local function isGlass(p)
	return p:IsA("BasePart") and p.Material == Enum.Material.Glass
end

return function()
	local rng = Random.new(1111)
	local n = 0
	local towers = {}
	for _, d in Lib.path("Downtown"):GetDescendants() do
		if d:IsA("Model") and d:GetAttribute("Height") then
			table.insert(towers, d)
		end
	end
	for i, t in towers do
		if t:GetAttribute("Recolored") then
			continue
		end
		t:SetAttribute("Recolored", true)
		local base = PALETTE[rng:NextInteger(1, #PALETTE)]
		for _, p in t:GetDescendants() do
			if isGlass(p) then
				-- garde les nuances relatives (reflets) en mélangeant avec le ton choisi
				p.Color = base:Lerp(p.Color, 0.25)
				n += 1
			end
		end
		if i % 4 == 0 then
			task.wait()
		end
	end
	-- toit du parking à étages : voitures garées
	local nc = 0
	local pk = Lib.path("Downtown"):FindFirstChild("ParkingEtage", true)
	local deck
	for _, d in pk and pk:GetDescendants() or {} do
		if d.Name == "Deck" and d:IsA("BasePart") and (not deck or d.Position.Y > deck.Position.Y) then
			deck = d
		end
	end
	if deck and not pk:GetAttribute("RoofCars") then
		pk:SetAttribute("RoofCars", true)
		local top = deck.CFrame * CFrame.new(0, deck.Size.Y / 2, 0)
		local ov = OverlapParams.new()
		ov.FilterType = Enum.RaycastFilterType.Exclude
		ov.FilterDescendantsInstances = { deck }
		for _, row in { { -36, 0 }, { -22, math.pi }, { 22, 0 }, { 36, math.pi } } do
			for x = -38, 38, 9.5 do
				local cf = top * CFrame.new(x, 0, row[1]) * CFrame.Angles(0, row[2], 0)
				Lib.mark(pk, top * CFrame.new(x + 4.75, 0.03, row[1]), Lib.V(0.35, 0.05, 13), Lib.C.white)
				if rng:NextNumber() < 0.55 and #workspace:GetPartBoundsInBox(cf * CFrame.new(0, 3, 0), Lib.V(7, 5, 13), ov) == 0 then
					Lib.toyCar(Lib.path("DecorativeVehicles"), cf)
					nc += 1
				end
			end
		end
	end
	-- zone industrielle : remplit les grandes cours vides (conteneurs, palettes, citernes, cônes, voitures du personnel)
	local ni = 0
	local V, M = Lib.V, Lib.M
	local CONT = { Lib.rgb(220, 70, 50), Lib.rgb(40, 120, 200), Lib.rgb(250, 180, 40), Lib.rgb(60, 170, 100), Lib.rgb(240, 120, 40), Lib.rgb(150, 80, 190) }
	local ind = Lib.path("IndustrialZone")
	if not ind:GetAttribute("Filled") then
		ind:SetAttribute("Filled", true)
		for _, yard in ind:GetDescendants() do
			if yard.Name == "Yard" and yard:IsA("BasePart") then
				local fill = Lib.model(yard.Parent, "YardProps")
				local ov = OverlapParams.new()
				ov.FilterType = Enum.RaycastFilterType.Exclude
				ov.FilterDescendantsInstances = { yard, workspace.Terrain }
				local top = yard.CFrame * CFrame.new(0, yard.Size.Y / 2, 0)
				for gx = -yard.Size.X / 2 + 20, yard.Size.X / 2 - 20, 26 do
					for gz = -yard.Size.Z / 2 + 20, yard.Size.Z / 2 - 20, 26 do
						local cf = top * CFrame.new(gx, 0, gz)
						if rng:NextNumber() < 0.42 and #workspace:GetPartBoundsInBox(cf * CFrame.new(0, 6, 0), V(26, 12, 28), ov) == 0 then
							local r = rng:NextNumber()
							local rot = cf * CFrame.Angles(0, rng:NextInteger(0, 1) * math.pi / 2, 0)
							if r < 0.4 then
								-- pile de conteneurs
								local h = rng:NextInteger(1, 3)
								for k = 0, h - 1 do
									Lib.container(fill, rot * CFrame.new(-4.2, k * 8.5, 0), CONT[rng:NextInteger(1, #CONT)])
									if rng:NextNumber() < 0.6 then
										Lib.container(fill, rot * CFrame.new(4.2, k * 8.5, 0), CONT[rng:NextInteger(1, #CONT)])
									end
								end
							elseif r < 0.65 then
								-- palettes de colis
								for px = -1, 1 do
									for pz = -1, 1 do
										if rng:NextNumber() < 0.75 then
											Lib.pallet(fill, rot * CFrame.new(px * 5.5, 0, pz * 5.5), rng:NextInteger(2, 8))
										end
									end
								end
								Lib.cone(fill, rot * CFrame.new(10, 0, 10))
							elseif r < 0.82 then
								-- citernes
								for _, x in { -6, 6 } do
									local col = Lib.rgb(235, 235, 230)
									Lib.cyl(fill, rot * CFrame.new(x, 0.5, 0), 1, 11, Lib.rgb(150, 150, 150), M.Concrete)
									Lib.cyl(fill, rot * CFrame.new(x, 8, 0), 15, 10, col, M.Metal, { Name = "Tank" })
									Lib.cylDeco(fill, rot * CFrame.new(x, 6, 0), 1.2, 10.2, Lib.rgb(240, 90, 50), M.SmoothPlastic)
								end
							else
								-- voitures du personnel
								for k = -1, 1 do
									if rng:NextNumber() < 0.8 then
										Lib.toyCar(Lib.path("DecorativeVehicles"), rot * CFrame.new(k * 8, 0, 0))
									end
								end
							end
							ni += 1
						end
					end
				end
				task.wait()
			end
		end
	end
	-- grandes lettres WRONG WAY : plus grandes, plus haut sur le flanc est des collines, face à la ville
	local view = Lib.path("Landmarks"):FindFirstChild("Belvedere")
	local nl = 0
	if view and not view:GetAttribute("BigLetters") then
		view:SetAttribute("BigLetters", true)
		for _, p in view:GetChildren() do
			if p.Name == "Letter" then
				p:Destroy()
			end
		end
		local hill = require(script.Parent.Plan).hill
		local tp = RaycastParams.new()
		tp.FilterType = Enum.RaycastFilterType.Include
		tp.FilterDescendantsInstances = { workspace.Terrain }
		local ov = OverlapParams.new()
		ov.FilterType = Enum.RaycastFilterType.Exclude
		ov.FilterDescendantsInstances = { workspace.Terrain }
		local text = "WRONG WAY"
		for _, r in { 165, 150, 180, 195, 135 } do
			local cfs, ok = {}, true
			for k = 1, #text do
				local ch = text:sub(k, k)
				if ch ~= " " then
					local z = hill.c.Z + (k - 5) * 22
					local x = hill.c.X + math.sqrt(math.max(r * r - (z - hill.c.Z) ^ 2, 0))
					local hit = workspace:Raycast(V(x, 400, z), V(0, -800, 0), tp)
					local y = hit and hit.Position.Y or 0
					local cf = CFrame.lookAt(V(x, y + 10, z), V(x + 10, y + 12, z))
					if #workspace:GetPartBoundsInBox(cf, V(20, 22, 6), ov) > 0 then
						ok = false
						break
					end
					table.insert(cfs, { cf, ch })
				end
			end
			if ok then
				for _, e in cfs do
					local lp = Lib.part(view, e[1], V(18, 22, 1.6), Lib.C.white, M.SmoothPlastic, { Name = "Letter" })
					Lib.label(lp, Enum.NormalId.Front, e[2], Lib.rgb(230, 50, 50), nil, Enum.Font.FredokaOne, false, 12)
					Lib.part(view, e[1] * CFrame.new(0, -12, 1.5), V(1, 8, 1), Lib.rgb(90, 90, 96), M.Metal, { Name = "LetterPost" })
					nl += 1
				end
				break
			end
		end
	end
	return ("finitions : %d vitrages recolorés sur %d tours, %d voitures sur le parking, %d groupes industriels, %d lettres"):format(n, #towers, nc, ni, nl)
end
