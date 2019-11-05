local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedFirst = script.Parent
local JointsService = game:GetService("JointsService")

do
	local StarterGui = game:GetService("StarterGui")
	
	local function setCoreSafe(method,...)
		while not pcall(StarterGui.SetCore, StarterGui, method,...) do
			wait()
		end
	end
	
	spawn(function ()
		setCoreSafe("ResetButtonCallback", false)
	end)
	
	setCoreSafe("TopbarEnabled", false)
end

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

if not UserInputService.TouchEnabled then
	mouse.Icon = "rbxassetid://334630296"
end

local guiRoot = script:WaitForChild("GuiRoot")
guiRoot.Parent = playerGui

ReplicatedFirst:RemoveDefaultLoadingScreen()

if playerGui:FindFirstChild("ConnectingGui") then
	playerGui.ConnectingGui:Destroy()
end

if RunService:IsStudio() then
	return
end

local c = workspace.CurrentCamera
local IS_PHONE = c.ViewportSize.Y < 600

local topbar = guiRoot:WaitForChild("Topbar")

if IS_PHONE then
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 0.6
	uiScale.Parent = topbar
end

local messageGui = guiRoot:WaitForChild("MessageGui")
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

local c = workspace.CurrentCamera
c.CameraType = "Follow"
c.CameraSubject = workspace

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

c.CameraSubject = nil
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
c.CameraType = "Custom"