local AssetService = game:GetService("AssetService")
local places = AssetService:GetGamePlacesAsync()

local creators =
{
	["Ultimate Paintball"]                  = "miked";
	["Sunset Plain"]                        = "Schwaabo";
	["Sword Fights on the Heights I"]       = "Telamon";
	["Sword Fights on the Heights IV"]      = "Telamon";
	["Haunted Mansion"]                     = "Telamon";
	["Rocket Fight Advanced"]               = "Telamon";
	["Pinball Wizards!"]                    = "Telamon";
	["Balance"]                             = "Matt Dusek";
	["Dodge The Teapots of Doom!"]          = "clockwork";
	["Thrillville"]                         = "JJ5x5";
	["The Undead Coming"]                   = "Stealth Pilot";
	["Brick Battle: Superiority Complex"]   = "Cruss Kilderstrohe";
	["Mini Robloxia"]                       = "Are92";
	["Nevermoor's Blight"]                  = "Telamon";
	["ROBLOX Halloween Treasure Hunt 2009"] = "Jacobxxduel and Stealth Pilot";
	["Yorick's Resting Place"]              = "Yorick";
	["King of the Hill"]                    = "Zuka and JoshJosh117";
	["Minigame World"]                      = "miked";
	["Super Nostalgia Zone Sandbox"]		= "CloneTrooper1019";
	["The Underground War"]					= "stickmasterluke";
	["Doomspire Brickbattle"]               = "Temple of Brickbattle";
	["HERE, where the world is quiet"]      = "Swinburne";
	["ROBLOX Bowling Alley"]                = "blXhd";
	["ROBLOX Halloween Paintball 2009"]     = "Stealth Pilot";
}

local function iterPageItems(pages)
	return coroutine.wrap(function ()
		local pageNum = 1
		while true do
			for _, item in ipairs(pages:GetCurrentPage()) do
				coroutine.yield(item, pageNum)
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
			pageNum = pageNum + 1
		end
	end)
end

local placeData = {}

for place in iterPageItems(places) do
	if place.PlaceId ~= game.PlaceId then 
		if place.Name:lower():find("devtest") then
			place.DevTest = true
		end
		place.Creator = creators[place.Name] or "ROBLOX"
		table.insert(placeData,place)
	end
end

return placeData