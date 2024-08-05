--[[
    ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======

    lua\PlayerInfoEntity.lua

    Created by:   Andreas Urwalek(andi@unknownworlds.com)

     Stores information of connected players.

     ========= For more information, visit us at http://www.unknownworlds.com =====================
]]

local clientIndexToSteamId = {}

function GetSteamIdForClientIndex(clientIndex)
    return clientIndexToSteamId[clientIndex]
end

class 'PlayerInfoEntity' (Entity)

PlayerInfoEntity.kMapName = "playerinfo"

local kMaxGroupName = 15

local networkVars =
{
    -- those are not necessary for this entity
    m_angles = "angles (by 10 [], by 10 [], by 10 [])",
    m_origin = "position (by 2000 [], by 2000 [], by 2000 [])",

    clientId = "entityid",
    steamId = "integer",
    playerId = "entityid",
    playerName = string.format("string (%d)", kMaxNameLength * 4 ),
    teamNumber = string.format("integer (-1 to %d)", kRandomTeamType),
    score = string.format("integer (0 to %d)", kMaxScore),
    kills = string.format("integer (0 to %d)", kMaxKills),
    assists = string.format("integer (0 to %d)", kMaxKills),
    deaths = string.format("integer (0 to %d)", kMaxDeaths),
    resources = string.format("integer (0 to %d)", kMaxPersonalResources),
    isCommander = "boolean",
    isRookie = "boolean",
    status = "enum kPlayerStatus",
    isSpectator = "boolean",
---------------
    playerSkill = "integer",
    playerSkillOffset = "integer",
    commanderSkill = "integer",
    commanderSkillOffset = "integer",
    fakeBot = "boolean",
    hideRank = "boolean",
    emblem = "integer (-64 to 64)",
    prewarmTier = "integer(0 to 16)",
    prewarmTime = "integer",
    prewarmScore = "integer",
    group = string.format("string (%d)", kMaxGroupName ),
    queueIndex = "integer (0 to 64)",
    reservedQueueIndex = "integer (0 to 64)",
    lastSeenName = string.format("string(%d)",kMaxNameLength * 4),
    ns2TimePlayed = "integer",
    reputation = "integer(-512 to 512)",
    showingSkill = "integer",
    showingCommSkill = "integer",
-----------
    adagradSum = "float",
    currentTech = "integer",
    callingCard = "enum kCallingCards",
}

function PlayerInfoEntity:OnCreate()

    Entity.OnCreate(self)

    self:SetUpdates(true, kDefaultUpdateRate)
    self:SetPropagate(Entity.Propagate_Always)

    if Server then

        self.clientId = -1
        self.playerId = Entity.invalidId
        self.status = kPlayerStatus.Void

    end

    self:AddTimedCallback(PlayerInfoEntity.UpdateScore, 0.3)

end


--Insight upgrades bitmask table
local techUpgradesTable =
{
    kTechId.Jetpack,
    kTechId.Welder,
    kTechId.ClusterGrenade,
    kTechId.PulseGrenade,
    kTechId.GasGrenade,
    kTechId.Mine,

    kTechId.Vampirism,
    kTechId.Carapace,
    kTechId.Regeneration,

    kTechId.Aura,
    kTechId.Focus,
    kTechId.Camouflage,

    kTechId.Celerity,
    kTechId.Adrenaline,
    kTechId.Crush,

    kTechId.Parasite
}

local techUpgradesBitmask = CreateBitMask(techUpgradesTable)

