
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
    ["Tier"] = {
        [1] = { Count = 1, Credit = 15,Inform = true, },
        [2] = { Count = 2, Credit = 8,Inform = true },
        [3] = { Count = 5, Credit = 5 },
        [4] = { Count = 9, Credit = 3 },
    },
}

Plugin.kPrefix = "[战局预热]" 
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true
do
    local Validator = Shine.Validator()
    Validator:AddFieldRule( "Restriction.Hour",  Validator.IsType( "number", Plugin.DefaultConfig.Restriction.Hour ))
    Validator:AddFieldRule( "Restriction.Player",  Validator.IsType( "number", Plugin.DefaultConfig.Restriction.Player ))
    Validator:AddFieldRule( "Tier",  Validator.IsType( "table", Plugin.DefaultConfig.Tier  ))
    Plugin.ConfigValidator = Validator
end

local kPrewarmColor = { 235, 152, 78 }

local PrewarmFile = "config://shine/temp/prewarm.json"

function Plugin:Initialise()
    self.PrewarmTracker = {}
    self.MemberInfos = { }
    self:CreateMessageCommands()
    
    local File, Err = Shine.LoadJSONFile(PrewarmFile)
    self.PrewarmData = File or {
        ValidationDay = 0,
        Validated = false,
        UserData = {
            ["55022511"] = {tier = 0 ,score = 0, time = 100 , credit = 0 , name = "StriteR."}
        },
    }
    
	return true
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
    
    local Success, Err = Shine.SaveJSONFile( self.PrewarmData, PrewarmFile )
    if not Success then
        Shared.Message( "Error saving prewarm file: "..Err )
    end
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
        --Initial
        local initialTier = 0
        local initialCredit = 0 
        
        local userData = Shine:GetUserData(_clientID)
        local groupName = userData and userData.Group or nil
        local groupData = groupName and Shine:GetGroupData(groupName) or nil
        if groupData and groupData.PrewarmCredit then
            initialCredit = groupData.PrewarmCredit
            initialTier = 5
        end
        
        self.MemberInfos[_clientID] = {name = "",score = 0, time = 0, tier = initialTier ,  credit = initialCredit }
    end
    
    return self.MemberInfos[_clientID]
end


local function NotifyClient(self, _client, _data)
    if not _client then return end

    local data = _data or GetPlayerData(self,_client:GetUserId())
    if data.credit > 0 then
        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                255, 255, 255,string.format("当日剩余%s[预热点],可作用于[投票-换图提名]或者[自由下场]等特权,每日清空记得用完哦!", data.credit) )
    end
end

local function GetPrewarmScore(self, player, trackedTime)

    local team = player:GetTeamNumber()

    if trackedTime < 300 
        or team == kSpectatorIndex
        or kCurrentHour <= self.Config.Restriction.Hour
    then
        return trackedTime
    end
    
    local kills = player:getKills()
    local assists = player:GetAssistKills()
    local activePlayScore = kills * 2 + assists
    local commTime = player:GetAlienCommanderTime() + player:GetMarineCommanderTime()

    local activePlayed = activePlayScore > 30 or commTime > 300
    if not activePlayed then
        return 0
    end
    
    return 3 * trackedTime
end

-- Track Clients Prewarm Time
local function TrackClient(self, client, _clientID)
    local now = Shared.GetTime()

    if not self.PrewarmTracker[_clientID] then
        self.PrewarmTracker[_clientID] = now
    end
    
    local data = GetPlayerData(self,_clientID)
    local player = client:GetControllingPlayer()
    
    local trackedTime = math.floor(now - self.PrewarmTracker[_clientID])
    data.time = data.time + trackedTime

    if not self.PrewarmData.Validated then
        data.score = data.score + GetPrewarmScore(self,player,trackedTime)
    end
    
    self.PrewarmTracker[_clientID] = now
    player:SetPrewarmData(data)
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
    _data.credit = _data.credit + _credit
    _data.score = _scoreOverride and _scoreOverride or _data.score
    
    local client = Shine.GetClientByNS2ID(_clientID)
    if not client then return end

    local player = client:GetControllingPlayer()
    player:SetPrewarmData(_data)
    if _data.tier > 0 then
        Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                string.format("激励已派发,以获得[预热徽章%s]及[%s预热点],感谢您的付出!",_tier,_credit) )
    end
end

local function Reset(self)
    table.Empty(self.PrewarmData.UserData)
    table.Empty(self.MemberInfos)
    self.PrewarmData.ValidationDay = kCurrentDay
    self.PrewarmData.Validated = false
end

local function PrewarmValidateEnable(self)
    if kCurrentHour < self.Config.Restriction.Hour then return false end
    return true
end


local function GetInGamePlayerCount()
    local gameRules = GetGamerules()
    if not gameRules then return 0 end
    local team1Players,_,team1Bots = gameRules:GetTeam(kTeam1Index):GetNumPlayers()
    local team2Players,_,team2Bots = gameRules:GetTeam(kTeam2Index):GetNumPlayers()
    return  team1Players + team2Players - team1Bots - team2Bots 
