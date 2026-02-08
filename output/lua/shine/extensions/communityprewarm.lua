
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
    },
    ["Tier"] = {
        [1] = { Count = 1, Credit = 15,Inform = true, },
        [2] = { Count = 2, Credit = 8,Inform = true },
        [3] = { Count = 5, Credit = 5 },
        [4] = { Count = 9, Credit = 3 },
    },
    TierlessReward = {
        BaseCredit = 0.4,
        MinCredit = 0.1,
        CreditPerScore = 0.0005 -- 1.8 per 3600 score
    },
    LateGameAward = {
        Hour = 22.5,
        Credit = 1,
        RewardPlayers = 20,
        MaxPlayers = 32,
    },
    ReturnReward = {
        Enabled = false,
        CreditFirstJoin = 4,
        DayOffset = 10,
        CreditReturn = 10,
    }
}

Plugin.kPrefix = "[战局预热]"
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true
do
    local Validator = Shine.Validator()
    Validator:AddFieldRule( "EndGameReward",  Validator.IsType( "table", Plugin.DefaultConfig.EndGameReward ))
    Validator:AddFieldRule( "EndGameReward.MaxCredit",  Validator.IsType( "number", Plugin.DefaultConfig.EndGameReward.MaxCredit ))
    Validator:AddFieldRule( "TierlessReward",  Validator.IsType( "table", Plugin.DefaultConfig.TierlessReward ))
    Validator:AddFieldRule( "TierlessReward.BaseCredit",  Validator.IsType( "number", Plugin.DefaultConfig.TierlessReward.BaseCredit ))
    Validator:AddFieldRule( "ScoreMultiplier",  Validator.IsType( "table", Plugin.DefaultConfig.ScoreMultiplier ))
    Validator:AddFieldRule( "ScoreMultiplier.RestrictedActive",  Validator.IsType( "number", Plugin.DefaultConfig.ScoreMultiplier.RestrictedActive ))
    Validator:AddFieldRule( "ScoreMultiplier.Dead",  Validator.IsType( "number", Plugin.DefaultConfig.ScoreMultiplier.Dead ))
    Validator:AddFieldRule( "Restriction.Hour",  Validator.IsType( "number", Plugin.DefaultConfig.Restriction.Hour ))
    Validator:AddFieldRule( "Restriction.Player",  Validator.IsType( "number", Plugin.DefaultConfig.Restriction.Player ))
    Validator:AddFieldRule( "Tier",  Validator.IsType( "table", Plugin.DefaultConfig.Tier))
    Validator:AddFieldRule( "ReturnReward", Validator.IsType("table",Plugin.DefaultConfig.ReturnReward))
    Validator:AddFieldRule( "LateGameAward",  Validator.IsType( "table", Plugin.DefaultConfig.LateGameAward))
    Validator:AddFieldRule( "LateGameAward.RewardPlayers",  Validator.IsType( "number", Plugin.DefaultConfig.LateGameAward.RewardPlayers))
    Plugin.ConfigValidator = Validator
end

local kPrewarmColor = { 235, 152, 78 }
local kErrorColor = { 236, 112, 99 }

local kPrewarmFile = "config://shine/temp/prewarm.json"
local kPrewarmAward = "config://shine/temp/prewarmLastDay.json"
local kPrewarmRecord = "config://shine/temp/prewarmRecord.json"

function Plugin:Initialise()
    self.PrewarmTracker = {}
    self.MemberInfos = { }
    self:CreateMessageCommands()

    self.PrewarmData = Shine.LoadJSONFile(kPrewarmFile) or {
        ValidationDay = 0,
        Validated = false,
        UserData = {
            ["55022511"] = {tier = 0 ,score = 0, time = 100 , credit = 0 , name = "StriteR."}
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
        self.MemberInfos[_clientID] = {name = "",score = 0, time = 0, tier = 0 ,  credit = 0 }
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
                        data.tier > 0 and ",亦可以可以使用!prewarm_give指令将预热点给予他人." or ".") )
        return true
    end

    return false
end

