
local Plugin = Shine.Plugin( ... )

Plugin.Version = "1.0"
Plugin.PrintName = "communityprewarm"
Plugin.HasConfig = true
Plugin.ConfigName = "CommunityPrewarm.json"
Plugin.DefaultConfig = {
    Restriction = {
        Hour = 4,           --Greater than this hour
        Player = 12,
    },
    ScoreMultiplier = {
        Restricted = 0.5,
        RestrictedActive = 1,
        Idle = 1,
        Active = 2,
        Dead = -1,
    },
    EndGameReward = {
        BaseCredit = 8,
        MinuteEachCredit = 4,
        MinCredit = 0.5,
        MaxCredit = 3,
        CommanderCredit = 3,
        CommanderMinMinute = 5,
    },
    ["Tier"] = {
        [1] = { Count = 1, Credit = 15, Inform = true, Member = 0 },
        [2] = { Count = 2, Credit = 8, Inform = true, Member = 0 },
        [3] = { Count = 5, Credit = 5, Member = 0 },
        [4] = { Count = 9, Credit = 3, Member = 0 },
    },
    LateGameAward = {
        Hour = 22.5,
        Credit = 1,
        MaxPlayers = 32,
        ActiveDurationNormalized = 0.8,
    },
    ReturnReward = {
        Enabled = false,
        CreditFirstJoin = 4,
        DayOffset = 10,
        CreditReturn = 10,
    },
    PrewarmScoreInField = 10,
    FloorCredit = 6,
}

Plugin.kPrefix = "[战局预热]"
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true
do
    local Validator = Shine.Validator()
    Validator:AddFieldRule( "EndGameReward",  Validator.IsType( "table", Plugin.DefaultConfig.EndGameReward ))
    Validator:AddFieldRule( "EndGameReward.MaxCredit",  Validator.IsType( "number", Plugin.DefaultConfig.EndGameReward.MaxCredit ))
    Validator:AddFieldRule( "EndGameReward.CommanderCredit",  Validator.IsType( "number", Plugin.DefaultConfig.EndGameReward.CommanderCredit ))
    Validator:AddFieldRule( "EndGameReward.CommanderMinMinute",  Validator.IsType( "number", Plugin.DefaultConfig.EndGameReward.CommanderMinMinute ))
    Validator:AddFieldRule( "ScoreMultiplier",  Validator.IsType( "table", Plugin.DefaultConfig.ScoreMultiplier ))
    Validator:AddFieldRule( "ScoreMultiplier.RestrictedActive",  Validator.IsType( "number", Plugin.DefaultConfig.ScoreMultiplier.RestrictedActive ))
    Validator:AddFieldRule( "ScoreMultiplier.Dead",  Validator.IsType( "number", Plugin.DefaultConfig.ScoreMultiplier.Dead ))
    Validator:AddFieldRule( "Restriction.Hour",  Validator.IsType( "number", Plugin.DefaultConfig.Restriction.Hour ))
    Validator:AddFieldRule( "Restriction.Player",  Validator.IsType( "number", Plugin.DefaultConfig.Restriction.Player ))
    Validator:AddFieldRule( "Tier",  Validator.IsType( "table", Plugin.DefaultConfig.Tier))
    Validator:AddFieldRule( "ReturnReward", Validator.IsType("table",Plugin.DefaultConfig.ReturnReward))
    Validator:AddFieldRule( "LateGameAward",  Validator.IsType( "table", Plugin.DefaultConfig.LateGameAward))
    Validator:AddFieldRule( "LateGameAward.ActiveDurationNormalized",  Validator.IsType( "number", Plugin.DefaultConfig.LateGameAward.ActiveDurationNormalized))
    Validator:AddFieldRule( "PrewarmScoreInField",  Validator.IsType( "number", Plugin.DefaultConfig.PrewarmScoreInField))
    Validator:AddFieldRule( "FloorCredit",  Validator.IsType( "number", Plugin.DefaultConfig.FloorCredit))
    for i, tierData in ipairs(Plugin.DefaultConfig.Tier) do
        Validator:AddFieldRule( string.format("Tier.%d.Member", i),  Validator.IsType( "number", 0 ))
    end
    Plugin.ConfigValidator = Validator
end

local kPrewarmColor = { 235, 152, 78 }
local kErrorColor = { 236, 112, 99 }

local kPrewarmFile = "config://shine/temp/prewarm.json"
local kPrewarmAward = "config://shine/temp/prewarmLastDay.json"
local kPrewarmRecord = "config://shine/temp/prewarmRecord.json"

function Plugin:Initialise()
    self.PrewarmTracker = {}
    self.MemberInfos = {}
    self:CreateMessageCommands()

    self.PrewarmData = Shine.LoadJSONFile(kPrewarmFile) or {
        ValidationDay = 0,
        Validated = false,
        UserData = {
            ["55022511"] = {tier = 0, score = 0, time = 100, credit = 0, name = "StriteR."}
        },
    }
    self.PrewarmAwardFile = Shine.LoadJSONFile(kPrewarmAward) or { }
    self.PrewarmRecordFile = Shine.LoadJSONFile(kPrewarmRecord) or { }
    return true
