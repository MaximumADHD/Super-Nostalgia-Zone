local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TeleportService = game:GetService("TeleportService")
local JointsService = game:GetService("JointsService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

spawn(function ()
	local function setCoreSafe(method, ...)
		while not pcall(StarterGui.SetCore, StarterGui, method, ...) do
			RunService.Heartbeat:Wait()
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

local gameJoin = ui:WaitForChild("GameJoin")

local message = gameJoin:WaitForChild("Message")
local exitOverride = gameJoin:WaitForChild("ExitOverride")

local partWatch = nil
local partQueue = {}

local bricks = 0
local connectors = 0
local messageFormat = "Bricks: %d  Connectors: %d"

---------------------------------------------------------------------

local camera = workspace.CurrentCamera
camera.CameraType = "Follow"
camera.CameraSubject = workspace

gameJoin.Visible = true

local bricks = 0
local connectors = 0
local lastUpdate = 0

while not game:IsLoaded() do
	game.Loaded:Wait()
end

if not player.Character then
	camera.CameraSubject = nil
	message.Text = "Requesting character..."

	local requestCharacter = ReplicatedStorage:WaitForChild("RequestCharacter")
	requestCharacter:FireServer()

	message.Text = "Waiting for character..."

	while not player.Character do
		player.CharacterAdded:Wait()
	end
end

if not exitOverride.Visible then
	gameJoin.Visible = false
end

camera.CameraType = "Custom"
camera.CameraSubject = player.Character

script:Destroy()