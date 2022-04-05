
local Plugin = Shine.Plugin( ... )
Shared.RegisterNetworkMessage( "Shine_CommunityTier", { Tier = "integer (0 to 16)",} )
return Plugin
