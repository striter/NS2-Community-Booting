local Shine = Shine
local StringMatch = string.match
local tonumber = tonumber

local Plugin = ...
Plugin.Version = "1.0"

Plugin.HasConfig = true
Plugin.ConfigName = "ServerSwitchVote.json"

Plugin.DefaultConfig = {
	ClientVote = true,
	ConfigURL = "",
	CrowdAdvert = {
		NotifyTimer = 150,
		PlayerCount = 0,
		RedirUntil = 28,
		ResSlots = 32,
		ToServer = 0,
		ToServerDelay = 10,
		Prefix = "[病危通知书]",
		Message = "服务器要炸了",
		FailInformCount = 40,
		FailInformMessage = "距离自动换服还差%i人",
		SuccessfulInformMessage = "当前人数已满足条件(%i),当前对局结束后将尝试自动分服.",
		FailInformPrefix = "[换服提示]",
	},
}

Plugin.CheckConfigTypes = true
do

local Validator = Shine.Validator()
local BitLShift = bit.lshift
local select = select

local function IPToInt( ... )
	if not ... then return nil end

	for i = 1, 4 do
		if tonumber( select( i, ... ), 10 ) > 255 then
			return -1
		end
	end

	local Byte1, Byte2, Byte3, Byte4 = ...

	-- Not using lshift for the first byte to avoid getting a signed int back.
	return tonumber( Byte1, 10 ) * 16777216 +
		BitLShift( tonumber( Byte2, 10 ), 16 ) +
		BitLShift( tonumber( Byte3, 10 ), 8 ) +
		tonumber( Byte4, 10 )
end

local function IsValidIPAddress( IP )
	if IP <= 0 then
		return false
	end

	-- 255.255.255.255 or higher.
	if IP >= 0xFFFFFFFF then
		return false
	end

	-- 127.x.x.x
	if IP >= 0x7F000000 and IP <= 0x7FFFFFFF then
		return false
	end

	-- 10.x.x.x
	if IP >= 0x0A000000 and IP <= 0x0AFFFFFF then
		return false
	end

	-- 172.16.0.0 - 172.31.255.255
	if IP >= 0xAC100000 and IP <= 0xAC1FFFFF then
		return false
	end

	-- 192.168.x.x
	if IP >= 0xC0A80000 and IP <= 0xC0A8FFFF then
		return false
	end

	return true
end

	Plugin.ConfigValidator = Validator
	Validator:AddFieldRule( "ConfigURL",  Validator.IsType( "string", Plugin.DefaultConfig.ConfigURL ))
	Validator:AddFieldRule( "ClientVote",  Validator.IsType( "boolean", Plugin.DefaultConfig.ClientVote ))
	Validator:AddFieldRule( "CrowdAdvert",  Validator.IsType( "table", Plugin.DefaultConfig.CrowdAdvert ))
	Validator:AddFieldRule( "CrowdAdvert.NotifyTimer",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.NotifyTimer ))
	Validator:AddFieldRule( "CrowdAdvert.PlayerCount",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.PlayerCount ))
	Validator:AddFieldRule( "CrowdAdvert.RedirUntil",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.RedirUntil ))
	Validator:AddFieldRule( "CrowdAdvert.ResSlots",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.ResSlots ))
	Validator:AddFieldRule( "CrowdAdvert.Prefix",  Validator.IsType( "string", Plugin.DefaultConfig.CrowdAdvert.Prefix ))
	Validator:AddFieldRule( "CrowdAdvert.ToServer",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.ToServer ))
	Validator:AddFieldRule( "CrowdAdvert.ToServerDelay",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.ToServerDelay ))
	Validator:AddFieldRule( "CrowdAdvert.Message",  Validator.IsType( "string", Plugin.DefaultConfig.CrowdAdvert.Message ))
	Validator:AddFieldRule( "CrowdAdvert.FailInformPrefix",  Validator.IsType( "string", Plugin.DefaultConfig.CrowdAdvert.FailInformPrefix ))
	Validator:AddFieldRule( "CrowdAdvert.FailInformMessage",  Validator.IsType( "string", Plugin.DefaultConfig.CrowdAdvert.FailInformMessage ))
	Validator:AddFieldRule( "CrowdAdvert.SuccessfulInformMessage",  Validator.IsType( "string", Plugin.DefaultConfig.CrowdAdvert.SuccessfulInformMessage ))
	Validator:AddFieldRule( "CrowdAdvert.FailInformCount",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.FailInformCount ))
end

local function NotifyCrowdAdvert(self, _message)
	Shine:NotifyDualColour(Shine.GetAllClients(),146, 43, 33,self.Config.CrowdAdvert.Prefix,
			253, 237, 236, _message)
end

