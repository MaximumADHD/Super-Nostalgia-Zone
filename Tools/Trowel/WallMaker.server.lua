local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local brickSpeed = 0.04
local wallHeight = 4
local wallWidth = 12

local Tool = script.Parent
local BrickColors = require(ReplicatedStorage:WaitForChild("BrickColors"))

-- places a brick at pos and returns the position of the brick's opposite corner
local function placeBrick(cf, pos, color)
	local brick = Instance.new("Part")
	brick.BrickColor = color
	brick.CFrame = cf * CFrame.new(pos + brick.Size / 2)

	local brickScript = Tool.TrowelBrick:Clone()
	brickScript.Disabled = false
	brickScript.Parent = brick

	-- place the brick
	brick.Parent = workspace
	
	-- return brick info
	return brick, pos + brick.Size
end

local function buildWall(cf)
	local color = BrickColor.new(BrickColors[math.random(1, #BrickColors)])
	local bricks = {}

	assert(wallWidth > 0)

	local y = 0

	while y < wallHeight do
		local p
		local x = -wallWidth / 2

		while x < wallWidth / 2 do
			local brick
			brick, p = placeBrick(cf, Vector3.new(x, y, 0), color)
			x = p.x
			table.insert(bricks, brick)
			brick:MakeJoints()
			wait(brickSpeed)
		end

		y = p.y
	end

	return bricks
end

local function snap(v)
	if math.abs(v.X) > math.abs(v.Z) then
		if v.X > 0 then
			return Vector3.new(1, 0, 0)
		else
			return Vector3.new(-1, 0, 0)
		end
	else
		if v.Z > 0 then
			return Vector3.new(0, 0, 1)
		else
			return Vector3.new(0, 0, -1)
		end
	end
end

Tool.Enabled = true

local function onActivated()
	if not Tool.Enabled then
		return
	end

	Tool.Enabled = false

	local character = Tool.Parent
	local humanoid = character.Humanoid

	if humanoid == nil then
		print("Humanoid not found")
		return 
	end

	local targetPos = humanoid.TargetPoint
	local lookAt = snap( (targetPos - character.Head.Position).Unit )
	local cf = CFrame.new(targetPos, targetPos + lookAt)

	Tool.Handle.BuildSound:Play()

	buildWall(cf)
	wait(5)

	Tool.Enabled = true
end

Tool.Activated:Connect(onActivated)

