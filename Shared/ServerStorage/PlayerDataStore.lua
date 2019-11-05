--===============================================--
--==                    API                    ==--
--===============================================--
--[[
	
The module returns an object 'PlayerDataStore'
with the following methods:

PlayerDataStore:GetSaveData(Player player) -> returns SaveData
	Returns the SaveData structure for a given
	player who is currently in the server.
	Will yield until the player's data is actually
	ready before returning.

PlayerDataStore:GetSaveDataById(integer userId) -> returns SaveData
	Returns the SaveData structure for a player
	with a given userId, who may or may not
	currently be in the server.
	Will yield until the user's data is actually
	ready before returning.
	
PlayerDataStore:FlushAll()
	Saves all unsaved changes in all SaveData
	structures in the place at the time of calling.
	Will yield until all of the save calls have
	completed.
	
The SaveData structures have the following methods:

SaveData:Get(string key) -> returns stored value
	Gets the value associated with |key| in this
	player's stored data. The cached value for this
	server will be returned, so this call will always
	return immediately.
	
SaveData:Set(string key, variant value)
	Sets the cached value associated with |key| on
	this server. This cached value will be saved to
	the DataStore at some point in the future: either
	when the passive save runs, when the player leaves
	the server, or when you call Flush() on he SaveData,
	whichever happens first.
	The call returns immediately.

SaveData:Update((array of strings) keys, function updateFunction)
	Atomically update multiple keys of a SaveData
	at once, and update the results in the data store,
	ensuring that no data is lost. Will yield until the
	save to the data store has actually completed.
	EG, for an important developer product purchase:
	saveData:Update({'PurchaseCount', 'Money'}, function(oldPurchaseCount, oldMoney)
		if not oldPurchaseCount then oldPurchaseCount = 0 end
		if not oldMoney then oldMoney = 0 end
		oldMoney = oldMoney + developerProductAmount
		oldPurchaseCount = oldPurchaseCount + 1
		return oldPurchaseCount, oldMoney
	end)
	In general you should only be using this function to
	handle developer product purchases, as the data store
	throttling limit is quite low, and you will run into
	it if your users are hitting part of your functionality
	that uses this with a lot of requests.
	
]]--


--===============================================--
--==          Global Module Settings           ==--
--===============================================--

-- How long to keep cached data for a given player
-- before letting it be thrown away if there are
-- no other references to it in your code.
-- Note1: Even after the expiry time, as long as
-- there is Lua code in your project somewhere
-- holding onto a reference to the SaveData object
-- for a player, the cached data for that player
-- will be kept.
-- Note2: Data for a given play will be cached for
-- as long as that player is in the server whether
-- or not you actually have a reference to it. The
-- expiry time is only relevant for the data of
-- players who are not in the server.
local CACHE_EXPIRY_TIME = 60*1 --10 minutes

-- How often to save unsaved changes to a player's 
-- data store if it has not been manually Flush'd 
-- by calling the Flush method on their SaveData,
-- or Flush'd via the player leaving the place.
local PASSIVE_SAVE_FREQUENCY = 60*1 -- once every 1 minute

-- How accurately to clear cache entries / do passive
-- saves. That is, how often to check if those things
-- need to be done.
local PASSIVE_GRANULARITY = 5 -- check once every 5 seconds

-- Optional key serialization. This specifies how
-- a given key should be saved to or loaded from
-- the actual data store. If not specified in the
-- tables then the key will just be directly
-- passed to the DataStore:Get/Set/UpdateAsync
-- methods.
local SERIALIZE = {}
local DESERIALIZE = {}
-- Put your entries here --
         --vvvvv--

         --^^^^^--
----------------------------
-- EG:
-- SERIALIZE.ScoreObject = function(scoreObject)
--     return scoreObject.Value
-- end
-- DESERIALIZE.ScoreObject = function(value)
--     local object = Instance.new('IntValue')
--     object.Name = 'ScoreIntValue'
--     object.Value = value
--     return object
-- end
-- ...usage (Note, you would never actually want to do this with an 
--           IntValue object as shown, you could just be storing a straight 
--           number instead, and it wouldn't work very well because
--           if you just set the IntValue's value the PlayerDataStore
--           would not know that it had changed, and would not save the
--           change. You'd actually have to call Set(...) to make the
--           change save):
-- local PlayerDataStore = require(game.ServerStorage.PlayerDataStore)
-- local saveData = PlayerDataStore:GetSaveData(player)
-- local valueObject = saveData:Get('ScoreObject')
-- print(valueObject.Name, valueObject.Value) -> ScoreIntValue <value>
-- local newScoreObject = Instance.new('IntValue')
-- newScoreObject.Value = 4
-- -- Even though normally you cannot save objects to the data 
-- -- store, the custom serialize you provided handles it
-- saveData:Set('ScoreObject', newScoreObject)
-- saveData:Flush()


