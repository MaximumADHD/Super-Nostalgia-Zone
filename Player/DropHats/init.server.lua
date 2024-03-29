local Players = game:GetService("Players")

local char = script.Parent
local torso = char:WaitForChild("HumanoidRootPart")

local humanoid = char:WaitForChild("Humanoid")
local hatPickup = script:WaitForChild("HatPickup")

local dropHat = script:WaitForChild("DropHat")

local function onDropHat(player)
	local myPlayer = Players:GetPlayerFromCharacter(char)
	assert(player == myPlayer, "Cannot drop hats unless it is your character.")
	
	local dropPos = torso.CFrame * CFrame.new(0, 5.4, -8)
	
	for _,hat in pairs(humanoid:GetAccessories()) do
		local handle = hat:FindFirstChild("Handle")
		
		if handle then
			local newHandle = handle:Clone()
			
			for _,joint in pairs(newHandle:GetJoints()) do
				joint:Destroy()
			end
			
			for _,child in pairs(newHandle:GetChildren()) do
				if child:IsA("JointInstance") then
					child:Destroy()
				end
			end
			
			newHandle.CFrame = dropPos
			newHandle.CanCollide = true
			newHandle.Parent = workspace
			
			handle:Destroy()
			hat.Parent = newHandle
			
			local pickup = hatPickup:Clone()
			pickup.Parent = newHandle
			pickup.Disabled = false
		end
	end
end

dropHat.OnServerEvent:Connect(onDropHat)
