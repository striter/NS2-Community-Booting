Shared.RegisterNetworkMessage("SwitchLocalize", {})
if Client then
    local localConfigPath = "config://NS2CN/LocalFile.json"
    
    gForceLocalize = true
    if GetFileExists(localConfigPath) then
        local localConfig = io.open(localConfigPath, "r")
        if localConfig then
            local parsedFile = json.decode(localConfig:read("*all"))
            gForceLocalize = parsedFile.forceLocalization or forceLocalization
            io.close(localConfig)
        end
    end
    
    Client.HookNetworkMessage("SwitchLocalize", function(message)
        gForceLocalize = not gForceLocalize

        local savedFile = io.open(localConfigPath, "w+")
        if savedFile then
            savedFile:write(json.encode({ forceLocalization = gForceLocalize }, { indent = true }))
            io.close(savedFile)
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
        if not gForceLocalize then
            return input
        end

        local locationName = kTranslateLocations[input]
        if not locationName then
            Shared.Message("Location:{" .. input .. "} Untranslated")
            locationName = input
        end
        return locationName
    end
    Locale.ResolveLocation = CNResolveLocation
    ModLoader.SetupFileHook("lua/GUIMinimap.lua", "lua/CNLocalize/GUIMinimap.lua", "post")
    ModLoader.SetupFileHook("lua/PhaseGate.lua", "lua/CNLocalize/PhaseGate.lua", "post")
    ModLoader.SetupFileHook("lua/Observatory.lua", "lua/CNLocalize/Observatory.lua", "post")
    ModLoader.SetupFileHook("lua/TunnelEntrance.lua", "lua/CNLocalize/TunnelEntrance.lua", "post")
    
    -- Name Fix
    ModLoader.SetupFileHook("lua/menu2/MenuUtilities.lua", "lua/CNLocalize/MenuUtilities.lua", "post")

    --Additional Localizes
    ModLoader.SetupFileHook("lua/GUIDeathScreen2.lua", "lua/CNLocalize/GUIDeathScreen2.lua", "post")
    ModLoader.SetupFileHook("lua/ConfigFileUtility.lua", "lua/CNLocalize/ShineExtensions.lua", "post" )        --Shine localizes

    --Chat Filter
    Script.Load("lua/CNLocalize/ChatFilters.lua")
    function CNChatFilter(input)
        return string.gsub(input, "%w+",kChatFilters)
    end
    Locale.ChatFilter = CNChatFilter
end

Shared.Message("[CNCE] CN Booting Version 2023.3.2")