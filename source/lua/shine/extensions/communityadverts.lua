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
	UserAdverts = {
		["5502211"]={
			enter = "萌新 <%s> 已加入战局.",
			leave = "奥义很爽.",
			prefixColor = {225,255,255},
			enterColor = {200,200,200},
			leaveColor = {200,200,200},
		}
	}
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true
Plugin.ConfigMigrationSteps = { }

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

	local userData = self.Config.UserAdverts[tostring(id)]
	if userData then
		return userData
	end

	local userData = Shine:GetUserData(Client)
	return self:BuildGroupAdverts(userData and userData.Group or nil)
end

function Plugin:PlayerEnter( Client )
	local player = Client:GetControllingPlayer()
	local userData=self:GetUserData(Client)
	Shine:NotifyDualColour( Shine.GetAllClients(),
	userData.prefixColor[1], userData.prefixColor[2], userData.prefixColor[3],"[社区通知]",
	userData.enterColor[1], userData.enterColor[2], userData.enterColor[3], string.format(userData.enter,player:GetName()))
	-- Shared.Message("[CNCA] Member Name Set:" .. player:GetName())
end

function Plugin:ClientDisconnect( Client )
	if not Client then return end
	if Client:GetIsVirtual() then return end
	local player = Client:GetControllingPlayer()
	local userData=self:GetUserData(Client)
	if #userData.leave == 0 then return end

	Shine:NotifyDualColour( Shine.GetAllClients(),
	userData.prefixColor[1], userData.prefixColor[2], userData.prefixColor[3],"[社区通知]",
	userData.leaveColor[1], userData.leaveColor[2], userData.leaveColor[3], string.format(userData.leave,player:GetName()))
	-- Shared.Message("[CNCA] Member Exit:" .. tostring(Client:GetId()))
end

function Plugin:Cleanup()
	self:ResetState()
	return self.BaseClass.Cleanup( self )
end

Shine.LoadPluginModule( "logger.lua", Plugin )

return Plugin
