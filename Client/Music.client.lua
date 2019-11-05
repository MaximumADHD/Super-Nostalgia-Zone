local TeleportService = game:GetService("TeleportService")
local gameMusic = workspace:WaitForChild("GameMusic",10)
if gameMusic and TeleportService:GetTeleportSetting("AllowMusic") then
	gameMusic:Play()
end