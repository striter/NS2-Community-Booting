--=============================================================================
--
-- lua/Scoreboard.lua
-- 
-- Created by Henry Kropf and Charlie Cleveland
-- Copyright 2011, Unknown Worlds Entertainment
--
--=============================================================================

--[[
 * Main purpose it to maintain a cache for player info, allowing information for a player
 * to be retrived by a players clientIndex or playerName.
 *
 * Originally intended to be used by the scoreboard, therefore its name. 
 * Should probably be renamed PlayerRecords or PlayerDatabase
 *
 * Keeps track of when it was last updated and avoids updating more often than kMaxPlayerDataAge
]]
Script.Load("lua/Insight.lua")

-- primary lookup table with clientIndex (clientId) as key
local playerData = unique_map()

-- index with player name as key
local playerDataByName = { }

-- sorted list by score
local sortedPlayerData = { }

local lastPlayerDataUpdateTime = 0
local kMaxPlayerDataAge = 0.5

local kLastMarineCommanderInfo
local kLastAlienCommanderInfo

-- For Death Messages
function Scoreboard_GetLastMarineCommanderInfo()
    return kLastMarineCommanderInfo
end

function Scoreboard_GetLastAlienCommanderInfo()
    return kLastAlienCommanderInfo
end

local kStatusTranslationStringMap = {
    [kPlayerStatus.Dead] = "STATUS_DEAD",
    [kPlayerStatus.Evolving] = "STATUS_EVOLVING",
    [kPlayerStatus.Embryo] = "STATUS_EMBRYO",
    [kPlayerStatus.Commander] = "STATUS_COMMANDER",
    [kPlayerStatus.Exo] = "STATUS_EXO",
    [kPlayerStatus.GrenadeLauncher] = "STATUS_GRENADE_LAUNCHER",
    [kPlayerStatus.Rifle] = "STATUS_RIFLE",
    [kPlayerStatus.HeavyMachineGun] = "STATUS_HMG",
    [kPlayerStatus.Shotgun] = "STATUS_SHOTGUN",
    [kPlayerStatus.Flamethrower] = "STATUS_FLAMETHROWER",
    [kPlayerStatus.Void] = "STATUS_VOID",
    [kPlayerStatus.Spectator] = "STATUS_SPECTATOR",
    [kPlayerStatus.Skulk] = "STATUS_SKULK",
    [kPlayerStatus.Gorge] = "STATUS_GORGE",
    [kPlayerStatus.Lerk] = "STATUS_LERK",
    [kPlayerStatus.Fade] = "STATUS_FADE",
    [kPlayerStatus.Onos] = "STATUS_ONOS",
    [kPlayerStatus.SkulkEgg] = "SKULK_EGG",
    [kPlayerStatus.GorgeEgg] = "GORGE_EGG",
    [kPlayerStatus.LerkEgg] = "LERK_EGG",
    [kPlayerStatus.FadeEgg] = "FADE_EGG",
    [kPlayerStatus.OnosEgg] = "ONOS_EGG",
}

