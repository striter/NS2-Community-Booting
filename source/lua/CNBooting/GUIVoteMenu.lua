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