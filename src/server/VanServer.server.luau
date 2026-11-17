-- Wrong Way Delivery : serveur.
-- Construit la camionnette (placeholder ou modèle 3D dans ReplicatedStorage.Assets),
-- charge les cartons, donne la physique au conducteur et compte les cartons perdus.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local VanPhysics = require(Shared:WaitForChild("VanPhysics"))

-- Devant le QG, sur l'avenue z = 0, voie de droite, tournée vers +X
local VAN_SPAWN = CFrame.new(100, 5, 12) * CFrame.Angles(0, -math.pi / 2, 0)

---------------------------------------------------------------- Remotes
local remotes = ReplicatedStorage:FindFirstChild("VanRemotes") or Instance.new("Folder")
remotes.Name = "VanRemotes"
remotes.Parent = ReplicatedStorage

local resetRemote = remotes:FindFirstChild("ResetVan") or Instance.new("RemoteEvent")
resetRemote.Name = "ResetVan"
resetRemote.Parent = remotes

---------------------------------------------------------------- Sol de test
if not Workspace:FindFirstChild("Baseplate") and not Workspace:FindFirstChild("Map") then
	local ground = Instance.new("Part")
	ground.Name = "Baseplate"
	ground.Size = Vector3.new(1024, 4, 1024)
	ground.Position = Vector3.new(0, -2, 0)
	ground.Anchored = true
	ground.Material = Enum.Material.Asphalt
	ground.Color = Color3.fromRGB(60, 60, 64)
	ground.Parent = Workspace
end

---------------------------------------------------------------- Helpers
local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

local function makePart(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

-- Colle un modèle 3D (Model ou BasePart) comme simple visuel sur `root`.
local function attachVisual(asset: Instance, root: BasePart, offset: CFrame, parent: Instance)
	local visual = asset:Clone()
	visual.Name = "Visual"
	if visual:IsA("Model") then
		visual:PivotTo(root.CFrame * offset)
	elseif visual:IsA("BasePart") then
		visual.CFrame = root.CFrame * offset
	end
	local parts = if visual:IsA("BasePart") then { visual } else {}
	for _, d in visual:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	for _, p in parts do
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		weld(root, p)
	end
	visual.Parent = parent
	return #parts > 0
end

---------------------------------------------------------------- Construction
local function buildVan(spawnCf: CFrame): Model
	local cfg = Config.Van
	local size = cfg.ChassisSize
	local van = Instance.new("Model")
	van.Name = "DeliveryVan"

	local white = Color3.fromRGB(240, 240, 240)
	local chassis = makePart({
		Name = "Chassis",
		Size = size,
		CFrame = spawnCf,
		Color = white,
		Material = Enum.Material.SmoothPlastic,
		CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.3, 0, 1, 1),
		RootPriority = 10,
	})
	chassis.Parent = van
	van.PrimaryPart = chassis

	-- Roues : points de départ des raycasts de suspension.
	local hx, hz = size.X / 2 - 0.5, size.Z / 2 - 1.5
	for name, offset in {
		WheelFL = Vector3.new(-hx, -size.Y / 2, -hz),
		WheelFR = Vector3.new(hx, -size.Y / 2, -hz),
		WheelRL = Vector3.new(-hx, -size.Y / 2, hz),
		WheelRR = Vector3.new(hx, -size.Y / 2, hz),
	} do
		local att = Instance.new("Attachment")
		att.Name = name
		att.Position = offset
		att.Parent = chassis

		local wheel = makePart({
			Name = name .. "Visual",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.9, cfg.WheelRadius * 2, cfg.WheelRadius * 2),
			CFrame = chassis.CFrame
				* CFrame.new(offset + Vector3.new(0, -cfg.SuspensionRest * (1 - cfg.SagRatio), 0)),
			Color = Color3.fromRGB(25, 25, 25),
			CanCollide = false,
			CanQuery = false,
			Massless = true,
		})
		wheel:SetAttribute("Placeholder", true)
		wheel.Parent = van
		weld(chassis, wheel)
	end

	-- Cabine à l'avant (-Z).
	local cabLength = 5
	local cab = makePart({
		Name = "Cab",
		Size = Vector3.new(size.X, 4.5, cabLength),
		CFrame = chassis.CFrame * CFrame.new(0, size.Y / 2 + 2.25, -size.Z / 2 + cabLength / 2),
		Color = white,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false, -- le conducteur est assis dedans
		Massless = true,
	})
	cab:SetAttribute("Placeholder", true)
	cab.Parent = van
	weld(chassis, cab)

	-- Plateau ouvert : deux ridelles latérales, pas de hayon (coffre ouvert).
	local bedLength = size.Z - cabLength
	local bedCenterZ = size.Z / 2 - bedLength / 2
	for _, side in { -1, 1 } do
		local wall = makePart({
			Name = "BedWall",
			Size = Vector3.new(0.2, 0.9, bedLength),
			CFrame = chassis.CFrame * CFrame.new(side * (size.X / 2 - 0.1), size.Y / 2 + 0.45, bedCenterZ),
			Color = white,
			Material = Enum.Material.SmoothPlastic,
			Massless = true,
		})
		wall.Parent = van
		weld(chassis, wall)
	end

	local bedCenter = Instance.new("Attachment")
	bedCenter.Name = "BedCenter"
	bedCenter.Position = Vector3.new(0, size.Y / 2, bedCenterZ)
	bedCenter.Parent = chassis

	-- Siège conducteur.
	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2, 1, 2)
	seat.CFrame = chassis.CFrame * CFrame.new(-1.5, size.Y / 2 + 0.5, -size.Z / 2 + 2.5)
	seat.MaxSpeed = 0
	seat.Torque = 0
	seat.HeadsUpDisplay = false
	seat.Transparency = 1
	seat.Massless = true
	seat:SetAttribute("WrongWayVan", true)
	seat.Parent = van
	weld(chassis, seat)

	local cargo = Instance.new("Folder")
	cargo.Name = "Cargo"
	cargo.Parent = van

	-- Modèle 3D (généré) si présent : les primitives restent pour la collision.
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local vanAsset = assets and assets:FindFirstChild("Van")
	if vanAsset and attachVisual(vanAsset, chassis, cfg.VisualOffset, van) then
		for _, d in van:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute("Placeholder") then
				d.Transparency = 1
			end
		end
		chassis.Transparency = 1
		for _, d in van:GetChildren() do
			if d.Name == "BedWall" then
				d.Transparency = 1
			end
		end
	end

	van:SetAttribute("BoxesTotal", 0)
	van:SetAttribute("BoxesLeft", 0)
	van.Parent = Workspace
	return van