function PlayerInfoEntity:UpdateScore()

    if Server then

        local scorePlayer = Shared.GetEntity(self.playerId)

        if scorePlayer then

            self.clientId = scorePlayer:GetClientIndex()
            self.steamId = scorePlayer:GetSteamId()
            self.entityId = scorePlayer:GetId()
            self.playerName = string.UTF8Sub(scorePlayer:GetName(), 0, kMaxNameLength)
            self.teamNumber = scorePlayer:GetTeamNumber()
            self.callingCard = scorePlayer:GetCallingCard()

            local playerSkill,playerSkillOffset, commanderSkill, commanderSkillOffset

            if HasMixin(scorePlayer, "Scoring") then

                playerSkill = scorePlayer:GetPlayerSkill()
                playerSkillOffset = scorePlayer:GetPlayerSkillOffset()
                commanderSkill = scorePlayer:GetCommanderSkill()
                commanderSkillOffset = scorePlayer:GetCommanderSkillOffset()
                
                self.score = scorePlayer:GetScore()
                self.kills = scorePlayer:GetKills()
                self.assists = scorePlayer:GetAssistKills()
                self.deaths = scorePlayer:GetDeaths()
            -------------
                self.playerSkill = playerSkill
                self.playerSkillOffset = playerSkillOffset
                self.commanderSkill = commanderSkill
                self.commanderSkillOffset = commanderSkillOffset
                self.group = scorePlayer.group
                self.fakeBot = scorePlayer.fakeBot
                self.hideRank = scorePlayer.hideRank
                self.emblem = scorePlayer.emblem
                self.prewarmTier = scorePlayer.prewarmTier
                self.prewarmTime = scorePlayer.prewarmTime
                self.prewarmScore = scorePlayer.prewarmScore
                self.queueIndex = scorePlayer.queueIndex
                self.reservedQueueIndex = scorePlayer.reservedQueueIndex
                self.lastSeenName = scorePlayer.lastSeenName
                self.ns2TimePlayed = scorePlayer.ns2TimePlayed
                self.reputation = scorePlayer.reputation
                self.showingSkill = scorePlayer:GetHiveSkill()
                self.showingCommSkill = scorePlayer:GetHiveCommSkill()
            -------------
                self.adagradSum = scorePlayer:GetAdagradSum()
                local scoreClient = scorePlayer:GetClient()
                Server.UpdatePlayerInfo( scoreClient, self.playerName, self.score )

            end

            -- Handle Stats
            if self.steamId and self.steamId > 0 then

                StatsUI_MaybeInitClientStats(self.steamId, nil, self.teamNumber)
                StatsUI_SetBaseClientStatsInfo(self.steamId, self.playerName, self.playerSkill, playerSkillOffset, commanderSkill, commanderSkillOffset, self.isRookie)
    
            end

            self.resources = scorePlayer:GetResources()
            self.isCommander = scorePlayer:isa("Commander")
            self.isRookie = scorePlayer:GetIsRookie()
            self.status = scorePlayer:GetPlayerStatusDesc()
            self.isSpectator = scorePlayer:isa("Spectator")

            self.reinforcedTierNum = scorePlayer.reinforcedTierNum

            --Always reset this value so we don't have to check for previous tech to remove it, etc
            self.currentTech = 0

            if scorePlayer:isa("Alien") then
                for _, upgrade in ipairs(scorePlayer:GetUpgrades()) do
                    if techUpgradesBitmask[upgrade] then
                        self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[upgrade])
                    end
                end
            elseif scorePlayer:isa("Marine") then
                if scorePlayer:GetIsParasited() then
                    self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[kTechId.Parasite])
                end

                if scorePlayer:isa("JetpackMarine") then
                    self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[kTechId.Jetpack])
                end

                --Mapname to TechId list of displayed weapons
                local displayWeapons = { { Welder.kMapName, kTechId.Welder },
                    { ClusterGrenadeThrower.kMapName, kTechId.ClusterGrenade },
                    { PulseGrenadeThrower.kMapName, kTechId.PulseGrenade },
                    { GasGrenadeThrower.kMapName, kTechId.GasGrenade },
                    { LayMines.kMapName, kTechId.Mine} }

                for _, weapon in ipairs(displayWeapons) do
                    if scorePlayer:GetWeapon(weapon[1]) ~= nil then
                        self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[weapon[2]])
                    end
                end
            end

        else
            DestroyEntity(self)
        end

    end

    clientIndexToSteamId[self.clientId] = self.steamId

    return true

end

if Server then

    function PlayerInfoEntity:SetScorePlayer(player)

        self.playerId = player:GetId()
        self:UpdateScore()

    end

end

function GetTechIdsFromBitMask(techTable)

    local techIds = { }

    if techTable and techTable > 0 then
        for _, techId in ipairs(techUpgradesTable) do
            local bitmask = techUpgradesBitmask[techId]
            if bit.band(techTable, bitmask) > 0 then
                table.insert(techIds, techId)
            end
        end
    end

    --Sort the table by bitmask value so it keeps the order established in the original table
    table.sort(techIds, function(a, b) return techUpgradesBitmask[a] < techUpgradesBitmask[b] end)

    return techIds
end

Shared.LinkClassToMap("PlayerInfoEntity", PlayerInfoEntity.kMapName, networkVars)