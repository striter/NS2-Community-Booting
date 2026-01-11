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
    Reputation = {
        Enable = true,
        Debug = true,
        PenaltyStarts = 0,
        PenaltyCheckInterval = 300,
        RageQuit = {
            CheckTime = 1200,
            MinPlayer = 12,
            ActivePlayTime = 60,
            DeltaQuit = -5,
            DeltaQuitReputationStepMultiplier = 100,
            DeltaWin = 1,
            DeltaLost = 1,
            DeltaMax = 200,
        },
    },
}

Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true
do
    local Validator = Shine.Validator()
    --Validator:AddFieldRule( "UserData",  Validator.IsType( "table", Plugin.DefaultConfig.UserData ))
    Validator:AddFieldRule( "Reputation",  Validator.IsType( "table", Plugin.DefaultConfig.Reputation ))
    Validator:AddFieldRule( "Reputation.Debug",  Validator.IsType( "boolean", Plugin.DefaultConfig.Reputation.Debug ))
    Validator:AddFieldRule( "Reputation.Enable",  Validator.IsType( "boolean", Plugin.DefaultConfig.Reputation.Enable ))
    Validator:AddFieldRule( "Reputation.PenaltyStarts",  Validator.IsType( "number", Plugin.DefaultConfig.Reputation.PenaltyStarts ))
    Validator:AddFieldRule( "Reputation.PenaltyCheckInterval",  Validator.IsType( "number", Plugin.DefaultConfig.Reputation.PenaltyCheckInterval ))
    Validator:AddFieldRule( "Reputation.RageQuit",  Validator.IsType( "table", Plugin.DefaultConfig.Reputation.RageQuit ))
    Validator:AddFieldRule( "Reputation.RageQuit.MinPlayer",  Validator.IsType( "number", Plugin.DefaultConfig.Reputation.RageQuit.MinPlayer ))
    Validator:AddFieldRule( "Reputation.RageQuit.DeltaWin",  Validator.IsType( "number", Plugin.DefaultConfig.Reputation.RageQuit.DeltaWin ))
    Validator:AddFieldRule( "Reputation.RageQuit.DeltaLost",  Validator.IsType( "number", Plugin.DefaultConfig.Reputation.RageQuit.DeltaLost ))
    Validator:AddFieldRule( "Reputation.RageQuit.DeltaMax",  Validator.IsType( "number", Plugin.DefaultConfig.Reputation.RageQuit.DeltaMax ))
    Validator:AddFieldRule( "Reputation.RageQuit.DeltaQuitReputationStepMultiplier",  Validator.IsType( "number", Plugin.DefaultConfig.Reputation.RageQuit.DeltaQuitReputationStepMultiplier ))
    Validator:AddFieldRule( "Elo.Check",  Validator.IsType( "boolean", Plugin.DefaultConfig.Elo.Check ))
    Validator:AddFieldRule( "Elo.Debug",  Validator.IsType( "boolean", Plugin.DefaultConfig.Elo.Debug ))
    Validator:AddFieldRule( "Elo.Restriction.Time",  Validator.IsType( "number", Plugin.DefaultConfig.Elo.Restriction.Time ))
    Validator:AddFieldRule( "Elo.Restriction.Player",  Validator.IsType( "number", Plugin.DefaultConfig.Elo.Restriction.Player ))
    Validator:AddFieldRule( "Elo.Constants.Tier",  Validator.IsType( "table", Plugin.DefaultConfig.Elo.Constants.Tier))
    Validator:AddFieldRule( "Elo.Constants.CommanderTier",  Validator.IsType( "table", Plugin.DefaultConfig.Elo.Constants.CommanderTier))
    Validator:AddFieldRule( "Elo.Constants.Default",  Validator.IsType( "number", Plugin.DefaultConfig.Elo.Constants.Default))
    Plugin.ConfigValidator = Validator
end
local kReputationGainColorTable = { 235, 152, 78 }
local kRageQuitColorTable = { 236, 112, 99 }
function Plugin:Initialise()
    self.MemberInfos = { }
    self:CreateMessageCommands()
	return true
end

local function ReadPersistent(self)
    --for k,v in pairs(self.Config.UserData) do
    --    self.MemberInfos[tonumber(k)] = v
    --end
end

local function SavePersistent(self)

    for k,v in pairs(self.MemberInfos) do
        if not v.fakeData then
            Shine.PlayerInfoHub:SetCommunityData(k,v)
        end
        --self.Config.UserData[tostring(k)] = v
    end
    --self:SaveConfig()
end

local function GetPlayerData(self,steamId)
    assert(steamId~=0)
    
    if not self.MemberInfos[steamId] then
        self.MemberInfos[steamId] = { fakeData = true }
    end
    
    return self.MemberInfos[steamId]
end

function Plugin:GetCommunityData(steamId)
    return GetPlayerData(self,steamId)
end

function Plugin:GetCommunityPlayHour(_steamId)
    local data = self:GetCommunityData(_steamId)
    
    local minute = data.timePlayed
    return minute and (minute / 60) or 0
