
if Server then

    local oldUpdateToReadyRoom = NS2Gamerules.UpdateToReadyRoom
    function NS2Gamerules:UpdateToReadyRoom()
        oldUpdateToReadyRoom(self)
        kModPanelsLoaded = true
        OnModPanelsCommand()
    end
    
    local baseCanHear = NS2Gamerules.GetCanPlayerHearPlayer
    function NS2Gamerules:GetCanPlayerHearPlayer(listenerPlayer, speakerPlayer, channelType)
        local teamNumber = listenerPlayer:GetTeamNumber()
        canHear = baseCanHear(self,listenerPlayer,speakerPlayer,channelType) or teamNumber == kTeamReadyRoom or teamNumber == kSpectatorIndex
        return canhear
    end
end