-- reloads the player data. Should be no need to call this, as player data is reloaded on demand
function Scoreboard_ReloadPlayerData()

    PROFILE("Scoreboard:ReloadPlayerData")
    lastPlayerDataUpdateTime = Shared.GetTime()

    for _, pie in ientitylist(Shared.GetEntitiesWithClassname("PlayerInfoEntity")) do

        local statusTxt = "-"
        if pie.status ~= kPlayerStatus.Hidden then
            local statusTranslationString = kStatusTranslationStringMap[pie.status]
            statusTxt = statusTranslationString and Locale.ResolveString(statusTranslationString) or "Unknown status:" .. pie.status
        end

        local clientId = pie.clientId
        local playerRecord = playerData:Get(clientId)
        if playerRecord == nil then
            playerRecord = {}
            playerData:Insert(clientId, playerRecord)

            playerRecord.ClientIndex = pie.clientId
            playerRecord.IsSteamFriend = Client.GetIsSteamFriend(pie.steamId)
            playerRecord.Ping = 0
        end

        playerRecord.LastUpdateTime = lastPlayerDataUpdateTime

        playerRecord.EntityId = pie.playerId
        playerRecord.Name = pie.playerName
        playerRecord.EntityTeamNumber = pie.teamNumber
        playerRecord.Score = pie.score
        playerRecord.Kills = pie.kills
        playerRecord.Deaths = pie.deaths
        playerRecord.Resources = math.floor(pie.resources)
        playerRecord.IsCommander = pie.isCommander
        playerRecord.IsRookie = pie.isRookie
        playerRecord.Status = statusTxt
        playerRecord.StatusId = pie.status
        playerRecord.IsSpectator = pie.isSpectator
        playerRecord.Assists = pie.assists
        playerRecord.SteamId = pie.steamId
        playerRecord.AdagradSum = pie.adagradSum
        playerRecord.Tech = pie.currentTech
        playerRecord.CallingCard = pie.callingCard
    ------------- Why
        playerRecord.Skill = pie.playerSkill
        playerRecord.SkillOffset = pie.playerSkillOffset
        playerRecord.CommSkill = pie.commanderSkill
        playerRecord.CommSkillOffset = pie.commanderSkillOffset
        
        playerRecord.FakeBot = pie.fakeBot
        playerRecord.HideRank = pie.hideRank
        playerRecord.Emblem = pie.emblem
        playerRecord.QueueIndex = pie.queueIndex
        playerRecord.ReservedQueueIndex = pie.reservedQueueIndex
        playerRecord.prewarmTier = pie.prewarmTier
        playerRecord.prewarmTime = pie.prewarmTime
        playerRecord.prewarmScore = pie.prewarmScore
        playerRecord.Group = pie.hideRank and "RANK_DEFAULT" or pie.group    --Hide this shit
        playerRecord.lastSeenName = pie.hideRank and "" or pie.lastSeenName
        playerRecord.ns2TimePlayed = pie.ns2TimePlayed
        playerRecord.reputation = pie.reputation
    ------------

        if playerRecord.IsCommander then

            local playerEnt = Shared.GetEntity(playerRecord.EntityId)
            if playerEnt then

                local commanderTeam = playerEnt:GetTeamType()
                if commanderTeam == kMarineTeamType then
                    kLastMarineCommanderInfo =
                    {
                        CallingCard = playerRecord.CallingCard,
                        Name = playerRecord.Name,

                        -- Skill Badge Info
                        SteamId32 = playerRecord.SteamId, -- Bot? == 0
                        Skill = playerRecord.Skill,
                        AdagradSum = playerRecord.AdagradSum,
                        Rookie = playerRecord.IsRookie
                    }
                elseif commanderTeam == kAlienTeamType then
                    kLastAlienCommanderInfo =
                    {
                        CallingCard = playerRecord.CallingCard,
                        Name = playerRecord.Name,

                        -- Skill Badge Info
                        SteamId32 = playerRecord.SteamId, -- Bot? == 0
                        Skill = playerRecord.Skill,
                        AdagradSum = playerRecord.AdagradSum,
                        Rookie = playerRecord.IsRookie
                    }
                end

            end


        end

    end

    sortedPlayerData = { }
    playerDataByName = { }

    -- clean out old player records
    for clientIndex, playerRecord in playerData:IterateBackwards() do
        if lastPlayerDataUpdateTime - playerRecord.LastUpdateTime > kMaxPlayerDataAge then
            playerData:Remove(clientIndex)
        else
            table.insert(sortedPlayerData, playerRecord)
            playerDataByName[playerRecord.Name] = playerRecord
        end
    end

    Scoreboard_Sort()

end

-- call this to ensure that the data is reasonably up-to-date
local function CheckForReload()

    if Shared.GetTime() - lastPlayerDataUpdateTime > kMaxPlayerDataAge then
        Scoreboard_ReloadPlayerData()
        return true
    end

    return false
end

-- Returns the playerRecord for the given players clientIndex, reloading player data if required
function Scoreboard_GetPlayerRecord(clientIndex)
    
    PROFILE("Scoreboard_GetPlayerRecord")
    
    if not CheckForReload() and playerData:Get(clientIndex) == nil then
        -- updates playerData
        Scoreboard_ReloadPlayerData()
    end

    return playerData:Get(clientIndex)

