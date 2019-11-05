local RunService = game:GetService("RunService")

local ffAdorns = workspace:WaitForChild("_ForceFieldAdorns")
local registry = {}
local cycleStates = {}
local cycles = 60

local function onChildAdded(child)
	if child:IsA("SelectionBox") then
		spawn(function ()
			while not child.Adornee do
				child.Changed:Wait()
			end
			registry[child] = child.Adornee
		end)
	end
end

local function onChildRemoved(child)
	if registry[child] then
		registry[child] = nil
	end
end

local function update()
	local now = tick()
	for adorn,adornee in pairs(registry) do
		local model = adornee:FindFirstAncestorWhichIsA("Model")
		local key
		if model then
			local key = model:GetFullName()
			local startTime = cycleStates[key]
			if not startTime then
				startTime = tick()
				cycleStates[key] = startTime
			end
			local cycle = math.floor(((now-startTime)*2) * cycles) % (cycles*2)
			if cycle > cycles then
				cycle = cycles - (cycle - cycles)
			end
			local invertCycle = cycles - cycle
			adorn.Color3 = Color3.new(cycle/cycles, 0, invertCycle/cycles)
			adorn.Transparency = 0
		end
		adorn.Visible = adornee:IsDescendantOf(workspace) and adornee.LocalTransparencyModifier < 1
	end
end

for _,v in pairs(ffAdorns:GetChildren()) do
	onChildAdded(v)
end

RunService.Heartbeat:Connect(update)
ffAdorns.ChildAdded:Connect(onChildAdded)
ffAdorns.ChildRemoved:Connect(onChildRemoved)