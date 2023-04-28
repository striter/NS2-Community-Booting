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
    },
    ["UserData"] = {
        ["55022511"] = {
            rank = -2000,
            rankComm = -500,
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
local function RankPlayerDelta(self,_steamId,_delta,_commDelta)
    local data = GetPlayerData(self,_steamId)
    data.rank = (data.rank or 0) + _delta
    data.rankComm =  (data.rankComm or 0) + _commDelta
    
    local target = Shine.GetClientByNS2ID(_steamId)
    if target then 
        local player = target:GetControllingPlayer()
        data.rank = math.max(data.rank, -player.skill)
        data.rankComm = math.max(data.rankComm, -player.skill)
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
        local commTimeNormalized = _teamEntry.commanderTime / gameLength
        local playTimeNormalized = _teamEntry.timePlayed / gameLength
        table.insert(_teamTable, {
            steamId = _steamId,
            playerTimeNormalized = playTimeNormalized - commTimeNormalized,
            commTimeNormalized = commTimeNormalized,
            score = _teamEntry.score,
            hiveSkill = _playerSkill
        })
        return _playerSkill * playTimeNormalized
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

    local function ApplyRankTable(_rankTable, _teamTable, _eloMultiplier)
        for _,data in pairs(_teamTable) do
            local steamId = data.steamId

            if not _rankTable[steamId] then
                _rankTable[steamId] = {
                    playerD = 0,
                    commD = 0,
                }
            end

            --its ELO dude
            local tier,_ = GetPlayerSkillTier(data.hiveSkill)
            local tierString = tostring(tier)
            local playerConstant = self.Config.Elo.Constants.Tier[tierString] or self.Config.Elo.Constants.Default
            _rankTable[steamId].playerD = _rankTable[steamId].playerD + math.floor(playerConstant * _eloMultiplier * data.playerTimeNormalized)
            local commConstant = self.Config.Elo.Constants.CommanderTier[tierString] or self.Config.Elo.Constants.Default
            _rankTable[steamId].commD = _rankTable[steamId].commD + math.floor(commConstant * _eloMultiplier * data.commTimeNormalized)
            --Shared.Message(tierString .. " " .. tostring(_eloMultiplier) .. " " .. tostring(commConstant) .." ".. tostring(data.commTimeNormalized))
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
        if rankOffset.playerD ~= 0 or rankOffset.commD ~=0 then
            RankPlayerDelta(self,steamId,rankOffset.playerD,rankOffset.commD)
        end
         --Shared.Message(string.format("%i|%d",steamId, rankOffset))
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
    
    --Jeez wtf
    local groupName,groupData = GetUserGroup(_client)

    local player = _client:GetControllingPlayer()
    player:SetGroup(groupName)
    player:SetPlayerExtraData(GetPlayerData(self,clientID))
    
    Shine.SendNetworkMessage(_client,"Shine_CommunityTier" ,{Tier = groupData.Tier or 0},true)
    --Shared.Message("[CNCR] Client Rank:" .. tostring(clientID))
end

function Plugin:CreateMessageCommands()
    --Elo
    local function AdminRankReset( _client, _id )
        local target = Shine.GetClientByNS2ID(_id)
        if not target then return end

        local data = GetPlayerData(self,_id)
        data.rank = 0
        data.rankComm = 0
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end

    local resetCommand = self:BindCommand( "sh_rank_reset", "rank_reset", AdminRankReset )
    resetCommand:AddParam{ Type = "steamid" }
    resetCommand:Help( "重置玩家的段位(还原至NS2段位)." )

    local function AdminRankPlayer( _client, _id, _rank ,_rankComm)
        local target = Shine.GetClientByNS2ID(_id)
        if not target then return end


        local data = GetPlayerData(self,_id)
        local player = target:GetControllingPlayer()
        data.rank = _rank - player.skill
        data.rankComm = _rankComm - player.commSkill
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end

    local setCommand = self:BindCommand( "sh_rank_set", "rank_set", AdminRankPlayer )
    setCommand:AddParam{ Type = "steamid" }
    setCommand:AddParam{ Type = "number", Round = true, Min = 0, Max = 9999999, Optional = true, Default = 0 }
    setCommand:AddParam{ Type = "number", Round = true, Min = 0, Max = 9999999, Optional = true, Default = 0 }
    setCommand:Help( "设置对应玩家的[社区段位]及[指挥段位].例:!rank_set 55022511 2500 2800" )

    local function AdminRankPlayerDelta( _client, _id, _offset,_commOffset )
        local target = Shine.GetClientByNS2ID(_id)
        if not target then return end

        RankPlayerDelta(self,_id,_offset,_commOffset)
    end
    local deltaCommand = self:BindCommand( "sh_rank_delta", "rank_delta", AdminRankPlayerDelta )
    deltaCommand:AddParam{ Type = "steamid" }
    deltaCommand:AddParam{ Type = "number", Round = true, Min = -5000, Max = 5000, Optional = true, Default = 0 }
    deltaCommand:AddParam{ Type = "number", Round = true, Min = -5000, Max = 5000, Optional = true, Default = 0 }
    deltaCommand:Help( "增减对应玩家的[社区段位]及[指挥段位].例:!rank_delta 55022511 100 -100" )

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
