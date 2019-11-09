local Chat = game:GetService("Chat")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local mSafeChatTree = ReplicatedStorage:WaitForChild("SafeChat")
local safeChatTree = require(mSafeChatTree)

local chatRemote = Instance.new("RemoteEvent")
chatRemote.Name = "ChatRemote"
chatRemote.Parent = ReplicatedStorage

local filterCache = {}
local maxChatLength = 128

local function onServerEvent(player, message)
	assert(typeof(message) == "string", "bad input passed")
	assert(#message <= maxChatLength, "Chat message was too long!")
	
	if message:sub(1,3) == "/sc" then
		local tree = safeChatTree
		
		for t in message:gmatch("%d+") do
			local i = tonumber(t) + 1
			tree = tree.Branches[i]
			
			if not tree then
				break
			end
		end 
		
		message = tree and tree.Label or " "
	end
	
	local asciiMessage = ""
	
	for p, c in utf8.codes(message) do
		if c > 0x1F600 then
			asciiMessage = asciiMessage .. "??"
		else
			asciiMessage = asciiMessage .. utf8.char(c)
		end
	end
	
	message = asciiMessage
	
	local userId = player.UserId
	if not filterCache[userId] then
		filterCache[userId] = {}
	end
	
	local filterResult = filterCache[userId][message]
	
	if not filterResult then
		filterResult = TextService:FilterStringAsync(message,userId)
		filterCache[userId][message] = filterResult
	end
	
	for _,receiver in pairs(Players:GetPlayers()) do
		spawn(function ()
			pcall(function ()
				local filtered = filterResult:GetChatForUserAsync(receiver.UserId)
				chatRemote:FireClient(receiver, player, filtered, filtered ~= message)
			end)
		end)
	end
end

chatRemote.OnServerEvent:Connect(onServerEvent)