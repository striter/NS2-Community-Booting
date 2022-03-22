
Shared.Message("[CNCE] CN Localize Version 2022.2.12.1")
ModLoader.SetupFileHook("lua/NetworkMessages_Server.lua", "lua/CNLocalize/NetworkMessages_Server.lua", "post")
ModLoader.SetupFileHook( "lua/ConfigFileUtility.lua", "lua/CNLocalize/ShineExtensions.lua", "post" )


if Client then
    if not kTranslateMessage then
        kTranslateMessage = {}
    end
    Script.Load("lua/CNLocalize/CNStrings.lua")
    Script.Load("lua/CNLocalize/CNStringsMenu.lua")
    Script.Load("lua/CNLocalize/CNBadges.lua")
    local baseResolveString = Locale.ResolveString

    function CNLocalizeResolve(input)
        if not input then return "" end

        local resolvedString = rawget(kTranslateMessage,input) 
        if resolvedString  then
            return resolvedString
        end

        return baseResolveString(input)
    end
    Locale.ResolveString = CNLocalizeResolve

    Script.Load("lua/CNLocalize/CNLocations.lua")
    function CNResolveLocation(input)
        local locationName=kTranslateLocations[input]
        if not locationName then
            Shared.Message("Location:{" .. input .. "} Untranslated")
            locationName=input
        end
        return locationName
    end
    Locale.ResolveLocation = CNResolveLocation


    Script.Load("lua/CNLocalize/ChatFilters.lua")
    function CNChatFilter(input)
        return string.gsub(input, "%w+",kChatFilters) 
    end
    Locale.ChatFilter = CNChatFilter

    ModLoader.SetupFileHook("lua/GUIAssets.lua", "lua/CNLocalize/GUIAssets.lua", "post")
    ModLoader.SetupFileHook("lua/GUI/FontGlobals.lua", "lua/CNLocalize/FontGlobals.lua", "replace")
    ModLoader.SetupFileHook("lua/menu2/MenuUtilities.lua", "lua/CNLocalize/MenuUtilities.lua", "post")
    -- ModLoader.SetupFileHook("lua/GUIDeathScreen2.lua", "lua/CNLocalize/GUIDeathScreen2.lua", "post") 
    -- NAME UTF 8 WTF
    ModLoader.SetupFileHook("lua/GUIMinimap.lua", "lua/CNLocalize/GUIMinimap.lua", "post")
    ModLoader.SetupFileHook("lua/PhaseGate.lua", "lua/CNLocalize/PhaseGate.lua", "post")
    ModLoader.SetupFileHook("lua/Observatory.lua", "lua/CNLocalize/Observatory.lua", "post")
    ModLoader.SetupFileHook("lua/TunnelEntrance.lua", "lua/CNLocalize/TunnelEntrance.lua", "post")

    Shared.Message("[CNCE] CN Localize Client Hooked")
end

if AddHintModPanel then
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    for i = 1, 100 do math.random() end
    
    local titleRandom = math.random(1, 2)
    Shared.Message("[CNCE] Banner Welcome:" .. tostring(titleRandom))
    local cnTitleMaterial = PrecacheAsset(string.format("materials/CNLocalize/Banner_Welcome%d.material",titleRandom))
    AddHintModPanel(cnTitleMaterial, "https://docs.qq.com/doc/DUFlBR0ZJeFRiRnRi","阅读服务器事宜")

    local mutekick = math.random(1, 2)
    Shared.Message("[CNCE] Banner MuteKick:" .. tostring(mutekick))
    local muteKickMaterial = PrecacheAsset(string.format("materials/CNLocalize/Banner_MuteKick%d.material",mutekick))
    AddHintModPanel(muteKickMaterial, "https://docs.qq.com/doc/DWUVmb3FEemlBaFBB","阅读语音净化指南")
end