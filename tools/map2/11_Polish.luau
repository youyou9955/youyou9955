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
	return ("finitions : %d vitrages recolorés sur %d tours"):format(n, #towers)
end
