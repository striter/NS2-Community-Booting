
-- Draw the current location on the HUD ("Marine Start", "Processing", etc.)

function PlayerUI_GetLocationName()

    local locationName = ""

    local player = Client.GetLocalPlayer()

    local playerLocation = GetLocationForPoint(player:GetOrigin())

    if player ~= nil and player:GetIsPlaying() then

        if playerLocation ~= nil then

            locationName = CNResolveLocation(playerLocation.name)

        elseif playerLocation == nil and locationName ~= nil then

            locationName = CNResolveLocation(player:GetLocationName())

        elseif locationName == nil then

            locationName = ""

        end

    end

    return locationName

end
