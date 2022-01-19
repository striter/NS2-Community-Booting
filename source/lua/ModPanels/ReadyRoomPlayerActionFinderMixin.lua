-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\ReadyRoomPlayerActionFinderMixin.lua
--
--    Created by:   Adam
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kIconUpdateRate = 0.1
local kDetectionRange = 0.65

ReadyRoomPlayerActionFinderMixin = CreateMixin( ReadyRoomPlayerActionFinderMixin )
ReadyRoomPlayerActionFinderMixin.type = "ReadyRoomPlayerActionFinderMixin"

ReadyRoomPlayerActionFinderMixin.expectedCallbacks =
{
    GetOrigin = "Returns the position of the Entity in world space"
}

function ReadyRoomPlayerActionFinderMixin:__initmixin()

    if Client and Client.GetLocalPlayer() == self then
    
        self.readyRoomActionIconGUI = GetGUIManager():CreateGUIScript("GUIActionIcon")
        self.readyRoomActionIconGUI:SetColor(kMarineFontColor)
        self.lastReadyRoomActionFindTime = 0
        
    end
    
end

function ReadyRoomPlayerActionFinderMixin:OnDestroy()

    if Client and self.readyRoomActionIconGUI then
    
        GetGUIManager():DestroyGUIScript(self.readyRoomActionIconGUI)
        self.readyRoomActionIconGUI = nil
        
    end
    
end

if Client then

    function ReadyRoomPlayerActionFinderMixin:OnProcessMove(input)
    
        local now = Shared.GetTime()
        local enoughTimePassed = (now - self.lastReadyRoomActionFindTime) >= kIconUpdateRate
        if enoughTimePassed then
        
            self.lastReadyRoomActionFindTime = now
            
            local success = false
            
            local position = self:GetOrigin() + self:GetViewAngles():GetCoords().zAxis * kDetectionRange + Vector(0,0.5,0)
            
            local nearbyModPanels = GetEntitiesWithinRange("ModPanel", position, kDetectionRange)
            for i, ent in ipairs(nearbyModPanels) do
                if ent and ent.InternalGetCanBeUsed and ent:InternalGetCanBeUsed() then
                    local hintText = "阅读信息"
                    
                    self.readyRoomActionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), nil, hintText, nil)
                    success = true
                    
                    if bit.band(input.commands, Move.Use) ~= 0 and not self.primaryAttackLastFrame and not self.secondaryAttackLastFrame then
                        if input.time > 0 and ent.OnUse then 
                            self.timeOfLastUse = Shared.GetTime()
                            ent:OnUse()
                        end
                    end
                    break;
                end
            end
            
            if not success then
                self.readyRoomActionIconGUI:Hide()
            end
            
        end
        
    end
    
end