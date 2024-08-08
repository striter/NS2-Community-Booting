if Client then
    
    local baseOnInitialized = SoundEffect.OnInitialized
    function SoundEffect:OnInitialized()
        baseOnInitialized(self)
        local assetName = Shared.GetSoundName(self.assetIndex)
        self.boomBoxSound = string.find(assetName, "CNBoomBox.fev") ~= nil
        self.boomboxValidate = self.boomBoxSound
    end
    
    function SoundEffect:ValidateBoomBoxVolume()
        if not self.boomboxValidate then return end
        if not self.playing or not self.soundEffectInstance then return end
        self.boomboxValidate = false
        self:UpdateBoomBoxVolume()
    end
    
    function SoundEffect:UpdateBoomBoxVolume()
        if not self.boomBoxSound then return end
        
        local assetName = Shared.GetSoundName(self.assetIndex)
        local volumeConfigPath = nil
        for k,v in pairs(gBoomBoxDefine) do
            if string.find(assetName,EnumToString(EBoomBoxTrack,k)) then
                volumeConfigPath = v.configPath
                break
            end
        end

        if volumeConfigPath == nil then return end

        local volume = OptionsDialogUI_GetSoundVolume() / 100
        volume = volume * OptionsDialogUI_GetMusicVolume() / 100
        volume = volume * Client.GetOptionFloat(volumeConfigPath,kBoomBoxDefaultValue)
        if self.volume ~= volume then
            self.volume = volume
            self.soundEffectInstance:SetVolume(volume)
        end
    end

    local baseOnUpdate = SoundEffect.OnUpdate
    function SoundEffect:OnUpdate(deltaTime)
        baseOnUpdate(self)
        self:ValidateBoomBoxVolume()
    end

    local baseOnProcessMove = SoundEffect.OnProcessMove
    function SoundEffect:OnProcessMove()
        baseOnProcessMove(self)
        self:ValidateBoomBoxVolume()
    end

    local baseOnProcessSpectate = SoundEffect.OnProcessSpectate
    function SoundEffect:OnProcessSpectate()
        baseOnProcessSpectate(self)
        self:ValidateBoomBoxVolume()
    end
end
