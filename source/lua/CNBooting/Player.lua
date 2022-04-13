
Script.Load("lua/CNBooting/ModPanelActionFinderMixin.lua")

local oldOnCreate = Player.OnCreate
function Player:OnCreate()
    oldOnCreate(self)
    InitMixin(self, ReadyRoomPlayerActionFinderMixin)
end

function Player:GetCanDieOverride()     --Just die Anyway
    local teamNumber = self:GetTeamNumber()
    return (teamNumber == kTeam1Index or teamNumber == kTeam2Index or teamNumber == kTeamReadyRoom)
end