

Script.Load("lua/Marine.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/JumpMoveMixin.lua")
Script.Load("lua/Mixins/CrouchMoveMixin.lua")
Script.Load("lua/Mixins/LadderMoveMixin.lua")

Shared.LinkClassToMap("Spectator", Spectator.kMapName, GroundMoveMixin.networkVars)
Shared.LinkClassToMap("Spectator", Spectator.kMapName, JumpMoveMixin.networkVars)
Shared.LinkClassToMap("Spectator", Spectator.kMapName, CrouchMoveMixin.networkVars)
Shared.LinkClassToMap("Spectator", Spectator.kMapName, LadderMoveMixin.networkVars)
Shared.LinkClassToMap("Spectator", Spectator.kMapName, {specMode = "enum kSpectatorMode"})

local baseOnCreate = Spectator.OnCreate
function Spectator:OnCreate()

    baseOnCreate(self)
    InitMixin(self, GroundMoveMixin)
    InitMixin(self, JumpMoveMixin)
    InitMixin(self, CrouchMoveMixin)
    InitMixin(self, LadderMoveMixin)
    self.scale = 0.2
end

function Spectator:GetIsVisible()
    return self.specMode == kSpectatorMode.FreeLook
end

function Spectator:OnAdjustModelCoords(modelCoords)
    local coords = modelCoords
    coords.xAxis = coords.xAxis * self.scale
    coords.yAxis = coords.yAxis * self.scale
    coords.zAxis = coords.zAxis * self.scale
    return coords
end

local baseGetTraceCapsule = Spectator.GetTraceCapsule
function Spectator:GetTraceCapsule()
    local height,radius = baseGetTraceCapsule(self)
    height = height * self.scale
    radius = radius * self.scale
    return height,radius
end

local baseGetControllerSize = Spectator.GetControllerSize
function Spectator:GetControllerSize()
    local height,radius = baseGetControllerSize(self)
    height = height * self.scale
    radius = radius * self.scale
    return height,radius
end

-- function Spectator:GetCanDieOverride()
--     return self.specMode == kSpectatorMode.FreeLook
-- end

local kPlayerHeight = Player.kYExtents * 2 - 0.2
function Spectator:OnPostUpdateCamera()
    local offset = -self:GetCrouchShrinkAmount() * self:GetCrouchAmount()
    self:SetCameraYOffset(kPlayerHeight*(self.scale-1) + offset *self.scale)
end

local baseGetMaxSpeed =  Spectator.GetMaxSpeed
function Spectator:GetMaxSpeed(possible)
    local activating = self.specMode == kSpectatorMode.FreeLook
    return activating and (Player.kWalkMaxSpeed  * ( 0.5 +  self.scale * 0.5))  or baseGetMaxSpeed(self,possible) 
end

local baseGetAcceleration = Spectator.GetAcceleration
function Spectator:GetAcceleration()
    local activating = self.specMode == kSpectatorMode.FreeLook
    return activating and (13 * self:GetSlowSpeedModifier()) or baseGetAcceleration(self)
end

local baseModifyGravityForce = Spectator.ModifyGravityForce
function Spectator:ModifyGravityForce(gravityTable)
    baseModifyGravityForce(self,gravityTable)
    gravityTable.gravity = gravityTable.gravity* 0.5
end

-- Function Below here to remove jump-key spec mode switch,but why?
local kDeltatimeBetweenAction = 0.3
local function UpdateSpectatorMode(self, input)

    assert(Server)

    self.timeFromLastAction = self.timeFromLastAction + input.time
    if self.timeFromLastAction > kDeltatimeBetweenAction then

        -- if bit.band(input.commands, Move.Jump) ~= 0 then

        --     self:SetSpectatorMode(NextSpectatorMode(self))
        --     self.timeFromLastAction = 0

        --     if self:GetIsOverhead() then
        --         self:ResetOverheadModeHeight()
        --     end

        if bit.band(input.commands, Move.Weapon1) ~= 0 then

            self:SetSpectatorMode(kSpectatorMode.FreeLook)
            self.timeFromLastAction = 0

        elseif bit.band(input.commands, Move.Weapon2) ~= 0 then

            self:SetSpectatorMode(kSpectatorMode.Overhead)
            self.timeFromLastAction = 0
            self:ResetOverheadModeHeight()

        elseif bit.band(input.commands, Move.Weapon3) ~= 0 then

            self:SetSpectatorMode(kSpectatorMode.FirstPerson)
            self.timeFromLastAction = 0

        end

        -- if bit.band(input.commands, Move.Reload) ~= 0 then
        --     self:SetIsThirdPerson(self:GetIsThirdPerson() and 0 or 0.3)
        -- end
    end

    -- Switch away from following mode ASAP while on a playing team.
    -- Prefer first person mode in this case.
    if self:GetIsOnPlayingTeam() and self:GetIsFollowing() then

        local followTarget = Shared.GetEntity(self:GetFollowTargetId())
        -- Disallow following a Player in this case. Allow following Eggs and IPs
        -- for example.
        if not followTarget or followTarget:isa("Player") then
            self:SetSpectatorMode(kSpectatorMode.FirstPerson)
        end

    end

end


function Spectator:OnProcessMove(input)


    if Client then
        if self.clientSpecMode ~= self.specMode then
            self:SetSpectatorMode(self.specMode)
            self.clientSpecMode = self.specMode
            -- Log("%s: Switching to mode %s", self, self.specMode)
        end
    end

    if self.specMode == kSpectatorMode.FreeLook then
        Player.OnProcessMove(self,input)
    else
        if self.modeInstance and self.modeInstance.OnProcessMove then
            self.modeInstance:OnProcessMove(self, input)
        end

        self:UpdateMove(input)
    end

    if Server then

        if not self:GetIsRespawning() then
            UpdateSpectatorMode(self, input)
        end

    elseif Client then

        self:UpdateCrossHairTarget()

        -- Toggle the insight GUI.
        if self:GetTeamNumber() == kSpectatorIndex then

            if bit.band(input.commands, Move.Weapon4) ~= 0 then

                self.showInsight = not self.showInsight
                ClientUI.GetScript("GUISpectator"):SetIsVisible(self.showInsight)

                if self.showInsight then

                    self.mapMode = kSpectatorMapMode.Small
                    self:ShowMap(true, false, true)

                else

                    self.mapMode = kSpectatorMapMode.Invisible
                    self:ShowMap(false, false, true)

                end

            end

        end

        -- This flag must be cleared inside OnProcessMove. See explaination in Commander:OverrideInput().
        self.setScrollPosition = false

    end

    self:OnUpdatePlayer(input.time)

    Player.UpdateMisc(self, input)

end