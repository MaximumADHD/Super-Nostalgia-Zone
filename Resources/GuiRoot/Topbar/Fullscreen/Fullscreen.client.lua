local UserInputService = game:GetService("UserInputService")

local btn = script.Parent
local gameSettings = UserSettings():GetService("UserGameSettings")
local player = game.Players.LocalPlayer

local function onClick()
	if not player:FindFirstChild("FullscreenMsg") then
		local m = Instance.new("Message")
		m.Name = "FullscreenMsg"
		m.Text = "This button is just here for legacy aesthetics, and has no functionality."
		if UserInputService.MouseEnabled and UserInputService.KeyboardEnabled then
			m.Text = m.Text .. "\nPress F11 to toggle fullscreen!"
		end
		m.Parent = player
		wait(3)
		m:Destroy()
	end
end

local function update()
	if gameSettings:InFullScreen() then
		btn.Text = "\t\tx Fullscreen"
	else
		btn.Text = "\t\tFullscreen"
	end
end

update()
gameSettings.FullscreenChanged:connect(update)
btn.MouseButton1Down:Connect(onClick)