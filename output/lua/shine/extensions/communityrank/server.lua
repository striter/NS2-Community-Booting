local Plugin = ...

Plugin.Version = "1.0"
Plugin.PrintName = "communityrank"
Plugin.HasConfig = true
Plugin.ConfigName = "CommunityRank.json"
Plugin.DefaultConfig = {
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
            CommanderTier = {
                [0] = 130,
                [1] = 115,
                [2] = 100,
                [3] = 90,
                [4] = 80,
                [5] = 70,
                [6] = 60,
                [7] = 50,
            },
        },
        Debug = false,
    },
    ["UserData"] = {
        ["55022511"] = {
            rank = -2000,
            rankOffset = -200,
            rankComm = -500,
            rankCommOffset = -200,
            fakeBot = true,
            emblem = 0,
        }
    },
}

Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true
do
    local Validator = Shine.Validator()
    Validator:AddFieldRule( "UserData",  Validator.IsType( "table", Plugin.DefaultConfig.UserData ))
    Validator:AddFieldRule( "Elo.Check",  Validator.IsType( "boolean", Plugin.DefaultConfig.Elo.Check ))
    Validator:AddFieldRule( "Elo.Debug",  Validator.IsType( "boolean", Plugin.DefaultConfig.Elo.Debug ))
    Validator:AddFieldRule( "Elo.Restriction.Time",  Validator.IsType( "number", Plugin.DefaultConfig.Elo.Restriction.Time ))
    Validator:AddFieldRule( "Elo.Restriction.Player",  Validator.IsType( "number", Plugin.DefaultConfig.Elo.Restriction.Player ))
    Validator:AddFieldRule( "Elo.Constants.Tier",  Validator.IsType( "table", Plugin.DefaultConfig.Elo.Constants.Tier))
    Validator:AddFieldRule( "Elo.Constants.CommanderTier",  Validator.IsType( "table", Plugin.DefaultConfig.Elo.Constants.CommanderTier))
    Validator:AddFieldRule( "Elo.Constants.Default",  Validator.IsType( "number", Plugin.DefaultConfig.Elo.Constants.Default))
    Plugin.ConfigValidator = Validator
end
function Plugin:Initialise()
    self.MemberInfos = { }
    self:CreateMessageCommands()
	return true
end

local function ReadPersistent(self)
    for k,v in pairs(self.Config.UserData) do
        self.MemberInfos[tonumber(k)] = v
    end
end

local function SavePersistent(self)
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
    ReadPersistent(self)
end

function Plugin:Cleanup()
    table.Empty(self.MemberInfos)
    return self.BaseClass.Cleanup( self )
end

----Elo
local function GetMarineSkill(player) return player.skill - player.skillOffset end
local function GetAlienSkill(player) return player.skill + player.skillOffset end
local function GetMarineCommanderSkill(player) return player.commSkill - player.commSkillOffset end
local function GetAlienCommanderSkill(player) return player.commSkill + player.commSkillOffset end
local abs = math.abs
local min = math.min
local max = math.max
local function sign(value)
    return value>0 and 1 or -1
end

local function EloDebugMessage(self,_string)
    if not self.Config.Elo.Debug then return end
    Shared.Message(_string)
end

local function EloDataSanityCheck(data,player)
    if player then      --Limit it for newcomers?
        if data.rank then data.rank = max(data.rank, -player.skill) end
        if data.rankComm then data.rankComm = max(data.rankComm, - player.commSkill) end
        
        -- How could one have offset greater than his skill?
        --if data.rankOffset then data.rankOffset = sign(data.rankOffset) * min(abs(player.skill),abs(data.rankOffset)) end
        --if data.rankCommOffset then data.rankCommOffset = sign(data.rankCommOffset) * min(abs(player.commSkill),abs(data.rankCommOffset)) end
        player:SetPlayerExtraData(data)
    end
end
local function RankPlayerDelta(self, _steamId, _marineDelta, _alienDelta, _marineCommDelta, _alienCommDelta)
    local data = GetPlayerData(self,_steamId)
    local client = Shine.GetClientByNS2ID(_steamId)
    data.rank = (data.rank or 0) + (_marineDelta + _alienDelta) / 2
    data.rankOffset = (data.rankOffset or 0) + (_alienDelta - _marineDelta) / 2
    data.rankComm = (data.rankComm or 0) + (_marineCommDelta + _alienCommDelta) / 2
    data.rankCommOffset = (data.rankCommOffset or 0) + (_alienCommDelta - _marineCommDelta) / 2
    EloDataSanityCheck(data,client and client:GetControllingPlayer())
