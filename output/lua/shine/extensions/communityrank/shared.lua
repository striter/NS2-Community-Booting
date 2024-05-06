
local Plugin = Shine.Plugin( ... )
Shared.RegisterNetworkMessage( "Shine_CommunityTier", {
    Tier = "integer (0 to 16)",
    RoundWin = "integer (0 to 4096)",
    RoundWinCommander = "integer (0 to 4096)",
    TimePlayed = "integer (0 to 16777216)",
    TimePlayedCommander = "integer (0 to 16777216)",
} )
return Plugin
