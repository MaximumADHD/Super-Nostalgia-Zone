local Debris = game:GetService("Debris")

local char = script.Parent
local humanoid = char:WaitForChild("Humanoid")
local head = char:WaitForChild("Head")

local function onStateChanged(old,new)
	if new.Name == "Landed" then
		local velocity = humanoid.Torso.Velocity
		local power = (-velocity.Y * workspace.Gravity) / 2
		
		local force = Instance.new("BodyForce")
		force.Name = "Bounce"
		force.Force = Vector3.new(0,power,0)
		force.Parent = head
		
		Debris:AddItem(force, 1/30)
	end
end

humanoid.StateChanged:connect(onStateChanged)