end

local eloEnable = { "ns2","NS2.0","NS1.0","Siege+++"  }
local function EndGameElo(self)
    local gameMode = Shine.GetGamemode()
    if not table.contains(eloEnable,gameMode) then return end

    if not self.Config.Elo.Check then return end

    local lastRoundData = CHUDGetLastRoundStats();
    if not lastRoundData then
        EloDebugMessage(self,"[CNCR] ERROR Option 'savestats' not enabled ")
        return
    end

    local winningTeam = lastRoundData.RoundInfo.winningTeam
    local gameLength = lastRoundData.RoundInfo.roundLength

    local team1Table = {}
    local team2Table = {}
    local function PopTeamEntry(_teamTable,_steamId,_teamEntry,_playerSkill)
        if not _teamEntry.timePlayed or _teamEntry.timePlayed <=0 then
            return 0
        end
        local commTimeNormalized = _teamEntry.commanderTime / gameLength
        local playTimeNormalized = _teamEntry.timePlayed / gameLength
        table.insert(_teamTable, {
            steamId = _steamId,
            playerTimeNormalized = playTimeNormalized - commTimeNormalized,
            commTimeNormalized = commTimeNormalized,
            score = _teamEntry.score,
            hiveSkill = _playerSkill
        })
        EloDebugMessage(self,string.format("%i %i %i",_steamId,_teamEntry.timePlayed,_teamEntry.score))
    end

    local playerCount = 0
    for steamId , playerStat in pairs( lastRoundData.PlayerStats ) do
        PopTeamEntry(team1Table,steamId,playerStat[kTeam1Index],playerStat.hiveSkill)
        PopTeamEntry(team2Table,steamId,playerStat[kTeam2Index],playerStat.hiveSkill)
        playerCount = playerCount + 1
    end
    
    if gameLength < self.Config.Elo.Restriction.Time or playerCount < self.Config.Elo.Restriction.Player then
        EloDebugMessage(self,string.format("[CNCR] End Game Result Restricted"))
        return
    end
    EloDebugMessage(self,string.format("[CNCR] End Game Resulting|Mode:%s Length:%i Players:%i WinTeam: %s|", gameMode , gameLength,playerCount , winningTeam))

    local function GetTeamAvgSkill(_teamTable)
        local count = 0
        local sum = 0
        for _,data in pairs(_teamTable) do
            sum = sum + data.hiveSkill * data.playerTimeNormalized + data.commTimeNormalized
            count = count + 1
        end
        return sum / math.max(count,1)
    end
    local team1AverageSkill = GetTeamAvgSkill(team1Table)
    local team2AverageSkill = GetTeamAvgSkill(team2Table)
    
    local function RankCompare(a,b) return a.score > b.score end
    table.sort(team1Table,RankCompare)
    table.sort(team2Table,RankCompare)

    local function ApplyRankTable(_rankTable, _teamTable, _estimate, _team1Param,_team2Param)
        for _,data in pairs(_teamTable) do
            local steamId = data.steamId

            if not _rankTable[steamId] then
                _rankTable[steamId] = {
                    player1 = 0,
                    player2 = 0,
                    comm1 = 0,
                    comm2 = 0,
                }
            end

            --its ELO dude
            local tier,_ = GetPlayerSkillTier(data.hiveSkill)
            local tierString = tostring(tier)
            local playerConstant = self.Config.Elo.Constants.Tier[tierString] or self.Config.Elo.Constants.Default
            local playerDelta = math.floor(playerConstant * _estimate * data.playerTimeNormalized)
            
            local commConstant = self.Config.Elo.Constants.CommanderTier[tierString] or self.Config.Elo.Constants.Default
            local commDelta =  math.floor(commConstant * _estimate * data.commTimeNormalized)

            _rankTable[steamId].player1 = _rankTable[steamId].player1 + playerDelta*_team1Param
            _rankTable[steamId].comm1 = _rankTable[steamId].comm1 + commDelta*_team1Param
            _rankTable[steamId].player2 = _rankTable[steamId].player2 + playerDelta*_team2Param
            _rankTable[steamId].comm2 = _rankTable[steamId].comm2 + commDelta*_team2Param

                EloDebugMessage(self,string.format("ID:%-10s T%-3i (P) T:%f K:%-3i F:%3i", steamId,tierString,data.playerTimeNormalized,playerConstant,playerDelta)
                        ..string.format("  (C) T:%f K:%-3i F:%3i",data.commTimeNormalized,commConstant,commDelta)
                )
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

    local estimateA = 1.0 / (1 + math.pow(10,(team2AverageSkill - team1AverageSkill) / 400))
    
    local rankTable = {}
    ApplyRankTable(rankTable,team1Table,team1S - estimateA,1,0.5)     
    EloDebugMessage(self,"Team1:" .. tostring(team1AverageSkill))
    ApplyRankTable(rankTable,team2Table,team2S - (1-estimateA),0.5,1)     
    EloDebugMessage(self,"Team2:" .. tostring(team2AverageSkill))

    for steamId, rankOffset in pairs(rankTable) do
        if rankOffset.player1 ~= 0 or  rankOffset.player2 ~= 0 or rankOffset.comm1 ~=0 or rankOffset.comm2 ~= 0 then
            RankPlayerDelta(self,steamId,rankOffset.player1,rankOffset.player2,rankOffset.comm1,rankOffset.comm2)   
            EloDebugMessage(self,string.format("(ID:%-10s (P1):%-5i (P2):%-5i (C1):%-5i (C2):%-5i",steamId, rankOffset.player1,rankOffset.player2,rankOffset.comm1,rankOffset.comm2))
        end
    end

