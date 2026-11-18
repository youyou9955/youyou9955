--!nolint
-- 15 : remplace les voitures décoratives de la carte (ParkedCar, ParkedVan, ToyCar de Map.DecorativeVehicles)
-- par les voitures générées avec Meshy AI (Assets.City.MeshySedan / SUV / Hatchback / Pickup / Minivan).
-- Même emplacement et même axe ; les camions (ParkedTruck) sont conservés.
local Lib = require(script.Parent.Lib)

return function()
	local dv = Lib.path("DecorativeVehicles")
	assert(game.ReplicatedStorage.Assets.City:FindFirstChild("MeshySedan"), "voitures Meshy absentes de Assets.City")
	local n, kinds = 0, {}
	for i, v in dv:GetChildren() do
		if v:IsA("Model") and not v:GetAttribute("Meshy") and (v.Name == "ParkedCar" or v.Name == "ParkedVan" or v.Name == "ToyCar") then
			local cf, sz = v:GetBoundingBox()
			local axis
			local col = v:FindFirstChild("Collision")
			if col then
				axis = col.CFrame - col.CFrame.Position
			else
				axis = cf - cf.Position
				if sz.X > sz.Z then
					axis = axis * CFrame.Angles(0, math.pi / 2, 0)
				end
			end
			-- garder seulement le cap horizontal
			local look = axis.LookVector * Vector3.new(1, 0, 1)
			if look.Magnitude < 0.1 then
				look = Vector3.new(0, 0, -1)
			end
			local ground = cf.Position - Vector3.new(0, sz.Y / 2, 0)
			local gcf = CFrame.lookAt(ground, ground + look.Unit)
			local kind = v.Name == "ParkedVan" and "MeshyMinivan" or nil
			local car = Lib.meshyCar(dv, gcf, kind)
			if car then
				for _, a in { "Lot" } do
					if v:GetAttribute(a) then
						car:SetAttribute(a, v:GetAttribute(a))
					end
				end
				local k = car:GetAttribute("Meshy")
				kinds[k] = (kinds[k] or 0) + 1
				v:Destroy()
				n += 1
			end
			if i % 40 == 0 then
				task.wait()
			end
		end
	end
	local t = {}
	for k, c in kinds do
		table.insert(t, k .. "=" .. c)
	end
	return ("voitures Meshy : %d remplacées (%s)"):format(n, table.concat(t, ", "))
end
