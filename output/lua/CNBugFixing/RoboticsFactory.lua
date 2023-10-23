
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
end

function RoboticsFactory:OnTag(tagName)

    PROFILE("RoboticsFactory:OnTag")

    if self.open and self.builtEntity and self.researchId ~= Entity.invalidId and tagName == "end" then

        if self.builtEntity:GetIsDestroyed() then return end        --Safe Check

        self.builtEntity:Rollout(self, RoboticsFactory.kRolloutLength)
        self.builtEntity = nil
    end


    if tagName == "open_start" then
        self:TriggerEffects("robofactory_door_open")
    elseif tagName == "close_start" then
        self:TriggerEffects("robofactory_door_close")
    end

end
