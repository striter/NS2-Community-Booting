
Shared.RegisterNetworkMessage("SwitchLocalize", {})

if Client then

    --local function OnConsoleHttp(url)
    --    Shared.Message("Pending:" .. url)
    --    Shared.SendHTTPRequest(url,"GET",{},function(response)
    --        Shared.Message(response) 
    --    end)
    --end
    --
    --Event.Hook("Console_http", OnConsoleHttp)


    --Core
    if not Locale.kTranslateMessage then
        Locale.kTranslateMessage = {}
        Locale.kLocales = {}
    end
    Locale.kForceLocalize = true
    if CNPersistent and CNPersistent.forceLocalize ~= nil then
        Locale.kForceLocalize = CNPersistent.forceLocalize
    end
    if Locale.kForceLocalize then
        Locale.kCommunityGuideTable = {
            mainPulloutTitle = "欢迎来到<物竞天择2中国社区>",
            subPulloutTitle = "点击查看指南",

            urlTitle = "物竞天择2中国社区 - 指南",
            url = "https://docs.qq.com/doc/DUFlBR0ZJeFRiRnRi",
        }
    else
        Locale.kCommunityGuideTable = {
            mainPulloutTitle = "Welcome to <NS2CN>",
            subPulloutTitle = "Click to read Guide",

            urlTitle = "<NS2CN> Community Guide",
            url = "https://docs.qq.com/doc/DUFVkbnBiSlVMb3Nx",
        }
    end

    -- Fonts Fix
    local hasFontAssetsPatched = GetFileExists("CNFontAssets.readme")
    if not hasFontAssetsPatched then
        ModLoader.SetupFileHook("lua/GUIAssets.lua", "lua/CNLocalize/GUIAssets.lua", "replace")
        ModLoader.SetupFileHook("lua/GUI/FontGlobals.lua", "lua/CNLocalize/FontGlobals.lua", "replace")
    end

    Script.Load("lua/CNLocalize/CNStringsMenu.lua")
    ModLoader.SetupFileHook("lua/Locale.lua", "lua/CNLocalize/CNStrings.lua", "post")
    local baseGetCurrentLanguage = Locale.GetCurrentLanguage
    local function CNGetCurrentLanguage()
        return Locale.kForceLocalize and "zhCN" or baseGetCurrentLanguage(self)
    end
    Locale.GetCurrentLanguage = CNGetCurrentLanguage

    --Locations
    Locale.kTranslateLocations = {}
    ModLoader.SetupFileHook("lua/Locale.lua", "lua/CNLocalize/CNLocations.lua", "post")
    function Locale.ResolveLocation(input)
        if not Locale.kForceLocalize then return input end
        return Locale.kTranslateLocations[input] or input
    end

    Client.HookNetworkMessage("SwitchLocalize", function(message)
        Locale.SetLocalize(not Locale.kForceLocalize)
    end )

    function Locale.SetLocalize(_value)
        Locale.kForceLocalize = _value
        if CNPersistent then
            CNPersistent.forceLocalize = Locale.kForceLocalize
            CNPersistentSave()
        end
    end

    local baseResolveString = Locale.ResolveString
    local function CNLocalizeResolve(input)
        if not input then return "" end

        local resolvedString = Locale.kForceLocalize and rawget(Locale.kTranslateMessage,input) or nil
        resolvedString = resolvedString or rawget(Locale.kLocales,input)
        return resolvedString or baseResolveString(input)
    end
    Locale.ResolveString = CNLocalizeResolve

    ModLoader.SetupFileHook("lua/GUIMinimap.lua", "lua/CNLocalize/GUIMinimap.lua", "post")
    ModLoader.SetupFileHook("lua/GUIUnitStatus.lua", "lua/CNLocalize/GUIUnitStatus.lua", "replace")
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
    ModLoader.SetupFileHook("lua/GUIWaypoints.lua", "lua/CNLocalize/GUIWaypoints.lua", "post" )
    ModLoader.SetupFileHook("lua/GUINotifications.lua", "lua/CNLocalize/GUINotifications.lua", "post")

    --Customization
    ModLoader.SetupFileHook("lua/menu2/PlayerScreen/Customize/GUIMenuCustomizeScreen.lua", "lua/CNLocalize/Customize/GUIMenuCustomizeScreen.lua", "replace" )
    ModLoader.SetupFileHook("lua/menu2/PlayerScreen/GUIMenuPlayerScreen.lua", "lua/CNLocalize/Customize/GUIMenuPlayerScreen.lua", "replace" )

    --Menu GUI
    ModLoader.SetupFileHook("lua/menu2/GUIMainMenu.lua", "lua/CNLocalize/GUI/GUIMainMenu.lua", "post")
    ModLoader.SetupFileHook("lua/menu2/NavBar/GUIMenuNavBar.lua", "lua/CNLocalize/GUI/GUIMenuNavBar.lua", "post")
    ModLoader.SetupFileHook("lua/menu2/NavBar/Screens/News/GUIMenuNewsFeedPullout.lua", "lua/CNLocalize/GUI/GUIMenuNewsFeedPullout.lua", "replace")

    --Chat Filter
    Script.Load("lua/CNLocalize/ChatFilters.lua")
    function CNChatFilter(input)
        return string.gsub(input, "%w+",kChatFilters)
    end
    Locale.ChatFilter = CNChatFilter


    --Spectator
    ModLoader.SetupFileHook("lua/GUIInsight_Location.lua", "lua/CNLocalize/Spectator/GUIInsight_Location.lua", "post")
    ModLoader.SetupFileHook("lua/GUIInsight_TechPoints.lua", "lua/CNLocalize/Spectator/GUIInsight_TechPoints.lua", "replace")
    ModLoader.SetupFileHook("lua/GUIInsight_PlayerFrames.lua", "lua/CNLocalize/Spectator/GUIInsight_PlayerFrames.lua", "replace")


end