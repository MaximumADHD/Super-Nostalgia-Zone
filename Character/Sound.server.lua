-- util

function waitForChild(parent, childName)
	local child = parent:findFirstChild(childName)
	if child then return child end
	while true do
		child = parent.ChildAdded:wait()
		if child.Name==childName then return child end
	end
end

function newSound(id)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.archivable = false
	sound.Parent = script.Parent.Head
	return sound
end

-- declarations

local sDied = newSound("rbxasset://sounds/uuhhh.wav")
local sFallingDown = newSound("rbxasset://sounds/splat.wav")
local sFreeFalling = newSound("rbxasset://sounds/swoosh.wav")
local sGettingUp = newSound("rbxasset://sounds/hit.wav")
local sJumping = newSound("rbxasset://sounds/button.wav")
local sRunning = newSound("rbxasset://sounds/bfsl-minifigfoots1.mp3")
sRunning.Looped = true

local Figure = script.Parent
local Head = waitForChild(Figure, "Head")
local Humanoid = waitForChild(Figure, "Humanoid")
--local Climbing = Figure:WaitForChild("Climbing")

-- functions

function onDied()
	sDied:Play()
end

function onJumping()
	sJumping:Play()
	wait(0.2)
	sJumping:Stop()
end

function onState(state, sound)
	sound.TimePosition = 0
	sound.Playing = state
end

function onRunning(speed)
	sRunning.Playing = (speed>0.1)
end

-- connect up

Humanoid.Died:connect(onDied)
Humanoid.Running:connect(onRunning)
Humanoid.Jumping:connect(onJumping)
Humanoid.GettingUp:connect(function(state) onState(state, sGettingUp) end)
Humanoid.FreeFalling:connect(function(state) 
	--if not Climbing.Value then
		onState(state, sFreeFalling) 
	--end
end)

Humanoid.FallingDown:connect(function(state) onState(state, sFallingDown) end)
