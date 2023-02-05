
local Plugin = Shine.Plugin( ... )
Plugin.EnabledGamemodes = {
	["ns2"] = true,
    ["NS2.0"] = true,
    ["siege+++"] = true,
}

Shared.RegisterNetworkMessage( "Shine_CommunityTier", { Tier = "integer (0 to 16)",} )
return Plugin
