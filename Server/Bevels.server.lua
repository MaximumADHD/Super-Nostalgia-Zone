------------------------------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------------------------------

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local function getFlag(name)
	local flag = ServerStorage:FindFirstChild(name)
	return (flag and flag:IsA("BoolValue") and flag.Value)
end

local enableBevels = getFlag("EnableBevels")
local debugMode = getFlag("DevTestMode")

local bevelCache = ServerStorage:FindFirstChild("BevelCache")
local bevelsReady = bevelCache:FindFirstChild("BevelsReady")

if not bevelCache then
	bevelCache = Instance.new("Folder")
	bevelCache.Name = "BevelCache"
	bevelCache.Parent = ServerStorage
end

if not bevelsReady then
	bevelsReady = Instance.new("BoolValue")
	bevelsReady.Name = "BevelsReady"
	bevelsReady.Parent = bevelCache
	bevelsReady.Archivable = false
end

if not enableBevels then
	bevelsReady.Value = true
	return
end

do
	local coreBevelCache = ServerStorage:WaitForChild("CoreBevelCache")
	
	for _,bevel in pairs(coreBevelCache:GetChildren()) do
		if not bevelCache:FindFirstChild(bevel.Name) then
			bevel.Parent = bevelCache
			bevel.Archivable = false
		end
	end
	
	coreBevelCache:Destroy()
end

local regen = ServerStorage:FindFirstChild("Regeneration")

if regen then
	local ready = regen:WaitForChild("Ready")
	
	while not ready.Value do
		ready.Changed:Wait()
	end
end

local loadBuildTools = ServerStorage:FindFirstChild("LoadBuildTools")
local hasBuildTools = (loadBuildTools ~= nil)

------------------------------------------------------------------------------------------------

local edgeDepth = 1 / 15
local cornerDepth = edgeDepth * math.sqrt(8 / 3)

local mirrorProps = 
{
	"Anchored",
	"CanCollide",
	"CastShadow",
	"CFrame",
	"CollisionGroupId",
	"CustomPhysicalProperties",
	"Color",
	"Locked",
	"Material",
	"Name",
	"Reflectance",
	"RotVelocity",
	"Transparency",
	"Velocity",
}

local surfaceProps =
{
	"ParamA",
	"ParamB",
	"Surface",
	"SurfaceInput"
}

local bevelHash = "%.2f ~ %.2f ~ %.2f"
local isStudio = RunService:IsStudio()

local negateBase = Instance.new("Part")
negateBase.Name = "__negateplane"
negateBase.CanCollide = false
negateBase.BottomSurface = 0
negateBase.Transparency = 1
negateBase.Anchored = true
negateBase.TopSurface = 0
negateBase.Locked = true

CollectionService:AddTag(negateBase, "NoBevels")

for _,normalId in pairs(Enum.NormalId:GetEnumItems()) do
	local name = normalId.Name
	for _,surfaceProp in pairs(surfaceProps) do
		table.insert(mirrorProps, name .. surfaceProp)
	end
end

------------------------------------------------------------------------------------------------

local overload = 0
local threshold = Vector3.new(30, 30, 30)

if ServerStorage:FindFirstChild("BevelThreshold") then
	threshold = ServerStorage.BevelThreshold.Value
end

local function debugPrint(...)
	if debugMode then
		warn("[BEVELS DEBUG]:", ...)
	end
end

local function isPartOfHumanoid(object)
	local model = object:FindFirstAncestorOfClass("Model")
	
	if model then
		if model:FindFirstChildOfClass("Humanoid") then
			return true
		else
			return isPartOfHumanoid(model)
		end
	end
	
	return false
end

local function canGiveBevels(part)
	if part.Parent and part:IsA("Part") and not CollectionService:HasTag(part, "NoBevels") then
		if not isPartOfHumanoid(part) and not part:FindFirstChildWhichIsA("DataModelMesh") then
			local inThreshold = false
			local diff = threshold - part.Size
			
			if diff.X >= 0 and diff.Y >= 0 and diff.Z >= 0 then
				inThreshold = true
			end
			
			if inThreshold then
				if CollectionService:HasTag(part, "ForceBevels") then
					return true
				else
					return part.Shape.Name == "Block" and part.Transparency < 1
				end
			end
		end
	end
	
	return false
end

