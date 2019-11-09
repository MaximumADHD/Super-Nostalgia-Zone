local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local camera = workspace.CurrentCamera
local moon = script:WaitForChild("Moon")

moon.Locked = true
moon.Size = Vector3.new(50, 50, 1)

local function moonUpdate()
	if TeleportService:GetTeleportSetting("ClassicSky") then
		local pos = Lighting:GetMoonDirection() * 900
		local origin = camera.CFrame.Position

		moon.Parent = camera
		moon.CFrame = CFrame.new(origin + pos, origin)
	else
		moon.Parent = nil
	end
end

RunService:BindToRenderStep("MoonUpdate", 201, moonUpdate)