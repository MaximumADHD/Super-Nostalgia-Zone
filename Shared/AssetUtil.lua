local MarketplaceService = game:GetService("MarketplaceService")
local InsertService = game:GetService("InsertService")

local AssetUtil =
{
	TextureCache = {};
	NUM_FETCH_RETRIES = 4;
}

local assetTypes = {}

for _,assetType in pairs(Enum.AssetType:GetEnumItems()) do
	assetTypes[assetType.Value] = assetType.Name
end

function AssetUtil:SafeCall(class, method, ...)
	local success, response
	local tries = 0
    
	while not success do
		success, response = pcall(class[method], class, ...)
		
		if not success then
			if response:find("400") then
				success = true
				response = false
			else
				tries = tries + 1
				
				if tries > self.NUM_FETCH_RETRIES then
					return false
				end
			end
		end
	end
	
	return success, response
end

function AssetUtil:Import(assetId)
	local success, model = self:SafeCall(InsertService, "LoadAsset", assetId)
    
	if success then
		local objects = model:GetChildren()
		return true, unpack(objects)
	end
    
	return false
end

function AssetUtil:RequestImage(assetId)
	assert(typeof(assetId) == "number")
	assert(assetId == math.floor(assetId))
	assert(assetId > 0)

	if self.TextureCache[assetId] == nil then
		local success, response = self:SafeCall(MarketplaceService, "GetProductInfo", assetId)
		if success then
			local result
            
			if response then
				local assetType = assetTypes[response.AssetTypeId]
                
				if assetType == "Image" then -- No transformation needed!
					result = "rbxassetid://" .. assetId
				elseif assetType == "TeeShirt" then
					local imported, shirtGraphic = self:Import(assetId)
					
					if imported then
						result = shirtGraphic.Graphic
					end
				elseif assetType == "Decal" or assetType == "Face" then
					local imported, decal = self:Import(assetId)
					
					if imported then
						result = decal.Texture
					end
				end
			else
				result = ""
			end
            
			self.TextureCache[assetId] = result
		end
	end
	
	return true, self.TextureCache[assetId]
end

return AssetUtil
