local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local function addUIScale(obj,scale)
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = scale
	uiScale.Parent = obj
end

if GuiService:IsTenFootInterface() then
	local gui = script.Parent
	local zoomControls = gui:WaitForChild("ZoomControls")
	zoomControls.Visible = false
	
	local backpack = gui:WaitForChild("Backpack")
	backpack.Position = UDim2.new(0, 0, 1, 0)
	
	local chat = gui:WaitForChild("Chat")
	addUIScale(chat, 1.5)
	
	local chatPadding = gui:WaitForChild("ChatPadding", 1)
	if chatPadding then
		chatPadding:Destroy()
	end

	local safeChat = gui:WaitForChild("SafeChat")
	addUIScale(safeChat, 1.5)
	
	local health = gui:WaitForChild("Health")
	addUIScale(health, 1.5)
end

wait()
script:Destroy()