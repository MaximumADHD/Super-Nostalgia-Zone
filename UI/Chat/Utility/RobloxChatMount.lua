local ChatConnections = {}
 
local function AddObjects(bindableClass, targetName, ...)
	local target = ChatConnections[targetName]

	if not target then
		target = {}
		ChatConnections[targetName] = target
	end

	local names = {...}

	for _,name in pairs(names) do
		local signal = Instance.new(bindableClass)
		signal.Name = targetName .. "_" .. name
		signal.Parent = script

		target[name] = signal
	end
end
 
AddObjects("BindableEvent","ChatWindow",
	---------------------------
	-- Fired from the CoreGui
	---------------------------
	"ToggleVisibility", -- Fired when the CoreGui chat button is pressed.
	"SetVisible", -- Fired when the CoreGui wants to directly change the visiblity state of the chat window.
	"FocusChatBar", -- Fired when the CoreGui wants to capture the Chatbar's Focus.
	"TopbarEnabledChanged", -- Fired when the visibility of the Topbar is changed.
	"SpecialKeyPressed", -- Fired when the reserved ChatHotkey is pressed.
	"CoreGuiEnabled", -- Fired when a user changes the SetCoreGuiEnabled state of the Chat Gui.
 
	---------------------------
	-- Fired to the CoreGui
	---------------------------
	"ChatBarFocusChanged",
		-- ^ Fire this with 'true' when you want to assure the CoreGui that the ChatBar is being focused on.
 
	"VisibilityStateChanged", 
		-- ^ Fire this with 'true' when the user shows or hides the chat.
 
	"MessagesChanged",
		-- ^ Fire this with a number to change the number of messages that have been recorded by the chat window.
		--   If the CoreGui thinks the chat window isn't visible, it will display the recorded difference between
		--   the number of messages that was displayed when it was visible, and the number you supply.
 
	"MessagePosted" 
		-- ^ Fire this to make the player directly chat under ROBLOX's C++ API. 
		--	  This will fire the LocalPlayer's Chatted event.
		--   Please only fire this on the player's behalf. If you attempt to spoof a player's chat
		--   to get them in trouble, you could face serious moderation action.
)
 
AddObjects("BindableFunction","ChatWindow",
	"IsFocused" -- This will be invoked by the CoreGui when it wants to check if the chat window is active.
)
 
-- The following events are fired if the user calls StarterGui:SetCore(string name, Variant data)
-- Note that you can only hook onto these ones specifically.
AddObjects("BindableEvent","SetCore",
	"ChatMakeSystemMessage",
	"ChatWindowPosition",
	"ChatWindowSize",
	"ChatBarDisabled"
)
 
-- The following functions are invoked if the user calls StarterGui:GetCore(string name)
-- Note that you can only hook onto these ones specifically.
AddObjects("BindableFunction","GetCore",
	"ChatWindowPosition", -- Should return a UDim2 representing the position of the chat window.
	"ChatWindowSize", -- Should return a UDim2 representing the size of the chat window.
	"ChatBarDisabled" -- Should return true if the chat bar is currently disabled.
)
 
-- Connect ChatConnections to the CoreGui.
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")

if not GuiService:IsTenFootInterface() then
	local tries = 0
	local maxAttempts = 30
	
	while (tries < maxAttempts) do
		local success,result = pcall(function ()
			StarterGui:SetCore("CoreGuiChatConnections", ChatConnections)
		end)

		if success then
			break
		else
			tries = tries + 1
			if tries == maxAttempts then
				error("Error calling SetCore CoreGuiChatConnections: " .. result)
			else
				wait()
			end
		end
	end
end

return ChatConnections