end

function Plugin:GetCommunityBlackListed(_steamId)
    local data = self:GetCommunityData(_steamId)
    return data.reputation and data.reputation < 0
end

function Plugin:UseCommunityReputation(_player, _limit, _cost)
    
    local clientId = _player:GetClient():GetUserId()
    local data = self:GetCommunityData(clientId)
    if not data.reputation then
        return false,0
    end
    
    local value = data.reputation
    if value < _limit then
        return false,data.reputation
    end
    
    if _cost == 0 then return true,data.reputation end
    data.reputation = data.reputation - _cost
    _player:SetPlayerExtraData(data)
    return true, data.reputation
end

function Plugin:ResetState()
    table.Empty(self.MemberInfos)
    ReadPersistent(self)
end

function Plugin:Cleanup()
    table.Empty(self.MemberInfos)
    return self.BaseClass.Cleanup( self )
end

-- Triggers
function Plugin:OnFirstThink()
    ReadPersistent(self)
    self:OnReputationPenaltyCheck()
    Shine.Hook.SetupClassHook("NS2Gamerules", "EndGame", "OnEndGame", "PassivePost")
end

function Plugin:OnEndGame(_winningTeam)
    local lastRoundData = CHUDGetLastRoundStats();
    if not lastRoundData then
        Shared.Message("[CNCR] ERROR Option 'savestats' not enabled ")
        return
    end

    local gameMode = Shine.GetGamemode()
    if not table.contains(Shine.kRankGameMode,gameMode) then return end
    self:EndGameElo(lastRoundData)
    self:EndGameReputation(lastRoundData)
    self:EndGameRecord(lastRoundData)
    self:EndGameLastSeenName(lastRoundData)
    SavePersistent(self)
end

function Plugin:SetGameState( Gamerules, State, OldState )
    if State == kGameState.Countdown then
        self:OnReputationRoundStart()
    end
end

function Plugin:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force )
    self:RageQuitValidate(Player,NewTeam)
end

function Plugin:ClientDisconnect( _client )
    self:RageQuitValidate(_client:GetControllingPlayer(),kTeamReadyRoom)
end

local function GetUserGroup(Client)
    local userData = Shine:GetUserData(Client)

    local groupName = userData and userData.Group or nil
    local Group = groupName and Shine:GetGroupData(groupName) or Shine:GetDefaultGroup()

    return groupName and groupName or "RANK_DEFAULT" , Group
end


local function GetNumber(_value)
    return _value and tonumber(_value) or nil
end

local function GetBoolean(_value)
    return (_value and _value == "1") and 1 or 0
end


function Plugin:OnClientDBReceived(client, clientID, rawData)
    local player = client:GetControllingPlayer()
    local data = GetPlayerData(self,clientID)
    --Resolve Data 
    data.fakeData = nil
    data.fakeBot = GetBoolean(rawData.fakeBot)
    data.hideRank = GetBoolean(rawData.hideRank)
    data.rank = GetNumber(rawData.rank)
    data.rankOffset = GetNumber(rawData.rankOffset)
    data.rankComm = GetNumber(rawData.rankComm)
    data.rankCommOffset = GetNumber(rawData.rankCommOffset)
    data.reputation = GetNumber(rawData.reputation)
    data.reputationPenaltyLog = rawData.reputationPenaltyLog
    
    data.lastSeenNameTimes = GetNumber(rawData.lastSeenNameTimes)
    data.lastSeenName = rawData.lastSeenName
    data.lastSeenTimeStamp = GetNumber(rawData.lastSeenTimeStamp)
    data.lastSeenSkill = GetNumber(rawData.lastSeenSkill)
    data.lastSeenDay = rawData.lastSeenDay

    data.signature = rawData.signature
    self:RecordResolveData(data,rawData)
    player:SetPlayerExtraData(data)
end

function Plugin:OnCommunityDBReceived()
    for client in Shine.IterateClients() do
        local clientID = client:GetUserId()
        if clientID > 0 then
            local rawData = Shine.PlayerInfoHub:GetCommunityData(clientID)
            self:OnClientDBReceived(client,clientID, rawData)
            self:UpdateClientData(client,clientID)
        end
    end
end

function Plugin:ClientConnect( _client )
    local clientID = _client:GetUserId()
    if clientID <= 0 then return end

    local player = _client:GetControllingPlayer()

    local playerData = GetPlayerData(self,clientID)
    playerData.lastSeenIP = IPAddressToString(Server.GetClientAddress(_client))
    if not playerData.fakeData then      --Already resolved
        player:SetPlayerExtraData(playerData)
        return 
    end
    
    local rawData = Shine.PlayerInfoHub:GetCommunityData(clientID)
    if not rawData then return end
    self:OnClientDBReceived(_client,clientID, rawData)
    --Shared.Message("[CNCR] Client Rank:" .. tostring(clientID))
end

