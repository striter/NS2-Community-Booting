local Plugin = Shine.Plugin( ... )

Plugin.HasConfig = true
Plugin.ConfigName = "EnforceTeamSizes.json"
Plugin.PrintName = "Enforced Team Size"

Plugin.RestrictedOperation = table.AsEnum{
	"SPECTATOR", "KICK", "REDIRECT",
}

Plugin.SkillLimitMode = table.AsEnum{
	"NONE", "NOOB",
}

Plugin.DefaultConfig = {
	SlotCoveringBegin = 15,
	DynamicStartupSeconds = 45,
	DynamicStartupHourContribution = 0.01,
	DynamicStartupSkillContribution = 0.001,
	
	Setting = {
		Mode = Plugin.SkillLimitMode.NOOB,
		MinPlayerCount = 28,
		Team = { 12 , 12 },
		TeamForceJoin = { 24 , 30, 36 },
		SkillRange = {-1,-1},
		BlockSpectators = true,
	},
	SettingOverride = {
		HourRange = {-1,-1},
		Setting = {
			Mode = Plugin.SkillLimitMode.NONE,
			MinPlayerCount = 16,
			Team = { 12 , 12 },
			TeamForceJoin = {30,34,38},
			SkillRange = {-1,-1},
			BlockSpectators = false,
		},
	},
	
	RestrictedOperation = 
	{
		Operation = Plugin.RestrictedOperation.SPECTATOR,
		Reason = "Rookie Server, No Smurf Is Allowed!",
		BanMinute = -1,
		RedirectIP = "192,168,0,1:27015",
	},
	
	NewComerBypass = {
		Enable = true,
		Skill = 500,
		Hour = 10,
	},
	ReputationBypass = {
		Enable = false,
		Limit = 50,
		Cost = 10,
	},
	PlayTimeBypass = 300,
	MessageNameColor = {0, 255, 0 },
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

do
	local Validator = Shine.Validator()
	Validator:AddFieldRule( "SlotCoveringBegin",  Validator.IsType( "number", Plugin.DefaultConfig.SlotCoveringBegin ))
	Validator:AddFieldRule( "PlayTimeBypass",  Validator.IsType( "number", Plugin.DefaultConfig.PlayTimeBypass ))
	Validator:AddFieldRule( "DynamicStartupSeconds",  Validator.IsType( "number", Plugin.DefaultConfig.DynamicStartupSeconds ))
	Validator:AddFieldRule( "DynamicStartupHourContribution",  Validator.IsType( "number", Plugin.DefaultConfig.DynamicStartupHourContribution ))
	Validator:AddFieldRule( "DynamicStartupSkillContribution",  Validator.IsType( "number", Plugin.DefaultConfig.DynamicStartupSkillContribution ))
	Validator:AddFieldRule( "RestrictedOperation", Validator.IsType( "table", Plugin.DefaultConfig.RestrictedOperation ) )
	Validator:AddFieldRule( "Setting", Validator.IsType( "table", Plugin.DefaultConfig.Setting ) )
	Validator:AddFieldRule( "Setting.TeamForceJoin", Validator.IsType( "table", Plugin.DefaultConfig.Setting.TeamForceJoin ) )
	Validator:AddFieldRule( "SettingOverride.HourRange", Validator.IsType( "table", Plugin.DefaultConfig.SettingOverride.HourRange ) )
	Validator:AddFieldRule( "SettingOverride.Setting.TeamForceJoin", Validator.IsType( "table", Plugin.DefaultConfig.SettingOverride.Setting.TeamForceJoin ) )
	Validator:AddFieldRule( "NewComerBypass",  Validator.IsType( "table", Plugin.DefaultConfig.NewComerBypass ))
	Validator:AddFieldRule( "MessageNameColor",  Validator.IsType( "table", {0,255,0} ))

	Plugin.ConfigValidator = Validator
end

local priorColorTable = { 235, 152, 78 }
local errorColorTable = { 236, 112, 99 }

local kTeamJoinTracker = { }
local kTeamRejoinTracker = {}

local function GetConstrains(self)
	local hour = kCurrentHourFloat
	local override = self.Config.SettingOverride
	
	local hourMin = override.HourRange[1]
	local hourMax = override.HourRange[2]
	local isOverride = hour >= hourMin and hour <= hourMax  --0-24
	if not isOverride then
		hour = hour + 24
		isOverride = hour >= hourMin and hour <= hourMax		--12 - 36 range 
	end
	
	local constrains = isOverride and override.Setting or self.Config.Setting
	constrains.IsOverride = isOverride
	return constrains
end

function Plugin:Initialise()
	self.Enabled = true
	self:CreateCommands()
	Shine.Hook.SetupClassHook("NS2Gamerules", "EndGame", "OnEndGame", "PassivePost")
	return true
end

function Plugin:OnFirstThink()
	self.Constrains = GetConstrains(self)
	self.ConstrainsUpdated = self.Constrains.Mode == Plugin.SkillLimitMode.NONE
	self.Timer = self:SimpleTimer( self.Config.DynamicStartupSeconds, function()
		self:UpdateConstrains()
	end )
end

function Plugin:Notify(Player, Message,colors, data)
		Shine:NotifyDualColour( Player,
				colors[1], colors[2], colors[3],"[战局约束]",
				255, 255, 255,Message,true, data )
end

function Plugin:GetNumPlayers(Team)
	local players, _, bots = Team:GetNumPlayers()
	return players - bots
end

function Plugin:GetPlayerLimit(Gamerules,Team)
	if Team == kSpectatorIndex and self.Constrains.BlockSpectators then
		local leastPlayersInGame = self.Constrains.Team[kTeam1Index] + self.Constrains.Team[kTeam2Index]
		local inTeamPlayers = self:GetNumPlayers(Gamerules:GetTeam(kTeam1Index)) + self:GetNumPlayers(Gamerules:GetTeam(kTeam2Index))
		if inTeamPlayers >= leastPlayersInGame then return 99 end 	--They are seeding
		return -1	--Join the game little f**k
	end

	return self.Constrains.Team[Team] or 99
end

function Plugin:RedirectClient(client)
	local message = {ip = self.Config.RestrictedOperation.RedirectIP}
	Server.SendNetworkMessage(client,"Redirect",message, true)
end

function Plugin:OnPlayerRestricted(_player,_newTeam)
	local client = _player:GetClient()
	local operationData = self.Config.RestrictedOperation
	local operation = operationData.Operation
	if operation == Plugin.RestrictedOperation.SPECTATOR then
		if _player:GetTeamNumber() ~= kSpectatorIndex then
			local gamerules = GetGamerules()
			if gamerules then gamerules:JoinTeam( _player, kSpectatorIndex, true,true ) end
		end
		return true
	end
	
	local reason = operationData.Reason
	if operation == Plugin.RestrictedOperation.KICK then
		client.DisconnectReason = reason
		Server.DisconnectClient(client, reason )
	elseif operation == Plugin.RestrictedOperation.REDIRECT then
		self:RedirectClient(client)
	end

	if operationData.BanMinute >= 0 then
		self:SimpleTimer( 0.2, function()
			Shine:RunCommand( nil, "sh_banid", false,  _player:GetClient():GetUserId(), operationData.BanMinute,  reason )
		end )
	end

	return true
end

--local function GetPlayerCurrentSkill(_player,_team)
--	local finalSkill = _player:GetPlayerSkill() or 0
--	local offset = _player.GetPlayerSkillOffset and _player:GetPlayerSkillOffset() or 0
--	if _team == 1 then
--		finalSkill = finalSkill + offset
--	elseif _team == 2 then
--		finalSkill = finalSkill - offset
--	end
--	return finalSkill
--end


function Plugin:UpdateConstrains()
	if self.Timer then
		self.Timer:Destroy()
		self.Timer = nil
	end
	
	self.ConstrainsUpdated = true
	local constrains = GetConstrains(self)
	local type = self.Constrains.Mode
	if type == Plugin.SkillLimitMode.NONE then
		return 
	end

	local clientSkillTable = {}
	--local activeClientCount = 0
	for client in Shine.IterateClients() do
		--activeClientCount = activeClientCount + 1
		if not client:GetIsVirtual() then
			local skill = client:GetControllingPlayer():GetPlayerSkill()
			if skill > self.Constrains.SkillRange[1] then
				table.insert(clientSkillTable, { skill = skill })
			end
		end
	end
	
	local function RankCompare(a,b)
		return a.skill < b.skill
	end
	
	if #clientSkillTable > 0 then
		table.sort(clientSkillTable,RankCompare)
		
		--local connectingClientCount = Server.GetNumClientsTotal() - activeClientCount
		local validateClientCount = constrains.MinPlayerCount -- - connectingClientCount
		local finalValue = clientSkillTable[math.min(#clientSkillTable, validateClientCount)].skill
		self.Constrains.SkillRange[2] = finalValue + 1
	end
		
	self.Timer = self:SimpleTimer( 5, function()
		self:UpdateConstrains()
	end )
end

function Plugin:GetPlayerSkillLimited(_player,_team)
	
	local skill = math.max(_player:GetPlayerSkill(),0)
	local skillLimited = skill < self.Constrains.SkillRange[1]
	if self.Constrains.SkillRange[2] > 0 then
		skillLimited = skillLimited or skill > self.Constrains.SkillRange[2]
	end
	
	return skillLimited,skill
end

function Plugin:GetPlayerRestricted(_player,_team)

	local client = Server.GetOwner(_player)
	local clientId = client:GetUserId()
	local crEnabled, cr = Shine:IsExtensionEnabled( "communityrank" )
	local skillLimited, finalSkill =  self:GetPlayerSkillLimited(_player,_team)
	
	if skillLimited then
		local errorMessage = string.format("您的平均分数(%i)不在服务器限制范围内(%s-%s).", finalSkill,self.Constrains.SkillRange[1],self.Constrains.SkillRange[2] < 0 and "∞" or self.Constrains.SkillRange[2])
		
		self:Notify(_player,errorMessage,errorColorTable,nil)

		local restricted = self:OnPlayerRestricted(_player,_team)
		if restricted then
			self:Notify(_player,string.format("预热玩家将忽略上述限制,可等待分服,同时非高峰期将开放限制.", finalSkill,self.Constrains.SkillRange[1],self.Constrains.SkillRange[2] < 0 and "∞" or self.Constrains.SkillRange[2])
			,errorColorTable,nil)
		end

		return restricted
	end

	if not self.ConstrainsUpdated and (_team == kTeam1Index or _team == kTeam2Index or _team == kTeamReadyRoom) then
		local now = Shared.GetTime()
		local minTimeToWait = self.Config.DynamicStartupSeconds
		if crEnabled then
			local awaitTime = math.floor(cr:GetCommunityPlayHour(clientId) * self.Config.DynamicStartupHourContribution)
			awaitTime = math.max(awaitTime, math.floor(finalSkill * self.Config.DynamicStartupSkillContribution))
			minTimeToWait = math.min(minTimeToWait, awaitTime)
		end

		if minTimeToWait > now then
			self:Notify(_player,string.format("战局准备中,请于%i秒后再次加入.",minTimeToWait - now),errorColorTable,nil)
			return true
		end
	end
	
	return false
end

local function GetForceJoinLimit(limitTable)
	local forceJoinLimit = 0
	local activeClient = Shine.GetHumanPlayerCount()
	for k,v in ipairs(limitTable) do
		if activeClient >= v then
			forceJoinLimit = k
		end
	end
	return forceJoinLimit
end

local kTeamNames = { "陆战队", "卡拉异形", "观战" }
function Plugin:JoinTeam(_gamerules, _player, _newTeam, _, _shineForce)
	if _shineForce then return end
	if _player:GetIsVirtual() then return end
	if _newTeam == kTeamReadyRoom then 
		if self:GetPlayerRestricted(_player,_newTeam) then return false end
		return
	end

	local available = not self:GetPlayerRestricted(_player,_newTeam)
	local curTeamPlayer = self:GetNumPlayers(_gamerules:GetTeam(_newTeam))
	local playerLimit = self:GetPlayerLimit(_gamerules, _newTeam)
	local playerLimitExtend = GetForceJoinLimit(self.Constrains.TeamForceJoin)
	local maxPlayerLimit = playerLimit + playerLimitExtend
	local forcePrivilegeTitle
	local forceCredit
	local teamName = kTeamNames[_newTeam]
	local errorString
	if curTeamPlayer >= playerLimit then
		if _newTeam == kSpectatorIndex then
			errorString =  "战局内存在可游玩空位,请尽快进入游戏!"
			available = false
			forceCredit = 0
			forcePrivilegeTitle = "预热观战位"
		else
			errorString = string.format( "<%s>已满[>=%s人%s],请等待场内空位.", teamName ,playerLimit,
					playerLimitExtend > 0 and string.format("|%s预热位",playerLimitExtend) or "")
			
			available = false
			local limitReached = curTeamPlayer < maxPlayerLimit
			forceCredit = limitReached and 1 or 2
			forcePrivilegeTitle = limitReached and "预热入场通道" or "预热越限通道"
		end
	end

	if available then return end
	
	local client = Server.GetOwner(_player)
	if not client or client:GetIsVirtual()  then return end
	local userId = client:GetUserId()

	local newComerConfig = self.Config.NewComerBypass
	local crEnabled, cr = Shine:IsExtensionEnabled( "communityrank" )
	if newComerConfig.Enable then
		local isNewcomer = newComerConfig.Skill <= 0 or _player:GetPlayerSkill() < newComerConfig.Skill
		if isNewcomer and newComerConfig.Hour > 0 and crEnabled then
			local communityData = cr:GetCommunityData(userId)
			if communityData.timePlayed then
				isNewcomer = isNewcomer and (communityData.timePlayed / 60) < newComerConfig.Hour
			end
		end
		if isNewcomer then
			--self:Notify(_player, "您为[新人优待玩家],已忽视上述限制!",priorColorTable,nil)
			return
		end
	end

	if Shine:HasAccess( client, "sh_priorslot" ) then
		self:Notify(_player, "[高级预留玩家]特权启用.",priorColorTable,nil)
		return
	end

	if _newTeam ~= kSpectatorIndex then
		local gamerules = GetGamerules()
		local team1Players = self:GetNumPlayers(gamerules:GetTeam(kTeam1Index))
		local team2Players = self:GetNumPlayers(gamerules:GetTeam(kTeam2Index))
		local teamMaxPlayers = math.max(team1Players,team2Players)
		if curTeamPlayer < teamMaxPlayers  then
			if math.abs(team1Players - team2Players) > 1
					or (curTeamPlayer < maxPlayerLimit and Shared.GetTime() > self.Config.SlotCoveringBegin * 60)
			then
				self:Notify(_player, "已进行对局补位.",priorColorTable,nil)
				return
			end
		end

		if table.contains(kTeamJoinTracker,userId) then
			self:Notify(_player, "[当局入场通道]特权启用.",priorColorTable,nil)
			return
		end

		if table.contains(kTeamRejoinTracker,userId) then
			self:Notify(_player, "[异常离开补位通道]已启用.",priorColorTable,nil)
			return
		end

		local cpEnabled, cp = Shine:IsExtensionEnabled( "communityprewarm" )
		if forceCredit and cpEnabled then
			if cp:GetPrewarmPrivilege(client,forceCredit,forcePrivilegeTitle) then
				table.insert(kTeamJoinTracker,userId)
				return
			end
		end

		local reputationConfig = self.Config.ReputationBypass
		if reputationConfig.Enable and crEnabled then
			local canUse,current = cr:UseCommunityReputation(_player,reputationConfig.Limit,0)
			if canUse then
				self:Notify(_player,string.format("你可以于聊天框输入!rep_join,使用[%s信誉点]获得本场越位特权(当前有%d点).",reputationConfig.Cost,current),priorColorTable)
			end
		end
	end


	if errorString then
		self:Notify(_player, errorString,errorColorTable)
	end

	return false
end

local function PlaytimeBypassValidate(self,_player)
	if not _player or _player:GetIsVirtual() then return end
	if _player:GetPlayTime() < self.Config.PlayTimeBypass then return end

	local userId = _player:GetClient():GetUserId()
	if table.contains(kTeamRejoinTracker,userId) then return end
	table.insert(kTeamRejoinTracker,userId)
end

--function Plugin:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force )
--	PlaytimeBypassValidate(self,Player)
--end

function Plugin:ClientDisconnect( _client )
	PlaytimeBypassValidate(self,_client:GetControllingPlayer())
end

function Plugin:OnEndGame(_winningTeam)
	table.Empty(kTeamJoinTracker)
	table.Empty(kTeamRejoinTracker)
end

local function RestrictionDisplay(self,_client)
	local skillLimitMin = self.Constrains.SkillRange[1]
	local skillLimitMax = self.Constrains.SkillRange[2] < 0 and "∞" or tostring(self.Constrains.SkillRange[2])
	local playerLimitExtend = GetForceJoinLimit(self.Constrains.TeamForceJoin)
	--local hourLimitMin = self.Constrains.MinHour
	--local hourLimitMax = self.Constrains.MaxHour < 0  and "∞" or tostring(self.Constrains.MaxHour)
	self:Notify(_client,string.format("队伍容量:陆战队:%s,卡拉异形:%s,入场通道:%s\n分数限制:[%s - %s]%s.",
			self.Constrains.Team[1], self.Constrains.Team[2],
			playerLimitExtend,
			skillLimitMin,skillLimitMax,
			self.Constrains.Mode == Plugin.SkillLimitMode.NONE and "" or "动态新兵"
	),self.Config.MessageNameColor,nil)
end

function Plugin:ClientConfirmConnect( Client )
	if Client:GetIsVirtual() then return end

	local player = Client:GetControllingPlayer()
	--if not self:GetPlayerRestricted(player) then
	--	RestrictionDisplay(self,Client)
	--end

	local userId = Client:GetUserId()
	if table.contains(kTeamRejoinTracker,userId) then
		self:Notify(player, "检测到异常离开,已启用[异常离开补位通道],可加入当前战局.",priorColorTable,nil)
	end
end

function Plugin:CreateCommands()

	local function NotifyClient(_client)
		RestrictionDisplay(self,_client:GetControllingPlayer())
	end
	
	local function NofityAll()
		for client in Shine.IterateClients() do
			NotifyClient(client)
		end
	end
	
	self:BindCommand( "sh_restriction", "restriction", NotifyClient , true) 
	:Help( "示例: !restriction 传回当前的队伍限制" )

	local function NotifyClientDebug(_client)
		local skillLimitMin = self.Constrains.SkillRange[1]
		local skillLimitMax = self.Constrains.SkillRange[2] < 0 and "∞" or tostring(self.Constrains.SkillRange[2])
		self:Notify(_client,string.format("当前设置:陆战队:%s,卡拉异形:%s\n分数限制:[%s - %s]%s.\n覆盖模式:%s,额外人数:%s,观战限制:%s",
				self.Constrains.Team[1], self.Constrains.Team[2],
				skillLimitMin,skillLimitMax,
				self.Constrains.Mode == Plugin.SkillLimitMode.NONE and "" or "动态新兵",
				self.Constrains.IsOverride,
				self.Constrains.TeamForceJoin,
				self.Constrains.BlockSpectators
		),self.Config.MessageNameColor)
	end

	self:BindCommand( "sh_restriction_debug", "restriction_debug", NotifyClientDebug)
		:Help( "示例: !restriction_debug 传回服务器的额外设置" )
	
	local function SetTeamSize(_client, _team1, _team2)
		self.Constrains.Team[kTeam1Index] = _team1
		self.Constrains.Team[kTeam2Index] = _team2

		local RRQPlugin = Shine.Plugins["readyroomqueue"]
		if RRQPlugin and RRQPlugin.Enabled then
			RRQPlugin:Pop()
		end

		NofityAll()
	end
	
	self:BindCommand( "sh_restriction_size", "restriction_size", SetTeamSize)								 
	:AddParam{ Type = "number", Round = true, Min = 0, Max = 28, Default = 0 }
	:AddParam{ Type = "number", Round = true, Min = 0, Max = 28, Default = 0 }
	:Help( "示例: !restriction_size 14 12 true. 将服务器的队伍人数上限设置为,队伍一(陆战队):14人,队伍二(卡拉):12人 并保存" )

	--local function SetHourLimit(_client, _min,_max,_save)
	--	self.Config.Constrains.Mode = Plugin.SkillLimitMode.NONE
	--	self.Constrains.MinHour = _min
	--	self.Constrains.MaxHour = _max
	--
	--	NofityAll()
	--end
	--self:BindCommand( "sh_restriction_hour", "restriction_hour", SetHourLimit)
	--:AddParam{ Type = "number", Round = true, Min = -1, Default = -1 }
	--:AddParam{ Type = "number", Round = true, Min = -1, Default = -1 , Optional = true}
	--:Help( "示例: !restriction_skill 10 -1 true.将服务器的入场小时数设置为,[1000-∞],并且保存,-1代表无限制" )
	
	local function SetSkillLimit(_client, _min,_max)
		self.Constrains.Mode = Plugin.SkillLimitMode.NONE
		self.Constrains.SkillRange = {_min,_max}

		NofityAll()
	end
	self:BindCommand( "sh_restriction_skill", "restriction_skill", SetSkillLimit)
	:AddParam{ Type = "number", Round = true, Min = -1, Default = -1 }
	:AddParam{ Type = "number", Round = true, Min = -1, Default = -1 , Optional = true}
	:Help( "示例: !restriction_skill 1000 -1 true.将服务器的入场分数设置为,[10-∞],并且保存,-1代表无限制" )
	
	local function RepJoin(_client)
		local crEnabled, cr = Shine:IsExtensionEnabled( "communityrank" )
		if not crEnabled then return end
		
		local reputationConfig = self.Config.ReputationBypass
		if cr:UseCommunityReputation(_client:GetControllingPlayer(),reputationConfig.Limit,reputationConfig.Cost) then
			table.insert(kTeamJoinTracker,_client:GetUserId())
			self:Notify(_client,string.format("已使用[%s信誉点],获得当局入场特权!",reputationConfig.Cost),priorColorTable)
		end
	end
	self:BindCommand( "sh_rep_join", "rep_join", RepJoin,true)
		:Help( "使用信誉点获得游戏加入特权" )
end


--Restrict teams also at voterandom
function Plugin:PreShuffleOptimiseTeams ( TeamMembers )
	local Gamerules = GetGamerules()
	local team1Max = Gamerules:GetTeam(kTeam1Index):GetNumPlayers()
	local team2Max = Gamerules:GetTeam(kTeam2Index):GetNumPlayers()
	local maxPlayer = math.max( team1Max, team2Max )

	for i = 1, 2 do
		local teamRestriction = self.Constrains.Team[i]
		local teamMaxPlayer = math.max( teamRestriction, maxPlayer )
		for j = #TeamMembers[i], teamMaxPlayer + 1, -1 do
			pcall( Gamerules.JoinTeam, Gamerules, TeamMembers[i][j], kTeamReadyRoom, nil, true )				--Move player into the ready room
			TeamMembers[i][j] = nil
		end
	end
end

return Plugin