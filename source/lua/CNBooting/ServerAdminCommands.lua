
CreateServerAdminCommand("Console_modpanels", function() OnModPanelsCommand() end, "Spawn the mod panels again")


local function DoServerRedirect(client,...)
    local targetIP = string.UTF8Sub(StringConcatArgs(...), 1, 25)
    -- Shared.Message("Server" .. targetIP)
    Server.SendNetworkMessage("Redirect",{ ip = targetIP }, true)
end

CreateServerAdminCommand("Console_sv_redir", DoServerRedirect, "<string>,force all client connect the ip")