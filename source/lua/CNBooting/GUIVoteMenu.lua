function GUIVoteMenu:SendKeyEvent(key, down)

    --if down and self.votedYes == nil and voteId ~= self.lastVotedId and voteId > 0 then
    if down and GetCurrentVoteId() > 0 then

        if self.timeLastVoted and Shared.GetTime() - self.timeLastVoted < 0.5 then
            return false
        end
        
        if GetIsBinding(key, "VoteYes") then
        
            self.votedYes = true
            self.timeLastVoted = Shared.GetTime()
            SendVoteChoice(true)
            
            return true
            
        elseif GetIsBinding(key, "VoteNo") then
        
            self.votedYes = false
            self.timeLastVoted = Shared.GetTime()
            SendVoteChoice(false)
            
            return true
            
        end
        
    end
    
    return false
    
end

local function UpdateSizeOfUI(self, screenWidth, screenHeight)

    local titleFontName = kFonts.small
    self.titleText:SetFontName(titleFontName)
    self.titleText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.titleText)
    self.timeText:SetFontName(titleFontName)
    self.timeText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.timeText)

    local minWidth = self.titleText:GetTextWidth(self.titleText:GetText()) * self.titleText:GetScale().x + self.timeText:GetTextWidth(" ##") * self.timeText:GetScale().x + GUIScale(20)
    local size = Vector(math.max(screenWidth * 0.15, minWidth), screenHeight * 0.1, 0)
    self.background:SetSize(size)
    self.background:SetPosition(Vector(GUIScale(2), -size.y, 0))

    local titleSize = Vector(size.x - GUIScale(4), size.y * 0.36 - GUIScale(4), 0)
    self.titleBackground:SetSize(titleSize)
    self.titleBackground:SetPosition(GUIScale(Vector(2, 2, 0)))

    local choiceSize = Vector(size.x - GUIScale(4), size.y * 0.32 - GUIScale(2), 0)
    self.yesBackground:SetSize(choiceSize)
    local yesPos = Vector(GUIScale(2), titleSize.y + GUIScale(4), 0)
    self.yesBackground:SetPosition(yesPos)
    self.yesText:SetFontName(titleFontName)
    self.yesText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.yesText)
    self.yesCount:SetFontName(titleFontName)
    self.yesCount:SetScale(GetScaledVector())
    GUIMakeFontScale(self.yesCount)

    self.noBackground:SetSize(choiceSize)
    self.noBackground:SetPosition(Vector(GUIScale(2), yesPos.y + choiceSize.y + GUIScale(2), 0))
    self.noText:SetFontName(titleFontName)
    self.noText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.noText)
    self.noCount:SetFontName(titleFontName)
    self.noCount:SetScale(GetScaledVector())
    GUIMakeFontScale(self.noCount)

    self.titleText:SetPosition(GUIScale(Vector(4, 0, 0)))
    self.timeText:SetPosition(GUIScale(Vector(-8, 0, 0)))
    self.yesText:SetPosition(GUIScale(Vector(4, 0, 0)))
    self.yesCount:SetPosition(GUIScale(Vector(-8, 0, 0)))
    self.noText:SetPosition(GUIScale(Vector(4, 0, 0)))
    self.noCount:SetPosition(GUIScale(Vector(-8, 0, 0)))
end

local baseUpdate = GUIVoteMenu.Update

function GUIVoteMenu:Update(deltaTime)

    PROFILE("GUIVoteMenu:Update")
    baseUpdate(self,deltaTime)
    
    if self.visible and GetCurrentVoteQuery() ~= nil then
        local onlyAccepted = GetOnlyAcceptedResults()
        if onlyAccepted then
            if self.yesText then
                self.yesText:SetText(StringReformat(Locale.ResolveString("VOTE_AFFECT_ACCEPTED_YES"), { key = GetPrettyInputName("VoteYes") }))
            end
    
            if self.noText then
                self.noText:SetText(StringReformat(Locale.ResolveString("VOTE_AFFECT_ACCEPTED_NO"), { key = GetPrettyInputName("VoteNo") }))
            end
        end
        self.noCount:SetIsVisible(not onlyAccepted)
    end

end