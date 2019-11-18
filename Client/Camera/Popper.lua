-- PopperCam Version 16
-- OnlyTwentyCharacters

local PopperCam = {} -- Guarantees your players won't see outside the bounds of your map!

-----------------
--| Constants |--
-----------------

local POP_RESTORE_RATE = 0.3
local MIN_CAMERA_ZOOM = 0.5

local VALID_SUBJECTS = 
{
	'Humanoid',
	'VehicleSeat',
	'SkateboardPlatform',
}

-----------------
--| Variables |--
-----------------

local Players = game:GetService('Players')

local Camera = nil
local CameraSubjectChangeConn = nil

local SubjectPart = nil

local PlayerCharacters = {} -- For ignoring in raycasts
local VehicleParts = {} -- Also just for ignoring

local LastPopAmount = 0
local LastZoomLevel = 0
local PopperEnabled = true

local CFrame_new = CFrame.new

-----------------------
--| Local Functions |--
-----------------------

local math_abs = math.abs

local function OnCharacterAdded(player, character)
	PlayerCharacters[player] = character
end

local function OnPlayersChildAdded(child)
	if child:IsA('Player') then
		child.CharacterAdded:connect(function(character)
			OnCharacterAdded(child, character)
		end)
		if child.Character then
			OnCharacterAdded(child, child.Character)
		end
	end
end

local function OnPlayersChildRemoved(child)
	if child:IsA('Player') then
		PlayerCharacters[child] = nil
	end
end

-------------------------
--| Exposed Functions |--
-------------------------

function PopperCam:Update()
	if PopperEnabled then
		-- First, prep some intermediate vars
		local Camera = workspace.CurrentCamera

		if Camera.CameraType.Name == "Fixed" then
			return
		end
		
		local cameraCFrame = Camera.CFrame
		local focusPoint = Camera.Focus.p

		if SubjectPart then
			focusPoint = SubjectPart.CFrame.p
		end

		local ignoreList = {}
		for _, character in pairs(PlayerCharacters) do
			ignoreList[#ignoreList + 1] = character
		end
		for i = 1, #VehicleParts do
			ignoreList[#ignoreList + 1] = VehicleParts[i]
		end
		
		-- Get largest cutoff distance
		local largest = Camera:GetLargestCutoffDistance(ignoreList)

		-- Then check if the player zoomed since the last frame,
		-- and if so, reset our pop history so we stop tweening
		local zoomLevel = (cameraCFrame.p - focusPoint).Magnitude
		if math_abs(zoomLevel - LastZoomLevel) > 0.001 then
			LastPopAmount = 0
		end
		
		-- Finally, zoom the camera in (pop) by that most-cut-off amount, or the last pop amount if that's more
		local popAmount = largest
		if LastPopAmount > popAmount then
			popAmount = LastPopAmount
		end

		if popAmount > 0 then
			Camera.CFrame = cameraCFrame + (cameraCFrame.lookVector * popAmount)
			LastPopAmount = popAmount - POP_RESTORE_RATE -- Shrink it for the next frame
			if LastPopAmount < 0 then
				LastPopAmount = 0
			end
		end

		LastZoomLevel = zoomLevel
	end
end

--------------------
--| Script Logic |--
--------------------


-- Connect to all Players so we can ignore their Characters
Players.ChildRemoved:connect(OnPlayersChildRemoved)
Players.ChildAdded:connect(OnPlayersChildAdded)
for _, player in pairs(Players:GetPlayers()) do
	OnPlayersChildAdded(player)
end

return PopperCam