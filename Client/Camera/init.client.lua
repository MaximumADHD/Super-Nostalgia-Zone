local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local main = require(script:WaitForChild("Main"))
local popper = require(script:WaitForChild("Popper"))
local opacity = require(script:WaitForChild("Opacity"))

local cameraSubjectChangedConn = nil
local renderSteppedConn = nil

local function onCameraSubjectChanged()
	local currentCamera = workspace.CurrentCamera
	if currentCamera then
		local newSubject = currentCamera.CameraSubject
		opacity:SetSubject(newSubject)
	end
end

local function onNewCamera()
	local currentCamera = workspace.CurrentCamera
	if currentCamera then
		if cameraSubjectChangedConn then
			cameraSubjectChangedConn:Disconnect()
  		end
		
		local cameraSubjectChanged = currentCamera:GetPropertyChangedSignal("CameraSubject")
		cameraSubjectChangedConn = cameraSubjectChanged:Connect(onCameraSubjectChanged)
		
		onCameraSubjectChanged()
	end
end

-- Initialize cameras.
local cameraUpdated = workspace:GetPropertyChangedSignal("CurrentCamera")
cameraUpdated:Connect(onNewCamera)

onNewCamera()
main:SetEnabled(true)
opacity:SetEnabled(true)

-- Overload the camera update function.
local function update()
	main:Update()
	popper:Update()
	opacity:Update()

	RunService:UnbindFromRenderStep("cameraRenderUpdate")
end

RunService:BindToRenderStep("RetroCamera", 250, update)