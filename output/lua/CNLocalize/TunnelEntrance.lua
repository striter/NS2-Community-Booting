
function TunnelEntrance:GetDestinationLocationName()

    local location = Shared.GetEntity(self.destLocationId)
    if location then
        return Locale.ResolveLocation(location:GetName())
    end
    
end