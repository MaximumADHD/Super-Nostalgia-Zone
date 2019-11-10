local TeleportService = game:GetService("TeleportService")

local classicExp = script:WaitForChild("Particle")
local camera = workspace.CurrentCamera

local baseExpAdorn = Instance.new("UnionOperation")
baseExpAdorn.Name = "ExplosionAdorn"
baseExpAdorn.Anchored = true
baseExpAdorn.CanCollide = false
baseExpAdorn.Locked = true
baseExpAdorn.Transparency = 1
baseExpAdorn.Size = Vector3.new()

local function onDescendantAdded(exp)
	if exp:IsA("Explosion") then
		local cf = CFrame.new(exp.Position)
		local expAdorn = baseExpAdorn:Clone()

		local lifeTime = 1.5
		exp.Visible = false

		if TeleportService:GetTeleportSetting("RetroExplosions") then
			local expObj = Instance.new("SphereHandleAdornment")
			expObj.Adornee = expAdorn
			expObj.Radius = exp.BlastRadius
			expObj.Color3 = Color3.new(1, 0, 0)
			expObj.CFrame = cf
			expObj.Parent = expAdorn

			lifeTime = 1

			if exp.BlastRadius > 1 then
				lifeTime = lifeTime - (1 / exp.BlastRadius)
			end
		else
			local e = classicExp:Clone()
			e.Parent = expAdorn
			expAdorn.CFrame = cf
			
			spawn(function ()
				local lessParticles = TeleportService:GetTeleportSetting("ReducedParticles")
				local count = lessParticles and 25 or 100

				for i = 1, 8 do
					e:Emit(count)
					wait(0.125)
				end
			end)
		end

		expAdorn.Parent = camera
		wait(lifeTime)
		
		expAdorn:Destroy()
	end
end

workspace.DescendantAdded:Connect(onDescendantAdded)