end


-- Triggers
function Plugin:OnFirstThink()
    ReadPersistent(self)
    Shine.Hook.SetupClassHook("NS2Gamerules", "EndGame", "OnEndGame", "PassivePost")
end

function Plugin:OnEndGame(_winningTeam)
    EndGameElo(self)
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
    
    local groupName,groupData = GetUserGroup(_client)
    local player = _client:GetControllingPlayer()
    player:SetGroup(groupName)
    Shine.SendNetworkMessage(_client,"Shine_CommunityTier" ,{Tier = groupData.Tier or 0},true)
    player:SetPlayerExtraData(GetPlayerData(self,clientID))
    --Shared.Message("[CNCR] Client Rank:" .. tostring(clientID))
end

-- Last Seen Name Check
function Plugin:PlayerEnter(_client)
    local clientID = _client:GetUserId()
    if clientID <= 0 then return end
    
    local player = _client:GetControllingPlayer()
    local playerData = GetPlayerData(self,clientID)
    playerData.lastSeenDay = playerData.lastSeenDay or -2
    playerData.lastSeenName = playerData.lastSeenName or nil
    
    local playerName = player:GetName()
    
    if playerData.lastSeenName ~= playerName then
        if math.abs(playerData.lastSeenDay - kCurrentDay) > 1 then
            playerData.lastSeenDay = kCurrentDay
            playerData.lastSeenName = playerName
            player:SetPlayerExtraData(playerData)
        end
    end
end

