function Observatory:GetDestinationLocationName()

    if self.beaconLocation and self.beaconLocation ~= 0 then
        local location = GetLocationForPoint(self.beaconLocation)
        if location then
            return location and CNResolveLocation(location:GetName()) or ""
        end
    end
    return ""

end

function Observatory:OverrideHintString( hintString, forEntity )

    if not GetAreEnemies(self, forEntity) and self.beaconLocation and self.beaconLocation ~= 0 then
        local location = GetLocationForPoint(self.beaconLocation)
        local locationName = location and location:GetName() or ""
        if locationName and locationName~="" then
            return string.format(Locale.ResolveString( "OBSERVATORY_BEACON_TO_HINT" ), CNResolveLocation(locationName) )
        end
    end

    return hintString

end
