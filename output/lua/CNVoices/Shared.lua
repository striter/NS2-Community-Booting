Shared.RegisterNetworkMessage("RandomDisease", {})

if Client then
    local function OnClientRedirect(message)
        Shared.ConsoleCommand("randomdisease")
    end
    Client.HookNetworkMessage("RandomDisease", OnClientRedirect)
end