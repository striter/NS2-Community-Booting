function GetPlayerSkillTier(skill, isRookie, adagradSum, isBot)
    if isBot then return -1, "SKILLTIER_BOT" end
    if not skill or skill == -1 then return -2, "SKILLTIER_UNKNOWN" end

    if skill <= 300 then
        if isRookie then
            return 0, "SKILLTIER_ROOKIE", 0
        else
            return 1, "SKILLTIER_RECRUIT", skill
        end
    end
    if skill <= 750 then return 2, "SKILLTIER_FRONTIERSMAN", skill end
    if skill <= 1400 then return 3, "SKILLTIER_SQUADLEADER", skill end
    if skill <= 2100 then return 4, "SKILLTIER_VETERAN", skill end
    if skill <= 2900 then return 5, "SKILLTIER_COMMANDANT", skill end
    if skill <= 4100 then return 6, "SKILLTIER_SPECIALOPS", skill end
    return 7, "SKILLTIER_SANJISURVIVOR", skill
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