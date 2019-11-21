local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local gui = script.Parent
local player = Players.LocalPlayer

local hintBin = Instance.new("Folder")
local msgNameFmt = "MsgLbl_%s [%s]"

local function addMessage(sourceMsg, msgType)
	local isInPlayer = (sourceMsg.Parent == player)
	local msgType = sourceMsg.ClassName
	
	if msgType == "Message" and isInPlayer then
		msgType = "Player"
	end
	
	local msgTemp = script:WaitForChild(msgType)
	
	local msg = msgTemp:Clone()
	msg.Name = msgNameFmt:format(msgType, sourceMsg:GetFullName())
	
	local textUpdater = sourceMsg:GetPropertyChangedSignal("Text")
	local isUpdating = false
	
	local function updateText()
		if not isUpdating then
			isUpdating = true
			
			msg.Text = sourceMsg.Text
			sourceMsg.Text = ""
			
			if msgType ~= "Hint" then
				msg.Visible = (#msg.Text > 0)
			end
			
			isUpdating = false
		end
	end
	
	local function onAncestryChanged()
		local desiredAncestor
		
		if msgType == "Hint" then
			desiredAncestor = hintBin
		elseif isInPlayer then
			desiredAncestor = player
		else
			desiredAncestor = workspace
		end
		
		if not sourceMsg:IsDescendantOf(desiredAncestor) then
			msg:Destroy()
		end
	end
	
	--[[
		I have to parent the Hint somewhere where it won't render since it
		draws even if the Hint has no text. The server will remove the object
		by it's reference address even if I change the parent, so this isn't a
		problem online. But I can't rely on this in a non-network scenario so 
		regular Hints will still be visible offline if they're in the Workspace :(
	--]]

	if msgType == "Hint" then
		RunService.Heartbeat:Wait()
		sourceMsg.Parent = hintBin
	end
	
	updateText()
	textUpdater:Connect(updateText)
	sourceMsg.AncestryChanged:Connect(onAncestryChanged)
	
	msg.Parent = gui
end

local function registerMessage(obj)
	if obj:IsA("Message") then
		addMessage(obj)
	end
end

for _,v in pairs(workspace:GetDescendants()) do
	registerMessage(v)
end

for _,v in pairs(player:GetChildren()) do
	registerMessage(v)
end

player.ChildAdded:Connect(registerMessage)
workspace.DescendantAdded:Connect(registerMessage)