end

local function GetCurrentRecordTable(self)
    local key = tostring(kCurrentTimeStampDay)
    if not self.PrewarmRecordFile[key] then
        self.PrewarmRecordFile[key] = {}
    end
    return self.PrewarmRecordFile[key]
end

local function ReadPersistent(self)
    table.Empty(self.MemberInfos)
    for k,v in pairs(self.PrewarmData.UserData) do
        self.MemberInfos[tonumber(k)] = v
    end
end

local function SavePersistent(self)
    for k,v in pairs(self.MemberInfos) do
        self.PrewarmData.UserData[tostring(k)] = v
    end

    local Success, Err = Shine.SaveJSONFile( self.PrewarmData, kPrewarmFile)
    if not Success then
        Shared.Message( "Error saving prewarm file: "..Err )
    end
    Shine.SaveJSONFile(self.PrewarmRecordFile,kPrewarmRecord)
    Shine.SaveJSONFile(self.PrewarmAwardFile,kPrewarmAward)
end

function Plugin:ResetState()
    table.Empty(self.MemberInfos)
    table.Empty(self.PrewarmTracker)
    ReadPersistent(self)
end

function Plugin:Cleanup()
    table.Empty(self.MemberInfos)
    table.Empty(self.PrewarmTracker)
    return self.BaseClass.Cleanup( self )
end

local function GetPlayerData(self, _clientID)
    if not self.MemberInfos[_clientID] then
        self.MemberInfos[_clientID] = {name = "", score = 0, time = 0, tier = 0, credit = 0}
    end

    return self.MemberInfos[_clientID]
end

local function NotifyClient(self, _client,_id)
    if not _client then return end

    local data = self.MemberInfos[_id]
    if data and data.credit > 0 then
        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                255, 255, 255,string.format(
                        "当前剩余%s[预热点],可用于兑换下场特权%s",
                        data.credit,
                        data.tier > 0 and ",亦可以在计分板点击玩家将预热点给予他人." or ".") )
        return true
    end

    return false
end

local function GetPlayerRank(self, _clientID)
    local targetScore = self.MemberInfos[_clientID] and self.MemberInfos[_clientID].score or 0
    local rank = 1
    for id, data in pairs(self.MemberInfos) do
        if id ~= _clientID and data.score > targetScore then
            rank = rank + 1
        end
    end
    return rank, table.Count(self.MemberInfos)
end

local function TrackClient(self, _client, _clientID)
    local now = Shared.GetTime()

    local player = _client:GetControllingPlayer()
    local curData = { time = now, score = player:GetScore(), kills = player:GetKills() or 0, assists = player:GetAssistKills() or 0, commTime = player:GetAlienCommanderTime() + player:GetMarineCommanderTime()}
    if not self.PrewarmTracker[_clientID] then
        self.PrewarmTracker[_clientID] = curData
    end

    local prewarmData = GetPlayerData(self,_clientID)
    local prevData = self.PrewarmTracker[_clientID]
    local trackTime = math.floor(curData.time - prevData.time)
    if not self.PrewarmData.Validated then
        local activePrewarm = kCurrentHour >= self.Config.Restriction.Hour

        local activePlayed = false
        local gameMode = Shine.GetGamemode()
        if table.contains(Shine.kRankGameMode,gameMode) then
            activePlayed = (curData.commTime > prevData.commTime) or (curData.score > prevData.score)
        elseif table.contains(Shine.kSeedingGameMode,gameMode) then
            activePlayed = (curData.kills > prevData.kills) or (curData.assists > prevData.assists)
        end

        local idleMultiplier = activePrewarm and self.Config.ScoreMultiplier.Idle or self.Config.ScoreMultiplier.Restricted
        local activeMultiplier = activePrewarm and self.Config.ScoreMultiplier.Active or self.Config.ScoreMultiplier.RestrictedActive

        local trackTimeMultiplier = activePlayed and activeMultiplier or idleMultiplier

        if Shine.GetHumanPlayerCount() >= self.Config.Restriction.Player then
            local playerTeam = player:GetTeamNumber()
            if playerTeam == kSpectatorIndex or playerTeam == kTeamReadyRoom then
                trackTimeMultiplier = self.Config.ScoreMultiplier.Dead
            end
        end
        
        prewarmData.score = math.max(0, prewarmData.score + trackTimeMultiplier * trackTime)
    end
    
    prewarmData.time = prewarmData.time + trackTime

    -- 每累积5分钟预热分(300分)时通知玩家
    local lastNotifyScore = prevData.lastNotifyScore or 0
    local scoreGain = prewarmData.score - lastNotifyScore
    if scoreGain >= 300 then
        local rank, total = GetPlayerRank(self, _clientID)
        local prevRank = prevData.lastNotifyRank or rank
        local rankChange = prevRank - rank
        local rankHint = rankChange > 0 and string.format(" 排名上升%d位!", rankChange)
                or (rankChange < 0 and string.format(" 排名下降%d位", -rankChange) or "")
        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3], self.kPrefix, 255, 255, 255,
                string.format("预热分累积+%d,当前[%d]分(第%d/%d名)%s",
                        math.floor(scoreGain / 60), math.floor(prewarmData.score / 60), rank, total, rankHint) )
        prevData.lastNotifyScore = prewarmData.score
        prevData.lastNotifyRank = rank
    end

    self.PrewarmTracker[_clientID] = curData
    player:SetPrewarmData(prewarmData)

    local record = GetCurrentRecordTable(self)
    record.PlayerCount = table.Count(self.MemberInfos)
