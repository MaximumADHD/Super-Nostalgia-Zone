local Tool = script.Parent
local Ball = Tool.Handle

function fire(direction)

	Tool.Handle.Boing:Play()

	local vCharacter = Tool.Parent
	local vPlayer = game.Players:playerFromCharacter(vCharacter)

	local missile = Instance.new("Part")       

	local spawnPos = vCharacter.PrimaryPart.Position

	spawnPos  = spawnPos + (direction * 5)

	missile.Position = spawnPos
	missile.Size = Vector3.new(2,2,2)
	missile.Velocity = direction * 200
	missile.BrickColor = BrickColor.random() 
	missile.Shape = 0
	missile.BottomSurface = 0
	missile.TopSurface = 0
	missile.Name = "Cannon Shot"
	missile.Reflectance = .2
	missile.CustomPhysicalProperties = PhysicalProperties.new(1,0,1)
	Tool.Handle.Boing:clone().Parent = missile
	
	local new_script = script.Parent.CannonBall:clone()
	new_script.Disabled = false
	new_script.Parent = missile

	local creator_tag = Instance.new("ObjectValue")
	creator_tag.Value = vPlayer
	creator_tag.Name = "creator"
	creator_tag.Parent = missile

	missile.Parent = game.Workspace
	missile:SetNetworkOwner(nil)
end



Tool.Enabled = true
function onActivated()
	if not Tool.Enabled then
		return
	end
	Tool.Enabled = false
	local character = Tool.Parent;
	local humanoid = character.Humanoid
	if humanoid == nil then
		print("Humanoid not found")
		return 
	end
	local targetPos = humanoid.TargetPoint
	local lookAt = (targetPos - character.Head.Position).unit
	fire(lookAt)
	wait(2)
	Tool.Enabled = true
end


Tool.Activated:connect(onActivated)

