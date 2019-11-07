--Made by Luckymaxer

Tool = script.Parent
Handle = Tool:WaitForChild("Handle")

Sound = Handle:WaitForChild("Sound")

Players = game:GetService("Players")
Debris = game:GetService("Debris")

Debounce = false

Tool.Enabled = true

local function spawnSound(s)
	local sound = s:Clone()
	sound.Parent = s.Parent
	sound:Play()
	sound.Ended:Connect(function ()
		sound:Destroy()
	end)
end
function TagHumanoid(humanoid, player)
	local Creator_Tag = Instance.new("ObjectValue")
	Creator_Tag.Name = "creator"
	Creator_Tag.Value = player
	Debris:AddItem(Creator_Tag, 2)
	Creator_Tag.Parent = humanoid
end

function UntagHumanoid(humanoid)
	for i, v in pairs(humanoid:GetChildren()) do
		if v:IsA("ObjectValue") and v.Name == "creator" then
			v:Destroy()
		end
	end
end

function FindCharacterAncestor(Parent)
	if Parent and Parent ~= game:GetService("Workspace") then
		local humanoid = Parent:FindFirstChild("Humanoid")
		if humanoid then
			return Parent, humanoid
		else
			return FindCharacterAncestor(Parent.Parent)
		end
	end
	return nil
end

function Blow(Hit)
	RightGrip = RightGrip:Clone()
	if Hit and Hit.Parent then
		local humanoid = Hit.Parent:FindFirstChild("Humanoid")
		if humanoid == Humanoid then
			return
		end
		if humanoid then
			Propel(Hit)
			UntagHumanoid(humanoid)
			TagHumanoid(humanoid, Player)
			humanoid.Health = humanoid.Health - 49
		else
			Explode(Hit)
		end
	end
end

function Propel(Part)
	if not Part or not Part.Parent or Part.Anchored then
		return
	end
	local character, humanoid = FindCharacterAncestor(Part)
	if character == Character then
		return
	end
	local Direction = (Part.Position - Torso.Position).unit
	Direction = Direction + Vector3.new(0, 1, 0)
	Direction = Direction * 200
	Part.Velocity = Part.Velocity + Direction
end

function Explode(Part)
	if not Part or not Part.Parent or Debounce then
		return
	end
	Debounce = true
	local Direction = (Part.Position - Torso.Position).unit
	local Position = Direction * 12 + Torso.Position
	local Explosion = Instance.new("Explosion")
	Explosion.ExplosionType = Enum.ExplosionType.NoCraters
	Explosion.BlastRadius = 4
	Explosion.BlastPressure = 1
	Explosion.Position = Position	
	Explosion.Hit:connect(function(Part, Distance)
		Propel(Part)
	end)
	local owner = Instance.new("ObjectValue")
	owner.Name = "Owner"
	owner.Value = Player
	owner.Parent = Explosion
	Explosion.Parent = game:GetService("Workspace")
	wait(0.1)
	local GripClone = RightGrip:Clone()
	GripClone.Parent = RightArm
	Debounce = false
end

function Attack()
	spawnSound(Sound)
	local Anim = Instance.new("StringValue")
	Anim.Name = "toolanim"
	Anim.Value = "Slash"
	Debris:AddItem(Anim, 2)
	Anim.Parent = Tool
end

function Lunge()
	Attack()
	local Force = Instance.new("BodyPosition")
	Force.maxForce = Vector3.new(1e+005, 1e+004, 1e+005)
	local Direction = Humanoid.targetPoint
	if ((Direction - Handle.Position).magnitude > 15) then
		return
	end
	Force.position = Direction
	Debris:AddItem(Force, 0.25)
	Force.Parent = Handle
end

function Activated()
	if not Tool.Enabled or not Humanoid.Parent or Humanoid.Health == 0 or not Torso.Parent or not RightArm.Parent or not RightGrip then
		return
	end
	Tool.Enabled = false
	connection = Handle.Touched:connect(Blow)
	Lunge()
	wait(0.4)
	connection:disconnect()
	Tool.Enabled = true
end

function Equipped()
	Character = Tool.Parent
	Player = Players:GetPlayerFromCharacter(Character)
	Humanoid = Character:FindFirstChild("Humanoid")
	Torso = Character:FindFirstChild("Torso")
	RightArm = Character:FindFirstChild("Right Arm")
	if RightArm then
		RightGrip = RightArm:WaitForChild("RightGrip",1)
	end
	if not Player or not Humanoid or Humanoid.Health == 0 or not Torso or not RightArm or not RightGrip then
		return
	end
end

Tool.Activated:connect(Activated)
Tool.Equipped:connect(Equipped)