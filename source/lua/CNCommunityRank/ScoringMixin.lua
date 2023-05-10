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
    local baseCopyPlayerDataFrom = ScoringMixin.CopyPlayerDataFrom
    function ScoringMixin:CopyPlayerDataFrom(player)
        baseCopyPlayerDataFrom(self,player)

        self.rankDelta = player.rankDelta
        self.rankCommDelta = player.rankCommDelta
        self.fakeBot = player.fakeBot
        self.emblem = player.emblem
        
        self.prewarmTier = player.prewarmTier
        self.prewarmTime = player.prewarmTime
        
        self.group = player.group
        
        self.queueIndex = player.queueIndex
        self.reservedQueueIndex = player.reservedQueueIndex
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

