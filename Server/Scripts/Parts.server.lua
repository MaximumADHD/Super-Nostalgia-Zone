local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local brickColors = require(ReplicatedStorage:WaitForChild("BrickColors"))
local oldColors = {}

for _,v in ipairs(brickColors) do
	oldColors[v] = true
end

local textureCaches = {}
local colorCaches = {}

local char = string.char
local floor = math.floor
local clamp = math.clamp

local function serializeColor3(color)
	local r = clamp(floor(color.r * 256), 0, 255)
	local g = clamp(floor(color.g * 256), 0, 255)
	local b = clamp(floor(color.b * 256), 0, 255)
	return r .. g .. b
end

local function computeEpsilon(bc, color)
	local bColor = bc.Color
	
	local v0 = Vector3.new(bColor.r, bColor.g, bColor.b)
	local v1 = Vector3.new(color.r, color.g, color.b)
	
	return (v1-v0).Magnitude
end

local function toNearestOldBrickColor(color)
	local colorKey = serializeColor3(color)
	
	if not colorCaches[colorKey] then
		local bestColor, bestEpsilon = nil, math.huge
		
		for bcName in pairs(oldColors) do
			local bc = BrickColor.new(bcName)
			local epsilon = computeEpsilon(bc, color)
			
			if epsilon < bestEpsilon then
				bestEpsilon = epsilon
				bestColor = bc
			end
		end
		
		colorCaches[colorKey] = bestColor
	end
	
	return colorCaches[colorKey]
end

local function onBrickColorUpdated(part)
	part.BrickColor = toNearestOldBrickColor(part.Color)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local scale = 1

if ServerStorage:FindFirstChild("StudScale") then
	scale = ServerStorage.StudScale.Value
end

local surfaces = 
{
	TopSurface    = "Top";
	BottomSurface = "Bottom";
	LeftSurface   = "Left"; 
	RightSurface  = "Right"; 
	FrontSurface  = "Front"; 
	BackSurface   = "Back";
}

local textures = 
{
	Studs = 3309082834;
	Inlet = 3307955447;
	Glue  = 3308133326;
	Weld  = 3308005654;
}

local normalIdToAxis =
{
	Left   = 'X';
	Right  = 'X';
	Top    = 'Y';
	Bottom = 'Y';
	Front  = 'Z';
	Back   = 'Z';
}

local function selectUVSize(part, normalId)
	if typeof(normalId) == "EnumItem" then
		normalId = normalId.Name
	end
	
	local axis = normalIdToAxis[normalId]
	local size = part.Size
	
	if axis == 'X' then
		return size.Z, size.Y
	elseif axis == 'Z' then
		return size.X, size.Y
	elseif axis == 'Y' then
		return size.X, size.Z
	end
end

local function onSurfaceChanged(part, surface)
	local surfaceId = part[surface].Name
	
	if surfaceId ~= "SmoothNoOutlines" then
		local normalId = surfaces[surface]
		local textureId = textures[surfaceId]
		
		local cache = textureCaches[part]
		local texture = cache[surface]
		
		if not textureId then
			if texture then
				texture.Texture = ""
			end
			
			return
		end
		
		if not (texture and texture:IsA("Texture")) then
			texture = Instance.new("Texture")
			cache[surface] = texture
			
			texture.StudsPerTileU = 2;
			texture.StudsPerTileV = 4;
			
			texture.Face = normalId
			texture.Name = surface
			
			texture.Parent = part
		end
		
		-- Select the texture id based on the even/odd dimensions of the UV map.
		local mapId = "AA"
		
		if part:IsA("MeshPart") then
			local texU, texV = selectUVSize(part, normalId)
			
			local alignU = string.format("%i", (texU % 2) + .5)
			local alignV = string.format("%i", (texV % 2) + .5)
			
			if alignU == '1' then
				texture.OffsetStudsU = 0.5
			end
			
			if alignV == '1' then
				texture.OffsetStudsV = 0.5
			end
		end
		
		texture.Texture = "rbxassetid://" .. textureId
	end
end

local function onTransparencyChanged(part)
	local textureCache = textureCaches[part]
	
	for _,texture in pairs(textureCache) do
		texture.Transparency = 0.25 + (part.Transparency * 0.75)
	end
end

local function onParentChanged(part)
	local texureCache = textureCaches[part]
	
	if not part:IsDescendantOf(workspace) then
		for _,tex in pairs(texureCache) do
			tex:Destroy()
		end
		
		texureCache[part] = nil
	end
end
	
local function registerPartSurfaces(part)
	local textureCache = {}
	textureCaches[part] = textureCache
	
	for surface in pairs(surfaces) do
		onSurfaceChanged(part, surface)
	end
	
	onBrickColorUpdated(part)
	onTransparencyChanged(part)
	
	part.Material = "SmoothPlastic"
end

local function applyCharacter(humanoid)
	local model = humanoid.Parent
	
	if not CollectionService:HasTag(humanoid, "Classified") then
		local characterAssets = ServerStorage.CharacterAssets 
		CollectionService:AddTag(humanoid, "Classified")
		
		for _,v in pairs(model:GetDescendants()) do
			if v:IsA("SpecialMesh") and v.MeshType == Enum.MeshType.Brick then
				v:Destroy()
			end
		end
		
		for _,child in pairs(characterAssets:GetChildren()) do
			if child:IsA("CharacterMesh") then
				local copy = child:Clone()
				copy.Parent = model
				CollectionService:AddTag(copy, "NoCharacterBevels")
			end
		end
		
		delay(1, function ()
			if not model:FindFirstChildWhichIsA("Shirt") then
				characterAssets.Shirt:Clone().Parent = model
			end
			
			if not model:FindFirstChildWhichIsA("Pants") then
				characterAssets.Pants:Clone().Parent = model
			end
		end)
	end	
end

local function onDescendantAdded(desc)
	if desc:IsA("BasePart") then
		local model = desc:FindFirstAncestorWhichIsA("Model")
		
		if model then
			local humanoid = model:FindFirstChildWhichIsA("Humanoid")
			
			if humanoid then
				applyCharacter(humanoid)
				return
			end
			
			local fileMesh = desc:FindFirstChildWhichIsA("FileMesh")
			
			if fileMesh then
				local meshType = fileMesh.MeshType.Name
				if meshType == "Head" or meshType == "FileMesh" then
					desc.Material = "SmoothPlastic"
					return
				end
			end
			
			if desc:IsA("VehicleSeat") then
				desc.HeadsUpDisplay = false
			end
			
			if not CollectionService:HasTag(desc, "NoBevels") then
				registerPartSurfaces(desc)
			end
		end
	elseif desc:IsA("Decal") and desc.Texture:lower() == "rbxasset://textures/spawnlocation.png" then
		desc.Texture = "rbxassetid://989514407"
	elseif desc:IsA("Humanoid") then
		applyCharacter(desc)
	end
end

local function onItemChanged(object, descriptor)
	if textureCaches[object] then
		if surfaces[descriptor] then
			onSurfaceChanged(object, descriptor)
		elseif descriptor == "Transparency" then
			onTransparencyChanged(object)
		elseif descriptor == "BrickColor" then
			onBrickColorUpdated(object)
		elseif descriptor == "Parent" then
			onParentChanged(object)
		end
	end
end

for _,desc in pairs(workspace:GetDescendants()) do
	onDescendantAdded(desc)
end

workspace.DescendantAdded:Connect(onDescendantAdded)
game.ItemChanged:Connect(onItemChanged)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

