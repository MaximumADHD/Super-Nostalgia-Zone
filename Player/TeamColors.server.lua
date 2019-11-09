local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local char = script.Parent
local player = Players:GetPlayerFromCharacter(char)
local teamListener = player:GetPropertyChangedSignal("TeamColor")
local bodyColors = char:WaitForChild("BodyColors")

local teamColors = Instance.new("BodyColors")
teamColors.Name = "TeamColors"
teamColors.HeadColor = BrickColor.new("Bright yellow")
teamColors.LeftArmColor = BrickColor.Black()
teamColors.LeftLegColor = BrickColor.Black()
teamColors.RightArmColor = BrickColor.Black()
teamColors.RightLegColor = BrickColor.Black()

CollectionService:AddTag(teamColors, "RespectCharacterAsset")

local function onTeamChanged()
	local team = player.Team
	if team then
		teamColors.TorsoColor = player.TeamColor
		bodyColors.Parent = nil
		
		if not CollectionService:HasTag(team, "NoAutoColor") then
			teamColors.Parent = char
		end
	else
		teamColors.Parent = nil
		bodyColors.Parent = char
	end
end

onTeamChanged()
teamListener:Connect(onTeamChanged)