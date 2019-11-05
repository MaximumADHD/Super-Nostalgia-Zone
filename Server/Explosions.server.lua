local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")

local FORCE_GRANULARITY = 2
local allowTeamDamage = false

local teamDamage = ServerStorage:FindFirstChild("TeamDamage")
if teamDamage then
	allowTeamDamage = teamDamage.Value
end

local function processExplosion(explosion)
	local BLAST_RADIUS = explosion.BlastRadius
	local BLAST_PRESSURE = explosion.BlastPressure
	
	if explosion:FindFirstChild("BLAST_PRESSURE") then
		BLAST_PRESSURE = explosion.BLAST_PRESSURE.Value
	end
	
	if BLAST_PRESSURE > 0 then
		local damagedPlayerSet = {}
		local blastCenter = explosion.Position
		
		local function onExplosionHit(p, dist)
			if explosion:FindFirstChild("Owner") then
				local player = explosion.Owner.Value
				if player then
					local char = player.Character
					if char and p:IsDescendantOf(char) then
						return
					end
				end
			end
			
			local isInCharacter = false
			
			if p.Size.Magnitude / 2 < 20 then
				--world->ticklePrimitive(p, true);
				
				local doBreakjoints = true
				local hitCharacter = p:FindFirstAncestorWhichIsA("Model")
				local hitHumanoid = hitCharacter:FindFirstChild("Humanoid")
				
				if hitCharacter and hitHumanoid then
					-- flag as character
					isInCharacter = true					
					
					-- don't breakjoints characters
					doBreakjoints = false
					
					-- work out what damage to do					
					local hitPlayer = game.Players:GetPlayerFromCharacter(hitCharacter)
					local creatorTag = explosion:FindFirstChild("creator")
					local myPlayer
					
					if creatorTag then
						myPlayer = creatorTag.Value
					end
					
					if hitPlayer and not damagedPlayerSet[hitPlayer] then
						local doDamage = true
						
						if not allowTeamDamage then
							if myPlayer and hitPlayer ~= myPlayer then
								if hitPlayer.Team and myPlayer.Team and hitPlayer.Team == myPlayer.Team then
									doDamage = false
								end
							end
						end
						
						if doDamage then
							-- flag as damaged
							damagedPlayerSet[hitPlayer] = true
							
							-- assume the torso is a massless frictionless unit ball in a perfect vaccum
							dist = math.min(math.max(dist - 0.8, 0), 1)
							
							-- damage to do
							local frac = (dist / BLAST_RADIUS)	
		
							-- do damage. See how much damage to do
							if myPlayer == hitPlayer then
								hitHumanoid:TakeDamage((BLAST_RADIUS * 20) - (frac * 38))
								hitHumanoid:ChangeState("Ragdoll")
							else
								hitHumanoid:TakeDamage(100)
							end
						end
					end
				end		
				
				-- breakjoints stuff
				if doBreakjoints then
					if not hitHumanoid and p:CanSetNetworkOwnership() then
						p:SetNetworkOwner(nil)
					end
					
					for _,joint in pairs(p:GetJoints()) do
						if not CollectionService:HasTag(joint, "GorillaGlue") then
							joint:Destroy()
						end
					end
				end
				
				--Vector3 delta = (p->getCoordinateFrame().translation - position);
				local delta = (p.Position - blastCenter)
				
				--Vector3 normal = 
				--	(delta == Vector3::zero())
				--	? Vector3::unitY()
				--	: delta.direction();
				local normal = (delta == Vector3.new(0, 0, 0))
				               and Vector3.new(0, 1, 0)
				               or  delta.unit
				
				--float radius = p->getRadius();
				local radius = p.Size.magnitude / 2				
				
				--float surfaceArea = radius * radius;
				local surfaceArea = radius * radius
				
				--Vector3 impulse = normal * blastPressure * surfaceArea * (1.0f / 4560.0f); // normalizing factor
				local impulse = normal * BLAST_PRESSURE * surfaceArea * (1.0 / 4560.0)
				
				-- How much force to apply (for characters, ramp it down towards the edge)
				local frac;
				
				if isInCharacter then
					frac = 1 - math.max(0, math.min(1, (dist - 2) / BLAST_RADIUS))
				else
					frac = 1
				end				
				
				--p->getBody()->accumulateLinearImpulse(impulse, p->getCoordinateFrame().translation);
				local currentVelocity = p.Velocity
				local deltaVelocity = impulse / p:GetMass() -- m * del-v = F * del-t = Impulse
				local forceNeeded = workspace.Gravity * p:GetMass() -- F = ma
				
				local bodyV = Instance.new('BodyVelocity')
				bodyV.Velocity = currentVelocity + deltaVelocity
				bodyV.MaxForce = Vector3.new(forceNeeded, forceNeeded, forceNeeded) * 10 * frac
				bodyV.Parent = p
				
				Debris:AddItem(bodyV, 0.2 / FORCE_GRANULARITY)
				
				--p->getBody()->accumulateRotationalImpulse(impulse * 0.5 * radius); // a somewhat arbitrary, but nice torque
				local rotImpulse = impulse * 0.5 * radius
				local currentRotVelocity = p.RotVelocity
				
				local momentOfInertia = (2 * p:GetMass() * radius * radius / 5) -- moment of inertia = 2/5*m*r^2 (assuming roughly spherical)
				local deltaRotVelocity = rotImpulse / momentOfInertia 
				local torqueNeeded = 20 * momentOfInertia -- torque = r x F, want about alpha = 20 rad/s^2, alpha * P = torque
					
				local rot = Instance.new('BodyAngularVelocity')
				rot.MaxTorque = Vector3.new(torqueNeeded, torqueNeeded, torqueNeeded) * 10 * frac
				rot.AngularVelocity = currentRotVelocity + deltaRotVelocity
				rot.Parent = p
				
				Debris:AddItem(rot, 0.2 / FORCE_GRANULARITY)
			end
		end
		
		explosion.Hit:Connect(onExplosionHit)
	end
end

local function onDescendantAdded(desc)
	if desc:IsA("Explosion") then
		local pressure = desc.BlastPressure
		
		if pressure > 0 then
			local blastPressure = Instance.new("NumberValue")
			blastPressure.Name = "BLAST_PRESSURE"
			blastPressure.Value = pressure
			blastPressure.Parent = desc
			
			desc.BlastPressure = 0
		end
		
		processExplosion(desc)
	end
end

workspace.DescendantAdded:Connect(onDescendantAdded)