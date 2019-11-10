return
{
    Style =
    {
        Font = "Cartoon";
        AutoButtonColor = false;
        
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 1, 0);
    
        BackgroundColor3 = Color3.fromRGB(177, 177, 177);
        BackgroundTransparency = 0.5;
        
        TextSize = 14;
        TextXAlignment = "Left";
        
        TextTransparency = 0.3;
        TextStrokeTransparency = 0.9;
    };

    TextColors = 
    {
        Active   = Color3.fromRGB( 77,  77,  77);
        Inactive = Color3.fromRGB(156, 156, 156);
    };

    Verbs = 
    {
        {
            Name = "Tools";
            Enabled = false;
        };
         
        {
            Name = "Insert";
            Enabled = false;
        };
        
        {
            Name = "Fullscreen";
            Enabled = true;
        };
        
        {
            Name = "Help";
            Label = "Help...";
            Enabled = true;
        };

        {
            Name = "Exit";
            Label = " Exit";
            Enabled = true;
        }
    }
}