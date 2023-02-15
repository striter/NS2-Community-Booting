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
	Team = { 14 , 14},
	SkillLimit = -1,
	MessageNameColor = {0, 255, 0 },
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

Plugin.EnabledGamemodes = {
	[ "ns2" ] = true,
	[ "NS2.0" ] = true,
	[ 'siege+++' ] = true,
	[ 'GunGame' ] =true,
}

local priorColorTable = { 237, 187, 153  }

function Plugin:Initialise()
	self.Enabled = true
	self:CreateCommands()
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


local TeamNames = { "陆战队","卡拉异形" }
function Plugin:JoinTeam( Gamerules, Player, NewTeam, _, ShineForce )
	if ShineForce or NewTeam == kTeamReadyRoom or NewTeam == kSpectatorIndex then return end
	if self.Config.IgnoreBots and Player:GetIsVirtual() then return end

	
	local skill = Player:GetPlayerSkill()
	
	local available
	
	if self.Config.SkillLimit ~= -1 and skill > self.Config.SkillLimit  then
		self:Notify(Player, string.format("您的分数(%s)以超过服务器上限(%s),请继续观战或加入其他服务器.", skill, self.Config.SkillLimit),self.Config.MessageNameColor,nil)
		available = false
	end
	
	--Check if team is above MaxPlayers
	local playerLimit = self.Config.Team[NewTeam]
	if self:GetNumPlayers(Gamerules:GetTeam(NewTeam)) >= playerLimit then
		self:Notify(Player,string.format( "[%s]人数已满(>=%s),请继续观战,等待空位或加入有空位的服务器.", TeamNames[NewTeam] ,playerLimit),self.Config.MessageNameColor,nil)
		available = false
	end

	if available == false then
		local client = Server.GetOwner(Player)
		if not client or client:GetIsVirtual()  then return end
		if Shine:HasAccess( client, "sh_priorslot" ) then
			self:Notify(Player, string.format("因为您为升级预留位玩家,已忽视限制加入游戏,请勿[过度影响]其他玩家的正常对局.", skill, self.Config.SkillLimit),priorColorTable,nil)
			return
		end
	end
	
	return available
end

function Plugin:CreateCommands()

	local function RestrictionDisplay(_client)
		local skillLimit = self.Config.SkillLimit == -1 and "无限制" or tostring(self.Config.SkillLimit)
		self:Notify(_client,string.format("当前加入限制为:[陆战队]:%s,[卡拉异形]:%s,[最高分数](%s)", self.Config.Team[1], self.Config.Team[2],skillLimit),self.Config.MessageNameColor,nil)
	end
	local showRestriction = self:BindCommand( "sh_restriction", "restriction", RestrictionDisplay)
	showRestriction:Help( "示例: !restriction 传回当前的队伍限制" )
	
	local function NofityAll()
		for client in Shine.IterateClients() do
			RestrictionDisplay(client:GetControllingPlayer())
		end
	end
	local function SetTeamSize(_client, _team1, _team2,_save)
		self.Config.Team[kTeam1Index] = _team1
		self.Config.Team[kTeam2Index] = _team2

		NofityAll()
		if _save then
			self:SaveConfig()
		end
	end
	local teamsizeCommand = self:BindCommand( "sh_restriction_size", "restriction_size", SetTeamSize)
	teamsizeCommand:AddParam{ Type = "number", Round = true, Min = 0, Max = 28, Default = 10 }
	teamsizeCommand:AddParam{ Type = "number", Round = true, Min = 0, Max = 28, Default = 10 }
	teamsizeCommand:AddParam{ Type = "boolean", Default = false, Help = "true = 保存设置", Optional = true  }
	teamsizeCommand:Help( "示例: !restriction_size 14 12. 将服务器的队伍人数上限设置为,队伍一(陆战队):14人,队伍二(卡拉):12人" )

	local function SetSkillLimit(_client, _skillLimit,_save)
		self.Config.SkillLimit = _skillLimit
		if _save then
			self:SaveConfig()
		end
		NofityAll()
	end
	local skillCommand = self:BindCommand( "sh_restriction_skill", "restriction_skill", SetSkillLimit)
	skillCommand:AddParam{ Type = "number", Round = true, Min = -1, Max = 99999, Default = -1 }
	skillCommand:AddParam{ Type = "boolean", Default = false, Help = "true = 保存设置", Optional = true  }
	skillCommand:Help( "示例: !restriction_skill 1000. 将服务器的分数上限设置为,最大分数(-1为全部通过):1000" )
end


--Restrict teams also at voterandom
function Plugin:PreShuffleOptimiseTeams ( TeamMembers )
	local  Gamerules = GetGamerules()
	local team1Max = self.Config.Team[1] or 1000
	local team2Max = self.Config.Team[2] or 1000
	local maxPlayer = math.min( team1Max, team2Max )
	
	if maxPlayer == 1000 then return end

	for i = 1, 2 do
		for j = #TeamMembers[i], maxPlayer + 1, -1 do
			--Move player into the ready room
			pcall( Gamerules.JoinTeam, Gamerules, TeamMembers[i][j], kTeamReadyRoom, nil, true )
			--remove the player's entry in the table
			TeamMembers[i][j] = nil
		end
	end
end

return Plugin