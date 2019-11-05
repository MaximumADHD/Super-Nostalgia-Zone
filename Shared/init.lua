if game.JobId ~= "" and game.GameId ~= 123949867 then
	return
end

for _,serviceBin in pairs(script:GetChildren()) do
	local className = serviceBin.Name
	local service = game:FindFirstChildWhichIsA(className, true)
	
	if not service then
		service = game:GetService(className)
	end
	
	for _,child in pairs(serviceBin:GetChildren()) do
		child.Parent = service
	end
end

return 1