end

-- Returns the playerRecord for the given players name, reloading player data if required
function Scoreboard_GetPlayerRecordByName(playerName)

    if not CheckForReload() and playerDataByName[playerName] == nil then
        Scoreboard_ReloadPlayerData()
    end

    return playerDataByName[playerName]

end

function Insight_SetPlayerHealth(clientIndex, health, maxHealth, armor, maxArmor)

    local playerRecord = Scoreboard_GetPlayerRecord(clientIndex)
    if playerRecord then
        playerRecord.Health = health
        playerRecord.MaxHealth = maxHealth
        playerRecord.Armor = armor
        playerRecord.MaxArmor = maxArmor
    end

end

function Scoreboard_Clear()

    playerData:Clear()
    Insight_Clear()

end

-- Score > Kills > Deaths > Resources
local function sortByScore(player1, player2)

    if player1.EntityTeamNumber == player2.EntityTeamNumber then

        if player1.Score == player2.Score then

            if player1.Kills == player2.Kills then

                if player1.Deaths == player2.Deaths then

                    if player1.Resources == player2.Resources then

                        -- Somewhat arbitrary but keeps more coherence and adds players to bottom in case of ties
                        return player1.ClientIndex > player2.ClientIndex

                    else
                        return player1.Resources > player2.Resources
                    end

                else
                    return player1.Deaths < player2.Deaths
                end

            else
                return player1.Kills > player2.Kills
            end

        else
            return player1.Score > player2.Score
        end

    else
        -- Spectators should be at the top of the RR "team"
        -- Spectators are team 3 and RR players are team 0
        return player1.EntityTeamNumber > player2.EntityTeamNumber
    end
end

function Scoreboard_Sort()
    table.sort(sortedPlayerData, sortByScore)
end

function Scoreboard_SetPing(clientIndex, ping)
    -- setting ping does not cause a reload for missing player data
    local playerRecord = playerData:Get(clientIndex)
    if playerRecord then
        playerRecord.Ping = ping
    end

end

-- Set local data for player so scoreboard updates instantly (used only in test)
function Scoreboard_SetLocalPlayerData(_, index, data)
    playerData:Insert(index, data)
end


function Scoreboard_GetPlayerName(clientIndex)

    local record = Scoreboard_GetPlayerRecord(clientIndex)
    return record and record.Name or "服务器"

end

function Scoreboard_GetPlayerList()

    CheckForReload()

    local playerList = { }
    for p = 1, #sortedPlayerData do

        local playerRecord = sortedPlayerData[p]
        table.insert(playerList, { name = playerRecord.Name, client_index = playerRecord.ClientIndex })

    end

    return playerList

end

function Scoreboard_GetPlayerData(clientIndex, dataType)
    
    PROFILE("Scoreboard_GetPlayerData")
    
    -- often used to avoid a null-check
    local playerRecord = Scoreboard_GetPlayerRecord(clientIndex)
    return playerRecord and playerRecord[dataType]

end

--[[
 * Get table of scoreboard player records for all players with team numbers in specified table.
]]
function GetScoreData(teamNumberArray)

    local scoreData = {}
    local players = {}

    local localTeamNumber = Client.GetLocalClientTeamNumber()

    -- convert array into set for faster lookups inside loop
    local teamNumberSet = unique_set()
    teamNumberSet:InsertAll(teamNumberArray)

    -- first insert commanders so they are on top of the scoreData
    for _, playerRecord in ipairs(sortedPlayerData) do
        local playerTeamNumber = playerRecord.EntityTeamNumber
        if teamNumberSet:Contains(playerTeamNumber) then

            local isVisibleTeam = localTeamNumber == kSpectatorIndex or playerTeamNumber == localTeamNumber
            local isCommander = playerRecord.IsCommander and isVisibleTeam

            if not isCommander then
                table.insert(players, playerRecord)
            else
                table.insert(scoreData, playerRecord)
            end

        end
    end

    -- then insert all players
    for _, playerRecord in ipairs(players) do
        table.insert(scoreData, playerRecord)
    end

    return scoreData
end

--[[
 * Get score data for the blue team
]]
function ScoreboardUI_GetBlueScores()
    return GetScoreData({ kTeam1Index })
