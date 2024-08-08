
BoomBoxMixin = CreateMixin( BoomBoxMixin )
BoomBoxMixin.type = "BoomBoxAble"
BoomBoxMixin.networkVars =
{
    musicId = "private entityid",
    selectedTrack  = "enum EBoomBoxTrack",
    selectedTrackIndex = "integer (0 to 16)",
    volume = "integer (0 to 16)",
}

local kTrackAssets = {
    [EBoomBoxTrack.CUSTOM]  =  {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/ygkldnh"), name = "阳光开朗大男孩" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/hjm"), name = "哈基基米慌慌" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/GetOverTheWorld"), name = "Get Over The World" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/WonderFunnyHarmony"), name = "Wonder Funny Harmony" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/zxmzf"), name = "最炫民族风" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/cjdl"), name = "不眠之夜" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/Girl"), name = "恋爱困难女孩" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/LOTUS"), name = "美丽的神话" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/Youngthink"), name = "ヰ世界の宝石譚" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/SonOfTheGround"), name = "大地之子-沙林mix" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/ClearMorning"), name = "Clear Morning" },
    },
    [EBoomBoxTrack.OST]  = {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/2077"), name = "The Rebel Path" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/PTSD"), name = "PTSD" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/RisingTide"), name = "Rising Tide" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/Castlevania"), name = "狂月の招き" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/MMFight"), name = "激闘" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/HLA"), name = "Gravity Perforation Detail" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/GTAV"), name = "No Happy Endings" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/VortalCombat"), name = "Vortal Combat" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/EXO"), name = "Exosuit" },
        
    },
    [EBoomBoxTrack.TWO] = {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/TWO/WanderingAround"), name = "アルクアラウンド" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/TWO/Flamingo"), name = "Flamingo" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/TWO/StepIt"), name = "Step It" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/TWO/Hear"), name = "聴きたかったダンスミュージック、リキッドルームに" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/TWO/DaMeDaNe"), name = "Baka Mitai" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/TWO/BloodyStream"), name = "Bloody Stream" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/TWO/DevilmanOld"), name = "Devilman" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/TWO/RageOfDust"), name = "Rage Of Dust" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/TWO/LoveLoop"), name = "恋爱循环" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/TWO/Monster"), name = "怪物" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/TWO/FreesiaLive"), name = "フリージア" },
    },
    [EBoomBoxTrack.SONG] = {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/Slumlord"), name = "Slumlord" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/NoGood"), name = "No Good" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/WhenYouGonnaLearn"), name = "When You Gonna Learn?" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/ShipMyBodyBackToTexas"), name = "Ship My Body Back To Texas" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/FreeBird"), name = "Free Bird" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/HowYouLikeMeNow"), name = "How you like me now" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/TheFeelings"), name = "The Feelings" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/WestCoast"), name = "West Coast" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/GreenRiver"), name = "Green River" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/AfterTheDisco"), name = "After the Disco" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/SureEnough"), name = "Sure Enough" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/HideAway"), name = "Hide Away" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/PolishGirl"), name = "Polish Girl" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/SONG/Valkyrie"), name = "Valkyrie" },
    },
}

function BoomBoxMixin:__initmixin()
    -- Shared.Message("Boombox Init")
    self.selectedTrack = EBoomBoxTrack.OST
    self.selectedTrackIndex = 0
    self.musicId = Entity.invalidId

end

if Client then
    
    function BoomBoxMixin:GetBoomBoxTitle()
        if self.musicId ~= Entity.invalidId then
            return string.format("<%s>", kTrackAssets[self.selectedTrack][self.selectedTrackIndex].name)
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

        local tracks = kTrackAssets[self.selectedTrack]
        local music = StartSoundEffectOnEntity(tracks[self.selectedTrackIndex].asset,self,1)
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
        if  self.selectedTrackIndex > #kTrackAssets[self.selectedTrack] then
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
        self.selectedTrackIndex = math.random(#kTrackAssets[self.selectedTrack])
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