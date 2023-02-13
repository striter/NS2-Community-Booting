ScoringMixin.networkVars.communityRank = "integer"

local baseInitMixin = ScoringMixin.__initmixin
function ScoringMixin:__initmixin()
    baseInitMixin(self)
    self.communityRank = 0
    self.fakeBot = false
    self.group = "RANK_INVALID"
end

function ScoringMixin:GetPlayerSkill()
    return math.max(0,self.skill + self.communityRank)
end

function ScoringMixin:GetCommanderSkill()
    return math.max(0,self.commSkill + self.communityRank)
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
        self.group = player.group
        self.communityRank = player.communityRank
        self.fakeBot = player.fakeBot
        self.emblem = player.emblem
---------
    end

    function ScoringMixin:SetPlayerExtraData(dataTable)
        self.communityRank = dataTable.rank or 0
        self.fakeBot = dataTable.fakeBot or false
        self.emblem = dataTable.emblem or 0
    end
    
    function ScoringMixin:SetGroup(_group)
        self.group = _group
    end
end --End-Server

