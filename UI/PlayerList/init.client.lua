local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

spawn(function ()
	local StarterGui = game:GetService("StarterGui")
	StarterGui:SetCoreGuiEnabled("PlayerList", false)
	
	local player = Players.LocalPlayer
	
	local playerGui = player:WaitForChild("PlayerGui")
	playerGui:SetTopbarTransparency(1)
end)

--------------------------------------------------------------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------------------------------------------------------------

local playerStates = {}
local teamGroups = {}

local statLookup = {}
local statNames = {}

local inTeamMode = false

local basePlayerLbl = script:WaitForChild("BasePlayerLbl")
local baseGroup = script:WaitForChild("BaseGroup")
local baseStat = script:WaitForChild("BaseStat")

local playerList = script.Parent
local backdrop = playerList:WaitForChild("Backdrop")
local container = playerList:WaitForChild("Container")

local coreGroup = baseGroup:Clone()
coreGroup.Name = "Default"
coreGroup.Parent = container

local coreFooter = coreGroup.Footer
local coreHeader = coreGroup.Header

local eUpdateStatLayout = Instance.new("BindableEvent")
local updateStatLayout = eUpdateStatLayout.Event

local eUpdateTeamTotal = Instance.new("BindableEvent")
local updateTeamTotal = eUpdateTeamTotal.Event

local ePlayerTeamChanged = Instance.new("BindableEvent")
local playerTeamChanged = ePlayerTeamChanged.Event

--------------------------------------------------------------------------------------------------------------------------------------
-- Player Colors
--------------------------------------------------------------------------------------------------------------------------------------

local PLAYER_COLORS = 
{
	[0] = Color3.fromRGB(173,  35,  35); -- red
	[1] = Color3.fromRGB( 42,  75, 215); -- blue
	[2] = Color3.fromRGB( 29, 105,  20); -- green
	[3] = Color3.fromRGB(129,  38, 192); -- purple
	[4] = Color3.fromRGB(255, 146,  51); -- orange
	[5] = Color3.fromRGB(255, 238,  51); -- yellow
	[6] = Color3.fromRGB(255, 205, 243); -- pink
	[7] = Color3.fromRGB(233, 222, 187); -- tan
}

local function computePlayerColor(player)
	local pName = player.Name
	local length = #pName
	local oddShift = (1 - (length % 2))
	local value = 0
	
	for i = 1,length do
		local char = pName:sub(i,i):byte()
		local rev = (length - i) + oddShift
		if (rev % 4) >= 2 then
			value = value - char
		else
			value = value + char	
		end 
	end 
	
	return PLAYER_COLORS[value % 8]
end

--------------------------------------------------------------------------------------------------------------------------------------
-- Backdrop Handler
--------------------------------------------------------------------------------------------------------------------------------------

local isTeamMode = false
local hasStats = false

local size1x1 = Vector2.new(1,1)
local rawGroups = {}

local function onContainerChildAdded(child)
	if child:IsA("Frame") then
		local listLayout = child:WaitForChild("ListLayout",2)
		if listLayout then
			rawGroups[child] = listLayout
		end
	end
end

local function onContainerChildRemoved(child)
	if rawGroups[child] then
		rawGroups[child] = nil
	end
end

local function sortGroups(a,b)
	if a == coreGroup then
		return true
	elseif b == coreGroup then
		return false
	else
		local orderA,orderB = a.LayoutOrder,b.LayoutOrder
		if orderA == orderB then
			return a.Name < b.Name
		else
			return orderA < orderB
		end
	end
end

local function updateBackdrop()
	local groups = {}
	local at = 1
	
	for group in pairs(rawGroups) do
		if group.Visible then
			groups[at] = group
			at = at + 1
		end
	end
	
	local height = 0
	table.sort(groups,sortGroups)
	
	for i = 1,#groups do
		local group = groups[i]
		local layout = rawGroups[group]
		group.Position = UDim2.new(0,0,0,height)
		height = height + layout.AbsoluteContentSize.Y
	end
	
	if #statNames > 0 and not hasStats then
		hasStats = true
		container.AnchorPoint = Vector2.new(1,0)
		for _,group in pairs(groups) do
			group.Header.TeamUnderline.Size = UDim2.new(2,-4,0,1)
		end
		eUpdateStatLayout:Fire()
	elseif #statNames == 0 and hasStats then
		hasStats = false
		container.AnchorPoint = Vector2.new(0,0)
		for _,group in pairs(groups) do
			group.Header.TeamUnderline.Size = UDim2.new(1,-4,0,1)
		end
		eUpdateStatLayout:Fire()
	end
	
	if isTeamMode then
		height = height + coreHeader.AbsoluteSize.Y
	end
	
	local width = container.AbsoluteSize.X * (container.AnchorPoint.X+1)
	backdrop.Size = UDim2.new(0,width,0,height)
