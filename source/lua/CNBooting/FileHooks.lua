
-- workaround because Las is lazy
if AddHintModPanel then return end


kModPanels = {}
kModPanelsLoaded = false
function AddHintModPanel(material, url,hint)
    if not kModPanelsLoaded then
        local panel = {["material"]= material,[ "url"]= url,["hint"]=hint}
        table.insert(kModPanels, panel)
    else
        Log("AddModPanel was called too late")
    end
end

ModLoader.SetupFileHook( "lua/NetworkMessages_Server.lua", "lua/CNBooting/NetworkMessages_Server.lua", "post")
ModLoader.SetupFileHook( "lua/Gamerules.lua", "lua/CNBooting/Gamerules.lua", "post" )
ModLoader.SetupFileHook( "lua/NS2Gamerules.lua", "lua/CNBooting/NS2Gamerules.lua", "post" )
ModLoader.SetupFileHook( "lua/Shared.lua", "lua/CNBooting/Shared.lua", "post" )
ModLoader.SetupFileHook( "lua/Utility.lua", "lua/CNBooting/Utility.lua", "post" )
ModLoader.SetupFileHook( "lua/MapCycle.lua", "lua/CNBooting/MapCycle.lua", "replace" )
ModLoader.SetupFileHook( "lua/ServerAdminCommands.lua", "lua/CNBooting/ServerAdminCommands.lua", "post" )
ModLoader.SetupFileHook( "lua/GUIWebView.lua", "lua/CNBooting/GUIWebView.lua", "replace" )
ModLoader.SetupFileHook( "lua/Badges_Shared.lua", "lua/CNBooting/Badges_Shared.lua", "replace")
ModLoader.SetupFileHook( "lua/Badges_Client.lua", "lua/CNBooting/Badges_Client.lua", "replace")
ModLoader.SetupFileHook( "lua/Voting.lua", "lua/CNBooting/Voting.lua", "replace")
ModLoader.SetupFileHook( "lua/VotingChangeMap.lua", "lua/CNBooting/VotingChangeMap.lua", "replace")
ModLoader.SetupFileHook( "lua/shine/core/shared/hook.lua", "lua/shine/gamemodehook.lua", "post" )