local CollectionService = game:GetService("CollectionService")

local cylinderSurface = script:WaitForChild("CylinderSurface")
local cylinderListener = CollectionService:GetInstanceAddedSignal("Cylinder")

local min, max = math.min, math.max

local function makeCylinderSurface(part, sizeUpdated)
	local surface = cylinderSurface:Clone()
	surface.Parent = part
	surface.Adornee = part
	surface.Archivable = false
	
	local lastSize = Vector3.new()
	
	local function onSizeUpdated()
		local size = part.Size
		if size ~= lastSize then
			local scale = min(size.Y, size.Z)
			surface.CanvasSize = Vector2.new(max(100, scale * 100), max(100, scale * 100))
			lastSize = size
		end
	end
	
	onSizeUpdated()
	sizeUpdated:Connect(onSizeUpdated)

	return surface
end

local function bindCylinder(part)
	if not part:IsA("Part") then
		return
	end
	
	local sizeUpdated = part:GetPropertyChangedSignal("Size")
	part.Shape = "Ball"
	part:MakeJoints()
	
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshId = "rbxassetid://1009010722"
	mesh.Archivable = false
	mesh.Parent = part
	
	local leftSurface = makeCylinderSurface(part, sizeUpdated)
	leftSurface.Face = "Left"
	
	local rightSurface = makeCylinderSurface(part, sizeUpdated)
	rightSurface.Face = "Right"
	
	local function onSizeUpdated()
		local size = part.Size
		local scale = math.min(size.Y,size.Z)
		mesh.Scale = Vector3.new(scale,scale,scale)
	end
	
	onSizeUpdated()
	sizeUpdated:Connect(onSizeUpdated)
end

local function findCylinder(obj)
	if obj:IsA("Part") and obj.Shape == Enum.PartType.Cylinder then
		CollectionService:AddTag(obj, "Cylinder")
	end
end

for _, obj in pairs(workspace:GetDescendants()) do
	findCylinder(obj)
end

for _, cylinder in pairs(CollectionService:GetTagged("Cylinder")) do
	bindCylinder(cylinder)
end

workspace.DescendantAdded:Connect(findCylinder)
cylinderListener:Connect(bindCylinder)