end

local function TrackAllClients(self)
    for client in Shine.IterateClients() do
        if not client:GetIsVirtual() then
            TrackClient(self,client,client:GetUserId())
        end
    end
end

local function ValidateClient(self, _clientID, _data, _tier, _credit,_scoreOverride)
    _data = _data or GetPlayerData(self,_clientID)
    _data.tier = _tier
    _data.credit = _credit
    _data.score = _scoreOverride and _scoreOverride or _data.score
    self:Print(string.format("Validate %s %s %s %s",_clientID,_data.tier,_data.credit,_data.score ))

    local client = Shine.GetClientByNS2ID(_clientID)
    if not client then return end

    local player = client:GetControllingPlayer()
    player:SetPrewarmData(_data)
    if _data.tier > 0 then
        Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                string.format("预热激励已派发,已获得[预热徽章%s]及[%s预热点]!",_tier,_credit) )
    else
        Shine:NotifyDualColour( client, kErrorColor[1], kErrorColor[2], kErrorColor[3],self.kPrefix,255, 255, 255,
                "您的预热资格已被取消.")
    end
end

local function Reset(self)
    table.Empty(self.PrewarmData.UserData)
    table.Empty(self.MemberInfos)
    self.PrewarmData.ValidationDay = kCurrentDay
    self.PrewarmData.Validated = false
end

local function PrewarmdScoreEnable(self)
    if kCurrentHour < self.Config.Restriction.Hour then return false end
    return true
end

local function PrewarmValidate(self)
    if not PrewarmdScoreEnable(self) then return end
    if not table.contains(Shine.kRankGameMode,GetGamemode()) then return end
    if Shine.GetPlayingPlayersCount() < self.Config.Restriction.Player then return end
    
    if self.PrewarmData.Validated then return end
    self.PrewarmData.Validated = true
    GetCurrentRecordTable(self).PrewarmTime = tostring(os.time())

    -- 校验成功后给所有场内玩家增加 PrewarmScoreInField
    local scoreInField = self.Config.PrewarmScoreInField or 10
    for client in Shine.IterateClients() do
        if not client:GetIsVirtual() then
            local player = client:GetControllingPlayer()
            local team = player:GetTeamNumber()
            if Shine.IsPlayingTeam(team) then
                local clientID = client:GetUserId()
                local data = GetPlayerData(self, clientID)
                data.score = data.score + scoreInField
                Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3], self.kPrefix, 255, 255, 255,
                        string.format("预热校验成功,场内玩家获得[%d]预热分加成.", scoreInField) )
            end
        end
    end
    
    local prewarmClients = {}
    for clientID,prewarmData in pairs(self.MemberInfos) do
        table.insert(prewarmClients, { clientID = clientID, data = prewarmData})
    end

    local function PrewarmCompare(a, b) return a.data.score > b.data.score end
    table.sort(prewarmClients, PrewarmCompare)

    local nameList = ""
    local currentIndex = 0
    for _, prewarmClient in pairs(prewarmClients) do
        local curTier = 0
        local curTierData = nil
        local tierValidator = 0
        for tier, tierData in ipairs(self.Config.Tier) do
            tierValidator = tierValidator + tierData.Count
            if currentIndex < tierValidator then
                curTierData = tierData
                curTier = tier
                break
            end
        end

        local clientID = prewarmClient.clientID
        if curTierData then
            ValidateClient(self, clientID, prewarmClient.data,curTier, curTierData.Credit,curTierData.Rank)
            if curTierData.Member and curTierData.Member > 0 then
                local client = Shine.GetClientByNS2ID(clientID)
                if client and not client:GetIsVirtual() then
                    Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3], self.kPrefix, 255, 255, 255,
                            string.format("预热奖励:已获得[%d]天社员资格.", curTierData.Member) )
                    Shine:RunCommand(nil, "sh_member_set", false, clientID, 2, curTierData.Member)
                end
            end
            if curTierData.Inform then
                nameList = nameList .. string.format("%s(%i分)|", prewarmClient.data.name, math.floor(prewarmClient.data.score / 60))
            end
            currentIndex = currentIndex + 1
        end
    end

    -- 保底机制: 有预热分但未进入 Tier 名额的玩家获得 FloorCredit
    local floorCredit = self.Config.FloorCredit or 0
    if floorCredit > 0 then
        local floorCount = 0
        for clientID, prewarmData in pairs(self.MemberInfos) do
            if (prewarmData.tier or 0) <= 0 and (prewarmData.score or 0) > 0 then
                prewarmData.credit = (prewarmData.credit or 0) + floorCredit
                floorCount = floorCount + 1
                local client = Shine.GetClientByNS2ID(clientID)
                if client and not client:GetIsVirtual() then
                    Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3], self.kPrefix, 255, 255, 255,
                            string.format("感谢你的预热贡献,已获得[%d]保底预热点,当前持有[%s]预热点.", floorCredit, prewarmData.credit) )
                end
            end
        end
        if floorCount > 0 then
            Shared.Message(string.format("[CNCP] Floor Guarantee: %d players received %d credits each.", floorCount, floorCredit))
        end
    end

    local informMessage = "已达成,排名靠前的玩家:" .. nameList .. "等,感谢各位做出的积极贡献."
    for client in Shine.IterateClients() do
        Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                255, 255, 255, informMessage)
    end

    return true
