
function GMTDRewardsScreen:FullUpdate()

    local timePlayed = Client.GetUserStat_Int(kThunderdomeStatFields_TimePlayed) or 0
    local timePlayedComm = Client.GetUserStat_Int(kThunderdomeStatFields_TimePlayedCommander) or 0
    local victories = Client.GetUserStat_Int(kThunderdomeStatFields_Victories) or 0
    local victoriesComm = Client.GetUserStat_Int(kThunderdomeStatFields_CommanderVictories) or 0

    if Shine then
        local crEnabled, cr = Shine:IsExtensionEnabled( "communityrank" )
        if crEnabled then
            local data = cr:GetCommunityData()
            timePlayed = data.TimePlayed * 60       --Previous in seconds wtf
            timePlayedComm = data.TimePlayedCommander * 60 
            victories = data.RoundWin
            victoriesComm = data.RoundWinCommander
        end
    end
    
    self:SetCurrentFieldHours(timePlayed)
    self:SetCurrentCommanderHours(timePlayedComm)
    self:SetCurrentFieldVictories(victories)
    self:SetCurrentCommanderVictories(victoriesComm)

    self:UpdateMarkerPositions()
    self:UpdateRewardsCompletion()

end

function GMTDRewardsScreen:OnRequiredMissionCompletedChanged()
    local shouldLockScreen = false -- not self:GetRequiredMission():GetCompleted()
    self:SetIsLocked(shouldLockScreen and not DEBUG_ALWAYSSHOWREWARDSSCREEN)
end