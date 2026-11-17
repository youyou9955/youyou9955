--!nolint
-- 11 : panneaux façon vraie signalisation.
-- Panneaux routiers (poteaux, limitations, entrées de quartier, arrêts de bus, zones de livraison) :
-- tôle plate couleur réglementaire, liseré intérieur fin de la couleur du texte, coins légèrement
-- arrondis, police de signalisation (Arimo gras), dos en aluminium brut, poteaux en acier galvanisé.
-- STOP : vrai octogone rouge à bord blanc. Enseignes et panneaux publicitaires : plaque simple.
-- Idempotent ; retire aussi l'ancien style « cartoon » (dégradés, reflets, capuchons orange).
local Lib = require(script.Parent.Lib)
local V = Vector3.new
local PPS = 40
local ALU = Color3.fromRGB(188, 190, 194)
local STEEL = Color3.fromRGB(160, 163, 168)
local FONT = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Bold)
local ROAD = { PostSign = true, SpeedLimit = true, Welcome = true, BusStop = true }

local function isRoadSign(part)
	local a = part.Parent
	while a and a ~= workspace do
		if ROAD[a.Name] or string.sub(a.Name, 1, 13) == "DeliveryZone_" then
			return true
		end
		if a.Name == "Signs" and a.Parent and a.Parent.Name == "Roads" then
			return true
		end
		a = a.Parent
	end
	return false
end

-- Retire l'ancien habillage (version précédente de cette passe)
local function strip(map)
	for _, d in map:GetDescendants() do
		if d:IsA("SurfaceGui") then
			if d.Name == "BackPlate" then
				d:Destroy()
			else
				local panel = d:FindFirstChild("Panel")
				if panel then
					local label = panel:FindFirstChildOfClass("TextLabel")
					if label then
						label.Parent = d
					end
					panel:Destroy()
				end
				local border = d:FindFirstChild("Border")
				if border then
					border:Destroy()
				end
				local label = d:FindFirstChildOfClass("TextLabel")
				if label then
					for _, s in label:GetChildren() do
						if s:IsA("UIStroke") then
							s:Destroy()
						end
					end
				end
				d:SetAttribute("Styled", nil)
			end
		elseif d:IsA("BasePart") then
			if d.Name == "PostCap" or d.Name == "PostBase" or (d.Name == "SignBack" and d.Parent.Name ~= "StopSign") then
				d:Destroy()
			else
				local pc = d:GetAttribute("PanelColor")
				if pc then
					d.Color = pc
					d.Material = Enum.Material.SmoothPlastic
				end
				for _, a in { "Framed", "BackPlated", "Capped", "PanelColor" } do
					d:SetAttribute(a, nil)
				end
			end
		end
	end
end

local function faceDims(part, face)
	local s = part.Size
	if face == Enum.NormalId.Front or face == Enum.NormalId.Back then
		return s.X, s.Y
	elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then
		return s.Z, s.Y
	end
end

local function roadStyle(g, part, bg)
	local label = g:FindFirstChildOfClass("TextLabel")
	local w, h = faceDims(part, g.Face)
	if not label or not w or w < 1 or h < 0.6 then
		return false
	end
	g.PixelsPerStud = PPS
	g.LightInfluence = 1
	label.BackgroundTransparency = 1
	label.FontFace = FONT
	label.TextScaled = true
	local m = math.min(w, h)
	local inset = math.clamp(m * 0.06, 0.08, 0.3) * PPS
	-- liseré : cadre arrondi couleur du texte + plaque intérieure couleur du fond
	local th = math.max(2, m * 0.035 * PPS)
	local border = Instance.new("Frame")
	border.Name = "Border"
	border.BorderSizePixel = 0
	border.BackgroundColor3 = label.TextColor3
	border.AnchorPoint = Vector2.new(0.5, 0.5)
	border.Position = UDim2.fromScale(0.5, 0.5)
	border.Size = UDim2.new(1, -inset * 2, 1, -inset * 2)
	local c1 = Instance.new("UICorner")
	c1.CornerRadius = UDim.new(0, m * 0.07 * PPS)
	c1.Parent = border
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.BorderSizePixel = 0
	inner.BackgroundColor3 = bg
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.new(1, -th * 2, 1, -th * 2)
	local c2 = Instance.new("UICorner")
	c2.CornerRadius = UDim.new(0, math.max(0, m * 0.07 * PPS - th))
	c2.Parent = inner
	inner.Parent = border
	border.Parent = g
	label.ZIndex = 3
	local pad = label:FindFirstChildOfClass("UIPadding")
	if pad then
		pad.PaddingLeft = UDim.new(0.07, 0)
		pad.PaddingRight = UDim.new(0.07, 0)
		pad.PaddingTop = UDim.new(0.14, 0)
		pad.PaddingBottom = UDim.new(0.14, 0)
	end
	return true
