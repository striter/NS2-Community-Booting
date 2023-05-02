
Script.Load("lua/SpectatorMode.lua")

class 'TinymanSpectatorMode' (SpectatorMode)

local kModelName = PrecacheAsset("models/props/descent/descent_arcade_gorgetoy_01.model")
function TinymanSpectatorMode:Initialize(spectator)
    Player.SetScale(spectator,0.5)
    spectator:SetModel(kModelName)
    spectator:SetIsAlive(true)
    spectator:SetIsVisible(true)
    spectator.controller:SetCollisionEnabled(true)
    spectator:SetPropagate(Entity.Propagate_Always)
    spectator:ResetAnimationGraphState()
    spectator:SetIsThirdPerson(0.3)
end

function TinymanSpectatorMode:Uninitialize(spectator)
    Player.SetScale(spectator,1)
    spectator:SetIsAlive(false)
    spectator:SetIsVisible(false)
    spectator:SetVelocity(Vector(0, 0, 0))
    spectator.controller:SetCollisionEnabled(false)
    spectator:SetPropagate(Entity.Propagate_Never)
    spectator:SetIsThirdPerson(0)
end
