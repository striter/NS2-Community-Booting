
function ReadyRoomExo:HandleBoomboxButtons(input)

    if not self.pressingMusicButtons and bit.band(input.commands, Move.Weapon1 + Move.Weapon2 + Move.Weapon3 + Move.Weapon4 + Move.Weapon5 + Move.Reload) ~= 0 then
        self.pressingMusicButtons = true

        if Server then
            -- Do track selection
            if bit.band(input.commands,Move.Weapon1) ~= 0 then
                self:SwitchTrack(EBoomBoxTrack.Calm)
            end

            if bit.band(input.commands,Move.Weapon2) ~= 0 then
                self:SwitchTrack(EBoomBoxTrack.Calm)
            end

            if bit.band(input.commands,Move.Weapon3) ~= 0 then
                self:SwitchTrack(EBoomBoxTrack.Calm)
            end

            if bit.band(input.commands,Move.Weapon4) ~= 0 then
                self:SwitchTrack(EBoomBoxTrack.Calm)
            end

            if bit.band(input.commands,Move.Weapon5) ~= 0 then
                self:SwitchTrack(EBoomBoxTrack.Calm)
            end

            if bit.band(input.commands,Move.Reload) ~= 0 then
                self:Action()
            end
        end

    else
        self.pressingMusicButtons = false
    end

end