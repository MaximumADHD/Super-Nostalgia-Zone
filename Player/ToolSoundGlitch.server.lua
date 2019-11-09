-- This replicates an old sound bug that used to occur with tools back then.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local char = script.Parent
local torso = char:WaitForChild("Torso")
local marked = {}

local function processHandle(handle)
	for _,child in pairs(handle:GetChildren()) do
		if child:IsA("Sound") then
			if not marked[child.SoundId] then
				marked[child.SoundId] = true
			else
				local replica = child:Clone()
				replica.Name = "ToolSoundGlitch"
				replica.MaxDistance = 0
				replica.Parent = torso
				
				CollectionService:AddTag(replica, "ToolSoundGlitch")
				replica:Play()
				
				replica.Ended:connect(function ()
					Debris:AddItem(replica, 1)
				end)
			end
		end
	end	
end

local function onChild(child)
	if child:IsA("Tool") then
		local handle = child:FindFirstChild("Handle")
		
		if handle then
			processHandle(handle)
		end
	end
end

char.ChildAdded:connect(onChild)
char.ChildRemoved:connect(onChild)