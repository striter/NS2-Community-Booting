local Plugin = Shine.Plugin(...)

Plugin.Version = "1.0"

Plugin.NotifyPrefixColour = {
    255, 160, 0
}

function Plugin:SetupDataTable()
    local MessageTypes = {
        QueuePosition = {
            Position = "integer"
        }
    }

    self:AddNetworkMessages( "AddTranslatedNotify", {
        [ MessageTypes.QueuePosition ] = {
            "QUEUE_CHANGED", "PIORITY_QUEUE_CHANGED", "QUEUE_ADDED", "PIORITY_QUEUE_ADDED",
            "QUEUE_POSITION", "PIORITY_QUEUE_POSITION", "QUEUE_INFORM", "QUEUE_WELCOME_BACK",
            "QUEUE_CHANGED_VIP", "PIORITY_QUEUE_CHANGED_VIP",
        }
    } )

    self:AddNetworkMessage( "QueueLeft", {}, "Client")
    self:AddNetworkMessage( "WaitTime", { Time = "integer" }, "Client")
end

return Plugin