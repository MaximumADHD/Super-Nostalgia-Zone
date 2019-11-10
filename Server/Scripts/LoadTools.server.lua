local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")
local Players = game:GetService("Players")

local tools = ServerStorage:WaitForChild("StandardTools")
local loadTools = ServerStorage:FindFirstChild("LoadTools")

if loadTools then
	for toolName in loadTools.Value:gmatch("[^;]+") do
		local tool = tools:WaitForChild(toolName)
		tool:Clone().Parent = StarterPack
		
		for _,player in pairs(Players:GetPlayers()) do
			local backpack = player:FindFirstChildOfClass("Backpack")
			
			if backpack and not backpack:FindFirstChild(tool.Name) then
				tool:Clone().Parent = backpack
			end
		end
	end
end