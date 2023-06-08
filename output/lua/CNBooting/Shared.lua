Script.Load("lua/CNBooting/ModPanel.lua")

local kRedirect =
{
    ip = "string (25)"
}

Shared.RegisterNetworkMessage("Redirect", kRedirect)

if Client then
    local function OnClientRedirect(message)
        Shared.Message("[CNCE] Connect Message Received:" .. message.ip)
        JoinServer(message.ip,nil)
    end
    Client.HookNetworkMessage("Redirect", OnClientRedirect)
    
end