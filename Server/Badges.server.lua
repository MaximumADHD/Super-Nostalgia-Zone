local ServerStorage = game:GetService("ServerStorage")
local BadgeService = game:GetService("BadgeService")
local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")

local usingLeaderboard = true

if ServerStorage:FindFirstChild("TrackCombatBadges") then
	usingLeaderboard = ServerStorage.TrackCombatBadges.Value
elseif ServerStorage:FindFirstChild("LoadLeaderboard") then
	usingLeaderboard = ServerStorage.LoadLeaderboard.Value
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local playerDataGet = require(ServerStorage:WaitForChild("PlayerDataStore"))

if not playerDataGet.Success then
	warn("Failed to load PlayerData, badges will not be awarded")
	return
end

local playerData = playerDataGet.DataStore

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local placeCount = 0

local function iterPageItems(pages)
	return coroutine.wrap(function ()
		local pageNum = 1
		while true do
			for _, item in ipairs(pages:GetCurrentPage()) do
				coroutine.yield(item, pageNum)
			end
			
			if pages.IsFinished then
				break
			end
			
			pages:AdvanceToNextPageAsync()
			pageNum = pageNum + 1
		end
	end)
end

for place in iterPageItems(AssetService:GetGamePlacesAsync()) do
	if not place.Name:lower():find("devtest") and not place.Name:find("Super Nostalgia Zone") then
		placeCount = placeCount + 1
	end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local badges =
{
	CombatInitiation	= 1020931358;
	Warrior				= 1020932933;
	Bloxxer				= 1021012898;
	Inviter				= 1021010468;
	Friendship			= 1021024465;
	Ambassador			= 1021056315;
}

local inviterBadgeStatus = {}
local lastWipeout = {}

local function giveBadge(player,badge)
	warn("AWARDING BADGE", badge, "TO", player)
	if not BadgeService:UserHasBadge(player.UserId,badge) then
		BadgeService:AwardBadge(player.UserId,badge)
	end
end

local function onHumanoidDied(humanoid, victim)
	local player do
		local char = humanoid.Parent
		if char then
			player = Players:GetPlayerFromCharacter(char)
		end
	end
	
	local myLastWipeout = lastWipeout[victim.Name] or 0
	local now = tick()
	
	if (now - myLastWipeout) > 5 then
		local creator = humanoid:FindFirstChild("creator")
		
		if creator then
			local killer = creator.Value
			
			if killer and killer.UserId > 0 and killer ~= player then
				local killerData = playerData:GetSaveData(killer)
				local knockOuts = killerData:Get("Knockouts") or 0
				
				knockOuts = knockOuts + 1
				killerData:Set("Knockouts",knockOuts)
				
				if knockOuts > 250 then
					local wipeOuts = killerData:Get("Wipeouts") or 0
					if wipeOuts < knockOuts then
						giveBadge(killer,badges.Bloxxer)
					end
				elseif knockOuts > 100 then
					giveBadge(killer,badges.Warrior)
				elseif knockOuts > 10 then
					giveBadge(killer,badges.CombatInitiation)
				end
			end
		end
		
		local myData = playerData:GetSaveData(victim)
		local wipeOuts = myData:Get("Wipeouts") or 0
		
		myData:Set("Wipeouts", wipeOuts + 1)
		lastWipeout[victim.Name] = now
	end
end

local function onCharacterAdded(char)
	local player = game.Players:GetPlayerFromCharacter(char)
	local humanoid = char:WaitForChild("Humanoid")
	
	humanoid.Died:Connect(function ()
		onHumanoidDied(humanoid,player)
	end)
end

local function handleSocialBadges(player)
	-- Set up our inviter status from scratch.
	inviterBadgeStatus[player.Name] = 
	{
		Counted = 0;
		Queried = {};
	}
	
	-- Check the status of other players, and see if we can give them the inviter badge.
	local myData = playerData:GetSaveData(player)
	
	for _,otherPlayer in pairs(Players:GetPlayers()) do
		if player ~= otherPlayer and player:IsFriendsWith(otherPlayer.UserId) then
			local theirName = otherPlayer.Name
			local theirStatus = inviterBadgeStatus[theirName]
			
			if theirStatus and not theirStatus.Queried[player.Name] then
				theirStatus.Queried[player.Name] = true
				theirStatus.Counted = theirStatus.Counted + 1
				if theirStatus.Counted >= 3 then
					giveBadge(otherPlayer,badges.Inviter)
				end
			end
			
			-- Also increment the friendship encounters for these two.
			
			local myFrEncs = myData:Get("FriendEncounters") or 0
			myFrEncs = myFrEncs + 1
			
			myData:Set("FriendEncounters",myFrEncs)
			
			if myFrEncs >= 10 then
				giveBadge(player,badges.Friendship)
			end
			
			local theirData = playerData:GetSaveData(otherPlayer)
			local theirFrEncs = theirData:Get("FriendEncounters") or 0
			
			theirFrEncs = theirFrEncs + 1
			theirData:Set("FriendEncounters",theirFrEncs)
			
			if theirFrEncs >= 10 then
				giveBadge(otherPlayer,badges.Friendship)
			end
		end
	end
end

local function onPlayerAdded(player)
	if player.UserId > 0 then
		-- Hook up combat badge listeners
		if usingLeaderboard then
			if player.Character and player.Character:IsDescendantOf(workspace) then
				onCharacterAdded(player.Character)
			end
			
			player.CharacterAdded:Connect(onCharacterAdded)
		end
		
		-- Handle social badges
		handleSocialBadges(player)
		
		-- Handle ambassador badge
		local myData = playerData:GetSaveData(player)
		local myPlaceVisits = myData:Get("PlacesVisited")
		
		if myPlaceVisits == nil then
			myPlaceVisits = 
			{
				Count = 0;
				Record = {};
			}
		end
		
		local placeId = tostring(game.PlaceId)
		
		if not myPlaceVisits.Record[placeId] then
			myPlaceVisits.Record[placeId] = true
			myPlaceVisits.Count = myPlaceVisits.Count + 1
		end
		
		if myPlaceVisits.Count >= placeCount then
			giveBadge(player, badges.Ambassador)
		end
		
		myData:Set("PlacesVisited", myPlaceVisits)
	end
end

for _,v in pairs(Players:GetPlayers()) do
	onPlayerAdded(v)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------