-- The name of the data store to use to store the 
-- player data.
local DATASTORE_NAME = '__SuP3R_n0sTa1Gi4_z0nE__'

-- Guarantee a save ASAP when a player leaves a server.
-- This ensures that if they go to another server of the 
-- same place the save will almost certainly have already
-- completed when they enter the new place. You can leave
-- this off to be lighter on the save quota if you are
-- not possibly storing very important stuff in the data
-- store right before a player leaves.
local SAVE_ON_LEAVE = true

-- Debug flag, for internal debugging
local DEBUG = false

-- Check if we are able to use DataStores.
if game.GameId < 1 then
	warn("Game is not connected to a universe, cannot load DataStores.")
	return { Success = false }
end

local success,errorMsg = pcall(function ()
	local DataStoreService = game:GetService("DataStoreService")
	wait()
	DataStoreService:GetGlobalDataStore()
end)

if not success then
	warn("DataStore is unavailable: " .. tostring(errorMsg))
	return { Success = false }
end

--===============================================--
--==             Utility Functions             ==--
--===============================================--
-- Deep copy a table without circular references
local function DeepCopy(tb)
	if type(tb) == 'table' then
		local new = {}
		for k, v in pairs(tb) do
			new[k] = DeepCopy(v)
		end
		return new
	else
		return tb
	end
end

-- Spawn a new thread and run it immedately up to
-- the first yield before returning
local function SpawnNow(func)
	local ev = Instance.new('BindableEvent')
	ev.Event:connect(func)
	ev:Fire()
end
	
--===============================================--
--==              SaveData Class               ==--
--===============================================--

-- Holds the cached saved data for a given player.
local SaveData = {}
function SaveData.new(playerDataStore, userId)
	local this = {}
	
	--===============================================--
	--==               Private Data                ==--
	--===============================================--	
	this.userId = userId
	this.lastSaved = 0
	
	-- Locked status, so that saves and updates cannot
	-- end up fighting over the same data
	this.locked = false
	this.unlocked = Instance.new('BindableEvent')
	
	-- The actual data for this SaveData structure 
	this.dataSet = nil
	
	-- Keys that have unsaved changes
	this.dirtyKeySet = {}
	
	-- keys that we "own", that is, ones we have
	-- written to or read from on this SaveData.
	this.ownedKeySet = {} 
	
	--===============================================--
	--==          Private Implementation           ==--
	--===============================================--
	local function ownKey(key)
		this.ownedKeySet[key] = true
	end
	local function dirtyKey(key)
		this.dirtyKeySet[key] = true
	end
	local function markAsTouched(key)
		ownKey(key)
		playerDataStore:markAsTouched(this)
	end
	local function markAsDirty(key)
		ownKey(key)
		dirtyKey(key)
		playerDataStore:markAsDirty(this)
	end
	
	-- Load in the data for the struct
	function this:makeReady(data)
		this.dataSet = data
		this.lastSaved = tick()
		playerDataStore:markAsTouched(this)
	end
	
	function this:waitForUnlocked()
		while this.locked do
			this.unlocked.Event:wait()
		end
	end
	function this:lock()
		this.locked = true
	end
	function this:unlock()
		this.locked = false
		this.unlocked:Fire()
	end
	
	--===============================================--
	--==                Public API                 ==--
	--===============================================--
	-- Getter and setter function to manipulate keys 
	-- for this player.
	function this:Get(key)
		if type(key) ~= 'string' then
			error("Bad argument #1 to SaveData::Get() (string expected)", 2)
		end
		if DEBUG then
			print("SaveData<"..this.userId..">::Get("..key..")")
		end
		markAsTouched(key)
		local value = this.dataSet[key]
		if value == nil and DESERIALIZE[key] then
			-- If there's no current value, and the key
			-- has serialization, then we should get the
			-- null deserialized state. 
			local v = DESERIALIZE[key](nil)
			-- Note: we don't markAsDirty here, that's 
			-- intentional, as we don't want to save
			-- if we don't have to, and we don't need
			-- to here, as Deserialize(key, nil) should
			-- return back the same thing every time.
			-- However, we still need cache the value,
			-- because deserialize(key, nil) might still
			-- be expensive or the caller might expect
			-- the same reference back each time. 
			this.dataSet[key] = v
			return v
		else
			return value
		end
	end
	-- Set(key, value, allowErase)
	-- Note: If allowErase is not set to true, then 
	-- the call will error on value = nil, this is
	-- to prevent you accidentally erasing data when
	-- you don't mean to. If you do want to erase,
	-- then call with allowErase = true
	function this:Set(key, value, allowErase)
		if type(key) ~= 'string' then
			error("Bad argument #1 to SaveData::Set() (string expected)", 2)
		end
		if value == nil and not allowErase then
			error("Attempt to SaveData::Set('"..key.."', nil) without allowErase = true", 2)
		end
		if DEBUG then
			print("SaveData<"..this.userId..">::Set("..key..", "..tostring(value)..")")
		end
		markAsDirty(key)
		this.dataSet[key] = value
	end
	
	-- For important atomic transactions, update data 
	-- store. For example, for any Developer Product
	-- based purchases you should use this to ensure
	-- that the changes are saved right away, and
	-- correctly.
	-- Note: Update() will automatically Flush any
	-- unsaved changes while doing the update.
	function this:Update(keyList, func)
		if type(keyList) ~= 'table' then
			error("Bad argument #1 to SaveData::Update() (table of keys expected)", 2)
		end
		if type(func) ~= 'function' then
			error("Bad argument #2 to SaveData::Update() (function expected)", 2)
		end
		if DEBUG then
			print("SaveData<"..this.userId..">::Update("..table.concat(keyList, ", ")..", "..tostring(func)..")")
		end
		playerDataStore:doUpdate(this, keyList, func)
	end
	
	-- Flush all unsaved changes out to the data 
	-- store for this player.
	-- Note: This call will yield and not return
	-- until the data has actually been saved if
	-- there were any unsaved changes.
	function this:Flush()
		if DEBUG then
			print("SaveData<"..this.userId..">::Flush()")
		end
		playerDataStore:doSave(this)
	end
	
	return this
