-- Wrong Way Delivery : réglages de la camionnette et des cartons.
-- Toutes les vitesses sont en studs/seconde.

local Config = {}

Config.Van = {
	-- Moteur
	MaxSpeed = 95,
	ReverseSpeed = 35,
	Acceleration = 55,
	BrakeDecel = 140,
	CoastDecel = 18,
	HandbrakeDecel = 45,

	-- Direction
	TurnRate = 2.6, -- rad/s au braquage maximum
	FullSteerSpeed = 18, -- vitesse à partir de laquelle on braque à fond
	SteerResponse = 8,
	DriftTurnBoost = 1.35,

	-- Adhérence (plus c'est haut, moins ça glisse)
	Grip = 7,
	DriftGrip = 1.2,

	-- Suspension (raycast, auto-réglée selon la masse)
	SuspensionRest = 2,
	WheelRadius = 1.2,
	SagRatio = 0.45, -- part de la suspension écrasée au repos
	DampingRatio = 0.45,

	-- Stabilité
	TiltDamping = 1.5,
	UprightStrength = 35,

	-- Dimensions du châssis (placeholder)
	ChassisSize = Vector3.new(7, 1, 14),
	BedSize = Vector3.new(6.6, 0, 8), -- surface utile du plateau arrière

	-- Décalage du modèle 3D visuel (Assets.Van) par rapport au châssis
	VisualOffset = CFrame.new(0, 1.2, 0),
}

Config.Cargo = {
	BoxCount = 8,
	BoxSize = Vector3.new(2, 1.5, 1.35),
	Density = 0.25,
	Friction = 0.55,
	Elasticity = 0.15,

	-- Instabilité arcade
	InertiaBoost = 0.2, -- exagère l'inertie quand la camionnette accélère / tourne
	MaxAccel = 400, -- coupe les pics lors des chocs
	BumpThreshold = 6, -- vitesse de compression qui déclenche un saut des cartons
	BumpKick = 0.06,
	SpinKick = 0.4,

	-- Perte
	LostMargin = 1.5, -- distance hors du plateau avant d'être compté perdu
	LostCleanupDelay = 6,
}

return Config
