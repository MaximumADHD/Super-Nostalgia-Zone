--------------------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------------------

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")

local LinkedList = require(script:WaitForChild("LinkedList"))

local ui = script.Parent
local rootFrame = ui:WaitForChild("RootFrame")

local chat = rootFrame:WaitForChild("Chat")
local chatBar = chat:WaitForChild("ChatBar")
local chatOutput = chat:WaitForChild("ChatOutput")
local chatRemote = ReplicatedStorage:WaitForChild("ChatRemote")

local focusBackdrop = chatBar:WaitForChild("FocusBackdrop")
local mainBackdrop = chat:WaitForChild("MainBackdrop")
local messageTemplate = script:WaitForChild("MessageTemplate")

local hasCoreGateway, coreGateway = pcall(function ()
	local getCoreGateway = script:WaitForChild("GetCoreGateway")
	return require(getCoreGateway)
end)

--------------------------------------------------------------------------------------------------------------------------------------
-- Player Colors
--------------------------------------------------------------------------------------------------------------------------------------

local PLAYER_COLORS = 
{
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
		
		for i = 1,length do
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
	local msg = chatBar.Text
	
	if enterPressed and #msg > 0 then
		if #msg > 128 then
			msg = msg:sub(1, 125) .. "..."
		end
		
		chatRemote:FireServer(msg)
		
		if hasCoreGateway then
			coreGateway.ChatWindow.MessagePosted:Fire(msg)
		end
	end
	
	chatBar.Text = ""
	focusBackdrop.Visible = false
end

UserInputService.InputBegan:Connect(onInputBegan)

chatBar.Focused:Connect(beginChatting)
chatBar.FocusLost:Connect(onChatFocusLost)

--------------------------------------------------------------------------------------------
-- Chat Output
--------------------------------------------------------------------------------------------

local messageId = 0
local blank_v2 = Vector2.new()
local chatQueue = LinkedList.new()

local function computeTextBounds(label)
	local bounds = TextService:GetTextSize(label.Text, label.TextSize, label.Font, blank_v2)
	return UDim2.new(0, bounds.X, 0, bounds.Y)
end

local function getMessageId()
	messageId = messageId + 1
	return messageId
end

local function onReceiveChat(player, message, wasFiltered)
	-- Process the message
	if message:sub(1, 1) == "%" then
		message = "(TEAM) " .. message:sub(2)
	end
	
	if wasFiltered then
		message = message:gsub("#[# ]+#", "[ Content Deleted ]")
	end
	
	-- Create the message
	local msg = messageTemplate:Clone()
	
	local playerLbl = msg:WaitForChild("PlayerName")
	playerLbl.TextColor3 = computePlayerColor(player)
	playerLbl.TextStrokeColor3 = playerLbl.TextColor3
	playerLbl.Text = player.Name .. ";  "
	playerLbl.Size = computeTextBounds(playerLbl)
	
	local msgLbl = msg:WaitForChild("Message")
	msgLbl.Text = message
	msgLbl.Size = computeTextBounds(msgLbl)

	local width = playerLbl.AbsoluteSize.X + msgLbl.AbsoluteSize.X
	
	msg.Size = msg.Size + UDim2.new(0, width, 0, 0)
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

chatRemote.OnClientEvent:Connect(onReceiveChat)

--------------------------------------------------------------------------------------------