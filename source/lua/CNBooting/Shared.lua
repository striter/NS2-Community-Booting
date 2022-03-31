Script.Load("lua/CNBooting/ModPanel.lua")

local kRedirect =
{
    ip = "string (25)"
}

Shared.RegisterNetworkMessage("Redirect", kRedirect)

if Client then
    local function OnClientRedirect(message)
        JoinServer(message.ip,nil)
    end
    Client.HookNetworkMessage("Redirect", OnClientRedirect)
    
end