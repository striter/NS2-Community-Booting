
-- workaround because Las is lazy
if AddModPanel then return end


kModPanels = {}
kModPanelsLoaded = false
function AddModPanel(material, url)
    if not kModPanelsLoaded then
        local panel = {["material"]= material,[ "url"]= url}
        table.insert(kModPanels, panel)
    else
        Log("AddModPanel was called too late")
    end
end

ModLoader.SetupFileHook( "lua/Globals.lua", "lua/ModPanels/Globals.lua", "post" )
ModLoader.SetupFileHook( "lua/NS2Gamerules.lua", "lua/ModPanels/NS2Gamerules.lua", "post" )
ModLoader.SetupFileHook( "lua/Shared.lua", "lua/ModPanels/Shared.lua", "post" )
ModLoader.SetupFileHook( "lua/Utility.lua", "lua/ModPanels/Utility.lua", "post" )
ModLoader.SetupFileHook( "lua/ReadyRoomPlayer.lua", "lua/ModPanels/ReadyRoomPlayer.lua", "post" )
ModLoader.SetupFileHook( "lua/ServerAdminCommands.lua", "lua/ModPanels/ServerAdminCommands.lua", "post" )