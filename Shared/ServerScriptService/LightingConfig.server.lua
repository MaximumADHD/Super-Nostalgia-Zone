local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

if not CollectionService:HasTag(Lighting, "ConfigApplied") then
	local toneMap = Instance.new("ColorCorrectionEffect")
	toneMap.TintColor = Color3.new(1.25, 1.25, 1.25)
	toneMap.Brightness = 0.03
	toneMap.Saturation = 0.07
	toneMap.Contrast = -0.15
	
	toneMap.Name = "LegacyToneMap"
	toneMap.Parent = Lighting
	
	local black = Color3.new()
	
	if Lighting.Ambient ~= black then
		Lighting.OutdoorAmbient = Lighting.Ambient
		Lighting.Ambient = black:Lerp(Lighting.Ambient, 0.5)
	end
	
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0
	
	CollectionService:AddTag(Lighting, "ConfigApplied")
end