
local function UpdateScoreDisplay(self, deltaTime)

    PROFILE("GUINotifications:UpdateScoreDisplay")
    self.updateInterval = kUpdateIntervalFull
    
    if self.scoreDisplayFadeoutTime > 0 then
        self.scoreDisplayFadeoutTime = math.max(0, self.scoreDisplayFadeoutTime - deltaTime)
        local fadeRate = 1 - (self.scoreDisplayFadeoutTime / GUINotifications.kScoreDisplayFadeoutTimer)
        local fadeColor = self.scoreDisplay:GetColor()
        fadeColor.a = 1
        fadeColor.a = fadeColor.a - (fadeColor.a * fadeRate)
        self.scoreDisplay:SetColor(fadeColor)
        if self.scoreDisplayFadeoutTime == 0 then
            self.scoreDisplay:SetIsVisible(false)
        end
        
    end
    
    if self.scoreDisplayPopdownTime > 0 then
        self.scoreDisplayPopdownTime = math.max(0, self.scoreDisplayPopdownTime - deltaTime)
        local popRate = self.scoreDisplayPopdownTime / GUINotifications.kScoreDisplayPopTimer
        local fontSize = GUINotifications.kScoreDisplayMinFontHeight + ((GUINotifications.kScoreDisplayFontHeight - GUINotifications.kScoreDisplayMinFontHeight) * popRate)
        local scale = GUIScale(fontSize / GUINotifications.kScoreDisplayFontHeight)
        self.scoreDisplay:SetScale(Vector(scale, scale, scale))
        if self.scoreDisplayPopdownTime == 0 then
            self.scoreDisplayFadeoutTime = GUINotifications.kScoreDisplayFadeoutTimer
        end
        
    end
    
    if self.scoreDisplayPopupTime > 0 then
        self.scoreDisplayPopupTime = math.max(0, self.scoreDisplayPopupTime - deltaTime)
        local popRate = 1 - (self.scoreDisplayPopupTime / GUINotifications.kScoreDisplayPopTimer)
        local fontSize = GUINotifications.kScoreDisplayMinFontHeight + ((GUINotifications.kScoreDisplayFontHeight - GUINotifications.kScoreDisplayMinFontHeight) * popRate)
        local scale = GUIScale(fontSize / GUINotifications.kScoreDisplayFontHeight)
        self.scoreDisplay:SetScale(Vector(scale, scale, scale))
        if self.scoreDisplayPopupTime == 0 then
            self.scoreDisplayPopdownTime = GUINotifications.kScoreDisplayPopTimer
        end
        
    end
    
    local newScore, resAwarded, wasKill = ScoreDisplayUI_GetNewScore()
    if newScore > 0 then
    
        -- Restart the animation sequence.
        self.scoreDisplayPopupTime = GUINotifications.kScoreDisplayPopTimer
        self.scoreDisplayPopdownTime = 0
        self.scoreDisplayFadeoutTime = 0
        
        local resAwardedString = ""
        if resAwarded > 0 then
            resAwarded = math.round(resAwarded * 10) / 10
            resAwardedString = string.format(Locale.ResolveString(PlayerUI_IsOnMarineTeam() and "RESOURCED_ADDED_MARINE" or "RESOURCED_ADDED_ALIEN"), ToString(resAwarded))
        end
        
        self.scoreDisplay:SetText(string.format("+%s%s", tostring(newScore), resAwardedString))
        self.scoreDisplay:SetScale(GUIScale(Vector(0.5, 0.5, 0.5)))
        
        self.scoreDisplay:SetColor(wasKill and GUINotifications.kScoreDisplayKillTextColor or GUINotifications.kScoreDisplayTextColor)
        self.scoreDisplay:SetIsVisible(self.visible)
        
    end
    
end

function GUINotifications:Update(deltaTime)

    PROFILE("GUINotifications:Update")
    
    GUIAnimatedScript.Update(self, deltaTime)
    
    -- The commander has their own location text.
    if PlayerUI_IsACommander() or PlayerUI_IsOnMarineTeam() then
        self.locationText:SetIsVisible(false)
    else
        self.locationText:SetIsVisible(self.visible)
        self.locationText:SetText(PlayerUI_GetLocationName())
    end
    
    UpdateScoreDisplay(self, deltaTime)
    
end