-- Track Clients Prewarm Time
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
                Shine:NotifyDualColour( _client, 255, 0,0,
                        self.kPrefix, 255, 255, 255,
                        string.format("当已满足预热人数条件,非对局内玩家的预热分加权为(%d)),请尽快加入战局!",trackTimeMultiplier))
            end
        end
        
        --Shared.Message(gameMode .. " " .. tostring(activePlayed))
        prewarmData.score = math.max(0, prewarmData.score + trackTimeMultiplier * trackTime)
    end
    
    prewarmData.time = prewarmData.time + trackTime

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
    
    local prewarmClients = {}
    for clientID,prewarmData in pairs(self.MemberInfos) do
        table.insert(prewarmClients, { clientID = clientID, data = prewarmData})
    end

    local function PrewarmCompare(a, b) return a.data.score > b.data.score end
    table.sort(prewarmClients, PrewarmCompare)

    local nameList = ""
    local lastSeenScore = 0
    local currentIndex = 0
    local tierlessReward = self.Config.TierlessReward
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

        local curScore = prewarmClient.data.score
        local clientID = prewarmClient.clientID
        local client = Shine.GetClientByNS2ID(prewarmClient.clientID)
        if curTierData then
            ValidateClient(self, clientID, prewarmClient.data,curTier, curTierData.Credit,curTierData.Rank)
            if curTierData.Inform then
                nameList = nameList .. string.format("%s(%i分)|", prewarmClient.data.name, math.floor(prewarmClient.data.score / 60))
            end

            currentIndex = currentIndex + 1
            lastSeenScore = curScore
        else
            local credit = tierlessReward.BaseCredit + curScore * tierlessReward.CreditPerScore
            credit = math.floor(credit * 10) * 0.1
            if credit >= tierlessReward.MinCredit then
                local data = GetPlayerData(self,clientID)
                data.credit = (data.credit or 0) + credit
                if client then
                    Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                            string.format("预热结束,你的预热分被结算为[%s]预热点.",credit) )
                end
            end

            if client then
                Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                        string.format("今日预热已结算,预热分距最近的排名[%s],还差[%s]预热分,活跃参与预热对局即可获得更多的预热分数!.",math.floor(lastSeenScore/60),math.floor((lastSeenScore - curScore)/60)))
            end
        end

    end

    local informMessage = string.format("已达成,排名靠前的玩家:" .. nameList .. "等,感谢各位做出的积极贡献.",
            self.Config.Restriction.Player)
    for client in Shine.IterateClients() do
        Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                255, 255, 255, informMessage)
    end

    return true
    --SavePersistent(self)
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

function Plugin:IsLateGameSeeder(_clientID)
    local targetData = GetPlayerData(self,_clientID)
    if self.PrewarmAwardFile[tostring(_clientID)] then
        return true
    end
    return targetData.isLateGameSeeder
end

-- Triggers
function Plugin:OnFirstThink()
    ReadPersistent(self)
    Shine.Hook.SetupClassHook("NS2Gamerules", "EndGame", "OnEndGame", "PassivePost")
    if self.PrewarmData.ValidationDay ~= kCurrentDay then
        Reset(self)
        --SavePersistent(self)
    end

    self:TrackWithInterval()
    
end

function Plugin:TrackWithInterval()
    TrackAllClients(self)
    self:SimpleTimer( 60,function() self:TrackWithInterval()  end )
end

function Plugin:SetGameState( Gamerules, State, OldState )
    if State == kGameState.Countdown then
        if PrewarmdScoreEnable(self) and not self.PrewarmData.Validated then
            local prewarmClients = {}
            for clientID,prewarmData in pairs(self.MemberInfos) do
                table.insert(prewarmClients, { clientID = clientID, data = prewarmData})
            end

            local function PrewarmCompare(a, b) return a.data.score > b.data.score end
            table.sort(prewarmClients, PrewarmCompare)
            local nameList = ""
            local index = 0
            for _, prewarmClient in pairs(prewarmClients) do
                nameList = nameList .. string.format("%s(%i分) ", prewarmClient.data.name, math.floor(prewarmClient.data.score / 60))
                index = index + 1
                if index > 10 then       -- Show these guys
                    break
                end
            end

            local message1 = string.format("分数记录中,当正式开局时[人数>%s]后,分数靠前玩家将获得当日[预热徽章]以及对应的[预热点].", self.Config.Restriction.Player)
            local message2 = string.format("当前排名:" .. nameList, self.Config.Restriction.Player)
            for client in Shine.IterateClients() do
                Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                        255, 255, 255,message1)

                Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                        255, 255, 255,message2)
            end
        end
    end
