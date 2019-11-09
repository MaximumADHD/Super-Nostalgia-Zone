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
local playerToKey = {}
local partToKey = {}
local debounce = {}

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
	if playerHasKey then
		return false
	end
	local partHasKey = partToKey[part]
	if partHasKey then
		return false
	end
	return true
end

local function claimAssembly(player, part)
	if part:CanSetNetworkOwnership() then
		part:SetNetworkOwner(player)
	end
end

local function validJointsOf(part)
	return coroutine.wrap(function ()
		for _,joint in pairs(part:GetJoints()) do
			if not CollectionService:HasTag(joint, NO_BREAK_TAG) then
				coroutine.yield(joint)
			end
		end
	end)
end

local function breakJoints(part)
	for joint in validJointsOf(part) do
		if not CollectionService:HasTag(joint, NO_BREAK_TAG) then
			joint:Destroy()
		end
	end	
end

local function makeJoints(part)
	-- Connect this part to a nearby surface
	workspace:JoinToOutsiders({part}, "Surface")
end

local function removePartKey(key)
	local data = activeKeys[key]
	if data then
		local player = data.Player
		if player then
			playerToKey[player] = nil
		end
		
		local part = data.Part
		
		if part then
			makeJoints(part)
			
			if CollectionService:HasTag(part, SIMULATE_TAG) then
				data.Anchored = false
				CollectionService:RemoveTag(part, SIMULATE_TAG)
			end
			
			part.Anchored = data.Anchored
			claimAssembly(player, part)
			
			partToKey[part] = nil
		end
		
		activeKeys[key] = nil
	end
end

local function restoreJointUpstream(part)
	local collectedParts = {}
	
	if part and CollectionService:HasTag(part, SIMULATE_TAG) then
		CollectionService:RemoveTag(part, SIMULATE_TAG)
		part.Anchored = false
		
		makeJoints(part)
		
		for joint in validJointsOf(part) do
			local part0 = joint.Part0
			local part1 = joint.Part1
			
			if part0 and part ~= part0 then
				collectedParts[part0] = true
				restoreJointUpstream(part0)
			end
			
			if part1 and part ~= part1 then
				collectedParts[part1] = true
				restoreJointUpstream(part1)
			end
		end
	end
	
	return collectedParts
end

local function collapseJointUpstream(part)
	if part and not (part.Locked or CollectionService:HasTag(part, SIMULATE_TAG)) then
		CollectionService:AddTag(part, SIMULATE_TAG)
		part.Anchored = true
		
		for joint in validJointsOf(part) do
			local part0 = joint.Part0
			local part1 = joint.Part1
			
			if part0 and part ~= part0 then
				collapseJointUpstream(part0)
			end
			
			if part1 and part ~= part1 then
				collapseJointUpstream(part1)
			end
		end
		
		breakJoints(part)
	end
end

function draggerGateway.OnServerInvoke(player, request, ...)
	if request == "GetKey" then
		local part, asClone = ...
		assertClass(part, "BasePart")
		
		if asClone then
			local newPart = part:Clone()
			newPart.Parent = workspace
			
			breakJoints(newPart)
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
			
			local collected = restoreJointUpstream(part)
			
			local anchored = part.Anchored
			part.Anchored = true
			breakJoints(part)
			
			for otherPart in pairs(collected) do
				if otherPart:IsGrounded() then
					collapseJointUpstream(otherPart)
				end
			end
			
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
				
				local connectedParts = restoreJointUpstream(part)
				part:Destroy()
				
				for otherPart in pairs(connectedParts) do
					if otherPart:IsGrounded() then
						collapseJointUpstream(otherPart)
					end
				end
			end
			
			wait(.1)
			debounce[player] = false
		end
	end
end

local function onChildAdded(child)
	if child:IsA("Backpack") then
		for draggerTool in toolList:gmatch("[^;]+") do
			local tool = Instance.new("Tool")
			tool.Name = draggerTool
			tool.RequiresHandle = false
			
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
				breakJoints(part)
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

-- Garbage Collection

while wait(5) do
	for part, key in pairs(partToKey) do
		if not part:IsDescendantOf(workspace) then
			removePartKey(key)
		end
	end
end