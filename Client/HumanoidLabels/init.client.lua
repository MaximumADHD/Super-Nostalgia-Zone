local humanoids = setmetatable({}, { __mode = 'k' })

local player = game.Players.LocalPlayer
local pgui = player:WaitForChild("PlayerGui")

local healthBase = script:WaitForChild("Health")
local rs = game:GetService("RunService")

local farStudsOffset = Vector3.new(0,2,0)
local closeStudsOffset = Vector3.new(0,1,0)

local farSize = UDim2.new(0, 50, 0, 20)
local closeSize = UDim2.new(0, 100, 0, 30)

local function isFinite(num)
	return num == num and num ~= -1/0 and num ~= 1/0
end

local function setupHumanoid(h)
	local updateCon = nil
	local currentHealth = nil
	
	local function onAncestryChanged()
		if updateCon then
			updateCon:disconnect()
			updateCon = nil
		end
		
		if currentHealth then
			currentHealth:Destroy()
			currentHealth = nil
		end
		
		local char = h.Parent
		
		if char then
			while not char:FindFirstChild("Head") do
				if h.Parent ~= char then break end
				char.ChildAdded:wait()
			end
			
			local head = char:FindFirstChild("Head")
			
			if head then
				local health = healthBase:Clone()
				local playerName = health:WaitForChild("PlayerName")
				local redBar = health:WaitForChild("RedBar")
				local greenBar = redBar:WaitForChild("GreenBar")
				local inOverWrite = false
				local overWriter = nil
				
				local hPlayer = game.Players:GetPlayerFromCharacter(char)
				playerName.Text = char.Name
				health.Adornee = head
				health.PlayerToHideFrom = hPlayer
				health.Parent = head
				
				local c = workspace.CurrentCamera
				
				local function update()
					local dist = (c.CFrame.p - head.Position).magnitude
					local fontSize = 12
					
					if dist < 20 then
						fontSize = 24
					elseif dist < 50 then
						fontSize = 18
					end

					local ratio = h.Health / h.MaxHealth
					redBar.Visible = isFinite(ratio)
					redBar.BackgroundTransparency = math.floor(ratio)
					redBar.Size = UDim2.new(0, fontSize * 4, 0, fontSize / 2)
					greenBar.Size = UDim2.new(ratio, 0, 1, 0)

					local width = fontSize * 4
					health.Size = UDim2.new(0, width, 0, fontSize)
					health.Enabled = (dist <= 100 and head.Transparency < 1)
					health.StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0)
					
					if hPlayer and game:FindService("Teams") then
						playerName.TextColor = hPlayer.TeamColor
					else
						playerName.TextColor3 = Color3.new(1, 1, 1)
					end
					
					local overWriter = char:FindFirstChild("NameOverwrite")
					if overWriter and overWriter:IsA("StringValue") then
						playerName.Text = overWriter.Value
					else
						playerName.Text = char.Name
					end
				end
				
				updateCon = rs.RenderStepped:Connect(update)
				currentHealth = health
				h.DisplayDistanceType = "None"
			end
		end
	end
	onAncestryChanged()
	h.AncestryChanged:Connect(onAncestryChanged)
end

for _,desc in pairs(workspace:GetDescendants()) do
	if desc:IsA("Humanoid") then
		humanoids[desc] = true
	end
end

for h in pairs(humanoids) do
	humanoids[h] = true
	
	spawn(function ()
		setupHumanoid(h)
	end)
end

local function onDescendantAdded(child)
	if child:IsA("Humanoid") then
		humanoids[child] = true
		setupHumanoid(child)
	end
end

for _,desc in pairs(workspace:GetDescendants()) do
	onDescendantAdded(desc)
end

workspace.DescendantAdded:Connect(onDescendantAdded)