function Plugin:Initialise()
	self.Enabled = true
	self:CreateCommands()
	return true
end


function Plugin:RedirectClient(_client, _address)
	Server.SendNetworkMessage(_client, "Redirect",{ ip = _address }, true)
end

function Plugin:RedirClients(_targetIP,_count,_newcomer)
	local clients = {}
	for Client in Shine.IterateClients() do
		local player = Client:GetControllingPlayer()
		if player then
			table.insert(clients,{
				client = Client,
				priority = math.max(player:GetPlayerSkill() , player:GetCommanderSkill()),
			})
		end
	end

	table.sort(clients,function (a, b)
		if _newcomer then
			return a.priority < b.priority
		else
			return a.priority > b.priority
		end
	end)

	local count = _count
	for _,data in pairs(clients) do
		local client =  data.client
		if Shine:HasAccess(client, "sh_host" ) then
			Shine:NotifyDualColour(client,146, 43, 33,"[注意]",
					253, 237, 236, "检测到[管理员]身份,已跳过强制换服,请在做好换服准备(如关门/锁观战)后前往预期服务器.")
		else
			self:RedirectClient(client,_targetIP)
			count = count - 1
		end

		if count <= 0 then
			break
		end
	end
end

function Plugin:OnFirstThink()
	self:SimpleTimer( self.Config.CrowdAdvert.NotifyTimer, function()
		self:NotifyCrowdRedirect()
	end )
end

local function NotifyRedirectProgression(self, _playerCount, _ignoreTeams)

	if _playerCount <= self.Config.CrowdAdvert.FailInformCount then return end

	local informMessage = _playerCount < self.Config.CrowdAdvert.PlayerCount 
						and string.format( self.Config.CrowdAdvert.FailInformMessage,self.Config.CrowdAdvert.PlayerCount - _playerCount)
						or string.format(self.Config.CrowdAdvert.SuccessfulInformMessage,self.Config.CrowdAdvert.PlayerCount)
	
	for client in Shine.IterateClients() do
		local team = client:GetControllingPlayer():GetTeamNumber()
		if _ignoreTeams or team == kSpectatorIndex or team == kTeamReadyRoom then
			Shine:NotifyDualColour(client,146, 43, 33,
					self.Config.CrowdAdvert.FailInformPrefix,
					253, 237, 236, informMessage)
		end
	end
end

function Plugin:NotifyCrowdRedirect()
	NotifyRedirectProgression(self,Shine.GetHumanPlayerCount(),false)		--Tells spectators/readyrooms
	self:SimpleTimer(self.Config.CrowdAdvert.NotifyTimer, function() self:NotifyCrowdRedirect() end )
end


function Plugin:OnMapVoteFinished()
	if self.Config.CrowdAdvert.ToServer <= 0 then return end
	if not self.PresetServers then return end
	local redirData = self.PresetServers[self.Config.CrowdAdvert.ToServer]
	if not redirData then return end

	local gameEndPlayerCount = Shine.GetHumanPlayerCount()
	if gameEndPlayerCount < self.Config.CrowdAdvert.PlayerCount then
		NotifyRedirectProgression(self,gameEndPlayerCount,false)		--Tells spectators/readyrooms
		return
	end

	local amount = gameEndPlayerCount - self.Config.CrowdAdvert.RedirUntil
	amount = amount > 0 and amount or gameEndPlayerCount / 2
	local delay = self.Config.CrowdAdvert.ToServerDelay
	NotifyCrowdAdvert(self,string.format( self.Config.CrowdAdvert.Message,delay,amount, redirData.Name))

	self.Timer = self:SimpleTimer(delay, function()
		local currentPlayerCount = Shine.GetHumanPlayerCount()
		if currentPlayerCount < self.Config.CrowdAdvert.PlayerCount then
			NotifyRedirectProgression(self,currentPlayerCount,true)		--Tells everyone
			return
		end

		if self.Config.CrowdAdvert.ResSlots > 0 then
			Shared.ConsoleCommand(string.format("sh_setresslots %i", self.Config.CrowdAdvert.ResSlots))
		end

		self:RedirClients(redirData.Address,amount,false)
	end )
end

function Plugin:ClientConfirmConnect(Client)
	if Client:GetIsVirtual() then return end
	self:QueryIfNeeded()
	self:ProcessClientVoteList( Client )
end

function Plugin:QueryIfNeeded()
	if self.Queried then return end
	self.Queried = true

	if self.Config.ConfigURL == "" then return end

	Shine.PlayerInfoHub:Query(self.Config.ConfigURL,function(response)
		if not response or #response == 0 then return end
		self.PresetServers = json.decode(response)
		for Client in Shine.IterateClients() do
			self:ClientConfirmConnect(Client)
		end
	end)
end

