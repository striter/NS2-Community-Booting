ModLoader.SetupFileHook("lua/Weapons/Alien/Web.lua", "lua/CNBugFixing/Web.lua", "post")
ModLoader.SetupFileHook("lua/bots/LocationGraph.lua", "lua/CNBugFixing/LocationGraph.lua", "post")
ModLoader.SetupFileHook("lua/bots/LocationContention.lua", "lua/CNBugFixing/LocationContention.lua", "post")
ModLoader.SetupFileHook("lua/NSLBadges/NSLBadgesManager.lua", "lua/CNBugFixing/NSLBadgesManager.lua", "post")
ModLoader.SetupFileHook("lua/NS2Gamerules.lua", "lua/CNBugFixing/NS2Gamerules.lua", "post")
ModLoader.SetupFileHook("lua/RoboticsFactory.lua", "lua/CNBugFixing/RoboticsFactory.lua", "post")
ModLoader.SetupFileHook("lua/bots/BotUtils.lua", "lua/CNBugFixing/BotUtils.lua", "post" )
--ModLoader.SetupFileHook("lua/Cyst.lua", "lua/CNBugFixing/Cyst.lua", "post")

--From LoadCrashFix
--if Client then
--    if Shared.ConsoleCommand then
--        Shared.ConsoleCommand("f_cache false")
--    else
--        Event.Hook("LoadComplete", function()
--            Shared.ConsoleCommand("f_cache false")
--        end)
--    end
--end
 
