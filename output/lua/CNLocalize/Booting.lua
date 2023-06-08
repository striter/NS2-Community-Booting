Shared.RegisterNetworkMessage("SwitchLocalize", {})
if Client then
    gForceLocalize = CNPersistent and CNPersistent.forceLocalization or true
    Client.HookNetworkMessage("SwitchLocalize", function(message)
        gForceLocalize = not gForceLocalize
        if CNPersistent then
            CNPersistent.forceLocalization = gForceLocalize
            CNPersistentSave()
        end 
    end )
    
    --Core
    if not kTranslateMessage then
        kTranslateMessage = {}
        kLocales = {}
    end
    
    Script.Load("lua/CNLocalize/CNStrings.lua")
    Script.Load("lua/CNLocalize/CNStringsMenu.lua")
    local baseResolveString = Locale.ResolveString
    function CNLocalizeResolve(input)
        if not input then return "" end

        local resolvedString = gForceLocalize and rawget(kTranslateMessage,input) or nil
        resolvedString = resolvedString or rawget(kLocales,input)
        return resolvedString or baseResolveString(input)
    end
    Locale.ResolveString = CNLocalizeResolve
    
    -- Fonts Fix
    ModLoader.SetupFileHook("lua/GUIAssets.lua", "lua/CNLocalize/GUIAssets.lua", "post")
    ModLoader.SetupFileHook("lua/GUI/FontGlobals.lua", "lua/CNLocalize/FontGlobals.lua", "replace")

    --Locations
    Script.Load("lua/CNLocalize/CNLocations.lua")
    function CNResolveLocation(input)
        if not gForceLocalize then return input end
        return kTranslateLocations[input] or input
    end
    
    ModLoader.SetupFileHook("lua/GUIMinimap.lua", "lua/CNLocalize/GUIMinimap.lua", "post")
    ModLoader.SetupFileHook("lua/Player_Client.lua", "lua/CNLocalize/Player_Client.lua", "post")
    ModLoader.SetupFileHook("lua/PhaseGate.lua", "lua/CNLocalize/PhaseGate.lua", "post")
    ModLoader.SetupFileHook("lua/Observatory.lua", "lua/CNLocalize/Observatory.lua", "post")
    ModLoader.SetupFileHook("lua/TunnelEntrance.lua", "lua/CNLocalize/TunnelEntrance.lua", "post")
    ModLoader.SetupFileHook("lua/GUIHiveStatus.lua", "lua/CNLocalize/GUIHiveStatus.lua", "post")
    ModLoader.SetupFileHook("lua/Hud/Commander/MarineGhostModel.lua", "lua/CNLocalize/MarineGhostModel.lua", "post")
    ModLoader.SetupFileHook("lua/TeamMessenger.lua", "lua/CNLocalize/TeamMessenger.lua", "replace")
    
    -- Name Fix
    ModLoader.SetupFileHook("lua/menu2/MenuUtilities.lua", "lua/CNLocalize/MenuUtilities.lua", "post")

    --Additional Localizes
    ModLoader.SetupFileHook("lua/GUIGameEndStats.lua", "lua/CNLocalize/GUIGameEndStats.lua", "replace" )
    ModLoader.SetupFileHook("lua/GUIDeathStats.lua", "lua/CNLocalize/GUIDeathStats.lua", "replace" )
    ModLoader.SetupFileHook("lua/ConfigFileUtility.lua", "lua/CNLocalize/ShineExtensions.lua", "post" )        --Shine localizes

    --Chat Filter
    Script.Load("lua/CNLocalize/ChatFilters.lua")
    function CNChatFilter(input)
        return string.gsub(input, "%w+",kChatFilters)
    end
    Locale.ChatFilter = CNChatFilter
end

Shared.Message("[CNCE] CN Booting Version 2023.04.13")