end

function Plugin:GetPrewarmPrivilege(_client, _cost, _privilege, _limitCheck)
    if not self.PrewarmData.Validated then return end

    local data = GetPlayerData(self,_client:GetUserId())
    local tier = data.tier or 0
    if _cost == 0 then
        if tier == 0 then return end

        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                255, 255, 255,string.format("当前拥有特权:[%s].", _privilege) )
        return true
    end

    local credit = data.credit or 0
    if credit >= _cost then
        if not _limitCheck then
            data.credit = credit - _cost
            Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                    255, 255, 255,string.format("使用%s[预热点],当前剩余 %s [预热点].\n获得特权:<%s>.", _cost,data.credit,_privilege) )
        else
            Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                    255, 255, 255,string.format("当前拥有[预热点]%s,已达到要求[>=%s].,\n获得特权<%s>.", data.credit,_cost,_privilege) )
        end
        return true
    end

    if credit > 0 then
        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                255, 255, 255,string.format("当前[预热点]%s 不足以获取特权 %s , 需%s.",credit, _privilege,_cost) )
    end
    return false
end

function Plugin:GetPrewarmCredit(_client)
    if not self.PrewarmData.Validated then return 0 end

    local data = GetPlayerData(self,_client:GetUserId())
    return data.credit or 0
end

function Plugin:IsPrewarmPlayer(_clientID)
    local data = GetPlayerData(self, _clientID)
    return data.tier and data.tier > 0
end

function Plugin:ShouldBypassTeamSizeRestriction()
    return not self.PrewarmData.Validated and PrewarmdScoreEnable(self)
end

function Plugin:IsLateGameSeeder(_clientID)
    local targetData = GetPlayerData(self,_clientID)
    if self.PrewarmAwardFile[tostring(_clientID)] then
        return true
    end
    return targetData.isLateGameSeeder
end

function Plugin:OnFirstThink()
    ReadPersistent(self)
    Shine.Hook.SetupClassHook("NS2Gamerules", "EndGame", "OnEndGame", "PassivePost")
    if self.PrewarmData.ValidationDay ~= kCurrentDay then
        Reset(self)
    end

    self:TrackWithInterval()
end

