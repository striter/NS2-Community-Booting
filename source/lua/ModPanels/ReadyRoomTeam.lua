
if Server then
Log("wat")
    local oldInitialize = ReadyRoomTeam.Initialize
    function ReadyRoomTeam:Initialize()
        oldInitialize(self)
        OnModPanelsCommand()
    end

end