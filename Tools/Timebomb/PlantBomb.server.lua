local bombScript = script.Parent.Bomb
local Tool = script.Parent
local Bomb = Tool.Handle

function plant()
	local bomb2 = Instance.new("Part")
   
	local vCharacter = Tool.Parent
	local vPlayer = game.Players:playerFromCharacter(vCharacter)

	local spawnPos = Bomb.Position

	bomb2.Position = Vector3.new(spawnPos.x, spawnPos.y+3, spawnPos.z)
	bomb2.Size = Vector3.new(2,2,2)
	
	bomb2.BrickColor = BrickColor.new(21)
	bomb2.Shape = 0
	bomb2.BottomSurface = 0
	bomb2.TopSurface = 0
	bomb2.Reflectance = 0.2
	bomb2.Name = "TimeBomb"
	bomb2.Locked = true

	local creator_tag = Instance.new("ObjectValue")
	creator_tag.Value = vPlayer
	creator_tag.Name = "creator"
	creator_tag.Parent = bomb2

	bomb2.Parent = game.Workspace
	bomb2:SetNetworkOwner(vPlayer)
	local new_script = bombScript:clone()
	new_script.Disabled = false
	new_script.Parent = bomb2
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
	Bomb.Transparency = 1.0

	plant()

	wait(6)
	Bomb.Transparency = 0.0

	Tool.Enabled = true
end

function onUnequipped()
end


Tool.Activated:connect(onActivated)
Tool.Unequipped:connect(onUnequipped)