local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
GuiService.AutoSelectGuiEnabled = false

local btn = script.Parent
local topbar = btn.Parent
local root = topbar.Parent
local messageGui = root:WaitForChild("MessageGui")
local message = messageGui:WaitForChild("Message")
local exitOverride = messageGui:WaitForChild("ExitOverride")

local function onClicked()
	local visibleSignal = messageGui:GetPropertyChangedSignal("Visible")
	message.Visible = false
	exitOverride.Visible = true
	messageGui.Visible = true
	TeleportService:Teleport(998374377)
	visibleSignal:Connect(function ()
		if not messageGui.Visible then
			messageGui.Visible = true
		end
	end)
end

if not GuiService:IsTenFootInterface() then
	btn.MouseButton1Down:Connect(onClicked)
end

local exitBuffer = "Continue holding down 'Back' to return to the menu.\nExiting in...\n%.1f"

local function onInputBegan(input)
	if input.KeyCode == Enum.KeyCode.ButtonSelect and not exitOverride.Visible and not messageGui.Visible then
		messageGui.Visible = true
		message.Size = exitOverride.Size
		
		local success = true
		for i = 3,0,-.1 do
			if input.UserInputState ~= Enum.UserInputState.Begin then
				success = false
				break
			end
			message.Text = exitBuffer:format(i)
			wait(.1)
		end
		
		if success then
			onClicked()
		else
			messageGui.Visible = false
		end
	end
end

UserInputService.InputBegan:Connect(onInputBegan)