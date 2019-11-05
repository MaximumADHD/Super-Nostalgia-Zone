local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local c = workspace.CurrentCamera
local resUpdate = c:GetPropertyChangedSignal("ViewportSize")
local safeChat = script.Parent
local click = script:WaitForChild("Click")

local IMG_CHAT = "rbxassetid://991182833"
local IMG_CHAT_DN = "rbxassetid://991182832"
local IMG_CHAT_OVR = "rbxassetid://991182834"

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Fetch Tree Data

local mSafeChatTree = ReplicatedStorage:WaitForChild("SafeChatTree")
local safeChatTree = require(mSafeChatTree)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Button Positioning

local IS_PHONE = c.ViewportSize.Y < 600

local function onResolutionUpdate()
	local viewPort = c.ViewportSize
	local chatX = math.min(25,viewPort.Y/40)
	local chatY = (viewPort.X/viewPort.Y) * (viewPort.Y * 0.225)
	safeChat.Position = UDim2.new(0,chatX,1,-chatY)
end

onResolutionUpdate()
resUpdate:Connect(onResolutionUpdate)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Safe Chat Tree

local chatRemote = ReplicatedStorage:WaitForChild("ChatRemote")
local tempBranch = script:WaitForChild("TempBranch")
local tempButton = script:WaitForChild("TempButton")
local isActivated = false
local rootTree

local function recursivelyDeactivateTree(obj)
	if obj:IsA("Frame") then
		obj.Visible = false
	elseif obj:IsA("TextButton") then
		obj.BackgroundColor3 = Color3.new(1,1,1)
	end
	for _,v in pairs(obj:GetChildren()) do
		recursivelyDeactivateTree(v)
	end
end

local function deactivateRootTree()
	isActivated = false
	safeChat.Image = IMG_CHAT
	recursivelyDeactivateTree(rootTree)
	
	if GuiService.SelectedObject then
		GuiService.SelectedObject = nil
		GuiService:RemoveSelectionGroup("SafechatNav")
	end
end

local function activateRootTree()
	isActivated = true
	rootTree.Visible = true
	safeChat.Image = IMG_CHAT_DN
	
	if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 then
		GuiService:AddSelectionParent("SafechatNav",safeChat)
		GuiService.SelectedObject = safeChat
	end
end

local function assembleTree(tree)
	local treeFrame = tempBranch:Clone()
	treeFrame.Name = "Branches"
	
	local currentBranch
	
	for i,branch in ipairs(tree.Branches) do
		local label = branch.Label
		local branches = branch.Branches
		local button = tempButton:Clone()
		button.Name = label
		button.Text = label
		button.LayoutOrder = i
		local branchFrame = assembleTree(branch)
		branchFrame.Parent = button
		button.Parent = treeFrame
		
		local function onEnter()
			if currentBranch then
				recursivelyDeactivateTree(currentBranch)
			end
			currentBranch = button
			button.BackgroundColor3 = Color3.new(0.7,0.7,0.7)
			branchFrame.Visible = true		
		end
		
		local function onActivate()
			local submit = true
			if UserInputService.TouchEnabled then
				if not branchFrame.Visible and #branchFrame:GetChildren() > 1 then
					branchFrame.Visible = true
					submit = false
				end
			end
			if submit then
				deactivateRootTree()
				chatRemote:FireServer(label)
				click:Play()
			end			
		end
		
		button.MouseEnter:Connect(onEnter)
		button.SelectionGained:Connect(onEnter)
		button.MouseButton1Down:Connect(onActivate)
	end
	
	return treeFrame
end

rootTree = assembleTree(safeChatTree)
rootTree.Parent = safeChat

if IS_PHONE then
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = rootTree
	uiScale.Scale = 0.7
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Button State

local isActivated = false
local isHovering = false

do
	local function onMouseEnter()
		if not isActivated then
			safeChat.Image = IMG_CHAT_OVR
		end
		isHovering = true
	end
	
	local function onMouseLeave()
		if not isActivated then
			safeChat.Image = IMG_CHAT
		end
		isHovering = false
	end
	
	local function onMouseDown()
		safeChat.Image = IMG_CHAT_DN
	end
	
	local function onMouseUp()
		if isHovering then
			activateRootTree()
		end
	end
	
	local function onInputBegan(input,gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed and isActivated then
			deactivateRootTree()
		end
	end
	
	safeChat.MouseEnter:Connect(onMouseEnter)
	safeChat.MouseLeave:Connect(onMouseLeave)
	safeChat.MouseButton1Down:Connect(onMouseDown)
	safeChat.MouseButton1Up:Connect(onMouseUp)
	
	UserInputService.InputBegan:Connect(onInputBegan)
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Gamepad Stuff
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local gamepadHint = safeChat:WaitForChild("GamepadHint")

if GuiService:IsTenFootInterface() then
	gamepadHint.Visible = true
else
	local function onLastInputTypeChanged(inputType)
		gamepadHint.Visible = (inputType.Name == "Gamepad1")
	end
	
	onLastInputTypeChanged(UserInputService:GetLastInputType())
	UserInputService.LastInputTypeChanged:Connect(onLastInputTypeChanged)
end


local function onInputBegan(input)
	if input.KeyCode == Enum.KeyCode.ButtonX then
		activateRootTree()
	end
end

UserInputService.InputBegan:Connect(onInputBegan)