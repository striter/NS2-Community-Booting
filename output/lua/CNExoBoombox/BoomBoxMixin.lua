
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
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/UED1"), name = "未来への咆哮" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/UED2"), name = "ライオン" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/WeAllLiftTogether"), name = "We All Lift Together" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/seeuagain"), name = "See you again (两倍速)" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/hjmidnightcity"), name = "哈基Midnight City" },
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
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/TheFinals"), name = "The Finals (Season 1)" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/IndustrialHero"), name = "Industrial Hero" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/Aegis"), name = "Aegis" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/ATrueCompetitor"), name = "A True Competitor" },
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
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Ame"), name = "Ame(A)" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/LightDance"), name = "ライトダンス" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/BluSwing"), name = "満ちていく体温" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Time26"), name = "表参道26時" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/P5"), name = "星と僕らと" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/WanderingAround"), name = "アルクアラウンド" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/dnmmm"), name = "电脑眠眠猫" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Elephant"), name = "象" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Flamingo"), name = "Flamingo" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/StepIt"), name = "Step It" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Hear"), name = "聴きたかったダンスミュージック、リキッドルームに" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/DaMeDaNe"), name = "Baka Mitai" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/BloodyStream"), name = "Bloody Stream" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/DevilmanOld"), name = "Devilman" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/RageOfDust"), name = "Rage Of Dust" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/LoveLoop"), name = "恋爱循环" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Monster"), name = "怪物" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/FreesiaLive"), name = "フリージア" },
    },
    [EBoomBoxTrack.SONG] = {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/LikeAHabit"), name = "Like A Habit" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Slumlord"), name = "Slumlord" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Starchild"), name = "Starchild" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/IRemember"), name = "I Remember" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Origami"), name = "Origami" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Rockin"), name = "Rockin'" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/SevenDaysInSundayJune"), name = "Seven Days In Sunday June" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/LastCall"), name = "Last Call" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Metamodernity"), name = "Metamodernity" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/NoGood"), name = "No Good" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/WhenYouGonnaLearn"), name = "When You Gonna Learn?" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/ShipMyBodyBackToTexas"), name = "Ship My Body Back To Texas" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/FreeBird"), name = "Free Bird" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/HowYouLikeMeNow"), name = "How you like me now" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/TheFeelings"), name = "The Feelings" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/WestCoast"), name = "West Coast" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/GreenRiver"), name = "Green River" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/AfterTheDisco"), name = "After the Disco" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/PolishGirl"), name = "Polish Girl" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Valkyrie"), name = "Valkyrie" },
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
            return string.format("%s", kTrackAssets[self.selectedTrack][self.selectedTrackIndex].name)
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