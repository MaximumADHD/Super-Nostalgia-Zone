local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

if GuiService:IsTenFootInterface() then
	return
end

local IS_TOUCH = UserInputService.TouchEnabled

local player = game.Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local passCameraEvent = playerScripts:WaitForChild("PassCameraEvent")

local self = script.Parent
local zoomIn = self:WaitForChild("ZoomIn")
local zoomLock = zoomIn:WaitForChild("Lock")
local firstPersonIndicator = self:WaitForChild("FirstPersonIndicator")

local yellow = Color3.new(1, 1, 0)
local white  = Color3.new(1, 1, 1)
local cyan   = Color3.new(0, 1, 1)

local c = workspace.CurrentCamera
local currentlyDown

local function updateCameraStatus()
	local dist = (c.Focus.p - c.CFrame.p).magnitude
	firstPersonIndicator.Visible = (dist <= 1.5)
	zoomLock.Visible = (dist <= 1)
end

local function setupButton(btn)
	local isDown = false
	local inBounds = false

	local lock = btn:FindFirstChild("Lock")
	local mouse = player:GetMouse()

	btn.MouseEnter:connect(function ()
		if (lock == nil or not lock.Visible) then
			if (currentlyDown == nil or currentlyDown == btn) then
				inBounds = true
				if isDown then
					btn.ImageColor3 = yellow
				else
					btn.ImageColor3 = cyan
				end
			end
		end
	end)

	btn.MouseLeave:connect(function ()
		if (lock == nil or not lock.Visible) then
			inBounds = false
			if isDown then
				btn.ImageColor3 = cyan
			else
				btn.ImageColor3 = white
			end
		end
	end)

	btn.MouseButton1Down:connect(function ()
		if (lock == nil or not lock.Visible) then
			isDown = true
			currentlyDown = btn
			btn.ImageColor3 = yellow
		end
	end)

	btn.MouseButton1Click:connect(function ()
		if (lock == nil or not lock.Visible) then
			isDown = false
			currentlyDown = nil
			inBounds = false
			passCameraEvent:Fire(btn.Name)
			if IS_TOUCH then
				btn.ImageColor3 = white
			end
		end
	end)

	mouse.Button1Up:Connect(function ()
		if (lock == nil or not lock.Visible) then
			if isDown then
				isDown = false
				currentlyDown = nil

				if inBounds then
					inBounds = false
					passCameraEvent:Fire(btn.Name)
				end
			end
		end

		btn.ImageColor3 = white
	end)

	if lock then
		lock.Changed:Connect(function ()
			if lock.Visible then
				btn.ImageColor3 = white
				isDown = false

				if currentlyDown == btn then
					currentlyDown = nil
				end
			end
		end)
	end

	if IS_TOUCH then
		btn.Modal = true
	end
end

for _,v in pairs(script.Parent:GetChildren()) do
	if v:IsA("ImageButton") then
		setupButton(v)
	end
end

c.Changed:connect(updateCameraStatus)