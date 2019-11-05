return function (script)
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local TeleportService = game:GetService("TeleportService")
	
	local c = workspace.CurrentCamera
	local moon = script:WaitForChild("Moon")
	moon.Locked = true
	moon.Size = Vector3.new(50,50,1)
	
	local function moonUpdate()
		if TeleportService:GetTeleportSetting("ClassicSky") then
			local pos = Lighting:GetMoonDirection() * 900
			local origin = c.CFrame.p
			moon.Parent = c
			moon.CFrame = CFrame.new(origin+pos, origin)
		else
			moon.Parent = nil
		end
	end
	
	RunService:BindToRenderStep("MoonUpdate",201,moonUpdate)
	return 1
end