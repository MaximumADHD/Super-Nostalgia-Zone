local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

while RunService.RenderStepped:Wait() do
	if TeleportService:GetTeleportSetting("FPSCapTo30") then
		local t0 = tick()
		RunService.Heartbeat:Wait()

		debug.profilebegin("30 FPS Cap")
		repeat until (t0 + 0.0325) < tick()
		
		debug.profileend()
	end
end