function Plugin:CreateMessageCommands()
    local function CanSelfTargeting(_client,_target)
        local access = _client == nil or Shine:HasAccess(_client,"sh_host") 
        if access then return true end
        if _target == _client then
            Shine:NotifyCommandError( _client, "你不应该对自己使用这个指令" )
            return false
        end
        return true
    end
    
    --Elo
    
    ----Reset
    local function AdminRankResetPlayer(_client, _id )
        local target = Shine.GetClientByNS2ID(_id)
        if not target then return end
        if not CanSelfTargeting(_client,target) then return end
        
        local data = GetPlayerData(self,_id)
        data.rank = 0
        data.rankOffset = 0
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end

    self:BindCommand( "sh_rank_reset_player", "rank_reset_player", AdminRankResetPlayer)
    :AddParam{ Type = "steamid" }
    :Help( "重置玩家的[玩家段位](还原至NS2段位)." )

    local function AdminRankResetCommander(_client, _id )
        local target = Shine.GetClientByNS2ID(_id)
        if not target then return end
        if not CanSelfTargeting(_client,target) then return end

        local data = GetPlayerData(self,_id)
        data.rankComm = 0
        data.rankCommOffset = 0
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end

    self:BindCommand( "sh_rank_reset_comm", "rank_reset_comm", AdminRankResetCommander)
        :AddParam{ Type = "steamid" }
        :Help( "重置玩家的[指挥段位](还原至NS2段位)." )
    
    --Set       (Jezz ....)
    local function AdminRankPlayer( _client, _id, _rankMarine ,_rankAlien)
        local target = Shine.GetClientByNS2ID(_id)
        if not target then return end
        if not CanSelfTargeting(_client,target) then return end
        
        local player = target:GetControllingPlayer()
        local data = GetPlayerData(self,_id)
        _rankMarine = _rankMarine >= 0 and _rankMarine or GetMarineSkill(player)
        _rankAlien = _rankAlien >= 0 and _rankAlien or GetAlienSkill(player)
        data.rank = (_rankMarine + _rankAlien) / 2 - player.skill
        data.rankOffset = (_rankAlien - _rankMarine) / 2 - player.skillOffset
        EloDataSanityCheck(data,player)
    end

    self:BindCommand( "sh_rank_set_player", "rank_set_player", AdminRankPlayer )
    :AddParam{ Type = "steamid" }
    :AddParam{ Type = "number", Round = true, Min = -1, Max = 9999999, Optional = true, Default = -1 }
    :AddParam{ Type = "number", Round = true, Min = -1, Max = 9999999, Optional = true, Default = -1 }
    :Help( "设置对应玩家的[玩家段位].例:!rank_set 55022511 2700 2800 (-1保持原状)" )

    local function AdminRankPlayerCommander( _client, _id, _rankMarine ,_rankAlien)
        local target = Shine.GetClientByNS2ID(_id)
        if not target then return end
        if not CanSelfTargeting(_client,target) then return end

        local player = target:GetControllingPlayer()
        local data = GetPlayerData(self,_id)
        _rankMarine = _rankMarine >= 0 and _rankMarine or GetMarineCommanderSkill(player)
        _rankAlien = _rankAlien >= 0 and _rankAlien or GetAlienCommanderSkill(player)
        data.rankComm = (_rankMarine + _rankAlien) / 2 - player.commSkill
        data.rankCommOffset = (_rankAlien - _rankMarine) / 2 - player.commSkillOffset
        Shared.Message(tostring(data.rankComm) .. " " .. tostring(data.rankCommOffset))
        EloDataSanityCheck(data,player)
        Shared.Message(tostring(data.rankComm) .. " " .. tostring(data.rankCommOffset))
    end

    self:BindCommand( "sh_rank_set_comm", "rank_set_comm", AdminRankPlayerCommander )
        :AddParam{ Type = "steamid" }
        :AddParam{ Type = "number", Round = true, Min = -1, Max = 9999999, Optional = true, Default = -1 }
        :AddParam{ Type = "number", Round = true, Min = -1, Max = 9999999, Optional = true, Default = -1 }
        :Help( "设置对应玩家的[指挥段位].例:!rank_set 55022511 2700 2800 (-1保持原状)" )
    
    --Delta
    local function AdminRankDeltaPlayer(_client, _id, _marineDelta, _alienDelta )
        local target = Shine.GetClientByNS2ID(_id)
        if not target then return end
        if not CanSelfTargeting(_client,target) then return end
        RankPlayerDelta(self,_id,_marineDelta,_alienDelta,0,0)
    end
    self:BindCommand( "sh_rank_delta_player", "rank_delta_player", AdminRankDeltaPlayer)
    :AddParam{ Type = "steamid"}
    :AddParam{ Type = "number", Round = true, Min = -5000, Max = 5000, Optional = true, Default = 0 }
    :AddParam{ Type = "number", Round = true, Min = -5000, Max = 5000, Optional = true, Default = 0 }
    :Help( "增减对应玩家的[玩家段位].例:!rank_delta 55022511 100 -100" )

    local function AdminRankDeltaCommander( _client, _id, _marineDelta,_alienDelta )
        local target = Shine.GetClientByNS2ID(_id)
        if not target then return end
        if not CanSelfTargeting(_client,target) then return end
        RankPlayerDelta(self,_id,0,0,_marineDelta,_alienDelta)
    end
    self:BindCommand( "sh_rank_delta_comm", "rank_delta_comm", AdminRankDeltaCommander )
        :AddParam{ Type = "steamid"}
        :AddParam{ Type = "number", Round = true, Min = -5000, Max = 5000, Optional = true, Default = 0 }
        :AddParam{ Type = "number", Round = true, Min = -5000, Max = 5000, Optional = true, Default = 0 }
        :Help( "增减对应玩家的[指挥段位].例:!rank_delta 55022511 100 -100" )

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
    --Hide Rank
    local function HideRankSwitchID(_client,_id)
        local target = Shine.GetClientByNS2ID(_id)
        if not target then
            return
        end

        local data = GetPlayerData(self,target:GetUserId())
        data.hideRank = not data.hideRank
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end
    
    self:BindCommand( "sh_hiderank_set", "hiderank_set", HideRankSwitchID,true )
        :AddParam{ Type = "steamid" }
        :Help( "目标玩家的社区段位显示." )

    local function HideRankSwitch(_client)
        HideRankSwitchID(_client,_client:GetUserId())
    end
    self:BindCommand( "sh_hiderank", "hiderank", HideRankSwitch)
        :Help( "切换社区段位显示." )
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
