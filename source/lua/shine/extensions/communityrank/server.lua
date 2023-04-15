local Plugin = ...

Plugin.Version = "1.0"
Plugin.PrintName = "communityrank"
Plugin.HasConfig = true
Plugin.ConfigName = "CommunityRank.json"
Plugin.DefaultConfig = {
    Prewarm =
    {
        Check = false,
        ValidationDay = 0,
        Restriction = {
            Hour = 4,           --Greater than this hour
            Player = 12,
        },
        ["Tier"] = {
            [1] = { Count = 2, Credit = 15 },
            [2] = { Count = 3, Credit = 10 },
            [3] = { Count = 10, Credit = 5 },
            [4] = { Count = 99, Credit = 1 },
        },
    },
    Elo = {
        Check = false,
        Restriction = {
            Time = 300,
            Player = 16,
        },
        ["Constants"] = {
            Default = 20,
            Tier =
            {
                [0] = 80,
                [1] = 65,
                [2] = 50,
                [3] = 40,
                [4] = 30,
                [5] = 20,
                [6] = 15,
                [7] = 10,
            },
        },
    },
    ["UserData"] = {
        ["55022511"] = {
            rank = -2000,
            fakeBot = true,
            emblem = 0,
            prewarmDay = 0,
            prewarmCredit = 5,
            prewarmTier = 0,
            prewarmTime = 0,
        }
    },
}

Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true
do
    local Validator = Shine.Validator()
    Validator:AddFieldRule( "UserData",  Validator.IsType( "table", Plugin.DefaultConfig.UserData ))
    Validator:AddFieldRule( "Elo.Check",  Validator.IsType( "boolean", Plugin.DefaultConfig.Elo.Check ))
    Validator:AddFieldRule( "Elo.Restriction.Time",  Validator.IsType( "number", Plugin.DefaultConfig.Elo.Restriction.Time ))
    Validator:AddFieldRule( "Elo.Restriction.Player",  Validator.IsType( "number", Plugin.DefaultConfig.Elo.Restriction.Player ))
    Validator:AddFieldRule( "Elo.Constants.Tier",  Validator.IsType( "table", Plugin.DefaultConfig.Elo.Constants.Tier))
    Validator:AddFieldRule( "Elo.Constants.Default",  Validator.IsType( "number", Plugin.DefaultConfig.Elo.Constants.Default))
    Validator:AddFieldRule( "Prewarm.ValidationDay",  Validator.IsType( "number", Plugin.DefaultConfig.Prewarm.ValidationDay ))
    Validator:AddFieldRule( "Prewarm.Restriction.Hour",  Validator.IsType( "number", Plugin.DefaultConfig.Prewarm.Restriction.Hour ))
    Validator:AddFieldRule( "Prewarm.Restriction.Player",  Validator.IsType( "number", Plugin.DefaultConfig.Prewarm.Restriction.Player ))
    Validator:AddFieldRule( "Prewarm.Tier",  Validator.IsType( "table", Plugin.DefaultConfig.Prewarm.Tier  ))
    Plugin.ConfigValidator = Validator
end
function Plugin:Initialise()
    self.MemberInfos = { }
    self.PrewarmTracker = { }
    self:CreateMessageCommands()
	return true
end

local function ReadPersistent(self)
    -- Shared.Message("[CNCR] Read Persistent:")
    for k,v in pairs(self.Config.UserData) do
        -- Shared.Message(k .. ":" .. tostring(v))
        self.MemberInfos[tonumber(k)] = v
    end
end

local function SavePersistent(self)
    -- Shared.Message("[CNCR] Save Persistent:")
    for k,v in pairs(self.MemberInfos) do
        self.Config.UserData[tostring(k)] = v
    end
    self:SaveConfig()
end

local function GetPlayerData(self,steamId)
    if not self.MemberInfos[steamId] then
        self.MemberInfos[steamId] = { }
    end
    
    return self.MemberInfos[steamId]
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

