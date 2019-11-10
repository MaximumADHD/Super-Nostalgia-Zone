local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local camera = workspace.CurrentCamera
local lensFlareNode = camera:FindFirstChild("LensFlareNode")

if not lensFlareNode then
	lensFlareNode = Instance.new("Part")
	lensFlareNode.Name = "LensFlareNode"
	lensFlareNode.Transparency = 1
	lensFlareNode.Anchored = true
	lensFlareNode.CanCollide = false
	lensFlareNode.Locked = true
	lensFlareNode.Parent = camera
end

local lenses = 
{
	{ Color = Color3.fromRGB(200, 255, 200), Radius = 1.20, Distance = 0.100 };
	{ Color = Color3.fromRGB(  0, 255,   0), Radius = 0.50, Distance = 0.200 };
	{ Color = Color3.fromRGB(255,   0,   0), Radius = 0.30, Distance = 0.225 };
	{ Color = Color3.fromRGB(255, 170,   0), Radius = 1.50, Distance = 0.250 };
	{ Color = Color3.fromRGB(255, 170,   0), Radius = 3.00, Distance = 0.250 };
	{ Color = Color3.fromRGB(  0, 255,   0), Radius = 0.50, Distance = 0.300 };
	{ Color = Color3.fromRGB(  0, 255,   0), Radius = 0.20, Distance = 0.600 };
	{ Color = Color3.fromRGB(  0, 255,   0), Radius = 0.40, Distance = 0.650 };
	{ Color = Color3.fromRGB(255,   0,   0), Radius = 0.20, Distance = 0.780 };
	{ Color = Color3.fromRGB(  0, 255,   0), Radius = 0.25, Distance = 0.900 };
	{ Color = Color3.fromRGB( 23,  17,   0), Radius = 0.15, Distance = 1.200 };
	{ Color = Color3.fromRGB( 23,  17,   0), Radius = 0.15, Distance = 1.500 };
}

local function projectRay(ray,length)
	local origin = ray.Origin
	local direction = ray.Direction
	return Ray.new(origin,direction.Unit * length)
end

local function computeSunOcclusion(sunPos)
	local cf = camera.CFrame
	
	if sunPos:Dot(cf.LookVector) > 0 then
		local sunView = camera:WorldToViewportPoint(cf.Position + sunPos)
		local visibility = 0
		local total = 0
		
		for dx = -1,1 do
			for dy = -1,1 do
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
		
		visibility = visibility / total
		return (1 - visibility), sunView
	end
	
	return 0
end

local function asVector2(v3, ...)
	return Vector2.new(v3.X, v3.Y), ...
end

local function update()
	if TeleportService:GetTeleportSetting("ClassicSky") then
		local vpSize = camera.ViewportSize
		local sunDir = Lighting:GetSunDirection()

		local sunWP = sunDir * 10e6
		local sunSP, inView = asVector2(camera:WorldToViewportPoint(sunWP))

		local occlusion = inView and computeSunOcclusion(sunDir) or 1
		
		if occlusion < 1 and sunDir.Y > -0.1 then
			local invSunSP = vpSize - sunSP
			local enabled = (inView and occlusion < 1)
			local flareBrightness = math.sqrt(math.max(0, sunDir.Y * 4))
			
			for i, lense in ipairs(lenses) do
				local radius = lense.Radius / 12

				if not lense.Beam then	
					local a0 = Instance.new("Attachment")
					lense.A0 = a0
					a0.Name = i .. "_A0"
					a0.Parent = lensFlareNode
					
					local a1 = Instance.new("Attachment")
					lense.A1 = a1
					a1.Name = i .. "_A1"
					a1.Parent = lensFlareNode
					
					local beam = Instance.new("Beam")
					lense.Beam = beam
					
					beam.Name = i
					beam.Color = ColorSequence.new(lense.Color)
					beam.Width0 = radius
					beam.Width1 = radius
					beam.TextureSpeed = 0
					beam.Transparency = NumberSequence.new(0.9)
					beam.LightEmission = 1
					beam.Texture = "rbxasset://sky/lensflare.jpg"
					beam.Attachment0 = a0
					beam.Attachment1 = a1
					beam.Parent = lensFlareNode
				end
				
				local lenseSP = invSunSP:Lerp(sunSP, lense.Distance)
				local lenseWP = camera:ViewportPointToRay(lenseSP.X, lenseSP.Y, 1).Origin
				local lenseCF = CFrame.new(lenseWP, lenseWP - sunDir)

				lense.A0.CFrame = lenseCF * CFrame.new(-radius / 2, 0, 0)
				lense.A1.CFrame = lenseCF * CFrame.new( radius / 2, 0, 0)
			end
			
			lensFlareNode.Parent = camera
			return
		end
	end
	
	lensFlareNode.Parent = nil
end

RunService:BindToRenderStep("LensFlareUpdate", 201, update)