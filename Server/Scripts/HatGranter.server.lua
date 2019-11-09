local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local itemData = ReplicatedStorage:WaitForChild("ItemData")
local hatData = require(itemData:WaitForChild("Hat"))

local grantHatToUser = Instance.new("BindableEvent")
grantHatToUser.Name = "GrantHatToUser"
grantHatToUser.Parent = ServerStorage

local authTable = 
{
	["1073469644"] = { ["96"]  = true  };
	
	["1081616136"] = { ["97"]  = true, 
	                   ["98"]  = true  };
	
	["2421080323"] = { ["100"] = true  };
	
	["2471146032"] = { ["101"] = true,
	                   ["102"] = true  };
}

local playerDataGet = { Success = false }

pcall(function ()
	playerDataGet = require(ServerStorage:WaitForChild("PlayerDataStore"))
end)

if not playerDataGet.Success then
	warn("Failed to load PlayerData. HatGranter will not work.")
end

local playerData = playerDataGet.DataStore

local function onGrantHat(player,hatId)
	local userId = player.UserId
	
	if userId > 0 then
		local auth = authTable[tostring(game.PlaceId)]
		
		if auth then
			local canGiveHat = auth[tostring(hatId)]
			
			if canGiveHat and playerData then
				local hatInfo = hatData[hatId]
				local hatAsset = hatInfo.AssetId
				
				local myData = playerData:GetSaveData(player)
				local items = myData:Get("Items")
				local loadout = myData:Get("Loadout")
				
				local id = tostring(hatAsset)
				
				if not items.Hat[id] then
					items.Hat[id] = true
					myData:Set("Items", items)
				end
				
				loadout.Hat = hatAsset
				myData:Set("Loadout", loadout)
			end
		end
	end
end

grantHatToUser.Event:Connect(onGrantHat)