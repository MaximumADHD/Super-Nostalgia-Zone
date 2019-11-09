local Debris = game:GetService("Debris")

ball = script.Parent
damage = 20

function onTouched(hit)
	if not (hit.CanCollide and hit.Parent) then
		return
	end
	
	local humanoid = hit.Parent:findFirstChild("Humanoid")
		
	if hit:getMass() < 1.2 * 200 then
		hit.BrickColor = ball.BrickColor
	end
	
	-- make a splat
	for i = 1, 3 do
		local s = Instance.new("Part")
		s.Shape = 1 -- block
		s.formFactor = 2 -- plate
		s.Size = Vector3.new(1,.4,1)
		s.BrickColor = ball.BrickColor
		
		local v = Vector3.new(math.random(-1,1), math.random(0,1), math.random(-1,1))
		s.Velocity = 15 * v
		s.CFrame = CFrame.new(ball.Position + v, v)
		
		Debris:AddItem(s, 24)
		
		s.Parent = game.Workspace
	end
	

	if humanoid ~= nil then
		local canDamage = true
		local tag = ball:FindFirstChild("creator")
		local char = humanoid:FindFirstAncestorWhichIsA("Model")
		
		if tag and char then
			local creator = tag.Value
			local player = game.Players:GetPlayerFromCharacter(char)
			if creator and player then
				if creator.Team and player.Team and creator.Team == player.Team then
					canDamage = false
				end
			end
		end
		
		if canDamage then
			tagHumanoid(humanoid)
			humanoid:TakeDamage(damage)
			wait(2)
			untagHumanoid(humanoid)
		end
	end

	connection:disconnect()
	ball.Parent = nil
end

function tagHumanoid(humanoid)
	-- todo: make tag expire
	local tag = ball:findFirstChild("creator")
	if tag ~= nil then
		local new_tag = tag:clone()
		new_tag.Parent = humanoid
	end
end

function untagHumanoid(humanoid)
	if humanoid ~= nil then
		local tag = humanoid:findFirstChild("creator")
		if tag ~= nil then
			tag.Parent = nil
		end
	end
end

connection = ball.Touched:connect(onTouched)

wait(8)
ball.Parent = nil