Plugin.kTDBadgesHourRequirement = {
    {name = "td_tier1",itemID = kTDTier1BadgeItemId,hourRequired = 2},
    {name = "td_tier2",itemID = kTDTier2BadgeItemId,hourRequired = 5},
    {name = "td_tier3",itemID = kTDTier3BadgeItemId,hourRequired = 20},
    {name = "td_tier4",itemID = kTDTier4BadgeItemId,hourRequired = 115},
    {name = "td_tier5",itemID = kTDTier5BadgeItemId,hourRequired = 200},
    {name = "td_tier6",itemID = kTDTier6BadgeItemId,hourRequired = 500},
    {name = "td_tier7",itemID = kTDTier7BadgeItemId,hourRequired = 1000},
    {name = "td_tier8",itemID = kTDTier8BadgeItemId,hourRequired = 1500},
}

local baseOwnsItem = GetOwnsItem
function GetOwnsItem(_itemID)
    return true
end

local kPrefix = "[信誉值]"

Plugin.kBadgeRows = {1,2,3,4,10}
local function DispatchBadge(_clientId, _name)
    for _, i in pairs(Plugin.kBadgeRows) do
        GiveBadge(_clientId, _name,i)
    end
end

function Plugin:UpdateClientData(_client, _clientId)        --Split cause connecting client sometimes won't receive network message
    local communityData = GetPlayerData(self, _clientId)
    if communityData.fakeData then return end
    local groupName,groupData = GetUserGroup(_client)
    local player = _client:GetControllingPlayer()
    player:SetGroup(groupName)

    local unlockGadgets = {}
    
    if groupData and groupData.UnlockGadgets then
        for _,v in pairs(groupData.UnlockGadgets) do
            unlockGadgets[tonumber(v)] = true
        end
    end
    
    local userData = Shine:GetUserData(_clientId)
    if userData and userData.UnlockGadgets then
        for _,v in pairs(userData.UnlockGadgets) do
            unlockGadgets[tonumber(v)] = true
        end
    end

    for k, _ in pairs(unlockGadgets) do
        unlockGadgets[k] = k
        Shine.SendNetworkMessage(_client,"Shine_CommunityGadgets" ,{ ItemID = k },true)
    end
    
    local syncData = {
        Tier = groupData.Tier or 0,
        TimePlayed = communityData.timePlayed or 0,
        RoundWin = communityData.roundWin or 0,
        TimePlayedCommander = communityData.timePlayedCommander or 0,
        RoundWinCommander = communityData.roundWinCommander or 0
    }

    local hourPlayed = math.floor(syncData.TimePlayed / 60.0)
    for _,tdBadges in pairs(Plugin.kTDBadgesHourRequirement) do
        if hourPlayed >= tdBadges.hourRequired or table.contains(unlockGadgets,tdBadges.itemID) then
            DispatchBadge(_clientId,tdBadges.name)
        end
    end
    
    local commHour = math.floor(syncData.TimePlayedCommander / 60.0)
    if commHour > 50 then
        DispatchBadge(_clientId, "commander")
    end
    
    Shine.SendNetworkMessage(_client,"Shine_CommunityTier" ,syncData,true)
    Shine.Hook.Broadcast("OnPlayerCommunityDataReceived",_client,communityData)
end


function Plugin:ClientConfirmConnect(_client)
    local clientID = _client:GetUserId()
    if clientID <= 0 then return end
    
    self:UpdateClientData(_client,clientID)
    Shine:NotifyDualColour( _client:GetControllingPlayer(),
            kReputationGainColorTable[1], kReputationGainColorTable[2], kReputationGainColorTable[3],kPrefix,
            255, 255, 255,string.format("当前服务器信誉值上限[%s],赢得获胜[+%s],完成比赛[+%s]",self.Config.Reputation.RageQuit.DeltaMax,self.Config.Reputation.RageQuit.DeltaWin,self.Config.Reputation.RageQuit.DeltaLost),true, data )
end

----Elo
local function GetMarineBaseSkill(player) return player.skill + player.skillOffset end
local function GetAlienBaseSkill(player) return player.skill - player.skillOffset end
local function GetMarineCommanderBaseSkill(player) return player.commSkill + player.commSkillOffset end
local function GetAlienCommanderBaseSkill(player) return player.commSkill - player.commSkillOffset end

local function GetMarineFinalSkill(player) return player:GetPlayerSkill() + player:GetPlayerSkillOffset() end
local function GetAlienFinalSkill(player) return player:GetPlayerSkill() - player:GetPlayerSkillOffset() end

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

