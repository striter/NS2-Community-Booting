-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\DeathMessage_Client.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kSubImageWidth = 128
local kSubImageHeight = 64

local queuedDeathMessages = { }

local resLostMarine = 0
local resLostAlien = 0
local rtsLostMarine = 0
local rtsLostAlien = 0
local resRecovered = 0

kDeathSource = enum({
    "Structure",
    "StructureNoCommander",
    "DeathTrigger",
    "Player",
    "KilledSelf",
    "TunnelDeath",
})

-- Can't have multi-dimensional arrays so return potentially very long array [color, name, color, name, doerid, ....]
function DeathMsgUI_GetMessages()

    local returnArray = {}
    -- local arrayIndex = 1
    
    -- return list of recent death messages
    for _, deathMsg in ipairs(queuedDeathMessages) do
    
        for _, element in ipairs(deathMsg) do
            table.insert(returnArray, element)
        end
        
    end
    
    -- Clear current death messages
    table.clear(queuedDeathMessages)
    
    return returnArray
    
end

function DeathMsgUI_MenuImage()
    return "death_messages"
end

function DeathMsgUI_GetTechOffsetX(_)
    return 0
end

function DeathMsgUI_GetTechOffsetY(iconIndex)

    if not iconIndex then
        iconIndex = 1
    end
    
    return (iconIndex - 1)*kSubImageHeight
    
end

function DeathMsgUI_GetTechWidth(_)
    return kSubImageWidth
end

function DeathMsgUI_GetTechHeight(_)
    return kSubImageHeight
end

-- Pass 1 for isPlayer if coming from a player (look it up from scoreboard data), otherwise it's a tech id
local function GetDeathMessageEntityName(isPlayer, clientIndexOrTechId)
    
    PROFILE("DeathMessage_Client:GetDeathMessageEntityName")
    
    local name = ""
    
    if isPlayer then
        name = Scoreboard_GetPlayerData(clientIndexOrTechId, "Name")
    elseif clientIndexOrTechId ~= -1 then
        name = GetDisplayNameForTechId(clientIndexOrTechId)
    end
    
    return name or ""
    
end

-- Stored the name of the last killer.
local gContext
local gKillerName
local gKillerCallingCard
local gKillerSteamId32
local gKillerSkill
local gKillerAdagradSum
local gKillerRookie
local gKillerWeaponIconIndex

local function ClearKillerInfo()
    gContext = nil
    gKillerName = nil
    gKillerCallingCard = nil
    gKillerSteamId32 = nil
    gKillerSkill = nil
    gKillerAdagradSum = nil
    gKillerRookie = nil
    gKillerWeaponIconIndex = nil
end

function GetAndClearKillerInfo()

    local killerInfo =
    {
        Context = gContext,
        Name = gKillerName,
        CallingCard = gKillerCallingCard,
        SteamId = gKillerSteamId32,
        Skill = gKillerSkill,
        AdagradSum = gKillerAdagradSum,
        IsRookie = gKillerRookie,
        WeaponIconIndex = gKillerWeaponIconIndex,
    }

    ClearKillerInfo()

    return killerInfo

end

function DeathMsgUI_GetResLost(teamNumber)

    if teamNumber == kTeam1Index then

        return resLostMarine

    elseif teamNumber == kTeam2Index then

        return resLostAlien

    end

    return nil

end

function DeathMsgUI_GetRtsLost(teamNumber)

    if teamNumber == kTeam1Index then

        return rtsLostMarine

    elseif teamNumber == kTeam2Index then

        return rtsLostAlien

    end

    return nil

end

function DeathMsgUI_GetCystsLost()

    return cystsLost

end

function DeathMsgUI_GetResRecovered()

    return resRecovered

end

function DeathMsgUI_ResetStats()

    resLostMarine = 0
    resLostAlien = 0
    rtsLostMarine = 0
    rtsLostAlien = 0
    resRecovered = 0
    
end

function DeathMsgUI_AddResLost(teamNumber, res)
    
    PROFILE("DeathMsgUI_AddResLost")
    
    if teamNumber == kTeam1Index then
        resLostMarine = resLostMarine + res
    elseif teamNumber == kTeam2Index then
        resLostAlien = resLostAlien + res
    end

end

function DeathMsgUI_AddRtsLost(teamNumber, rts)
    
    PROFILE("DeathMsgUI_AddRtsLost")
    
    if teamNumber == kTeam1Index then
        rtsLostMarine = rtsLostMarine + rts
    elseif teamNumber == kTeam2Index then
        rtsLostAlien = rtsLostAlien + rts
    end

end

function DeathMsgUI_AddResRecovered(amount)
    
    PROFILE("DeathMsgUI_AddResRecovered")
    
    resRecovered = resRecovered + amount

end

local function EnqueueDeathMessage(killerColor, killerName, targetColor, targetName, iconIndex, targetIsPlayer)

    PROFILE("DeathMessage_Client:EnqueueDeathMessage")
    
    local deathMessage =
    {
        killerColor,
        killerName,
        targetColor,
        targetName,
        iconIndex,
        targetIsPlayer,
    }
    
    table.insert(queuedDeathMessages, deathMessage)

end

local function GetDeathMessageEntityCallingCard(isPlayer, clientIndex, killedSelf)

    PROFILE("DeathMessage_Client:GetDeathMessageEntityCallingCard")
-----------------------?
    if isPlayer then --and not killedSelf then
---------------------
        return Scoreboard_GetPlayerData(clientIndex, "CallingCard")
    end

    return kNaturalCausesCallingCard

end

