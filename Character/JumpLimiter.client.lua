local char = script.Parent
local humanoid = char:WaitForChild("Humanoid")

local function onStateChanged(old,new)
	if old == Enum.HumanoidStateType.Freefall and new == Enum.HumanoidStateType.Landed then
		humanoid:SetStateEnabled("Jumping",false)
		wait(0.5)
		humanoid:SetStateEnabled("Jumping",true)
	end
end

humanoid.StateChanged:Connect(onStateChanged)