local function RankPlayer(self, player, _id,
                          _rankMarine, _rankAlien,
                          _rankMarineComm,_rankAlienComm)
    local data = GetPlayerData(self,_id)
    if _rankMarine and _rankAlien then
        _rankMarine = _rankMarine >= 0 and _rankMarine or GetMarineBaseSkill(player)
        _rankAlien = _rankAlien >= 0 and _rankAlien or GetAlienBaseSkill(player)
        data.rank = (_rankMarine + _rankAlien) / 2 - player.skill
        data.rankOffset = (_rankMarine - _rankAlien) / 2 - player.skillOffset
    end
        
    if _rankMarineComm and _rankAlienComm then
        _rankMarineComm = _rankMarineComm >= 0 and _rankMarineComm or GetMarineCommanderBaseSkill(player)
        _rankAlienComm = _rankAlienComm >= 0 and _rankAlienComm or GetAlienCommanderBaseSkill(player)
        data.rankComm = (_rankMarineComm + _rankAlienComm) / 2 - player.commSkill
        data.rankCommOffset = (_rankMarineComm - _rankAlienComm) / 2 - player.commSkillOffset
    end
    EloDataSanityCheck(data,player)
end

local function RankPlayerDelta(self, _steamId, _marineDelta, _alienDelta, _marineCommDelta, _alienCommDelta)
    local data = GetPlayerData(self,_steamId)
    local client = Shine.GetClientByNS2ID(_steamId)
    
    data.rank = (data.rank or 0) + (_marineDelta + _alienDelta) / 2
    data.rankOffset = (data.rankOffset or 0) + (_marineDelta - _alienDelta) / 2
    data.rankComm = (data.rankComm or 0) + (_marineCommDelta + _alienCommDelta) / 2
    data.rankCommOffset = (data.rankCommOffset or 0) + (_marineCommDelta - _alienCommDelta) / 2
    EloDataSanityCheck(data,client and client:GetControllingPlayer())
end

function Plugin:EndGameElo(lastRoundData)

    if not self.Config.Elo.Check then return end


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
            _rankTable[steamId].player2 = _rankTable[steamId].player2 + playerDelta*_team2Param
            _rankTable[steamId].comm1 = _rankTable[steamId].comm1 + commDelta*_team1Param
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

    -- Quite dynamic(people join people leave), and with single legs exists average skill won't work,so treat both team equals
    local estimateA = 0.5 -- 1.0 / (1 + math.pow(10,(team2AverageSkill - team1AverageSkill) / 400))     --What it should be...
    
    local rankTable = {}
    ApplyRankTable(rankTable,team1Table,team1S - estimateA,1.25,0.75)     
    EloDebugMessage(self,"Team1:" .. tostring(team1AverageSkill))
    ApplyRankTable(rankTable,team2Table,team2S - (1-estimateA),0.75,1.25)     
    EloDebugMessage(self,"Team2:" .. tostring(team2AverageSkill))

    for steamId, rankOffset in pairs(rankTable) do
        if rankOffset.player1 ~= 0 or  rankOffset.player2 ~= 0 or rankOffset.comm1 ~=0 or rankOffset.comm2 ~= 0 then
            RankPlayerDelta(self,steamId,rankOffset.player1,rankOffset.player2,rankOffset.comm1,rankOffset.comm2)   
            EloDebugMessage(self,string.format("(ID:%-10s (P1):%-5i (P2):%-5i (C1):%-5i (C2):%-5i",steamId, rankOffset.player1,rankOffset.player2,rankOffset.comm1,rankOffset.comm2))
        end
    end

end

--Reputation
local kDefaultReputation = 48
local function ReputationPlayerDelta(self, _steamId, _delta, _reputationTitle)
    local data = GetPlayerData(self,_steamId)
    data.reputation = (data.reputation or kDefaultReputation) + _delta
    
    local client = Shine.GetClientByNS2ID(_steamId)
    if not client then
        if _reputationTitle and _delta < 0 then
            data.reputationPenaltyLog = string.format("%s|%s",os.date("%Y-%m-%d %H:%M:%S"), _reputationTitle)
        end
        return 
    end
    local player = client:GetControllingPlayer()
    player:SetPlayerExtraData(data)

    if _reputationTitle then

        if _delta > 0 then
            Shine:NotifyDualColour( player,
                    kReputationGainColorTable[1], kReputationGainColorTable[2], kReputationGainColorTable[3],kPrefix,
                    255, 255, 255,string.format("%s,现有[%s]信誉分",_reputationTitle,data.reputation),true, data )
        else

            Shine:NotifyDualColour( player,
                    kRageQuitColorTable[1], kRageQuitColorTable[2], kRageQuitColorTable[3],"[信誉分]",
                    255, 255, 255,string.format("%s,现有[%s]信誉分",_reputationTitle,data.reputation),true, data )
        end
    end
end

local function ReputationDebugMessage(self,_string)
    if not self.Config.Reputation.Debug then return end
    Shared.Message(_string)
end

local function ReputationEnabled(self)
    if not self.Config.Reputation.Enable then return false end
    return true
end

