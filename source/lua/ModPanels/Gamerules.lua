
if Server then
Log("wat")
    local oldOnMapPostLoad = Gamerules.OnMapPostLoad
    function Gamerules:OnMapPostLoad()
        oldOnMapPostLoad(self)
        Log("Spawning mod panels")
        OnModPanelsCommand()
    end

end