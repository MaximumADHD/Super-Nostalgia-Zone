local self = script.Parent
local remote = self:WaitForChild("Gateway")

local tool = self.Parent
tool.ManualActivationOnly = true

local keyEvent = Instance.new("BindableEvent")
keyEvent.Name = "KeyEvent"
keyEvent.Parent = tool

local function onGatewayReceive(sendingPlayer, request, ...)
	local char = tool.Parent
	
	if char and char:IsA("Model") then
		local humanoid = char:FindFirstChild("Humanoid")
		
		if humanoid then
			local player = game.Players:GetPlayerFromCharacter(char)
			assert(sendingPlayer == player)
			
			if request == "SetActive" then
				local down, target = ...
				assert(typeof(target) == "CFrame", "Expected CFrame")
				
				humanoid.TargetPoint = target.Position
				
				if humanoid.Health > 0 and tool:IsDescendantOf(char) then
					if down then
						tool:Activate()
					else
						tool:Deactivate()
					end
				end
			elseif request == "SetTarget" then
				local target = ...
				assert(typeof(target) == "CFrame", "Expected CFrame")
				humanoid.TargetPoint = target.Position
			elseif request == "KeyEvent" then
				local key, down = ...

				assert(typeof(key) == "string", "Expected string")
				assert(typeof(down) == "boolean", "Expected boolean")
				
				keyEvent:Fire(key, down)
			end
		end
	end
end

remote.OnServerEvent:Connect(onGatewayReceive)