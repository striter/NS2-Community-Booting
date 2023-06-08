
function PhaseGate:GetDestinationLocationName()

    local location = Shared.GetEntity(self.destLocationId)   
    if location then
        return CNResolveLocation(location:GetName())
    end
    
end