r = game:service("RunService")

shaft = script.Parent
position = shaft.Position

function fly()
	direction = shaft.CFrame.lookVector 
	position = position + 35*direction
	error = position - shaft.Position
	shaft.Velocity = 5*error
end

function blow()
	swoosh:stop()
	explosion = Instance.new("Explosion")
	explosion.Position = shaft.Position
	explosion.BlastRadius = 10

	-- find instigator tag
	local creator = script.Parent:findFirstChild("creator")
	if creator ~= nil then
		explosion.Hit:connect(function(part, distance)  onPlayerBlownUp(part, distance, creator) end)
	end

	explosion.Parent = game.Workspace
	connection:disconnect()
	wait(.1)
	shaft:remove()
end

function onTouch(hit)
	if hit.Name == "Building" or
	hit.Name == "Safe" then
		swoosh:stop()
		shaft:remove()
	return end

	local parent = hit.Parent.Parent
	local owner = shaft.Owner
	if owner ~= nil then
		if parent ~= nil and owner.Value ~= nil then
			if parent ~= owner.Value then
				local stunt = parent:FindFirstChild("Stunt")
				if stunt ~= nil then
					if stunt.Value ~= 1 then
						blow()
					end
				else
					blow()
				end
			end
		end
	end
end

function onPlayerBlownUp(part, distance, creator)
	if part.Name == "Head" then
		local humanoid = part.Parent:findFirstChild("Humanoid")
		tagHumanoid(humanoid, creator)
	end
end

function tagHumanoid(humanoid, creator)
	if creator ~= nil then
		local new_tag = creator:clone()
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

t, s = r.Stepped:wait()

swoosh = script.Parent.Swoosh
swoosh:play()

d = t + 4.0 - s
connection = shaft.Touched:connect(onTouch)

while t < d do
	fly()
	t = r.Stepped:wait()
end

-- at max range
script.Parent.Explosion.PlayOnRemove = false
swoosh:stop()
shaft:remove()
