local handle = script.Parent
local hat = handle:FindFirstChildWhichIsA("Accoutrement")
local equipSignal

local function onTouched(hit)
	local char = hit:FindFirstAncestorWhichIsA("Model")
	
	if char then
		local hitHum = char:FindFirstChild("Humanoid")
		
		if hitHum then
			local existingHat = char:FindFirstChildWhichIsA("Accoutrement")
			
			if existingHat == nil or existingHat == hat then
				if equipSignal then
					equipSignal:Disconnect()
					equipSignal = nil
				end
				
				hat.Parent = workspace
				handle.Parent = hat
				
				handle:SetNetworkOwnershipAuto()
				hitHum:AddAccessory(hat)
				
				script:Destroy()
			else
				hat.Parent = workspace
			end
		end
	end
end

equipSignal = handle.Touched:Connect(onTouched)	