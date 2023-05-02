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
		ToServer = 0,
		ToServerDelay = 10,
		Prefix = "[病危通知书]",
		Message = "服务器要炸了",
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
	Validator:AddFieldRule( "CrowdAdvert.Prefix",  Validator.IsType( "string", Plugin.DefaultConfig.CrowdAdvert.Prefix ))
	Validator:AddFieldRule( "CrowdAdvert.ToServer",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.ToServer ))
	Validator:AddFieldRule( "CrowdAdvert.ToServerDelay",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.ToServerDelay ))
	Validator:AddFieldRule( "CrowdAdvert.Message",  Validator.IsType( "string", Plugin.DefaultConfig.CrowdAdvert.Message ))
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

function Plugin:OnFirstThink()
	
end

function Plugin:OnEndGame(_winningTeam)
	local playerCount = Shine.GetHumanPlayerCount()
	if playerCount < self.Config.CrowdAdvert.PlayerCount then return end
	
	if self.Config.CrowdAdvert.ToServer <= 0 then return end
	local data = self.Config.Servers[self.Config.CrowdAdvert.ToServer]
	if not data then return end 
	local delay = self.Config.CrowdAdvert.ToServerDelay

	local address = data.IP .. ":" .. data.Port
	local amount = playerCount / 2
	Shine:NotifyDualColour( Shine.GetAllClients(),146, 43, 33,self.Config.CrowdAdvert.Prefix,
			253, 237, 236, string.format( self.Config.CrowdAdvert.Message,delay,amount,data.Name))
	
	self.Timer = self:SimpleTimer(delay, function()
		self:RedirClients(address,amount)
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

function Plugin:RedirClients(_targetIP,_count)
	local clients = {}
	for Client in Shine.IterateClients() do

		local player = Client:GetControllingPlayer()
		if player then
			table.insert(clients,{client = Client,priority = player:GetPlayerSkill()})
		end
	end

	table.sort(clients,function (a,b) return a.priority < b.priority end)
	local count = _count
	for _,data in pairs(clients) do
		Server.SendNetworkMessage(data.client, "Redirect",{ ip = _targetIP }, true)
		count = count - 1
		if count <= 0 then
			break
		end
	end
end

function Plugin:CreateCommands()
	local function RedirPlayersWithCount(_client,_serverIndex,_count)
		self:RedirClients(GetConnectIP(_serverIndex),_count)
	end

	local redirPlayersCommand = self:BindCommand( "sh_redir_count", "redir_count", RedirPlayersWithCount )
	redirPlayersCommand:AddParam{ Type = "number", Round = true, Min = 1, Max = 6, Default=1 }
	redirPlayersCommand:AddParam{ Type = "number", Round = true, Min = 0, Max = 28, Optional = true, Default = 16 }
	redirPlayersCommand:Help( "示例: !redir_count 1 20. 将20个玩家(包括观战)迁移至服务器[1],排序为分数从下到上" )
end