----Elo
local function RankPlayerDelta(self,_steamId,_delta)
    local data = GetPlayerData(self,_steamId)
    local rank = data.rank or 0
    rank = rank + _delta
    data.rank = rank
    
    local target = Shine.GetClientByNS2ID(_steamId)
    if target then 
        local player = target:GetControllingPlayer()
        data.rank = math.max(rank, -player.skill)
        player:SetPlayerExtraData(data)
    end
end

local eloEnable = { "ns2","NS2.0","NS1.0","siege+++"  }
local function EndGameElo(self)
    local gameMode = Shine.GetGamemode()
    if not table.contains(eloEnable,gameMode) then return end

    if not self.Config.Elo.Check then return end

    local lastRoundData = CHUDGetLastRoundStats();
    if not lastRoundData then
        Shared.Message("[CNCR] ERROR Option 'savestats' not enabled ")
        return
    end

    local winningTeam = lastRoundData.RoundInfo.winningTeam
    local gameLength = lastRoundData.RoundInfo.roundLength
    local team1AverageSkill = 0
    local team2AverageSkill = 0

    local team1Table = {}
    local team2Table = {}
    local function PopTeamEntry(_teamTable,_steamId,_teamEntry,_playerSkill)
        if not _teamEntry.timePlayed or _teamEntry.timePlayed <=0 then
            return 0
        end
        local playTimeNormalized = _teamEntry.timePlayed / gameLength
        table.insert(_teamTable, {steamId = _steamId,playTimeNormalized = playTimeNormalized ,score = _teamEntry.score,hiveSkill = _playerSkill })
        return  _playerSkill * playTimeNormalized
        -- Shared.Message(string.format("%i %i %i",_steamId,_teamEntry.timePlayed,_teamEntry.score))
    end

    local playerCount = 0
    for steamId , playerStat in pairs( lastRoundData.PlayerStats ) do
        team1AverageSkill = team1AverageSkill + PopTeamEntry(team1Table,steamId,playerStat[1],playerStat.hiveSkill)
        team2AverageSkill = team2AverageSkill + PopTeamEntry(team2Table,steamId,playerStat[2],playerStat.hiveSkill)
        playerCount = playerCount + 1
    end

    if gameLength < self.Config.Elo.Restriction.Time or playerCount < self.Config.Elo.Restriction.Player then
        Shared.Message(string.format("[CNCR] End Game Result Restricted"))
        return
    end
    Shared.Message(string.format("[CNCR] End Game Resulting|Mode:%s Length:%i Players:%i WinTeam: %s|", gameMode , gameLength,playerCount , winningTeam))

    local function RankCompare(a,b) return a.score > b.score end
    table.sort(team1Table,RankCompare)
    table.sort(team2Table,RankCompare)

    local function ApplyRankTable(_rankTable, _teamTable, _delta)
        for _,data in ipairs(_teamTable) do
            local steamId = data.steamId

            if not _rankTable[steamId] then
                _rankTable[steamId] = 0
            end

            local tier,_ = GetPlayerSkillTier(data.hiveSkill)

            --its ELO dude
            local eloConstant = self.Config.Elo.Constants.Tier[tier] or self.Config.Elo.Constants.Default
            local Edelta = eloConstant * _delta

            _rankTable[steamId] = _rankTable[steamId] + math.floor(Edelta * data.playTimeNormalized)
            --Shared.Message(string.format("ID:%s T%s K:%s ES-EA:%s", steamId,tier,eloConstant,_delta))
        end
    end

    local team1S, team2S
    if winningTeam == kMarineTeamType then
        team1S = 1; team2S = 0;
    elseif winningTeam == kAlienTeamType then
        team1S = 0; team2S = 1;
    else
        team1S = .5; team2S = .5;
    end

    local rankTable = {}
    ApplyRankTable(rankTable,team1Table,team1S - 1.0 / (1 + math.pow(10,(team2AverageSkill - team1AverageSkill)/400)))
    ApplyRankTable(rankTable,team2Table,team2S - 1.0 / (1 + math.pow(10,(team1AverageSkill - team2AverageSkill)/400)))

    -- Shared.Message("[CNCR] Result")

    for steamId, rankOffset in pairs(rankTable) do
        if rankOffset ~= 0 then
            RankPlayerDelta(self,steamId,rankOffset)
        end
         --Shared.Message(string.format("%i|%d",steamId, rankOffset))
    end

