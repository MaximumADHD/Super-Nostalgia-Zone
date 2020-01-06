-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Sky Colors

local midnight = 0
local day = 86400
local hour = day / 24

local sunRise = day * .25
local sunSet = day * .75
local riseAndSetTime = hour / 2

local times =
{
	midnight;
	sunRise - hour;
	sunRise - riseAndSetTime;
	sunRise;
	sunRise + riseAndSetTime;
	sunSet - riseAndSetTime;
	sunSet;
	sunSet + (hour/3);
	day;
}

local colors = 
{
	Color3.new();
	Color3.new();
	Color3.new(.2, .15, .01);
	Color3.new(.2, .15, .01);
	Color3.new(1, 1, 1);
	Color3.new(1, 1, 1);
	Color3.new(.4, .2, .05);
	Color3.new();
	Color3.new();
}

local function linearSpline(x, times, values)
	assert(#times == #values)

	if #values == 1 or x < times[1] then
		return values[1]
	end
	
	for i = 2, #times do
		if x < times[i] then
			local alpha = (times[i] - x) / (times[i] - times[i - 1])
			return values[i - 1]:lerp(values[i], 1 - alpha)
		end
	end
	
	return values[#values]
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function r()
	return -1 + (math.random() * 2)
end

local lastTime = 0
local camera = workspace.CurrentCamera

local skyAdorn = script:WaitForChild("SkyAdorn")
local night = skyAdorn:WaitForChild("Night")
local nightFrame = night:WaitForChild("NightFrame")
local star = script:WaitForChild("Star")

local shadowsOn = true
local black = Color3.new()

local toneMap do
	toneMap = Instance.new("ColorCorrectionEffect")
	toneMap.TintColor = Color3.new(1.25, 1.25, 1.25)
	toneMap.Name = "LegacyToneMap"
	toneMap.Brightness = 0.03
	toneMap.Saturation = 0.07
	toneMap.Contrast = -0.15
	toneMap.Parent = Lighting
	
	if Lighting.Ambient ~= black then
		Lighting.OutdoorAmbient = Lighting.Ambient
		Lighting.Ambient = black:Lerp(Lighting.Ambient, 0.5)
	end
	
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.1
end

for i = 1, 3000 do
	local bb = star:Clone()
	local size = math.random(2, 6) / 2
	bb.StudsOffsetWorldSpace = Vector3.new(r(), r(), r()).Unit * 2500
	bb.Star.Transparency = (math.random(1, 4) - 1) / 4
	-- bb.Size = UDim2.new(0, size, 0, size)
	bb.Adornee = skyAdorn
	bb.Parent = skyAdorn
end

local function updateSky()
	local shadowState = TeleportService:GetTeleportSetting("StencilShadows")
	
	if shadowState == nil then
		TeleportService:SetTeleportSetting("StencilShadows", true)
		shadowState = true
	end
	
	if shadowState ~= shadowsOn then
		shadowsOn = shadowState
		
		if shadowsOn then
			local black = Color3.new()
			Lighting.GlobalShadows = true
			Lighting.Ambient = black:Lerp(Lighting.OutdoorAmbient, 0.5)
		else
			Lighting.GlobalShadows = false
			Lighting.Ambient = Lighting.OutdoorAmbient
		end
	end

	local sunDir = Lighting:GetSunDirection()
	local globalLight = math.clamp((sunDir.Y + .033) * 10, 0, 1)
	
	toneMap.Contrast = -0.15 * globalLight
	toneMap.Saturation = 0.07 * globalLight
	
	if TeleportService:GetTeleportSetting("ClassicSky") then
		local camera = workspace.CurrentCamera
		local seconds = Lighting:GetMinutesAfterMidnight() * 60
		
		if seconds < 0 then
			seconds = day + seconds
		end
		
		if seconds ~= lastTime then
			local sunDir = game.Lighting:GetSunDirection() 
			local skyColor = linearSpline(seconds, times, colors)
			nightFrame.BackgroundTransparency = globalLight
			nightFrame.BackgroundColor3 = skyColor
			lastTime = seconds
		end
		
		skyAdorn.CFrame = CFrame.new(camera.CFrame.Position) * CFrame.new(Vector3.new(), sunDir)
		skyAdorn.Parent = (nightFrame.BackgroundTransparency < 1 and camera or nil)
	else
		skyAdorn.Parent = nil
	end
end

RunService:BindToRenderStep("UpdateSky", 201, updateSky)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------