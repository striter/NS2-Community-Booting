
Script.Load("lua/CNBooting/ReadyRoomPlayerActionFinderMixin.lua")

local oldOnCreate = Player.OnCreate
function Player:OnCreate()
    InitMixin(self, ReadyRoomPlayerActionFinderMixin)
    oldOnCreate(self)
    
end