local function createProxyPart(part, name, tag, sizeChange)
	local proxyPart = Instance.new("Part")
	proxyPart.Name = name
	proxyPart.Locked = true
	proxyPart.TopSurface = 0
	proxyPart.Massless = true
	proxyPart.Transparency = 1
	proxyPart.BottomSurface = 0
	proxyPart.CanCollide = false
	proxyPart.CFrame = part.CFrame
	
	local size = part.Size
	if sizeChange then
		size = size + sizeChange
	end
	
	local proxyWeld = Instance.new("Weld")
	proxyWeld.Name = "ProxyWeld"
	proxyWeld.Part1 = proxyPart
	proxyWeld.Part0 = part
	
	if hasBuildTools then
		local mesh = Instance.new("SpecialMesh")
		mesh.Scale = size * 20
		mesh.MeshType = "Brick"
		mesh.Offset = part.Size
		mesh.Parent = proxyPart
		
		proxyPart.Size = Vector3.new(.05, .05, .05)
		proxyWeld.C0 = CFrame.new(-mesh.Offset)
	else
		proxyPart.Size = part.Size
	end
	
	CollectionService:AddTag(proxyPart, tag)
	CollectionService:AddTag(proxyPart, "NoBevels")
	CollectionService:AddTag(proxyWeld, "GorillaGlue")
	
	proxyWeld.Parent = proxyPart
	proxyPart.Parent = part
	
	return proxyPart
end

local function createBevels(part, initializing)
	if not canGiveBevels(part) or isPartOfHumanoid(part) then
		return
	end
	
	local size = part.Size
	local sx, sy, sz = size.X, size.Y, size.Z
	local bevelKey = bevelHash:format(sx, sy, sz)
	
	local debugBox
	
	if debugMode then
		debugBox = Instance.new("BoxHandleAdornment")
		
		debugBox.Color3 = Color3.new(0, 2, 2)
		debugBox.AlwaysOnTop = true
		debugBox.Name = "DebugBox"
		debugBox.Size = size
		debugBox.ZIndex = 0
		
		debugBox.Adornee = part
		debugBox.Parent = part
	end
	
	if not bevelCache:FindFirstChild(bevelKey) then
		local halfSize = size / 2
		
		local planeScale = math.max(sx, sy, sz)
		local planes = {}
		
		local solverPart = part:Clone()
		solverPart.CFrame = CFrame.new()
		solverPart.BrickColor = BrickColor.new(-1)
		
		debugPrint("Solving:", bevelKey)
		
		for x = -1, 1 do
			local x0 = (x == 0)
			
			for y = -1, 1 do
				local y0 = (y == 0)
				
				for z = -1, 1 do
					local z0 = (z == 0)
					
					local isCenter = (x0 and y0 and z0)
					local isFace = ((x0 and y0) or (y0 and z0) or (z0 and x0))
					
					if not (isCenter or isFace) then
						local isCorner = (not x0 and not y0 and not z0)
						local depth = isCorner and cornerDepth or edgeDepth
						
						local offset = Vector3.new(x, y, z)
						local cornerPos = (halfSize * offset)
						
						local plane = negateBase:Clone()
						plane.CFrame = CFrame.new(cornerPos, cornerPos + offset)
						plane.Size = Vector3.new(planeScale, planeScale, depth)
						plane.Parent = part
						
						table.insert(planes, plane)
					end
				end
			end
		end
		
		local success, union = pcall(function ()
			return solverPart:SubtractAsync(planes, "Box")
		end)
		
		if success then
			union.Name = bevelKey
			union.UsePartColor = true
			union.Parent = bevelCache
			
			CollectionService:AddTag(union, "HasBevels")
			
			if debugBox then
				debugBox.Color3 = Color3.new(0, 2, 0)
			end
		elseif debugBox then
			debugBox.Color3 = Color3.new(2, 0, 0)
		end
		
		for _,plane in pairs(planes) do
			plane:Destroy()
		end
		
		overload = 0
	else
		if debugBox then
			debugBox.Color3 = Color3.new(2, 0, 2)
		end
		
		overload = overload + 1
		
		if overload % 10 == 0 then
			RunService.Heartbeat:Wait()
		end
	end
	
	local baseUnion = bevelCache:FindFirstChild(bevelKey)
	
	if baseUnion then
		local archivable = baseUnion.Archivable
		baseUnion.Archivable = true
		
		local union = baseUnion:Clone()
		baseUnion.Archivable = archivable
		
		for _,prop in ipairs(mirrorProps) do
			union[prop] = part[prop]
		end
		
		for _,joint in pairs(part:GetJoints()) do
			if joint:IsA("JointInstance") or joint:IsA("WeldConstraint") then
				if joint.Part0 == part then
					joint.Part0 = union
				elseif joint.Part1 == part then
					joint.Part1 = union
				end
			end
		end
		
		for _,child in pairs(part:GetChildren()) do
			if not child:IsA("TouchTransmitter") and not child:IsA("Texture") then
				if child:IsA("BaseScript") then
					child.Disabled = true
				end
				
				child.Parent = union
				
				if child:IsA("BaseScript") then
					child.Disabled = false
				end
			end
		end
		
		if not initializing then
			wait()
		end
		
		if CollectionService:HasTag(part, "DoUnlock") then
			union.Locked = false
		end
		
		if part.ClassName ~= "Part" then
			local holder = Instance.new("Weld")
			holder.Part0 = part
			holder.Part1 = union
			holder.Parent = part
			
			union.Anchored = false
			union.Massless = true
			union.Parent = part
			
			part.Transparency = 1
			CollectionService:AddTag(holder, "GorillaGlue")
		else
			local parent = part.Parent
			part:Destroy()
			
			union.Parent = parent
		end
	elseif debugBox then
		debugBox.Color3 = Color3.new(2, 0, 0)
	end
	
	if debugBox then
		debugBox.Transparency = 0.5
		Debris:AddItem(debugBox, 2)
	end
