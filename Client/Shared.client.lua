local TARGET = script.Name

do
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local client = ReplicatedStorage:WaitForChild("Client")
	local targetScript = client:WaitForChild(TARGET)
	local activation = require(targetScript)
	activation(script)
end