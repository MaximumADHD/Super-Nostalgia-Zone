local gameInst = game.JobId 
local isOnline = (gameInst ~= "")

if isOnline and game.GameId ~= 123949867 then
	script:Destroy()
	return 1
end

for _,rep in pairs(script:GetChildren()) do
    local service = game:GetService(rep.Name)

    for _,child in pairs(rep:GetChildren()) do
        child.Parent = service
    end
end

return 0