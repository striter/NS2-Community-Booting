

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

