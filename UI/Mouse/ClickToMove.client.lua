-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @CloneTrooper1019, 2018
-- ClickToMove
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local IS_TOUCH = UserInputService.TouchEnabled

local ICON_IDLE  = "rbxassetid://334630296"
local ICON_HOVER = "rbxassetid://1000000"
local ICON_CLICK = "rbxasset://textures/DragCursor.png"

local DISK_OFFSET = CFrame.Angles(math.pi / 2,0,0)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Character Listener
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local player = game.Players.LocalPlayer
local character, humanoid

local function onCharacterAdded(char)
	humanoid = char:WaitForChild("Humanoid")
	character = char
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Gui Focus
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local isMouseHoveringUi = false

local function onInputChanged(input, gameProcessed)
	local inputType = input.UserInputType.Name
	
	if inputType == "MouseMovement" then
		isMouseHoveringUi = gameProcessed
	end
end

local function isGuiFocused()
	return isMouseHoveringUi or GuiService.SelectedObject ~= nil
end

UserInputService.InputChanged:Connect(onInputChanged)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Movement Goal
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local currentGoal, moveSignal

local function findAngleBetweenXZVectors(vec2, vec1)
	return math.atan2(vec1.X * vec2.Z - vec1.Z * vec2.X, vec1.X * vec2.X + vec1.Z * vec2.Z)
end

local function isFinite(num)
	return num == num and num ~= 1/0 and num ~= -1/0
end

local function rotateCameraTowardsGoal(dt)
	local camera = workspace.CurrentCamera
	
	if camera then
		local cf = camera.CFrame
		local focus = camera.Focus
						
		local desiredAngle = CFrame.new(cf.Position, currentGoal).lookVector
		local currentAngle = cf.LookVector
		
		local angleBetween = findAngleBetweenXZVectors(desiredAngle, currentAngle)
		
		if isFinite(angleBetween) then
			local abs = math.abs(angleBetween)
			local sign = math.sign(angleBetween)
			local rotation = math.min(dt * 6, abs)
			
			local cfLocal = focus:toObjectSpace(cf)
			camera.CFrame = focus * CFrame.Angles(0, -rotation * sign, 0) * cfLocal
		end
	end
end

local function finishGoal()
	if currentGoal then
		currentGoal = nil
	end

	if moveSignal then
		moveSignal:Disconnect()
		moveSignal = nil
	end
end

local function clickToMove(goal)
	finishGoal()
	currentGoal = goal
	
	moveSignal = humanoid.MoveToFinished:Connect(finishGoal)
	
	humanoid:Move(Vector3.new(1,1,1))
	humanoid:MoveTo(currentGoal)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Green Disk
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local mouse = player:GetMouse()
local mouseIcon = script.Parent 
mouse.TargetFilter = workspace.CurrentCamera

local lastTarget
local lastTargetCanClick = false

local adorn = Instance.new("Part", script)

local disk = Instance.new("CylinderHandleAdornment")
disk.Name = "Disk"
disk.Color3 = Color3.new(0,1,0)
disk.Radius = 1
disk.Height = 0.2
disk.Visible = false
disk.Adornee = adorn
disk.Parent = script

local goalDisk = disk:Clone()
goalDisk.Name = "Goal"
goalDisk.Parent = script

local function hasTool()
	if character then
		return character:FindFirstChildOfClass("Tool") ~= nil
	end
	
	return false
end

local function isFirstPerson()
	if character then
		local head = character:FindFirstChild("Head")
		if head then
			return head.LocalTransparencyModifier == 1
		end
	end

	return false
end

local function canClickTarget()
	local target = mouse.Target

	if target then
		if target ~= lastTarget then
			local canClick = false
			local clickDetector = target:FindFirstChildOfClass("ClickDetector")
			
			if clickDetector then
				local dist = player:DistanceFromCharacter(target.Position)
				if dist <= clickDetector.MaxActivationDistance then
					canClick = true
				end
			end
			
			lastTarget = target
			lastTargetCanClick = canClick
		end
		
		return lastTargetCanClick
	end
end

local function canRenderDisk(rendering)
	if not TeleportService:GetTeleportSetting("ClickToMove") then
		return false
	end
	
	if rendering and IS_TOUCH then
		return false
	end
	
	if humanoid then
		local movement = humanoid.MoveDirection
		if movement.Magnitude == 0 then
			local pos = mouse.Hit.Position
			local dist = player:DistanceFromCharacter(pos)
			
			if dist < 32 then
				local blockers = {hasTool, isFirstPerson, canClickTarget, isGuiFocused}
				
				for _,blocker in pairs(blockers) do
					if blocker() then
						return false
					end
				end
				
				return true
			end
		else
			finishGoal()
		end
	end
	
	return false
end

local function render3dAdorn(dt)
	local dt = math.min(0.1, dt)
	disk.Visible = canRenderDisk(true)
	
	if disk.Visible then
		disk.CFrame = CFrame.new(mouse.Hit.Position) * DISK_OFFSET
		mouseIcon.Image = ICON_HOVER
	elseif canClickTarget() then
		mouseIcon.Image = ICON_CLICK
	elseif not hasTool() then
		mouseIcon.Image = ICON_IDLE
	end
	
	if currentGoal then
		goalDisk.Visible = true
		goalDisk.CFrame = CFrame.new(currentGoal) * DISK_OFFSET
		rotateCameraTowardsGoal(dt)
	else
		goalDisk.Visible = false
	end
end

RunService.Heartbeat:Connect(render3dAdorn)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Click Action
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function onInputBegan(input, gameProcessed)
	local goal = mouse.Hit.Position
	
	if not gameProcessed and canRenderDisk() and humanoid then	
		local name = input.UserInputType.Name
		
		if name == "MouseButton1" then
			clickToMove(goal)
		elseif name == "Touch" then
			wait(.1)
			if input.UserInputState == Enum.UserInputState.End then
				clickToMove(goal)
			end
		elseif name == "Gamepad1" then
			if input.KeyCode == Enum.KeyCode.ButtonR2 then
				clickToMove(goal)
			end
		end
	end
end

UserInputService.InputBegan:Connect(onInputBegan)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- OBLITERATE the invasive click to move mode that Roblox provides
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

pcall(function ()
	if IS_TOUCH then
		local playerScripts = player:WaitForChild("PlayerScripts")
		local no = function () end
		
		spawn(function ()
			local controlScript = playerScripts:WaitForChild("ControlScript", 86400)
			if controlScript then
				local masterControl = controlScript:WaitForChild("MasterControl")
				
				local clickToMove = masterControl:WaitForChild("ClickToMoveController")
				clickToMove = require(clickToMove)
				
				clickToMove:Disable()
				clickToMove.Enable = no
			end
		end)
		
		spawn(function ()
			local playerModule = playerScripts:WaitForChild("PlayerModule", 86400)
			if playerModule then
				local controlModule = playerModule:WaitForChild("ControlModule")
				
				local clickToMove = controlModule:WaitForChild("ClickToMoveController")
				clickToMove = require(clickToMove)
				
				clickToMove:Stop()
				clickToMove.Enable = no
			end
		end)
	end
end)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------