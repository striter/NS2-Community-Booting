local function Vote(self,prefer)
    self.votedYes = prefer
    self.timeLastVoted = Shared.GetTime()
    SendVoteChoice(prefer)
end

function GUIVoteMenu:SendKeyEvent(key, down)

    --if down and self.votedYes == nil and voteId ~= self.lastVotedId and voteId > 0 then

    local currentVoteId = GetCurrentVoteId()
    
    if currentVoteId <= 0 then return false end
    
    if self.votedYes == nil and GetOnlyAcceptedResults() then
        local team = Client.GetLocalPlayer():GetTeamNumber()
        if team ~= kTeam1Index and team ~=kTeam2Index then
            Vote(self,true)
            return false
        end
    end
    
    if down then
        if self.timeLastVoted and Shared.GetTime() - self.timeLastVoted < 0.5 then
            return false
        end
        
        if GetIsBinding(key, "VoteYes") then
            Vote(self,true)
            return true
        elseif GetIsBinding(key, "VoteNo") then
            Vote(self,false)
            return true
        end
    end
    
    return false
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