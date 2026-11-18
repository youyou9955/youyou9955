--!nolint
-- Essai visuel des bâtiments (efface et reconstruit Map.Test)
local Lib = require(script.Parent.Lib)
local Build = require(script.Parent.Build)
local V, rgb = Lib.V, Lib.rgb
return function()
	local old = workspace.Map:FindFirstChild("Test")
	if old then old:Destroy() end
	local f = Lib.folder(workspace.Map, "Test")
	local face = CFrame.lookAt(V(0,0,0), V(0,0,-1))
	Build.house(f, CFrame.new(60, 0, 380) * face, { w = 20, d = 16, floors = 1, wall = Build.WALLS[1], roof = Build.ROOFS[1], door = Build.DOORS[1], porch = true, chimney = true, shutters = rgb(60,110,160), flowerBoxes = true })
	Build.house(f, CFrame.new(110, 0, 380) * face, { w = 22, d = 18, floors = 2, wall = Build.WALLS[2], roof = Build.ROOFS[2], door = Build.DOORS[4], wing = true, garage = "right", chimney = true })
	Build.house(f, CFrame.new(170, 0, 380) * face, { w = 18, d = 20, floors = 2, ridgeZ = true, wall = Build.WALLS[4], roof = Build.ROOFS[4], door = Build.DOORS[2], porch = true, shutters = rgb(255,255,255) })
	Build.tower(f, CFrame.new(80, 0, 470) * face, 36, 32, 14, { body = rgb(236, 210, 170), kind = "grid", crown = "stepped", setback = true }, { { "CAFÉ", rgb(220, 60, 60) }, { "LIVRES", rgb(40, 120, 200) }, corner = true })
	Build.tower(f, CFrame.new(140, 0, 470) * face, 30, 30, 20, { body = rgb(80, 150, 220), glass = rgb(110, 190, 240), kind = "glass", crown = "spire" }, { { "BANQUE", rgb(30, 90, 160) } })
	Build.tower(f, CFrame.new(200, 0, 470) * face, 34, 30, 9, { body = rgb(190, 80, 60), kind = "brick", trim = rgb(245, 235, 220) }, { { "PIZZA", rgb(240, 120, 30) }, { "FLEURS", rgb(230, 80, 150) } })
	Build.shopBlock(f, CFrame.new(250, 0, 470) * face, 24, 22, 2, rgb(120, 190, 200), rgb(255,255,255), { "BOULANGERIE", rgb(200, 90, 40) })
	Build.warehouse(f, CFrame.new(150, 0, 580) * face, 70, 50, 22, rgb(110, 140, 170), rgb(90, 96, 106), rgb(255, 170, 30), "Warehouse")
	return "test ok"
end
