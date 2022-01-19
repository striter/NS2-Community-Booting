
if Server then

    local oldUpdateToReadyRoom = NS2Gamerules.UpdateToReadyRoom
    function NS2Gamerules:UpdateToReadyRoom()
        oldUpdateToReadyRoom(self)
        kModPanelsLoaded = true
        OnModPanelsCommand()
    end

end