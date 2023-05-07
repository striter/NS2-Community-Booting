local Plugin = Shine.Plugin( ... )

Plugin.HasConfig = true
Plugin.ConfigName = "EnforceTeamSizes.json"
Plugin.PrintName = "Enforced Team Size"

--[[
--TeamNumbers:
 - 1: Marines
 - 2: Aliens
 - 3: Spec
 ]]
Plugin.DefaultConfig = {
	Team = { 14 , 14 , 5 },
	IncreaseByForceJoins = true,
	SkillLimitMin = -1,
	SkillLimitMax = -1,
	NewcomerForceJoin = -1,
	MessageNameColor = {0, 255, 0 },
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

Plugin.EnabledGamemodes = {
	[ "ns2" ] = true,
	[ "NS2.0" ] = true,
	[ "NS2.0beta" ] = true,
	[ "NS1.0" ] = true,
	[ 'siege+++' ] = true,
	[ 'GunGame' ] = true,
	[ 'Combat' ] = true,
}

do
	local Validator = Shine.Validator()
	Validator:AddFieldRule( "Team",  Validator.IsType( "table", {} ))
	Validator:AddFieldRule( "IncreaseByForceJoins",  Validator.IsType( "boolean", true ))
	Validator:AddFieldRule( "SkillLimitMin",  Validator.IsType( "number", -1 ))
	Validator:AddFieldRule( "SkillLimitMax",  Validator.IsType( "number", -1 ))
	Validator:AddFieldRule( "NewcomerForceJoin",  Validator.IsType( "number", -1 ))
	Validator:AddFieldRule( "MessageNameColor",  Validator.IsType( "table", {0,255,0} ))
	Plugin.ConfigValidator = Validator
end

local priorColorTable = { 235, 152, 78 }
local errorColorTable = { 236, 112, 99 }

function Plugin:Initialise()
	self.Enabled = true
	self:CreateCommands()
	Shine.Hook.SetupClassHook("NS2Gamerules", "EndGame", "OnEndGame", "PassivePost")
	return true
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
	if self.Config.IncreaseByForceJoins then
		local maxPlayers = math.max(self:GetNumPlayers(Gamerules:GetTeam(kTeam1Index)),self:GetNumPlayers(Gamerules:GetTeam(kTeam2Index)))
		playerLimit = math.max(playerLimit,maxPlayers)
	end
	return playerLimit
end

function Plugin:GetMaxPlayers(_gamerules)
	return self:GetPlayerLimit(_gamerules,kTeam1Index) + self:GetPlayerLimit(_gamerules,kTeam2Index)
end

function Plugin:GetSkillLimited(_player)
	local skill = _player:GetPlayerSkill()
	local skillLimited = false
	skillLimited = skillLimited or (skill < self.Config.SkillLimitMin)
	if self.Config.SkillLimitMax >= 0 then
		skillLimited = skillLimited or skill >= self.Config.SkillLimitMax
	end
	
	if skillLimited then
		self:Notify(_player, string.format("您的分数(%i)不在服务器限制内(%s-%s),请继续观战或加入其他服务器.",
				skill,self.Config.SkillLimitMin,self.Config.SkillLimitMax < 0 and "∞" or self.Config.SkillLimitMax),
				errorColorTable,nil)

		if _player:GetTeamNumber() ~= kSpectatorIndex then
			local gamerules = GetGamerules()
			if gamerules then gamerules:JoinTeam( _player, kSpectatorIndex, true,true ) end
		end
	end
	
	return skillLimited
end

local kJoinTracker = { }
local TeamNames = { "陆战队","卡拉异形","观战" }
function Plugin:JoinTeam(_gamerules, _player, _newTeam, _, _shineForce)
	if _shineForce then return end
	if _player:GetIsVirtual() then return end
	local skillLimited = self:GetSkillLimited(_player)
	if _newTeam == kTeamReadyRoom then 
		if skillLimited then return false end
		return
	end
	
	local playerLimit = self:GetPlayerLimit(_gamerules, _newTeam)
	local playerLimited = self:GetNumPlayers(_gamerules:GetTeam(_newTeam)) >= playerLimit
	if _newTeam == kSpectatorIndex then
		if playerLimited then
			self:Notify(_player,string.format( "[%s]人数已满(>=%s),请进入游戏或加入有观战位的服务器.", TeamNames[_newTeam] ,playerLimit),errorColorTable,nil)
			return false
		end
		return 
	end

	local available = true
	--Check if team is above MaxPlayers
	if playerLimited then
		self:Notify(_player,string.format( "[%s]人数已满(>=%s),请继续观战,等待空位或加入有空位的服务器.", TeamNames[_newTeam] ,playerLimit),errorColorTable,nil)
		available = false
	end

	if available == false then
		local client = Server.GetOwner(_player)
		if not client or client:GetIsVirtual()  then return end

		if Shine:HasAccess( client, "sh_priorslot" ) then
			self:Notify(_player, "您为 [高级预留玩家],已忽视限制加入!",priorColorTable,nil)
			return
		end

		if self.Config.NewcomerForceJoin ~= -1 and skill < self.Config.NewcomerForceJoin then
			self:Notify(_player, "您为 [新人优待玩家],已忽视限制加入!",priorColorTable,nil)
			return
		end

		local cpEnabled, cp = Shine:IsExtensionEnabled( "communityprewarm" )
		if cpEnabled then
			local userId = client:GetUserId()
			if table.contains(kJoinTracker,userId) and cp:GetPrewarmPrivilege(client,0,"本局自由下场") then return end
			if cp:GetPrewarmPrivilege(client,1,"自由下场") then table.insert(kJoinTracker,userId) return end
		end
	end
	
	if available then return end
	return false
end

function Plugin:OnEndGame(_winningTeam)
	table.Empty(kJoinTracker)
end

local function RestrictionDisplay(self,_client)
	local skillLimitMin = self.Config.SkillLimitMin
	local skillLimitMax = self.Config.SkillLimitMax < 0 and "∞" or tostring(self.Config.SkillLimitMax)

	self:Notify(_client,string.format("当前加入限制:陆战队:%s,卡拉异形:%s 分数限制:(%s至%s)", self.Config.Team[1], self.Config.Team[2],skillLimitMin,skillLimitMax),self.Config.MessageNameColor,nil)
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

	local function SetSpectatorSize(_client, _size,_save)
		self.Config.Team[kSpectatorIndex] = _size
		if _save then self:SaveConfig() end
	end

	self:BindCommand( "sh_restriction_specsize", "restriction_specsize", SetSpectatorSize)
	:AddParam{ Type = "number", Round = true, Min = 0, Max = 28, Default = -1 }
	:AddParam{ Type = "boolean", Default = false, Help = "true = 保存设置", Optional = true  }
	:Help( "示例: !restriction_size 14 12 true. 将服务器的队伍人数上限设置为,队伍一(陆战队):14人,队伍二(卡拉):12人 并保存" )
	
	local function SetSkillLimit(_client, _min,_max,_save)
		self.Config.SkillLimitMin = _min
		self.Config.SkillLimitMax = _max

		NofityAll()
		if _save then self:SaveConfig() end
	end
	local skillCommand = self:BindCommand( "sh_restriction_skill", "restriction_skill", SetSkillLimit)
	skillCommand:AddParam{ Type = "number", Round = true, Min = -1, Default = -1 }
	skillCommand:AddParam{ Type = "number", Round = true, Min = -1, Default = -1 , Optional = true}
	skillCommand:AddParam{ Type = "boolean", Default = false, Help = "true = 保存设置", Optional = true  }
	skillCommand:Help( "示例: !restriction_skill 1000 -1 true.将服务器的入场分数设置为,[1000-∞],并且保存,-1代表无限制" )
end

function Plugin:ClientConfirmConnect( Client )
	if Client:GetIsVirtual() then return end
	RestrictionDisplay(self,Client)
end

--Restrict teams also at voterandom
function Plugin:PreShuffleOptimiseTeams ( TeamMembers )
	local  Gamerules = GetGamerules()
	local team1Max = Gamerules:GetTeam(kTeam1Index):GetNumPlayers()
	local team2Max = Gamerules:GetTeam(kTeam2Index):GetNumPlayers()
	local maxPlayer = math.max( team1Max, team2Max )

	for i = 1, 2 do
		local teamRestriction = self.Config.Team[i]
		local teamMaxPlayer = math.max( teamRestriction, maxPlayer )
		for j = #TeamMembers[i], teamMaxPlayer + 1, -1 do
			pcall( Gamerules.JoinTeam, Gamerules, TeamMembers[i][j], kTeamReadyRoom, nil, true )				--Move player into the ready room
			TeamMembers[i][j] = nil				--remove the player's entry in the table
		end
	end
end

return Plugin