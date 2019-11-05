local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local playerScripts = script.Parent
local playerModule = require(playerScripts:WaitForChild("PlayerModule"))

local cameraSystem = playerModule:GetCameras()

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
function cameraSystem:Update()
	if cameraSystem.activeCameraController then
		cameraSystem.activeCameraController:Enable(false)
		cameraSystem.activeCameraController = nil
	end
	
	main:Update()
	popper:Update()
	opacity:Update()
end

playerScripts:RegisterTouchCameraMovementMode(Enum.TouchCameraMovementMode.Default)
playerScripts:RegisterComputerCameraMovementMode(Enum.ComputerCameraMovementMode.Default)