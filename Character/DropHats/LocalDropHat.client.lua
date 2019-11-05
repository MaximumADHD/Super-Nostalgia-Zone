local UserInputService = game:GetService("UserInputService")

local server = script.Parent
local dropHat = server:WaitForChild("DropHat")

local function onInputBegan(input, gameProcessed)
	if not gameProcessed then
		local keyCode = input.KeyCode.Name
		if keyCode == "Equals" or keyCode == "DPadDown" then
			dropHat:FireServer()
		end
	end
end

UserInputService.InputBegan:Connect(onInputBegan)