
ModLoader.SetupFileHook( "lua/PlayerInfoEntity.lua", "lua/CNCommunityRank/PlayerInfoEntity.lua", "replace" )
ModLoader.SetupFileHook( "lua/ScoringMixin.lua", "lua/CNCommunityRank/ScoringMixin.lua", "post" )
ModLoader.SetupFileHook( "lua/NS2Utility.lua", "lua/CNCommunityRank/NS2Utility.lua", "post" )
ModLoader.SetupFileHook( "lua/Globals.lua", "lua/CNCommunityRank/Globals.lua", "post" )
ModLoader.SetupFileHook( "lua/ItemUtils.lua", "lua/CNCommunityRank/ItemUtils.lua", "post" )
ModLoader.SetupFileHook( "lua/Scoreboard.lua", "lua/CNCommunityRank/Scoreboard.lua", "replace")
ModLoader.SetupFileHook( "lua/GUIScoreboard.lua", "lua/CNCommunityRank/GUIScoreboard.lua", "replace")