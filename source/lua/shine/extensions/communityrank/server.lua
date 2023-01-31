local Plugin = ...

Plugin.Version = "1.0"
Plugin.PrintName = "communityrank"
Plugin.HasConfig = true
Plugin.ConfigName = "CommunityRank.json"
Plugin.DefaultConfig = {
    ["UserData"] = {
        ["55022511"] = {
            rank = -2000,
            fakeBot = true,
        }
    }
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

do
	local Validator = Shine.Validator()
	Validator:AddFieldRule( "UserData",  Validator.IsType( "table", {} ))
	Plugin.ConfigValidator = Validator
end

function Plugin:Initialise()
    self.PlayerRanks = {}
    self:CreateMessageCommands()
	return true
end

local function ReadPersistent(self)
    -- Shared.Message("[CNCR] Read Persistent:")
    for k,v in pairs(self.Config.UserData) do
        -- Shared.Message(k .. ":" .. tostring(v))
        self.PlayerRanks[tonumber(k)] = v
    end
end

local function SavePersistent(self)
    -- Shared.Message("[CNCR] Save Persistent:")
    for k,v in pairs(self.PlayerRanks) do
        self.Config.UserData[tostring(k)] = v
    end
    self:SaveConfig()
end

local function GetPlayerData(self,steamId)
    if not self.PlayerRanks[steamId] then
        self.PlayerRanks[steamId] = {
            rank = 0,
            fakeBot = false,
        }
    end
    
    return self.PlayerRanks[steamId]
end

local function RankPlayerDelta(self,_steamId,_delta)
    
    local rank = GetPlayerData(self,_steamId).rank + _delta
    
    local target = Shine.GetClientByNS2ID(_steamId)
    if target then 
        local player = target:GetControllingPlayer()
        
        rank = math.max(rank, -player.skill)
        player:SetCommunityRank(rank)
    end
    
    self.PlayerRanks[_steamId].rank = rank
end

function Plugin:OnFirstThink()
    ReadPersistent(self)
    
    function Plugin:OnEndGame(_winningTeam)

        local gameMode = Shine.GetGamemode()
        
        local data = CHUDGetLastRoundStats();
        if not data then
            -- Shared.Message("[CNCR] ERROR Option 'savestats' not enabled ")
            return
        end
        
        local winningTeam = data.RoundInfo.winningTeam
        local gameLength = data.RoundInfo.roundLength

        local team1Table = {}
        local team2Table = {}
        local function PopTeamEntry(_teamTable,_steamId,_teamEntry)
            if not _teamEntry.timePlayed or _teamEntry.timePlayed <=0 then return end 
            table.insert(_teamTable, {steamId = _steamId,gameTime = _teamEntry.timePlayed ,score = _teamEntry.score })
            -- Shared.Message(string.format("%i %i %i",_steamId,_teamEntry.timePlayed,_teamEntry.score))
        end

        local playerCount = 0
        for steamId , playerStat in pairs( data.PlayerStats ) do
            PopTeamEntry(team1Table,steamId,playerStat[1])
            PopTeamEntry(team2Table,steamId,playerStat[2])
            playerCount = playerCount + 1
        end
        
        Shared.Message(string.format("[CNCR] End Game Resulting|Mode:%s Length:%i Players:%i WinTeam: %s|", gameMode , gameLength,playerCount , winningTeam))
        if gameLength < 300 or playerCount < 16 then
            Shared.Message(string.format("[CNCR] End Game Restricted"))
            return
        end

        local function RankCompare(a,b) return a.score > b.score end
        table.sort(team1Table,RankCompare)
        table.sort(team2Table,RankCompare)
        
        local function ApplyRankTable(rankTable,teamTable,rankStart,rankEnd,gameLength)
            local size = #teamTable
            for index,data in ipairs(teamTable) do
                local steamId = data.steamId
                if not rankTable[steamId] then
                    rankTable[steamId] = 0
                end

                local timeParam = data.gameTime / gameLength
                local indexParam = (index - 1) / math.max(1,( size - 1 )) -- 1 to size
                local baseScore = rankStart + (rankEnd - rankStart)*indexParam
                rankTable[steamId] = rankTable[steamId] +  math.floor(baseScore * timeParam)
                -- Shared.Message(string.format("ID:%s I:%.2f T:%.2f BS:%i F:%i",steamId,indexParam,timeParam,baseScore,rankTable[steamId]))
            end
        end
        local rankTable = {}
        local rankScoreStatus = {}
        rankScoreStatus[-1] = { eloStart = -20 , eloEnd = -40 }
        rankScoreStatus[0] = { eloStart = 0 , eloEnd = 40 }
        rankScoreStatus[1] = { eloStart = 50 , eloEnd = 30 }

        local team1Status,team2Status
        if winningTeam == kMarineTeamType then
            team1Status = 1; team2Status = -1;
        elseif winningTeam == kAlienTeamType then
            team1Status = -1; team2Status = 1;
        else
            team1Status = 0; team2Status = 0;
        end

        -- Shared.Message("[CNCR] Team 1")
        ApplyRankTable(rankTable,team1Table,rankScoreStatus[team1Status].eloStart,rankScoreStatus[team1Status].eloEnd,gameLength)
        -- Shared.Message("[CNCR] Team 2")
        ApplyRankTable(rankTable,team2Table,rankScoreStatus[team2Status].eloStart,rankScoreStatus[team2Status].eloEnd,gameLength)

        -- Shared.Message("[CNCR] Result")

        for steamId, rankOffset in pairs(rankTable) do
            if rankOffset ~= 0 then
                RankPlayerDelta(self,steamId,rankOffset)
            end
            -- Shared.Message(string.format("%i|%d",steamId, rankOffset))
        end

        SavePersistent(self)
    end
    Shine.Hook.SetupClassHook("NS2Gamerules", "EndGame", "OnEndGame", "PassivePost")
end

function Plugin:ResetState()
    table.empty(self.PlayerRanks)
    ReadPersistent(self)
end

function Plugin:Cleanup()
    table.empty(self.PlayerRanks)
    return self.BaseClass.Cleanup( self )
end

function Plugin:CreateMessageCommands()
    local function AdminRankPlayer( _client, _id, _rank )
        local target = Shine.GetClientByNS2ID(_id)
        if not target then 
            return 
        end

        local player = target:GetControllingPlayer()
        local preRank = player.skill

        local rank = _rank - preRank
        GetPlayerData(self,_id).rank = rank
        player:SetCommunityRank(rank)
    
        Shine:AdminPrint( nil, "%s set %s rank to %s", true,  Shine.GetClientInfo( _client ), Shine.GetClientInfo( target ), _rank )
        SavePersistent(self)
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

        GetPlayerData(self,_id).rank = 0 
        target:GetControllingPlayer():SetCommunityRank(0)
        
        Shine:AdminPrint( nil, "%s reset %s rank", true,  Shine.GetClientInfo( _client ), _id )
        SavePersistent(self)
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
        Shine:AdminPrint( nil, "%s delta %s rank with %s", true,  Shine.GetClientInfo( _client ), _id, _offset )
        SavePersistent(self)
    end
    local deltaCommand = self:BindCommand( "sh_rank_delta", "rank_delta", AdminRankPlayerDelta )
    deltaCommand:AddParam{ Type = "steamid" }
    deltaCommand:AddParam{ Type = "number", Round = true, Min = -5000, Max = 5000, Optional = true, Default = 0 }
    deltaCommand:Help( "增减ID对应玩家的社区段位." )

    local function FakeBotSwitchID(_client,_id)
        local target = Shine.GetClientByNS2ID(_id)
        if not target then 
            return 
        end

        local data = GetPlayerData(self,target:GetUserId())
        data.fakeBot = not data.fakeBot
        target:GetControllingPlayer():SetFakeBot(data.fakeBot)
        Shine:AdminPrint( nil, "%s switch %s fakeBot to <%s>", true, Shine.GetClientInfo( _client ),Shine.GetClientInfo(target),data.fakeBot )
        SavePersistent(self)
    end
    local botCommand = self:BindCommand( "sh_fakebot_set", "fakebot_set", FakeBotSwitchID )
    botCommand:AddParam{ Type = "steamid" }
    botCommand:Help( "切换目标玩家的假BOT设置." )
    
    local function FakeBotSwitch(_client)
        FakeBotSwitchID(_client,_client:GetUserId())
    end

    local botCommand = self:BindCommand( "sh_fakebot", "fakebot", FakeBotSwitch )
    botCommand:Help( "假扮成BOT." )
end

function Plugin:GetUserGroup(Client)
	local id=tostring(Client:GetUserId())
	local userData = Shine:GetUserData(Client)

    local groupName = userData and userData.Group or nil
    local Group = groupName and Shine:GetGroupData(groupName) or Shine:GetDefaultGroup()
    
	return groupName and groupName or "RANK_DEFAULT" , Group
end

function Plugin:ClientConnect( _client )
    local clientID = _client:GetUserId()
    if clientID == 0 then return end
    
    local data = GetPlayerData(self,clientID)

    local player = _client:GetControllingPlayer()
    player:SetCommunityRank(data.rank)
    player:SetFakeBot(data.fakeBot)

    --Jeez wtf
    local groupName,groupData = self:GetUserGroup(_client)
    player:SetGroup(groupName)
    Shine.SendNetworkMessage(_client,"Shine_CommunityTier" ,{Tier = groupData.Tier or 0},true)
    Shared.Message("[CNCR] Client Rank:" .. tostring(clientID) .. ":" .. tostring(data.rank) .. "," .. tostring(data.fakeBot))
end