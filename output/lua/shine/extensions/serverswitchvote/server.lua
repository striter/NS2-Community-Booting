local Shine = Shine
local StringMatch = string.match
local tonumber = tonumber

local Plugin = ...
Plugin.Version = "1.0"

Plugin.HasConfig = true
Plugin.ConfigName = "ServerSwitchVote.json"

Plugin.DefaultConfig = {
	ClientVote = true,
	Servers = {
		{ Name = "My awesome server", IP = "127.0.0.1", Port = "27015", Password = "" }
	},
	CrowdAdvert = {
		PlayerCount = 0,
		RedirCount = 24,
		ResSlots = 32,
		ToServer = 0,
		ToServerDelay = 10,
		Prefix = "[病危通知书]",
		Message = "服务器要炸了",
		FailInformCount = 40,
		FailInformMessage = "距离自动换服还差%i人",
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

	Validator:AddFieldRule( "Servers", Validator.AllValuesSatisfy(
		Validator.ValidateField( "Name", Validator.IsAnyType( { "string", "nil" } ) ),
		Validator.ValidateField( "IP", Validator.IsType( "string" ), { DeleteIfFieldInvalid = true } ),
		Validator.ValidateField( "IP", {
			Check = function( Address )
				local IP = IPToInt( StringMatch( Address, "^(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$" ) )
				if IP then
					return not IsValidIPAddress( IP )
				end

				-- Hostname must contain at least 2 segments.
				if StringMatch( Address, "%." ) then
					return false
				end

				return true
			end,
			Fix = function() return nil end,
			Message = function()
				return "%s must have a valid IP address or hostname"
			end
		}, {
			DeleteIfFieldInvalid = true
		} ),
		Validator.ValidateField( "Port", Validator.IsAnyType( { "string", "number" } ), {
			DeleteIfFieldInvalid = true
		} ),
		Validator.ValidateField( "Port", Validator.IfType( "string", Validator.MatchesPattern( "^%d+$" ) ), {
			DeleteIfFieldInvalid = true
		} ),
		Validator.ValidateField( "Password", Validator.IsAnyType( { "string", "nil" } ) )
	) )

	Plugin.ConfigValidator = Validator

	Validator:AddFieldRule( "ClientVote",  Validator.IsType( "boolean", Plugin.DefaultConfig.ClientVote ))
	Validator:AddFieldRule( "CrowdAdvert",  Validator.IsType( "table", Plugin.DefaultConfig.CrowdAdvert ))
	Validator:AddFieldRule( "CrowdAdvert.PlayerCount",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.PlayerCount ))
	Validator:AddFieldRule( "CrowdAdvert.RedirCount",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.RedirCount ))
	Validator:AddFieldRule( "CrowdAdvert.ResSlots",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.ResSlots ))
	Validator:AddFieldRule( "CrowdAdvert.Prefix",  Validator.IsType( "string", Plugin.DefaultConfig.CrowdAdvert.Prefix ))
	Validator:AddFieldRule( "CrowdAdvert.ToServer",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.ToServer ))
	Validator:AddFieldRule( "CrowdAdvert.ToServerDelay",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.ToServerDelay ))
	Validator:AddFieldRule( "CrowdAdvert.Message",  Validator.IsType( "string", Plugin.DefaultConfig.CrowdAdvert.Message ))
	Validator:AddFieldRule( "CrowdAdvert.FailInformPrefix",  Validator.IsType( "string", Plugin.DefaultConfig.CrowdAdvert.FailInformPrefix ))
	Validator:AddFieldRule( "CrowdAdvert.FailInformMessage",  Validator.IsType( "string", Plugin.DefaultConfig.CrowdAdvert.FailInformMessage ))
	Validator:AddFieldRule( "CrowdAdvert.FailInformCount",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.FailInformCount ))
end

local function GetConnectIP(_index)
	local data = Plugin.Config.Servers[_index]
	return string.format("%s:%s",data.IP,data.Port)
end

function Plugin:Initialise()
	self.Enabled = true
	self:CreateCommands()
	return true
end

local function NotifyCrowdAdvert(self, _message)
	Shine:NotifyDualColour(Shine.GetAllClients(),146, 43, 33,self.Config.CrowdAdvert.Prefix,
			253, 237, 236, _message)
end

local function NotifyCrowdFailed(self, _crowdingPlayers, _ignoreTeams)
	if _crowdingPlayers >= self.Config.CrowdAdvert.FailInformCount then
		local informMessage = string.format( self.Config.CrowdAdvert.FailInformMessage,self.Config.CrowdAdvert.PlayerCount - _crowdingPlayers)
		for client in Shine.IterateClients() do
			local team = client:GetControllingPlayer():GetTeamNumber()
			if _ignoreTeams or team == kSpectatorIndex or team == kTeamReadyRoom then
				Shine:NotifyDualColour(client,146, 43, 33,
						self.Config.CrowdAdvert.FailInformPrefix,
						253, 237, 236, informMessage)
			end
		end
	end
