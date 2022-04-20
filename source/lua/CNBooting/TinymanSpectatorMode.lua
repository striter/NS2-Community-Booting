
Script.Load("lua/SpectatorMode.lua")

class 'TinymanSpectatorMode' (SpectatorMode)

function TinymanSpectatorMode:Initialize(spectator)

    spectator:SetIsAlive(true)
    spectator:SetIsVisible(true)
    spectator.controller:SetCollisionEnabled(true)
    spectator:SetPropagate(Entity.Propagate_Always)
    spectator:ResetAnimationGraphState()
    spectator:SetIsThirdPerson(0.3)
end

function TinymanSpectatorMode:Uninitialize(spectator)
    spectator:SetIsAlive(false)
    spectator:SetIsVisible(false)
    spectator:SetVelocity(Vector(0, 0, 0))
    spectator.controller:SetCollisionEnabled(false)
    spectator:SetPropagate(Entity.Propagate_Never)
    spectator:SetIsThirdPerson(0)
end