end

------------------------------------------------------------------------------------------------

do
	local waitForPlayer = getFlag("BevelsWaitForPlayer")
	
	if waitForPlayer then
		-- Wait for a player to spawn
		local playerSpawned = false
		
		while not playerSpawned do
			for _,player in pairs(Players:GetPlayers()) do
				if player.Character and player.Character:IsDescendantOf(workspace) then
					playerSpawned = true
					break
				end
			end
			
			workspace.ChildAdded:Wait()
		end
	end
	
	warn("Solving bevels...")
	
	-- Collect all blocks currently in the workspace.
	local initialPass = {}
	local debugHint
	
	for _,desc in pairs(workspace:GetDescendants()) do
		if canGiveBevels(desc) then
			if not desc.Locked then
				CollectionService:AddTag(desc, "DoUnlock")
				desc.Locked = true
			end
			
			table.insert(initialPass, desc)
		end
	end
	
	if waitForPlayer then	
		-- Sort the blocks by the sum of their distances from players in the game.
		local samplePoints = {}
		
		for _,player in pairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local root = char.PrimaryPart
				if root then
					local rootPos = root.Position
					table.insert(samplePoints, rootPos)
				end
			end
		end
		
		table.sort(initialPass, function (a, b)
			local distSumA = 0
			local distSumB = 0
			
			local posA = a.Position
			local posB = b.Position
			
			for _,rootPos in pairs(samplePoints) do
				local distA = (rootPos - posA).Magnitude
				distSumA = distSumA + distA
				
				local distB = (rootPos - posB).Magnitude
				distSumB = distSumB + distB
			end
			
			if distSumA ~= distSumB then
				return distSumA < distSumB
			end
			
	        if posA.Y ~= posB.Y then
	            return posA.Y < posB.Y
	        end
	       
	        if posA.X ~= posB.X then
	            return posA.X < posB.X
	        end
	       
	        if posA.Z ~= posB.Z then
	            return posA.Z < posB.Z
	        end		
	
			return 0
		end)
	end
	
	if debugMode then
		debugHint = Instance.new("Hint")
		debugHint.Text = "Generating Bevels..."
		debugHint.Parent = workspace
	end
	
	-- Run through the initial bevel creation phase.
	for _,block in ipairs(initialPass) do
		createBevels(block, true)
	end
	
	if debugHint then
		debugHint:Destroy()
	end
end

-- Listen for new parts being added.
workspace.DescendantAdded:Connect(createBevels)

-- Allow regeneration to request bevel solving
local bevelSolver = bevelCache:FindFirstChild("RequestSolve")

if not bevelSolver then
	bevelSolver = Instance.new("BindableFunction")
	bevelSolver.Name = "RequestSolve"
	bevelSolver.Parent = bevelCache
	bevelSolver.Archivable = false
end

function bevelSolver.OnInvoke(inst)
	for _,desc in pairs(inst:GetDescendants()) do
		if desc:IsA("Part") then
			createBevels(desc)
		end
	end
end

if RunService:IsStudio() then
	local exportBin = Instance.new("Folder")
	exportBin.Name = "ExportBin"
	exportBin.Parent = ServerStorage
	
	for _,v in pairs(bevelCache:GetChildren()) do
		if v:IsA("TriangleMeshPart") and v.Archivable then
			v:Clone().Parent = exportBin
		end
	end
	
	wait(.1)
	
	for _,v in pairs(exportBin:GetChildren()) do
		if v:FindFirstChild("LOD") then
			v.LOD:Destroy()
		end
	end
end

-- Ready!
warn("Bevels ready!")
bevelsReady.Value = true

------------------------------------------------------------------------------------------------