end

local function fillCargo(van: Model)
	local cargoCfg = Config.Cargo
	local chassis = van:FindFirstChild("Chassis") :: BasePart
	local bedCenter = chassis:FindFirstChild("BedCenter") :: Attachment
	local cargo = van:FindFirstChild("Cargo") :: Folder
	cargo:ClearAllChildren()

	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local boxAsset = assets and assets:FindFirstChild("Box")

	local bs = cargoCfg.BoxSize
	local cols, rows = 3, 2
	for i = 0, cargoCfg.BoxCount - 1 do
		local layer = i // (cols * rows)
		local idx = i % (cols * rows)
		local cx = (idx % cols - (cols - 1) / 2) * (bs.X + 0.2)
		local cz = (idx // cols - (rows - 1) / 2) * (bs.Z + 0.4)
		local cy = bs.Y / 2 + 0.05 + layer * (bs.Y + 0.05)

		local box = makePart({
			Name = "Box",
			Size = bs,
			CFrame = bedCenter.WorldCFrame * CFrame.new(cx, cy, cz) * CFrame.Angles(0, math.rad(math.random(-8, 8)), 0),
			Color = Color3.fromRGB(196, 150, 96),
			Material = Enum.Material.Cardboard,
			CustomPhysicalProperties = PhysicalProperties.new(
				cargoCfg.Density,
				cargoCfg.Friction,
				cargoCfg.Elasticity,
				1,
				1
			),
		})
		box.Parent = cargo
		if boxAsset and attachVisual(boxAsset, box, CFrame.identity, box) then
			box.Transparency = 1
		end
	end

	van:SetAttribute("BoxesTotal", cargoCfg.BoxCount)
	van:SetAttribute("BoxesLeft", cargoCfg.BoxCount)
end

---------------------------------------------------------------- Propriété réseau
local function setOwner(van: Model, player: Player?)
	local chassis = van:FindFirstChild("Chassis") :: BasePart
	if not chassis.Anchored then
		chassis:SetNetworkOwner(player)
	end
	for _, box in (van :: any).Cargo:GetChildren() do
		if box:IsA("BasePart") and not box.Anchored then
			box:SetNetworkOwner(player)
		end
	end
end

local function driverOf(van: Model): Player?
	local seat = van:FindFirstChild("DriverSeat") :: VehicleSeat
	local occupant = seat.Occupant
	return occupant and Players:GetPlayerFromCharacter(occupant.Parent)
end

---------------------------------------------------------------- Mise en route
local van = buildVan(VAN_SPAWN)
fillCargo(van)
local serverPhysics = VanPhysics.new(van)
local seat = van:FindFirstChild("DriverSeat") :: VehicleSeat

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	setOwner(van, driverOf(van))
end)

-- Quand personne ne conduit, le serveur garde la suspension active.
RunService.PreSimulation:Connect(function(dt)
	if seat.Occupant == nil then
		serverPhysics:Step(dt, 0, 0, true)
	end
end)

-- Touche R côté client : remet la camionnette sur ses roues et recharge les cartons.
resetRemote.OnServerEvent:Connect(function(player)
	if driverOf(van) ~= player then
		return
	end
	local chassis = van:FindFirstChild("Chassis") :: BasePart
	local pos = chassis.Position + Vector3.new(0, 4, 0)
	local look = chassis.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.1 then
		look = Vector3.new(0, 0, -1)
	end
	van:PivotTo(CFrame.lookAt(pos, pos + look.Unit))
	chassis.AssemblyLinearVelocity = Vector3.zero
	chassis.AssemblyAngularVelocity = Vector3.zero
	fillCargo(van)
	setOwner(van, player)
end)

-- Détection des cartons tombés du plateau.
task.spawn(function()
	local cargoCfg = Config.Cargo
	local bed = Config.Van.BedSize
	local chassis = van:FindFirstChild("Chassis") :: BasePart
	local bedCenter = chassis:FindFirstChild("BedCenter") :: Attachment
	while van.Parent do
		task.wait(0.25)
		local bedCf = bedCenter.WorldCFrame
		local left = 0
		for _, box in (van :: any).Cargo:GetChildren() do
			if not box:IsA("BasePart") or box:GetAttribute("Lost") then
				continue
			end
			local p = bedCf:PointToObjectSpace(box.Position)
			local m = cargoCfg.LostMargin
			local out = math.abs(p.X) > bed.X / 2 + m
				or math.abs(p.Z) > bed.Z / 2 + m
				or p.Y < -2
				or p.Y > 15
			if out then
				box:SetAttribute("Lost", true)
				task.delay(cargoCfg.LostCleanupDelay, function()
					if box.Parent then
						box:Destroy()
					end
				end)
			else
				left += 1
			end
		end
		if van:GetAttribute("BoxesLeft") ~= left then
			van:SetAttribute("BoxesLeft", left)
		end
	end
end)