end

function Plugin:OnEndGame(_winningTeam)
	if self.Config.CrowdAdvert.ToServer <= 0 then return end
	local redirData = self.Config.Servers[self.Config.CrowdAdvert.ToServer]
	if not redirData then return end
	
	local gameEndPlayerCount = Shine.GetHumanPlayerCount()
	if gameEndPlayerCount < self.Config.CrowdAdvert.PlayerCount then
		NotifyCrowdFailed(self,gameEndPlayerCount,false)		--Tells spectators/readyrooms
		return
	end
	
	local amount = self.Config.CrowdAdvert.RedirCount
	amount = amount > 0 and amount or gameEndPlayerCount / 2
	local delay = self.Config.CrowdAdvert.ToServerDelay
	NotifyCrowdAdvert(self,string.format( self.Config.CrowdAdvert.Message,delay,amount, redirData.Name))

	self.Timer = self:SimpleTimer(delay, function()
		local currentPlayerCount = Shine.GetHumanPlayerCount()
		if currentPlayerCount < self.Config.CrowdAdvert.PlayerCount then
			NotifyCrowdFailed(self,currentPlayerCount,true)		--Tells everyone
			return
		end
		
		if self.Config.CrowdAdvert.ResSlots > 0 then
			Shared.ConsoleCommand(string.format("sh_setresslots %i", self.Config.CrowdAdvert.ResSlots))
		end

		local address = redirData.IP .. ":" .. redirData.Port
		self:RedirClients(address,amount,false)
	end )
end

-- Send Client Vote List
function Plugin:ClientConnect( Client )
	if Client:GetIsVirtual() then return end
	self:ProcessClientVoteList( Client )
end

function Plugin:OnUserReload()
	for Client in Shine.IterateClients() do
		self:ProcessClientVoteList( Client )
	end
end

function Plugin:OnNetworkingReady()
	for Client in Shine.IterateClients() do
		self:ProcessClientVoteList( Client )
	end
end

function Plugin:ProcessClientVoteList( Client )
	local valid = self.Config.ClientVote
	valid = valid or Shine:HasAccess( Client, "sh_adminmenu" )
	if not valid then return end

	for i = 1, #self.Config.Servers do
		local data = self.Config.Servers[i]
		for _,amount in ipairs(data.Amount) do
			self:SendNetworkMessage( Client, "AddServerList", {
				ID = i,
				Name = data.Name  or "No Name",
				IP = data.IP,
				Port = tonumber( data.Port ) or 27015,
				Amount = amount
			}, true )
		end
	end
end

function Plugin:RedirClients(_targetIP,_count,_newcomer)
	local clients = {}
	for Client in Shine.IterateClients() do

		local player = Client:GetControllingPlayer()
		if player then
			table.insert(clients,{ client = Client, priority = player:GetPlayerSkill()})
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
			Server.SendNetworkMessage(client, "Redirect",{ ip = _targetIP }, true)
		end
		count = count - 1
		if count <= 0 then
			break
		end
	end
end

function Plugin:CreateCommands()
	 self:BindCommand( "sh_redir_newcomer", "redir_newcomer", function(_client,_serverIndex,_count,_message)
		 NotifyCrowdAdvert(self,_message)
		 self:RedirClients(GetConnectIP(_serverIndex),_count,true)
	end):
	AddParam{ Type = "number", Help = "目标服务器",Round = true, Min = 1, Max = 6, Default=1 }:
	AddParam{ Type = "number", Help = "迁移人数",Round = true, Min = 0, Max = 28, Default = 16 }:
	AddParam{ Type = "string", Help = "显示消息",Optional = true, Default = "服务器人满为患,开启被动分服." }:
	Help( "示例: !redir_newcomer 1 20 昂?. 迁移[20]名<新屁股>去[1服]" )
	
	self:BindCommand( "sh_redir_oldass", "redir_oldass", function(_client,_serverIndex,_count,_message)
		NotifyCrowdAdvert(self,_message)
		self:RedirClients(GetConnectIP(_serverIndex),_count,false)
	end):
	AddParam{ Type = "number", Help = "目标服务器",Round = true, Min = 1, Max = 6, Default=1 }:
	AddParam{ Type = "number", Help = "迁移人数",Round = true, Min = 0, Max = 28, Default = 16 }:
	AddParam{ Type = "string", Help = "显示消息",Optional = true,  Default = "服务器已人满为患,开启被动分服." }:
	Help( "示例: !redir_oldass 1 20. 迁移[20]名<老屁股>去[1服]" )
end