end


---Prewarm
local kPrewarmColor = { 235, 152, 78 }
local tmpDate = os.date("*t", Shared.GetSystemTime())
local kCurrentDay = tmpDate.day
local kCurrentHour = tmpDate.hour

local function PrewarmEnabled(self)
    if not self.Config.Prewarm.Check then return false end
    if kCurrentDay == self.Config.Prewarm.ValidationDay then return false end
    if kCurrentHour < self.Config.Prewarm.Restriction.Hour then return false end
    return true
end

local function PrewarmStatusNotify(self,_client,_data)
    if not _client then return end
    
    local data = _data or GetPlayerData(self,_client:GetUserId())
    Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],"[战局预热]",
            255, 255, 255,string.format("您的预热等级为:[%s].\n可用[预热点]:%s点.今日预热时长[%s分]!",
                    (data.prewarmTier and data.prewarmTier  > 0) and string.format("预热贡献者 - %s",data.prewarmTier) or "社区玩家",
                    data.prewarmCredit or 0,
                    math.floor((data.prewarmTime or 0) / 60)
            ) )
end

local function PrewarmTrack(self,client,_clientID)
    local now = Shared.GetTime()
    local data = GetPlayerData(self,_clientID)
    if data.prewarmDay ~= kCurrentDay then
        data.prewarmDay = kCurrentDay
        data.prewarmTime = 0
        data.prewarmTier = 0
        data.prewarmCredit = 0
    end
    
    data.prewarmTime = (data.prewarmTime or 0) + math.floor(now - self.PrewarmTracker[_clientID])
    self.PrewarmTracker[_clientID] = now
    client:GetControllingPlayer():SetPlayerExtraData(data)
end

local function PrewarmTrackConnect(self, _client, _clientID)
    if not PrewarmEnabled(self) then --return end
        
        if not self.Config.Prewarm.Check then return end
        local data = GetPlayerData(self,_client:GetUserId())
        if data.prewarmTier and data.prewarmTier > 0 then
            PrewarmStatusNotify(self,_client,data)
        end
        
        return 
    end
    
    self.PrewarmTracker[_clientID] = Shared.GetTime()
    Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],"[战局预热]",255, 255, 255,
            string.format("服务器为预热状态,预热成功后场[>=%s人]内所有人都将获得激励.",self.Config.Prewarm.Restriction.Player),true, data )
    PrewarmTrack(self,_client,_clientID)
end

local function PrewarmTrackDisconnect(self, _client, _clientID)
    if not PrewarmEnabled(self) then return end
    PrewarmTrack(self,_client,_clientID)
    self.PrewarmTracker[_clientID] = nil
end

local function PrewarmClientsTrack(self)
    if not PrewarmEnabled(self) then return end
    for client in Shine.IterateClients() do
        PrewarmTrack(self,client,client:GetUserId())
    end
end

local function PrewarmNotify(self)
    if not PrewarmEnabled(self) then return end
    for client in Shine.IterateClients() do
        Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],"[战局预热]",
                255, 255, 255,string.format("当前为预热局,当游戏开始/结束时[人数>%s]后,参与预热的玩家将获得当日[预热徽章]以及对应的[预热点].",
                        self.Config.Prewarm.Restriction.Player))
    end
end