local kRageQuitType = enum({ 'None','Quit','Cover' })
local kRageQuitTracker = { }
function Plugin:OnReputationRoundStart()
    for Client in Shine.IterateClients() do
        local player = Client:GetControllingPlayer()
        local steamId = Client:GetUserId()
        if steamId > 0 then
            local data = GetPlayerData(self,steamId)
            local reputation = data.reputation or 0
            local team = player:GetTeamNumber()
            if data.reputationPenaltyLog then
                Shine:NotifyDualColour( player, kRageQuitColorTable[1], kRageQuitColorTable[2], kRageQuitColorTable[3],"[规范行为通知]",
                        255, 255, 255,string.format("由于您[%s],导致信誉值降低,若信誉值过低将受到不可预期的惩罚.\n请保证参与比赛的完整性,尊重你的队友与对手.",data.reputationPenaltyLog),true, data )
                data.reputationPenaltyLog = nil
            else
                if reputation < self.Config.Reputation.PenaltyStarts and (team == 1 or team == 2) then
                    Shine:NotifyDualColour( player, kRageQuitColorTable[1], kRageQuitColorTable[2], kRageQuitColorTable[3],"[规范行为通知]",
                            255, 255, 255,"由于您近期的行为导致信誉值过低,在对局中将受到不可预期的惩罚.\n请规范自身的游戏行为完整参与比赛以提升信誉值.",true, data )
                end
            end
        end
    end
end

function Plugin:OnReputationPenaltyCheck()
    if not ReputationEnabled(self) then return end
    if GetGamerules():GetGameStarted() then
        for Client in Shine.IterateClients() do
            local player = Client:GetControllingPlayer()
            local team = player:GetTeamNumber()
            
            local steamId = Client:GetUserId()
            if steamId <=0 then return end
            
            local data = GetPlayerData(self,steamId)
            local reputation = data.reputation or 0
            if reputation < self.Config.Reputation.PenaltyStarts
                    and (team == 1 or team == 2)
            then
                if player:isa("Marine") then
                    local random = math.random(1,3)
                    if random == 1 then
                        local weapon = player:GetWeaponInHUDSlot(1)
                        if weapon then
                            player:Drop(weapon,true,true)
                        end
                    elseif random == 2 then
                        player:SetStun(1)
                    else
                        player:SetParasited(nil)
                    end
                elseif player:isa("Exo") then
                    player:SetParasited(nil)
                elseif player:isa("Alien") then
                    local random = math.random(1,2)
                    if random == 1 then
                        player:SetVelocity(-player:GetVelocity())
                        player:DisableGroundMove(1)
                    elseif random == 2 then
                        player:DeductAbilityEnergy(50)
                    end
                end

                --data.reputation = reputation + 1
                --player:SetPlayerExtraData(data)
            end
        end
    end
    
    self:SimpleTimer( self.Config.Reputation.PenaltyCheckInterval, function()
        self:OnReputationPenaltyCheck()
    end )
end

function Plugin:RageQuitValidate(Player,NewTeam)
    if not ReputationEnabled(self)
        or not GetGamerules():GetGameStarted() 
        or Shine.GetHumanPlayerCount() <= self.Config.Reputation.RageQuit.MinPlayer
        or Shared:GetTime() < self.Config.Reputation.RageQuit.CheckTime 
            then return end     --Only validate when join a late game
    
    if Player:GetIsVirtual() then return end
    
    local clientId = Player:GetClient():GetUserId()
    if NewTeam == 1 or NewTeam == 2 then        --Join team1 or 2
        if kRageQuitTracker[clientId] == kRageQuitType.Quit then        --Rejoin
            kRageQuitTracker[clientId] = kRageQuitType.None
        else
            kRageQuitTracker[clientId] = kRageQuitType.Cover
        end
    else                    --Quit

        local playTime = Player:GetPlayTime()
        if playTime < self.Config.Reputation.RageQuit.ActivePlayTime then return end
        
        if kRageQuitTracker[clientId] == kRageQuitType.Cover then       --But leave
            kRageQuitTracker[clientId] = kRageQuitType.None
        else
            kRageQuitTracker[clientId] = kRageQuitType.Quit
        end
    end
