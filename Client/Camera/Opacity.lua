-- SolarCrane

local module = {}

local LastUpdate = tick()
local TransparencyDirty = false
local Enabled = false
local LastTransparency = nil

local DescendantAddedConn, DescendantRemovingConn = nil, nil
local ToolDescendantAddedConns = {}
local ToolDescendantRemovingConns = {}
local CachedParts = {}

local function HasToolAncestor(object)
	return (object:FindFirstAncestorWhichIsA("Tool")) ~= nil
end

local function IsValidPartToModify(part)
	if part:IsA('BasePart') or part:IsA('Decal') then
		return not HasToolAncestor(part)
	end
	return false
end

local function TeardownTransparency()
	for child, _ in pairs(CachedParts) do
		child.LocalTransparencyModifier = 0
	end
	
	CachedParts = {}
	TransparencyDirty = true
	LastTransparency = nil

	if DescendantAddedConn then
		DescendantAddedConn:disconnect()
		DescendantAddedConn = nil
	end
	
	if DescendantRemovingConn then
		DescendantRemovingConn:disconnect()
		DescendantRemovingConn = nil
	end
	
	for object, conn in pairs(ToolDescendantAddedConns) do
		conn:disconnect()
		ToolDescendantAddedConns[object] = nil
	end
	
	for object, conn in pairs(ToolDescendantRemovingConns) do
		conn:disconnect()
		ToolDescendantRemovingConns[object] = nil
	end
end

local function SetupTransparency(character)
	TeardownTransparency()

	if DescendantAddedConn then 
		DescendantAddedConn:Disconnect() 
	end
	
	DescendantAddedConn = character.DescendantAdded:connect(function (object)
		-- This is a part we want to invisify
		if IsValidPartToModify(object) then
			CachedParts[object] = true
			TransparencyDirty = true
		-- There is now a tool under the character
		elseif object:IsA('Tool') then
			if ToolDescendantAddedConns[object] then 
				ToolDescendantAddedConns[object]:Disconnect() 
			end
			
			ToolDescendantAddedConns[object] = object.DescendantAdded:connect(function (toolChild)
				CachedParts[toolChild] = nil
				if toolChild:IsA('BasePart') or toolChild:IsA('Decal') then
					-- Reset the transparency
					toolChild.LocalTransparencyModifier = 0
				end
			end)
			
			if ToolDescendantRemovingConns[object] then 
				ToolDescendantRemovingConns[object]:Disconnect() 
			end
			
			ToolDescendantRemovingConns[object] = object.DescendantRemoving:connect(function (formerToolChild)
				wait() -- wait for new parent
				if character and formerToolChild and formerToolChild:IsDescendantOf(character) then
					if IsValidPartToModify(formerToolChild) then
						CachedParts[formerToolChild] = true
						TransparencyDirty = true
					end
				end
			end)
		end
	end)
	
	if DescendantRemovingConn then 
		DescendantRemovingConn:Disconnect()
	end
	
	DescendantRemovingConn = character.DescendantRemoving:connect(function (object)
		if CachedParts[object] then
			CachedParts[object] = nil
			-- Reset the transparency
			object.LocalTransparencyModifier = 0
		end
	end)
	
	for _,desc in pairs(character:GetDescendants()) do
		if IsValidPartToModify(desc) then
			CachedParts[desc] = true
			TransparencyDirty = true
		end
	end
end


function module:SetEnabled(newState)
	if Enabled ~= newState then
		Enabled = newState
		self:Update()
	end
end

function module:SetSubject(subject)
	local character = nil
	if subject and subject:IsA("Humanoid") then
		character = subject.Parent
	end
	if subject and subject:IsA("VehicleSeat") and subject.Occupant then
		character = subject.Occupant.Parent
	end
	if character then
		SetupTransparency(character)
	else
		TeardownTransparency()
	end
end

function module:Update()
	local instant = false
	local now = tick()
	local currentCamera = workspace.CurrentCamera

	if currentCamera then
		local transparency = 0
		if not Enabled then
			instant = true
		else
			local distance = (currentCamera.Focus.p - currentCamera.CFrame.p).magnitude
			if distance < 2 then
				transparency = 1
			elseif distance < 6 then
				transparency = 0.5
			else
				transparency = 0
			end
		end

		if TransparencyDirty or LastTransparency ~= transparency then
			for child in pairs(CachedParts) do
				if child.ClassName == "Decal" then
					child.LocalTransparencyModifier = math.floor(transparency)
				else
					child.LocalTransparencyModifier = transparency
				end
			end
			TransparencyDirty = false
			LastTransparency = transparency
		end
	end
	LastUpdate = now
end

return module