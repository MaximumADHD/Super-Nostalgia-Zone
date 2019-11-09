local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")

local gateway = script.Parent
local tool = gateway.Parent
local remote = gateway:WaitForChild("Gateway")
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local isActive = false

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Standard Input
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function activate(active,cf)
	isActive = active
	remote:FireServer("SetActive",active,cf)
	while isActive do
		wait(.1)
		remote:FireServer("SetTarget",mouse.Hit)
	end
end

local function onKey(input)
	local keyCode = input.KeyCode.Name
	local down = (input.UserInputState.Name == "Begin")
	remote:FireServer("KeyEvent",keyCode,down)
end

local function onInputBegan(input,gameProcessed)
	if not gameProcessed then
		local name = input.UserInputType.Name
		if name == "MouseButton1" then
			activate(true,mouse.Hit)
		elseif name == "Touch" then
			wait(.1)
			local state = input.UserInputState.Name
			if state == "End" or state == "Cancel" then
				activate(true,mouse.Hit)
			end
		elseif name == "Gamepad1" then
			local keyCode = input.KeyCode.Name
			if keyCode == "ButtonR2" then
				activate(true,mouse.Hit)
			end
		elseif name == "Keyboard" then
			onKey(input)
		end
	end
end

local function onInputEnded(input,gameProcessed)
	if not gameProcessed and isActive then
		local name = input.UserInputType.Name
		if name == "MouseButton1" or name == "Touch" or name == "Gamepad1" then
			activate(false,mouse.Hit)
		elseif name == "Keyboard" then
			onKey(input)
		end
	end
end

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Special case Input
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local mControlScheme = tool:WaitForChild("ControlScheme",5)

if mControlScheme then
	local controlSchemeData = require(mControlScheme)
	local controlScheme = controlSchemeData.Buttons
	local activateContext = controlSchemeData.ActivateContext
	local keyEvent = tool:WaitForChild("KeyEvent")
	local callbacks = {}
	
	local hands = { L = "Left", R = "Right" }
	local handTypes = {"Bumper","Trigger","Joystick (Press)"}
	
	local schemeDocs = 
	{
		Keyboard = {"Hold Left Mouse Button - " .. activateContext};
		Gamepad = {"Hold Right Trigger - " .. activateContext};
	}
	
	for key,data in pairs(controlScheme) do
		local down = false
		callbacks[key] = function (actionName,inputState,inputObject)
			if (inputState.Name == "Begin") and not down then
				down = true
				if data.Client then
					keyEvent:Fire(key,true)
				else
					remote:FireServer("KeyEvent",key,true)
				end
			elseif (inputState.Name == "End") and down then
				down = false
				if data.Client then
					keyEvent:Fire(key,false)
				else
					remote:FireServer("KeyEvent",key,false)
				end
			end
		end
		
		local xBtn = data.XboxButton:gsub("Button","")
		if #xBtn == 2 then
			local handId,hTypeId = xBtn:match("(%u)(%d)")
			local hand = hands[handId]
			local hType = handTypes[tonumber(hTypeId)]
			xBtn = hand .. " " .. hType
		else
			xBtn = "(" .. xBtn .. ")"
		end
		table.insert(schemeDocs.Keyboard,key .. " - " .. data.Label)
		table.insert(schemeDocs.Gamepad,xBtn .. " - " .. data.Label)
	end

	local currentSchemeDocMsg
	
	local function onLastInputTypeChanged(inputType)
		if currentSchemeDocMsg and not UserInputService.TouchEnabled and not controlSchemeData.HideControls then
			local schemeDoc
			if inputType.Name:find("Gamepad") then
				schemeDoc = "Gamepad"
			else
				schemeDoc = "Keyboard"
			end
			currentSchemeDocMsg.Text = schemeDoc .. " Controls:\n\n" .. table.concat(schemeDocs[schemeDoc],"\n")
		end
	end
	
	local diedCon
	local equipped = false
	
	local function onUnequipped()
		if equipped then
			equipped = false
			for key,data in pairs(controlScheme) do
				ContextActionService:UnbindAction(data.Label)
			end
			currentSchemeDocMsg:Destroy()
			currentSchemeDocMsg = nil
		end
	end
	
	local function onEquipped()
		if not equipped then
			equipped = true
			for key,data in pairs(controlScheme) do
				ContextActionService:BindAction(data.Label,callbacks[key],true,Enum.KeyCode[data.XboxButton])
				ContextActionService:SetTitle(data.Label,data.Label)
			end
			if UserInputService.TouchEnabled then
				spawn(function ()
					local playerGui = player:WaitForChild("PlayerGui")
					local contextActionGui = playerGui:WaitForChild("ContextActionGui")
					local contextButtonFrame = contextActionGui:WaitForChild("ContextButtonFrame")
					contextButtonFrame.Size = UDim2.new(3/8,0,3/8,0)
					contextButtonFrame.AnchorPoint = Vector2.new(1,1)
					contextButtonFrame.Position = UDim2.new(1,0,1,0)
				end)
			end
			currentSchemeDocMsg = Instance.new("Message")
			currentSchemeDocMsg.Parent = player
			onLastInputTypeChanged(UserInputService:GetLastInputType())
			if not diedCon then
				local char = tool.Parent
				if char then
					local humanoid = char:FindFirstChildWhichIsA("Humanoid")
					if humanoid then
						diedCon = humanoid.Died:Connect(onUnequipped)
					end
				end
			end
		end
	end
	
	tool.Equipped:Connect(onEquipped)
	tool.Unequipped:Connect(onUnequipped)
	UserInputService.LastInputTypeChanged:Connect(onLastInputTypeChanged)
end