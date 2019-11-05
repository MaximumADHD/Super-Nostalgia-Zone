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
local hour = day/24

local sunRise = day * .25
local sunSet = day * .75
local riseAndSetTime = hour/2

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

local function linearSpline(x,times,values)
	assert(#times == #values)
	if #values == 1 or x < times[1] then
		return values[1]
	end
	
	for i = 2, #times do
		if x < times[i] then
			local alpha = (times[i] - x) / (times[i] - times[i-1])
			return values[i-1]:lerp(values[i], 1-alpha)
		end
	end
	
	return values[#values]
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local lastTime = 0
local c = workspace.CurrentCamera

local function r()
	return -1 + (math.random()*2)
end

local skyAdorn = script:WaitForChild("SkyAdorn")
local night = skyAdorn:WaitForChild("Night")
local nightFrame = night:WaitForChild("NightFrame")
local star = script:WaitForChild("Star")

if UserInputService.TouchEnabled then
	-- TODO: Get rid of this when shadow-mapping is available
	--       on mobile or the tone mapping is corrected.
	
	spawn(function ()
		local legacyToneMap = Lighting:WaitForChild("LegacyToneMap")
		legacyToneMap:Destroy()
	end)
end

return function (script)
	local shadowsOn = true
	
	for i = 1,500 do
		local bb = star:Clone()
		bb.StudsOffsetWorldSpace = Vector3.new(r(), r(), r()).Unit * 2500
		bb.Size = UDim2.new(0, math.random(2, 5), 0, math.random(2, 5))
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
		
		
		
		if TeleportService:GetTeleportSetting("ClassicSky") then
			local seconds = Lighting:GetMinutesAfterMidnight() * 60
			
			if seconds < 0 then
				seconds = day + seconds
			end
			
			if seconds ~= lastTime then
				local sunDir = game.Lighting:GetSunDirection() 
				local skyColor = linearSpline(seconds, times, colors)
				nightFrame.BackgroundColor3 = skyColor
				nightFrame.BackgroundTransparency = math.clamp((sunDir.Y + .033) * 10, 0, 1)
				lastTime = seconds
			end
			
			local sunDir = Lighting:GetSunDirection()
			skyAdorn.CFrame = CFrame.new(c.CFrame.p) * CFrame.new(Vector3.new(), sunDir)
			skyAdorn.Parent = (nightFrame.BackgroundTransparency < 1 and c or nil)
		else
			skyAdorn.Parent = nil
		end
	end
	
	RunService:BindToRenderStep("UpdateSky", 201, updateSky)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------