end

	
--===============================================--
--==           PlayerDataStore Class           ==--
--===============================================--
-- A singleton that manages all of the player data
-- saving and loading in a place.
local PlayerDataStore = {}
function PlayerDataStore.new()
	local this = {}

	--===============================================--
	--==               Private Data                ==--
	--===============================================--
	
	-- The actual data store we are writing to
	local DataStoreService = game:GetService('DataStoreService')
	local mDataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
	
	-- The weak-reference to each player's data, so
	-- that as long as the place owner keeps a ref
	-- to the data we will have it in this cache, and
	-- won't reload a second copy.
	local mUserIdSaveDataCache = setmetatable({}, {__mode = 'v'}) -- {UserId -> SaveData}
	
	-- Strong-reference to recently touched data, to
	-- implement the cache expiry time.
	local mTouchedSaveDataCacheSet = {} -- {SaveData}
	
	-- Strong-reference to the data of players who are
	-- online, we always want to keep a reference to
	-- their data.
	local mOnlinePlayerSaveDataMap = {} -- {Player -> SaveData}
	
	-- Dirty save datas, that is, ones that have
	-- unsaved changes.
	local mDirtySaveDataSet = {} -- {SaveData}
	
	-- Players whose data is currently being requested
	local mOnRequestUserIdSet = {} -- {UserId}
	local mRequestCompleted = Instance.new('BindableEvent')
	
	-- Number of save functions still running
	-- used on server shutdown to know how long to keep the
	-- server alive for after the last player has left.
	local mSavingCount = 0
	
	--===============================================--
	--==          Private Implementation           ==--
	--===============================================--
	-- transform a userId into a data store key
	local function userIdToKey(userId)
		if script:FindFirstChild("DebugUserId") and game.JobId == "" then
			return "PlayerList$" .. script.DebugUserId.Value
		else
			return 'PlayerList$'..userId
		end
	end	
	
	function this:markAsTouched(saveData)
		if DEBUG then print("PlayerDataStore::markAsTouched("..saveData.userId..")") end
		mTouchedSaveDataCacheSet[saveData] = true
		saveData.lastTouched = tick()
		mUserIdSaveDataCache[saveData.userId] = saveData
	end	
	function this:markAsDirty(saveData)
		if DEBUG then print("PlayerDataStore::markAsDirty("..saveData.userId..")") end
		this:markAsTouched(saveData)
		mDirtySaveDataSet[saveData] = true
		mUserIdSaveDataCache[saveData.userId] = saveData
	end
	
	-- the initial data to record for a given userId
	local function initialData(userId)
		return {}
	end
	
	-- collect and clear out the dirty key set of a save data
	local function collectDataToSave(saveData)
		local toSave = {}
		local toErase = {}
		for key, _ in pairs(saveData.dirtyKeySet) do
			local value = saveData.dataSet[key]
			if value ~= nil then
				-- Get the value to be saved
				if SERIALIZE[key] then
					-- If there is a seralization function provided, then use
					-- that to serialize out the value into the data to be
					-- stored.
					toSave[key] = SERIALIZE[key](value)
				else
					-- If no serialiation is provided, still do at least a deep
					-- copy of the value, so that further changes to the SaveData
					-- after the save call will not interfear with the call if
					-- it takes multiple tries to update the DataStore data.
					toSave[key] = DeepCopy(value)				
				end
			else
				-- no value, add to the list of keys to erase
				table.insert(toErase, key)
			end
			-- Turn off the dirty flag for the key, we are working on saving it
			saveData.dirtyKeySet[key] = nil
		end	
		return toSave, toErase
	end
	
	-- Main saving functions that push out unsaved
	-- changes to the actual data store
	function this:doSave(saveData)
		if DEBUG then print("PlayerDataStore::doSave("..saveData.userId..") {") end
		-- update save time and dirty status in my
		-- listing even if there arn't any changes 
		-- to save.
		saveData.lastSaved = tick()
		mDirtySaveDataSet[saveData] = nil	
		
		-- are there any dirty keys?
		if next(saveData.dirtyKeySet) then
			-- cache the data to save
			local toSave, toErase = collectDataToSave(saveData)
			
			-- update the data with all the dirty keys
			saveData:waitForUnlocked()
			saveData:lock()
			mSavingCount = mSavingCount + 1
			
			local attempts = 0
			for i = 1,10 do
				local success = pcall(function ()
					mDataStore:UpdateAsync(userIdToKey(saveData.userId), function(oldData)
						-- Init the data if there is none yet
						if not oldData then
							oldData = initialData(saveData.userId)
						end
						if DEBUG then print("\tattempting save:") end
						
						-- For each dirty key to be saved, update it
						for key, data in pairs(toSave) do
							if DEBUG then print("\t\tsaving `"..key.."` = "..tostring(data)) end
							oldData[key] = data
						end
						
						-- For each key to erase, erase it
						for _, key in pairs(toErase) do
							if DEBUG then print("\t\tsaving `"..key.."` = nil [ERASING])") end
							oldData[key] = nil
						end
						
						-- Return back the updated data
						return oldData
					end)
				end)
				if success then
					break
				else
					attempts = attempts + 1
					warn("save failed, trying again...", attempts)
				end
			end
			if DEBUG then print("\t saved.") end
			mSavingCount = mSavingCount - 1
			saveData:unlock()
		elseif DEBUG then
			print("\tnothing to save")
		end
		if DEBUG then print("}") end
	end
	function this:doUpdate(saveData, keyList, updaterFunc)
		if DEBUG then print("PlayerDataStore::doUpdate("..saveData.userId..", {"..table.concat(keyList, ", ").."}, "..tostring(updaterFunc)..") {") end
		-- updates happen all at once, lock right away
		saveData:waitForUnlocked()
		saveData:lock()
		mSavingCount = mSavingCount + 1
		
		-- Unflag this SaveData as dirty
		saveData.lastSaved = tick()
		mDirtySaveDataSet[saveData] = nil
		
		-- turn the keyList into a key set as well
		-- also own all of the keys in it.
		local updateKeySet = {}
		for _, key in pairs(keyList) do
			saveData.ownedKeySet[key] = true
			updateKeySet[key] = true
		end
		
		-- gather the data to save currently in the saveData. There
		-- may be some or none.
		local toSave, toErase = collectDataToSave(saveData)
		
		-- do the actual update
		mDataStore:UpdateAsync(userIdToKey(saveData.userId), function(oldData)
			if DEBUG then print("\ttrying update:") end
			-- Init the data if there is none yet
			if not oldData then
				oldData = initialData(saveData.userId)
			end
			
			-- gather current values to pass to the the updater func
			local valueList = {}
			for i, key in pairs(keyList) do
				local value = saveData.dataSet[key]
				if value == nil and DESERIALIZE[key] then
					valueList[i] = DESERIALIZE[key](nil)
				else
					valueList[i] = value
				end
			end
			
			-- call the updaterFunc and get the results back
			local results = {updaterFunc(unpack(valueList, 1, #keyList))}
			
			-- Save the results to the data store and SaveData cache
			for i, result in pairs(results) do			
				local key = keyList[i]
				-- Serialize if needed, and save to the result for the data store
				if SERIALIZE[key] then
					local serialized = SERIALIZE[key](result)
					if DEBUG then print("\t\tsaving result: `"..key.."` = "..tostring(serialized).." [SERIALIZED]") end	
					oldData[key] = serialized
				else
					if DEBUG then print("\t\tsaving result: `"..key.."` = "..tostring(result)) end	
					oldData[key] = result
				end
				-- also save the result to the SaveData cache:
				saveData.dataSet[key] = result
			end
			
			-- Also while we're at it, save the dirty values to the data store
			-- but only if they weren't in the set that we just updated.
			for key, value in pairs(toSave) do
				-- Serialize if needed. 
				if not updateKeySet[key] then
					if DEBUG then print("\t\tsaving unsaved value: `"..key.."` = "..tostring(value)) end
					oldData[key] = value --(note, value is already serialized)
				end
			end
			for _, key in pairs(toErase) do
				if not updateKeySet[key] then
					if DEBUG then print("\t\tsaving unsaved value: `"..key.."` = nil [ERASING]") end
					oldData[key] = nil
				end
			end
			
			-- return the finalized result
			return oldData
		end)
		
		
		-- finish the save
		mSavingCount = mSavingCount - 1
		saveData:unlock()
		
		if DEBUG then print("}") end
	end
	
	-- Main method for loading in the data of a user
	-- or grabbing it from the cache if it is still
	-- "hot" (in the UserIdSaveDataCache but nowhere
	-- else)
	local function doLoad(userId)
		if DEBUG then print("PlayerDataStore::doLoad("..userId..") {") end
		local saveData;
		-- First see if it is in the cache
		saveData = mUserIdSaveDataCache[userId]
		if saveData then
			if DEBUG then print("\tRecord was already in cache") end
			-- touch it and return it
			this:markAsTouched(saveData)
			if DEBUG then print("}") end
			return saveData
		end
		-- Not on file, we need to load it in, are
		-- we already loading it though?
		if mOnRequestUserIdSet[userId] then
			if DEBUG then print("\tRecord already requested, wait for it...") end
			-- wait for the existing request to complete
			while true do
				saveData = mRequestCompleted.Event:wait()()
				if saveData.userId == userId then
					-- this IS the request we're looking for
					this:markAsTouched(saveData)
					if DEBUG then 
						print("\tRecord successfully retrieved by another thread")
						print("}") 
					end
					return saveData
				end
			end
		else
			if DEBUG then print("\tRequest record...") end
			-- Not on request, we need to do the load
			mOnRequestUserIdSet[userId] = true
			-- load the data
			local data = mDataStore:GetAsync(userIdToKey(userId)) or {}
			-- deserialize any data that needs to be deserialized
			for key, value in pairs(data) do
				if DESERIALIZE[key] then
					data[key] = DESERIALIZE[key](value)
				end
			end
			-- create te SaveData structure and initialize it
			saveData = SaveData.new(this, userId)
			saveData:makeReady(data)
			this:markAsTouched(saveData)
			-- unmark as loading
			mOnRequestUserIdSet[userId] = nil
			-- Pass to other waiters
			mRequestCompleted:Fire(function() return saveData end)
			if DEBUG then 
				print("\tRecord successfully retrieved from data store")
				print("}") 
			end
			return saveData
		end
	end
	
	-- Handle adding and removing strong-references to a player's
	-- data while they are in the server.
	local function HandlePlayer(player)
		if DEBUG then print("PlayerDataStore> Player "..player.userId.." Entered > Load Data") end
		local saveData = doLoad(player.userId)
		-- are the still in the game? If they are then
		-- add the strong-reference to the SaveData
		if player.Parent then
			mOnlinePlayerSaveDataMap[player] = saveData
		end 
	end
	Game.Players.PlayerAdded:connect(HandlePlayer)
	for _, player in pairs(Game.Players:GetChildren()) do
		if player:IsA('Player') then
			HandlePlayer(player)
		end
	end
	Game.Players.PlayerRemoving:connect(function(player)
		-- remove the strong-reference when they leave.
		local oldSaveData = mOnlinePlayerSaveDataMap[player]
		mOnlinePlayerSaveDataMap[player] = nil
		
		-- Do a save too if the flag is on
		if SAVE_ON_LEAVE and oldSaveData then 
			-- Note: We only need to do a save if the initial 
			-- load for that player actually completed yet. Cached
			-- versions from before the player entered are not a concern
			-- here as if there were a cache version the oldSaveData
			-- would exist, as the doLoad on player entered would
			-- have completed immediately.
			if DEBUG then print("PlayerDataStore> Player "..player.userId.." Left with data to save > Save Data") end
			this:doSave(oldSaveData)
		end
	end)
	
	-- when the game shuts down, save all data
	local RunService = game:GetService("RunService")
	
	game:BindToClose(function ()
		if DEBUG then print("PlayerDataStore> OnClose Shutdown\n\tFlushing...") end
		
		-- First, flush all unsaved changes at the point of shutdown
		this:FlushAll()
		
		if DEBUG then print("\tFlushed, additional wait...",os.time()) end
		
		-- Then wait for random saves that might still be running
		-- for some reason to complete as well
		if not RunService:IsStudio() then
			while mSavingCount > 0 do
				wait()
			end
		end
		
		if DEBUG then print("\tShutdown completed normally.",os.time()) end
	end)
	
	-- Cleanup of cache entries that have timed out (not been touched
	-- in any way for more than CACHE_EXPIRY_TIME)
	local function removeTimedOutCacheEntries()
		local now = tick()
		for saveData, _ in pairs(mTouchedSaveDataCacheSet) do
			if (now - saveData.lastTouched) > CACHE_EXPIRY_TIME then
				-- does it have unsaved changes still somehow?
				if mDirtySaveDataSet[saveData] then
					if DEBUG then print(">> Cache expired for: "..saveData.userId..", has unsaved changes, wait.") end
					-- Spawn off a save and don't remove it, it needs to save
					SpawnNow(function() this:doSave(saveData) end)
				else
					if DEBUG then print(">> Cache expired for: "..saveData.userId..", removing.") end
					-- It is not needed, uncache it
					mTouchedSaveDataCacheSet[saveData] = nil
				end
			end 
		end
	end
	
	-- Passive saving task, save entries with unsaved changes that have
	-- not been saved for more than PASSIVE_SAVE_FREQUENCY.
	local function passiveSaveUnsavedChanges()
		local now = tick()
		for saveData, _ in pairs(mDirtySaveDataSet) do
			if (now - saveData.lastSaved) > PASSIVE_SAVE_FREQUENCY then
				if DEBUG then print("PlayerDataStore>> Passive save for: "..saveData.userId) end
				SpawnNow(function()
					this:doSave(saveData)
				end)
			end
		end
	end
	
	-- Main save / cache handling daemon
	Spawn(function()
		while true do
			removeTimedOutCacheEntries()
			passiveSaveUnsavedChanges()
			wait(PASSIVE_GRANULARITY)
		end
	end)
	
	--===============================================--
	--==                Public API                 ==--
	--===============================================--
	
	-- Get the data for a player online in the place
	function this:GetSaveData(player)
		if not player or not player:IsA('Player') then
			error("Bad argument #1 to PlayerDataStore::GetSaveData(), Player expected", 2)
		end
		return doLoad(player.userId)
	end
	
	-- Get the data for a player by userId, they may
	-- or may not be currently online in the place.
	function this:GetSaveDataById(userId)
		if type(userId) ~= 'number' then
			error("Bad argument #1 to PlayerDataStore::GetSaveDataById(), userId expected", 2)
		end
		return doLoad(userId)
	end
	
	function this:IsEmulating()
		return (script:FindFirstChild("DebugUserId") and game.JobId == "")
	end
	
	-- Save out all unsaved changes at the time of 
	-- calling.
	-- Note: This call yields until all the unsaved 
	-- changes have been saved out.
	function this:FlushAll()
		local savesRunning = 0
		local complete = Instance.new('BindableEvent')
		this.FlushingAll = true
		
		-- Call save on all of the dirty entries
		for saveData, _ in pairs(mDirtySaveDataSet) do
			SpawnNow(function()
				savesRunning = savesRunning + 1
				this:doSave(saveData)
				savesRunning = savesRunning - 1
				if savesRunning <= 0 then
					complete:Fire()
				end
			end)
		end
		
		-- wait for completion
		if savesRunning > 0 then
			complete.Event:wait()
			this.FlushingAll = false
		end
	end
	
	return this
end

return 
{
	Success = true;
	DataStore = PlayerDataStore.new();
}