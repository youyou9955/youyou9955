--!nolint
-- 09t : tunnel du Col sous la crête nord (à relancer après toute régénération du terrain, qui le rebouche).
local Lib = require(script.Parent.Lib)
local Plan = require(script.Parent.Plan)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C

local function tunnel(parent)
	local t = Plan.tunnel
	local m = Lib.model(parent, "TunnelDuCol")
	local z1, z2 = t.z1 + 8, t.z2 - 8
	local len = math.abs(z2 - z1)
	local cz = (z1 + z2) / 2
	local W, H = 60, 26
	-- creuse le terrain
	-- épaulements rocheux autour des portails (le relief est trop bas à l'entrée)
	local T = workspace.Terrain
	for _, pz in { z1, z2 } do
		local s = pz == z1 and 1 or -1
		T:FillBall(V(0, H + 12, pz - s * 30), 44, M.Rock)
		for _, x in { -1, 1 } do
			T:FillBall(V(x * 52, 14, pz - s * 18), 40, M.Rock)
			T:FillBall(V(x * 78, 4, pz - s * 4), 30, M.Ground)
		end
		-- tranchée d'accès devant le portail
		T:FillBlock(CFrame.new(0, 40, pz + s * 40), V(W + 26, 80, 80), M.Air)
	end
	T:FillBlock(CFrame.new(0, H / 2 + 2, cz), V(W + 14, H + 10, len + 30), M.Air)
	Lib.part(m, CFrame.new(0, -0.4, cz), V(W + 4, 1, len + 20), rgb(120, 118, 116), M.Concrete, { Name = "Floor" })
	local wallC, ceilC = rgb(230, 226, 214), rgb(200, 196, 186)
	for _, s in { -1, 1 } do
		Lib.part(m, CFrame.new(s * (W / 2 + 1), H / 2, cz), V(2, H, len), wallC, M.SmoothPlastic, { Name = "Wall" })
		-- bandes de couleur
		Lib.fine(m, CFrame.new(s * (W / 2 - 0.05), 3, cz), V(0.1, 2, len), rgb(250, 190, 40), M.SmoothPlastic)
		Lib.fine(m, CFrame.new(s * (W / 2 - 0.05), 5, cz), V(0.1, 0.6, len), rgb(40, 110, 200), M.SmoothPlastic)
		-- angles arrondis (chanfreins)
		Lib.part(m, CFrame.new(s * (W / 2 - 3), H - 3, cz) * CFrame.Angles(0, 0, s * math.rad(45)), V(2, 9, len), ceilC, M.SmoothPlastic)
		-- trottoir de service
		Lib.part(m, CFrame.new(s * (W / 2 - 3), 0.7, cz), V(5, 1, len), rgb(206, 202, 194), M.Concrete)
	end
	Lib.part(m, CFrame.new(0, H + 1, cz), V(W + 4, 2, len), ceilC, M.SmoothPlastic, { Name = "Ceiling" })
	-- éclairage
	for k = 0, math.floor(len / 16) do
		local z = z1 - k * 16
		for _, x in { -10, 10 } do
			local l = Lib.fine(m, CFrame.new(x, H - 0.2, z), V(1.2, 0.3, 6), rgb(255, 236, 190), M.Neon)
			if k % 2 == 0 and x < 0 then
				local pl = Instance.new("PointLight")
				pl.Range, pl.Brightness, pl.Color, pl.Shadows = 30, 1.2, rgb(255, 226, 170), false
				pl.Parent = l
			end
		end
	end
	-- portails en pierre
	for _, pz in { z1, z2 } do
		local s = pz == z1 and 1 or -1
		local face = CFrame.new(0, 0, pz + s * 3)
		local stone = rgb(170, 160, 146)
		for _, x in { -1, 1 } do
			Lib.part(m, face * CFrame.new(x * (W / 2 + 6), (H + 12) / 2, 0), V(12, H + 12, 6), stone, M.Cobblestone, { Name = "Portal" })
		end
		Lib.part(m, face * CFrame.new(0, H + 6, 0), V(W + 2, 12, 6), stone, M.Cobblestone, { Name = "Portal" })
		Lib.part(m, face * CFrame.new(0, H + 1.5, s * 3.2), V(W + 8, 3, 1), rgb(220, 210, 190), M.SmoothPlastic)
		local sg = Lib.fine(m, face * CFrame.new(0, H + 6, s * 3.2), V(36, 5, 0.3), rgb(30, 90, 170), M.SmoothPlastic)
		local lab = Lib.label(sg, s > 0 and Enum.NormalId.Back or Enum.NormalId.Front, "TUNNEL DU COL", C.white, nil, Enum.Font.FredokaOne)
	end
	return m
end

return function()
	local f = Lib.path("Roads", "Tunnels")
	f:ClearAllChildren()
	tunnel(f)
	return "tunnel du Col reconstruit"
end