end

function Plugin:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam )
    if self.PrewarmData.Validated then return end
    if not Shine.IsPlayingTeam( NewTeam ) then return end
    PrewarmValidate(self)
end


function Plugin:OnEndGame(_winningTeam)
    --Validate(self)
    
    if not self.PrewarmData.Validated then return end
    
    local lastRoundData = CHUDGetLastRoundStats();
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
    local nonTeamPlayerCount = Shine.GetHumanPlayerCount() - Shine.GetPlayingPlayersCount()

    local rewardPerPlayer = math.floor(totalReward * 10 / nonTeamPlayerCount) * 0.1
    rewardPerPlayer = Clamp(rewardPerPlayer,self.Config.EndGameReward.MinCredit,self.Config.EndGameReward.MaxCredit)
    Shared.Message(string.format("[CNCP] End Game Reward: T %s(+%s) | C: %s | Each %s" , totalReward,minuteBonus, nonTeamPlayerCount,rewardPerPlayer))
    for Client, _ in Shine.IterateClients() do
        local Player = Client.GetControllingPlayer and Client:GetControllingPlayer()
        local team = Player:GetTeamNumber()
        local clientID = Client:GetUserId()
        if team == kTeamReadyRoom or team == kSpectatorIndex then
            local data = GetPlayerData(self,clientID)
            data.credit = (data.credit or 0) + rewardPerPlayer
            Shine:NotifyDualColour( Client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                    string.format("对局结束,非局内玩家已获得%s[预热点]用于获取当日特权,您当前拥有%s[预热点].",rewardPerPlayer,data.credit) )
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
        local playTime = (playerStat[kTeam1Index].timePlayed + playerStat[kTeam2Index].timePlayed) 
        table.insert(lateGameClients, { steamId = steamId, playTime = playTime})
    end
    
    local function LateGameCompare(a, b) return a.playTime > b.playTime end
    table.sort(lateGameClients, LateGameCompare)

    local index = 0
    for _,data in pairs(lateGameClients) do
        local steamId = data.steamId
        local steamIdString = tostring(steamId)
        local lateGameAwardData = self.PrewarmAwardFile[steamIdString]
        if not lateGameAwardData then
            lateGameAwardData = { credit = 0 , time = kCurrentTimeStampDay}
            self.PrewarmAwardFile[steamIdString] = lateGameAwardData
        end
        lateGameAwardData.credit = lateGameAwardData.credit + self.Config.LateGameAward.Credit
        local client = Shine.GetClientByNS2ID(steamId)
        if client then
            Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                    string.format("尾声对局已结束,明日预热结束后您将获得额外[%d(+%d)]预热点.", lateGameAwardData.credit,self.Config.LateGameAward.Credit) )
        end
        Shared.Message(string.format("[CNCP] Late Game Reward: %d" ,steamId))

        index = index + 1
        if index >= self.Config.LateGameAward.RewardPlayers then
            break
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
                string.format("当前处于尾声对局激励.当参与人数小于[%d]的有效战局结束后,对局时长排名前[%s]玩家将获得次日的[%d]预热点.", self.Config.LateGameAward.MaxPlayers,self.Config.LateGameAward.RewardPlayers,self.Config.LateGameAward.Credit) )
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
            Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                    string.format("服务器为预热状态,待预热成功后(开局时场内人数>=%s人),排名靠前的玩家将获得对应的预热激励.",self.Config.Restriction.Player) )
        end
        return
    end
end

function Plugin:OnPlayerCommunityDataReceived(_client,data)
    if not self.Config.ReturnReward.Enabled then return end
    
    local clientID = _client:GetUserId()
    if clientID <= 0 then return end

    local targetData = GetPlayerData(self,clientID)
    if targetData.credit > 0 then return end
    
    local credit = 0
    local title = nil
    if not data.lastSeenTimeStamp then
        credit = self.Config.ReturnReward.CreditFirstJoin
        title = "首次加入社区"
    else
        local secOffset = kCurrentTimeStamp - data.lastSeenTimeStamp
        local dayOffset = math.floor(secOffset / 86400)
        if dayOffset >= self.Config.ReturnReward.DayOffset then
            credit = self.Config.ReturnReward.CreditReturn
            title = "回归玩家激励"
        end
    end

    if credit > 0 then
        targetData.tier = 5
        
        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                string.format("%s,今天可自由入场,欢迎加入NS2CN!",title) )
    end
