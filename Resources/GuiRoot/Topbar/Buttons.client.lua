local topbar = script.Parent

local function registerButton(btn)
	if btn:IsA("TextButton") and btn.Active then
		local function onMouseEnter()
			btn.BackgroundTransparency = 0
		end
		
		local function onMouseLeave()
			btn.BackgroundTransparency = 0.5
		end
		
		btn.MouseEnter:Connect(onMouseEnter)
		btn.MouseLeave:Connect(onMouseLeave)
	end
end

for _,v in pairs(topbar:GetChildren()) do
	registerButton(v)
end

topbar.ChildAdded:Connect(registerButton)