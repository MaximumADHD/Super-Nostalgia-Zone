local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled("All", false)

local health = script.Parent
local healthBar = health:WaitForChild("HealthBar")
local healthGauge = healthBar:WaitForChild("HealthGauge")

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

if camera.ViewportSize.Y < 600 then
	local scale = Instance.new("UIScale")
	scale.Scale = 0.6
	scale.Parent = health
end

local function onCharacterAdded(char)
	local humanoid = char:WaitForChild("Humanoid")
	
	local function updateHealth(health)
		healthGauge.Size = UDim2.new(1, 0, health / humanoid.MaxHealth, 0)
	end
	
	updateHealth(humanoid.MaxHealth)
	humanoid.HealthChanged:Connect(updateHealth)
	
	health.Visible = true
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)