local char = script.Parent
local humanoid = char:WaitForChild("Humanoid")

local function onStateChanged(old,new)
	if new == Enum.HumanoidStateType.RunningNoPhysics then
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	elseif new == Enum.HumanoidStateType.FallingDown then
		humanoid:ChangeState("Ragdoll")
		
		while wait(0.5) do
			if humanoid.RootPart then
				local velocity = humanoid.RootPart.Velocity
				
				if velocity.Magnitude < 0.1 then
					wait(2)
					humanoid:ChangeState("GettingUp")
					break
				end
			else
				break
			end
		end
	end
end

humanoid.StateChanged:Connect(onStateChanged)