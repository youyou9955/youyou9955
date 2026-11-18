--!nolint
-- 18 : ambiance lumineuse : lumière naturelle chaude, ambiance intérieure neutre (plus de teinte bleue dans
-- les maisons), saturation et brume modérées pour garder la visibilité.
return function()
	local L = game:GetService("Lighting")
	L.Ambient = Color3.fromRGB(122, 116, 108)
	L.OutdoorAmbient = Color3.fromRGB(138, 138, 142)
	L.Brightness = 2.6
	L.EnvironmentDiffuseScale = 0.35
	L.EnvironmentSpecularScale = 0.35
	L.ShadowSoftness = 0.25
	L.ClockTime = 14.2
	L.GlobalShadows = true
	local atm = L:FindFirstChildOfClass("Atmosphere")
	if atm then
		atm.Density = 0.24
		atm.Haze = 0.6
		atm.Glare = 0.1
		atm.Color = Color3.fromRGB(200, 214, 230)
		atm.Decay = Color3.fromRGB(120, 130, 150)
	end
	local cc = L:FindFirstChildOfClass("ColorCorrectionEffect")
	if cc then
		cc.Saturation = 0.1
		cc.Contrast = 0.06
		cc.Brightness = 0.02
		cc.TintColor = Color3.fromRGB(255, 250, 244)
	end
	local bloom = L:FindFirstChildOfClass("BloomEffect")
	if bloom then
		bloom.Intensity = 0.25
		bloom.Threshold = 1.8
	end
	return "lumière : ambiance chaude, saturation 0,1, brume 0,6"
end
