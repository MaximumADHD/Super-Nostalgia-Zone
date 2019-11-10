local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local camera = workspace.CurrentCamera
local resUpdate = camera:GetPropertyChangedSignal("ViewportSize")

local safeChat = script.Parent
local chatButton = safeChat:WaitForChild("ChatButton")

local click = chatButton:WaitForChild("Click")
local gamepadHint = chatButton:WaitForChild("Hint")

local IMG_CHAT = "rbxassetid://991182833"
local IMG_CHAT_DN = "rbxassetid://991182832"
local IMG_CHAT_OVR = "rbxassetid://991182834"

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Fetch Tree Data

local mSafeChatTree = ReplicatedStorage:WaitForChild("SafeChat")
local safeChatTree = require(mSafeChatTree)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Safe Chat Tree

local chatRemote = ReplicatedStorage:WaitForChild("ChatRemote")
local templates = safeChat:WaitForChild("Templates")

local tempBranch = templates:WaitForChild("TempBranch")
local tempButton = templates:WaitForChild("TempButton")

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
	chatButton.Image = IMG_CHAT

	recursivelyDeactivateTree(rootTree)
	
	if GuiService.SelectedObject then
		GuiService.SelectedObject = nil
		GuiService:RemoveSelectionGroup("SafeChatNav")
	end
end

local function activateRootTree()
	isActivated = true
	rootTree.Visible = true
	chatButton.Image = IMG_CHAT_DN
	
	if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 then
		GuiService:AddSelectionParent("SafeChatNav", safeChat)
		GuiService.SelectedObject = safeChat
	end
end

local function assembleTree(tree)
	local treeFrame = tempBranch:Clone()
	treeFrame.Name = "Branches"
	
	local currentBranch
	
	for i, branch in ipairs(tree.Branches) do
		local branches = branch.Branches
		local label = branch.Label

		local button = tempButton:Clone()
		button.Name = label
		button.Text = label
		button.LayoutOrder = i
		button.Visible = true

		local branchFrame = assembleTree(branch)
		branchFrame.Parent = button
		button.Parent = treeFrame
		
		local function onEnter()
			if currentBranch then
				recursivelyDeactivateTree(currentBranch)
			end

			currentBranch = button
			button.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
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
				click:Play()
				deactivateRootTree()
				chatRemote:FireServer(label)
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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Button State

local isActivated = false
local isHovering = false

do
	local function onMouseEnter()
		if not isActivated then
			chatButton.Image = IMG_CHAT_OVR
		end
		isHovering = true
	end
	
	local function onMouseLeave()
		if not isActivated then
			chatButton.Image = IMG_CHAT
		end

		isHovering = false
	end
	
	local function onMouseDown()
		chatButton.Image = IMG_CHAT_DN
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
	
	chatButton.MouseEnter:Connect(onMouseEnter)
	chatButton.MouseLeave:Connect(onMouseLeave)
	
	chatButton.MouseButton1Up:Connect(onMouseUp)
	chatButton.MouseButton1Down:Connect(onMouseDown)
	
	UserInputService.InputBegan:Connect(onInputBegan)
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Gamepad Stuff
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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