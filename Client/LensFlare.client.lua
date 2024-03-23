------------------------------------------------------------------------------------------------------------------------
-- @CloneTrooper1019, 2018 <3
-- Lens Flare Effect
-- A remake of Roblox's 2007 Lens Flare
------------------------------------------------------------------------------------------------------------------------
-- Configuration
------------------------------------------------------------------------------------------------------------------------

-- Classic Style

local LENS_FLARE_CONFIGURATION = 
{	
	Scale = 1/8;
	Texture = "rbxasset://textures/whiteCircle.png";
	Transparency = 0.9;
}

-- Modern Style

--local LENS_FLARE_CONFIGURATION =
--{
--	
--	Scale = 1/3;
--	Texture = "rbxasset://textures/shadowblurmask.png";
--	Transparency = 0.7;
--}

------------------------------------------------------------------------------------------------------------------------
-- Lenses
------------------------------------------------------------------------------------------------------------------------
--[[
	The LENSES array is used to control the individual lenses of the effect.
	
	* Color		- The color of the lense.
	* Radius	- An arbitrary scaling factor for each lense.
	* Distance	- A value between 0 and 1 indicating the position of the lense on the screen.
				  ( A value of 0.5 will always be at the center of the screen )
				  ( A value of 1.0 will be directly on top of the sun )
				  ( A value of 0.0 will be on the opposite end of the screen )
	
--]]

local LENSES = 
{
	{ Color = Color3.fromRGB(200, 255, 200), Radius = 1.00, Distance = 0.000 };
	{ Color = Color3.fromRGB(  0, 255,   0), Radius = 0.50, Distance = 0.200 };
	{ Color = Color3.fromRGB(255,   0,   0), Radius = 0.30, Distance = 0.225 };
	{ Color = Color3.fromRGB(255, 170,   0), Radius = 1.50, Distance = 0.250 };
	{ Color = Color3.fromRGB(255, 170,   0), Radius = 3.00, Distance = 0.250 };
	{ Color = Color3.fromRGB(  0, 255,   0), Radius = 0.50, Distance = 0.300 };
	{ Color = Color3.fromRGB(  0, 255,   0), Radius = 0.20, Distance = 0.600 };
	{ Color = Color3.fromRGB(  0, 255,   0), Radius = 0.40, Distance = 0.650 };
	{ Color = Color3.fromRGB(255,   0,   0), Radius = 0.20, Distance = 0.780 };
	{ Color = Color3.fromRGB(  0, 255,   0), Radius = 0.25, Distance = 0.900 };
	{ Color = Color3.fromRGB( 63,  63,  63), Radius = 0.15, Distance = 1.200 };
	{ Color = Color3.fromRGB( 63,  63,  63), Radius = 0.15, Distance = 1.500 };
}

------------------------------------------------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------------------------------------------------

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local c = workspace.CurrentCamera
local lensFlareNode = c:FindFirstChild("LensFlareNode")
if lensFlareNode then
	lensFlareNode:ClearAllChildren()
else
	lensFlareNode = Instance.new("Part")
	lensFlareNode.Name = "LensFlareNode"
	lensFlareNode.Transparency = 1
	lensFlareNode.Anchored = true
	lensFlareNode.CanCollide = false
	lensFlareNode.Locked = true
	lensFlareNode.Parent = c
end

------------------------------------------------------------------------------------------------------------------------
-- Main
------------------------------------------------------------------------------------------------------------------------

local function as_Vector2(v3,...)
	-- Roblox likes to kill my OCD.
	return Vector2.new(v3.X,v3.Y),...
end

local function isSunOccluded(sunDir)
	local origin = c.CFrame.p + (c.CFrame.lookVector*2)
	local ray = Ray.new(origin,origin + (sunDir * 10e6))
	local ignore = {}
	local occluded = false
	while true do
		local hit,pos = workspace:FindPartOnRayWithIgnoreList(ray,ignore)
		if hit then
			local t = hit.Transparency + hit.LocalTransparencyModifier
			if t <= 0 then
				occluded = true
				break
			else
				table.insert(ignore,hit)
			end
		else
			break
		end
	end
	return occluded
end

local function createLenseBeam(lense,id)
	local radius = lense.Radius * LENS_FLARE_CONFIGURATION.Scale
	
	local a0 = Instance.new("Attachment")
	a0.Name = id .. "_A0"
	a0.Parent = lensFlareNode
	lense.A0 = a0
	
	local a1 = Instance.new("Attachment")
	a1.Name = id .. "_A1"
	a1.Parent = lensFlareNode
	lense.A1 = a1
	
	local beam = Instance.new("Beam")
	beam.Name = id
	beam.Color = ColorSequence.new(lense.Color)
	beam.Width0 = radius
	beam.Width1 = radius
	beam.TextureSpeed = 0
	beam.LightEmission = 1
	beam.Texture = LENS_FLARE_CONFIGURATION.Texture
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Transparency = NumberSequence.new(LENS_FLARE_CONFIGURATION.Transparency)
	beam.Parent = lensFlareNode
	lense.Beam = beam

	return beam
end

local function updateLensFlare()
	local vpSize = c.ViewportSize
	local sunDir = Lighting:GetSunDirection()
	local sunWrldSpace = sunDir * 10e6
	local sunScrnSpace,inView = as_Vector2(c:WorldToViewportPoint(sunWrldSpace))
	local sunScrnSpaceInv = c.ViewportSize - sunScrnSpace
	local enabled = (inView and not isSunOccluded(sunDir))
	
	for i,lense in ipairs(LENSES) do
		local beam = lense.Beam or createLenseBeam(lense,i)
		beam.Enabled = enabled
		if enabled then
			local radius = lense.Radius * LENS_FLARE_CONFIGURATION.Scale
			local lenseSP = sunScrnSpaceInv:lerp(sunScrnSpace,lense.Distance)
			local lenseWP = c:ViewportPointToRay(lenseSP.X,lenseSP.Y,1).Origin
			local lenseCF = CFrame.new(lenseWP,lenseWP - sunDir)
			lense.A0.CFrame = lenseCF * CFrame.new(-radius/2,0,0)
			lense.A1.CFrame = lenseCF * CFrame.new(radius/2,0,0)
		end
	end
end

RunService:BindToRenderStep("UpdateLensFlare",201,updateLensFlare)

------------------------------------------------------------------------------------------------------------------------