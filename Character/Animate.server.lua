local Players = game:GetService("Players")

local character = script.Parent
local player = Players:GetPlayerFromCharacter(character)

local climbing = Instance.new("BoolValue")
climbing.Name = "Climbing"
climbing.Parent = character

local setValue = Instance.new("RemoteEvent")
setValue.Name = "SetValue"
setValue.Parent = climbing

local function onSetValue(requester, value)
	if requester ~= player then
		return
	end
	
	if typeof(value) ~= "boolean" then
		return
	end
	
	climbing.Value = value
end

setValue.OnServerEvent:Connect(onSetValue)