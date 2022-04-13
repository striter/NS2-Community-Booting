local baseInitialize = FreeLookSpectatorMode.Initialize
function FreeLookSpectatorMode:Initialize(spectator)

    baseInitialize(self,spectator)
    spectator:SetIsAlive(true)
    spectator:SetIsVisible(true)
    spectator:SetPropagate(Entity.Propagate_Always)
    spectator:CreateController()
    spectator:ResetAnimationGraphState()
    spectator:SetIsThirdPerson(0.3)
end

local baseUninitialize = FreeLookSpectatorMode.Uninitialize
function FreeLookSpectatorMode:Uninitialize(spectator)
    baseUninitialize(self,spectator)
    spectator:SetIsThirdPerson(0)
    spectator:SetIsAlive(false)
    spectator:SetIsVisible(false)
    spectator:SetPropagate(Entity.Propagate_Never)
    spectator:DestroyController()
end
