--[[
	Shine multi-server plugin.
]]

local Shine = Shine

local Notify = Shared.Message
local StringFormat = string.format
local StringMatch = string.match
local tonumber = tonumber

local Plugin = ...
Plugin.Version = "1.0"

Plugin.HasConfig = true
Plugin.ConfigName = "ServerSwitchVote.json"

Plugin.DefaultConfig = {
	Servers = {
		{ Name = "My awesome server", IP = "127.0.0.1", Port = "27015", Password = "" }
	},
	CrowdAdvert = {
		PlayerCount = 0,
		Interval = 120,
		StartVote = false,
		Prefix = "[病危通知书]",
		Messages = {
			"服务器要炸了",
			"真的要炸了",
			"马上就炸",
		}
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

	Validator:AddFieldRule( "CrowdAdvert",  Validator.IsType( "table", Plugin.DefaultConfig.CrowdAdvert ))
	Validator:AddFieldRule( "CrowdAdvert.PlayerCount",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.PlayerCount ))
	Validator:AddFieldRule( "CrowdAdvert.Interval",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.Interval ))
	Validator:AddFieldRule( "CrowdAdvert.Prefix",  Validator.IsType( "string", Plugin.DefaultConfig.CrowdAdvert.Prefix ))
	Validator:AddFieldRule( "CrowdAdvert.StartVote",  Validator.IsType( "boolean", Plugin.DefaultConfig.CrowdAdvert.StartVote ))
	Validator:AddFieldRule( "CrowdAdvert.Messages",  Validator.IsType( "table", Plugin.DefaultConfig.CrowdAdvert.Messages ))
end

local function GetConnectIP(_index)
	local data = Plugin.Config.Servers[_index]
	return string.format("%s:%s",data.IP,data.Port)
end

function Plugin:Initialise()
	self.Enabled = true

	local function RedirClients(_serverIndex,_count,_onlySpectate)
		local clients = {}
		for Client in Shine.IterateClients() do
			
            local player = Client:GetControllingPlayer()
            if player then
                if _onlySpectate and not player:GetIsSpectator() then
                    goto continue
                end
                
                table.insert(clients,{client = Client,priority = player:GetPlayerSkill()})
                ::continue::
			end
		end

		table.sort(clients,function (a,b) return a.priority < b.priority end)
		local count = _count
		local targetIP =  GetConnectIP(_serverIndex)
		for index,data in pairs(clients) do
			
			Server.SendNetworkMessage(data.client, "Redirect",{ ip = targetIP }, true)

			count = count - 1
			if count == 0 then
				break
			end
		end
	end
	
	
	local function RedirSpectateWithCount(_client,_serverIndex,_count)
	    RedirClients(_serverIndex,_count,1)
	end
	
    local redirSpectateWithCountCommand = self:BindCommand( "sh_redir_spec_count", "redir_spec_count", RedirSpectateWithCount )
    redirSpectateWithCountCommand:AddParam{ Type = "number", Round = true, Min = 1, Max = 6, Default=1 }
    redirSpectateWithCountCommand:AddParam{ Type = "number", Round = true, Min = 0, Max = 28, Optional = true, Default = 16 }
    redirSpectateWithCountCommand:Help( "示例: !redir_spec_count 1 20. 将20个观战(不包括场内玩家)迁移至服务器[1],排序为分数从下到上" )


	local function RedirPlayersWithCount(_client,_serverIndex,_count)
	    RedirClients(_serverIndex,_count,nil)
	end

    local redirPlayersCommand = self:BindCommand( "sh_redir_count", "redir_count", RedirPlayersWithCount )
    redirPlayersCommand:AddParam{ Type = "number", Round = true, Min = 1, Max = 6, Default=1 }
    redirPlayersCommand:AddParam{ Type = "number", Round = true, Min = 0, Max = 28, Optional = true, Default = 16 }
    redirPlayersCommand:Help( "示例: !redir_count 1 20. 将20个玩家(包括观战)迁移至服务器[1],排序为分数从下到上" )

	return true
end

function Plugin:OnNetworkingReady()
	for Client in Shine.IterateClients() do
		self:ProcessClient( Client )
	end
end

function Plugin:OnFirstThink()
	if self.Config.CrowdAdvert.PlayerCount ~= 0  then
		self:TriggerCrowdAdvert()
	end
end

function Plugin:TriggerCrowdAdvert()
	if self.Timer then
		self.Timer:Destroy()
		self.Timer = nil
	end

	if Shine.GetHumanPlayerCount() >= self.Config.CrowdAdvert.PlayerCount then
		Shine:NotifyDualColour( Shine.GetAllClients(),146, 43, 33,self.Config.CrowdAdvert.Prefix,
				253, 237, 236, self.Config.CrowdAdvert.Messages[math.random(#self.Config.CrowdAdvert.Messages)])
	end
	
	if self.Config.CrowdAdvert.StartVote then
		local data = self.Config.Servers[math.random(#self.Config.Servers)]
		local amount = data.Amount[#data.Amount]
		local address = data.IP .. ":" .. data.Port
		if amount > 0 then
			StartVote("VoteSwitchServer",nil, { ip = address , name = data.Name, onlyAccepted = true, voteRequired = amount })
		end
	end
	
	self.Timer = self:SimpleTimer( self.Config.CrowdAdvert.Interval, function()
		self:TriggerCrowdAdvert()
	end )
end

function Plugin:SendServerData( Client, ID, Data )
	for _,amount in ipairs(Data.Amount) do
		self:SendNetworkMessage( Client, "AddServerList", {
			Name = Data.Name  or "No Name",
			IP = Data.IP,
			Port = tonumber( Data.Port ) or 27015,
			Amount = amount
		}, true )
	end
end

function Plugin:ProcessClient( Client )
	for i = 1, #self.Config.Servers do
		self:SendServerData( Client, i, self.Config.Servers[i] )
	end
end

function Plugin:ClientConnect( Client )
	if Client:GetIsVirtual() then return end
	self:ProcessClient( Client )
end

function Plugin:OnUserReload()
	for Client in Shine.IterateClients() do
		self:ProcessClient( Client )
	end
end