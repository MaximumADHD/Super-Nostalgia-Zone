-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Services
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Animator Data
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Animators = {}

local function createAnimator(humanoid)
	local Figure = humanoid.Parent

	local Torso = Figure:WaitForChild("Torso", 5)
	local Climbing = Figure:WaitForChild("Climbing", 5)

	if not (Torso and Climbing) then
		return
	end
	
	local animator = {}
	animator.Joints = {}
	
	do
		local joints = 
		{
			RightShoulder = Torso:WaitForChild("Right Shoulder", 5);
			LeftShoulder = Torso:WaitForChild("Left Shoulder", 5);
			RightHip = Torso:WaitForChild("Right Hip", 5);
			LeftHip = Torso:WaitForChild("Left Hip", 5);
		}
		
		if not (joints.RightShoulder and joints.LeftShoulder) then
			return
		end
		
		if not (joints.RightHip and joints.LeftHip) then
			return
		end
		
		for name, joint in pairs(joints) do
			local object = 
			{
				JointObject = joint;
				MaxVelocity = joint.MaxVelocity;
				DesiredAngle = joint.DesiredAngle;
				CurrentAngle = joint.CurrentAngle;
			}
			
			animator.Joints[name] = object
		end
	end
	
	local joints = animator.Joints
	
	local pi = math.pi
	local sin = math.sin
	
	local pose = "Standing"
	local toolAnim = "None"
	local toolAnimTime = 0
	
	local RightShoulder = joints.RightShoulder
	local LeftShoulder = joints.LeftShoulder
	
	local RightHip = joints.RightHip
	local LeftHip = joints.LeftHip
	
	function animator:SetMaxVelocities(value)
		RightShoulder.MaxVelocity = value
		LeftShoulder.MaxVelocity = value
		
		RightHip.MaxVelocity = value
		LeftHip.MaxVelocity = value
	end
	
	function animator:Update()
		local now = tick()
		
		if Climbing.Value then
			pose = "Climbing"
		else
			local stateType = humanoid:GetState()
			pose = stateType.Name
			
			if pose == "Running" then
				local speed = humanoid.WalkSpeed
				local movement = (Torso.Velocity * Vector3.new(1, 0, 1)).Magnitude
				
				if (speed * movement) < 1 then
					pose = "Standing"
				end
			end
		end
		
		if pose == "Jumping" then
			self:SetMaxVelocities(.5)
			
			RightShoulder.DesiredAngle = 1
			LeftShoulder.DesiredAngle = -1
			
			RightHip.DesiredAngle = 0
			LeftHip.DesiredAngle = 0
		elseif pose == "Freefall" then
			self:SetMaxVelocities(.5)
			
			RightShoulder.DesiredAngle = pi
			LeftShoulder.DesiredAngle = -pi
			
			RightHip.DesiredAngle = 0
			LeftHip.DesiredAngle = 0
		elseif pose == "Seated" then
			self:SetMaxVelocities(.15)
			
			RightShoulder.DesiredAngle = pi / 2
			LeftShoulder.DesiredAngle = -pi / 2
			
			RightHip.DesiredAngle = pi / 2
			LeftHip.DesiredAngle = -pi / 2
		else
			local climbFudge = 0
			local amplitude = .1
			local frequency = 1
			
			if pose == "Running" then
				self:SetMaxVelocities(0.15)
				amplitude = 1
				frequency = 9
			elseif pose == "Climbing" then
				self:SetMaxVelocities(0.5)
				climbFudge = pi
				
				amplitude = 1
				frequency = 9
			end
			
			local desiredAngle = amplitude * sin(now * frequency)
			
			RightShoulder.DesiredAngle = desiredAngle + climbFudge
			LeftShoulder.DesiredAngle = desiredAngle - climbFudge
			
			RightHip.DesiredAngle = -desiredAngle
			LeftHip.DesiredAngle = -desiredAngle
			
			local tool = Figure:FindFirstChildWhichIsA("Tool")
			
			if tool and tool.RequiresHandle and not CollectionService:HasTag(tool, "Flag") then
				local animString = tool:FindFirstChild("toolanim")
				
				if animString and animString:IsA("StringValue") then
					-- apply tool animation
					toolAnim = animString.Value
					toolAnimTime = now + .3
					
					-- delete event sender
					animString:Destroy()
				end
				
				if now > toolAnimTime then
					toolAnimTime = 0
					toolAnim = "None"
				end
				
				if toolAnim == "None" then
					RightShoulder.DesiredAngle = pi / 2
				elseif toolAnim == "Slash" then
					RightShoulder.MaxVelocity = 0.5
					RightShoulder.DesiredAngle = 0
				elseif toolAnim == "Lunge" then
					self:SetMaxVelocities(0.5)
					
					RightShoulder.DesiredAngle = pi / 2
					RightHip.DesiredAngle = pi / 2
					
					LeftShoulder.DesiredAngle = 1
					LeftHip.DesiredAngle = 1
				end
			else
				toolAnim = "None"
				toolAnimTime = 0
			end
		end
	end
	
	return animator
end

local function createAnimatorAsync(humanoid, callback)
	local async = coroutine.wrap(function ()
		local animator = createAnimator(humanoid)
		callback(animator)
	end)
	
	async()
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Collection Handler
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local animTag = "Animator"

local animAdded = CollectionService:GetInstanceAddedSignal(animTag)
local animRemoved = CollectionService:GetInstanceRemovedSignal(animTag)

local function onAnimatorAdded(humanoid)
	if humanoid:IsA("Humanoid") then
		createAnimatorAsync(humanoid, function (animator)
			if CollectionService:HasTag(humanoid, animTag) then
				Animators[humanoid] = animator
			end
		end)
	end
end

local function onAnimatorRemoved(humanoid)
	if Animators[humanoid] then
		Animators[humanoid] = nil
	end
end

for _,humanoid in pairs(CollectionService:GetTagged(animTag)) do
	onAnimatorAdded(humanoid)
end

animAdded:Connect(onAnimatorAdded)
animRemoved:Connect(onAnimatorRemoved)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Motor Angle Updater 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local desiredFPS = 30 -- The framerate that would be expected given the MaxVelocity in use.

local function updateAnimations(deltaTime)
	local velocityAdjust = desiredFPS * deltaTime
	
	for humanoid, animator in pairs(Animators) do
		-- Update the motor states
		animator:Update()
		
		-- Step the motor angles
		for name, jointData in pairs(animator.Joints) do
			local joint = jointData.JointObject
			local maxVelocity = jointData.MaxVelocity
			
			local desiredAngle = jointData.DesiredAngle
			local currentAngle = jointData.CurrentAngle
			
			-- Adjust the MaxVelocity based on the current framerate
			maxVelocity = math.abs(maxVelocity * velocityAdjust)
			
			-- Update the CurrentAngle
			local delta = (desiredAngle - currentAngle)
			
			if math.abs(delta) < maxVelocity then
				currentAngle = desiredAngle
			elseif delta > 0 then
				currentAngle = currentAngle + maxVelocity
			else
				currentAngle = currentAngle - maxVelocity
			end
			
			-- Apply the motor transform
			joint.Transform = CFrame.Angles(0, 0, currentAngle)
			jointData.CurrentAngle = currentAngle
		end
	end
end

RunService:BindToRenderStep("UpdateAnimations", 301, updateAnimations)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------