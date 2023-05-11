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


function GUIMenuCallingCardCustomizer:Update()
    Shared.Message("?")
end 