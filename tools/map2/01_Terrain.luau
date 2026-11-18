--!nolint
-- 01 : terrain complet à partir de la carte des hauteurs de Plan (WriteVoxels par blocs de 128 studs).
-- Herbe, roche sur les pentes, sable au bord de l'eau, neige en haute montagne, eau dans la rivière et le lac.
local Plan = require(script.Parent.Plan)
local Lib = require(script.Parent.Lib)
local M = Enum.Material
local V = Vector3.new

local RES = 4
local X1, X2, Z1, Z2 = -1600, 1600, -1440, 1440
local YB = -24
local CH = 128

return function()
	local T = workspace.Terrain
	local W = Plan.WATER
	local n = CH / RES
	local done = 0
	for cx = X1, X2 - 1, CH do
		for cz = Z1, Z2 - 1, CH do
			-- hauteurs avec une bordure pour les pentes
			local H = {}
			local hmax = -1e9
			for i = 0, n + 1 do
				local row = {}
				H[i] = row
				for j = 0, n + 1 do
					local h = Plan.height(cx + (i - 0.5) * RES, cz + (j - 0.5) * RES)
					row[j] = h
					if i >= 1 and i <= n and j >= 1 and j <= n and h > hmax then
						hmax = h
					end
				end
			end
			local ytop = math.max(math.ceil((math.max(hmax, W) + 4) / RES) * RES, 4)
			local ny = (ytop - YB) / RES
			local region = Region3.new(V(cx, YB, cz), V(cx + CH, ytop, cz + CH))
			local mats, occ = {}, {}
			for i = 1, n do
				local mi, oi = {}, {}
				mats[i], occ[i] = mi, oi
				local hr = H[i]
				for k = 1, ny do
					mi[k], oi[k] = {}, {}
				end
				for j = 1, n do
					local h = hr[j]
					local slope = math.max(math.abs(H[i + 1][j] - H[i - 1][j]), math.abs(hr[j + 1] - hr[j - 1])) / (2 * RES)
					local top
					if h < 2 and Plan.riverDist(cx + (i - 0.5) * RES, cz + (j - 0.5) * RES) < Plan.river.w / 2 + 26 then
						top = M.Sand
					elseif h < 2 and (V(cx + (i - 0.5) * RES, 0, cz + (j - 0.5) * RES) - Plan.river.lake.c).Magnitude < Plan.river.lake.r + 30 then
						top = M.Sand
					elseif h > 170 then
						top = M.Snow
					elseif slope > 1.05 then
						top = M.Rock
					elseif slope > 0.8 then
						top = M.Ground
					elseif h > 2 and math.noise((cx + i * RES) / 60, (cz + j * RES) / 60, 2.2) > 0.25 then
						top = M.LeafyGrass
					else
						top = M.Grass
					end
					for k = 1, ny do
						local y0 = YB + (k - 1) * RES
						local o = math.clamp((h - y0) / RES, 0, 1)
						local m
						if o > 0 then
							if y0 + RES < h - 8 then
								m = M.Rock
							elseif y0 + RES < h - 3 and top ~= M.Sand then
								m = M.Ground
							else
								m = top
							end
						else
							m = M.Air
						end
						-- eau au-dessus du fond, jusqu'au niveau W
						if o < 1 and y0 < W and h < W then
							m = M.Water
							o = 1
						end
						mi[k][j] = m
						oi[k][j] = o
					end
				end
			end
			T:WriteVoxels(region, RES, mats, occ)
			done += 1
			task.wait()
		end
	end

	-- Limites invisibles
	local bounds = Lib.path("Boundaries")
	for _, b in { { 0, 1330, 3200, 4 }, { 0, -1330, 3200, 4 }, { 1460, 0, 4, 2800 }, { -1460, 0, 4, 2800 } } do
		Lib.part(bounds, CFrame.new(b[1], 150, b[2]), V(b[3], 400, b[4]), Color3.new(1, 1, 1), M.SmoothPlastic, { Transparency = 1, CanTouch = false, CastShadow = false, Name = "Boundary" })
	end
	return ("terrain : %d blocs"):format(done)
end
