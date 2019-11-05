local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")
local Players = game:GetService("Players")

local standardTools = ServerStorage:WaitForChild("StandardTools")
local loadTools = ServerStorage:FindFirstChild("LoadTools")

if loadTools then
	for toolName in loadTools.Value:gmatch("[^;]+") do
		local tool = standardTools:WaitForChild(toolName)
		tool:Clone().Parent = StarterPack
		
		for _,v in pairs(Players:GetPlayers()) do
			if v:FindFirstChild("Backpack") and not v:FindFirstChild(tool.Name) then
				tool:Clone().Parent = v.Backpack
			end
		end
	end
end