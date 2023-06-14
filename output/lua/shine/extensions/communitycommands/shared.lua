local Plugin = Shine.Plugin( ... )
local kAdminWarning = { Message = "string (256)"}
Shared.RegisterNetworkMessage( "Shine_PopupWarning", kAdminWarning )

return Plugin