end

for _,child in pairs(container:GetChildren()) do
	onContainerChildAdded(child)
end

container.ChildAdded:Connect(onContainerChildAdded)
container.ChildRemoved:Connect(onContainerChildRemoved)
RunService.Heartbeat:Connect(updateBackdrop)

--------------------------------------------------------------------------------------------------------------------------------------
-- Header Size Stuff
--------------------------------------------------------------------------------------------------------------------------------------

local function switchHeaderMode(isTeamMode)
	if isTeamMode then
		coreHeader.Size = UDim2.new(1,0,1/3,0)
		coreHeader.Stats.Size = UDim2.new(0.75,0,1,0)
		coreHeader.Title.Size = UDim2.new(1,0,1,0)
	else
		coreHeader.Size = UDim2.new(1,0,0.4,0)
		coreHeader.Stats.Size = UDim2.new(0.75,0,0.85,0)
		coreHeader.Title.Size = UDim2.new(1,0,0.85,0)
	end
end

switchHeaderMode(false)

--------------------------------------------------------------------------------------------------------------------------------------
-- Player Stats
--------------------------------------------------------------------------------------------------------------------------------------

local function incrementStat(statName)
	if not statLookup[statName] then
		statLookup[statName] = 1
		table.insert(statNames,statName)
	else
		statLookup[statName] = statLookup[statName] + 1
	end
	eUpdateStatLayout:Fire()
end

local function decrementStat(statName)
	if statLookup[statName] then
		statLookup[statName] = statLookup[statName] - 1
		
		if statLookup[statName] == 0 then
			statLookup[statName] = nil
			for i,name in ipairs(statNames) do
				if name == statName then
					table.remove(statNames,i)
					break
				end
			end
		end
		
		eUpdateStatLayout:Fire()
	end	
end

local function getPlayerStateFromStat(stat)
	local leaderstats = stat.Parent
	if leaderstats then
		local player = leaderstats.Parent
		if player then
			return playerStates[player]
		end
	end
end

local function refreshTeamStats()
	for _,team in pairs(Teams:GetTeams()) do
		eUpdateTeamTotal:Fire(team)
	end
end

local function onStatRemoved(stat,statName)
	if stat.ClassName == "IntValue" then
		local statName = statName or stat.Name
		local playerState = getPlayerStateFromStat(stat)
		if playerState and playerState.Stats[statName] then
			playerState.Stats[statName]:Destroy()
			playerState.Stats[statName] = nil
		end
		decrementStat(statName)
		refreshTeamStats()
	end
end

local function onStatAdded(stat)
	if stat.ClassName == "IntValue" then
		local statName = stat.Name
		local playerState = getPlayerStateFromStat(stat)
		if playerState then
			local changeSignal
			
			if not playerState.Stats[statName] then
				local statLbl = baseStat:Clone()
				statLbl.Name = statName
				
				local function updateStat()
					statLbl.Text = stat.Value
					if isTeamMode then
						local team = playerState.Player.Team
						if team then
							eUpdateTeamTotal:Fire(team)
						end
					end
				end
				
				updateStat()
				changeSignal = stat.Changed:Connect(updateStat)
				
				statLbl.Parent = playerState.Label.Stats
				playerState.Stats[statName] = statLbl
			end
			
			local nameSignal do
				local function onNameChanged()
					if changeSignal then
						changeSignal:Disconnect()
						changeSignal = nil
					end
					nameSignal:Disconnect()
					nameSignal = nil
					
					-- Rebuild the stat
					onStatRemoved(stat,statName)
					onStatAdded(stat)
				end
				
				nameSignal = stat:GetPropertyChangedSignal("Name"):Connect(onNameChanged)
			end
		end
		
		incrementStat(statName)
		refreshTeamStats()
	end
end

local function onPlayerChildAdded(leaderstats)
	if leaderstats.Name == "leaderstats" then
		local player = leaderstats.Parent
		local playerState = playerStates[player]
		if playerState and not playerState.leaderstats then
			playerState.leaderstats = leaderstats
			for _,stat in pairs(leaderstats:GetChildren()) do
				onStatAdded(stat)
			end
			leaderstats.ChildAdded:Connect(onStatAdded)
			leaderstats.ChildRemoved:Connect(onStatRemoved)
		end
	end
