
ModLoader.SetupFileHook( "lua/PlayerInfoEntity.lua", "lua/CNCommunityRank/PlayerInfoEntity.lua", "replace" )
ModLoader.SetupFileHook( "lua/ScoringMixin.lua", "lua/CNCommunityRank/ScoringMixin.lua", "post" )
ModLoader.SetupFileHook( "lua/NS2Utility.lua", "lua/CNCommunityRank/NS2Utility.lua", "post" )
ModLoader.SetupFileHook( "lua/Globals.lua", "lua/CNCommunityRank/Globals.lua", "post" )
ModLoader.SetupFileHook( "lua/ItemUtils.lua", "lua/CNCommunityRank/ItemUtils.lua", "post" )
ModLoader.SetupFileHook( "lua/Scoreboard.lua", "lua/CNCommunityRank/Scoreboard.lua", "replace")
ModLoader.SetupFileHook( "lua/GUIScoreboard.lua", "lua/CNCommunityRank/GUIScoreboard.lua", "replace")

--CallingCards
ModLoader.SetupFileHook("lua/GUIDeathScreen2.lua", "lua/CNCommunityRank/CallingCards/GUIDeathScreen2.lua", "post")
ModLoader.SetupFileHook( "lua/DeathMessage_Client.lua", "lua/CNCommunityRank/CallingCards/DeathMessage_Client.lua", "replace")
ModLoader.SetupFileHook( "lua/menu2/PlayerScreen/CallingCards/GUIMenuCallingCardCustomizer.lua", "lua/CNCommunityRank/CallingCards/GUIMenuCallingCardCustomizer.lua", "post")
ModLoader.SetupFileHook( "lua/menu2/PlayerScreen/CallingCards/GUIMenuCallingCardData.lua", "lua/CNCommunityRank/CallingCards/GUIMenuCallingCardData.lua", "replace")

ModLoader.SetupFileHook( "lua/menu2/PlayerScreen/CallingCards/GUIMenuCallingCard.lua", "lua/CNCommunityRank/CallingCards/GUIMenuCallingCard.lua", "post")


--Rewards
ModLoader.SetupFileHook( "lua/menu2/MissionScreen/GMTDRewardsScreen.lua", "lua/CNCommunityRank/Rewards/GMTDRewardsScreen.lua", "post")
