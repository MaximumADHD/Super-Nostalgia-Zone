local help = script.Parent
local topbar = help.Parent
local root = topbar.Parent
local window = root:WaitForChild("HelpWindow")
local close = window:WaitForChild("Close")

local function onOpen()
	window.Visible = true
end

local function onClose()
	window.Visible = false
end

help.MouseButton1Down:Connect(onOpen)
close.MouseButton1Down:Connect(onClose)