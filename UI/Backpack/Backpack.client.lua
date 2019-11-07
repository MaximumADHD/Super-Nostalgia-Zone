-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @CloneTrooper1019, 2015
-- Backpack
-- Simulates the 2008 backpack from scratch.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Setup

local ui = script.Parent
local rootFrame = ui:WaitForChild("RootFrame")

local self = rootFrame:WaitForChild("Backpack")
local slotTemp = script:WaitForChild("SlotTemp")

local backdrop = self:WaitForChild("Backdrop")
local slotsBin = self:WaitForChild("Slots")

local player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local toolIndex = 0

local tools = {}
local slots = {}
local tokens = 
{
	One = 1;
	Two = 2;
	Three = 3;
	Four = 4;
	Five = 5;
	Six = 6;
	Seven = 7;
	Eight = 8;
	Nine = 9;
	Zero = 10; -- shhh not a hack
}

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Key Hookup

local eNumPress = Instance.new("BindableEvent")
local numPress = eNumPress.Event

-- Hack to work around the inputs being overridden while the Plane tool is active.
local function allowGameProcessedBypassHack()
	local lastInputType = UserInputService:GetLastInputType()
	if lastInputType.Name == "Gamepad1" then
		local char = player.Character
		if char then
			local tool = char:FindFirstChildWhichIsA("Tool")
			if tool and not tool.Enabled then
				return true
			end
		end
	end
	return false
end

local function onInputBegan(input,gameProcessed)
	if not gameProcessed or allowGameProcessedBypassHack() then
		local name = input.UserInputType.Name
		local keyCode = input.KeyCode.Name
		if name == "Keyboard" then
			local toIndex = tokens[keyCode]
			if toIndex then
				eNumPress:Fire(toIndex)
			end
		elseif name == "Gamepad1" then
			if keyCode == "ButtonL1" or keyCode == "ButtonR1" then
				local nextIndex = toolIndex
				if keyCode == "ButtonL1" then
					nextIndex = nextIndex - 1
				elseif keyCode == "ButtonR1" then
					nextIndex = nextIndex + 1
				end
				print(nextIndex,#tools)
				if nextIndex > 0 and nextIndex <= #tools then
					eNumPress:Fire(nextIndex)
				else
					eNumPress:Fire(toolIndex)
				end
			end
		end
	end
end

UserInputService.InputBegan:connect(onInputBegan)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function resortSlots()
	for index,tool in ipairs(tools) do
		local slot = slots[tool]
		slot.Index.Text = index
		slot.LayoutOrder = index
		slot.Visible = true
	end
	backdrop.Size = UDim2.new(#tools,0,1,0)
end

local function createSlot(tool)
	if not slots[tool] then
		local index = #tools+1
		tools[index] = tool
		
		local slot = slotTemp:clone()
		slot.Name = tool.Name
		slot.Parent = slotsBin
		
		local textHover = slot:WaitForChild("TextHover")
		local selectionOutline = slot:WaitForChild("SelectionOutline")
		local toolIcon = slot:WaitForChild("ToolIcon")
		local indexLbl = slot:WaitForChild("Index")
		local toolName = slot:WaitForChild("ToolName")
		
		local isHovering = false
		local isDown = false

		local backpack = player:WaitForChild("Backpack")
		local char = player.Character or player.CharacterAdded:Wait()
		
		local humanoid = char:WaitForChild("Humanoid")
		local conReg = {}
		
		local function killTool()
			local currentIndex = tonumber(indexLbl.Text)
			table.remove(tools, currentIndex)
			
			for _,con in pairs(conReg) do
				con:disconnect()
			end
			
			slots[tool] = nil
			slot:Destroy()
			
			resortSlots()
		end
		
		local function checkParent()
			if tool.Parent == char then
				selectionOutline.Visible = true
			elseif tool.Parent == backpack then
				selectionOutline.Visible = false
			else
				killTool()
			end
		end
		
		local function toggleTool()
			if tool.Parent == char then
				humanoid:UnequipTools()
			else
				toolIndex = tonumber(indexLbl.Text)
				humanoid:EquipTool(tool)
			end
		end
		
		local function renderUpdate()
			if tool.TextureId ~= "" then
				toolName.Visible = false
				toolIcon.Visible = true
				toolIcon.Image = tool.TextureId
			else
				toolIcon.Visible = false
				toolName.Visible = true
				toolName.Text = tool.Name
			end
			if tool.TextureId ~= "" then
				textHover.Visible = false
				if isHovering then
					toolIcon.BackgroundTransparency = 0
					if isDown then
						toolIcon.BackgroundColor3 = Color3.new(0,0,1)
					else
						toolIcon.BackgroundColor3 = Color3.new(1,1,0)
					end
				else
					toolIcon.BackgroundTransparency = 1
				end
			else
				textHover.Visible = true
				if isHovering then
					textHover.BackgroundTransparency = 0
					if isDown then
						textHover.BackgroundColor3 = Color3.new(1,1,0)
					else
						textHover.BackgroundColor3 = Color3.new(0.706,0.706,0.706)
					end
				else
					textHover.BackgroundTransparency = 1
				end
			end
		end

		local function onInputBegan(input)
			if input.UserInputType.Name == "MouseButton1" then
				isDown = true
			elseif input.UserInputType.Name == "MouseMovement" or input.UserInputType.Name == "Touch" then
				isHovering = true
			end
			renderUpdate()
		end
		
		local function onInputEnded(input)
			if input.UserInputType.Name == "MouseButton1" then
				isDown = false
				if isHovering then
					toggleTool()
				end
			elseif input.UserInputType.Name == "MouseMovement" then
				isHovering = false
			elseif input.UserInputType.Name == "Touch" then
				isHovering = false
				if humanoid.MoveDirection == Vector3.new() then
					toggleTool()
				end
			end
			
			renderUpdate()
		end
		
		local function onNumDown(num)
			local currentIndex = tonumber(indexLbl.Text)
			
			if num == currentIndex then
				toggleTool()
			end
		end
		
		local function onToolChanged(property)
			if property == "TextureId" or property == "Name" then
				renderUpdate()
			elseif property == "Parent" then
				checkParent()
			end
		end
		
		local eventMounts = 
		{
			[numPress]        = onNumDown;
			[tool.Changed]    = onToolChanged;
			[slot.InputBegan] = onInputBegan;
			[slot.InputEnded] = onInputEnded;			
			[humanoid.Died]   = killTool;
		}
		
		renderUpdate()
		checkParent()
		
		for event, func in pairs(eventMounts) do
			local connection = event:Connect(func)
			table.insert(conReg, connection)
		end
		
		slots[tool] = slot
		resortSlots()
	end
end

local currentChar

local function onCharacterAdded(char)
	if currentChar ~= char then
		currentChar = char
		
		for _,v in pairs(slots) do
			v:Destroy()
		end
		
		slots = {}
		tools = {}
		
		local function onChildAdded(child)
			if child:IsA("Tool") then
				createSlot(child)
			end
		end
		
		local backpack = player:WaitForChild("Backpack")
		
		for _,v in pairs(backpack:GetChildren()) do
			onChildAdded(v)
		end
		
		for _,v in pairs(char:GetChildren()) do
			onChildAdded(v)
		end
		
		char.ChildAdded:connect(onChildAdded)
		backpack.ChildAdded:connect(onChildAdded)
	end
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:connect(onCharacterAdded)

game.StarterGui.ResetPlayerGuiOnSpawn = false