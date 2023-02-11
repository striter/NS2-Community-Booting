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

local Plugin = Shine.Plugin( ... )
Plugin.Version = "1.0"
Plugin.PrintName = "communityadverts"
Plugin.HasConfig = true
Plugin.ConfigName = "CommunityAdverts.json"
Plugin.DefaultConfig = {
	NewcomerSkill = 100,
	Delay = 2,
	URL = "https://www.unknownworlds.com/ns2/",
	Title = "Welcome To Natural Selection 2",
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true
Plugin.ConfigMigrationSteps = { }

do
	local Validator = Shine.Validator()
	Validator:AddFieldRule( "NewcomerSkill",  Validator.IsType( "number", 100 ))
	Validator:AddFieldRule( "Delay",  Validator.IsType( "number", 2 ))
	Validator:AddFieldRule( "URL",  Validator.IsType( "string", "https://www.unknownworlds.com/ns2/" ))
	Validator:AddFieldRule( "Title",  Validator.IsType( "string", "Welcome To Natural Selection 2" ))
	Plugin.ConfigValidator = Validator
end

function Plugin:Initialise()
	self.groupData = { }
	return true
end

function Plugin:ResetState()
	TableEmpty( self.groupData )
end

Plugin.KDefaultGroup = "DefaultGroup"
Plugin.kDefaultData = {
	enter = "玩家 <%s> 加入了战局",
	leave = "一名玩家离开了战局",
	prefixColor = {225,255,255},
	enterColor = {128,128,128}, 
	leaveColor = {128,128,128},
}
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
	Shared.Message("[CNCA] Group Initialize:" .. _groupName .." " .. targetData.enter .. " " .. targetData.leave)
	return targetData
end

function Plugin:GetUserData(Client)
	local id=tostring(Client:GetUserId())
	-- Shared.Message("[CNCA] Community Adverts:" .. id)

	local userData = Shine:GetUserData(Client)
	local advert = userData and userData.Adverts
	if advert then
		return advert
	end

	return self:BuildGroupAdverts(userData and userData.Group or nil)
end

function Plugin:ClientConfirmConnect( Client )
	local player = Client:GetControllingPlayer()
	local userData=self:GetUserData(Client)
	Shine:NotifyDualColour( Shine.GetAllClients(),
	userData.prefixColor[1], userData.prefixColor[2], userData.prefixColor[3],"[战区通知]",
	userData.enterColor[1], userData.enterColor[2], userData.enterColor[3], string.format(userData.enter,player:GetName()))
	-- Shared.Message("[CNCA] Member Name Set:" .. player:GetName())

	local player = Client:GetControllingPlayer()
	if not player then return end
	if player:GetPlayerSkill() > self.Config.NewcomerSkill then return end

	self:SimpleTimer( self.Config.Delay, function()
		Shine.SendNetworkMessage( Client, "Shine_Web", {
			URL = self.Config.URL,
			Title = self.Config.Title,
		}, true )
	end )
end

function Plugin:ClientDisconnect( Client )
	if not Client then return end
	if Client:GetIsVirtual() then return end
	local player = Client:GetControllingPlayer()
	local userData=self:GetUserData(Client)
	if #userData.leave == 0 then return end

	Shine:NotifyDualColour( Shine.GetAllClients(),
	userData.prefixColor[1], userData.prefixColor[2], userData.prefixColor[3],"[战区通知]",
	userData.leaveColor[1], userData.leaveColor[2], userData.leaveColor[3], string.format(userData.leave,player:GetName()))
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
		214, 234, 248, "你已进入预备室.\n*在战局开始的情况下请尽快加入游戏.\n*贴近广告牌按[E]互动查看文档.\n*按[M]呼出服务器菜单.")
	end
end

function Plugin:Cleanup()
	self:ResetState()
	return self.BaseClass.Cleanup( self )
end

Shine.LoadPluginModule( "logger.lua", Plugin )

return Plugin
