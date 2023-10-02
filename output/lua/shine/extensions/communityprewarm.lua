
local Plugin = Shine.Plugin( ... )

Plugin.Version = "1.0"
Plugin.PrintName = "communityprewarm"
Plugin.HasConfig = true
Plugin.ConfigName = "CommunityPrewarm.json"
Plugin.DefaultConfig = {
    ValidationDay = 0,
    Validated = false,
    Restriction = {
        Hour = 4,           --Greater than this hour
        Player = 12,
    },
    ["Tier"] = {
        [1] = { Count = 2, Credit = 15,Rank = -200,Inform = true, },
        [2] = { Count = 3, Credit = 10,Rank = -100,Inform = true },
        [3] = { Count = 10, Credit = 5 },
        [4] = { Count = 99, Credit = 1 },
    },
    ["TomorrowAward"] = {
        Tier = 5,
        Credit = 1,
        ["UserData"] = {
            [1] = 55022511,
        },
    },
    ["UserData"] = {
        ["55022511"] = {tier = 0 ,score = 0, time = 100 , credit = 0 , name = "StriteR."}
    },
}

Plugin.kPrefix = "[战局预热]" 
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true
do
    local Validator = Shine.Validator()
    Validator:AddFieldRule( "ValidationDay",  Validator.IsType( "number", Plugin.DefaultConfig.ValidationDay ))
    Validator:AddFieldRule( "Validated",  Validator.IsType( "boolean", Plugin.DefaultConfig.Validated ))
    Validator:AddFieldRule( "Restriction.Hour",  Validator.IsType( "number", Plugin.DefaultConfig.Restriction.Hour ))
    Validator:AddFieldRule( "Restriction.Player",  Validator.IsType( "number", Plugin.DefaultConfig.Restriction.Player ))
    Validator:AddFieldRule( "Tier",  Validator.IsType( "table", Plugin.DefaultConfig.Tier  ))
    Validator:AddFieldRule( "UserData",  Validator.IsType( "table", Plugin.DefaultConfig.UserData  ))
    Validator:AddFieldRule( "TomorrowAward",  Validator.IsType( "table", Plugin.DefaultConfig.TomorrowAward))
    Validator:AddFieldRule( "TomorrowAward.Tier",  Validator.IsType( "number", Plugin.DefaultConfig.TomorrowAward.Tier))
    Validator:AddFieldRule( "TomorrowAward.Credit",  Validator.IsType( "number", Plugin.DefaultConfig.TomorrowAward.Credit))
    Validator:AddFieldRule( "TomorrowAward.UserData",  Validator.IsType( "table", Plugin.DefaultConfig.TomorrowAward.UserData))
    Plugin.ConfigValidator = Validator
end

local kPrewarmColor = { 235, 152, 78 }

function Plugin:Initialise()
    self.PrewarmTracker = {}
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

-- Track Clients Prewarm Time
local function TrackClient(self, client, _clientID)
    local now = Shared.GetTime()

    if not self.PrewarmTracker[_clientID] then
        self.PrewarmTracker[_clientID] = now
    end
    
    local data = GetPlayerData(self,_clientID)
    local player = client:GetControllingPlayer()
    local team = player:GetTeamNumber()
    
    local trackedTime = math.floor(now - self.PrewarmTracker[_clientID])
    data.time = data.time + trackedTime

    if not self.Config.Validated then
        local scoreScalar = 1
        if team == kTeam1Index or team == kTeam2Index then
            scoreScalar = 3
        end
        data.score = data.score + trackedTime * scoreScalar
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

local function ValidateClient(self, _clientID, _data, _tier, _credit,_rank)
    _data = _data or GetPlayerData(self,_clientID)
    _data.tier = _tier
    _data.credit = _data.credit + _credit
    
    local client = Shine.GetClientByNS2ID(_clientID)
    if not client then return end

    local player = client:GetControllingPlayer()
    
    if _rank then
        local EFEnabled, EFPlugin = Shine:IsExtensionEnabled( "enforceteamsizes" )
        local CREnabled, CRPlugin = Shine:IsExtensionEnabled( "communityrank" )
        if EFEnabled and CREnabled then
            if EFPlugin:GetPlayerSkillLimited(player) then
                Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix, 255, 255, 255,"您为非服务器目标分段玩家,但鉴于你的积极贡献行为,已为您调整分数.若作出不符分段的行为将受到惩罚(分数还原或封禁).")
                Shared.ConsoleCommand(string.format("sh_rank_delta %s %s %s", _clientID,_rank,_rank))
            end
        end
    end


    player:SetPrewarmData(_data)
    Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewPParmColor[3],self.kPrefix,255, 255, 255,
            string.format("激励已派发,以获得[预热徽章%s]及[%s预热点],感谢您的付出!",_tier,_credit) )
end

local function Reset(self)
    table.Empty(self.Config.UserData)
    table.Empty(self.MemberInfos)
    self.Config.ValidationDay = kCurrentDay
    self.Config.Validated = false
end

local function PrewarmValidateEnable(self)
    if kCurrentHour < self.Config.Restriction.Hour then return false end
    return true
end

function Plugin:DispatchTomorrowPrivilege(_clients,_message)
    if not self.Config.Validated then return end
    
    for _,client in pairs(_clients) do
        local clientID = tostring(client:GetUserId())
        if not table.contains(self.Config.TomorrowAward.UserData,clientID) then
            table.insert(self.Config.TomorrowAward.UserData,clientID)
        end
    end

    for client in Shine.IterateClients() do
        Shine:NotifyDualColour( client, kPrewarmColor[1], kPrewarmColor[2], kPrewarmColor[3],self.kPrefix,
                255, 255, 255,string.format("%s成功,参与其中的%i名玩家将于明日获得对应的换服激励.",_message,#_clients))
    end
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
    
    if self.Config.Validated then return end
    self.Config.Validated = true

    --Dispatch lastday award
    for _,clientIDs in pairs(self.Config.TomorrowAward.UserData) do
        local clientID = tonumber(clientIDs)
        ValidateClient(self,clientID,nil,self.Config.TomorrowAward.Tier,self.Config.TomorrowAward.Credit)
    end
    table.Empty(self.Config.TomorrowAward.UserData)
    
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
    if not self.Config.Validated then return end
    
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
    if self.Config.ValidationDay ~= kCurrentDay then
        Reset(self)
        --SavePersistent(self)
    end
end

function Plugin:SetGameState( Gamerules, State, OldState )
    if State == kGameState.Countdown then
        TrackAllClients(self)
        Validate(self)

        if PrewarmValidateEnable(self) and not self.Config.Validated then
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
        if self.Config.Validated then
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
    
    local validateCommand = self:BindCommand( "sh_prewarm_validate", "prewarm_validate", function(_client,_targetID,_tier,_credit) ValidateClient(self,_targetID,nil,_tier,_credit) end,true )
    validateCommand:AddParam{ Type = "steamid" }
    validateCommand:AddParam{ Type = "number", Round = true, Min = 1, Max = 5, Default = 4 }
    validateCommand:AddParam{ Type = "number", Round = true, Min = 0, Max = 15, Default = 3 }
    validateCommand:Help( "设置玩家的预热状态以及预热点数,例如!prewarm_validate 5 3.(设置玩家段位4并给予3点预热点)")

    local resetCommand = self:BindCommand( "sh_prewarm_reset", "prewarm_reset", function(_client)
        Reset(self)
        SavePersistent(self)        
    end,true )
    resetCommand:Help( "重置服务器的预热状态与数据.")
end

function Plugin:IsPrewarming() 
    return not self.Config.Validated
end

return Plugin
