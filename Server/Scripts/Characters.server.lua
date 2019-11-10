local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local assetUtil = require(ReplicatedStorage:WaitForChild("AssetUtil"))
local itemData = ReplicatedStorage:WaitForChild("ItemData")
local hatData = require(itemData:WaitForChild("Hat"))

local playerDataGet = { Success = false }

pcall(function ()
	playerDataGet = require(ServerStorage:WaitForChild("PlayerDataStore"))
end)

if not playerDataGet.Success then
	warn("Failed to get PlayerData. Avatars will not be loaded.")
end

local playerDataStore = playerDataGet.DataStore
local limbs = {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}

local requestCharacter = Instance.new("RemoteEvent")
requestCharacter.Name = "RequestCharacter"
requestCharacter.Parent = ReplicatedStorage

local assets = ServerStorage:WaitForChild("CharacterAssets")

local hats = Instance.new("Folder")
hats.Name = "ServerHatCache"
hats.Parent = ServerStorage

local function preBufferHat(hatId)
	local hat = hats:FindFirstChild(hatId)
	
	if not hat then
		local success, import = assetUtil:SafeCall(InsertService, "LoadAsset", tonumber(hatId))
		
		if success then
			hat = import:FindFirstChildWhichIsA("Accoutrement")
			if hat then
				hat.Name = hatId
				hat.Parent = hats
			end
		end
	end
	
	return hat
end

local function safeDestroy(obj)
	spawn(function ()
		obj:Destroy()
	end)
end

local function onCharacterAdded(char)
	local player = Players:GetPlayerFromCharacter(char)
	
	local bodyColors = assets.BodyColors:Clone()
	CollectionService:AddTag(bodyColors, "RespectCharacterAsset")
	
	local graphic = assets.ShirtGraphic:Clone()
	
	local shirt = char:FindFirstChildWhichIsA("Shirt")
	if not shirt then
		shirt = assets.Shirt:Clone()
	end
	
	local pants = char:FindFirstChildWhichIsA("Pants")
	if not pants then
		pants = assets.Pants:Clone()
	end
	
	local faceId = 1104210678
	local tshirtId = 131792587
	
	local humanoid = char:WaitForChild("Humanoid")
	CollectionService:AddTag(humanoid, "Animator")
	CollectionService:AddTag(humanoid, "HumanoidSound")
	
	local function onDied()
		local fuse do
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			local torso = char:FindFirstChild("Torso")
			
			if rootPart and torso then
				fuse = Instance.new("WeldConstraint")
				fuse.Part0 = torso
				fuse.Part1 = rootPart
				fuse.Parent = rootPart
			end
		end
		
		for _,desc in pairs(char:GetDescendants()) do
			if desc:IsA("BasePart") then
				for _,joint in pairs(desc:GetJoints()) do
					if joint ~= fuse then
						joint:Destroy()
					end
				end
			end
		end
		
		wait(5)
		
		local player = game.Players:GetPlayerFromCharacter(char)
		
		if player then
			player:LoadCharacter()
		end
	end
	
	local function onDescendantAdded(desc)
		if desc:IsA("CharacterMesh") and not desc.Name:sub(1, 3) == "CL_" then
			safeDestroy(desc)
		elseif desc:IsA("Accoutrement") then
			-- Safe way to deter non-game accessories, since I name them by their AssetId
			if not tonumber(desc.Name) then 
				safeDestroy(desc)
			end
		elseif desc:IsA("SpecialMesh") and desc.Parent.Name == "Head" then
			if desc.Name ~= "HeadMesh" then
				wait()
				
				local override = Instance.new("SpecialMesh")
				override.Name = "HeadMesh"
				override.Scale = Vector3.new(1.25, 1.25, 1.25)
				override.Parent = desc.Parent
				
				safeDestroy(desc)
			end
		elseif desc:IsA("BodyColors") and desc ~= bodyColors and not CollectionService:HasTag(bodyColors, "RespectCharacterAsset") then
			safeDestroy(desc)
			bodyColors.Parent = nil
			wait()
			bodyColors.Parent = char
		end
	end
		
	for _,v in pairs(char:GetDescendants()) do
		onDescendantAdded(v)
	end
	
	char.DescendantAdded:Connect(onDescendantAdded)
	humanoid.Died:Connect(onDied)
	
	if player.UserId > 0 and playerDataStore then
		local playerData = playerDataStore:GetSaveData(player)
		local colorData = playerData:Get("BodyColors")

		if colorData then
			for _,limb in pairs(limbs) do
				local num = colorData[limb]
				if num then
					bodyColors[limb.."Color"] = BrickColor.new(num)
				end
			end
		end
		
		local loadout = playerData:Get("Loadout")

		if loadout then
			local shirtId = loadout.Shirt
			local pantsId = loadout.Pants

			if shirtId then
				shirt.ShirtTemplate = "rbxassetid://" .. shirtId
			end

			if pantsId then
				pants.PantsTemplate = "rbxassetid://" .. pantsId
			end
			
			faceId = loadout.Face or faceId

			spawn(function ()
				local hatId = loadout.Hat or 0

				if hatId > 0 then
					local hatSrc = preBufferHat(hatId)
					local hat = hatSrc:Clone()
					hat.Parent = char
				end
			end)
		end
		
		tshirtId = playerData:Get("TShirt") or tshirtId
	end
	
	if tshirtId > 0 then
		local success, img = assetUtil:RequestImage(tshirtId)
		
		if success and img then
			graphic.Graphic = img
			graphic.Parent = char
		end
	end
		
	bodyColors.Parent = char
	shirt.Parent = char
	pants.Parent = char
	
	local head = char:WaitForChild("Head")
	local face = head:WaitForChild("face")

	face.Texture = "rbxhttp://Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=420&ht=420&aid=" .. faceId
end

local function onRequestCharacter(player)
	if not player.Character then
		player:LoadCharacter()
	end
end

local function onPlayerAdded(player)
	player.CanLoadCharacterAppearance = false
	player.CharacterAdded:Connect(onCharacterAdded)
	
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

for _,v in pairs(Players:GetPlayers()) do
	onPlayerAdded(v)
end

Players.PlayerAdded:connect(onPlayerAdded)
requestCharacter.OnServerEvent:Connect(onRequestCharacter)