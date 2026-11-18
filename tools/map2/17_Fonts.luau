--!nolint
-- 17 : applique les polices du jeu à tous les textes déjà posés dans workspace (enseignes, panneaux, lettres
-- WRONG WAY…) : Montserrat ExtraBold pour les enseignes, Roboto Condensed Bold pour la signalisation routière.
local Lib = require(script.Parent.Lib)

return function()
	local n, road = 0, 0
	for i, d in workspace:GetDescendants() do
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			local fam = d.FontFace.Family
			if fam:find("Gotham") or fam:find("RobotoCondensed") then
				d.FontFace = Lib.FONT_ROAD
				road += 1
			else
				d.FontFace = Lib.FONT_DISPLAY
			end
			n += 1
		end
		if i % 5000 == 0 then
			task.wait()
		end
	end
	return ("polices : %d textes (%d panneaux routiers en Roboto Condensed, %d enseignes en Montserrat)"):format(n, road, n - road)
end
