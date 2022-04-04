function GetPlayerSkillTier(skill, isRookie, adagradSum, isBot)
    if isBot then return -1, "SKILLTIER_BOT" end
    if skill <= 100 then return 0, "SKILLTIER_ROOKIE", skill end
    if skill <= 400 then return 1, "SKILLTIER_RECRUIT", skill end
    if skill <= 850 then return 2, "SKILLTIER_FRONTIERSMAN", skill end
    if skill <= 1400 then return 3, "SKILLTIER_SQUADLEADER", skill end
    if skill <= 2100 then return 4, "SKILLTIER_VETERAN", skill end
    if skill <= 2900 then return 5, "SKILLTIER_COMMANDANT", skill end
    if skill <= 4100 then return 6, "SKILLTIER_SPECIALOPS", skill end
    return 7, "SKILLTIER_SANJISURVIVOR", skill
end