function Plugin:ProcessClientVoteList( Client )
	if not self.PresetServers then return end
	
	local valid = self.Config.ClientVote or Shine:HasAccess( Client, "sh_adminmenu" )
	if not valid then return end

	for i = 1, #self.PresetServers do
		local data = self.PresetServers[i]
		for _,amount in ipairs(data.Amount) do
			self:SendNetworkMessage( Client, "AddServerList", {
				ID = i,
				Name = data.Name  or "No Name",
				Address = data.Address,
				Amount = amount
			}, true )
		end
	end
end

function Plugin:CreateCommands()
	self.targetServer = nil
	
	--Set Target
	local function ServerTargetingList(_client)
		if not self.PresetServers then
			Shine:NotifyError(_client,"服务器预设列表未加载")
			return 
		end
		for k,v in pairs(self.PresetServers) do
			Shine:NotifyDualColour(_client,146, 43, 33,"[预设服务器]",
					253, 237, 236,string.format("%i %s %s",k,v.Name,v.Address))
		end
	end
	self:BindCommand( "sh_redir_verify_list", "redir_verify_list", ServerTargetingList)
			:Help("获取所有预设服务器的信息")
	
	local function ServerTargetingPreset(_client, _server)
		if not self.PresetServers then return end
		local data = self.PresetServers[_server]
		if not data then
			Shine:NotifyError(_client,"服务器" .. tostring(_server) .."不存在")
			return
		end
		
		self.targetServer = data.Address
		Shine:NotifyDualColour(_client,146, 43, 33,"[注意]",
				253, 237, 236,string.format("已设置目标服务器[%s]<%s>",data.Name,self.targetServer))
	end
	self:BindCommand( "sh_redir_verify", "redir_verify", ServerTargetingPreset)
		:AddParam{ Type = "number", Help = "目标服务器",Round = true, Min = 1, Max = 12, Default=1 }
		:Help("设置预设的目标服务器ID.例：!redir_verify 2")

	local function ServerTargeting(_client, _serverAddress)
		self.targetServer = _serverAddress
		Shine:NotifyDualColour(_client,146, 43, 33,"[注意]",253, 237, 236,string.format("已设置目标服务器<%s>",self.targetServer))
	end
	
	self:BindCommand( "sh_redir_verify_adv", "redir_verify_adv", ServerTargeting)
		:AddParam{ Type = "string", Help = "目标服务器IP与端口",Round = true, Min = 1, Max = 12, Default=1 }
		:Help("设置目标服务器IP(请留意服务器是否真实存在).例：!redir_verify 127.0.0.1:27015")

	--Redir to target
	local function RedirAddressCheck(_client)
		if self.targetServer == nil then
			Shine:NotifyCommandError( _client, "无目标服务器,请通过 redir_target 命令设置 " )
			return nil
		end

		return self.targetServer
	end
	
	 self:BindCommand( "sh_redir_player_newcomer", "redir_player_newcomer", function(_client,_count,_message)
		 local serverAddress = RedirAddressCheck(_client)
		 if serverAddress == nil then return end

		 NotifyCrowdAdvert(self,_message)
		 self:RedirClients(serverAddress,_count,true)
	end):
	AddParam{ Type = "number", Help = "迁移人数",Round = true, Min = 0, Max = 28, Default = 16 }:
	AddParam{ Type = "string", Help = "显示消息",Optional = true, Default = "服务器人满为患,开启被动分服." }:
	Help( "示例: !redir_newcomer 20. 迁移[20]名<新屁股>去[预设置好的服务器]" )
	
	self:BindCommand( "sh_redir_player_oldass", "redir_player_oldass", function(_client,_count,_message)
		local serverAddress = RedirAddressCheck(_client)
		if serverAddress == nil then return end
		
		NotifyCrowdAdvert(self,_message)
		self:RedirClients(serverAddress,_count,false)
	end):
	AddParam{ Type = "number", Help = "迁移人数",Round = true, Min = 0, Max = 28, Default = 16 }:
	AddParam{ Type = "string", Help = "显示消息",Optional = true,  Default = "服务器已人满为患,开启被动分服." }:
	Help( "示例: !redir_oldass 20. 迁移[20]名<老屁股>去[预设置好的服务器]" )

	local function AdminRedirectClient(_client,_id)
		local serverAddress = RedirAddressCheck(_client)
		if serverAddress == nil then return end
		
		local target = Shine.AdminGetClientByNS2ID(_client,_id)
		if not target then return end

		self:RedirectClient(target,serverAddress)
	end
	self:BindCommand( "sh_redir_player", "redir_player", AdminRedirectClient)
		:AddParam{ Type = "steamid" }
		:Help("使这名玩家前往预设的服务器.\n例：!redir 55022511")

end