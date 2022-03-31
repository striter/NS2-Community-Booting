function Player:GetCanDieOverride()     --Kill Readyroom player
    local teamNumber = self:GetTeamNumber()
    return (teamNumber == kTeam1Index or teamNumber == kTeam2Index or teamNumber == kTeamReadyRoom)
end