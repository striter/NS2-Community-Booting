if Client then
    local baseOnInitialized = SoundEffect.OnInitialized
    function SoundEffect:OnInitialized()
        baseOnInitialized(self)
        local assetName = Shared.GetSoundName(self.assetIndex)
        self.voiceOverSound = string.find(assetName, "CNTaunts.fev") ~= nil
        self.voiceOverValidate = self.voiceOverSound
    end

    function SoundEffect:ValidateVoiceOverVolume()
        if not self.voiceOverValidate then return end
        if not self.playing or not self.soundEffectInstance then return end
        self.voiceOverValidate = false
        self:UpdateVoiceOverVolume()
    end

    function SoundEffect:UpdateVoiceOverVolume()
        if not self.voiceOverSound then return end

        local volume = OptionsDialogUI_GetSoundVolume() / 100
        volume = volume * Client.GetOptionFloat(kCNVoiceOverConfig.VolumePath,kCNVoiceOverConfig.VolumeDefault)
        if self.volume ~= volume then
            self.volume = volume
            self.soundEffectInstance:SetVolume(volume)
        end
    end

    local baseOnUpdate = SoundEffect.OnUpdate
    function SoundEffect:OnUpdate(deltaTime)
        baseOnUpdate(self)
        self:ValidateVoiceOverVolume()
    end

    local baseOnProcessMove = SoundEffect.OnProcessMove
    function SoundEffect:OnProcessMove()
        baseOnProcessMove(self)
        self:ValidateVoiceOverVolume()
    end

    local baseOnProcessSpectate = SoundEffect.OnProcessSpectate
    function SoundEffect:OnProcessSpectate()
        baseOnProcessSpectate(self)
        self:ValidateVoiceOverVolume()
    end
end
