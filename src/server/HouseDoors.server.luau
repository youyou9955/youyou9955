--!strict
-- Portes d'entrée des maisons : chaque pièce taguée "HouseDoor" reçoit une invite (touche E)
-- qui l'ouvre vers l'intérieur en pivotant sur son bord gauche, puis la referme.
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local INFO = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function setup(door: Instance)
	if not door:IsA("BasePart") or door:GetAttribute("DoorReady") then
		return
	end
	door:SetAttribute("DoorReady", true)
	local closed = door.CFrame
	local hinge = closed * CFrame.new(-door.Size.X / 2, 0, 0)
	-- l'intérieur de la maison est du côté +Z local de la porte
	local opened = hinge * CFrame.Angles(0, math.rad(-92), 0) * CFrame.new(door.Size.X / 2, 0, 0)
	local isOpen = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ouvrir"
	prompt.ObjectText = "Porte"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.Parent = door

	-- maisons Meshy : un cache sombre masque la porte peinte du modèle quand la porte est ouverte
	local shadeRef = door:FindFirstChild("Shade")
	local shade = shadeRef and shadeRef:IsA("ObjectValue") and shadeRef.Value

	prompt.Triggered:Connect(function()
		isOpen = not isOpen
		prompt.ActionText = isOpen and "Fermer" or "Ouvrir"
		TweenService:Create(door, INFO, { CFrame = isOpen and opened or closed }):Play()
		if shade and shade:IsA("BasePart") then
			shade.Transparency = isOpen and 0 or 1
		end
	end)
end

for _, door in CollectionService:GetTagged("HouseDoor") do
	setup(door)
end
CollectionService:GetInstanceAddedSignal("HouseDoor"):Connect(setup)