end

return function()
	local map = workspace.Map
	strip(map)
	local road, other, backs = 0, 0, 0
	local plates = {}
	for _, g in map:GetDescendants() do
		if g:IsA("SurfaceGui") and g.Name ~= "BackPlate" then
			local part = g.Parent
			local label = g:FindFirstChildOfClass("TextLabel")
			if part and part:IsA("BasePart") and label and part.Name ~= "Pad" and part.Name ~= "HouseNumber" then
				local model = part.Parent
				if model and model.Name == "StopSign" then
					label.FontFace = FONT
				elseif isRoadSign(part) then
					if roadStyle(g, part, part.Color) then
						road += 1
						plates[part] = plates[part] or {}
						plates[part][g.Face] = true
						part.Material = Enum.Material.SmoothPlastic
						part.Reflectance = 0.04
					end
				else
					-- enseigne : plaque simple, texte net
					label.TextScaled = true
					if label.Font == Enum.Font.FredokaOne then
						label.Font = Enum.Font.GothamBlack
					end
					g.PixelsPerStud = 24
					other += 1
				end
			end
			Lib.yield(1)
		end
	end

	-- dos en aluminium brut pour les panneaux simple face
	for part, faces in plates do
		local front = faces[Enum.NormalId.Front]
		local back = faces[Enum.NormalId.Back]
		if (front and not back) or (back and not front) then
			local off = (front and 1 or -1) * (part.Size.Z / 2 + 0.03)
			local b = Lib.deco(part.Parent, part.CFrame * CFrame.new(0, 0, off), V(part.Size.X, part.Size.Y, 0.05), ALU, Enum.Material.Metal, { Name = "SignBack" })
			backs += 1
		end
	end

	-- poteaux en acier galvanisé
	local poles = 0
	for _, m in map:GetDescendants() do
		if m:IsA("Model") and (m.Name == "PostSign" or m.Name == "Welcome" or m.Name == "SpeedLimit" or m.Name == "StopSign") then
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") and p.Size.Y > 3 and p.Size.X <= 0.7 and p.Size.Z <= 0.7 then
					p.Color = STEEL
					p.Material = Enum.Material.Metal
					poles += 1
				end
			end
		end
	end

	-- STOP : vrai octogone (2 bandes + 4 coins en biseau) rouge, bord blanc derrière
	local function octagon(m, base, W, thick, color, name)
		local sd = W / (1 + math.sqrt(2))
		local L = (W - sd) / 2
		local band = Lib.deco(m, base, V(W, sd, thick), color, Enum.Material.SmoothPlastic, { Name = name })
		Lib.deco(m, base * CFrame.new(0, 0, 0.012), V(sd, W, thick - 0.02), color, Enum.Material.SmoothPlastic, { Name = name })
		local c = (sd + W) / 4
		for k = 0, 3 do
			local corner = CFrame.Angles(0, 0, k * math.pi / 2) * CFrame.fromMatrix(V(c, c, 0), V(0, 0, 1), V(0, 1, 0))
			Lib.deco(m, base * corner, V(thick, L, L), color, Enum.Material.SmoothPlastic, { Name = name, Class = "WedgePart" })
		end
		return band
	end
	local stops = 0
	for _, m in map:GetDescendants() do
		if m:IsA("Model") and m.Name == "StopSign" and not m:GetAttribute("RealStop") then
			local gui, base
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") and p:FindFirstChildOfClass("SurfaceGui") then
					gui, base = p:FindFirstChildOfClass("SurfaceGui"), p.CFrame
				end
			end
			if gui then
				for _, p in m:GetChildren() do
					if p:IsA("BasePart") and (p.Size.Y < 3 and p.Size.Z < 0.3 or p.Name == "StopBorder" or p.Name == "SignBack") then
						if p ~= gui.Parent then
							p:Destroy()
						end
					end
				end
				local old = gui.Parent
				local band = octagon(m, base, 2.5, 0.1, Color3.fromRGB(196, 22, 28), "StopFace")
				octagon(m, base * CFrame.new(0, 0, 0.07), 2.8, 0.05, Color3.new(1, 1, 1), "StopBorder")
				octagon(m, base * CFrame.new(0, 0, 0.11), 2.8, 0.03, ALU, "SignBack")
				gui.Parent = band
				gui.PixelsPerStud = 60
				old:Destroy()
				m:SetAttribute("RealStop", true)
				stops += 1
			end
		end
	end
	return ("panneaux : %d panneaux routiers, %d enseignes, %d dos alu, %d poteaux, %d STOP"):format(road, other, backs, poles, stops)
end
