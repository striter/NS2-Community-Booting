local JSON = require "shine/lib/json"

local Shine = Shine

local pairs = pairs
local pcall = pcall
local rawget = rawget
local tonumber = tonumber
local tostring = tostring
local IsType = Shine.IsType
local Notify = Shared.Message
local TableEmpty = table.Empty

local Plugin = ...
Plugin.Version = "1.0"
Plugin.PrintName = "communityadverts"
Plugin.HasConfig = true
Plugin.ConfigName = "CommunityAdverts.json"
Plugin.DefaultConfig = { 
	ShowLeave = false,
	ShowLeaveToAdminOnly = true,
	AnnouncementsURL = ""
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true
do
	local Validator = Shine.Validator()
	Validator:AddFieldRule( "ShowLeave",  Validator.IsType( "boolean", Plugin.DefaultConfig.ShowLeave ))
	Validator:AddFieldRule( "ShowLeaveToAdminOnly",  Validator.IsType( "boolean", Plugin.DefaultConfig.ShowLeaveToAdminOnly ))
	Validator:AddFieldRule( "AnnouncementsURL",  Validator.IsType( "string", Plugin.DefaultConfig.AnnouncementsURL ))
end

Plugin.KDefaultGroup = "DefaultGroup"
Plugin.kDefaultData = {
	enter = "玩家 <%s> 加入了战局",
	leave = "一名玩家离开了战局",
	prefixColor = {225,255,255},
	enterColor = {128,128,128}, 
	leaveColor = {128,128,128},
}
local kInvalidUserAdvert = { }

function Plugin:Initialise()
	self.groupData = { }
	return true
end

function Plugin:OnFirstThink()
	if self.Config.AnnouncementsURL == "" then
		return
	end
	Shine.PlayerInfoHub:Query(self.Config.AnnouncementsURL,function(response)
		if not response or #response == 0 then return end
		self.Announcements = json.decode(response)
		for Client in Shine.IterateClients() do
			self:ClientConfirmConnect(Client)	
		end
	end)
end

function Plugin:ResetState()
	TableEmpty( self.groupData )
end

function Plugin:Cleanup()
	self:ResetState()
	return self.BaseClass.Cleanup( self )
end

--Announcements
function Plugin:ClientConfirmConnect(_client)
	if _client:GetIsVirtual() then return end

	Shine.SendNetworkMessage(_client,"Shine_Announcement" ,self.Announcements,true)
end

--Enter/Leave Advert
function Plugin:BuildGroupAdverts(_groupName)
	local Group = _groupName and Shine:GetGroupData(_groupName) or Shine:GetDefaultGroup()
	_groupName = _groupName or Plugin.KDefaultGroup 
	
	local targetData = self.groupData[_groupName]
	if targetData then return targetData end

	local GroupData = Group.Adverts
	if not GroupData then
		targetData = Plugin.kDefaultData
	else
		targetData = {
			prefixColor = GroupData.prefixColor or {255,255,255},
			enter = GroupData.enter or "玩家 <%s> 加入了战局",
			enterColor = GroupData.enterColor or {128,128,128}, 
			leave = GroupData.leave or "一名玩家离开了战局",
			leaveColor = GroupData.leaveColor or {128,128,128},
		}
	end
	
	self.groupData[_groupName] = targetData
	--Shared.Message("[CNCA] Group Initialize:" .. _groupName .." " .. targetData.enter .. " " .. targetData.leave)
	return targetData
end

function Plugin:GetAdvertData(Client)
	local userData = Shine:GetUserData(Client)
	local groupAdvert = self:BuildGroupAdverts(userData and userData.Group or nil)
	local userAdvert = userData and userData.Adverts or kInvalidUserAdvert
	return groupAdvert , userAdvert
end

function Plugin:PlayerEnter( Client )
	
	local player = Client:GetControllingPlayer()
	local groupData,userData = self:GetAdvertData(Client)
	local prefix = userData.prefixColor or groupData.prefixColor
	local enterColor = userData.enterColor or groupData.enterColor
	local enterMessage = userData.enter or groupData.enter
	
	Shine:AdminPrint( nil, "%s<%s> joined", true, Shine.GetClientInfo( Client ) , IPAddressToString( Server.GetClientAddress( Client ) )  )

	if #enterMessage > 0 then
		Shine:NotifyDualColour( Shine.GetAllClients(), prefix[1], prefix[2], prefix[3],"[战区通知]",
				enterColor[1], enterColor[2], enterColor[3], string.format(enterMessage,player:GetName()))
	end
	-- Shared.Message("[CNCA] Member Name Set:" .. player:GetName())
end


function Plugin:ClientDisconnect( Client )
	if not Client then return end
	if Client:GetIsVirtual() then return end
	if not self.Config.ShowLeave then return end
	
	local player = Client:GetControllingPlayer()
	local groupData,userData = self:GetAdvertData(Client)
	local prefix = userData.prefixColor or groupData.prefixColor
	local leaveColor = userData.leaveColor or groupData.leaveColor
	local leaveMessage = userData.leave or groupData.leave
	
	if #leaveMessage > 0 then
		for client in Shine.IterateClients() do
			if not self.Config.ShowLeaveToAdminOnly or Shine:HasAccess( Client, "sh_adminmenu" ) then
				Shine:NotifyDualColour(client,prefix[1], prefix[2], prefix[3],"[战区通知]",
						leaveColor[1], leaveColor[2], leaveColor[3], string.format(leaveMessage,player:GetName()))
			end
		end
	end
	-- Shared.Message("[CNCA] Member Exit:" .. tostring(Client:GetId()))
end


function Plugin:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force )
	if NewTeam == kSpectatorIndex then 
		Shine:NotifyDualColour( Player.client,
		93, 173, 226,"[观察者]",
		214, 234, 248, "你已成为观察者.\n*请按[F4]进入预备室(在有空位的情况下).\n*服务器爆满时可在观战区等待新战区开启.")
	elseif NewTeam == kTeamReadyRoom then
		Shine:NotifyDualColour( Player.client,
		93, 173, 226,"[预备室]",
		214, 234, 248, "*在战局开始的情况下请尽快加入游戏.\n*贴近广告牌按[E]互动查看文档.\n*按[M]呼出服务器菜单.")
	end
end


return Plugin
