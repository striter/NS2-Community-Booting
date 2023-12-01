local Plugin = Shine.Plugin( ... )
Script.Load( "lua/shine/core/server/playerinfohub.lua" )

Plugin.HasConfig = true
Plugin.ConfigName = "EnforceTeamSizes.json"
Plugin.PrintName = "Enforced Team Size"

--[[
--TeamNumbers:
 - 1: Marines
 - 2: Aliens
 - 3: Spec
 ]]
Plugin.RestrictedOperation = table.AsEnum{
	"SPECTATOR", "KICK", "REDIRECT",
}

Plugin.SkillLimitMode = table.AsEnum{
	"NONE", "NOOB",
}

Plugin.DefaultConfig = {
	Team = { 12 , 12 , 5},
	TeamForceJoin = 3,
	SlotCoveringBegin = 15,
	BlockSpectators = true,
	Constrains = {
		Mode = Plugin.SkillLimitMode.NONE,
		MinPlayerCount = 16,
		Constant = {
			MinSkill = -1,
			MaxSkill = -1,
		}
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
		--Hour = 10,
	},
	MessageNameColor = {0, 255, 0 },
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

do
	local Validator = Shine.Validator()
	Validator:AddFieldRule( "Team",  Validator.IsType( "table", Plugin.DefaultConfig.Team ))
	Validator:AddFieldRule( "TeamForceJoin",  Validator.IsType( "number", Plugin.DefaultConfig.TeamForceJoin ))
	Validator:AddFieldRule( "SlotCoveringBegin",  Validator.IsType( "number", Plugin.DefaultConfig.SlotCoveringBegin ))
	Validator:AddFieldRule( "BlockSpectators",  Validator.IsType( "boolean", Plugin.DefaultConfig.BlockSpectators ))
	Validator:AddFieldRule( "RestrictedOperation", Validator.IsType( "table", Plugin.DefaultConfig.RestrictedOperation ) )
	Validator:AddFieldRule( "Constrains", Validator.IsType( "table", Plugin.DefaultConfig.Constrains ) )
	Validator:AddFieldRule( "Constrains.Constant", Validator.IsType( "table", Plugin.DefaultConfig.Constrains.Constant ) )

	Validator:AddFieldRule( "NewComerBypass",  Validator.IsType( "table", Plugin.DefaultConfig.NewComerBypass ))
	Validator:AddFieldRule( "MessageNameColor",  Validator.IsType( "table", {0,255,0} ))

	Plugin.ConfigValidator = Validator
end

local priorColorTable = { 235, 152, 78 }
local errorColorTable = { 236, 112, 99 }

local kTeamJoinTracker = { }
local kRestrictionJoinTracker = {}

function Plugin:Initialise()
	self.Enabled = true

	self.Constrains = {
		Mode = self.Config.Constrains.Mode,
		MinSkill = self.Config.Constrains.Constant.MinSkill,
		MaxSkill = self.Config.Constrains.Constant.MaxSkill,
		--MinHour = -1,
		--MaxHour = -1,
	}
	self:CreateCommands()
	Shine.Hook.SetupClassHook("NS2Gamerules", "EndGame", "OnEndGame", "PassivePost")
	return true
end

function Plugin:OnFirstThink()
	self.Timer = self:SimpleTimer( 45, function()
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
	local playerLimit = self.Config.Team[Team]
	if Shared.GetTime() > self.Config.SlotCoveringBegin * 60 then
		local maxPlayers = math.max(self:GetNumPlayers(Gamerules:GetTeam(kTeam1Index)),self:GetNumPlayers(Gamerules:GetTeam(kTeam2Index)))
		playerLimit = math.max(playerLimit,maxPlayers)
	end

	if Team == kSpectatorIndex and self.Config.BlockSpectators then
		local leastPlayersInGame = self.Config.Team[kTeam1Index] + self.Config.Team[kTeam2Index]
		local inServerPlayers = Shine.GetHumanPlayerCount()
		if inServerPlayers < leastPlayersInGame then return 99 end 	--They are seeding
		return inServerPlayers - leastPlayersInGame	--Join the game little f**k
	end
	
	return playerLimit
end

function Plugin:RedirectClient(client)
	local message = {ip = self.Config.RestrictedOperation.RedirectIP}
	Server.SendNetworkMessage(client,"Redirect",message, true)
end

function Plugin:OnPlayerRestricted(_player,_newTeam)
	local client = _player:GetClient()

	local clientId = client:GetUserId()
	local cpEnabled, cp = Shine:IsExtensionEnabled( "communityprewarm" )
	if cpEnabled then
		if cp:GetPrewarmPrivilege(client,1,"预热越限通道") then
			self:Notify(_player,"您为今日预热玩家,可以越过限制下场,请勿利用该特权做出不符合规范的行为!.",errorColorTable)
			table.insert(kTeamJoinTracker,clientId)
			return false
		end
		
		if table.contains(kTeamJoinTracker,clientId) and cp:GetPrewarmPrivilege(client,0,"预热越限通道") then return false end
	end

	if Shine:HasAccess(client, "sh_adminmenu" ) then
		self:Notify(_player,"检测到您为管理员,请引导玩家前往合适的场所进行游玩(切勿炸鱼)!",errorColorTable)
		return false
	end
	
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

	local config = self.Config.Constrains
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
			if skill > self.Constrains.MinSkill then
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
		local validateClientCount = config.MinPlayerCount -- - connectingClientCount
		local finalValue = clientSkillTable[math.min(#clientSkillTable, validateClientCount)].skill
	
		self.Constrains.MaxSkill = math.max(self.Config.Constrains.Constant.MaxSkill,finalValue + 1)
	end
		
	self.Timer = self:SimpleTimer( 5, function()
		self:UpdateConstrains()
	end )
end

function Plugin:GetPlayerSkillLimited(_player,_team)
	
	local skill = math.max(_player:GetPlayerSkill(),0)
	local skillLimited = skill < self.Constrains.MinSkill
	if self.Constrains.MaxSkill > 0 then
		skillLimited = skillLimited or skill > self.Constrains.MaxSkill
	end
	
	return skillLimited,skill
end

function Plugin:GetPlayerRestricted(_player,_team)
	local skillLimited, finalSkill =  self:GetPlayerSkillLimited(_player,_team)
	if skillLimited then
		self:Notify(_player, string.format("您的平均分数(%i)不在服务器限制范围内(%s-%s).",
				finalSkill,self.Constrains.MinSkill,self.Constrains.MaxSkill < 0 and "∞" or self.Constrains.MaxSkill),
				errorColorTable,nil)
		return self:OnPlayerRestricted(_player,_team)
	end

	--local hour = Shine.PlayerInfoHub:GetSteamData(_player:GetClient():GetUserId()).PlayTime
	--local hourLimited = false
	--if self.Config.HourLimitMin > 0 then
	--	hourLimited = hourLimited or hour <= self.Constrains.MinHour
	--end
	--if self.Constrains.MaxHour > 0 then
	--	hourLimited = hourLimited or hour >= self.Constrains.MaxHour
	--end
	--
	--if hourLimited then
	--	self:Notify(_player, string.format("您的游戏时长(%i)不在服务器限制内(%s-%s).",
	--			hour,self.Constrains.MinHour,self.Constrains.MaxHour < 0 and "∞" or self.Constrains.MaxHour),
	--			errorColorTable,nil)
	--	return self:OnPlayerRestricted(_player,_team)
	--end

	return false
end

local TeamNames = { "陆战队","卡拉异形","观战" }
function Plugin:JoinTeam(_gamerules, _player, _newTeam, _, _shineForce)
	if _shineForce then return end
	if _player:GetIsVirtual() then return end
	if _newTeam == kTeamReadyRoom then 
		if self:GetPlayerRestricted(_player,_newTeam) then return false end
		return
	end

	local available = not self:GetPlayerRestricted(_player)
	local playerNum = self:GetNumPlayers(_gamerules:GetTeam(_newTeam))
	local playerLimit = self:GetPlayerLimit(_gamerules, _newTeam)
	local playerLimited = playerNum >= playerLimit
	local forcePrivilegeTitle
	local forceCredit
	local couldBeIgnored = true
	local teamName = TeamNames[_newTeam]
	if _newTeam == kSpectatorIndex then
		if playerLimited then
			self:Notify(_player,string.format( "[%s]人数已满(>=%s),请尽快进入游戏!", teamName ,playerLimit),errorColorTable)
			available =  false
			forceCredit = 0
			forcePrivilegeTitle = "预热观战位"
		end
	else
		if playerLimited then
			local forceJoinLimit = playerLimit + self.Config.TeamForceJoin
			if playerNum >= forceJoinLimit then
				self:Notify(_player,string.format( "[%s]已爆满(>=%s),无法再增加任何玩家,请继续观战,等待空位/分服或加入有空位的服务器.", teamName ,forceJoinLimit),errorColorTable)
				couldBeIgnored = false
			else
				self:Notify(_player,string.format( "[%s]人数已满(>=%s),请继续观战,等待空位/分服或加入有空位的服务器.", teamName ,playerLimit),errorColorTable)
			end 
			available = false
			forceCredit = 1
			forcePrivilegeTitle = "预热入场通道"
		end
		
	end

	if available then return end
	
	local client = Server.GetOwner(_player)
	if not client or client:GetIsVirtual()  then return end

	if not couldBeIgnored then return false end

	--Accesses
	if Shine:HasAccess( client, "sh_priorslot" ) then
		self:Notify(_player, "您为[高级预留玩家],已忽视上述限制!",priorColorTable,nil)
		return
	end

	local userId = client:GetUserId()
	local newComerConfig = self.Config.NewComerBypass
	if newComerConfig.Enable then
		local isNewcomer = newComerConfig.Skill <= 0 or _player:GetPlayerSkill() < newComerConfig.Skill
		--local steamData = Shine.PlayerInfoHub:GetSteamData(userId)
		--isNewcomer = isNewcomer and  (newComerConfig.Hour <= 0 or steamData.PlayTime < newComerConfig.Hour)
		if isNewcomer then
			self:Notify(_player, "您为[新人优待玩家],已忽视上述限制!",priorColorTable,nil)
			return
		end
	end
	
	local cpEnabled, cp = Shine:IsExtensionEnabled( "communityprewarm" )
	if cpEnabled then
		if table.contains(kTeamJoinTracker,userId) and cp:GetPrewarmPrivilege(client,0,"当局入场通道") then return end

		if cp:GetPrewarmPrivilege(client,forceCredit,forcePrivilegeTitle) then
			if forceCredit > 0 then table.insert(kTeamJoinTracker,userId) end
			return
		end
	end
	
	return false
end

function Plugin:OnEndGame(_winningTeam)
	table.Empty(kTeamJoinTracker)
	table.Empty(kRestrictionJoinTracker)
end

local function RestrictionDisplay(self,_client)
	local skillLimitMin = self.Constrains.MinSkill
	local skillLimitMax = self.Constrains.MaxSkill < 0 and "∞" or tostring(self.Constrains.MaxSkill)
	--local hourLimitMin = self.Constrains.MinHour
	--local hourLimitMax = self.Constrains.MaxHour < 0  and "∞" or tostring(self.Constrains.MaxHour)
	local addition = self.Constrains.Mode == Plugin.SkillLimitMode.NONE and "" or "动态新兵"
	self:Notify(_client,string.format("当前人数限制:陆战队:%s,卡拉异形:%s\n分数限制:[%s - %s]%s.", 
			self.Config.Team[1], self.Config.Team[2],
			skillLimitMin,skillLimitMax,
			addition
	),self.Config.MessageNameColor,nil)
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
	
	local showRestriction = self:BindCommand( "sh_restriction", "restriction", NotifyClient , true) 
	showRestriction:Help( "示例: !restriction 传回当前的队伍限制" )
	
	local function SetTeamSize(_client, _team1, _team2,_save)
		self.Config.Team[kTeam1Index] = _team1
		self.Config.Team[kTeam2Index] = _team2

		local RRQPlugin = Shine.Plugins["readyroomqueue"]
		if RRQPlugin and RRQPlugin.Enabled then
			RRQPlugin:Pop()
		end

		NofityAll()
		if _save then self:SaveConfig() end
	end
	
	self:BindCommand( "sh_restriction_size", "restriction_size", SetTeamSize)								 
	:AddParam{ Type = "number", Round = true, Min = 0, Max = 28, Default = 0 }
	:AddParam{ Type = "number", Round = true, Min = 0, Max = 28, Default = 0 }
	:AddParam{ Type = "boolean", Default = false, Help = "true = 保存设置", Optional = true  }
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
		self.Constrains.MinSkill = _min
		self.Constrains.MaxSkill = _max

		NofityAll()
	end
	self:BindCommand( "sh_restriction_skill", "restriction_skill", SetSkillLimit)
	:AddParam{ Type = "number", Round = true, Min = -1, Default = -1 }
	:AddParam{ Type = "number", Round = true, Min = -1, Default = -1 , Optional = true}
	:Help( "示例: !restriction_skill 1000 -1 true.将服务器的入场分数设置为,[10-∞],并且保存,-1代表无限制" )
end

function Plugin:ClientConfirmConnect( Client )
	if Client:GetIsVirtual() then return end
	
	if not self:GetPlayerRestricted(Client:GetControllingPlayer()) then
		RestrictionDisplay(self,Client)
	end
end

--Restrict teams also at voterandom
function Plugin:PreShuffleOptimiseTeams ( TeamMembers )
	local Gamerules = GetGamerules()
	local team1Max = Gamerules:GetTeam(kTeam1Index):GetNumPlayers()
	local team2Max = Gamerules:GetTeam(kTeam2Index):GetNumPlayers()
	local maxPlayer = math.max( team1Max, team2Max )

	for i = 1, 2 do
		local teamRestriction = self.Config.Team[i]
		local teamMaxPlayer = math.max( teamRestriction, maxPlayer )
		for j = #TeamMembers[i], teamMaxPlayer + 1, -1 do
			pcall( Gamerules.JoinTeam, Gamerules, TeamMembers[i][j], kTeamReadyRoom, nil, true )				--Move player into the ready room
			TeamMembers[i][j] = nil
		end
	end
end

return Plugin