local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerStorage = game:GetService("ServerStorage")

local loadBuildTools = ServerStorage:FindFirstChild("LoadBuildTools")
if not (loadBuildTools and loadBuildTools.Value) then
	return
end

local looseBranches = ServerStorage:FindFirstChild("LooseBranches")

if looseBranches and looseBranches:IsA("BoolValue") then
	looseBranches = looseBranches.Value
else
	looseBranches = false
end

local toolList = loadBuildTools.Value
if toolList == true then -- If it's a BoolValue, load all of them.
	toolList = "GameTool;Clone;Delete"
end

local DraggerService = Instance.new("Folder")
DraggerService.Name = "DraggerService"
DraggerService.Parent = ReplicatedStorage

local draggerGateway = Instance.new("RemoteFunction")
draggerGateway.Name = "DraggerGateway"
draggerGateway.Parent = DraggerService

local submitUpdate = Instance.new("RemoteEvent")
submitUpdate.Name = "SubmitUpdate"
submitUpdate.Parent = DraggerService

local draggerScript = script:WaitForChild("Dragger")

local activeKeys = {}
local debounce = {}

local weakTable = { __mode = 'k' }

local playerToKey = setmetatable({}, weakTable)
local partToKey = setmetatable({}, weakTable)

local SIMULATE_TAG = "SimulateAfterDrag"
local NO_BREAK_TAG = "GorillaGlue"

local function assertClass(obj, class)
	assert(obj)
	assert(typeof(obj) == "Instance")
	assert(obj:IsA(class))
end

local function canGiveKey(player, part)
	if part.Locked then
		return false
	end

	local playerHasKey = playerToKey[player]
	local partHasKey = partToKey[part]

	if playerHasKey or partHasKey then
		return false
	end

	return true
end

local function claimAssembly(player, part)
	if part:CanSetNetworkOwnership() then
		part:SetNetworkOwner(player)
	end
end

local function removePartKey(key)
	local data = activeKeys[key]

	if data then
		local player = data.Player
		local part = data.Part

		if player then
			playerToKey[player] = nil
		end
		
		if part then
			part:MakeJoints()
			part.Anchored = data.Anchored

			claimAssembly(player, part)
			partToKey[part] = nil
		end
		
		activeKeys[key] = nil
	end
end

function draggerGateway.OnServerInvoke(player, request, ...)
	if request == "GetKey" then
		local part, asClone = ...
		assertClass(part, "BasePart")
		
		if asClone then
			local newPart = part:Clone()
			newPart.Parent = workspace
			
			newPart:BreakJoints()
			newPart.CFrame = CFrame.new(part.Position + Vector3.new(0, part.Size.Y, 0))
			
			local copySound = Instance.new("Sound")
			copySound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			copySound.PlayOnRemove = true
			copySound.Parent = newPart
			
			wait()
			
			part = newPart
			copySound:Destroy()
		end
		
		if canGiveKey(player, part) then
			local key = HttpService:GenerateGUID(false)
			claimAssembly(player, part)
			
			playerToKey[player] = key
			partToKey[part] = key
			
			local anchored = part.Anchored
			part.Anchored = true
			part:BreakJoints()
			
			activeKeys[key] =
			{
				Player = player;
				Part = part;
				Anchored = anchored;
			}
			
			return true, key, part
		else
			return false
		end
	elseif request == "ClearKey" then
		local key = ...
		
		if not key then
			key = playerToKey[player]
		end
		
		if key then
			local data = activeKeys[key]
			if data then
				local owner = data.Player
				if player == owner then
					removePartKey(key)
				end
			end
		end
	elseif request == "RequestDelete" then
		if not debounce[player] then
			local part = ...
			assertClass(part, "BasePart")
			
			debounce[player] = true
			
			if canGiveKey(player, part) then
				local e = Instance.new("Explosion")
				e.BlastPressure = 0
				e.Position = part.Position
				e.Parent = workspace
				
				local s = Instance.new("Sound")
				s.SoundId = "rbxasset://sounds/collide.wav"
				s.Volume = 1
				s.PlayOnRemove = true
				s.Parent = part

				part:Destroy()
			end
			
			wait(.1)
			debounce[player] = nil
		end
	end
end

local function onChildAdded(child)
	if child:IsA("Backpack") then
		for draggerTool in toolList:gmatch("[^;]+") do
			local tool = Instance.new("Tool")
			tool.Name = draggerTool
			tool.RequiresHandle = false
			tool.CanBeDropped = false
			
			local newDragger = draggerScript:Clone()
			newDragger.Parent = tool
			newDragger.Disabled = false
			
			tool.Parent = child
		end
	end
end

local function onPlayerAdded(player)
	for _, v in pairs(player:GetChildren()) do
		onChildAdded(v)
	end
	
	player.ChildAdded:Connect(onChildAdded)
end

local function onPlayerRemoved(player)
	local key = playerToKey[player]
	if key then
		removePartKey(key)
	end
end

local function onSubmitUpdate(player, key, cframe)
	local keyData = activeKeys[key]
	if keyData then
		local owner = keyData.Player
		if owner == player then
			local part = keyData.Part
			if part and part:IsDescendantOf(workspace) then
				part:BreakJoints()
				part.CFrame = cframe
			end
		end
	end
end

for _, player in pairs(game.Players:GetPlayers()) do
	onPlayerAdded(player)
end

submitUpdate.OnServerEvent:Connect(onSubmitUpdate)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoved)