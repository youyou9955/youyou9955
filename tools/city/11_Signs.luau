--!nolint
-- 11 : panneaux plus stylés. Repasse sur tous les SurfaceGui de la map (faces avant/arrière) :
-- cadre sombre, plaque arrondie avec dégradé, liseré clair, reflet, texte arrondi avec contour.
-- Idempotent (attribut Styled). Les panneaux STOP gardent leur forme octogonale.
local Lib = require(script.Parent.Lib)
local V = Vector3.new
local PPS = 40
local FRAME = Color3.fromRGB(34, 36, 42)

local function shade(c, k)
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, math.clamp(s * (k > 1 and 0.85 or 1.05), 0, 1), math.clamp(v * k, 0, 1))
end

local function corner(parent, px)
	local u = Instance.new("UICorner")
	u.CornerRadius = UDim.new(0, px)
	u.Parent = parent
end

local function style(g, part, bg)
	local label = g:FindFirstChildOfClass("TextLabel")
	if not label then
		return false
	end
	local face = g.Face
	local sz = part.Size
	local w, h
	if face == Enum.NormalId.Front or face == Enum.NormalId.Back then
		w, h = sz.X, sz.Y
	elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then
		w, h = sz.Z, sz.Y
	else
		return false
	end
	if w < 1 or h < 0.6 then
		return false
	end
	g.PixelsPerStud = PPS
	local margin = math.clamp(math.min(w, h) * 0.06, 0.08, 0.35) * PPS
	local radius = math.min(w, h) * 0.16 * PPS

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -margin * 2, 1, -margin * 2)
	panel.BackgroundColor3 = bg
	panel.BorderSizePixel = 0
	corner(panel, radius)
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, shade(bg, 1.25)),
		ColorSequenceKeypoint.new(0.55, bg),
		ColorSequenceKeypoint.new(1, shade(bg, 0.7)),
	})
	grad.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.15
	stroke.Thickness = math.max(2, math.min(w, h) * 0.05 * PPS)
	stroke.Parent = panel
	-- reflet en haut
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.86
	shine.BorderSizePixel = 0
	shine.Position = UDim2.fromScale(0.02, 0.04)
	shine.Size = UDim2.fromScale(0.96, 0.38)
	corner(shine, radius * 0.8)
	shine.Parent = panel
	panel.Parent = g

	label.Parent = panel
	label.ZIndex = 2
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	local ts = Instance.new("UIStroke")
	ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	ts.Color = shade(bg, 0.35)
	ts.Thickness = math.max(1.5, h * 0.04 * PPS)
	ts.Transparency = 0.25
	ts.Parent = label
	return true
end

return function()
	local map = workspace.Map
	local n, frames = 0, 0
	for _, g in map:GetDescendants() do
		if g:IsA("SurfaceGui") and not g:GetAttribute("Styled") then
			local part = g.Parent
			local model = part and part.Parent
			local label = g:FindFirstChildOfClass("TextLabel")
			if part and part:IsA("BasePart") and label then
				if model and model.Name == "StopSign" then
					label.Font = Enum.Font.FredokaOne
					g:SetAttribute("Styled", true)
				elseif part.Name ~= "Pad" then
					local bg = label.BackgroundTransparency < 1 and label.BackgroundColor3 or part.Color
					if style(g, part, bg) then
						g:SetAttribute("Styled", true)
						if not part:GetAttribute("Framed") and part.Material ~= Enum.Material.Neon then
							part:SetAttribute("Framed", true)
							part:SetAttribute("PanelColor", bg)
							part.Color = FRAME
							part.Material = Enum.Material.Metal
							frames += 1
						end
						n += 1
					end
				end
			end
			Lib.yield(1)
		end
	end

	-- Poteaux de panneaux : métal sombre + capuchon
	local caps = 0
	for _, m in map:GetDescendants() do
		if m:IsA("Model") and (m.Name == "PostSign" or m.Name == "Welcome" or m.Name == "SpeedLimit") then
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") and p.Size.Y > 3 and p.Size.X <= 0.7 and p.Size.Z <= 0.7 and not p:GetAttribute("Capped") then
					p.Color = FRAME
					p.Material = Enum.Material.Metal
					p:SetAttribute("Capped", true)
					local cap = Lib.deco(m, p.CFrame * CFrame.new(0, p.Size.Y / 2 + 0.15, 0), V(p.Size.X + 0.25, 0.3, p.Size.Z + 0.25), Lib.C.brandOrange, Enum.Material.SmoothPlastic, { Name = "PostCap" })
					local base = Lib.deco(m, p.CFrame * CFrame.new(0, -p.Size.Y / 2 + 0.2, 0), V(p.Size.X + 0.5, 0.4, p.Size.Z + 0.5), FRAME, Enum.Material.Metal, { Name = "PostBase" })
					caps += 1
				end
			end
		end
	end
	return ("panneaux : %d plaques stylées (%d cadres), %d poteaux"):format(n, frames, caps)
end