end

--[[
 * Get score data for the red team
]]
function ScoreboardUI_GetRedScores()
    return GetScoreData({ kTeam2Index })
end

--[[
 * Get score data for everyone not playing.
]]
function ScoreboardUI_GetSpectatorScores()
    return GetScoreData({ kTeamReadyRoom, kSpectatorIndex })
end

function ScoreboardUI_GetAllScores()
    return GetScoreData({ kTeam1Index, kTeam2Index, kTeamReadyRoom, kSpectatorIndex })
end

function ScoreboardUI_GetTeamResources(teamNumber)

    local teamInfo = GetEntitiesForTeam("TeamInfo", teamNumber)
    if #teamInfo > 0 then
        return teamInfo[1]:GetTeamResources()
    end

    return 0

end

--[[
 * Get the name of the blue team
]]
function ScoreboardUI_GetBlueTeamName()
    return kTeam1Name
end

--[[
 * Get the name of the red team
]]
function ScoreboardUI_GetRedTeamName()
    return kTeam2Name
end

--[[
 * Get the name of the spectator team
]]
function ScoreboardUI_GetSpectatorTeamName()
    return kSpectatorTeamName
end

--[[
 * Return true if playerName is a local player.
]]
kActualClientId = nil
function ScoreboardUI_IsPlayerLocal(playerName)

    local player = Client.GetLocalPlayer()

    -- make the scoreboard use the player's actual id to highlight
    local clientId = player:GetClientIndex()
    if Client.GetIsControllingPlayer() then
        kActualClientId = clientId
    else
        clientId = kActualClientId or clientId
    end

    -- Get entry with this name and check entity id
    if player then

        local playerRecord = Scoreboard_GetPlayerRecord(clientId)
        return playerRecord and playerName == playerRecord.Name

    end

    return false

end

function ScoreboardUI_IsPlayerCommander(playerName)

    local playerRecord = Scoreboard_GetPlayerRecordByName(playerName)
    return playerRecord and playerRecord.IsCommander

end

function ScoreboardUI_IsPlayerRookie(playerName)

    local playerRecord = Scoreboard_GetPlayerRecordByName(playerName)
    return playerRecord and playerRecord.IsRookie

end



function ScoreboardUI_GetTeamHasCommander(teamNumber)

    CheckForReload()

    for i = 1, #sortedPlayerData do

        local playerRecord = sortedPlayerData[i]
        if playerRecord.EntityTeamNumber == teamNumber and playerRecord.IsCommander then
            return true
        end

    end

    return false

end

function ScoreboardUI_GetCommanderName(teamNumber)

    CheckForReload()

    for i = 1, #sortedPlayerData do

        local playerRecord = sortedPlayerData[i]
        if playerRecord.EntityTeamNumber == teamNumber and playerRecord.IsCommander then
            return playerRecord.Name
        end

    end

    return nil

end

-- Expensive! Avoid usage!
function ScoreboardUI_GetOrderedCommanderNames(teamNumber)

    CheckForReload()
    local commanders = {}

    -- Create table of commander entity ids and names
    for i = 1, #sortedPlayerData do

        local playerRecord = sortedPlayerData[i]

        if playerRecord.EntityTeamNumber == teamNumber and playerRecord.IsCommander then
            table.insert( commanders, {playerRecord.EntityId, playerRecord.Name} )
        end

    end

    local function sortCommandersByEntity(pair1, pair2)
        return pair1[1] < pair2[1]
    end

    -- Sort it by entity id
    table.sort(commanders, sortCommandersByEntity)

    -- Return names in order
    local commanderNames = {}
    for _, pair in ipairs(commanders) do
        table.insert(commanderNames, pair[2])
    end

    return commanderNames

end

-- Expensive! Avoid usage!
function ScoreboardUI_GetNumberOfAliensByType(alienType)

    CheckForReload()
    local numberOfAliens = 0

    local typeId = kPlayerStatus[alienType]

    for _, playerRecord in ipairs(sortedPlayerData) do
        if typeId and typeId == playerRecord.StatusId then
            numberOfAliens = numberOfAliens + 1
        end
    end

    return numberOfAliens

end