BotAim.reactionTime = 0.25
BotAim.kAccuracies = {
    --[kBotAccWeaponGroup.Bullets] = { 14.5, 16.5, 21, 25, 28.5, 34, 38.5 },
    [kBotAccWeaponGroup.Bullets] = { 20, 21, 22, 23,  25, 28.5, 34, 38.5 },

    -- These guys should be stonker
    --[kBotAccWeaponGroup.ExoMinigun] = { 23, 25, 28, 30, 35, 39, 43 },
    --[kBotAccWeaponGroup.ExoRailgun] = { 25, 28, 30, 32, 35, 39, 43 },
    [kBotAccWeaponGroup.ExoMinigun] = { 30, 32, 33, 35, 35, 35, 35 },
    [kBotAccWeaponGroup.ExoRailgun] = { 43, 43, 43, 43, 43, 43, 43 },

    -- Similar to "bullets", but caps off in higher tiers
    [kBotAccWeaponGroup.LerkSpikes] = { 14.5, 16.5, 21, 25, 28.5, 28.5, 28.5 },

    [kBotAccWeaponGroup.Spit] = { 13.5, 15, 18.5, 21.1, 25.1, 31.1, 41.1 },

    --TODO Add Fade and Onos weapons

    [kBotAccWeaponGroup.Melee] = { 25, 28, 32, 38, 42, 48, 55 },

    [kBotAccWeaponGroup.Swipe] = { 28, 32, 38, 42, 48, 55, 62 },

    [kBotAccWeaponGroup.BiteLeap] = { 11, 13, 15, 18.5, 25, 32, 45 },

    [kBotAccWeaponGroup.LerkBite] = { 15, 20, 25, 30, 35, 40, 60 },

    -- [kBotAccWeaponGroup.Parasite]

    --TODO Add Exo weapons?
}

BotAim.kBotTurnSpeeds["DevouredPlayer"] = 1.0       --?
BotAim.kBotTurnSpeeds["Prowler"] = 1.0
