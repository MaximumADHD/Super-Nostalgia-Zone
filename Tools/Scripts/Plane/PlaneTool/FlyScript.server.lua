local engine = script.Parent.Parent.Engine
local speed = 90
if engine:FindFirstChild("EngineSpeed") then
	speed = engine.EngineSpeed.Value
end

local bv = engine:FindFirstChild("EngineForce")
if not bv then
	bv = Instance.new("BodyVelocity")
	bv.Name = "EngineForce"
	bv.MaxForce = Vector3.new(10e7,10e7,10e7)
	bv.Velocity = Vector3.new()
	bv.Parent = engine
end

while true do
	wait(.1)
	bv.Velocity = engine.CFrame.lookVector * speed
end 
