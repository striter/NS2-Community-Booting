
--- why?
function NSLBadgesManager:OnClientConnect(newClient)

    --self.clientsWaiting:Add(newClient)
    --
    ---- We have the data already, go ahead and send it to our new client.
    --if self.status == kBadgeStatus.RequestSuccess then
    --    self:SendTeamPlacementDataToWaitingClients()
    --end

end

function NSLBadgesManager:OnClientDisconnect(disconnectingClient)
    
    --if self.clientsWaiting:Contains(disconnectingClient) then
    --    self.clientsWaiting:RemoveElement(disconnectingClient)
    --end
end
