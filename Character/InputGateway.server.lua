local ServerStorage = game:GetService("ServerStorage")
local inputGateway = ServerStorage:WaitForChild("InputGateway")
local char = script.Parent

local function onChildAdded(child)
	if child:IsA("Tool") and not child:FindFirstChild("InputGateway") then
		wait(.1)
		local gateway = inputGateway:Clone()
		gateway.Parent = child
	end
end

local tool = char:FindFirstChildWhichIsA("Tool")
if tool then
	onChildAdded(tool)
end

char.ChildAdded:Connect(onChildAdded)