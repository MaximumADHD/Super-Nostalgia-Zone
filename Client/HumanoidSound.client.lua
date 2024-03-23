local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local soundTag = "HumanoidSound"
local soundMounted = CollectionService:GetInstanceAddedSignal(soundTag)

----------------------------------------------------------------------------------------------------

local function deleteSound(sound)
	sound.EmitterSize = 0
	Debris:AddItem(sound, 0.1)
end

local function setSoundId(soundId, andThen)
	return function (sound, humanoid)
		sound.SoundId = "rbxasset://sounds/" .. soundId
		sound.Pitch = 1
		
		if andThen then
			andThen(sound, humanoid)
		end
	end
end

local function mountSoundToState(sound)
	return function (state)
		sound.TimePosition = 0
		sound.Playing = state
	end
end

local function createSound(name, fileName, parent)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/" .. fileName
	sound.Parent = parent
	sound.Name = name
	
	return sound
end

local function createSound2(name, fileName, parent)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. fileName
	sound.Parent = parent
	sound.Name = name
	
	return sound
end

local function promiseChild(object, name, andThen, ...)
	local args = {...}
	
	local callback = coroutine.wrap(function ()
		local child = object:WaitForChild(name, 10)
		
		if child then
			andThen(child, unpack(args))
		end
	end)
	
	callback()
end

----------------------------------------------------------------------------------------------------

local soundActions = 
{
	Splash      = deleteSound;
	Landing     = deleteSound;
	Climbing    = deleteSound;
	Swimming    = deleteSound;
	FreeFalling = deleteSound;
	
	GettingUp = setSoundId("hit.wav");
	Running   = setSoundId("bfsl-minifigfoots1.mp3");
	
	Jumping = setSoundId("button.wav", function (jumping, humanoid)
		humanoid.Jumping:Connect(function ()
			wait(0.1 + (math.random() / 10))
			jumping:Stop()
		end)
	end);
}

local function onSoundMounted(humanoid)
	if not humanoid:IsA("Humanoid") then
		return
	end
	
	local avatar = humanoid.Parent
	
	promiseChild(avatar, "HumanoidRootPart", function (rootPart)
		local fallingDown = createSound("FallingDown", "splat.wav", rootPart)
		humanoid.FallingDown:Connect(mountSoundToState(fallingDown))
		
		local freeFalling = createSound2("FreeFall", "12222200", rootPart)
		humanoid.FreeFalling:Connect(mountSoundToState(freeFalling))
		
		for soundName, soundAction in pairs(soundActions) do
			promiseChild(rootPart, soundName, soundAction, humanoid)
		end
		
		local mountClimbSound = coroutine.wrap(function ()
			local running = rootPart:WaitForChild("Running", 10)
			local climbing = avatar:WaitForChild("Climbing", 10)
			
			if not (running and climbing) then
				return
			end
			
			local function onClimbing(isClimbing)
				if not isClimbing then
					return
				end
				
				while climbing.Value do
					if not avatar:IsDescendantOf(workspace) then
						break
					end
					
					local state = humanoid:GetState()
					
					if state.Name == "Freefall" then
						if running.IsPaused then
							running:Resume()
						end
						
						if freeFalling.IsPlaying then
							freeFalling:Stop()
						end
					end
					
					RunService.Heartbeat:Wait()
				end
			end
			
			climbing.Changed:Connect(onClimbing)
		end)
		
		mountClimbSound()
	end)
end

for _,humanoid in pairs(CollectionService:GetTagged(soundTag)) do
	onSoundMounted(humanoid)
end

soundMounted:Connect(onSoundMounted)

----------------------------------------------------------------------------------------------------