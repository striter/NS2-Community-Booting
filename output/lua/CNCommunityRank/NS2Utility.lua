function GetPlayerSkillTier(skill, isRookie, adagradSum, isBot)
    if isBot then return -1, "SKILLTIER_BOT" end
    if not skill or skill == -1 then return -2, "SKILLTIER_UNKNOWN" end

    if isRookie then
        return 0, "SKILLTIER_ROOKIE"
    end
    
    if skill <= 300 then return 1, "SKILLTIER_RECRUIT" end
    if skill <= 750 then return 2, "SKILLTIER_FRONTIERSMAN" end
    if skill <= 1400 then return 3, "SKILLTIER_SQUADLEADER" end
    if skill <= 2100 then return 4, "SKILLTIER_VETERAN" end
    if skill <= 2900 then return 5, "SKILLTIER_COMMANDANT" end
    if skill <= 4100 then return 6, "SKILLTIER_SPECIALOPS" end
    return 7, "SKILLTIER_SANJISURVIVOR"
end

function FormatDateTimeString(dateTime)
    local tmpDate = os.date("*t", dateTime)
    return string.format("%d年%02d月%02d日 | %d:%02d", tmpDate.year,tmpDate.month,tmpDate.day, tmpDate.hour, tmpDate.min)
end

function SendPlayerCallingCardUpdate()

    if Client.GetIsConnected() then

        local kCardID = kDefaultPlayerCallingCard
        if CNPersistent then
            kCardID = CNPersistent.callingCardID or kDefaultPlayerCallingCard
            if not GetIsCallingCardUnlocked(kCardID) then
                kCardID = kDefaultPlayerCallingCard
                CNPersistent.callingCardID = kCardID
            end
            GetMainMenu().navBar.playerScreen.callingCardCustomizer:SetCardId(kCardID)
            GetMainMenu().navBar.playerScreen.callingCardCustomizer:UpdateAppearance()
        end
        
        Client.SendNetworkMessage("SetPlayerCallingCard", {
            callingCard = kCardID
        })

    end

end