local function PrewarmValidate(self)
    if not PrewarmEnabled(self) then return end

    PrewarmClientsTrack(self)
    if Shine.GetHumanPlayerCount() < self.Config.Prewarm.Restriction.Player then return end
    self.Config.Prewarm.ValidationDay = kCurrentDay
    
    local prewarmTable = {}
    
    for client in Shine.IterateClients() do
        local clientID = client:GetUserId()
        local playerData = GetPlayerData(self,clientID)
        table.insert(prewarmTable, { client = client,clientID = clientID, data = playerData or 0})
    end

    local function PrewarmCompare(a, b) return a.data.prewarmTime > b.data.prewarmTime end
    table.sort(prewarmTable, PrewarmCompare)

    local currentIndex = 0
    for _, clientData in ipairs(prewarmTable) do
        local curTier = 0
        local tierInfo = nil
        local tierValidator = 0
        for tier,data in ipairs(self.Config.Prewarm.Tier) do
            tierValidator = tierValidator + data.Count
            if currentIndex < tierValidator then
                tierInfo = data
                curTier = tier
                break
            end
        end
        
        if not tierInfo then break end
        local client = clientData.client
        
        data = clientData.data
        data.prewarmTier = curTier
        data.prewarmCredit = tierInfo.Credit
        client:GetControllingPlayer():SetPlayerExtraData(data)
        Shine:NotifyDualColour( clientData.client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],"[战局预热]",255, 255, 255,
                string.format("预热已达成,您于当日享有[预热徽章%s]并获得了[%s预热点],感谢您的付出!", curTier, tierInfo.Credit) )
        PrewarmStatusNotify(self,client,nil)
        
        currentIndex = currentIndex + 1
    end
    
end

function Plugin:GetPrewarmPrivilege(_client, _cost, _privilege)
    local data = GetPlayerData(self,_client:GetUserId())
    if not data.prewarmTier or data.prewarmTier <= 0 then return end
    
    if _cost == 0 then
        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],"[战局预热]",
                255, 255, 255,string.format("您已使用[预热特权:%s]!", _privilege) )
        return true
    end
    
    if _cost > 0 then
        local credit = data.prewarmCredit or 0
        if credit >= _cost then
            data.prewarmCredit = credit - _cost
            Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],"[战局预热]",
                    255, 255, 255,string.format("消耗[%s预热点]获得[预热特权:%s],剩余[%s预热点]!", _cost,_privilege,data.prewarmCredit) )
            return true
        end
        return false
    else
        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],"[战局预热]",
                255, 255, 255,string.format("您的[预热点]不足!", _privilege) )
        return true
    end
end

-- Triggers
function Plugin:OnFirstThink()
    ReadPersistent(self)
    Shine.Hook.SetupClassHook("NS2Gamerules", "EndGame", "OnEndGame", "PassivePost")
end

function Plugin:SetGameState( Gamerules, State, OldState )
    if State == kGameState.Countdown then
        PrewarmValidate(self)
        PrewarmNotify(self)
    end
end

function Plugin:OnEndGame(_winningTeam)
    EndGameElo(self)
    PrewarmValidate(self)
    SavePersistent(self)
end

function Plugin:MapChange()
    if not self.Config.Prewarm.Check then return end
    
    PrewarmClientsTrack(self)
    SavePersistent(self)
end

local function GetUserGroup(Client)
	local userData = Shine:GetUserData(Client)

    local groupName = userData and userData.Group or nil
    local Group = groupName and Shine:GetGroupData(groupName) or Shine:GetDefaultGroup()
    
	return groupName and groupName or "RANK_DEFAULT" , Group
end

function Plugin:ClientConnect( _client )
    local clientID = _client:GetUserId()
    if clientID <= 0 then return end
    PrewarmTrackConnect(self,_client,clientID)
    
    --Jeez wtf
    local groupName,groupData = GetUserGroup(_client)

    local player = _client:GetControllingPlayer()
    player:SetGroup(groupName)
    player:SetPlayerExtraData(GetPlayerData(self,clientID))
    
    Shine.SendNetworkMessage(_client,"Shine_CommunityTier" ,{Tier = groupData.Tier or 0},true)
    --Shared.Message("[CNCR] Client Rank:" .. tostring(clientID))
end

function Plugin:ClientDisconnect( _client )
    local clientID = _client:GetUserId()
    if clientID <= 0 then return end

    PrewarmTrackDisconnect(self,_client,clientID)
end

