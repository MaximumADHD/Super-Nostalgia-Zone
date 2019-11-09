local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local loadTime = ServerStorage:FindFirstChild("LoadTime")

if loadTime and loadTime.Value then
	while wait() do
		Lighting:SetMinutesAfterMidnight((tick()*5)%1440)
	end
end