local function BroadcastPrewarmStatus(self)
    if self.PrewarmData.Validated then return end
    if not PrewarmdScoreEnable(self) then return end

    local prewarmClients = {}
    for clientID, prewarmData in pairs(self.MemberInfos) do
        table.insert(prewarmClients, { clientID = clientID, data = prewarmData })
    end

    if #prewarmClients == 0 then return end

    table.sort(prewarmClients, function(a, b) return a.data.score > b.data.score end)

    local totalTierSlots = 0
    for _, tierData in ipairs(self.Config.Tier) do
        totalTierSlots = totalTierSlots + tierData.Count
    end

    local lastTierScore = 0
    if totalTierSlots <= #prewarmClients then
        lastTierScore = prewarmClients[totalTierSlots].data.score
    elseif #prewarmClients > 0 then
        lastTierScore = prewarmClients[#prewarmClients].data.score
    end

    local nameList = ""
    local showCount = math.min(5, #prewarmClients)
    for i = 1, showCount do
        local p = prewarmClients[i]
        nameList = nameList .. string.format("%s(%d分) ", p.data.name, math.floor(p.data.score / 60))
    end

    local message = string.format("预热排名: %s| 末位入位需[%d]分",
            nameList,
            math.floor(lastTierScore / 60))

    for client in Shine.IterateClients() do
        Shine:NotifyDualColour(client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3], self.kPrefix,
                255, 255, 255, message)
    end
end

function Plugin:TrackWithInterval()
    TrackAllClients(self)
    self:SimpleTimer(60, function() self:TrackWithInterval() end)
end

function Plugin:SetGameState( Gamerules, State, OldState )
    if State == kGameState.Countdown and PrewarmdScoreEnable(self) and not self.PrewarmData.Validated then
        local result = PrewarmValidate(self)
        if not result then
            local playingCount = Shine.GetPlayingPlayersCount()
            local required = self.Config.Restriction.Player
            for client in Shine.IterateClients() do
                Shine:NotifyDualColour( client, kErrorColor[1], kErrorColor[2], kErrorColor[3], self.kPrefix,
                        255, 255, 255,
                        string.format("预热校验未通过:当前场内人数[%d/%d],尚缺%d人.", playingCount, required, required - playingCount) )
            end
        end

        BroadcastPrewarmStatus(self)
    end
end

function Plugin:OnEndGame(_winningTeam)
    if not self.PrewarmData.Validated then return end

    local lastRoundData = CHUDGetLastRoundStats()
    if Shine.IsActiveRound(lastRoundData) then
        self:DispatchEndGameCredit(lastRoundData)
    end

    if self:IsActiveLateGameRound(lastRoundData) then
        self:DispatchLateGameAward(lastRoundData)
    end
end

function Plugin:DispatchEndGameCredit(lastRoundData)
    local gameLengthInMinute = lastRoundData.RoundInfo.roundLength / 60
    local totalReward = math.floor(self.Config.EndGameReward.BaseCredit  )
    local minuteBonus = math.floor(gameLengthInMinute / self.Config.EndGameReward.MinuteEachCredit)
    totalReward = totalReward + minuteBonus
    local nonTeamPlayerCount = 0
    for Client, _ in Shine.IterateClients() do
        local Player = Client.GetControllingPlayer and Client:GetControllingPlayer()
        local team = Player:GetTeamNumber()
        if team == kTeamReadyRoom or team == kSpectatorIndex then
            local data = GetPlayerData(self, Client:GetUserId())
            if not data.tier or data.tier <= 0 then
                nonTeamPlayerCount = nonTeamPlayerCount + 1
            end
        end
    end
    if nonTeamPlayerCount <= 0 then
        Shared.Message("[CNCP] End Game Reward: No eligible non-team players, skipping spectator reward.")
    else
        local rewardPerPlayer = math.floor(totalReward * 10 / nonTeamPlayerCount) * 0.1
        rewardPerPlayer = Clamp(rewardPerPlayer,self.Config.EndGameReward.MinCredit,self.Config.EndGameReward.MaxCredit)
        Shared.Message(string.format("[CNCP] End Game Reward: T %s(+%s) | C: %s | Each %s" , totalReward,minuteBonus, nonTeamPlayerCount,rewardPerPlayer))
        for Client, _ in Shine.IterateClients() do
            local Player = Client.GetControllingPlayer and Client:GetControllingPlayer()
            local team = Player:GetTeamNumber()
            local clientID = Client:GetUserId()
            if team == kTeamReadyRoom or team == kSpectatorIndex then
                local data = GetPlayerData(self,clientID)
                if not (data.tier and data.tier > 0) then
                    data.credit = (data.credit or 0) + rewardPerPlayer
                    Shine:NotifyDualColour( Client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                            string.format("对局结束,非局内玩家已获得%s[预热点]用于获取当日特权,您当前拥有%s[预热点].",rewardPerPlayer,data.credit) )
                end
            end
        end
    end

    local commanderCredit = self.Config.EndGameReward.CommanderCredit
    local commanderMinSeconds = (self.Config.EndGameReward.CommanderMinMinute or 5) * 60
    if commanderCredit and commanderCredit ~= 0 then
        local topCommSteamId = { [kTeam1Index] = nil, [kTeam2Index] = nil }
        local topCommTime   = { [kTeam1Index] = 0,   [kTeam2Index] = 0   }

        for steamId, playerStat in pairs(lastRoundData.PlayerStats) do
            for _, teamIdx in ipairs({ kTeam1Index, kTeam2Index }) do
                local teamEntry = playerStat[teamIdx]
                if teamEntry and teamEntry.commanderTime and teamEntry.commanderTime > topCommTime[teamIdx] then
                    topCommTime[teamIdx]   = teamEntry.commanderTime
                    topCommSteamId[teamIdx] = steamId
                end
            end
        end

        for _, teamIdx in ipairs({ kTeam1Index, kTeam2Index }) do
            local steamId = topCommSteamId[teamIdx]
            if steamId and topCommTime[teamIdx] > commanderMinSeconds then
                local client = Shine.GetClientByNS2ID(steamId)
                if client and not client:GetIsVirtual() then
                    local data = GetPlayerData(self, steamId)
                    if not data.tier or data.tier <= 0 then
                        data.credit = (data.credit or 0) + commanderCredit
                        local player = client:GetControllingPlayer()
                        player:SetPrewarmData(data)
                        Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3], self.kPrefix, 255, 255, 255,
                                string.format("感谢你本局担任指挥,已获得%s[预热点],当前拥有%s[预热点].", commanderCredit, data.credit) )
                        Shared.Message(string.format("[CNCP] Commander Reward: ID:%s Team:%s CommTime:%s Credit:+%s", steamId, teamIdx, topCommTime[teamIdx], commanderCredit))
                    end
                end
            end
        end
    end
