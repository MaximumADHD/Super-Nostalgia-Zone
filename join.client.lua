local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TeleportService = game:GetService("TeleportService")
local JointsService = game:GetService("JointsService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local mouse = player:GetMouse()

if not UserInputService.TouchEnabled then
	mouse.Icon = "rbxassetid://334630296"
end

local ui = script.UI
ui.Parent = playerGui

if playerGui:FindFirstChild("ConnectingGui") then
	playerGui.ConnectingGui:Destroy()
end

local gameJoin = ui.GameJoin

local message = gameJoin.Message
local exitOverride = gameJoin.ExitOverride

local bricks = 0
local connectors = 0
local statusFormat = "Bricks: %d  Connectors: %d"

---------------------------------------------------------------------

local camera = workspace.CurrentCamera
camera.CameraType = "Follow"
camera.CameraSubject = nil

gameJoin.Visible = true

local bricks = 0
local connectors = 0

local queueMax = 1
local queueSize = 1

local loadTimeout = 0
local canTimeout = false

local extentsUpdate = 0
local focus, size

local loading = true

local function computeVisibleExtents(model)
	local abs, inf = math.abs, math.huge
	local min, max = math.min, math.max
	
	local min_X, min_Y, min_Z = inf, inf, inf
	local max_X, max_Y, max_Z = -inf, -inf, -inf
	
	for _,child in pairs(model:GetChildren()) do
		if child:IsA("Model") then
			local cf, size = child:GetBoundingBox()

			local x, y, z = cf.X, cf.Y, cf.Z
			local sx, sy, sz = size.X / 2, size.Y / 2, size.Z / 2
			
			min_X = min(min_X, x - sx)
			min_Y = min(min_Y, y - sy)
			min_Z = min(min_Z, z - sz)
			
			max_X = max(max_X, x + sx)
			max_Y = max(max_Y, y + sy)
			max_Z = max(max_Z, z + sz)
		elseif child:IsA("BasePart") then
			if child.Transparency < 1 and not child:IsA("Terrain") then
				local cf = child.CFrame
				local size = child.Size
				
				local sx, sy, sz = size.X, size.Y, size.Z
				local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()
				
				-- https://zeuxcg.org/2010/10/17/aabb-from-obb-with-component-wise-abs/
				local ws_X = (abs(R00) * sx + abs(R01) * sy + abs(R02) * sz) / 2
				local ws_Y = (abs(R10) * sx + abs(R11) * sy + abs(R12) * sz) / 2
				local ws_Z = (abs(R20) * sx + abs(R21) * sy + abs(R22) * sz) / 2
				
				min_X = min(min_X, x - ws_X)
				min_Y = min(min_Y, y - ws_Y)
				min_Z = min(min_Z, z - ws_Z)
				
				max_X = max(max_X, x + ws_X)
				max_Y = max(max_Y, y + ws_Y)
				max_Z = max(max_Z, z + ws_Z)
			end
		end
	end

	if min_X == inf then
		min_X, min_Y, min_Z = 0, 0, 0
		max_X, max_Y, max_Z = 0, 0, 0
	end
	
	local cf = CFrame.new((min_X + max_X) / 2, 
		              (min_Y + max_Y) / 2, 
		              (min_Z + max_Z) / 2)
	
	local size = Vector3.new(max_X - min_X,
	                         max_Y - min_Y,
	                         max_Z - min_Z)
	
	return cf, size
end

local function onDescendantAdded(desc)
	if desc:IsA("BasePart") and desc.Transparency < 1 then
		bricks = bricks + 1
	elseif desc:IsA("JointInstance") then
		connectors = connectors + 1
	end
end

local function onDescendantRemoved(desc)
	if desc:IsA("BasePart") and desc.Transparency < 1 then
		bricks = bricks - 1
	elseif desc:IsA("JointInstance") then
		connectors = connectors - 1
	end
end

local added = workspace.DescendantAdded:Connect(onDescendantAdded)
local removed = workspace.DescendantRemoving:Connect(onDescendantRemoved)

local function updateLoadingState()
	-- Shutdown if the camera subject has been set.
	if camera.CameraSubject ~= nil then
		return
	end
	
	-- Update the extents
	local now = tick()

	if (now - extentsUpdate > 0.5) then
		focus, size = computeVisibleExtents(workspace)
		extentsUpdate = now
	end

	-- Update the camera zoom and location.
	local focalPos = focus.Position
	local extents = size.Magnitude * 2
	
	local lookVector = camera.CFrame.LookVector
	local zoom = CFrame.new(focalPos - (lookVector * extents), focalPos)
	
	camera.CFrame = camera.CFrame:Lerp(zoom, 0.2)
	camera.Focus = camera.Focus:Lerp(focus, 0.2)

	if loading then
		-- Update the display.
		local ratio = (queueMax - queueSize) / queueMax
		local r_bricks = math.floor(bricks * ratio)
		local r_connectors = math.floor(connectors * ratio)
		message.Text = statusFormat:format(r_bricks, r_connectors)
		
		-- Let the loading finish if the game is loaded
		-- and 90% of the content has finished loading.
		
		if game:IsLoaded() and ratio > 0.9 and canTimeout then
			loadTimeout = loadTimeout + 1

			if loadTimeout > 30 then
				loading = false
				
				if added then
					added:Disconnect()
					added = nil
				end
				
				if removed then
					removed:Disconnect()
					removed = nil
				end
			end
		end
	end
end

RunService:BindToRenderStep("LoadingState", 1000, updateLoadingState)

coroutine.wrap(function ()
	local function setCoreSafe(method, ...)
		while not pcall(StarterGui.SetCore, StarterGui, method, ...) do
			RunService.Heartbeat:Wait()
		end
	end
	
	setCoreSafe("TopbarEnabled", false)
	setCoreSafe("ResetButtonCallback", false)
end)()

do
	local bevelData = ReplicatedStorage:WaitForChild("BevelData")
	local meshPool = Instance.new("Folder", script)

	for assetId in bevelData.Value:gmatch("[^;]+") do
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshId = assetId
		mesh.Parent = meshPool
	end

	local meshes = meshPool:GetChildren()
	canTimeout = true

	if #meshes > 0 then
		queueMax = #meshes
		queueSize = #meshes

		ContentProvider:PreloadAsync(meshes, function (assetId, status)
			queueSize = queueSize - 1
		end)
	else
		queueMax = 1
		queueSize = 0
	end

	meshPool:Destroy()
end

while loading do
	RunService.Heartbeat:Wait()
end

if not player.Character then
	message.Text = "Requesting character..."
	wait(0.5)
	
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

RunService:UnbindFromRenderStep("LoadingState")
script:Destroy()