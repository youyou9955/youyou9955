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
	local deck = pk and pk:FindFirstChild("Deck")
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
	return ("finitions : %d vitrages recolorés sur %d tours, %d voitures sur le parking"):format(n, #towers, nc)
end