end
local kRoundFinishNormalizedTime = 0.9
function Plugin:EndGameReputation(lastRoundData)
    if not ReputationEnabled(self) then return end

    if table.count(kRageQuitTracker) > 0 then
        ReputationDebugMessage(self,string.format("Rage quitters:"))
        for steamId,rageQuitType in pairs(kRageQuitTracker) do
            local reputationDelta = 0
            if rageQuitType == kRageQuitType.Quit then
                local data = GetPlayerData(self,steamId)
                local reputation = data.reputation or 0
                
                reputationDelta = self.Config.Reputation.RageQuit.DeltaQuit * (1 + math.floor(reputation / self.Config.Reputation.RageQuit.DeltaQuitReputationStepMultiplier))
                ReputationPlayerDelta(self,steamId, reputationDelta,string.format("中途离场 (%s)",reputationDelta))
            end
            ReputationDebugMessage(self,string.format("(ID:%-10s  (Delta):%-5i",steamId,reputationDelta))
        end
    end


    local winningTeamType = lastRoundData.RoundInfo.winningTeam
    local losingTeam
    if winningTeamType == kMarineTeamType then
        losingTeam = kAlienTeamType
    elseif winningTeamType == kAlienTeamType then
        losingTeam = kMarineTeamType
    end

    local gameLength = lastRoundData.RoundInfo.roundLength
    if Shine.GetHumanPlayerCount() >= self.Config.Reputation.RageQuit.MinPlayer
            and gameLength >= self.Config.Reputation.RageQuit.CheckTime
            and losingTeam ~= nil
    then
        ReputationDebugMessage(self,string.format("Covers:  Win:%s Lose:%s",winningTeamType,losingTeam))
        for Client in Shine.IterateClients() do
            if not Client:GetIsVirtual() then
                local clientId = Client:GetUserId()
                local rageQuitType = kRageQuitTracker[clientId] or kRageQuitType.None
                local player = Client:GetControllingPlayer()
                local steamId = Client:GetUserId()
                local playTime = player:GetPlayTime()
                local team =  player:GetTeamNumber()

                if rageQuitType ~= kRageQuitType.Quit and playTime / gameLength > kRoundFinishNormalizedTime then
                    local wins = team == winningTeamType
                    local reputationDelta = wins and self.Config.Reputation.RageQuit.DeltaWin or self.Config.Reputation.RageQuit.DeltaLost

                    if reputationDelta ~=0 then
                        local data = GetPlayerData(self,steamId)
                        if not data.reputation or data.reputation < self.Config.Reputation.RageQuit.DeltaMax then
                            ReputationPlayerDelta(self,steamId, reputationDelta,string.format("完成对局 (+%s)",reputationDelta))
                            ReputationDebugMessage(self,string.format("(ID:%-10s (Time):%-5i (team):%-5i (type:):%-5s (Delta):%-5i",steamId, playTime,team,EnumToString(kRageQuitType,rageQuitType),reputationDelta))
                        end
                    end
                end
            end
        end
    end

    table.clear(kRageQuitTracker)
end

function Plugin:RecordResolveData(data,rawData)
    data.timePlayed = GetNumber(rawData.timePlayed)
    data.timePlayedCommander = GetNumber(rawData.timePlayedCommander)
    data.roundPlayed = GetNumber(rawData.roundPlayed)
    data.roundFinished = GetNumber(rawData.roundFinished)
    data.roundFinishedCommander = GetNumber(rawData.roundFinishedCommander)
    data.roundWin = GetNumber(rawData.roundWin)
    data.roundWinCommander = GetNumber(rawData.roundWinCommander)
end

function Plugin:EndGameRecord(lastRoundData)

    local gameLength = lastRoundData.RoundInfo.roundLength
    
    local function RecordPlayer(playerData,data,wins)
        local playTime = math.floor(data.timePlayed/60)
        local commTime = math.floor(data.commanderTime / 60)
        local validPlay = data.timePlayed / gameLength > kRoundFinishNormalizedTime
        local validCommander = data.commanderTime / gameLength > 0.8
        
        playerData.timePlayed = (playerData.timePlayed or 0) + playTime
        playerData.timePlayedCommander = (playerData.timePlayedCommander or 0) + commTime
        if validPlay then
            playerData.roundFinished = (playerData.roundFinished or 0) + 1
            playerData.roundWin =  (playerData.roundWin or 0) + (wins and 1 or 0)
            if validCommander then
                playerData.roundFinishedCommander = (playerData.roundFinishedCommander or 0) + 1
                playerData.roundWinCommander = (playerData.roundWinCommander or 0) + (wins and 1 or 0)
            end
        end
    end

    local winningTeam = lastRoundData.RoundInfo.winningTeam
    local team1Wins = winningTeam == kTeam1Index
    local team2Wins = winningTeam == kTeam2Index
    for steamId , playerStat in pairs( lastRoundData.PlayerStats ) do
        local playerData = GetPlayerData(self,steamId)
        playerData.roundPlayed = (playerData.roundPlayed or 0) + 1
        RecordPlayer(playerData,playerStat[kTeam1Index],team1Wins)
        RecordPlayer(playerData,playerStat[kTeam2Index],team2Wins)
    end
end

function Plugin:EndGameLastSeenName(lastRoundData)
    if not Shine.IsActiveRound(lastRoundData) then return end
    
    local currentTimeStamp = os.time()
    local currentDate = string.format("%s-%s-%s",kCurrentYear,kCurrentMonth,kCurrentDay)
    for steamId , playerStat in pairs( lastRoundData.PlayerStats ) do
        local playerData = GetPlayerData(self,steamId)
        local currentName = playerStat.playerName
        playerData.lastSeenTimeStamp = currentTimeStamp
        playerData.lastSeenSkill = playerStat.skill
        playerData.lastSeenDay = currentDate
        if playerData.lastSeenName == nil then
            playerData.lastSeenName = currentName
            playerData.lastSeenNameTimes = nil
        else
            if currentName ~= playerData.lastSeenName then
                playerData.lastSeenNameTimes = (playerData.lastSeenNameTimes or 0) + 1
            else
                playerData.lastSeenNameTimes = nil
            end
        end
        
        if playerData.lastSeenNameTimes ~= nil and playerData.lastSeenNameTimes >= 30 then
            playerData.lastSeenNameTimes = nil
            playerData.lastSeenName = currentName
        end

        local client = Shine.GetClientByNS2ID(steamId)
        if client then
            local player = client:GetControllingPlayer()
            playerData.lastSeenSkill = math.max(player:GetPlayerSkill(),player:GetCommanderSkill())
        end
    end
