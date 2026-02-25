
function GUIInsight_Location:Update(deltaTime)
          
    PROFILE("GUIInsight_Location:Update")
    
    if self.locationVisible then
    
        local player = Client.GetLocalPlayer()
        if player == nil then
            return
        end
        
        -- Location Text
        
        local nearestLocation = GetLocationForPoint(player:GetOrigin())
        if nearestLocation == nil then
            nearestLocationName = Locale.ResolveLocation("Unknown")
        else
            nearestLocationName = Locale.ResolveLocation(nearestLocation.name)
        end
        self.locationText:SetText(nearestLocationName)
        self.locationTextBack:SetText(nearestLocationName)
        
    end
    
end