Script.Load("lua/CNExoBoomBox/BoomBoxMixin.lua")
Shared.LinkClassToMap("Exo", Exo.kMapName, BoomBoxMixin.networkVars, true)
local baseOninitialized = Exo.OnInitialized
function Exo:OnInitialized()
    baseOninitialized(self)
    InitMixin(self,BoomBoxMixin)
end

local originalHandleButtons = Exo.HandleButtons
function Exo:HandleButtons(input)
    originalHandleButtons(self, input)

    if not self.pressingMusicButtons and bit.band(input.commands, Move.Weapon1 + Move.Weapon2 + Move.Weapon3 + Move.Weapon4 + Move.Weapon5) ~= 0 then
        self.pressingMusicButtons = true

        if Server then
            -- Do track selection
            if bit.band(input.commands,Move.Weapon1) ~= 0 then
                self:SwitchTrack(EBoomBoxTrack.CUSTOM)
            end

            if bit.band(input.commands,Move.Weapon2) ~= 0 then
                self:SwitchTrack(EBoomBoxTrack.OST)
            end

            if bit.band(input.commands,Move.Weapon3) ~= 0 then
                self:SwitchTrack(EBoomBoxTrack.TWO)
            end

            if bit.band(input.commands,Move.Weapon4) ~= 0 then
                self:SwitchTrack(EBoomBoxTrack.SONG)
            end

            if bit.band(input.commands,Move.Weapon5) ~= 0 then
                self:Action()
            end
        end
        
    else
        self.pressingMusicButtons = false
    end
end

if Server then
    -- can't simply extend due to local var, gotta replace
    function Exo:PerformEject()
      if self:GetIsAlive() then

          -- pickupable version
          local exosuit = CreateEntity(Exosuit.kMapName, self:GetOrigin(), self:GetTeamNumber())
          exosuit:SetLayout(self.layout)
          exosuit:SetCoords(self:GetCoords())
          exosuit:SetMaxArmor(self:GetMaxArmor())
          exosuit:SetArmor(self:GetArmor())
          exosuit:SetExoVariant(self:GetExoVariant())
          exosuit:SetFlashlightOn(self:GetFlashlightOn())
          exosuit:TransferParasite(self)
-------------------
          exosuit:TransferMusic(self)
--------------------

          -- Set the auto-weld cooldown of the dropped exo to match the cooldown if we weren't
          -- ejecting just now.
          local combatTimeEnd = math.max(self:GetTimeLastDamageDealt(), self:GetTimeLastDamageTaken()) + kCombatTimeOut
          local cooldownEnd = math.max(self.timeNextWeld, combatTimeEnd)
          local now = Shared.GetTime()
          local combatTimeRemaining = math.max(0, cooldownEnd - now)
          exosuit.timeNextWeld = now + combatTimeRemaining
          
          local reuseWeapons = self.storedWeaponsIds ~= nil

          local marine = self:Replace(self.prevPlayerMapName or Marine.kMapName, self:GetTeamNumber(), false, self:GetOrigin() + Vector(0, 0.2, 0), { preventWeapons = reuseWeapons })
          marine:SetHealth(self.prevPlayerHealth or kMarineHealth)
          marine:SetMaxArmor(self.prevPlayerMaxArmor or kMarineArmor)
          marine:SetArmor(self.prevPlayerArmor or kMarineArmor)

          exosuit:SetOwner(marine)

          marine.onGround = false
          local initialVelocity = self:GetViewCoords().zAxis
          initialVelocity:Scale(4)
          initialVelocity.y = math.max(0,initialVelocity.y) + 9
          marine:SetVelocity(initialVelocity)

          if reuseWeapons then

              for _, weaponId in ipairs(self.storedWeaponsIds) do

                  local weapon = Shared.GetEntity(weaponId)
                  if weapon then
                      marine:AddWeapon(weapon)
                  end

              end

          end

          marine:SetHUDSlotActive(1)

          if marine:isa("JetpackMarine") then
              marine:SetFuel(0.25)
          end

      end

      return false

    end
end


