local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local adorn = script:WaitForChild("Rays")
local sunRays = adorn:WaitForChild("SunRays")

local function getCamera()
	return workspace.CurrentCamera
end

local function projectRay(ray, length)
	local origin = ray.Origin
	local direction = ray.Direction
	return Ray.new(origin, direction.Unit * length)
end

local function computeSunVisibility()
	local sunPos = Lighting:GetSunDirection()
	local camera = getCamera()
	local cf = camera.CFrame
	
	if sunPos:Dot(cf.LookVector) > 0 then
		local sunView = camera:WorldToViewportPoint(cf.Position + sunPos)
		local visibility = 0
		local total = 0
		
		for dx = -1, 1 do
			for dy = -1, 1 do
				local posX = math.floor(sunView.X + dx * 15)
				local posY = math.floor(sunView.Y + dy * 15)
				
				local sunRay = camera:ViewportPointToRay(posX, posY)
				sunRay = projectRay(sunRay, 5000)

				local hit, pos = workspace:FindPartOnRay(sunRay, camera)

				if not hit then
					visibility = visibility + 1
				end

				total = total + 1
			end
		end
		
		return visibility / total, sunView
	end
	
	return 0
end

local function update()
	if TeleportService:GetTeleportSetting("ClassicSky") then
		local sunPos = Lighting:GetSunDirection()
		if sunPos.Y >= -.1 then
			local visibility, sunView = computeSunVisibility()

			if visibility > 0.001 then
				local attenuation = (1 - (2 * visibility - 1) * (2 * visibility - 1))
				local strength = math.clamp((((1 - sunPos.Y) * 2) / math.sqrt(2)), 0, 1)
				local opacity = attenuation * 0.4 * strength
				
				local camera = getCamera()
				local rayPos = camera:ViewportPointToRay(sunView.X, sunView.Y, 1).Origin
				local rayLook = camera.CFrame.Position
				
				adorn.Parent = camera
				adorn.CFrame = CFrame.new(rayPos, rayLook)
				sunRays.Transparency = NumberSequence.new(1 - opacity)
				
				return
			end
		end
	end
	
	adorn.Parent = nil
end

RunService:BindToRenderStep("SunRays", 201, update)