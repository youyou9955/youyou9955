-- Wrong Way Delivery : client du conducteur.
-- Quand le joueur s'assoit dans la camionnette, c'est lui qui fait tourner la physique.
-- Commandes : Z/S ou W/S = gaz/frein, Q/D ou A/D = direction,
-- Shift gauche (ou X manette) = frein à main / drift, R = remettre sur les roues.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local VanPhysics = require(Shared:WaitForChild("VanPhysics"))
local resetRemote = ReplicatedStorage:WaitForChild("VanRemotes"):WaitForChild("ResetVan")

local player = Players.LocalPlayer

---------------------------------------------------------------- HUD
local gui = Instance.new("ScreenGui")
gui.Name = "VanHud"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 1)
label.Position = UDim2.new(0.5, 0, 1, -24)
label.Size = UDim2.fromOffset(320, 44)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.GothamBold
label.TextSize = 20
label.Parent = gui
Instance.new("UICorner", label).CornerRadius = UDim.new(0, 10)

---------------------------------------------------------------- Conduite
local driving: { physics: any, seat: VehicleSeat, van: Model, conn: RBXScriptConnection }? = nil

local function stopDriving()
	if driving then
		driving.conn:Disconnect()
		driving = nil
	end
	gui.Enabled = false
end

local function handbrakeDown(): boolean
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonX)
end

local function startDriving(seat: VehicleSeat)
	stopDriving()
	local van = seat.Parent :: Model
	local physics = VanPhysics.new(van)
	gui.Enabled = true

	local conn = RunService.PreSimulation:Connect(function(dt)
		physics:Step(dt, seat.ThrottleFloat, seat.SteerFloat, handbrakeDown())
		local left = van:GetAttribute("BoxesLeft") or 0
		local total = van:GetAttribute("BoxesTotal") or 0
		label.Text = string.format("%d km/h   |   📦 %d / %d", math.floor(math.abs(physics.Speed) * 0.5), left, total)
	end)
	driving = { physics = physics, seat = seat, van = van, conn = conn }
end

local function onCharacter(character: Model)
	stopDriving()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Seated:Connect(function(active, seatPart)
		if active and seatPart and seatPart:IsA("VehicleSeat") and seatPart:GetAttribute("WrongWayVan") then
			startDriving(seatPart)
		else
			stopDriving()
		end
	end)
end

if player.Character then
	task.spawn(onCharacter, player.Character)
end
player.CharacterAdded:Connect(onCharacter)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not driving then
		return
	end
	if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonY then
		resetRemote:FireServer()
	end
end)
