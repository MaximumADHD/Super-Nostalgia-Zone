local RunService = game:GetService("RunService")
local GameSettings = UserSettings():GetService("UserGameSettings")

local char = script.Parent
local humanoid = char:WaitForChild("Humanoid")
local climbing = char:WaitForChild("Climbing")
local rootPart = humanoid.RootPart

local c = workspace.CurrentCamera
local blankV3 = Vector3.new()
local xz = Vector3.new(1,0,1)
local bg = rootPart:FindFirstChild("FirstPersonGyro")

local runState = Enum.HumanoidStateType.Running

if not bg then
	bg = Instance.new("BodyGyro")
	bg.Name = "FirstPersonGyro"
	bg.MaxTorque = Vector3.new(0,10e6,0)
	bg.D = 100
end

local function toRotation(dir)
	return CFrame.new(blankV3,dir)
end

local velocityThreshold = 200
spawn(function ()
	local threshold = char:WaitForChild("VelocityThreshold",5)
	if threshold then
		velocityThreshold = threshold.Value
	end
end)

local function update()
	local zoom = (c.Focus.Position - c.CFrame.Position).Magnitude
	local rotationType = GameSettings.RotationType
	local seatPart = humanoid.SeatPart
	
	if rotationType.Name == "CameraRelative" and not seatPart then
		local dir
		
		if zoom <= 1.5 then
			dir = c.CFrame.lookVector
		else
			bg.Parent = nil
		end
		
		if dir then
			bg.CFrame = toRotation(dir * xz)
			bg.Parent = rootPart
		end

		humanoid.AutoRotate = false
	else
		local state = humanoid:GetState()
		local isRunning = (state == runState)
		local isClimbing = climbing.Value
		humanoid.AutoRotate = (isRunning or isClimbing)
		bg.Parent = nil
	end
	
	if rootPart.Velocity.Magnitude > velocityThreshold and not seatPart then
		humanoid:ChangeState("FallingDown")
	end
end

humanoid.AutoRotate = false
humanoid:SetStateEnabled("Climbing",false)
RunService:BindToRenderStep("GoofyMotion", 400, update)

c.FieldOfView = 65