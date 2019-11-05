local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")

local noBevelsTag = "NoCharacterBevels"
local bevelTracker = CollectionService:GetInstanceAddedSignal(noBevelsTag)

local function safeDestroy(obj)
	spawn(function ()
		obj:Destroy()
	end)
end

local function onInstanceAdded(inst)
	if TeleportService:GetTeleportSetting("CharacterBevels") then
		safeDestroy(inst)
	end
end

for _,inst in pairs(CollectionService:GetTagged(noBevelsTag)) do
	onInstanceAdded(inst)
end

bevelTracker:Connect(onInstanceAdded)


