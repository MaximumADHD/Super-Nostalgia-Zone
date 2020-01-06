local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Teams = game:GetService("Teams")

local FlagInstance = "FlagInstance"
local FlagStandInstance = "FlagStandInstance"

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Flags
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function restoreFlag(flag)
	local owner = flag:FindFirstChild("FlagStand")
	local flagStand = owner and owner.Part0
	
	if owner and flagStand then
		print("deleting grip")

		for _,joint in pairs(flag:GetJoints()) do
			if joint.Name == "RightGrip" then
				joint:Destroy()
			end
		end
		
		print("restoring name")

		if flag.Name == "Handle" then
			local tool = flag.Parent
			if tool:IsA("Tool") then
				flag.Name = tool.Name
				tool.Parent = nil
			end
		end
		
		print("restoring flag")

		flag.Anchored = true
		flag.CanCollide = true
		flag.Parent = flagStand.Parent
		
		flag.CFrame = flagStand.CFrame
			* CFrame.new(0, flagStand.Size.Y / 2, 0)
			* CFrame.new(0, flag.Size.Y / 2, 0)
		
		flag.Velocity = Vector3.new()
		flag.RotVelocity = Vector3.new()

		wait()

		owner.Enabled = true
		flag.Anchored = false

		print("done!")
	end	
end

local function mountFlagAsTool(flag, humanoid)
	local owner = flag:FindFirstChild("FlagStand")
	local teamColor = flag:FindFirstChild("TeamColor")
	
	if not (owner and teamColor) or flag.Name == "Handle" then
		return
	end
	
	local grip = CFrame.new(0.25, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0)
	
	local tool = Instance.new("Tool")
	tool.Name = flag.Name
	tool.Grip = grip
		
	local deathCon
	
	local function onDied()
		local char = humanoid.Parent
		
		if char and tool.Parent == char then
			humanoid:UnequipTools()
		end
		
		if deathCon then
			deathCon:Disconnect()
			deathCon = nil
		end
	end
	
	local function onUnequipped()
		if deathCon then
			deathCon:Disconnect()
			deathCon = nil
		end
		
		if humanoid then
			local rootPart = humanoid.RootPart
			
			if rootPart then
				local cf = rootPart.CFrame * CFrame.new(0, 4, -8)
				flag.RotVelocity = Vector3.new(1, 1, 1)
				flag.Position = cf.Position
			end
		end
		
		if flag.Parent == tool then
			flag.Parent = workspace
		end
		
		flag.Name = tool.Name
		
		spawn(function ()
			tool:Destroy()
		end)
	end
	
	tool.Unequipped:Connect(onUnequipped)
	CollectionService:AddTag(tool, "Flag")
	
	tool.Parent = workspace
	owner.Enabled = false
	
	flag.Name = "Handle"
	flag.Parent = tool
	
	humanoid:EquipTool(tool)
	deathCon = humanoid.Died:Connect(onDied)
end

