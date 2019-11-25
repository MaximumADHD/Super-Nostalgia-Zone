local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Dragger = Instance.new("Dragger")

local tool = script.Parent
local selection = Instance.new("SelectionBox")
selection.Parent = tool
selection.Transparency = 1

local icon = Instance.new("StringValue")
icon.Name = "IconOverride"
icon.Parent = tool

local mode = tool.Name
local draggerService = ReplicatedStorage:WaitForChild("DraggerService")
local gateway = draggerService:WaitForChild("DraggerGateway")
local submitUpdate = draggerService:WaitForChild("SubmitUpdate")

----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Connections
----------------------------------------------------------------------------------------------------------------------------------------------------------------

local cons = {}

local function addConnections(connections)
	for event, func in pairs(connections) do
		local con = event:Connect(func)
		table.insert(cons, con)
	end
end

local function clearCons()
	while #cons > 0 do
		local connection = table.remove(cons)
		connection:Disconnect()
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Keys
----------------------------------------------------------------------------------------------------------------------------------------------------------------

local keyLocks = {}

local function onInputEnded(input)
	if keyLocks[input.KeyCode.Name] then
		keyLocks[input.KeyCode.Name] = nil
	end
end

local function isKeyDown(key)
	if UserInputService:IsKeyDown(key) and not keyLocks[key] then
		keyLocks[key] = true
		return true
	end
	return false
end

UserInputService.InputEnded:Connect(onInputEnded)

----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Tool Style
----------------------------------------------------------------------------------------------------------------------------------------------------------------

local style =
{
	GameTool = 
	{
		Icon = "rbxassetid://1048129653";
		HoverColor = Color3.fromRGB(25,153,255);
		Cursors = 
		{
			Idle = "";
			Hover = "rbxasset://textures/DragCursor.png";
			Grab = "rbxasset://textures/GrabRotateCursor.png";
		};
	};
	Clone = 
	{
		Icon = "rbxasset://textures/Clone.png";
		HoverColor = Color3.fromRGB(25,153,255);
		Cursors =
		{
			Idle = "rbxasset://textures/CloneCursor.png";
			Hover = "rbxassetid://1048136830";
			Grab = "rbxasset://textures/GrabRotateCursor.png";		
		}
	};
	Delete =
	{
		Icon = "rbxasset://textures/Hammer.png";
		HoverColor = Color3.new(1,0.5,0);
		CanShowWithHover = true;
		Cursors = 
		{
			Idle = "rbxasset://textures/HammerCursor.png";
			Hover = "rbxasset://textures/HammerOverCursor.png";
		}
	}
}

local function getIcon(iconType)
	return style[mode].Cursors[iconType]
end

tool.TextureId = style[mode].Icon
selection.Color3 = style[mode].HoverColor

if style[mode].CanShowWithHover then
	selection.Transparency = 0
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Dragger
----------------------------------------------------------------------------------------------------------------------------------------------------------------

local mouse
local currentKey
local down = false
local debounce = false

local function onIdle()
	if not down and mouse then
		local mousePart = mouse.Target
		
		if mousePart and not mousePart.Locked then
			selection.Adornee = mousePart
			icon.Value = getIcon("Hover")
			return
		end
		
		selection.Adornee = nil
		icon.Value = getIcon("Idle")
	end
end

local function draggerRotate(axis)
	if down then
		Dragger:AxisRotate(axis)
	end
end

local function startDraggerAction(mPart)
	if mode == "Delete" then
		gateway:InvokeServer("RequestDelete", mPart)
		return
	end
	
	local pointOnMousePart = mPart.CFrame:ToObjectSpace(mouse.Hit).Position
	local canDrag, dragKey, mousePart = gateway:InvokeServer("GetKey", mPart, mode == "Clone")
	
	if canDrag then
		selection.Adornee = mousePart
		selection.Transparency = 0
		
		down = true
		currentKey = dragKey
		
		icon.Value = getIcon("Grab")
		Dragger:MouseDown(mousePart, pointOnMousePart, {mousePart})
		
		local lastSubmit = 0
		
		while down do
			local now = tick()
			
			if down then
				Dragger:MouseMove(mouse.UnitRay)
			end
			
			if mousePart and currentKey then
				if isKeyDown("R") then
					draggerRotate("Z")
				elseif isKeyDown("T") then
					draggerRotate("X")
				end
				
				if now - lastSubmit > 0.03 then
					submitUpdate:FireServer(currentKey, mousePart.CFrame)
					lastSubmit = now
				end
			end
			
			RunService.Heartbeat:Wait()
		end
		
		selection.Transparency = 1

		-- Its the servers job to deal with these, but thanks Roblox :)
		for _,child in pairs(mousePart:GetChildren()) do
			if child:IsA("JointInstance") then
				child:Destroy()
			end
		end
		
		gateway:InvokeServer("ClearKey", dragKey)
		currentKey = nil
	end
end

local function onButton1Down()
	if not debounce then
		debounce = true
		
		local mousePart = selection.Adornee
		
		if mousePart and not down then
			startDraggerAction(mousePart)
		end
		
		debounce = false
	end
end

local function onButton1Up()
	if down then
		down = false
		Dragger:MouseUp()
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Tool 
----------------------------------------------------------------------------------------------------------------------------------------------------------------

local function onEquipped(newMouse)
	mouse = newMouse
	addConnections
	{
		[mouse.Button1Down] = onButton1Down;
		[mouse.Button1Up]   = onButton1Up;
		[mouse.Idle]        = onIdle;
	}
end

local function onUnequipped()
	onButton1Up()
	clearCons()
	
	selection.Adornee = nil
	mouse = nil
end

tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)

----------------------------------------------------------------------------------------------------------------------------------------------------------------