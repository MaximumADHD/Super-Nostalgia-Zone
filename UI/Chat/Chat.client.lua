--------------------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------------------

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local chat = script.Parent
local util = chat:WaitForChild("Utility")

local chatBar = chat:WaitForChild("ChatBar")
local chatOutput = chat:WaitForChild("ChatOutput")
local focusBackdrop = chatBar:WaitForChild("FocusBackdrop")
local mainBackdrop = chat:WaitForChild("MainBackdrop")
local messageTemplate = util:WaitForChild("MessageTemplate")

local TextChannels = TextChatService:WaitForChild("TextChannels")
local LinkedList = require(util:WaitForChild("LinkedList"))
local SafeChat = require(ReplicatedStorage.SafeChat)

--------------------------------------------------------------------------------------------------------------------------------------
-- Player Colors
--------------------------------------------------------------------------------------------------------------------------------------

local PLAYER_COLORS = {
	[0] = Color3.fromRGB(173,  35,  35); -- red
	[1] = Color3.fromRGB( 42,  75, 215); -- blue
	[2] = Color3.fromRGB( 29, 105,  20); -- green
	[3] = Color3.fromRGB(129,  38, 192); -- purple
	[4] = Color3.fromRGB(255, 146,  51); -- orange
	[5] = Color3.fromRGB(255, 238,  51); -- yellow
	[6] = Color3.fromRGB(255, 205, 243); -- pink
	[7] = Color3.fromRGB(233, 222, 187); -- tan
}

local function computePlayerColor(player)
	if player.Team then
		return player.TeamColor.Color
	else
		local pName = player.Name
		local length = #pName
		
		local oddShift = (1 - (length % 2))
		local value = 0
		
		for i = 1, length do
			local char = pName:sub(i, i):byte()
			local rev = (length - i) + oddShift
			
			if (rev % 4) >= 2 then
				value = value - char
			else
				value = value + char	
			end 
		end
		
		return PLAYER_COLORS[value % 8]
	end
end

--------------------------------------------------------------------------------------------
-- Chat Input
--------------------------------------------------------------------------------------------

local function beginChatting()
	focusBackdrop.Visible = true
	mainBackdrop.BackgroundColor3 = Color3.new(1, 1, 1)

	if not chatBar:IsFocused() then
		chatBar.TextTransparency = 1
		chatBar:CaptureFocus()

		wait()

		chatBar.Text = ""
		chatBar.TextTransparency = 0
	end
end

local function onInputBegan(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.Slash then
			beginChatting()
		end
	end
end

local function onChatFocusLost(enterPressed)
	local msg: string = chatBar.Text
	mainBackdrop.BackgroundColor3 = focusBackdrop.BackgroundColor3
	focusBackdrop.Visible = false
	chatBar.Text = ""

	if enterPressed and #msg > 0 then
		if #msg > 128 then
			msg = msg:sub(1, 125) .. "..."
		end

		local player = Players.LocalPlayer
		local channel = TextChannels:FindFirstChild("RBXGeneral")

		if msg:sub(1, 1) == "%" then
			local teamColor = player.TeamColor
			local teamChannel = TextChannels:FindFirstChild(`RBXTeam{teamColor.Name}`)

			if teamChannel then
				channel = teamChannel
			end

			msg = msg:sub(2)
		elseif msg:sub(1, 3) == "/sc" then
			local indices = msg:sub(4):split(" ")
			local tree = SafeChat

			for i, index in indices do
				local num = 1 + (tonumber(index) or 0)
				tree = tree.Branches[num]
			end

			msg = tree.Label
		end

		if channel and channel:IsA("TextChannel") then
			channel:SendAsync(msg)
		end
	end
end

chatBar.Focused:Connect(beginChatting)
chatBar.FocusLost:Connect(onChatFocusLost)
UserInputService.InputBegan:Connect(onInputBegan)

--------------------------------------------------------------------------------------------
-- Chat Output
--------------------------------------------------------------------------------------------

local messageId = 0
local chatQueue = LinkedList.new()

local function getMessageId()
	messageId += 1
	return messageId
end

local function onIncomingMessage(message: TextChatMessage)
	local source = message.TextSource
	local player = source and Players:GetPlayerByUserId(source.UserId)

	if not player then
		return
	end

	local text = message.Text
	text = text:gsub("#[# ]+#", "[ Content Deleted ]")

	-- Create the message
	local msg = messageTemplate:Clone()
	
	local playerLbl = msg:WaitForChild("PlayerName")
	playerLbl.TextColor3 = computePlayerColor(player)
	playerLbl.TextStrokeColor3 = playerLbl.TextColor3
	playerLbl.AutomaticSize = Enum.AutomaticSize.XY
	playerLbl.Text = player.Name .. ";  "
	
	local msgLbl = msg:WaitForChild("Message")
	msgLbl.AutomaticSize = Enum.AutomaticSize.XY
	msgLbl.Text = text

	msg.AutomaticSize = Enum.AutomaticSize.X
	msg.LayoutOrder = getMessageId()

	msg.Name = "Message" .. msg.LayoutOrder
	msg.Parent = chatOutput

	if chatQueue.size == 6 then
		local front = chatQueue.front
		front.data:Destroy()

		chatQueue:Remove(front.id)
	end

	chatQueue:Add(msg)
	Debris:AddItem(msg, 60)
end

TextChatService.MessageReceived:Connect(onIncomingMessage)

--------------------------------------------------------------------------------------------