end

local function Validate(self)
    if not PrewarmValidateEnable(self) then return end
    if GetInGamePlayerCount() < self.Config.Restriction.Player then return end
    
    if self.PrewarmData.Validated then return end
    self.PrewarmData.Validated = true

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
        
        if not curTierData then break end
        
        ValidateClient(self, prewarmClient.clientID, prewarmClient.data,curTier, curTierData.Credit,curTierData.Rank)
        
        if curTierData.Inform then
            nameList = nameList .. string.format("%s(%i分)|", prewarmClient.data.name, math.floor(prewarmClient.data.score / 60)) 
        end
        
        currentIndex = currentIndex + 1
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

function Plugin:GetPrewarmPrivilege(_client, _cost, _privilege)
    if not self.PrewarmData.Validated then return end
    
    local data = GetPlayerData(self,_client:GetUserId())
    if not data.tier or data.tier <= 0 then return end
    
    if _cost == 0 then
        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                255, 255, 255,string.format("当前拥有特权:[%s].", _privilege) )
        return true
    end
    
    if _cost > 0 then
        local credit = data.credit or 0
        if credit >= _cost then
            data.credit = credit - _cost
            Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                    255, 255, 255,string.format("使用 %s [预热点],当前剩余 %s [预热点].\n已获得特权:<%s>.", _cost,data.credit,_privilege) )
            return true
        end
        return false
    else
        Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                255, 255, 255,string.format("您的可用[预热点]不足.", _privilege) )
        return true
    end
end

-- Triggers
function Plugin:OnFirstThink()
    ReadPersistent(self)
    Shine.Hook.SetupClassHook("NS2Gamerules", "EndGame", "OnEndGame", "PassivePost")
    if self.PrewarmData.ValidationDay ~= kCurrentDay then
        Reset(self)
        --SavePersistent(self)
    end
end

function Plugin:SetGameState( Gamerules, State, OldState )
    if State == kGameState.Countdown then
        TrackAllClients(self)
        Validate(self)

        if PrewarmValidateEnable(self) and not self.PrewarmData.Validated then
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

function Plugin:OnEndGame(_winningTeam)
    TrackAllClients(self)
    --Validate(self)
end

function Plugin:MapChange()
    TrackAllClients(self)
    SavePersistent(self)
end

function Plugin:ClientConnect(_client)
    local clientID = _client:GetUserId()
    if clientID <= 0 then return end
    TrackClient(self,_client,clientID)

    if PrewarmValidateEnable(self) then
        if self.PrewarmData.Validated then
            NotifyClient(self,_client,nil)
        else
            Shine:NotifyDualColour( _client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,255, 255, 255,
                    string.format("服务器为预热状态,待预热成功后(开局时场内人数>=%s人),排名靠前的玩家将获得对应的预热激励.",self.Config.Restriction.Player) )
        end
    end
end

function Plugin:ClientConfirmConnect( _client )
    local clientID = _client:GetUserId()
    if clientID <= 0 then return end

    local data = GetPlayerData(self,clientID)
    local player = _client:GetControllingPlayer()
    data.name = player:GetName()
end

function Plugin:ClientDisconnect( _client )
    local clientID = _client:GetUserId()
    if clientID <= 0 then return end

    TrackClient(self,_client,clientID)
end

function Plugin:CreateMessageCommands()
    local setCommand = self:BindCommand( "sh_prewarm", "prewarm", function(_client) NotifyClient(self,_client,nil) end,true )
    setCommand:Help( "显示你的预热状态.")
    
    self:BindCommand( "sh_prewarm_validate", "prewarm_validate", function(_client,_targetID,_tier,_credit) ValidateClient(self,_targetID,nil,_tier,_credit) end,true )
    :AddParam{ Type = "steamid" }
    :AddParam{ Type = "number", Round = true, Min = 1, Max = 5, Default = 4 }
    :AddParam{ Type = "number", Round = true, Min = 0, Max = 15, Default = 3 }
    :Help( "设置玩家的预热状态以及预热点数,例如!prewarm_validate 5 3.(设置玩家段位4并给予3点预热点)")
    
    self:BindCommand( "sh_prewarm_cancel", "prewarm_cancel", function(_client,_targetID) ValidateClient(self,_targetID,nil,0,0,0) end,true )
        :AddParam{ Type = "steamid" }
        :Help( "取消玩家的预热点数(例如使用了连点器/作弊).")
    
    local resetCommand = self:BindCommand( "sh_prewarm_reset", "prewarm_reset", function(_client)
        Reset(self)
        SavePersistent(self)        
    end,true )
    resetCommand:Help( "重置服务器的预热状态与数据.")
end

function Plugin:IsPrewarming() 
    return not self.PrewarmData.Validated
end

return Plugin
