local character = script.Parent

local function onChildAdded(child)
    if child:IsA("Tool") and child.RequiresHandle then
        local handle = child:FindFirstChild("Handle")

        if handle and handle:IsGrounded() then
            workspace:UnjoinFromOutsiders{character}
        end
    end
end

for _,child in pairs(character:GetChildren()) do
    onChildAdded(child)
end

character.ChildAdded:Connect(onChildAdded)