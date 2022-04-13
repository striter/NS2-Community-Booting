    local baseGetCanHearPlayer =NS2Gamerules.GetCanPlayerHearPlayer
    function NS2Gamerules:GetCanPlayerHearPlayer(listenerPlayer, speakerPlayer, channelType)
        local canHear = baseGetCanHearPlayer(self,listenerPlayer,speakerPlayer,channelType)

        if not canHear and listenerPlayer:GetTeamNumber() == kTeamReadyRoom then
            canHear =true
        end
        return canHear
    end