

local baseInitialize = GUIMenuCallingCard.Initialize
function GUIMenuCallingCard:Initialize(params, errorDepth)
    baseInitialize(self,params,errorDepth)
    self:HookEvent(self.button, "OnMouseEnter", self.OnMouseEnter)
    self:HookEvent(self.button, "OnMouseHover", self.OnMouseHover)
end

function GUIMenuCallingCard:OnMouseEnter()
    self.frameStartTime = Shared.GetTime()
end

function GUIMenuCallingCard:OnMouseHover()
    local isFrame,pixels = GetCallingCardTextureFrameDetails(self:GetCardID(),Shared.GetTime() - self.frameStartTime)
    if not isFrame then return end
    self.button:SetTexturePixelCoordinates(pixels)
end

local kTooltipExtra = Locale.ResolveString("CALLINGCARD_TOOLTIP_EXTRA")
local kTooltipShouldPatchExtra = Locale.ResolveString("CALLINGCARD_TOOLTIP_EXTRASHOULDERPATCH")
function GUIMenuCallingCard:OnCardIDChanged(newCardID)

    local isUnlocked = GetIsCallingCardUnlocked(newCardID)

    local cardData = GetCallingCardTextureDetails(newCardID)
    if cardData and cardData.texture then
        self.button:SetTexture(cardData.texture)
        self.button:SetTexturePixelCoordinates(cardData.texCoords)
        self.button:SetColor(1,1,1)

        local tooltipId = GetCallingCardUnlockedTooltipIdentifier(newCardID)
        assert(tooltipId)

        local extraStr = ""
        if not isUnlocked then

            local lockedTooltipOverride = GetCallingCardLockedTooltipIdentifierOverride(newCardID)
            if lockedTooltipOverride then
                extraStr = string.format(" (%s)", Locale.ResolveString(lockedTooltipOverride))
            else
                extraStr = string.format(" (%s)", kTooltipExtra)
                if GetIsCallingCardShoulderPatch(newCardID) then
                    extraStr = string.format(" (%s)", kTooltipShouldPatchExtra)
                end
            end

        end

        self.button:SetTooltip(string.format("%s%s", Locale.ResolveString(tooltipId), extraStr))

    end

    self.lockedOverlay:SetVisible(not isUnlocked)

end