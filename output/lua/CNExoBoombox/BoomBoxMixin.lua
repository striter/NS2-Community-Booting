
BoomBoxMixin = CreateMixin( BoomBoxMixin )
BoomBoxMixin.type = "BoomBoxAble"
BoomBoxMixin.networkVars =
{
    musicId = "private entityid",
    selectedTrack  = "enum EBoomBoxTrack",
    selectedTrackIndex = "integer (0 to 16)",
    volume = "integer (0 to 16)",
}

BoomBoxMixin.kTracks = GetBoomBoxTracks()


function BoomBoxMixin:__initmixin()
    -- Shared.Message("Boombox Init")
    self.selectedTrack = EBoomBoxTrack.OST
    self.selectedTrackIndex = 0
    self.musicId = Entity.invalidId

end

if Client then

    function BoomBoxMixin:GetBoomBoxTitle()
        if self.musicId ~= Entity.invalidId then
            return string.format("%s", BoomBoxMixin.kTracks[self.selectedTrack][self.selectedTrackIndex].name)
        end

        return Locale.ResolveString("BOOMBOX_TITLE")
    end

    function BoomBoxMixin:GetBoomBoxAction()
        if self.musicId ~= Entity.invalidId  then
            return Locale.ResolveString("BOOMBOX_STOP")
        end

        return Locale.ResolveString("BOOMBOX_RANDOM")
    end

end

if Server then

    local function Play(self)
        if self.volume == 1
                or self.selectedTrackIndex <= 0
        then return end

        local tracks = BoomBoxMixin.kTracks[self.selectedTrack]
        local track = tracks[self.selectedTrackIndex]
        local asset = PrecacheAsset(track.asset)
        if track.assetBattle and self.GetIsInCombat and self:GetIsInCombat() then
            asset = PrecacheAsset(track.assetBattle)
        end
        local music = StartSoundEffectOnEntity(asset,self,1)
        self.musicId = music:GetId()
        self:SetRelevancyDistance(kMaxRelevancyDistance)
    end

    function BoomBoxMixin:SwitchTrack(_trackIndex)
        self:DestroyMusic()

        if self.selectedTrack ~= _trackIndex then
            self.selectedTrackIndex = 0
        end

        self.selectedTrack = _trackIndex
        self.selectedTrackIndex = self.selectedTrackIndex + 1
        if  self.selectedTrackIndex > #BoomBoxMixin.kTracks[self.selectedTrack] then
            self.selectedTrackIndex = 1
        end

        self.selectedTrack = _trackIndex
        Play(self)
    end

    function BoomBoxMixin:Action()
        if self.musicId ~= Entity.invalidId then
            self:DestroyMusic()
            return
        end
        self.selectedTrack = math.random(#EBoomBoxTrack)
        self.selectedTrackIndex = math.random(#BoomBoxMixin.kTracks[self.selectedTrack])
        Play(self)
    end

    function BoomBoxMixin:TransferMusic(_from)
        self.selectedTrack = _from.selectedTrack
        self.selectedTrackIndex = _from.selectedTrackIndex
        if _from.musicId ~= Entity.invalidId then
            local musicEntity = Shared.GetEntity(_from.musicId)
            if musicEntity and musicEntity.GetIsPlaying then
                self.musicId = musicEntity:GetId()
                self:SetRelevancyDistance(Math.infinity)
                musicEntity:SetParent(self)
            end

            _from.musicId = Entity.invalidId
        end
    end

    function BoomBoxMixin:DestroyMusic()
        if self.musicId ~= Entity.invalidId then
            local musicEntity = Shared.GetEntity(self.musicId)
            if musicEntity and musicEntity.GetIsPlaying and musicEntity:GetIsPlaying() and musicEntity.Stop then
                musicEntity:Stop()
                DestroyEntity(musicEntity)
            end
            self.musicId = Entity.invalidId
        end
    end

    --For exosuit's messy states
    function BoomBoxMixin:SaveMusic()
        local id = self.musicId
        self.musicId = Entity.invalidId
        if id ~= Entity.invalidId then
            local musicEntity = Shared.GetEntity(id)
            musicEntity:SetParent(nil)
        end

        return id
    end

    function BoomBoxMixin:ReleaseMusic(_id, _target)
        self.musicId = _id
        if _target then
            _target:TransferMusic(self)
            return
        end
        self:DestroyMusic()
    end

    function BoomBoxMixin:OnKill()
        self:DestroyMusic()
    end

    function BoomBoxMixin:OnDestroy()
        self:DestroyMusic()
    end

end