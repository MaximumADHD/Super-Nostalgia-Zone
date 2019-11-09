local topbar = script.Parent

local buttons = 
{
    Tools = 
    {
        Label = "Tools";
        Enabled = false;
        Order = 1;
    };

    Insert = 
    {
        Label = "Insert";
        Enabled = false;
        Order = 2;
    };

    Fullscreen =
    {
        Label = "Fullscreen";
        Enabled = true;
        Order = 3;
    };

    Help = 
    {
        Label = "Help...";
        Enabled = true;
        Order = 4;
    };

    Exit = 
    {
        Label = " Exit";
        Enabled = true;
        Order = 5;
    }
}

local BTN_COLOR = Color3.fromRGB(177, 177, 177)
local TEXT_ACTIVE = Color3.fromRGB(77, 77, 77)
local TEXT_INACTIVE = Color3.fromRGB(156, 156, 156)

for name, data in pairs(buttons) do
    local button = Instance.new("TextButton")
    button.Name = name
    button.Active = data.Enabled
    button.LayoutOrder = data.Order
    button.Text = " " .. data.Label
    
    button.Font = "Cartoon"
    button.AutoButtonColor = false
    
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, 0, 1, 0)

    button.BackgroundColor3 = BTN_COLOR;
    button.BackgroundTransparency = 0.5;

    button.TextSize = 14
    button.TextXAlignment = "Left"

    button.TextTransparency = 0.3;
    button.TextStrokeTransparency = 0.9;

    local textColor = (data.Enabled and TEXT_ACTIVE or TEXT_INACTIVE)
    button.TextStrokeColor3 = textColor
    button.TextColor3 = textColor

    if data.Enabled then
        local function onMouseEnter()
            button.BackgroundTransparency = 0
        end

        local function onMouseLeave()
            button.BackgroundTransparency = 0.5
        end

        button.MouseEnter:Connect(onMouseEnter)
        button.MouseLeave:Connect(onMouseLeave)
    end
    
    button.Parent = topbar
end