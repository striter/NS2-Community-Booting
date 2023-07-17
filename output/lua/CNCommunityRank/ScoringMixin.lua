ScoringMixin.networkVars.rankDelta = "integer"
ScoringMixin.networkVars.rankOffsetDelta = "integer"
ScoringMixin.networkVars.rankCommDelta = "integer"
ScoringMixin.networkVars.rankCommOffsetDelta = "integer"

local baseInitMixin = ScoringMixin.__initmixin
function ScoringMixin:__initmixin()
    baseInitMixin(self)
    self.group = "RANK_INVALID"
    
    self.rankDelta = 0 
    self.rankOffsetDelta = 0  
    self.rankCommDelta = 0 
    self.rankCommOffsetDelta = 0
    
    self.fakeBot = false 
    self.hideRank = false 
    self.emblem = 0
    self.lastSeenName = ""
    
    self.prewarmTier = 0  
    self.prewarmTime = 0
    
    self.queueIndex = 0  
    self.reservedQueueIndex = 0
end

function ScoringMixin:GetPlayerSkill()
    return math.max(0,self.skill + self.rankDelta)
end

function ScoringMixin:GetCommanderSkill()
    return math.max(0,self.commSkill + self.rankCommDelta)
end

function ScoringMixin:GetPlayerSkillOffset()
    return self.skillOffset + self.rankOffsetDelta
end

function ScoringMixin:GetCommanderSkillOffset()
    return self.commSkillOffset + self.rankCommOffsetDelta
end

function ScoringMixin:GetPlayerTeamSkill()
    assert(HasMixin(self, "Team"))
    local team = self:GetTeamNumber()
    local skill = self:GetPlayerSkill()

    if team ~= kTeam1Index and team ~= kTeam2Index then
        return self.skill   --just stick with the "average" for RR players
    end

    local skillOffset = self:GetPlayerSkillOffset()
    return
    ( team == kTeam1Index ) and
            skill + skillOffset or
            skill - skillOffset
end

if Server then
    local baseCopyPlayerDataFrom = ScoringMixin.CopyPlayerDataFrom
    function ScoringMixin:CopyPlayerDataFrom(player)
        baseCopyPlayerDataFrom(self,player)
        self.group = player.group

        self.rankDelta = player.rankDelta   
        self.rankOffsetDelta = player.rankOffsetDelta
        self.rankCommDelta = player.rankCommDelta   
        self.rankCommOffsetDelta = player.rankCommOffsetDelta
        
        self.fakeBot = player.fakeBot
        self.hideRank = player.hideRank
        self.emblem = player.emblem
        self.lastSeenName = player.lastSeenName
        
        self.prewarmTier = player.prewarmTier
        self.prewarmTime = player.prewarmTime
        
        self.queueIndex = player.queueIndex
        self.reservedQueueIndex = player.reservedQueueIndex
    end

    function ScoringMixin:SetPlayerExtraData(dataTable)
        self.rankDelta = dataTable.rank or 0
        self.rankOffsetDelta = dataTable.rankOffset or 0
        self.rankCommDelta = dataTable.rankComm or 0
        self.rankCommOffsetDelta = dataTable.rankCommOffset or 0
        
        self.fakeBot = dataTable.fakeBot or false
        self.hideRank = dataTable.hideRank or false
        self.emblem = dataTable.emblem or 0
        self.lastSeenName = dataTable.lastSeenName or ""
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

