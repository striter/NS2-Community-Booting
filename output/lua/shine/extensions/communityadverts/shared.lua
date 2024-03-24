
local Plugin = Shine.Plugin( ... )
Shared.RegisterNetworkMessage( "Shine_Announcement", {
    identity = "string (128)",
    message = "string (1024)",
} )
return Plugin
