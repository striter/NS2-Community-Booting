function GUIMenuCallingCardCustomizer:OnCallingCardSelected(callingCardObj)
    local cardId = callingCardObj:GetCardID()
    self:SetCardId(cardId)
    self.contents:Hide()
    
    if not Client.GetIsConnected() then return end
    if CNPersistent then
        CNPersistent.callingCardID = cardId
        CNPersistentSave() 
    end

    SendPlayerCallingCardUpdate()
end


local baseInitialize = GUIMenuCallingCardCustomizer.Initialize
function GUIMenuCallingCardCustomizer:Initialize(params, errorDepth)
    baseInitialize(self,params,errorDepth)
    self:HookEvent(self.button, "OnMouseEnter", self.OnMouseEnter)
    self:HookEvent(self.button, "OnMouseHover", self.OnMouseHover)
end

function GUIMenuCallingCardCustomizer:OnMouseEnter()
    self.frameStartTime = Shared.GetTime()
end

function GUIMenuCallingCardCustomizer:OnMouseHover()
    local isFrame,pixels = GetCallingCardTextureFrameDetails(self:GetCardId(),Shared.GetTime() - self.frameStartTime)
    if not isFrame then return end
    self.button:SetTexturePixelCoordinates(pixels)
end

