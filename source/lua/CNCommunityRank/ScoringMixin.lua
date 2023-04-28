ScoringMixin.networkVars.rankDelta = "integer"
ScoringMixin.networkVars.rankCommDelta = "integer"

local baseInitMixin = ScoringMixin.__initmixin
function ScoringMixin:__initmixin()
    baseInitMixin(self)
    self.rankDelta = 0
    self.rankCommDelta = 0
    self.fakeBot = false
    self.prewarmTier = 0
    self.prewarmTime = 0
    self.group = "RANK_INVALID"
    self.emblem = 0
    self.queueIndex = 0
    self.reservedQueueIndex = 0
end

function ScoringMixin:GetPlayerSkill()
    return math.max(0,self.skill + self.rankDelta)
end

function ScoringMixin:GetCommanderSkill()
    return math.max(0,self.commSkill + self.rankCommDelta)
end

if Server then

    function ScoringMixin:CopyPlayerDataFrom(player)
    
        self.scoreGainedCurrentLife = player.scoreGainedCurrentLife    
        self.score = player.score or 0
        self.kills = player.kills or 0
        self.assistkills = player.assistkills or 0
        self.deaths = player.deaths or 0
        self.playTime = player.playTime or 0
        self.commanderTime = player.commanderTime or 0
        self.marineTime = player.marineTime or 0
        self.alienTime = player.alienTime or 0
        
        self.weightedEntranceTimes = player.weightedEntranceTimes
        self.weightedExitTimes = player.weightedExitTimes
        
        self.weightedCommanderTimes = player.weightedCommanderTimes

        self.teamAtEntrance = player.teamAtEntrance
        
        self.totalKills = player.totalKills
        self.totalAssists = player.totalAssists
        self.totalDeaths = player.totalDeaths
        self.skill = player.skill
        self.skillOffset = player.skillOffset
        self.commSkill = player.commSkill
        self.commSkillOffset = player.commSkillOffset
        self.adagradSum = player.adagradSum
        self.commAdagradSum = player.commAdagradSum
        self.skillTier = player.skillTier
        self.totalScore = player.totalScore
        self.totalPlayTime = player.totalPlayTime
        self.playerLevel = player.playerLevel
        self.totalXP = player.totalXP

----------
        self.rankDelta = player.rankDelta
        self.rankCommDelta = player.rankCommDelta
        self.fakeBot = player.fakeBot
        self.emblem = player.emblem
        self.prewarmTier = player.prewarmTier
        self.prewarmTime = player.prewarmTime
        self.group = player.group
        self.queueIndex = player.queueIndex
        self.reservedQueueIndex = player.reservedQueueIndex
---------
    end

    function ScoringMixin:SetPlayerExtraData(dataTable)
        self.rankDelta = dataTable.rank or 0
        self.rankCommDelta = dataTable.rankComm or 0
        self.fakeBot = dataTable.fakeBot or false
        self.emblem = dataTable.emblem or 0
    end
    
    function ScoringMixin:SetGroup(_group)
        self.group = _group
    end
    
    function ScoringMixin:SetQueueIndex(_index)
        if _index == 0 then
            self.queueIndex = 0
            self.reservedQueueIndex = 0
        end

        if _index < 0 then
            self.reservedQueueIndex = -_index
        else
            self.queueIndex = _index
        end 
    end
    
    function ScoringMixin:SetPrewarmData(dataTable)
        self.prewarmTier = dataTable.tier or 0
        self.prewarmTime = math.floor((dataTable.time or 0) / 60)
    end
end --End-Server