local function onFlagAdded(flag)
	if not flag:IsA("BasePart") then
		return
	end
	
	-- Mount TeamColor
	local teamColor = flag:FindFirstChild("TeamColor")
	local flagBackup
	
	if not teamColor then
		teamColor = Instance.new("BrickColorValue")
		teamColor.Value = flag.BrickColor
		teamColor.Name = "TeamColor"
		teamColor.Parent = flag
	end
	
	-- Mount FlagStand
	local flagStand, owner
	
	for _,part in pairs(flag:GetConnectedParts()) do
		if CollectionService:HasTag(part, FlagStandInstance) then
			flagStand = part
			break
		end
	end
	
	if flagStand then
		owner = Instance.new("WeldConstraint")
		owner.Name = "FlagStand"
		owner.Part0 = flagStand
		owner.Parent = flag
		
		for _,joint in pairs(flag:GetJoints()) do
			if joint ~= owner then
				joint:Destroy()
			end
		end
		
		owner.Part1 = flag
		CollectionService:AddTag(owner, "GorillaGlue")
	end

	local function onTouched(hit)
		local char = hit.Parent
		if char then
			local player = Players:GetPlayerFromCharacter(char)
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			
			if player and humanoid then
				if player.Neutral then
					return
				end
				
				if player.TeamColor == teamColor.Value then
					if owner and owner.Part1 ~= flag then
						restoreFlag(flag)
					elseif owner == nil then
						flag = nil
					end
				else
					mountFlagAsTool(flag, humanoid)
				end
			end
		end
	end
	
	spawn(function ()
		local deathPlane = workspace.FallenPartsDestroyHeight

		while wait() do
			-- Try to keep the flag from falling out of the world.
			if not flagBackup then
				flagBackup = flag:Clone()
			end

			local resetClock = 400
			flag.Touched:Connect(onTouched)
			
			while flag:IsDescendantOf(workspace) do
				if flag.Position.Y < deathPlane + 200 then
					local tool = flag.Parent
					
					if tool:IsA("Tool") then
						tool.Parent = workspace
						wait()
					end
					
					restoreFlag(flag)
				end

				if (flag and owner) and not owner.Enabled and not flag.Parent:IsA("Tool") then
					resetClock = resetClock - 1
					
					if resetClock <= 0 then
						restoreFlag(flag)
						resetClock = 400
					end
				else
					resetClock = 400
				end

				wait()
			end

			flag:Destroy()
			
			flag = flagBackup:Clone()
			flag.Parent = workspace
			
			owner = flag.FlagStand
			restoreFlag(flag)
			
			wait()
		end
	end)
end

for _,flag in pairs(CollectionService:GetTagged(FlagInstance)) do
	onFlagAdded(flag)
end

local flagAdded = CollectionService:GetInstanceAddedSignal(FlagInstance)
flagAdded:Connect(onFlagAdded)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Flag Stands
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function onFlagStandAdded(flagStand)
	if not flagStand:IsA("BasePart") then
		return
	end
	
	local debounce = false
	local teamColor = flagStand:FindFirstChild("TeamColor")
	local flagCaptured = flagStand:FindFirstChild("FlagCaptured")
	
	if not teamColor then
		teamColor = Instance.new("BrickColorValue")
		teamColor.Value = flagStand.BrickColor
		teamColor.Name = "TeamColor"
		teamColor.Parent = flagStand
	end
	
	if not flagCaptured then
		flagCaptured = Instance.new("BindableEvent")
		flagCaptured.Name = "FlagCaptured"
		flagCaptured.Parent = flagStand
	end
	
	local function onTouched(hit)
		if debounce then
			return
		end
		
		local char = hit.Parent
		if char then
			local player = Players:GetPlayerFromCharacter(char)
			if player then 
				if player.Neutral then
					return
				end
				
				if player.TeamColor ~= teamColor.Value then
					return
				end
				
				local tool = char:FindFirstChildOfClass("Tool")
				local handle = tool and tool:FindFirstChild("Handle")
				
				if handle and CollectionService:HasTag(handle, FlagInstance) then
					debounce = true
					print("flag captured!")
					
					flagCaptured:Fire(player)
					restoreFlag(handle)
					
					tool:Destroy()
					wait(1)
					
					debounce = false
				end
			end
		end
	end
	
	flagStand.Touched:Connect(onTouched)
end

local function onFlagStandRemoved(flagStand)
	local teamColor = flagStand:FindFirstChild("TeamColor")
	local flagCaptured = flagStand:FindFirstChild("FlagCaptured")
	
	if teamColor then
		teamColor:Destroy()
	end
	
	if flagCaptured then
		flagCaptured:Destroy()
	end
end

for _,flagStand in pairs(CollectionService:GetTagged(FlagStandInstance)) do
	onFlagStandAdded(flagStand)
end

local flagStandAdded = CollectionService:GetInstanceAddedSignal(FlagStandInstance)
flagStandAdded:Connect(onFlagStandAdded)

local flagStandRemoved = CollectionService:GetInstanceRemovedSignal(FlagStandInstance)
flagStandRemoved:Connect(onFlagStandRemoved)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------