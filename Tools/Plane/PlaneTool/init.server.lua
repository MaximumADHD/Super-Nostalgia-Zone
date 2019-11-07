local Players = game:GetService("Players")

local tool = script.Parent
local plane = nil
local hold = false
local debounce = false
local planedebounce = false
local stuntdebounce = false
local controlling = false
local player

local rocket = tool:WaitForChild("Rocket")
rocket.Parent = nil

local function fireRocket(pln,spn)
	local missile = rocket:Clone()
	missile.CFrame = spn.CFrame * CFrame.new(0, 0, -35)
	missile.Anchored = false

	missile.RocketScript.Disabled = false
	missile.Parent = workspace

	local creator_tag = Instance.new("ObjectValue")
	creator_tag.Value = player
	creator_tag.Name = "creator"
	creator_tag.Parent = missile

	missile.Owner.Value = pln
end

local function fireDeathLaser(engine)
	local dir = engine.CFrame.lookVector
	for i = 1, 50 do
		local ex = Instance.new("Explosion")
		ex.BlastRadius = 6
		ex.BlastPressure = 8000000
		ex.Position = engine.Position + (dir * 50) + (dir  * i * 12)
		ex.Parent = workspace
	end
	if engine:FindFirstChild("DeathLaser") then
		engine.DeathLaser:Play()
	end
end

local function computeDirection(vec)
	local lenSquared = vec.magnitude * vec.magnitude
	local invSqrt = 1 / math.sqrt(lenSquared)
	return Vector3.new(vec.x * invSqrt, vec.y * invSqrt, vec.z * invSqrt)
end

local function move(target, engine)
	local bg = engine:findFirstChild("BodyGyro")
	if bg then
		local origincframe = bg.cframe
		local dir = (target - engine.Position).unit
		local spawnPos = engine.Position
	
		local pos = spawnPos + (dir * 1)
	
		bg.maxTorque = Vector3.new(900000, 900000, 900000)
		bg.cframe = CFrame.new(pos,  pos + dir)
		wait(0.1)
		bg.maxTorque = Vector3.new(0, 0, 0)
		bg.cframe = origincframe
	end
end

function findPlane(char)
	local player = Players:GetPlayerFromCharacter(char)
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	local plane = char:FindFirstChildWhichIsA("Model")
	if plane and plane.Name == "Plane" then
		local color_tag = plane:FindFirstChild("PlaneColor")
		if color_tag then
			color_tag.Value = player.TeamColor
		end
		local seat = plane:FindFirstChildWhichIsA("Seat",true)
		if seat then
			local occupant = seat.Occupant
			if humanoid == occupant then
				return plane
			end
		end
	end
end

local function onActivated()
	local char = tool.Parent
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		local vehicle = findPlane(char)
		if vehicle ~= nil and debounce == false and planedebounce == false and stuntdebounce == false then
			debounce = true
			player = Players:GetPlayerFromCharacter(char)
			controlling = true
		
			local engine = vehicle.Parts.Engine
			
			while wait() do
				local target = humanoid.TargetPoint
				if engine:FindFirstChild("FlyScript") ~= nil then
					move(target, engine)
				end
				if planedebounce or not controlling then 
					break 
				end
			end
			
			wait(.1)
			debounce = false
		end
	end
end

local function onDeactivated()
	controlling = false
end