end

function Plugin:IsActiveLateGameRound(_lastRoundData)
    if not _lastRoundData.RoundInfo then return false end
    local playerCount = table.countkeys(_lastRoundData.PlayerStats)
    local minimumLength = 300 + math.max(12 - playerCount,0) * 60
    if _lastRoundData.RoundInfo.roundLength < minimumLength then
        return false
    end
    return true
end

function Plugin:DispatchLateGameAward(_lastRoundData)
    if kCurrentHour < self.Config.LateGameAward.Hour then return end
    local playerCount = table.Count(_lastRoundData.PlayerStats)
    if playerCount >= self.Config.LateGameAward.MaxPlayers then return end

    local lateGameClients = {}
    for steamId , playerStat in pairs(_lastRoundData.PlayerStats) do
        local t1 = playerStat[kTeam1Index]
        local t2 = playerStat[kTeam2Index]
        local playTime = (t1 and t1.timePlayed or 0) + (t2 and t2.timePlayed or 0)
        table.insert(lateGameClients, { steamId = steamId, playTime = playTime})
    end
    
    local function LateGameCompare(a, b) return a.playTime > b.playTime end
    table.sort(lateGameClients, LateGameCompare)

    for _,data in pairs(lateGameClients) do
        local steamId = data.steamId

        local client = Shine.GetClientByNS2ID(steamId)
        if client then
            local playtimeNormalized = data.playTime / _lastRoundData.RoundInfo.roundLength
            local successful = playtimeNormalized >= self.Config.LateGameAward.ActiveDurationNormalized
            if successful then
                local steamIdString = tostring(steamId)
                local lateGameAwardData = self.PrewarmAwardFile[steamIdString]
                if not lateGameAwardData then
                    lateGameAwardData = { credit = 0, time = kCurrentTimeStampDay }
                    self.PrewarmAwardFile[steamIdString] = lateGameAwardData
                end
                lateGameAwardData.credit = lateGameAwardData.credit + self.Config.LateGameAward.Credit
                Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                        string.format("尾声对局已结束,明日预热结束后您将获得额外[%d(+%d)]预热点.", lateGameAwardData.credit,self.Config.LateGameAward.Credit))
            else
                Shine:NotifyDualColour( client, kErrorColor[1], kErrorColor[2], kErrorColor[3],self.kPrefix,255, 255, 255, 
                        "尾声对局已结束,由于您的对局时长不足,暂未获得尾声对局特权,请于下局保持活跃.")
            end

            Shared.Message(string.format("[CNCP] Late Game Reward: %d %d %s" ,steamId,playtimeNormalized,successful and "Valid" or "Failure"))
        end
    end
end

function Plugin:QueryGroupAward(_client)
    local id = _client:GetUserId()
    local userData = Shine:GetUserData(id)
    local groupName = userData and userData.Group or nil
    local groupData = groupName and Shine:GetGroupData(groupName) or nil
    local prewarmData = GetPlayerData(self,id)
    if prewarmData.groupDailyQueried then return end
    prewarmData.groupDailyQueried = true
    if groupData and groupData.PrewarmCredit then
        Shared.ConsoleCommand(string.format("sh_prewarm_delta %s %s %s", id, groupData.PrewarmCredit,"社区段位激励"))
    end
end

function Plugin:QueryLateGameAward(_client)
    local id = _client:GetUserId()
    if kCurrentHour > self.Config.LateGameAward.Hour then
        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                string.format("当前处于尾声对局激励.当参与人数小于[%d]的有效战局结束后,完整参与对局的所有玩家将获得次日的[%d]预热点.", self.Config.LateGameAward.MaxPlayers,self.Config.LateGameAward.Credit) )
    end

    local stringId = tostring(id)
    local lateGameAwardData = self.PrewarmAwardFile[stringId]
    if not lateGameAwardData or 
            lateGameAwardData.time == kCurrentTimeStampDay then
        return
    end
    Shared.ConsoleCommand(string.format("sh_prewarm_delta %s %s %s",id, lateGameAwardData.credit,"尾声对局参与激励"))
    self.PrewarmAwardFile[stringId] = nil
    local targetData = GetPlayerData(self,id)
    targetData.isLateGameSeeder = true
