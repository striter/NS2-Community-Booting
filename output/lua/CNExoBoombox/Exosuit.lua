
Script.Load("lua/CNExoBoomBox/BoomBoxMixin.lua")
Shared.LinkClassToMap("Exosuit", Exosuit.kMapName, BoomBoxMixin.networkVars)
local baseOninitialized = Exosuit.OnInitialized
function Exosuit:OnInitialized()
    baseOninitialized(self)
    InitMixin(self,BoomBoxMixin)
end

if Server then
    local baseUseDeferred = Exosuit.OnUseDeferred
    function Exosuit:OnUseDeferred()
        local owner = self:GetOwner()
        if not owner then
            baseUseDeferred(self)
            return
        end
        
        local ownerId = owner:GetClientIndex() 
        local musicId = self:SaveMusic()

        baseUseDeferred(self)
        
        local exoOwner = Server.GetClientById(ownerId)
        local exoPlayer = exoOwner and exoOwner:GetPlayer()
        if exoPlayer and not exoPlayer.TransferMusic then
            exoPlayer = nil
        end
        self:ReleaseMusic(musicId,exoPlayer)
    end
end
