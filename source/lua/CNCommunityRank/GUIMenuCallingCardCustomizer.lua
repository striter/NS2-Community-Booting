local baseOnCallingCardSelect = GUIMenuCallingCardCustomizer.OnCallingCardSelected
function GUIMenuCallingCardCustomizer:OnCallingCardSelected(callingCardObj)
    baseOnCallingCardSelect(self,callingCardObj)
    if not CNPersistent then return end
    local cardId = callingCardObj:GetCardID()
    CNPersistent.callingCardID = cardId
    CNPersistentSave()
    Shared.Message("Save" .. tostring(cardId))
end
