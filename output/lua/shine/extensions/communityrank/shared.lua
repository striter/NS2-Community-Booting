
local Plugin = Shine.Plugin( ... )
Shared.RegisterNetworkMessage( "Shine_CommunityTier", {
    Tier = "integer (0 to 16)",
    TimePlayed = "integer (0 to 8192)",
    RoundWin = "integer (0 to 2048)",
    TimePlayedCommander = "integer (0 to 8192)",
    RoundWinCommander = "integer (0 to 2048)",
} )
return Plugin