local function onKeyDown(key)
	if (key~=nil) then
		key = key:lower()
		local char = tool.Parent
		local player = game.Players:GetPlayerFromCharacter(char)
		if player==nil then return end
		local vehicle = findPlane(char)
		if (vehicle==nil) then return end
		plane = vehicle.Parts
		local engine = vehicle.Parts.Engine
			if (key=="f") and tool.Enabled then
				local engine = plane.Engine
				if engine:FindFirstChild("DeathLaserMode") and engine.DeathLaserMode.Value then
					fireDeathLaser(engine)
				else
					fireRocket(vehicle,plane.Gun1)
					fireRocket(vehicle,plane.Gun2)
				end
				tool.Enabled = false
				wait(1)
				tool.Enabled = true
			end
			if (key=="x") and not planedebounce then
				local power = plane.Engine:FindFirstChild("FlyScript")
				if (power ~= nil) then
					power:Destroy()
					tool.Enabled = false
					for _,v in pairs(vehicle:GetDescendants()) do
						if v:IsA("ParticleEmitter") and v.Name == "EngineSparkles" then
							v.Enabled = false
						elseif v:IsA("BodyVelocity") and v.Name == "EngineForce" then
							v:Destroy()
						end
					end
				end
			end
			if (key=="y") then
				local power = plane.Engine:FindFirstChild("FlyScript")
				if not power then
					local fly = script.FlyScript:Clone()
					fly.Disabled = false
					fly.Parent = plane.Engine
					tool.Enabled = true
					for _,v in pairs(vehicle:GetDescendants()) do
						if v:IsA("ParticleEmitter") and v.Name == "EngineSparkles" then
							v.Enabled = true
						elseif v:IsA("BasePart") and v:CanSetNetworkOwnership() then
							v:SetNetworkOwner(player)
						end
					end
				end
			end
			if (key=="k") and not planedebounce then
				planedebounce = true
				for i = 1,4 do
					wait()
					engine.RotVelocity = engine.RotVelocity + Vector3.new(0, -0.7, 0)
				end
				planedebounce = false
			end
			if (key=="h") and not planedebounce then
				planedebounce = true
				for i = 1,4 do
					wait()
					engine.RotVelocity = engine.RotVelocity + Vector3.new(0, 0.7, 0)
				end
			end
			if (key=="j") and not planedebounce then
				local body = plane.Engine.BodyGyro
				body.maxTorque = Vector3.new(9000, 9000, 9000)

				local position = engine.CFrame * Vector3.new(0, 0.5, -4)
				local dir = position - engine.Position

				dir = computeDirection(dir)

				local spawnPos = engine.Position

				local pos = spawnPos + (dir * 8)

				body.cframe = CFrame.new(pos,  pos + dir)
				wait(.2)
				body.maxTorque = Vector3.new(0, 0, 0)
			end
			if (key=="l") and planedebounce == false then
				local body = plane.Engine.BodyGyro
				body.maxTorque = Vector3.new(9000, 0, 0)
				local frame = plane:FindFirstChild("OriginCFrame")
				if frame ~= nil then
					body.cframe = frame.Value
				end
				wait(0.1)
				body.maxTorque = Vector3.new(0, 0, 0)
			end
			if (key=="u") and planedebounce == false then
				local body = plane.Engine.BodyGyro
				body.maxTorque = Vector3.new(9000, 9000, 9000)

				local position = engine.CFrame * Vector3.new(0, -0.5, -4)
				local dir = position - engine.Position

				dir = computeDirection(dir)

				local spawnPos = engine.Position

				local pos = spawnPos + (dir * 8)

				body.cframe = CFrame.new(pos,  pos + dir)
				wait(.2)
				body.maxTorque = Vector3.new(0, 0, 0)
			end
			if (key=="g") and planedebounce == false and stuntdebounce == false then
				planedebounce = true
				stuntdebounce = true
				plane.Parent.Stunt.Value = 1
				local body = plane.Engine.BodyGyro
				body.maxTorque = Vector3.new(9000, 9000, 9000)

				local currentframe = plane.Engine.CFrame

				for i = 1,6 do
				body.cframe = plane.Engine.CFrame * CFrame.fromEulerAnglesXYZ(0, 0, 30)
				wait(.2)
				end

				body.cframe = currentframe
				wait(.6)

				body.maxTorque = Vector3.new(0, 0, 0)
				planedebounce = false
				plane.Parent.Stunt.Value = 0
				wait(3)
				stuntdebounce = false
			end
			if (key=="t") and planedebounce == false and stuntdebounce == false then
				planedebounce = true
				stuntdebounce = true
				plane.Parent.Stunt.Value = 1
				local body = plane.Engine.BodyGyro
				body.maxTorque = Vector3.new(9000, 9000, 9000)

				local currentframe = plane.Engine.CFrame
				local valy = 30
				local valz = 30

				for i = 1,8 do
				body.cframe = currentframe * CFrame.fromEulerAnglesXYZ(0, valy, valz)
				valy = valy +50
				valz = valz +100
				wait(.1)
				end

				body.cframe = currentframe * CFrame.fromEulerAnglesXYZ(0, 600, 0)

				wait(.5)

				body.maxTorque = Vector3.new(0, 0, 0)
				planedebounce = false
				plane.Parent.Stunt.Value = 0
				wait(4)
				stuntdebounce = false
			end
	end
end

spawn(function ()
	local iconOverride = tool:WaitForChild("IconOverride")
	while wait(.25) do
		local isToolInactive = true
		local char = tool.Parent
		if char and char:IsA("Model") then
			local plane = findPlane(char)
			if plane then
				if plane.Parts.Engine:FindFirstChild("FlyScript") then
					isToolInactive = false
				end
			end
		end
		iconOverride.Parent = isToolInactive and tool or nil
	end
end)

local keyEvent = tool:WaitForChild("KeyEvent",99999)

local function onKeyEvent(key,down)
	if down then
		onKeyDown(key)
	end
end

tool.Activated:Connect(onActivated)
tool.Deactivated:Connect(onDeactivated)
keyEvent.Event:Connect(onKeyEvent)