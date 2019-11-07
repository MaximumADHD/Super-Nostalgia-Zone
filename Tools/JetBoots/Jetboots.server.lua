print("Jet Boots loaded")

bin = script.Parent

walking = false
reloadtime = 0

local thrust = Instance.new("BodyVelocity")
local velocity = 0
local max_velocity = 30
local flight_time = 6
local localPlayer



function onStart()
	local char = localPlayer.Character
	local head = char:WaitForChild("Head")
	
	print("start walking")
	walking = true
	reloadtime = 8.0
	
	thrust.Parent = head
	
	thrust.velocity = Vector3.new(0,velocity,0)
	thrust.maxForce = Vector3.new(0,4e+003,0) 
	
	local sound = head:findFirstChild("JetbootSound")
	if sound == nil then 
		sound = Instance.new("Sound")
		sound.Name = "JetbootSound"
		sound.SoundId = "rbxasset://sounds\\Rocket whoosh 01.wav"
		sound.Looped = true
		sound.Parent = head
	end
	sound:play()

end

function onDeactivated()
	print("stop walking")
	local char = localPlayer.Character
	local head = char:WaitForChild("Head")
	walking = false
	thrust.Parent = nil
	local sound = head:findFirstChild("JetbootSound")
	if sound ~= nil then sound:stop() end
	bin.Enabled = false
	wait(reloadtime)
	bin.Enabled = true
	reloadtime = 0
end

function onActivated()
	local char = bin.Parent
	localPlayer = game.Players:GetPlayerFromCharacter(char)
	if not localPlayer then return end
	if reloadtime > 0 then return end
	if walking then return end
	
	onStart()

	local time = 0
	while walking do
		wait(.2)
		time = time + .2
		velocity = (max_velocity * (time / flight_time)) + 3 
		thrust.velocity = Vector3.new(0,velocity,0)

		if time > flight_time then onDeactivated() end
	end
end

bin.Activated:Connect(onActivated)
bin.Deactivated:Connect(onDeactivated)