function Plugin:CreateMessageCommands()
    local setCommand = self:BindCommand( "sh_prewarm", "prewarm", function(_client) PrewarmStatusNotify(self,_client) end,true )
    setCommand:Help( "显示你的[预热点]状态." )

    --Elo
    local function AdminRankPlayer( _client, _id, _rank )
        local target = Shine.GetClientByNS2ID(_id)
        if not target then
            return
        end

        local player = target:GetControllingPlayer()
        local preRank = player.skill

        local rank = _rank - preRank
        local data = GetPlayerData(self,_id)
        data.rank = rank
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end

    local setCommand = self:BindCommand( "sh_rank_set", "rank_set", AdminRankPlayer )
    setCommand:AddParam{ Type = "steamid" }
    setCommand:AddParam{ Type = "number", Round = true, Min = 0, Max = 9999999, Optional = true, Default = 0 }
    setCommand:Help( "设置ID对应玩家的社区段位." )

    local function AdminRankReset( _client, _id )
        local target = Shine.GetClientByNS2ID(_id)
        if not target then
            return
        end

        local data = GetPlayerData(self,_id)
        data.rank = 0
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end

    local resetCommand = self:BindCommand( "sh_rank_reset", "rank_reset", AdminRankReset )
    resetCommand:AddParam{ Type = "steamid" }
    resetCommand:Help( "重置玩家的段位(还原至NS2段位)." )

    local function AdminRankPlayerDelta( _client, _id, _offset )
        local target = Shine.GetClientByNS2ID(_id)
        if not target then
            return
        end

        RankPlayerDelta(self,_id,_offset)
    end
    local deltaCommand = self:BindCommand( "sh_rank_delta", "rank_delta", AdminRankPlayerDelta )
    deltaCommand:AddParam{ Type = "steamid" }
    deltaCommand:AddParam{ Type = "number", Round = true, Min = -5000, Max = 5000, Optional = true, Default = 0 }
    deltaCommand:Help( "增减ID对应玩家的社区段位." )

    --BOT
    local function FakeBotSwitchID(_client,_id)
        local target = Shine.GetClientByNS2ID(_id)
        if not target then
            return
        end

        local data = GetPlayerData(self,target:GetUserId())
        data.fakeBot = not data.fakeBot
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end
    local botCommand = self:BindCommand( "sh_fakebot_set", "fakebot_set", FakeBotSwitchID )
    botCommand:AddParam{ Type = "steamid" }
    botCommand:Help( "切换目标玩家的假BOT设置." )

    local function FakeBotSwitch(_client)
        FakeBotSwitchID(_client,_client:GetUserId())
    end

    local botSwitchCommand = self:BindCommand( "sh_fakebot", "fakebot", FakeBotSwitch )
    botSwitchCommand:Help( "假扮成BOT." )

    --Emblem
    local function EmblemSetID(_client, _id, _emblem)
        local target = Shine.GetClientByNS2ID(_id)
        if not target then return  end

        local data = GetPlayerData(self,target:GetUserId())
        data.emblem = _emblem
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end
    local function EmblemSet(_client, _emblem)
        EmblemSetID(_client,_client:GetUserId(),_emblem)
    end

    local function DynamicEmblemSet(_client, _emblem)
        EmblemSetID(_client,_client:GetUserId(),-_emblem)
    end

    local emblemSetCommand = self:BindCommand( "sh_emblem_set", "emblem_set", EmblemSetID)
    emblemSetCommand:AddParam{ Type = "steamid" }
    emblemSetCommand:AddParam{ Type = "number", Round = true, Min = -20, Max = 20, Optional = true, Default = 0 }
    emblemSetCommand:Help( "切换目标玩家的计分板底图(0为默认,正数为静态,负数为动态)." )

    local emblemCommand = self:BindCommand( "sh_emblem", "emblem", EmblemSet)
    emblemCommand:AddParam{ Type = "number", Round = true, Min = 0, Max = 20, Optional = true, Default = 0 }
    emblemCommand:Help( "切换自己的计分板底图(0为使用默认)." )

    local dynamicEmblemCommand = self:BindCommand( "sh_emblem_dynamic", "emblem_dynamic", DynamicEmblemSet)
    dynamicEmblemCommand:AddParam{ Type = "number", Round = true, Min = 0, Max = 20, Optional = true, Default = 0 }
    dynamicEmblemCommand:Help( "切换自己的动态计分板底图(0为使用默认)." )
end