end

function Plugin:MapChange()
    TrackAllClients(self)
    SavePersistent(self)
end

function Plugin:ClientConnect(_client)
    local clientID = _client:GetUserId()
    if clientID <= 0 then return end
    TrackClient(self,_client,clientID)
end

function Plugin:ClientDisconnect( _client )
    local clientID = _client:GetUserId()
    if clientID <= 0 then return end

    TrackClient(self,_client,clientID)
end

function Plugin:ClientConfirmConnect( _client )
    local clientID = _client:GetUserId()
    if clientID <= 0 then return end

    local data = GetPlayerData(self,clientID)
    local player = _client:GetControllingPlayer()
    data.name = player:GetName()

    if PrewarmdScoreEnable(self) then
        if self.PrewarmData.Validated then
            NotifyClient(self,_client,_client:GetUserId())
            self:QueryLateGameAward(_client)
            self:QueryGroupAward(_client)
        else
            local playerCount = Shine.GetHumanPlayerCount()
            local rank, total = GetPlayerRank(self, clientID)
            local scoreMinutes = math.floor((data.score or 0) / 60)
            local required = self.Config.Restriction.Player
            Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                    string.format("服务器为预热状态(在线%d人/需%d人). 你的预热分:%d分钟,排名:%d/%d.",
                            playerCount, required, scoreMinutes, rank, total) )
            -- 初始化通知基准,避免连接瞬间触发累积通知
            local tracker = self.PrewarmTracker[clientID]
            if tracker then
                tracker.lastNotifyScore = data.score or 0
                tracker.lastNotifyRank = rank
            end
        end
        return
    end
end

function Plugin:OnPlayerCommunityDataReceived(_client, data)
    if not self.Config.ReturnReward.Enabled then return end

    local clientID = _client:GetUserId()
    if clientID <= 0 then return end

    local targetData = GetPlayerData(self,clientID)
    if targetData.credit > 0 then return end

    local credit = 0
    local title = nil
    local isReturning = false
    if not data.lastSeenTimeStamp then
        credit = self.Config.ReturnReward.CreditFirstJoin
        title = "首次加入社区"
    else
        local secOffset = kCurrentTimeStamp - data.lastSeenTimeStamp
        local dayOffset = math.floor(secOffset / 86400)
        if dayOffset >= self.Config.ReturnReward.DayOffset then
            credit = self.Config.ReturnReward.CreditReturn
            title = "回归玩家激励"
            isReturning = true
        end
    end

    if credit > 0 then
        targetData.tier = 5
        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                string.format("%s,今天可自由入场,欢迎加入NS2CN!", title) )
        if isReturning then
            Shine:RunCommand(nil, "sh_member_set", false, clientID, 2, 3)
        end
    end
end

