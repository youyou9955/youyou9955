-- Wrong Way Delivery : physique arcade de la camionnette + cartons instables.
-- Utilisé par le client du conducteur (qui possède la physique) et par le
-- serveur quand personne ne conduit.

local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)

local WHEEL_NAMES = { "WheelFL", "WheelFR", "WheelRL", "WheelRR" }

local VanPhysics = {}
VanPhysics.__index = VanPhysics

local function moveTowards(current: number, target: number, maxDelta: number): number
	if math.abs(target - current) <= maxDelta then
		return target
	end
	return current + math.sign(target - current) * maxDelta
end

local function randomUnit(): Vector3
	local v = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
	return if v.Magnitude > 1e-3 then v.Unit else Vector3.yAxis
end

function VanPhysics.new(model: Model)
	local self = setmetatable({}, VanPhysics)
	self.Model = model
	self.Chassis = model:WaitForChild("Chassis") :: BasePart
	self.CargoFolder = model:WaitForChild("Cargo")

	self.Wheels = {}
	for _, name in WHEEL_NAMES do
		table.insert(self.Wheels, {
			Attachment = self.Chassis:WaitForChild(name) :: Attachment,
			LastCompression = 0,
		})
	end

	self.RayParams = RaycastParams.new()
	self.RayParams.FilterType = Enum.RaycastFilterType.Exclude
	self.RayParams.FilterDescendantsInstances = { model }

	self.LastVelocity = self.Chassis.AssemblyLinearVelocity
	self.Grounded = false
	self.Speed = 0
	return self
end

function VanPhysics:Step(dt: number, throttle: number, steer: number, handbrake: boolean)
	dt = math.clamp(dt, 1 / 240, 1 / 30)
	local cfg = Config.Van
	local chassis: BasePart = self.Chassis
	if chassis.Anchored or not chassis:IsDescendantOf(Workspace) then
		return
	end

	local mass = chassis.AssemblyMass
	local cf = chassis.CFrame
	local up = cf.UpVector

	---------------------------------------------------------------- Suspension
	local rest = cfg.SuspensionRest
	local k = (mass * Workspace.Gravity / 4) / (rest * cfg.SagRatio)
	local c = 2 * cfg.DampingRatio * math.sqrt(k * mass / 4)

	local grounded = 0
	local bump = 0
	for _, wheel in self.Wheels do
		local origin = wheel.Attachment.WorldPosition
		local hit = Workspace:Raycast(origin, -up * (rest + cfg.WheelRadius), self.RayParams)
		if hit then
			grounded += 1
			local compression = math.clamp(rest - (hit.Distance - cfg.WheelRadius), 0, rest)
			local compressionSpeed = (compression - wheel.LastCompression) / dt
			wheel.LastCompression = compression

			local pointVel = chassis:GetVelocityAtPosition(origin)
			local force = math.max(k * compression - c * pointVel:Dot(up), 0)
			chassis:ApplyImpulseAtPosition(up * force * dt, origin)
			bump = math.max(bump, math.abs(compressionSpeed))
		else
			wheel.LastCompression = 0
		end
	end
	self.Grounded = grounded > 0

	---------------------------------------------------------------- Conduite
	local vel = chassis.AssemblyLinearVelocity
	local fwd = cf.LookVector
	local right = cf.RightVector
	local fwdSpeed = vel:Dot(fwd)
	self.Speed = fwdSpeed

	if grounded > 0 then
		local traction = grounded / 4
		local latSpeed = vel:Dot(right)

		local target, accel
		if throttle > 0 then
			target = cfg.MaxSpeed * throttle
			accel = if fwdSpeed < -1 then cfg.BrakeDecel else cfg.Acceleration
		elseif throttle < 0 then
			target = cfg.ReverseSpeed * throttle
			accel = if fwdSpeed > 1 then cfg.BrakeDecel else cfg.Acceleration
		else
			target = 0
			accel = if handbrake then cfg.HandbrakeDecel else cfg.CoastDecel
		end

		local newFwd = moveTowards(fwdSpeed, target, accel * dt * traction)
		local grip = if handbrake then cfg.DriftGrip else cfg.Grip
		local newLat = latSpeed * math.max(0, 1 - grip * dt * traction)
		local dv = fwd * (newFwd - fwdSpeed) + right * (newLat - latSpeed)
		chassis:ApplyImpulse(dv * mass)

		-- Braquage arcade : on pilote directement la vitesse de lacet.
		local speedFactor = math.clamp(fwdSpeed / cfg.FullSteerSpeed, -1, 1)
		local yawTarget = -steer * cfg.TurnRate * speedFactor * (if handbrake then cfg.DriftTurnBoost else 1)
		local localAng = cf:VectorToObjectSpace(chassis.AssemblyAngularVelocity)
		local tiltKeep = 1 - math.min(1, cfg.TiltDamping * dt)
		local newYaw = localAng.Y + (yawTarget - localAng.Y) * math.min(1, cfg.SteerResponse * dt * traction)
		chassis.AssemblyAngularVelocity =
			cf:VectorToWorldSpace(Vector3.new(localAng.X * tiltKeep, newYaw, localAng.Z * tiltKeep))
	end

	-- Aide anti-tonneau (marche aussi en l'air).
	local uprightAxis = up:Cross(Vector3.yAxis)
	chassis:ApplyAngularImpulse(uprightAxis * cfg.UprightStrength * mass * dt)

	---------------------------------------------------------------- Cartons
	self:_shakeCargo(dt, vel, bump, grounded > 0)
end

function VanPhysics:_shakeCargo(dt: number, vel: Vector3, bump: number, grounded: boolean)
	local cargo = Config.Cargo
	local accel = (vel - self.LastVelocity) / dt
	self.LastVelocity = vel

	local horizontal = Vector3.new(accel.X, 0, accel.Z)
	if horizontal.Magnitude > cargo.MaxAccel then
		horizontal = horizontal.Unit * cargo.MaxAccel
	end

	local kick = grounded and bump > cargo.BumpThreshold
	for _, box in self.CargoFolder:GetChildren() do
		if not box:IsA("BasePart") or box.Anchored or box:GetAttribute("Lost") then
			continue
		end
		local boxMass = box.AssemblyMass
		-- Les cartons "restent en arrière" quand la camionnette accélère, tourne ou freine.
		local impulse = -horizontal * boxMass * dt * cargo.InertiaBoost
		if kick then
			local strength = math.min(bump, 40) * cargo.BumpKick * (0.5 + math.random())
			impulse += Vector3.yAxis * boxMass * strength
			box:ApplyAngularImpulse(randomUnit() * boxMass * cargo.SpinKick * strength)
		end
		box:ApplyImpulse(impulse)
	end
end

return VanPhysics