end

function Plugin:CreateMessageCommands()
    self:BindCommand( "sh_prewarm_status", "prewarm_status", function(_client)
        if not NotifyClient(self,_client,_client:GetUserId()) then
            Shine:NotifyError(_client,"暂未获得预热点.")
        end
    end,true )
        :Help( "显示你的预热状态.")

    self:BindCommand( "sh_prewarm_check", "prewarm_check", function(_client,_targetId)
        if not NotifyClient(self,_client,_targetId) then
            Shine:NotifyError(_client,"暂未获得预热点.")
        end
    end )       
        :AddParam{ Type = "steamid" }

    self:BindCommand("sh_prewarm_delta","prewarm_delta",function(_client, _id, _credit, _reason)
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end
        
        local targetId = target:GetUserId()
        local targetData = GetPlayerData(self,targetId)
        if targetData.credit > 256 then
            Shine:NotifyError(_client,"信誉值已超过上限(256),无法再获得更多的信誉值.")
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
        if not self.PrewarmData.Validated then
            Shine:NotifyError(_client,"预热状态无法使用该指令")
            return
        end

        local clientData = GetPlayerData(self,_client:GetUserId())
        local selfCredit = clientData.credit or 0
        local tier = clientData.tier or 0
        if tier <= 0 then
            Shine:NotifyError(_client,"仅预热贡献者可使用该指令.")
            return
        end

        local value = 1
        if selfCredit < value then
            Shine:NotifyError(_client,"你的预热点不足.")
            return
        end

        local targetData = GetPlayerData(self, _target:GetUserId())
        local targetTier = targetData.tier or 0
        if targetTier > 0 then
            Shine:NotifyError(_client,"对方已有预热段位.")
            return
        end
        
        targetData.credit = (targetData.credit or 0) + value
        clientData.credit = clientData.credit - value
        local shareReputation = value
        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                string.format("你已给予<%s>%s[预热点](剩余%s),对方目前已有%s预热点.",_target:GetControllingPlayer():GetName(), value, clientData.credit,targetData.credit) )
        Shine:NotifyDualColour( _target, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                string.format("<%s>给予了你%s[预热点],当前剩余%s.",_client:GetControllingPlayer():GetName(), value, targetData.credit) )

        if targetData.tier == 0 then
            Shared.ConsoleCommand(string.format("sh_rep_delta %s %s %s",_client:GetUserId(), shareReputation,string.format("分享预热点(+%d)",shareReputation)))
        end
    end,true):AddParam{ Type = "client", NotSelf = true }
            :Help("将你的预热点分予其他玩家,例如:给予玩家<哈基米> 3个预热点 - !prewarm_give 哈基米 3")
    
    self:BindCommand( "sh_prewarm_validate", "prewarm_validate", function(_client,_targetID,_tier,_credit) ValidateClient(self,_targetID,nil,_tier,_credit) end )
        :AddParam{ Type = "steamid" }
        :AddParam{ Type = "number", Round = true, Min = 1, Max = 5, Default = 4 }
        :AddParam{ Type = "number", Round = true, Min = 0, Max = 15, Default = 3 }
        :Help( "设置玩家的预热状态以及预热点数,例如设置55022511段位4,3点预热点 !prewarm_validate 55022511 4 3")

    self:BindCommand( "sh_prewarm_cancel", "prewarm_cancel", function(_client,_targetID) ValidateClient(self,_targetID,nil,0,0,0) end )
        :AddParam{ Type = "steamid" }
        :Help( "取消玩家的预热点数(例如使用了连点器/作弊).")

    self:BindCommand( "sh_prewarm_track", "prewarm_track", function(_client)
        TrackAllClients(self)
    end ):Help( "录入数据(debug)")
    self:BindCommand( "sh_prewarm_reset", "prewarm_reset", function(_client)
        Reset(self)
        SavePersistent(self)
    end ):Help( "重置服务器的预热状态与数据.")

end

function Plugin:IsPrewarming()
    return not self.PrewarmData.Validated
end

return Plugin
