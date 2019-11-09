local ffAdorns = Instance.new("Folder")
ffAdorns.Name = "_ForceFieldAdorns"
ffAdorns.Parent = workspace

local hide = false
if game.ServerStorage:FindFirstChild("HideForceFields") then
	hide = true
end

local ignoreNames = 
{
	HumanoidRootPart = true;
	DebugAdorn = true;
	NoForceField = true;
}

local function onDescendantAdded(desc)
	if desc:IsA("ForceField") then
		desc.Visible = false
		if hide then return end
		
		local adorns = {}
		local char = desc.Parent
		
		local function registerAdorn(child)
			if child:IsA("BasePart") and not ignoreNames[child.Name] then
				local adorn = Instance.new("SelectionBox")
				adorn.Transparency = 1
				adorn.Adornee = child
				adorn.Parent = ffAdorns
				table.insert(adorns,adorn)
			end
		end
		
		for _,part in pairs(char:GetDescendants()) do
			registerAdorn(part)
		end
		
		local regSignal = char.DescendantAdded:Connect(registerAdorn)
		
		
		while desc:IsDescendantOf(workspace) do
			desc.AncestryChanged:Wait()
		end
		
		for _,adorn in pairs(adorns) do
			adorn:Destroy()
		end
		
		adorns = nil
		regSignal:Disconnect()
		
	end
end

for _,v in pairs(workspace:GetDescendants()) do
	onDescendantAdded(v)
end

workspace.DescendantAdded:Connect(onDescendantAdded)