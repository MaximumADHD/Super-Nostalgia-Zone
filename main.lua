local gameInst = game.JobId 
local isOnline = (gameInst ~= "")

if isOnline and game.GameId ~= 123949867 then
	script:Destroy()
	return
end

local dataModel = script:WaitForChild("DataModel")
local framework = script:WaitForChild("Framework")

local Chat = game:GetService("Chat")
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

-- Standard Forced Settings
Lighting.Outlines = false
Players.CharacterAutoLoads = false
StarterGui.ShowDevelopmentGui = false

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

local devProps =
{
	DevComputerMovementMode       = "KeyboardMouse";
	DevComputerCameraMovementMode = "Classic";
	DevTouchMovementMode          = "UserChoice";
	DevTouchCameraMovementMode    = "Classic";
}

StarterPlayer.LoadCharacterAppearance = false
StarterPlayer.EnableMouseLockOption = false

for prop,value in pairs(devProps) do
	StarterPlayer[prop] = value
end

for _,player in pairs(Players:GetPlayers()) do
	local char = player.Character
	
	if char and char:IsDescendantOf(workspace) then
		char:Destroy()
		player.Character = nil
	end
	
	for prop,value in pairs(devProps) do
		StarterPlayer[prop] = value
	end
end

-- Import the shared universe assets (scripts and stuff shared between both the main menu and the actual places)
require(ServerStorage:FindFirstChild("LocalSharedImport") or 1027421176)

-- Load Scripts
for _,desc in pairs(dataModel:GetDescendants()) do
	if desc:IsA("StringValue") and desc.Name:sub(1,9) == "ScriptRef" then
		local scriptName = desc.Name:gsub("ScriptRef%[(.+)%]","%1")
		local scriptPath = desc.Value
		local scriptRef = framework
		
		local gotScript = true
		
		for path in scriptPath:gmatch("[^/]+") do
			scriptRef = scriptRef:WaitForChild(path, 1)
			
			if not scriptRef then
				gotScript = false
				
				warn("WARNING: Failed to load ScriptRef for", desc:GetFullName())
				warn("         got stuck at:", path)
				
				break
			end
		end
		
		if gotScript then
			local newScript = scriptRef:Clone()
			newScript.Name = scriptName
			
			if newScript:IsA("BaseScript") then
				newScript.Disabled = false
			end
			
			for _,child in pairs(desc:GetChildren()) do
				child.Parent = newScript
			end
			
			newScript.Parent = desc.Parent
		end
		
		desc:Destroy()
	end
end

-- Load DataModel 

for _,rep in pairs(dataModel:GetChildren()) do
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
-- (or restart the PlayerScripts manually if I'm offline testing)

local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

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