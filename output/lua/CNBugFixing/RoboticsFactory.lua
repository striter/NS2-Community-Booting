--Merges with rollout fix
function RoboticsFactory:ManufactureEntity()

    local mapName = LookupTechData(self.researchId, kTechDataMapName)
    local owner = Shared.GetEntity(self.researchingPlayerId)

    local builtEntity = CreateEntity(mapName, self:GetOrigin(), self:GetTeamNumber())

    if builtEntity ~= nil then

        local newPosition = self:GetPositionForEntity(builtEntity)

        if owner and owner:isa("Commander") then
            builtEntity:SetOwner(owner)
        end
        
        builtEntity:SetCoords(newPosition)
        builtEntity:ProcessRallyOrder(self)

    end

end

function RoboticsFactory:CancelRollout()

    self:ClearResearch()
    self.open = false

end

function RoboticsFactory:OnTag(tagName)

    PROFILE("RoboticsFactory:OnTag")

    if self.open and self.builtEntity and self.researchId ~= Entity.invalidId and tagName == "open_end" then
        if self.builtEntity:GetIsDestroyed() then
            self:CancelRollout()
        else
            self.builtEntity:Rollout(self, RoboticsFactory.kRolloutLength)
        end

        self.builtEntity = nil

    end

    if tagName == "open_start" then
        self:TriggerEffects("robofactory_door_open")
    elseif tagName == "close_start" then
        self:TriggerEffects("robofactory_door_close")
    end

end

if Server then
    
    function RoboticsFactory:ManufactureEntity()

        local mapName = LookupTechData(self.researchId, kTechDataMapName)
        local owner = Shared.GetEntity(self.researchingPlayerId)

        local builtEntity = CreateEntity(mapName, self:GetOrigin(), self:GetTeamNumber())

        if builtEntity ~= nil then

            if owner and owner:isa("Commander") then
                builtEntity:SetOwner(owner)
            end
            builtEntity:SetAngles(self:GetAngles())
            builtEntity:SetIgnoreOrders(true)

        end

        return builtEntity

    end

    function RoboticsFactory:OnEntityChange(oldEntityId, newEntityId)

        if self.builtEntity and self.builtEntity:GetId() == oldEntityId then
            local ent = oldEntityId and Shared.GetEntity(oldEntityId)
            if not ent or not ent:GetIsAlive()then
                self.builtEntity = nil
                self:CancelRollout()
            end
        end

    end
end