function Plugin:CreateMessageCommands()
    self:BindCommand( "sh_prewarm_status", "prewarm_status", function(_client)
        if not NotifyClient(self,_client,_client:GetUserId()) then
            local data = self.MemberInfos[_client:GetUserId()]
            local score = data and data.score or 0
            Shine:NotifyError(_client,string.format("暂未获得预热点,当前预热分:%d.",math.floor(score / 60)))
        end
    end,true )
        :Help( "显示你的预热状态.")

    self:BindCommand( "sh_prewarm_check", "prewarm_check", function(_client,_targetId)
        if not NotifyClient(self,_client,_targetId) then
            local data = self.MemberInfos[_targetId]
            local score = data and data.score or 0
            Shine:NotifyError(_client,string.format("该玩家暂未获得预热点,当前预热分:%d.",math.floor(score / 60)))
        end
    end )       
        :AddParam{ Type = "steamid" }

    self:BindCommand("sh_prewarm_delta","prewarm_delta",function(_client, _id, _credit, _reason)
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then
            Shine:NotifyError(_client,"未找到该玩家,请确认SteamID是否正确或玩家是否在线.")
            return
        end
        
        local targetId = target:GetUserId()
        local targetData = GetPlayerData(self,targetId)
        if targetData.credit > 256 then
            Shine:NotifyError(target,"你的预热点已达上限(256),无法再获得更多的预热点.")
            return
        end
        
        targetData.credit = targetData.credit + _credit
        local colorTable = _credit > 0 and kPrewarmColor or kErrorColor
        Shine:NotifyDualColour(target, colorTable[1], colorTable[2], colorTable[3],self.kPrefix,255, 255, 255,
                string.format("因<%s>获得[%s]预热点,现有[%s]预热点.",_reason,_credit,targetData.credit) )
        if _client then
            Shine:NotifyDualColour( _client, colorTable[1], colorTable[2], colorTable[3],self.kPrefix,255, 255, 255,
                    string.format("<%s>获得[%s]预热点,现有[%s]预热点.", target:GetControllingPlayer():GetName(),_credit,targetData.credit) )
        end
    end)
        :AddParam{ Type = "steamid"}
        :AddParam{ Type = "number", Round = false, Min = -10, Max = 10, Default = 1 }
        :AddParam{ Type = "string",Optional = true, TakeRestOfLine = true, Default = "未知原因" }
        :Help( "激励玩家预热点.")
    
    self:BindCommand("sh_prewarm_give","prewarm_give", function(_client, _target)
        if not _target then
            Shine:NotifyError(_client,"未找到目标玩家,请使用!prewarm_give <玩家名> 格式.")
            return
        end
        if not self.PrewarmData.Validated then
            Shine:NotifyError(_client,"预热尚未结算,请等待当次预热排名完成后使用.")
            return
        end

        local clientData = GetPlayerData(self,_client:GetUserId())
        local selfCredit = clientData.credit or 0
        local tier = clientData.tier or 0
        if tier <= 0 then
            Shine:NotifyError(_client,"仅预热排名靠前的贡献者可使用该指令,活跃参与预热对局即可获取.")
            return
        end

        local value = 1
        if selfCredit < value then
            Shine:NotifyError(_client,string.format("你的预热点不足(当前%s),需要至少%s.",selfCredit,value))
            return
        end

        local targetData = GetPlayerData(self, _target:GetUserId())
        local targetTier = targetData.tier or 0
        if targetTier > 0 then
            Shine:NotifyError(_client,string.format("对方已有预热段位[%d],无需重复给予.",targetTier))
            return
        end

        local inTeamPlayers = Shine.GetPlayingPlayersCount()
        if inTeamPlayers < 20 then
            Shine:NotifyError(_client,string.format("场内人数不足(%d/20),无需给予预热点.",inTeamPlayers))
            return
        end
        targetData.credit = (targetData.credit or 0) + value
        clientData.credit = clientData.credit - value
        local shareReputation = value
        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                string.format("你已给予<%s>%s[预热点](剩余%s),对方目前已有%s预热点.",_target:GetControllingPlayer():GetName(), value, clientData.credit,targetData.credit) )
        Shine:NotifyDualColour( _target, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                string.format("<%s>给予了你%s[预热点],当前剩余%s.",_client:GetControllingPlayer():GetName(), value, targetData.credit) )
        NotifyClient(self, _target, _target:GetUserId())
        NotifyClient(self, _client, _client:GetUserId())

        Shared.ConsoleCommand(string.format("sh_rep_delta %s %s %s",_client:GetUserId(), shareReputation,string.format("分享预热点(+%d)",shareReputation)))
    end,true):AddParam{ Type = "client", NotSelf = true }
            :Help("将你的预热点分予其他玩家,例如: !prewarm_give 哈基米")
    
    self:BindCommand( "sh_prewarm_validate", "prewarm_validate", function(_client,_targetID,_tier,_credit)
        ValidateClient(self,_targetID,nil,_tier,_credit)
        local target = Shine.GetClientByNS2ID(_targetID)
        local onlineHint = target and "已通知玩家" or "玩家不在线,下次上线时生效"
        Shine:NotifyError(_client,string.format("已设置玩家[%s]段位[%d]预热点[%d].(%s)",_targetID,_tier,_credit,onlineHint))
    end )
        :AddParam{ Type = "steamid" }
        :AddParam{ Type = "number", Round = true, Min = 1, Max = 5, Default = 4 }
        :AddParam{ Type = "number", Round = true, Min = 0, Max = 15, Default = 3 }
        :Help( "设置玩家的预热状态以及预热点数,例如设置55022511段位4,3点预热点 !prewarm_validate 55022511 4 3")

    self:BindCommand( "sh_prewarm_cancel", "prewarm_cancel", function(_client,_targetID)
        ValidateClient(self,_targetID,nil,0,0,0)
        local target = Shine.GetClientByNS2ID(_targetID)
        local onlineHint = target and "已通知玩家" or "玩家不在线,下次上线时生效"
        Shine:NotifyError(_client,string.format("已取消玩家[%s]的预热资格.(%s)",_targetID,onlineHint))
    end )
        :AddParam{ Type = "steamid" }
        :Help( "取消玩家的预热点数(例如使用了连点器/作弊).")

    self:BindCommand( "sh_prewarm_track", "prewarm_track", function(_client)
        TrackAllClients(self)
        Shine:NotifyError(_client,"预热数据已手动录入完成.")
    end ):Help( "录入数据(debug)")
    self:BindCommand( "sh_prewarm_reset", "prewarm_reset", function(_client)
        Reset(self)
        SavePersistent(self)
        Shine:NotifyError(_client,"已重置服务器预热状态与数据.")
    end ):Help( "重置服务器的预热状态与数据.")

end

function Plugin:IsPrewarming()
    return not self.PrewarmData.Validated
end

return Plugin