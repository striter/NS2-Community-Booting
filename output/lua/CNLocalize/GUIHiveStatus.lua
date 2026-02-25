
--[[
Each status frame is associated to a given location, NOT a given status-slot
Frames can be moved/re-ordered to any slot at any time.
--]]
function GUIHiveStatus:UpdateStatusSlot( slotIdx, slotData )
    PROFILE("GUIHiveStatus:UpdateStatusSlot")

    assert( type(slotIdx) == "number" )
    assert( slotIdx > 0 and slotIdx <= GUIHiveStatus.kMaxStatusSlots )
    assert( type(slotData) == "table" )
    
    if self.statusSlots[slotIdx] ~= nil then
        
        local isEmpty = 
            slotData.eggCount == 0 
            and slotData.hiveFlag == 0 
            --TODO Add chambers
        
        if isEmpty then
        --Now and Empty-Slot, test and re-order next slot if able
            if slotIdx + 1 <= GUIHiveStatus.kMaxStatusSlots then
                if not self.statusSlots[slotIdx + 1]._isEmpty then
                    self:UpdateSlotOrdering( slotIdx )
                else
                    self:ClearStatusSlot( slotIdx )
                end
            end
            return
        end
        
        --cheaper to just force visible instead of checking visibility each update
        self.statusSlots[slotIdx].background:SetIsVisible( self.visible )
        self.statusSlots[slotIdx].frame:SetIsVisible( self.visible )
        self.statusSlots[slotIdx].locationText:SetText( Locale.ResolveLocation( Shared.GetString( slotData.locationId ) ) )
        self.statusSlots[slotIdx].locationText:SetIsVisible( self.visible )
        self.statusSlots[slotIdx].locationBackground:SetIsVisible( self.visible )
        
        self.statusSlots[slotIdx].eggsIcon:SetIsVisible( self.visible )
        self.statusSlots[slotIdx].eggsText:SetText( ToString(slotData.eggCount) )
        
        local eggIconColor = GUIHiveStatus.kEggsIconColor
        if slotData.eggInCombat and slotData.eggCount > 0 then
            eggIconColor = self:PulseIconRed( GUIHiveStatus.kEggsIconColor )
        end
        self.statusSlots[slotIdx].eggsIcon:SetColor( eggIconColor )
        
        if slotData.eggCount < self.kLowEggCountThreshold then
            self.statusSlots[slotIdx].eggsIcon:SetTexturePixelCoordinates( 260, 0, 325, 60 ) --TODO Move to local global
        else
            self.statusSlots[slotIdx].eggsIcon:SetTexturePixelCoordinates( 195, 0, 260, 60 ) --TODO Move to local global
        end
        
        self:UpdateHiveIconDisplay( 
            slotIdx, slotData.hiveFlag, slotData.hiveBuiltFraction, 
            slotData.hiveHealthScalar, slotData.hiveMaxHealth,
            slotData.hiveInCombat
        )
        
        self:UpdateCommanderIcon( slotIdx )
        
        local prevSlotIdx = slotIdx - 1
        if prevSlotIdx > 0 then
            if self.statusSlots[prevSlotIdx]._isEmpty then
                self:UpdateSlotOrdering( prevSlotIdx ) --FIXME Calling here means duplicate SetIsVisible() calls
            end
        end
        
    end
    
end
