local debris = game:service("Debris")
pellet = script.Parent
damage = 8

local allowTeamDamage = false
local ServerStorage = game:GetService("ServerStorage")
if ServerStorage:FindFirstChild("TeamDamage") then
	allowTeamDamage = ServerStorage.TeamDamage.Value
end

function tagHumanoid(humanoid)
	-- todo: make tag expire
	local tag = pellet:findFirstChild("creator")
	if tag ~= nil then
		-- kill all other tags
		while(humanoid:findFirstChild("creator") ~= nil) do
			humanoid:findFirstChild("creator").Parent = nil
		end

		local new_tag = tag:clone()
		new_tag.Parent = humanoid
		debris:AddItem(new_tag, 1)
	end
end

function onTouched(hit)
	local hitChar = hit:FindFirstAncestorWhichIsA("Model")
	local humanoid = hitChar:FindFirstChild("Humanoid")
	if humanoid ~= nil then
		local canDamage = true
		local tag = pellet:FindFirstChild("creator")
		if tag then
			local creator = tag.Value
			local player = game.Players:GetPlayerFromCharacter(hitChar)
			if creator and player then
				if creator.Team and player.Team and creator.Team == player.Team then
					canDamage = allowTeamDamage
				end
			end
		end
		if canDamage then
			tagHumanoid(humanoid)
			humanoid:TakeDamage(damage)
		end
	else
		damage = damage / 2
		if damage < 1 then
			connection:disconnect()
			pellet.Parent = nil
		end
	end
end

connection = pellet.Touched:connect(onTouched)

r = game:service("RunService")
t, s = r.Stepped:wait()
d = t + 2.0 - s
while t < d do
	t = r.Stepped:wait()
end

pellet.Parent = nil
