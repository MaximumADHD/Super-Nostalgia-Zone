--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local char = script.Parent

local humanoid = char:WaitForChild("Humanoid")
humanoid:SetStateEnabled("Climbing", false)

local rootPart = humanoid.RootPart
local bv = rootPart:FindFirstChild("ClimbForce")

if not bv then
	bv = Instance.new("BodyVelocity")
	bv.Name = "ClimbForce"
	bv.Parent = humanoid.RootPart
end

bv.MaxForce = Vector3.new()

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Climbing State
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local climbing = char:WaitForChild("Climbing")
local setValue = climbing:WaitForChild("SetValue")

local function onClimbing(value)
	setValue:FireServer(value)
end

climbing.Changed:Connect(onClimbing)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Debug Visuals
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Debris = game:GetService("Debris")
local isDevTest = false

local DEBUG_COLOR_RED = Color3.new(1, 0, 0)
local DEBUG_COLOR_YLW = Color3.new(1, 1, 0)
local DEBUG_COLOR_GRN = Color3.new(0, 1, 0)

local debugBox = Instance.new("BoxHandleAdornment")
debugBox.Adornee = workspace.Terrain
debugBox.Color3 = DEBUG_COLOR_RED
debugBox.Visible = false
debugBox.Parent = script

local debugCylinder = Instance.new("CylinderHandleAdornment")
debugCylinder.Color = BrickColor.new("Bright violet")
debugCylinder.Adornee = workspace.Terrain
debugCylinder.Height = 0.2
debugCylinder.Radius = 1.0
debugCylinder.Visible = false
debugCylinder.Parent = script

local debugSBox = Instance.new("SelectionBox")
debugSBox.Color3 = DEBUG_COLOR_RED
debugSBox.Parent = script

local function drawRayIfDebugging(rayStart, look, length, color)
	if isDevTest then
		local line = Instance.new("LineHandleAdornment")
		line.CFrame = CFrame.new(rayStart, rayStart + (look.Unit * length))
		line.Adornee = workspace.Terrain
		line.Length = length
		line.Color3 = color
		line.Thickness = 4
		line.Parent = script
		
		local cone = Instance.new("ConeHandleAdornment")
		cone.CFrame = CFrame.new(rayStart + (look.Unit * (length - 0.32)), rayStart + (look.Unit * length))
		cone.Adornee = workspace.Terrain
		cone.Color3 = color
		cone.Radius = 1 / 10
		cone.Height = 1 / 3
		cone.Parent = script
		
		Debris:AddItem(line, .5)
		Debris:AddItem(cone, .5)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Main Climbing Logic
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local searchDepth = 0.7
local maxClimbDist = 2.45
local sampleSpacing = 1 / 7
local lowLadderSearch = 2.7
local stepForwardFrames = 0
local ladderSearchDist = 2.0

local running = Enum.HumanoidStateType.Running
local freefall = Enum.HumanoidStateType.Freefall

local function findPartInLadderZone()
	debug.profilebegin("FastClimbCheck")
	--
	
	local cf = rootPart.CFrame
	
	local top = -humanoid.HipHeight
	local bottom = -lowLadderSearch + top
	local radius = 0.5 * ladderSearchDist
	
	local center = cf.Position + (cf.LookVector * ladderSearchDist * 0.5)
	local min = Vector3.new(-radius, bottom, -radius)
	local max = Vector3.new(radius, top, radius)
	
	local extents = Region3.new(center + min, center + max)
	local parts = workspace:FindPartsInRegion3(extents, char)
	
	if isDevTest then
		if #parts > 0 then
			debugBox.Visible = false
			debugSBox.Visible = true
			debugSBox.Adornee = parts[1]
		else
			debugBox.Visible = true
			debugSBox.Visible = false
			
			debugBox.Size = extents.Size
			debugBox.CFrame = extents.CFrame
			
			debugCylinder.Visible = false
		end
	end
	
	--
	debug.profileend()
	return #parts > 0
end

local function findLadder()
	if not findPartInLadderZone() then
		return false
	end
	
	debug.profilebegin("ExpensiveClimbCheck")
	
	local torsoCoord = rootPart.CFrame
	local torsoLook = torsoCoord.LookVector
	
	local firstSpace = 0
	local firstStep = 0
	
	local lookForSpace = true
	local lookForStep = false
	
	local debugColor = DEBUG_COLOR_YLW
	local topRay = math.floor(lowLadderSearch / sampleSpacing)
	
	for i = 1, topRay do
		local distFromBottom = i * sampleSpacing
		local originOnTorso = Vector3.new(0, -lowLadderSearch + distFromBottom, 0)
		
		local casterOrigin = torsoCoord.Position + originOnTorso
		local casterDirection = torsoLook * ladderSearchDist
		
		local ray = Ray.new(casterOrigin, casterDirection)
		local hitPrim, hitLoc = workspace:FindPartOnRay(ray, char)
		
		-- make trusses climbable.
		if hitPrim and hitPrim:IsA("TrussPart") then
			return true
		end
		
		local mag = (hitLoc - casterOrigin).Magnitude
		
		if mag < searchDepth then
			if lookForSpace then
				debugColor = DEBUG_COLOR_GRN
				firstSpace = distFromBottom
				
				lookForSpace = false
				lookForStep = true
			end
		elseif lookForStep then
			firstStep = distFromBottom - firstSpace
			debugColor = DEBUG_COLOR_RED
			lookForStep = false
		end
		
		drawRayIfDebugging(casterOrigin, casterDirection, mag, debugColor)
	end
	
	local found = (firstSpace < maxClimbDist and firstStep > 0 and firstStep < maxClimbDist)
	debugCylinder.Visible = isDevTest and found
	
	if debugCylinder.Visible then
		local y = Vector3.FromAxis('Y')
		local pos = torsoCoord.Position + Vector3.new(0, 5, 0)
		debugCylinder.CFrame = CFrame.new(pos, pos + y)
	end
	
	debug.profileend()
	return found
end

while wait() do
	local canClimb = false
	
	local state = humanoid:GetState()
	local speed = humanoid.WalkSpeed
	
	if state == freefall or state == running then
		canClimb = findLadder()
	end
	
	if canClimb then
		local climbSpeed = speed * 0.7
		bv.Velocity = Vector3.new(0, climbSpeed, 0)
		bv.MaxForce = Vector3.new(climbSpeed * 100, 10e6, climbSpeed * 100)
	else
		if climbing.Value then
			stepForwardFrames = 2
		end
		
		bv.MaxForce = Vector3.new()
	end
	
	if stepForwardFrames > 0 then
		local cf = rootPart.CFrame
		humanoid:Move(cf.LookVector)
		stepForwardFrames = stepForwardFrames - 1
	end
	
	climbing.Value = canClimb
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------