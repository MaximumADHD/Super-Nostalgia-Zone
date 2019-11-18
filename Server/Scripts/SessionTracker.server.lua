local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")

local jobId = game.JobId
local placeId = game.PlaceId
local privateServerId = game.PrivateServerId

if jobId == "" or privateServerId ~= "" then
	return
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local closed = false

local function publishUpdate()
	local playerCount = #Players:GetPlayers()
	
	local serverInfo =
	{
		JobId = jobId;
		PlaceId = placeId;
		Players = playerCount;
	}
	
	if closed then
		serverInfo.Closed = true;
	end
	
	pcall(function ()
		MessagingService:PublishAsync("ServerData", serverInfo)
	end)
end

local function onGameClosing()
	closed = true
	publishUpdate()
end

game:BindToClose(onGameClosing)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

while #Players:GetPlayers() < 1 do
	wait(1)
end

while not closed do
	publishUpdate()
	wait(5)
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------