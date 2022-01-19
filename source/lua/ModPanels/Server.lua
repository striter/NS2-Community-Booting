Log("waaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaat")
local oldCreateLiveMapEntities = CreateLiveMapEntities
function CreateLiveMapEntities()
    oldCreateLiveMapEntities(self)
    OnModPanelsCommand()
    kModPanelsLoaded = true
end
