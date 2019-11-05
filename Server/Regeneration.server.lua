local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local regen = ServerStorage:FindFirstChild("Regeneration")

if regen then
	local REGEN_TIME = 800
	local REGEN_DELAY = 4
	
	if regen:FindFirstChild("RegenTime") then
		REGEN_TIME = regen.RegenTime.Value
	end
	
	if regen:FindFirstChild("RegenDelay") then
		REGEN_DELAY = regen.RegenDelay.Value
	end
	
	local ready = Instance.new("BoolValue")
	ready.Name = "Ready"
	ready.Parent = regen
	
	local bevelCache = ServerStorage:WaitForChild("BevelCache")
	local bevelsReady = bevelCache:WaitForChild("BevelsReady")
	
	local function isLodPart(part)
		return part and CollectionService:HasTag(part, "PartLOD")
	end
	
	local function setupModelRegen(model, title)
		local title = title or model.Name
		
		local parent = model.Parent
		local backup = model:Clone()
		
		local message, text
		
		if typeof(title) == "string" then
			message = Instance.new("Message")
			text = "Regenerating " .. title .. "..."
		end
		
		spawn(function ()
			while not bevelsReady.Value do
				bevelsReady.Changed:Wait()
			end
			
			local requestSolve = bevelCache:FindFirstChild("RequestSolve")
			if requestSolve then
				requestSolve:Invoke(backup)
			end
			
			while wait(REGEN_TIME * (1 - (math.random() * .8))) do
				local cooldown = 0
				
				if message then
					message.Text = text
					message.Parent = workspace
				end
				
				model:Destroy()
				wait(REGEN_DELAY)
				
				model = backup:Clone()
				model.Parent = parent
				
				for _,inst in pairs(model:GetDescendants()) do
					if inst:IsA("BasePart") then
						workspace:JoinToOutsiders({inst}, Enum.JointCreationMode.All)
					end
				end
				
				for _,joint in pairs(model:GetDescendants()) do
					if joint:IsA("JointInstance") and joint.Name:sub(-12) == "Strong Joint" then
						if isLodPart(joint.Part0) or isLodPart(joint.Part1) then
							joint:Destroy()
						end
					end
				end
				
				if message then
					message.Parent = nil
				end
			end
		end)
	end
	
	for _,v in pairs(regen:GetChildren()) do
		if v:IsA("ObjectValue") then
			if v.Name == "" then
				setupModelRegen(v.Value, true)
			else
				setupModelRegen(v.Value, v.Name)
			end
		end
	end
	
	ready.Value = true
end