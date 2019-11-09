local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TeleportService = game:GetService("TeleportService")
local JointsService = game:GetService("JointsService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

spawn(function ()
	local function setCoreSafe(method, ...)
		while not pcall(StarterGui.SetCore, StarterGui, method, ...) do
			wait()
		end
	end
	
	setCoreSafe("TopbarEnabled", false)
	setCoreSafe("ResetButtonCallback", false)
end)

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

if not UserInputService.TouchEnabled then
	mouse.Icon = "rbxassetid://334630296"
end

local ui = script:FindFirstChild("UI")

if ui then
	ui.Parent = playerGui
else
	ui = playerGui:WaitForChild("UI")
end

ReplicatedFirst:RemoveDefaultLoadingScreen()

if playerGui:FindFirstChild("ConnectingGui") then
	playerGui.ConnectingGui:Destroy()
end

local IS_PHONE = ui.AbsoluteSize.Y < 600
local topbar = ui:WaitForChild("Topbar")

if IS_PHONE then
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 0.6
	uiScale.Parent = topbar
end

local messageGui = ui:WaitForChild("GameJoin")
local message = messageGui:WaitForChild("Message")

local partWatch = nil
local partQueue = {}

local bricks = 0
local connectors = 0
local messageFormat = "Bricks: %d  Connectors: %d"

---------------------------------------------------------------------

local fakeLoadTime = TeleportService:GetTeleportSetting("FakeLoadTime")

local function onDescendantAdded(desc)
	if desc:IsA("BasePart") and not desc:IsA("Terrain") then
		if not CollectionService:HasTag(desc, "AxisPart") and desc.Name ~= "__negatepart" then
			desc.LocalTransparencyModifier = 1
			partQueue[#partQueue + 1] = desc
		end
	elseif desc:IsA("Decal") then
		desc.LocalTransparencyModifier = 1
	end
end

if fakeLoadTime then
	local descendants = workspace:GetDescendants()
	
	for _,desc in pairs(descendants) do
		onDescendantAdded(desc)
	end
		
	partWatch = workspace.DescendantAdded:Connect(onDescendantAdded)
end

---------------------------------------------------------------------

local camera = workspace.CurrentCamera
camera.CameraType = "Follow"
camera.CameraSubject = workspace

messageGui.Visible = true

local bricks = 0
local connectors = 0
local lastUpdate = 0

local done = false

local function stepBrickConnectorStatus()
	if fakeLoadTime then
		wait(math.random() / 4)
		
		for i = 1, math.random(30, 50) do
			local part = table.remove(partQueue)
			
			if part then
				bricks = bricks + 1
				
				connectors = connectors + #part:GetJoints()
				part.LocalTransparencyModifier = 0
				
				for _,v in pairs(part:GetDescendants()) do
					if v:IsA("Decal") then
						v.LocalTransparencyModifier = 0
					end
				end
			end
		end
		
		done = (#partQueue == 0)
	else
		wait()
		done = game:IsLoaded()
	end
end

while not done do
	stepBrickConnectorStatus()
	message.Text = messageFormat:format(bricks, connectors)
end

if partWatch then
	partWatch:Disconnect()
	partWatch = nil
end

camera.CameraSubject = nil
message.Text = "Requesting character..."

wait(1)

local rep = game:GetService("ReplicatedStorage")
local requestCharacter = rep:WaitForChild("RequestCharacter")

requestCharacter:FireServer()
message.Text = "Waiting for character..."

while not player.Character do
	player.CharacterAdded:Wait()
	wait()
end

messageGui.Visible = false
camera.CameraType = "Custom"