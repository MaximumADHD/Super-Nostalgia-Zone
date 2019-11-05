-- Seriously Roblox?

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")

local playerModule = playerScripts:WaitForChild("PlayerModule")
local controlModule = playerModule:WaitForChild("ControlModule")
local gamepad = require(controlModule:WaitForChild("Gamepad"))

playerModule = require(playerModule)
controlModule = playerModule:GetControls()

local function fixGamepad()
	local lastInputType = UserInputService:GetLastInputType()
	
	if lastInputType.Name == "Gamepad1" then
		local controllers = controlModule.controllers
		
		if controlModule.activeController ~= controllers[gamepad] then
			controlModule:SwitchToController(gamepad)
		end
	end
end

RunService:BindToRenderStep("GamepadPatch", 0, fixGamepad)