--!nolint
-- 20 : grandes surfaces et restaurants visitables (ShopKit) à la place des boîtes pleines de l'étape 07 :
-- supermarché, centre commercial, cinéma, bricolage, 4 restaurants. Les éléments extérieurs éloignés de la
-- façade (mâts d'enseigne, terrasses, caddies) sont conservés ; l'ancien modèle est sauvegardé dans
-- ServerStorage.Backups. workspace:SetAttribute("BigOnly", "Supermarket,Restaurant") limite le remplacement.
local Lib = require(script.Parent.Lib)
local SK = require(script.Parent.ShopKit)
local HK = require(script.Parent.HouseKit)
local rgb, M = Lib.rgb, Lib.M

local rng = Random.new(2020)
local SPECS = {
	Supermarket = { theme = "grocery", label = "SUPER MARCHÉ", accent = rgb(220, 40, 40), wall = rgb(250, 248, 240), wallMat = M.SmoothPlastic, big = true, door = -0.25 },
	Mall = { theme = "mall", label = "CENTRE COMMERCIAL L'ENVERS", accent = rgb(120, 70, 190), wall = rgb(236, 230, 250), wallMat = M.SmoothPlastic, big = true, door = 0 },
	Cinema = { theme = "cinema", label = "CINÉMA LE RÉTROVISEUR", accent = rgb(230, 50, 120), wall = rgb(60, 40, 90), wallMat = M.SmoothPlastic, big = true, door = 0 },
	Hardware = { theme = "hardware", label = "BRICO LE DÉTOUR", accent = rgb(250, 140, 20), wall = rgb(250, 250, 246), wallMat = M.SmoothPlastic, big = true, door = -0.25 },
}
local RESTOS = {
	["BURGER RETOUR"] = { accent = rgb(230, 60, 40), wall = rgb(255, 240, 210), wallMat = M.Brick },
	["PIZZA SENS UNIQUE"] = { accent = rgb(40, 150, 70), wall = rgb(250, 250, 240), wallMat = M.Brick },
	["SUSHI DÉRAPAGE"] = { accent = rgb(200, 40, 40), wall = rgb(250, 250, 250), wallMat = M.Plaster },
	["CRÊPES À CONTRESENS"] = { accent = rgb(70, 130, 200), wall = rgb(255, 236, 200), wallMat = M.Plaster },
}

local function restoName(m)
	for _, d in m:GetDescendants() do
		if d:IsA("TextLabel") and RESTOS[d.Text] then
			return d.Text
		end
	end
end

return function()
	local root = Lib.path("CommercialDistrict")
	local backups = game:GetService("ServerStorage"):FindFirstChild("Backups") or Instance.new("Folder")
	backups.Name = "Backups"
	backups.Parent = game:GetService("ServerStorage")
	HK.installScript()
	local only = workspace:GetAttribute("BigOnly")
	local todo = {}
	for _, m in root:GetDescendants() do
		if m:IsA("Model") and m:FindFirstChild("Body") and not m:GetAttribute("ShopTheme") then
			local spec, label
			if SPECS[m.Name] then
				spec, label = SPECS[m.Name], SPECS[m.Name].label
			elseif m.Name == "Restaurant" then
				label = restoName(m)
				if label then
					spec = RESTOS[label]
				end
			end
			if spec and (not only or only == "" or string.find(only, m.Name, 1, true)) then
				table.insert(todo, { m = m, spec = spec, label = label })
			end
		end
	end
	local log = {}
	for i, t in todo do
		local m, sp = t.m, t.spec
		local body = m.Body
		local W, D, Hb = body.Size.X, body.Size.Z, body.Size.Y
		local base = body.CFrame * CFrame.new(0, -Hb / 2, 0)
		local b = m:Clone()
		b.Name = "Big_" .. m.Name .. "_" .. i
		b.Parent = backups
		-- conserver ce qui est loin du volume (mâts, terrasses, caddies) ; retirer l'auvent sur poteaux
		local keep = Lib.model(m.Parent, (t.label or m.Name) .. "_Exterieur")
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") and p ~= body and p.Name ~= "Canopy" then
				local lp = base:PointToObjectSpace(p.Position)
				local out = math.max(math.abs(lp.X) - W / 2, math.abs(lp.Z) - D / 2)
				local post = p.Size.Y > 10 and p.Size.X <= 1.01 and p.Size.Z <= 1.01 and lp.Z < -D / 2 and math.abs(lp.X) < W / 2
				if out > 2.5 and not post and lp.Y < Hb + 2 then
					p.Parent = keep
				end
			end
		end
		local name = m.Name == "Restaurant" and ("Resto_" .. t.label) or ("Shop_" .. m.Name)
		local parent = m.Parent
		m:Destroy()
		local cf = base * CFrame.new(0, -0.3, -D / 2)
		local spec = {
			W = W, D = D, theme = sp.theme or "restaurant", label = t.label, accent = sp.accent, wall = sp.wall, wallMat = sp.wallMat,
			name = name, big = sp.big, H = sp.big and math.max(Hb, 16) or nil, doorX = sp.big and math.floor(W * (sp.door or 0)) or -5,
		}
		local nm = SK.build(parent, cf, spec, rng)
		nm:SetAttribute("BaseCF", base)
		local c = 0
		for _, d in nm:GetDescendants() do
			if d:IsA("BasePart") then
				c += 1
			end
		end
		table.insert(log, ("%s %dx%d (%d pièces)"):format(name, W, D, c))
		task.wait()
	end
	return "grandes surfaces : " .. table.concat(log, ", ")
end
