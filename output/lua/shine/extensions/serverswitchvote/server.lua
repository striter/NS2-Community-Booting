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
		ToServer = 0,
		FailInformCount = 40,
	},
	RecallPenalty = {
		Count = -1,
		Reputation = -20,
	}
}

Plugin.CheckConfigTypes = true
do

local Validator = Shine.Validator()
	Plugin.ConfigValidator = Validator
	Validator:AddFieldRule( "ConfigURL",  Validator.IsType( "string", Plugin.DefaultConfig.ConfigURL ))
	Validator:AddFieldRule( "ClientVote",  Validator.IsType( "boolean", Plugin.DefaultConfig.ClientVote ))
	Validator:AddFieldRule( "CrowdAdvert",  Validator.IsType( "table", Plugin.DefaultConfig.CrowdAdvert ))
	Validator:AddFieldRule( "CrowdAdvert.NotifyTimer",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.NotifyTimer ))
	Validator:AddFieldRule( "CrowdAdvert.PlayerCount",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.PlayerCount ))
	Validator:AddFieldRule( "CrowdAdvert.ToServer",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.ToServer ))
	Validator:AddFieldRule( "CrowdAdvert.FailInformCount",  Validator.IsType( "number", Plugin.DefaultConfig.CrowdAdvert.FailInformCount ))
	Validator:AddFieldRule( "RecallPenalty",  Validator.IsType( "table", Plugin.DefaultConfig.RecallPenalty ))
end

local kPrefix = "[被动分服]"

local function NotifyCrowdAdvert(self, _message)
	Shine:NotifyDualColour(Shine.GetAllClients(),146, 43, 33,kPrefix,
			253, 237, 236, _message)
end

local LocalFilePath = "config://shine/temp/history_last_redir.json"
function Plugin:Initialise()
	self.Enabled = true
	self:CreateCommands()
	local File, Err = Shine.LoadJSONFile(LocalFilePath)
	self.RedirHistory = File or {}
	return true
end

function Plugin:RedirectClient(_client, _address)
	Server.SendNetworkMessage(_client, "Redirect",{ ip = _address }, true)
end

function Plugin:ProcessRecallPenalty( Client )

	local recallPenaltyCount = self.RedirHistory.RecallPenaltyCount or 0
	if recallPenaltyCount <= 0 then return end

	local id = Client:GetUserId()
	if not table.contains(self.RedirHistory.Clients,id) then return end
	table.removevalue(self.RedirHistory.Clients,id)
	
	Shared.ConsoleCommand(string.format("sh_rep_delta %s %s %s",id, self.Config.RecallPenalty.Reputation,string.format("分服回流|第%s名",self.Config.RecallPenalty.Count - recallPenaltyCount)))
	self.RedirHistory.RecallPenaltyCount = recallPenaltyCount - 1
end

function Plugin:RedirClients(_targetIP,_count,_newcomer)
	self.RedirHistory.RecallPenaltyCount = self.Config.RecallPenalty.Count
	self.RedirHistory.Clients = {}
	
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
		local player = client:GetControllingPlayer()
		if Shine:HasAccess(client, "sh_host" ) then
			Shine:NotifyDualColour(client,146, 43, 33,kPrefix, 253, 237, 236, "检测到[管理员]身份,已跳过强制换服,请在做好换服准备(如关门/锁观战)后前往预期服务器.")
		elseif player:isa("Commander") then
			Shine:NotifyDualColour(client,146, 43, 33,kPrefix, 253, 237, 236, "检测到您为指挥官,已跳过强制分服.")
		else
			table.insert(self.RedirHistory.Clients,client:GetUserId())
			self:RedirectClient(client,_targetIP)
			count = count - 1
		end

		if count <= 0 then
			break
		end
	end
end

function Plugin:OnEndGame(_winningTeam)
	self.RedirHistory.RecallPenaltyCount = 0
end

function Plugin:MapChange()
	local Success, Err = Shine.SaveJSONFile(self.RedirHistory, LocalFilePath)
	if not Success then
		Shared.Message( "Error saving last redir file: "..Err )
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
						and string.format( "距离自动换服还差%i名活跃玩家.",self.Config.CrowdAdvert.PlayerCount - _playerCount)
						or string.format("当前玩家数已满足分服条件(%i),当下一场对局倒计时开始时若存在足够的活跃(非观战)玩家,将尝试自动分服.",self.Config.CrowdAdvert.PlayerCount)
	
	for client in Shine.IterateClients() do
		local team = client:GetControllingPlayer():GetTeamNumber()
		if _ignoreTeams or team == kSpectatorIndex or team == kTeamReadyRoom then
			Shine:NotifyDualColour(client,146, 43, 33, kPrefix,
					253, 237, 236, informMessage)
		end
	end
end

function Plugin:NotifyCrowdRedirect()
	NotifyRedirectProgression(self,Shine.GetHumanPlayerCount(),false)		--Tells spectators/readyrooms
	self:SimpleTimer(self.Config.CrowdAdvert.NotifyTimer, function() self:NotifyCrowdRedirect() end )
end

function Plugin:SetGameState(Gamerules, _state, OldState )

	if _state ~= kGameState.PreGame then return end
	if self.Config.CrowdAdvert.ToServer <= 0 then return end
	if not self.PresetServers then return end
	local redirData = self.PresetServers[self.Config.CrowdAdvert.ToServer]
	if not redirData then return end

	local currentPlayerCount = Shine.GetHumanPlayerCount()
	local checkCount = currentPlayerCount - Server.GetNumSpectators()
	if checkCount < self.Config.CrowdAdvert.PlayerCount then
		NotifyRedirectProgression(self,checkCount,true)		--Tells spectators/readyrooms
		return
	end

	local amount = math.floor(currentPlayerCount / 2)
	local delay = 3
	NotifyCrowdAdvert(self,string.format( "活跃玩家数已达到服务器性能峰值,%i秒后%i名玩家将前往<%s>开启新战局.",delay,amount, redirData.Name))
	self.Timer = self:SimpleTimer(delay, function()
		self:RedirClients(redirData.Address,amount,false)
	end)
end

function Plugin:ClientConfirmConnect(_client)
	if _client:GetIsVirtual() then return end
	self:QueryIfNeeded()
	self:ProcessClientVoteList(_client)
	self:ProcessRecallPenalty(_client)
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
			Shine:NotifyCommandError( _client, "无目标服务器,请通过 !redir_verify 命令设置 " )
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