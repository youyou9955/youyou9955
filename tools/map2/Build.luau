--!nolint
-- Bâtiments procéduraux style cartoon : tours, immeubles à commerces, maisons, entrepôts.
-- Repère d'un bâtiment : cf au sol au centre de l'emprise, façade principale vers LookVector (-Z local).
local Lib = require(script.Parent.Lib)
local V, rgb, M, C = Lib.V, Lib.rgb, Lib.M, Lib.C
local Build = {}

local function darker(c, k)
	return c:Lerp(Color3.new(0, 0, 0), k or 0.2)
end
local function lighter(c, k)
	return c:Lerp(Color3.new(1, 1, 1), k or 0.25)
end
Build.darker, Build.lighter = darker, lighter

-- cf d'une face : 1 = avant (-Z), 2 = droite (+X), 3 = arrière (+Z), 4 = gauche (-X)
-- Renvoie cf au centre bas de la face (LookVector vers l'extérieur) et sa largeur
function Build.face(cf, w, d, i)
	if i == 1 then
		return cf * CFrame.new(0, 0, -d / 2), w
	elseif i == 2 then
		return cf * CFrame.new(w / 2, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), d
	elseif i == 3 then
		return cf * CFrame.new(0, 0, d / 2) * CFrame.Angles(0, math.pi, 0), w
	else
		return cf * CFrame.new(-w / 2, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), d
	end
end

-- Fenêtre (cadre + vitre + traverse), fcf = centre de la fenêtre sur le mur, LookVector vers l'extérieur
function Build.window(m, fcf, ww, wh, frame, glass, opts)
	opts = opts or {}
	Lib.fine(m, fcf * CFrame.new(0, 0, -0.12), V(ww + 0.6, wh + 0.6, 0.25), frame, M.SmoothPlastic)
	Lib.fine(m, fcf * CFrame.new(0, 0, -0.27), V(ww, wh, 0.1), glass, M.Glass, { Transparency = 0.15, Reflectance = 0.15 })
	if opts.cross then
		Lib.fine(m, fcf * CFrame.new(0, 0, -0.33), V(0.25, wh, 0.08), frame, M.SmoothPlastic)
		Lib.fine(m, fcf * CFrame.new(0, 0, -0.33), V(ww, 0.25, 0.08), frame, M.SmoothPlastic)
	end
	if opts.sill then
		Lib.fine(m, fcf * CFrame.new(0, -wh / 2 - 0.35, -0.35), V(ww + 1, 0.3, 0.7), frame, M.SmoothPlastic)
	end
	if opts.shutters then
		for _, s in { -1, 1 } do
			Lib.fine(m, fcf * CFrame.new(s * (ww / 2 + 0.95), 0, -0.2), V(1.1, wh + 0.4, 0.2), opts.shutters, M.SmoothPlastic)
		end
	end
	if opts.box then
		Lib.fine(m, fcf * CFrame.new(0, -wh / 2 - 0.8, -0.7), V(ww + 0.6, 0.8, 0.9), rgb(150, 100, 60), M.Wood)
		for k = -1, 1 do
			Lib.ball(m, (fcf * CFrame.new(k * ww / 3, -wh / 2 - 0.2, -0.7)).Position, 0.8, Lib.pick({ rgb(255, 90, 130), rgb(255, 210, 60), rgb(240, 120, 240) }), M.SmoothPlastic, { CastShadow = false })
		end
	end
end

---------------------------------------------------------------- Tours et immeubles
-- style : body, glass, trim, kind ("grid" | "glass" | "brick" | "bands"), crown ("flat" | "spire" | "stepped" | "pyramid" | "helipad")
-- shops : liste de { name, color } pour le rez-de-chaussée (sur la face avant et la face droite si corner)
function Build.tower(parent, cf, w, d, floors, style, shops, name)
	local m = Lib.model(parent, name or "Tower")
	local fh = 7
	local gh = 12
	local body = style.body
	local trim = style.trim or C.trim
	local glass = style.glass or C.glass
	local kind = style.kind or "grid"
	-- socle et rez-de-chaussée commercial
	Lib.part(m, cf * CFrame.new(0, 0.4, 0), V(w + 1.2, 0.8, d + 1.2), darker(trim, 0.3), M.Concrete, { Name = "Plinth" })
	Lib.part(m, cf * CFrame.new(0, gh / 2 + 0.4, 0), V(w - 1, gh, d - 1), darker(body, 0.25), M.SmoothPlastic, { Name = "GroundFloor" })
	for i = 1, 4 do
		local fcf, fw = Build.face(cf, w - 1, d - 1, i)
		local isShop = shops and (i == 1 or (shops.corner and i == 2))
		if isShop then
			local n = math.max(1, math.floor(fw / 16))
			local seg = fw / n
			for k = 1, n do
				local x = -fw / 2 + seg * (k - 0.5)
				local sh = shops[((k - 1 + (i == 2 and 2 or 0)) % #shops) + 1]
				-- vitrine
				Lib.fine(m, fcf * CFrame.new(x, 4.6, -0.15), V(seg - 2.4, 7.6, 0.2), rgb(40, 44, 52), M.SmoothPlastic)
				Lib.fine(m, fcf * CFrame.new(x, 4.6, -0.3), V(seg - 3.2, 6.8, 0.1), rgb(160, 210, 235), M.Glass, { Transparency = 0.25, Reflectance = 0.2 })
				Lib.fine(m, fcf * CFrame.new(x + seg / 2 - 4.4, 3.8, -0.36), V(2.6, 6.4, 0.1), rgb(40, 44, 52), M.SmoothPlastic)
				-- auvent incliné
				Lib.wedge(m, fcf * CFrame.new(x, 9.2, -1.6), V(seg - 2, 1.4, 3.2), sh[2], M.Fabric, { CanCollide = false, CanQuery = false, CanTouch = false })
				Lib.fine(m, fcf * CFrame.new(x, 8.35, -3.15), V(seg - 2, 0.35, 0.15), C.white, M.Fabric)
				-- enseigne
				local sg = Lib.fine(m, fcf * CFrame.new(x, 11, -0.35), V(seg - 3, 1.9, 0.3), sh[2], M.SmoothPlastic)
				Lib.label(sg, Enum.NormalId.Front, sh[1], C.white, nil, Enum.Font.FredokaOne, true)
			end
		else
			local n = math.max(1, math.floor(fw / 9))
			for k = 1, n do
				local x = -fw / 2 + fw / n * (k - 0.5)
				Build.window(m, fcf * CFrame.new(x, 6.4, 0), 4.2, 5.4, trim, glass)
			end
		end
	end
	-- corps
	local y0 = gh + 0.4
	local setback = style.setback and floors >= 10
	local f1 = setback and math.floor(floors * 0.62) or floors
	local function section(sw, sd, ya, nf, col)
		local h = nf * fh
		local mat = kind == "brick" and M.Brick or (kind == "glass" and M.Glass or M.SmoothPlastic)
		local bcol = kind == "glass" and glass or col
		Lib.part(m, cf * CFrame.new(0, ya + h / 2, 0), V(sw, h, sd), bcol, mat, { Name = "Body", Reflectance = kind == "glass" and 0.12 or 0 })
		for i = 1, 4 do
			local fcf, fw = Build.face(cf, sw, sd, i)
			if kind == "glass" then
				-- mur-rideau : lignes d'étage et meneaux
				for f = 1, nf do
					Lib.fine(m, fcf * CFrame.new(0, ya + f * fh - 0.3, -0.12), V(fw + 0.2, 0.6, 0.3), trim, M.SmoothPlastic)
				end
				local nm = math.max(2, math.floor(fw / 6))
				for k = 1, nm - 1 do
					Lib.fine(m, fcf * CFrame.new(-fw / 2 + fw / nm * k, ya + h / 2, -0.1), V(0.35, h, 0.25), trim, M.SmoothPlastic)
				end
			else
				-- bandes vitrées par étage + pilastres
				for f = 1, nf do
					Lib.fine(m, fcf * CFrame.new(0, ya + (f - 1) * fh + 3.9, -0.08), V(fw - 1.6, 3.8, 0.2), glass, M.Glass, { Reflectance = 0.15 })
					if kind == "bands" then
						Lib.fine(m, fcf * CFrame.new(0, ya + (f - 1) * fh + 1.2, -0.18), V(fw + 0.2, 0.6, 0.4), trim, M.SmoothPlastic)
					end
				end
				local np = math.max(2, math.floor(fw / 7.5))
				for k = 0, np do
					local x = -fw / 2 + fw / np * k
					Lib.fine(m, fcf * CFrame.new(x, ya + h / 2, -0.25), V(k == 0 or k == np and 1.6 or 0.9, h, 0.5), kind == "brick" and trim or darker(col, 0.12), M.SmoothPlastic)
				end
			end
		end
		-- corniche
		Lib.part(m, cf * CFrame.new(0, ya + h + 0.5, 0), V(sw + 1.4, 1, sd + 1.4), trim, M.SmoothPlastic, { Name = "Cornice" })
		return ya + h + 1
	end
	local top = section(w, d, y0, f1, body)
	local tw, td = w, d
	if setback then
		tw, td = w * 0.7, d * 0.7
		top = section(tw, td, top, floors - f1, lighter(body, 0.08))
	end
	-- toit
	local crown = style.crown or "flat"
	-- parapet
	for i = 1, 4 do
		local fcf, fw = Build.face(cf, tw + 1.4, td + 1.4, i)
		Lib.fine(m, fcf * CFrame.new(0, top + 1, 0.3), V(fw, 2, 0.6), trim, M.SmoothPlastic)
	end
	if crown == "spire" then
		Lib.part(m, cf * CFrame.new(0, top + 5, 0), V(tw * 0.5, 10, td * 0.5), trim, M.SmoothPlastic)
		Lib.part(m, cf * CFrame.new(0, top + 13, 0), V(tw * 0.28, 6, td * 0.28), glass, M.Glass)
		Lib.cylDeco(m, cf * CFrame.new(0, top + 30, 0), 28, 1.2, C.metal, M.Metal)
		Lib.ball(m, (cf * CFrame.new(0, top + 44.5, 0)).Position, 1.6, rgb(255, 60, 60), M.Neon)
	elseif crown == "stepped" then
		Lib.part(m, cf * CFrame.new(0, top + 3, 0), V(tw * 0.75, 6, td * 0.75), lighter(body, 0.1), M.SmoothPlastic)
		Lib.part(m, cf * CFrame.new(0, top + 8, 0), V(tw * 0.5, 4, td * 0.5), trim, M.SmoothPlastic)
		Lib.cylDeco(m, cf * CFrame.new(0, top + 16, 0), 12, 0.6, C.metal, M.Metal)
	elseif crown == "pyramid" then
		local r = Lib.part(m, cf * CFrame.new(0, top + 4, 0) * CFrame.Angles(0, math.rad(45), 0), V(tw * 0.62, 8, td * 0.62), style.roof or rgb(60, 140, 120), M.SmoothPlastic)
		Lib.part(m, cf * CFrame.new(0, top + 10, 0), V(tw * 0.4, 4, td * 0.4), style.roof or rgb(60, 140, 120), M.SmoothPlastic)
	elseif crown == "helipad" then
		Lib.cyl(m, cf * CFrame.new(0, top + 0.6, 0), 0.6, math.min(tw, td) * 0.8, rgb(60, 64, 72), M.SmoothPlastic)
		local hp = Lib.fine(m, cf * CFrame.new(0, top + 0.95, 0), V(math.min(tw, td) * 0.45, 0.05, math.min(tw, td) * 0.45), rgb(60, 64, 72), M.SmoothPlastic)
		Lib.label(hp, Enum.NormalId.Top, "H", C.yellow, nil, Enum.Font.GothamBlack)
	else
		-- équipements techniques
		for k = 1, 3 do
			local x = Lib.rng:NextNumber(-tw / 3, tw / 3)
			local z = Lib.rng:NextNumber(-td / 3, td / 3)
			Lib.part(m, cf * CFrame.new(x, top + 1.5, z), V(4, 3, 4), rgb(190, 194, 200), M.Metal)
		end
		if kind == "brick" then
			Lib.cyl(m, cf * CFrame.new(tw / 4, top + 6, -td / 4), 6, 6, rgb(150, 110, 80), M.Wood)
			for _, s in { -1, 1 } do
				Lib.part(m, cf * CFrame.new(tw / 4 + s * 2, top + 1.5, -td / 4), V(0.5, 3, 0.5), C.dark, M.Metal)
			end
		end
	end
	m:SetAttribute("Height", top)
	return m
end

---------------------------------------------------------------- Petit immeuble à commerces (2 à 4 étages)
function Build.shopBlock(parent, cf, w, d, floors, wall, trim, shop, name)
	local m = Lib.model(parent, name or "ShopBuilding")
	local gh, fh = 11, 8
	local h = gh + floors * fh
	Lib.part(m, cf * CFrame.new(0, h / 2, 0), V(w, h, d), wall, M.SmoothPlastic, { Name = "Body" })
	-- rez-de-chaussée vitré
	local fcf = Build.face(cf, w, d, 1)
	Lib.fine(m, fcf * CFrame.new(0, gh / 2, -0.1), V(w - 1, gh - 1, 0.2), rgb(40, 44, 52), M.SmoothPlastic)
	Lib.fine(m, fcf * CFrame.new(-2, gh / 2 - 0.5, -0.25), V(w - 7, gh - 3, 0.1), rgb(170, 215, 238), M.Glass, { Transparency = 0.2, Reflectance = 0.2 })
	Lib.fine(m, fcf * CFrame.new(w / 2 - 3, 4, -0.3), V(3, 7.6, 0.1), darker(shop[2], 0.2), M.SmoothPlastic)
	Lib.wedge(m, fcf * CFrame.new(0, gh - 1, -1.8), V(w - 1, 1.6, 3.6), shop[2], M.Fabric, { CanCollide = false, CanQuery = false, CanTouch = false })
	local sg = Lib.fine(m, fcf * CFrame.new(0, gh + 1.4, -0.4), V(w * 0.8, 2.6, 0.4), shop[3] or C.white, M.SmoothPlastic)
	Lib.label(sg, Enum.NormalId.Front, shop[1], shop[2], nil, Enum.Font.FredokaOne, true)
	-- étages
	for i = 1, 4 do
		local f, fw = Build.face(cf, w, d, i)
		local n = math.max(1, math.floor(fw / 8))
		for fl = 1, floors do
			for k = 1, n do
				if not (i == 1 and fl == 0) then
					Build.window(m, f * CFrame.new(-fw / 2 + fw / n * (k - 0.5), gh + (fl - 1) * fh + 4.6, 0), 3.6, 4.6, trim, C.glass, { sill = i == 1, shutters = (i == 1 and Lib.rng:NextNumber() < 0.4) and darker(wall, 0.35) or nil })
				end
			end
		end
	end
	Lib.part(m, cf * CFrame.new(0, h + 0.5, 0), V(w + 1, 1, d + 1), trim, M.SmoothPlastic, { Name = "Cornice" })
	for i = 1, 4 do
		local f, fw = Build.face(cf, w + 1, d + 1, i)
		Lib.fine(m, f * CFrame.new(0, h + 1.6, 0.3), V(fw, 1.4, 0.6), trim, M.SmoothPlastic)
	end
	return m
end

---------------------------------------------------------------- Maisons
Build.WALLS = { rgb(250, 238, 214), rgb(178, 214, 236), rgb(196, 230, 196), rgb(255, 214, 186), rgb(250, 250, 244), rgb(255, 232, 150), rgb(214, 196, 236), rgb(236, 180, 170), rgb(204, 176, 140) }
Build.ROOFS = { rgb(178, 66, 54), rgb(70, 76, 92), rgb(70, 110, 160), rgb(196, 100, 60), rgb(72, 130, 86), rgb(120, 70, 60) }
Build.DOORS = { rgb(200, 40, 40), rgb(30, 60, 120), rgb(20, 130, 130), rgb(240, 180, 30), rgb(30, 100, 60), rgb(120, 70, 40) }

-- Toit à deux pans (faîtage selon X local), base à la hauteur y, emprise w x d, débord ov
local function gable(m, cf, w, d, y, rise, roofC, wallC, ov)
	ov = ov or 1.2
	local half = d / 2
	local a = math.atan2(rise, half)
	local slen = math.sqrt(half * half + rise * rise) + ov
	for _, s in { -1, 1 } do
		Lib.part(m, cf * CFrame.new(0, y + rise / 2, s * half / 2) * CFrame.Angles(s * a, 0, 0) * CFrame.new(0, 0.45, s * ov / 2 - 0 * s), V(w + ov * 2, 0.9, slen), roofC, M.SmoothPlastic, { Name = "Roof" })
	end
	Lib.part(m, cf * CFrame.new(0, y + rise + 0.55, 0), V(w + ov * 2 + 0.2, 0.7, 1.2), darker(roofC, 0.2), M.SmoothPlastic, { Name = "Ridge" })
	-- pignons
	for _, sx in { -1, 1 } do
		Lib.wedge(m, cf * CFrame.new(sx * (w / 2 - 0.3), y + rise / 2, -half / 2), V(0.6, rise, half), wallC, M.SmoothPlastic)
		Lib.wedge(m, cf * CFrame.new(sx * (w / 2 - 0.3), y + rise / 2, half / 2) * CFrame.Angles(0, math.pi, 0), V(0.6, rise, half), wallC, M.SmoothPlastic)
	end
end
Build.gable = gable

-- opts : w, d, floors, wall, roof, trim, door, garage ("left"|"right"|nil), porch, chimney, wing, ridgeZ, shutters
function Build.house(parent, cf, o)
	local m = Lib.model(parent, "House")
	local w, d = o.w or 20, o.d or 16
	local fh = 9
	local floors = o.floors or 1
	local wall, roof = o.wall, o.roof
	local trim = o.trim or C.trim
	local hw = floors * fh + 1
	-- fondation et murs
	Lib.part(m, cf * CFrame.new(0, 0.5, 0), V(w + 0.8, 1, d + 0.8), rgb(170, 166, 158), M.Concrete, { Name = "Foundation" })
	Lib.part(m, cf * CFrame.new(0, 1 + (hw - 1) / 2, 0), V(w, hw - 1, d), wall, M.SmoothPlastic, { Name = "Walls" })
	-- angles et bandeau
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Lib.fine(m, cf * CFrame.new(sx * (w / 2 + 0.05), hw / 2 + 0.5, sz * (d / 2 + 0.05)), V(0.8, hw - 1, 0.8), trim, M.SmoothPlastic)
		end
	end
	if floors == 2 then
		for i = 1, 4 do
			local f, fw = Build.face(cf, w, d, i)
			Lib.fine(m, f * CFrame.new(0, fh + 1, -0.15), V(fw + 0.4, 0.5, 0.3), trim, M.SmoothPlastic)
		end
	end
	-- toit
	local rise = o.ridgeZ and w * 0.38 or d * 0.36
	if o.ridgeZ then
		gable(m, cf * CFrame.Angles(0, math.pi / 2, 0), d, w, hw, rise, roof, wall)
	else
		gable(m, cf, w, d, hw, rise, roof, wall)
	end
	-- porte d'entrée
	local front = Build.face(cf, w, d, 1)
	local dx = o.doorX or 0
	Lib.fine(m, front * CFrame.new(dx, 4.2, -0.12), V(4.4, 7.6, 0.25), trim, M.SmoothPlastic)
	Lib.part(m, front * CFrame.new(dx, 4.1, -0.25), V(3.4, 6.8, 0.2), o.door, M.Wood, { Name = "Door" })
	Lib.fine(m, front * CFrame.new(dx + 1.1, 4, -0.42), V(0.3, 0.3, 0.2), rgb(230, 190, 60), M.Metal)
	Lib.fine(m, front * CFrame.new(dx, 6.4, -0.38), V(2.2, 1.2, 0.08), rgb(170, 215, 238), M.Glass)
	-- marche ou porche
	if o.porch then
		Lib.part(m, front * CFrame.new(dx, 0.6, -3), V(9, 1.2, 6), rgb(200, 196, 188), M.Concrete, { Name = "Porch" })
		for _, s in { -1, 1 } do
			Lib.part(m, front * CFrame.new(dx + s * 4, 4.6, -5.4), V(0.7, 7, 0.7), trim, M.SmoothPlastic)
		end
		Lib.wedge(m, front * CFrame.new(dx, 8.8, -3.2), V(10, 1.4, 6.4), roof, M.SmoothPlastic)
	else
		Lib.part(m, front * CFrame.new(dx, 0.5, -1.6), V(5.5, 1, 3), rgb(200, 196, 188), M.Concrete, { Name = "Step" })
		Lib.fine(m, front * CFrame.new(dx, 8.6, -1.2), V(6, 0.4, 2.4), roof, M.SmoothPlastic)
	end
	-- fenêtres
	local cross = o.cross ~= false
	for i = 1, 4 do
		local f, fw = Build.face(cf, w, d, i)
		local n = math.max(1, math.floor((fw - 2) / 7))
		for fl = 1, floors do
			for k = 1, n do
				local x = -fw / 2 + fw / n * (k - 0.5)
				local skip = i == 1 and fl == 1 and math.abs(x - dx) < 4.5
				if not skip then
					Build.window(m, f * CFrame.new(x, (fl - 1) * fh + 5.2, 0), 3.4, 4, trim, rgb(150, 205, 240), { cross = cross, sill = true, shutters = (i == 1 and o.shutters) or nil, box = (i == 1 and fl == 1 and o.flowerBoxes) })
				end
			end
		end
	end
	-- cheminée
	if o.chimney then
		local x = w / 2 - 3
		Lib.part(m, cf * CFrame.new(x, hw + rise * 0.7, d / 6), V(2.4, rise * 1.1 + 2, 2.4), rgb(170, 90, 70), M.Brick, { Name = "Chimney" })
		Lib.fine(m, cf * CFrame.new(x, hw + rise * 1.25 + 1.2, d / 6), V(3, 0.5, 3), rgb(120, 70, 56), M.SmoothPlastic)
	end
	-- garage accolé
	if o.garage then
		local s = o.garage == "left" and -1 or 1
		local gw, gd, gh = 12, d - 2, 9
		local gcf = cf * CFrame.new(s * (w / 2 + gw / 2), 0, -1)
		Lib.part(m, gcf * CFrame.new(0, gh / 2 + 0.5, 0), V(gw, gh, gd), lighter(wall, 0.15), M.SmoothPlastic, { Name = "Garage" })
		local gf = Build.face(gcf, gw, gd, 1)
		Lib.fine(m, gf * CFrame.new(0, 3.9, -0.12), V(10, 7.2, 0.25), trim, M.SmoothPlastic)
		Lib.part(m, gf * CFrame.new(0, 3.8, -0.25), V(9, 6.8, 0.2), rgb(236, 236, 230), M.SmoothPlastic, { Name = "GarageDoor" })
		for k = 1, 4 do
			Lib.fine(m, gf * CFrame.new(0, 0.9 + k * 1.4, -0.38), V(9, 0.12, 0.08), rgb(200, 200, 196), M.SmoothPlastic)
		end
		Lib.wedge(m, gcf * CFrame.new(0, gh + 1.6, 0) * CFrame.Angles(0, s > 0 and -math.pi / 2 or math.pi / 2, 0), V(gd + 1, 2.2, gw + 1), roof, M.SmoothPlastic)
	end
	-- aile avant à pignon (maisons à deux étages)
	if o.wing then
		local ww, wd = math.min(10, w * 0.45), 6
		local wcf = cf * CFrame.new(-w / 4, 0, -d / 2 - wd / 2 + 0.2)
		Lib.part(m, wcf * CFrame.new(0, hw / 2 + 0.5, 0), V(ww, hw - 1, wd), wall, M.SmoothPlastic, { Name = "Wing" })
		gable(m, wcf * CFrame.Angles(0, math.pi / 2, 0), wd + 0.4, ww, hw, ww * 0.42, roof, wall, 0.8)
		local wf = Build.face(wcf, ww, wd, 1)
		for fl = 1, floors do
			Build.window(m, wf * CFrame.new(0, (fl - 1) * fh + 5.2, 0), 4.2, 4.4, trim, rgb(150, 205, 240), { cross = true, sill = true, box = fl == 1 })
		end
	end
	return m
end

---------------------------------------------------------------- Entrepôt / hangar
function Build.warehouse(parent, cf, w, d, h, wall, roofC, accent, name, docks)
	local m = Lib.model(parent, name or "Warehouse")
	Lib.part(m, cf * CFrame.new(0, h / 2, 0), V(w, h, d), wall, M.CorrodedMetal, { Name = "Body" })
	-- nervures verticales du bardage
	for i = 1, 4 do
		local f, fw = Build.face(cf, w, d, i)
		local n = math.floor(fw / 6)
		for k = 1, n - 1 do
			Lib.fine(m, f * CFrame.new(-fw / 2 + fw / n * k, h / 2, -0.12), V(0.4, h, 0.25), darker(wall, 0.15), M.Metal)
		end
		Lib.fine(m, f * CFrame.new(0, h - 1.2, -0.2), V(fw + 0.4, 2.4, 0.4), accent, M.SmoothPlastic)
		Lib.fine(m, f * CFrame.new(0, 0.8, -0.2), V(fw + 0.4, 1.6, 0.4), darker(wall, 0.35), M.Concrete)
	end
	-- toit légèrement bombé (deux pans très plats)
	gable(m, cf, w, d, h, d * 0.08, roofC, wall, 0.8)
	-- lanterneaux
	for k = -1, 1 do
		Lib.fine(m, cf * CFrame.new(k * w / 4, h + d * 0.04 + 0.6, 0), V(4, 0.6, d * 0.6), rgb(170, 215, 238), M.Glass)
	end
	-- quais de chargement
	local f, fw = Build.face(cf, w, d, 1)
	local nd = docks or math.max(2, math.floor(fw / 16))
	for k = 1, nd do
		local x = -fw / 2 + fw / nd * (k - 0.5)
		Lib.fine(m, f * CFrame.new(x, 6.5, -0.15), V(11, 11, 0.3), darker(accent, 0.1), M.SmoothPlastic)
		Lib.part(m, f * CFrame.new(x, 6.5, -0.3), V(10, 10, 0.2), rgb(210, 214, 220), M.Metal, { Name = "RollUpDoor" })
		for j = 1, 6 do
			Lib.fine(m, f * CFrame.new(x, 1.5 + j * 1.5, -0.42), V(10, 0.15, 0.08), rgb(170, 174, 180), M.Metal)
		end
		Lib.part(m, f * CFrame.new(x, 1.5, -2.5), V(12, 3, 5), rgb(150, 150, 146), M.Concrete, { Name = "Dock" })
		Lib.fine(m, f * CFrame.new(x - 6.4, 3, -4.9), V(0.7, 2, 0.7), C.yellow, M.SmoothPlastic)
		Lib.fine(m, f * CFrame.new(x + 6.4, 3, -4.9), V(0.7, 2, 0.7), C.yellow, M.SmoothPlastic)
		Lib.fine(m, f * CFrame.new(x, 12.5, -1.4), V(12, 0.5, 2.8), accent, M.SmoothPlastic)
	end
	-- porte de service
	Lib.fine(m, f * CFrame.new(fw / 2 - 4, 3.8, -0.25), V(3.4, 7, 0.2), C.dark, M.SmoothPlastic)
	return m
end

return Build
