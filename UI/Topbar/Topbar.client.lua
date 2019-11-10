-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Setup
-------------------------------------------------------------------------------------------------------------------------------------------------------------

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

local topbar = script.Parent

local ui = topbar.Parent
local config = require(topbar:WaitForChild("Config"))

local style = config.Style
local verbs = config.Verbs
local textColors = config.TextColors

local buttons = {}

for i, verb in ipairs(verbs) do
    local name = verb.Name
    local enabled = verb.Enabled
    local label = verb.Label or name

    local button = Instance.new("TextButton")
    button.Name = name
    button.LayoutOrder = i
    button.Active = enabled
    button.Text = "  " .. label
    
    for key, value in pairs(config.Style) do
        button[key] = value
    end
    
    local textColor = (enabled and textColors.Active or textColors.Inactive)
    button.TextStrokeColor3 = textColor
    button.TextColor3 = textColor

    if enabled then
        local function onMouseEnter()
            button.BackgroundTransparency = 0
        end

        local function onMouseLeave()
            button.BackgroundTransparency = 0.5
        end

        button.MouseEnter:Connect(onMouseEnter)
        button.MouseLeave:Connect(onMouseLeave)
    end
    
    buttons[name] = button
    button.Parent = topbar
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Help Button
-------------------------------------------------------------------------------------------------------------------------------------------------------------

local helpButton = buttons.Help

local helpWindow = ui:WaitForChild("HelpWindow")
local helpClose = helpWindow:WaitForChild("Close")

local function onHelpActivated()
    helpWindow.Visible = true
end

local function onHelpClosed()
    helpWindow.Visible = false
end

helpClose.Activated:Connect(onHelpClosed)
helpButton.Activated:Connect(onHelpActivated)

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Fullscreen Button
-------------------------------------------------------------------------------------------------------------------------------------------------------------

local player = Players.LocalPlayer
local fullscreen = buttons.Fullscreen

local function onFullscreenActivated()
    if not player:FindFirstChild("FullcreenMsg") then
        local msg = Instance.new("Message")
        msg.Name = "FullscreenMsg"
        msg.Text = "This button is just here for legacy aesthetics, and has no functionality."

        if UserInputService.KeyboardEnabled then
            msg.Text = msg.Text .. "\nPress F11 to toggle fullscreen!"
        end

        msg.Parent = player
        wait(3)
        msg:Destroy()
    end
end

local function updateFullscreen()
    local text = fullscreen.Text

    if UserGameSettings:InFullScreen() then
        fullscreen.Text = text:gsub("Full", "x Full")
    else
        fullscreen.Text = text:gsub("x ", "")
    end
end

updateFullscreen()

fullscreen.Activated:Connect(onFullscreenActivated)
UserGameSettings.FullscreenChanged:Connect(updateFullscreen)

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exit Button
-------------------------------------------------------------------------------------------------------------------------------------------------------------

local exitButton = buttons.Exit

local gameJoin = ui:WaitForChild("GameJoin")
local message = gameJoin:WaitForChild("Message")

local exitOverride = gameJoin:WaitForChild("ExitOverride")
local exitBuffer = "Continue holding down 'Back' to return to the menu.\nExiting in...\n%.1f"

local function onExitActivated()
    if not exitOverride.Visible then
        exitOverride.Visible = true
        message.Visible = false
        gameJoin.Visible = true

        TeleportService:Teleport(998374377)
    end
end

local function processExitInput(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.ButtonSelect then
        if exitOverride.Visible then
            return
        end
        
        if gameJoin.Visible then
            return
        end
        
        if not game:IsLoaded() then
            return
        end
        
        local success = true
        
        gameJoin.Visible = true
        message.Size = exitOverride.Size
        
        for i = 3, 0, -.1 do
            if input.UserInputState ~= Enum.UserInputState.Begin then
                success = false
                break
            end
            
            message.Text = exitBuffer:format(i)
            wait(.1)
        end
        
        if success then
            onExitActivated()
        else
            gameJoin.Visible = false
        end
    end
end

if not GuiService:IsTenFootInterface() then
    exitButton.Activated:Connect(onExitActivated)
end

UserInputService.InputBegan:Connect(processExitInput)

-------------------------------------------------------------------------------------------------------------------------------------------------------------