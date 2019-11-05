local tool = script.Parent

local function onActivated()
	local char = tool.Parent
	if char then
		local humanoid = char:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
end

tool.Activated:Connect(onActivated)