local RunService = game:GetService("RunService")

local char = script.Parent
local humanoid = char:WaitForChild("Humanoid")
local rootPart = char:WaitForChild("HumanoidRootPart")
local climbForce = rootPart:WaitForChild("ClimbForce")
local rayDown = Vector3.new(0, -5000, 0)

local function moveTowards(value, goal, rate)
	if value < goal then
		return math.min(goal, value + rate)
	elseif value > goal then
		return math.max(goal, value - rate)
	else
		return goal
	end
end

local function getFloorLevel()
	local origin = rootPart.Position
	local ray = Ray.new(origin, rayDown)
	local hit, pos = workspace:FindPartOnRay(ray, char)
	return pos.Y, math.clamp(math.abs(pos.Y - origin.Y), -1, 1)
end

local stepRate = (20 / 3)
local decayRate = 0.925

local lastLevel = getFloorLevel()
local updateCon

local function update(dt)
	local level, dist = getFloorLevel()
	local dt = math.min(0.1, dt)
	
	if humanoid.Health == 0 then
		updateCon:Disconnect()
		return
	end
	
	if humanoid.SeatPart then
		humanoid.HipHeight = 0
		lastLevel = level
		return
	end
	
	local yVel = rootPart.Velocity.Y
	local step = dt * stepRate
	
	if math.abs(yVel) > 8 then
		local goal = math.sign(yVel)
		humanoid.HipHeight = moveTowards(humanoid.HipHeight, goal, step)
	elseif lastLevel ~= level then
		humanoid.HipHeight = math.sign(lastLevel - level) * math.clamp(dist - 3, 0, 1)
		lastLevel = level
	else
		local decay = decayRate ^ (step * 60)
		humanoid.HipHeight = humanoid.HipHeight * decay
	end
end

updateCon = RunService.RenderStepped:Connect(update)