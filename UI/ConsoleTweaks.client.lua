local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local function addUIScale(obj,scale)
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = scale
	uiScale.Parent = obj
end

if GuiService:IsTenFootInterface() then
	local ui = script.Parent
	local rootFrame = ui:WaitForChild("RootFrame")
	
	local zoomControls = gui:WaitForChild("ZoomControls")
	zoomControls.Visible = false
	
	local backpack = gui:WaitForChild("Backpack")
	backpack.Position = UDim2.new(0, 0, 1, 0)
	
	local chat = gui:WaitForChild("Chat")
	chat.Visible = false
	
	local chatPadding = gui:WaitForChild("ChatPadding", 1)
	if chatPadding then
		chatPadding:Destroy()
	end

	local safeChat = gui:WaitForChild("SafeChat")
	safeChat.Visible = false
	
	local health = gui:WaitForChild("Health")
	addUIScale(health, 1.5)
end

wait()
script:Destroy()