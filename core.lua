local gameInst = game.JobId 
local isOnline = (gameInst ~= "")

if isOnline and game.GameId ~= 123949867 then
	script:Destroy()
	return
end

local Chat = game:GetService("Chat")
local CollectionService = game:GetService("CollectionService")
local InsertService = game:GetService("InsertService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local TeleportService = game:GetService("TeleportService")

local initMsg = Instance.new("Message")
initMsg.Text = "INITIALIZING..."
initMsg.Parent = workspace

spawn(function ()
	local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
	local loader = StarterPlayerScripts:WaitForChild("PlayerScriptsLoader")
	loader.Disabled = true
end)

if not workspace.FilteringEnabled then
	initMsg.Text = "FATAL: Workspace.FilteringEnabled MUST be set to true!!!"
	return 0
end

local override = ServerStorage:FindFirstChild("LocalGameImport")

if override then
	if isOnline then
		warn("WARNING: Dev framework is present in a networked game, and it shouldn't be!!!")
		override:Destroy()
	elseif override ~= script then
		initMsg:Destroy()
		require(override)
		return 1
	end
end

-- Apply standard forced settings
local devProps =
{
	DevComputerMovementMode       = "KeyboardMouse";
	DevComputerCameraMovementMode = "Classic";
	DevTouchMovementMode          = "UserChoice";
	DevTouchCameraMovementMode    = "Classic";
	
	LoadCharacterAppearance       = false;
	EnableMouseLockOption         = false;
}

for prop, value in pairs(devProps) do
	StarterPlayer[prop] = value
end

Lighting.Outlines = false
Players.CharacterAutoLoads = false
StarterGui.ShowDevelopmentGui = false

-- Add the default skybox, if no skybox has been added.
local sky = Lighting:FindFirstChildOfClass("Sky")

if not sky then
	local skyProps = {"Bk", "Dn", "Ft", "Lf", "Rt", "Up"}
	local skyId = "rbxasset://Sky/null_plainsky512_%s.jpg"
	
	sky = Instance.new("Sky")
	
	for _,prop in pairs(skyProps) do
		sky["Skybox"..prop] = skyId:format(prop:lower())
	end
	
	sky.Parent = Lighting
end

sky.SunAngularSize = 14
sky.MoonAngularSize = 6

for _,player in pairs(Players:GetPlayers()) do
	local char = player.Character
	
	if char and char:IsDescendantOf(workspace) then
		char:Destroy()
		player.Character = nil
	end
	
	for prop, value in pairs(devProps) do
		StarterPlayer[prop] = value
	end
end

-- Load DataModel 

for _,rep in pairs(script:GetChildren()) do
	local real = game:FindFirstChildWhichIsA(rep.Name, true)
	
	if not real then -- Hopefully a service that doesn't exist yet?
		real = game:GetService(rep.Name)
	end
	
	for _,child in pairs(rep:GetChildren()) do
		local existing = real:FindFirstChild(child.Name)
		
		if existing then
			existing:Destroy()
		end
		
		child.Parent = real
	end
end

-- Reconnect any players that may have joined during initialization.

if isOnline then
	for _,player in pairs(Players:GetPlayers()) do
		TeleportService:TeleportToPlaceInstance(game.PlaceId, gameInst, player)
	end
end

if Chat.LoadDefaultChat then
	warn("Chat.LoadDefaultChat should be set to false!")
end

initMsg:Destroy()
return 0