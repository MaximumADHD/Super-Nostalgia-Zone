local RunService = game:GetService("RunService")

local char = script.Parent
local rootPart = char:WaitForChild("HumanoidRootPart")

local platform = Instance.new("Part")
platform.Name = "NoForceField"
platform.TopSurface = 0
platform.BottomSurface = 0
platform.BrickColor = BrickColor.new("Bright orange")
platform.Size = Vector3.new(5, 1, 2)
platform.Anchored = true
platform.Transparency = 1

local down = Vector3.new(0, -100, 0)
local platformOffset = Vector3.new(0, -.5, 0)

while wait() do
	local start = rootPart.CFrame
	local startPos = start.p
	local startRay = Ray.new(startPos, start.lookVector * 5)
	
	local hit, pos, norm = workspace:FindPartOnRay(startRay, char)
	local floorCheckRay
	
	local pass = false
	
	if hit and hit.CanCollide and hit:IsGrounded() then
		if hit:IsA("UnionOperation") or (not hit:IsA("Part") or hit.Shape.Name == "Block") then
			local floorCheckRay = Ray.new(pos - (norm / 5), down)
			local floor, floorPos = workspace:FindPartOnRayWithIgnoreList(floorCheckRay, {char, hit})
			
			if floor and floor.CanCollide and startPos.Y - 2 > floorPos.Y then
				floorPos = floorPos + platformOffset
				platform.Parent = char
				platform.CFrame = CFrame.new(Vector3.new(pos.X + norm.X, floorPos.Y, pos.Z + norm.Z),floorPos)
				pass = true
			end
		end
	end
	
	if not pass then
		platform.Parent = nil
	end
end