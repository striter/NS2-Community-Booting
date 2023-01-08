
local baseGetMaxSpeed = Onos.GetMaxSpeed
function Onos:GetMaxSpeed(possible)
    return baseGetMaxSpeed(self,possible) * GTinySpeedMultiplier(self)
end