end

function Plugin:ValidatePlayerRecord(_notifyClient, _targetClient)
    local player = _targetClient:GetControllingPlayer()
    local data = GetPlayerData(self,_targetClient:GetUserId())
    local reputation = data.reputation or 0
    Shine:NotifyDualColour( _notifyClient:GetControllingPlayer(),  236, 112, 99 ,"[社区记录]",
            255,255,255,
            string.format("<%s>的信息:\n社区: %d小时 %s信誉值\n战局: %d场次 %d胜局 %d参与\n指挥: %d场次 %d胜局 %d小时",
                    player:GetName(), 
                    math.floor((data.timePlayed or 0)/60), reputation > 256 and ">=256" or reputation,
                    data.roundFinished or 0, data.roundWin or 0,data.roundPlayed or 0,
                    data.roundFinishedCommander or 0, data.roundWinCommander or 0,math.floor((data.timePlayedCommander or 0)/60)
            )
    )
end

function Plugin:CreateMessageCommands()
    
    local function CanEloSelfTargeting(_client, _target)
        local access = _client == nil or Shine:HasAccess(_client,"sh_adminmenu")
        if access then return true end
        if _target == _client then
            Shine:NotifyCommandError( _client, "你不应该对自己使用这个指令" )
            return false
        end
        return true
    end
    
    --Elo
    self:BindCommand( "sh_rank_reset", "rank_reset", function(_client, _id )     ----Reset
    local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end
        if not CanEloSelfTargeting(_client,target) then return end

        local data = GetPlayerData(self,_id)
        data.rank = 0
        data.rankOffset = 0
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end)
        :AddParam{ Type = "steamid" }
        :Help( "重置玩家的[玩家段位](还原至NS2段位)." )

    self:BindCommand( "sh_rank_reset_comm", "rank_reset_comm",function(_client, _id )
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end
        if not CanEloSelfTargeting(_client,target) then return end

        local data = GetPlayerData(self,_id)
        data.rankComm = 0
        data.rankCommOffset = 0
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end)
        :AddParam{ Type = "steamid" }
        :Help( "重置玩家的[指挥段位](还原至NS2段位)." )

    self:BindCommand( "sh_rank_set", "rank_set", function( _client, _id, _rankMarine ,_rankAlien)     --Set       (Jezz ....)
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end
        if not CanEloSelfTargeting(_client,target) then return end

        RankPlayer( self, target:GetControllingPlayer(),_id,_rankMarine,_rankAlien,nil,nil)
    end )
        :AddParam{ Type = "steamid" }
        :AddParam{ Type = "number", Round = true, Min = -1, Max = 9999999, Optional = true, Default = -1 }
        :AddParam{ Type = "number", Round = true, Min = -1, Max = 9999999, Optional = true, Default = -1 }
        :Help( "设置对应玩家的[玩家段位].例:!rank_set 55022511 2700 2800 (-1保持原状)" )
    
    self:BindCommand( "sh_rank_set_comm", "rank_set_comm", function( _client, _id, _rankMarine ,_rankAlien)
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end
        if not CanEloSelfTargeting(_client,target) then return end

        RankPlayer( self, target:GetControllingPlayer(),_id,nil,nil,_rankMarine,_rankAlien)
    end )
        :AddParam{ Type = "steamid" }
        :AddParam{ Type = "number", Round = true, Min = -1, Max = 9999999, Optional = true, Default = -1 }
        :AddParam{ Type = "number", Round = true, Min = -1, Max = 9999999, Optional = true, Default = -1 }
        :Help( "设置对应玩家的[指挥段位].例:!rank_set 55022511 2700 2800 (-1保持原状)" )

    self:BindCommand( "sh_rank_delta", "rank_delta", function (_client, _id, _marineDelta, _alienDelta )     --Delta
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end
        if not CanEloSelfTargeting(_client,target) then return end
        RankPlayerDelta(self,_id,_marineDelta,_alienDelta,0,0)
    end)
        :AddParam{ Type = "steamid"}
        :AddParam{ Type = "number", Round = true, Min = -5000, Max = 5000, Optional = true, Default = 0 }
        :AddParam{ Type = "number", Round = true, Min = -5000, Max = 5000, Optional = true, Default = 0 }
        :Help( "增减对应玩家的[玩家段位].例:!rank_delta 55022511 100 -100" )

    self:BindCommand( "sh_rank_delta_comm", "rank_delta_comm", function( _client, _id, _marineDelta,_alienDelta )
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end
        if not CanEloSelfTargeting(_client,target) then return end
        RankPlayerDelta(self,_id,0,0,_marineDelta,_alienDelta)
    end )
        :AddParam{ Type = "steamid"}
        :AddParam{ Type = "number", Round = true, Min = -5000, Max = 5000, Optional = true, Default = 0 }
        :AddParam{ Type = "number", Round = true, Min = -5000, Max = 5000, Optional = true, Default = 0 }
        :Help( "增减对应玩家的[指挥段位].例:!rank_delta 55022511 100 -100" )
        
    --Reputation
    self:BindCommand( "sh_rep_delta", "rep_delta", function( _client, _id, _delta,_title )
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end
        ReputationPlayerDelta(self,_id,_delta,_title)
    end)
        :AddParam{ Type = "steamid"}
        :AddParam{ Type = "number", Round = true, Min = -500, Max = 500, Optional = true, Default = 0 }
        :AddParam{ Type = "string", Optional = true}
        :Help( "增减对应玩家的[性欲分].例:!rep_delta 55022511 500" )

    self:BindCommand( "sh_rep_reset", "rep_reset",function( _client, _id, _delta )
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end
        local data = GetPlayerData(self,_id)
        data.reputation = 0
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end )
    :AddParam{ Type = "steamid"}
    :Help( "重置玩家的[性欲分].例:!rep_reset 55022511" )
    
    self:BindCommand( "sh_rep_set", "rep_set",function( _client, _id, _amount )
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end
        local data = GetPlayerData(self,_id)
        data.reputation = _amount
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end )
        :AddParam{ Type = "steamid"}
        :AddParam{ Type = "number", Round = true, Min = -500, Max = 500, Optional = true, Default = 0 }
        :Help( "设置玩家的[性欲分].例:!rep_set 55022511 500" )
    
    --BOT
    local function FakeBotSwitchID(_client,_id)
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end

        local data = GetPlayerData(self,target:GetUserId())
        data.fakeBot = data.fakeBot == 1 and 0 or 1
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
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end

        local data = GetPlayerData(self,target:GetUserId())
        data.hideRank = data.hideRank == 1 and 0 or 1
        target:GetControllingPlayer():SetPlayerExtraData(data)
    end

    self:BindCommand( "sh_hiderank_set", "hiderank_set", HideRankSwitchID )
        :AddParam{ Type = "steamid" }
        :Help( "目标玩家的社区段位显示." )

    local function HideRankSwitch(_client)
        HideRankSwitchID(_client,_client:GetUserId())
    end
    self:BindCommand( "sh_hiderank", "hiderank", HideRankSwitch)
        :Help( "切换社区段位显示." )
    --Emblem
    local function EmblemSetID(_client, _id, _emblem)
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end

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


    local function CheckPlayerHistory(_client, _id)
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end
        
        self:ValidatePlayerRecord(_client,target)
    end

    local function CheckHistory(_client)
        self:ValidatePlayerRecord(_client,_client)
    end

    self:BindCommand( "sh_history_check", "history_check", CheckPlayerHistory,true)
        :AddParam{ Type = "steamid" }
        :Help( "查询玩家的社区历史记录." )
    
    self:BindCommand( "sh_history", "history", CheckHistory,true )
        :Help( "查询我的社区历史记录." )

    local function SetSignature(_client,_signature)
        if not _client then return end
        local data = GetPlayerData(self,_client:GetUserId())
        data.signature = _signature
        local player = _client:GetControllingPlayer()
        player:SetPlayerExtraData(data)
    end
    
    self:BindCommand( "sh_signature", "signature", SetSignature,true )
        :AddParam{ Type = "string", TakeRestOfLine = true, Default = "这个人很懒没有设置个性签名" }
        :Help( "设置我的个性签名. 示例!signature 在吗" )
    
    local function EloCheck(_client,_id)
        local target = Shine.AdminGetClientByNS2ID(_client,_id)
        if not target then return end

        local player = target:GetControllingPlayer()
        Shine:NotifyDualColour( _client:GetControllingPlayer(),  236, 112, 99 ,"[查询]", 255,255,255,
                string.format("<%s>的查询信息:\n玩家: [hive:%d/%d] [ns2cn:%d/%d] \n指挥：[hive:%d/%d] [ns2cn:%d/%d]",
                        player:GetName(),
                        player.skill,player.skillOffset,player:GetPlayerSkill(),player:GetPlayerSkillOffset(),
                        player.commSkill,player.commSkillOffset,player:GetCommanderSkill(),player:GetCommanderSkillOffset()))
    end
    
    self:BindCommand( "sh_elo_check", "elo_check", EloCheck)
        :AddParam{ Type = "steamid" }
        :Help( "查询玩家的分数明细." )

    self:BindCommand( "sh_querydatabase", "querydatabase",  function()
        Shine.PlayerInfoHub:QueryDB()
    end ):Help( "数据库挂了,尝试刷新一下." )
end