end

local function onPlayerChildRemoved(child)
	if child.Name == "leaderstats" then
		for _,stat in pairs(child:GetChildren()) do
			onStatRemoved(stat)
		end
		for player,playerState in pairs(playerStates) do
			if playerState.leaderstats == child then
				playerState.leaderstats = nil
				break
			end
		end
	end
end

local function updateStatLbl(statLbl,index)
	statLbl.Size = UDim2.new(1/#statNames,0,1,0)
	statLbl.Position = UDim2.new((index-1)/#statNames)	
end

local function onUpdateStatLayout()
	local statBin = coreHeader.Stats
	
	for _,statLbl in pairs(statBin:GetChildren()) do
		if statLbl:IsA("TextLabel") and not statLookup[statLbl.Name] then
			statLbl:Destroy()
		end
	end

	for i,statName in pairs(statNames) do
		local statLbl = statBin:FindFirstChild(statName)
		if not statLbl then
			statLbl = baseStat:Clone()
			statLbl.Name = statName
			statLbl.Text = statName
			statLbl.Parent = statBin
		end
		updateStatLbl(statLbl,i)
	end
	
	for player,playerState in pairs(playerStates) do
		for statName,statLbl in pairs(playerState.Stats) do
			if not statLookup[statName] then
				statLbl:Destroy()
				playerState.Stats[statName] = nil
			end
		end

		for i,statName in pairs(statNames) do
			local statLbl = playerState.Stats[statName]
			if statLbl then
				if player.Team then
					statLbl.TextColor = player.Team.TeamColor
				else
					statLbl.TextColor3 = Color3.new(1,1,1)
				end
				updateStatLbl(statLbl,i)
			end
		end
	end
	
	isTeamMode = (#Teams:GetTeams() > 0)
	
	if isTeamMode then
		coreHeader.Visible = hasStats
		coreHeader.Title.Text = "Team"
	else
		coreHeader.Visible = true
		if hasStats then
			coreHeader.Title.Text = "Players"
		else
			coreHeader.Title.Text = "Player List"
		end
	end
	
	switchHeaderMode(isTeamMode)
end

updateStatLayout:Connect(onUpdateStatLayout)

--------------------------------------------------------------------------------------------------------------------------------------
-- Player States
--------------------------------------------------------------------------------------------------------------------------------------

local function onPlayerAdded(player)
	local playerState = {}
	local name = player.Name
	
	local lbl = basePlayerLbl:Clone()
	lbl.Name = name
	lbl.PlayerName.Text = name
	lbl.PlayerName.TextColor3 = computePlayerColor(player)
	lbl.Parent = coreGroup
	
	playerState.Player = player
	playerState.Label = lbl
	playerState.Stats = {}
	playerStates[player] = playerState
	
	for _,child in pairs(player:GetChildren()) do
		onPlayerChildAdded(child)
	end
	
	player.ChildAdded:Connect(onPlayerChildAdded)
	player.ChildRemoved:Connect(onPlayerChildRemoved)
	
	player.Changed:Connect(function (property)
		if property == "Team" then
			ePlayerTeamChanged:Fire(player)
		end
	end)

	ePlayerTeamChanged:Fire(player)
end

local function onPlayerRemoved(player)
	local state = playerStates[player]
	playerStates[player] = nil
	
	if state and state.Label then
		state.Label:Destroy()
	end
end

for _,player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoved)

--------------------------------------------------------------------------------------------------------------------------------------
-- Teams
--------------------------------------------------------------------------------------------------------------------------------------

local function neutralizePlayer(player)
	local playerState = playerStates[player]
	if playerState then
		local playerLbl = playerState.Label
		playerLbl.PlayerName.Text = player.Name
		playerLbl.PlayerName.TextColor3 = computePlayerColor(player)
		playerLbl.PlayerName.Position = UDim2.new(0,0,0,0)
		for stat,statLbl in pairs(playerState.Stats) do
			statLbl.TextColor3 = Color3.new(1,1,1)
		end
		playerLbl.Visible = (not isTeamMode)
		playerLbl.Parent = coreGroup
	end
end

local function onPlayerAddedToTeam(player)
	local team = player.Team
	local group = teamGroups[team]
	if group then
		local playerState = playerStates[player]
		if playerState then
			local playerLbl = playerState.Label
			playerLbl.PlayerName.TextColor = team.TeamColor
			playerLbl.PlayerName.Position = UDim2.new(0,4,0,0)
			for stat,statLbl in pairs(playerState.Stats) do
				statLbl.TextColor = team.TeamColor
			end
			playerLbl.Parent = group
			playerLbl.Visible = true
			eUpdateStatLayout:Fire()
			refreshTeamStats()
		end
	end
end

local function onPlayerRemovedFromTeam(player)
	if not player.Team then
		neutralizePlayer(player)
		refreshTeamStats()
	end
end

local function onUpdateTeamTotal(team)
	local teamGroup = teamGroups[team]
	if teamGroup then
		local teamStats = teamGroup.Header.Stats
		local totals = {}
		
		for i,statName in ipairs(statNames) do
			local total = totals[i]
			if not total then
				total = { Name = statName, Value = 0 }
				totals[i] = total
			end
			for _,player in pairs(team:GetPlayers()) do
				local playerState = playerStates[player]
				if playerState then
					local leaderstats = playerState.leaderstats
					if leaderstats then
						local stat = leaderstats:FindFirstChild(statName)
						if stat then
							total.Value = total.Value + stat.Value
						end
					end
				end
			end
		end
		
		local numStats = #statNames
		
		for i,statRecord in ipairs(totals) do
			local statName = statRecord.Name
			local statLbl = teamStats:FindFirstChild(statName)
			if not statLbl then
				statLbl = baseStat:Clone()
				statLbl.Name = statName
				statLbl.TextColor = team.TeamColor
				statLbl.TextStrokeTransparency = 0.5
				statLbl.Parent = teamStats
			end
			statLbl.Text = statRecord.Value
			updateStatLbl(statLbl,i)
		end
		
		for _,statLbl in pairs(teamStats:GetChildren()) do
			if not statLookup[statLbl.Name] then
				statLbl:Destroy()
			end
		end
	end
end

local function onTeamAdded(team)
	if team.ClassName == "Team" then
		local teamGroup = baseGroup:Clone()
		teamGroup.Name = team.Name
		teamGroup.Footer.Visible = true
		
		local teamHeader = teamGroup.Header
		
		local teamUnderline = teamHeader.TeamUnderline
		teamUnderline.Visible = true
		teamUnderline.BackgroundColor = team.TeamColor
		
		if hasStats then
			teamUnderline.Size = teamUnderline.Size + UDim2.new(1,0,0,0)
		end
		
		local teamTitle = teamHeader.Title
		teamTitle.Text = team.Name
		teamTitle.TextColor = team.TeamColor
		teamTitle.TextStrokeTransparency = 0.5
		
		teamGroup.Parent = container
		teamGroups[team] = teamGroup
		
		for _,player in pairs(team:GetPlayers()) do
			onPlayerAddedToTeam(player)
		end
		
		eUpdateTeamTotal:Fire(team)
		eUpdateStatLayout:Fire()
	end
	if #Teams:GetTeams() > 0 and not isTeamMode then
		isTeamMode = true
		for _,player in pairs(Players:GetPlayers()) do
			if not player.Team then
				neutralizePlayer(player)
			end
		end
	end
end

local function onTeamRemoved(team)
	if teamGroups[team] then
		for _,player in pairs(Players:GetPlayers()) do
			if player.TeamColor == team.TeamColor then
				neutralizePlayer(player)
			end
		end
		teamGroups[team]:Destroy()
		teamGroups[team] = nil
		eUpdateStatLayout:Fire()
	end
	if #Teams:GetTeams() == 0 then
		isTeamMode = false
		for _,player in pairs(Players:GetPlayers()) do
			neutralizePlayer(player)
		end
	end
end

local function onPlayerTeamChange(player)
	local team = player.Team
	if team then
		onPlayerAddedToTeam(player)
	else
		onPlayerRemovedFromTeam(player)
	end
end

for _,team in pairs(Teams:GetTeams()) do
	onTeamAdded(team)
end

for _,player in pairs(Players:GetPlayers()) do
	onPlayerTeamChange(player)
end

Teams.ChildAdded:Connect(onTeamAdded)
Teams.ChildRemoved:Connect(onTeamRemoved)
updateTeamTotal:Connect(onUpdateTeamTotal)
playerTeamChanged:Connect(onPlayerTeamChange)

--------------------------------------------------------------------------------------------------------------------------------------