local kNaturalCausesText = Locale.ResolveString("DEATHSCREEN_SELFKILL_TITLE")
local function AddDeathMessage(killerIsPlayer, killerIndex, killerTeamNumber, iconIndex, targetIsPlayer, targetIndex, targetTeamNumber)
    
    PROFILE("DeathMessage_Client:AddDeathMessage")

    local killerName = GetDeathMessageEntityName(killerIsPlayer, killerIndex)
    local targetName = GetDeathMessageEntityName(targetIsPlayer, targetIndex)
    
    Print("%s killed %s with %s", killerName, targetName, EnumToString(kDeathMessageIcon, iconIndex))
    
    if targetIsPlayer ~= 1 then
    
        if targetTeamNumber == kTeam1Index then
        
            local techIdString = string.gsub(targetName, "%s+", "")
            local techId = StringToEnum(kTechId, techIdString)
            local resOverride = false
            
            if techIdString == "AdvancedArmory" then
                resOverride = kArmoryCost + kAdvancedArmoryUpgradeCost
            elseif techIdString == "ARCRoboticsFactory" then
                resOverride = kRoboticsFactoryCost + kUpgradeRoboticsFactoryCost
            end
            
            local amount = resOverride or LookupTechData(techId, kTechDataCostKey, 0)
            
            DeathMsgUI_AddResLost(kTeam1Index, amount)
            
            if techIdString == "Extractor" then
                DeathMsgUI_AddRtsLost(kTeam1Index, 1)
            end
            
        elseif targetTeamNumber == kTeam2Index then
        
            local techIdString = string.gsub(targetName, "%s+", "")
            local techId = StringToEnum(kTechId, techIdString)
            local resOverride = false
            
            if techIdString == "Egg" or techIdString == "Hydra" or techIdString == "MiniCyst" or techIdString == "GooWall" then
                resOverride = 0
            elseif techIdString == "CragHive" or techIdString == "ShadeHive" or techIdString == "ShiftHive" then
                resOverride = kHiveCost + kUpgradeHiveCost
            end
            
            -- Change to only add cost if TRes, gonna add exceptions manually for now -DGH
            local amount = (resOverride or LookupTechData(techId, kTechDataCostKey, 0))
            
            DeathMsgUI_AddResLost(kTeam2Index, amount)
            
            if techIdString == "Harvester" then
                DeathMsgUI_AddRtsLost(kTeam2Index, 1)
            end
            
        end
        
    end
    
    local killedSelf = killerIsPlayer and targetIsPlayer and killerIndex == targetIndex
    
    EnqueueDeathMessage(GetColorForTeamNumber(killerTeamNumber), killedSelf and "" or killerName, GetColorForTeamNumber(targetTeamNumber), targetName, iconIndex, targetIsPlayer)
    
    local player = Client.GetLocalPlayer()
    if player and player.GetName and player:GetName() == targetName then

        ClearKillerInfo()

        gKillerWeaponIconIndex = iconIndex

        if killerIsPlayer then -- We have direct info on our killer.

            --playerRecord.EntityTeamNumber: should color name text?

            gContext = killedSelf and kDeathSource.KilledSelf or kDeathSource.Player
            gKillerCallingCard = GetDeathMessageEntityCallingCard(killerIsPlayer, killerIndex, killedSelf)
            gKillerName = killedSelf and kNaturalCausesText or killerName

            -- Skill Badge
            gKillerSteamId32 = Scoreboard_GetPlayerData(killerIndex, "SteamId")
            gKillerSkill = Scoreboard_GetPlayerData(killerIndex, "Skill")
            gKillerAdagradSum = Scoreboard_GetPlayerData(killerIndex, "AdagradSum")
            gKillerRookie = Scoreboard_GetPlayerData(killerIndex, "IsRookie")

        else -- killerIndex is a techID, or is for a Death Trigger

            if killerIndex == kTechId.DeathTrigger or killerIndex == kTechId.TunnelTube then -- "NaturalCauses" case

                gContext = kDeathSource.DeathTrigger -- Tunnel death is piggy-backing, oh well
                gKillerCallingCard = kNaturalCausesCallingCard
                gKillerName = kNaturalCausesText

                -- No Skill Badge


            else -- Killer is structure, fill out info using last commander info

                local lastCommanderInfo = killerTeamNumber == kAlienTeamType and Scoreboard_GetLastAlienCommanderInfo() or Scoreboard_GetLastMarineCommanderInfo()
                if lastCommanderInfo then -- We have a last commander, so use that cached info. (Similar to player)

                    -- Assume we never kill ourselves here, even if the last commander on the other team is us.
                    gContext = kDeathSource.Structure
                    gKillerCallingCard = lastCommanderInfo.CallingCard
                    gKillerName = lastCommanderInfo.Name

                    -- Skill Badge
                    gKillerSteamId32 = lastCommanderInfo.SteamId32
                    gKillerSkill = lastCommanderInfo.Skill
                    gKillerAdagradSum = lastCommanderInfo.AdagradSum
                    gKillerRookie = lastCommanderInfo.Rookie

                else -- No commander has jumped in the chair yet, so just fill out a minimal case.

                    gContext = kDeathSource.StructureNoCommander
                    gKillerCallingCard = kNaturalCausesCallingCard
                    gKillerName = EnumToString(kDeathMessageIcon, iconIndex)

                    -- No Skill Badge

                end

            end

        end
        
    end
    
end

local function OnDeathMessage(message)
    PROFILE("DeathMessage_Client:OnDeathMessage")
    AddDeathMessage(message.killerIsPlayer, message.killerId, message.killerTeamNumber, message.iconIndex, message.targetIsPlayer, message.targetId, message.targetTeamNumber)
end
Client.HookNetworkMessage("DeathMessage", OnDeathMessage)