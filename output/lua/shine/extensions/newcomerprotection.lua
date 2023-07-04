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
Plugin.PrintName = "newcomerprotection"
Plugin.HasConfig = true
Plugin.ConfigName = "NewcomerProtection.json"
Plugin.DefaultConfig = {
	["Tier"] ={100,300,500},
	["MarineGears"] = false,
	["Refund"] = true,
	["RefundMultiply"] = { 0.8 , 0.5 , 0.3},
	["RefundAdditive"] = {
		["Skulk"] = 		{1,		0.5,	0.25},
		["Marine"]=			{1, 0.5,	0.25},
	},
	RefundForcePurchase = 80,
	BelowSkillNotify = 100,
	ExtraNotify = true,
	ExtraNotifyMessage = "You are at a higher tier skill server,choose rookie server for better experience",
	Messages = {
		{"Hello Marines"},
		{"Hello Aliens"},
	},
}

Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true
Plugin.ConfigMigrationSteps = { }
do
	local Validator = Shine.Validator()
	Validator:AddFieldRule( "BelowSkillNotify",  Validator.IsType( "number", Plugin.DefaultConfig.BelowSkillNotify ))
	Validator:AddFieldRule( "ExtraNotify",  Validator.IsType( "boolean", true ))
	Validator:AddFieldRule( "ExtraNotifyMessage",  Validator.IsType( "string", "You are at a higher tier skill server,choose rookie server for better experience" ))
	Validator:AddFieldRule( "Messages",  Validator.IsType( "table", Plugin.DefaultConfig.Messages))
	Validator:AddFieldRule( "Refund",  Validator.IsType( "boolean", Plugin.DefaultConfig.Refund ))
	Validator:AddFieldRule( "RefundMultiply",  Validator.IsType( "table", Plugin.DefaultConfig.RefundMultiply ))
	Validator:AddFieldRule( "RefundAdditive",  Validator.IsType( "table", Plugin.DefaultConfig.RefundAdditive ))
	Validator:AddFieldRule( "RefundForcePurchase",  Validator.IsType( "number", Plugin.DefaultConfig.RefundForcePurchase ))

	Plugin.ConfigValidator = Validator
end

Plugin.EnabledGamemodes = {
	["ns2"] = true,
	["NS2.0"] = true,
	["NS2.0beta"] = true,
	["NS1.0"] = true,
	["Siege+++"] = true,
}

function Plugin:Initialise()
	return true
end

function Plugin:OnFirstThink()
	Shine.Hook.SetupClassHook("Player", "OnKill", "OnPlayerKill", "PassivePost")
	Shine.Hook.SetupClassHook("MarineTeam", "RespawnPlayer", "OnMarineRespawn", "PassivePost")
	Shine.Hook.SetupClassHook("Marine", "DropAllWeapons", "OnDropAllWeapons", "PassivePre")
	Shine.Hook.SetupClassHook("TeamSpectator", "Replace", "OnTeamSpectatorReplace", "ActivePre")
end

local function GetClientAndTier(player)
	local client = player:GetClient()
	if client and client:GetIsVirtual() then
		client = nil
	end

	local tier = 0
	if client then
		local skill = player:GetPlayerSkill()
		for k,v in ipairs(Plugin.Config.Tier) do
			if skill < v then
				tier = k
				break
			end
		end
	end

	return client,tier
end

local kMarineRespawnEquipment = {
	{map = LayMines.kMapName,info = "地雷 ",slot = 4 , refill=1, },
	{map = PulseGrenadeThrower.kMapName ,info = "电磁手雷 ",slot = 5},
	{map = Welder.kMapName,info = "焊枪 "}
}

function Plugin:OnMarineRespawn(playingTeam,player, origin, angles)
	if not Plugin.Config.MarineGears then return end

	local client,tier = GetClientAndTier(player)
	if not client or tier == 0 then return end

	local techId = player:GetTechId()
	local resultString = nil
	if techId == kTechId.Marine then
		local equipments = {}
		for i=tier,#kMarineRespawnEquipment do
			local equipment = kMarineRespawnEquipment[i]
			if not equipment.slot or not player:GetWeaponInHUDSlot(equipment.slot) then
				player:GiveItem(equipment.map)
				if equipment.refill then
					local giveWeapon = player:GetWeapon(equipment.map)
					if giveWeapon then
						giveWeapon:Refill(equipment.refill)
					end
				end

				resultString = (resultString or "") .. equipment.info
			end
		end
		local weapon = player:GetWeaponInHUDSlot(kPrimaryWeaponSlot)
		if weapon then
			player:SetActiveWeapon(weapon:GetMapName())
		end
	end

	if resultString then
		Shine:NotifyDualColour( player,
				88, 214, 141, string.format("[新晋-装备%i]",tier),
				234, 250, 241, string.format("初始装备:%s 已派发", resultString))
	end
	-- Shared.Message("[CNNP] New Comer Protection <Weapon Initalize>")

end


function Plugin:ClientConfirmConnect( Client )
	if Client:GetIsVirtual() then return end

	local player = Client:GetControllingPlayer()
	if not player then return end
	if player:GetPlayerSkill() > self.Config.BelowSkillNotify then return end

	if self.Config.ExtraNotify then
		Shine:NotifyDualColour( Client,  88, 214, 141, "[新兵保护]",
				213, 245, 227, self.Config.ExtraNotifyMessage)
	end
end


function Plugin:OnPlayerKill(player,attacker, doer, point, direction)
	if not Plugin.Config.Refund then return end

	local client,tier = GetClientAndTier(player)
	if not client or tier == 0 then return end

	local refund = 0
	local refundAdditiveTable = Plugin.Config.RefundAdditive[player:GetClassName()]
	if refundAdditiveTable then
		refund = refund + refundAdditiveTable[tier]
	end

	local techID = player:GetTechId()
	if techID == kTechId.Exo then	--....?
		techID = kTechId.Exosuit
	elseif techID == kTechId.JetpackMarine then	--....???
		techID = kTechId.Jetpack
	end

	local cost = LookupTechData(techID,kTechDataCostKey,0)
	if cost > 0 then
		refund = refund + Plugin.Config.RefundMultiply[tier] * cost
	end

	if refund == 0 then return end

	player:AddResources(refund)
	Shine:NotifyDualColour( player,
			88, 214, 141, string.format("[新兵保护]",tier),
			234, 250, 241, string.format("已转入<%.2f>资源作为[阵亡补偿].",refund) )

	local team = player:GetTeamNumber()
	local messages = self.Config.Messages[team]
	if messages then
		Shine:NotifyDualColour( player,
				88, 214, 141, "[提示]",
				234, 250, 241, messages[math.random(#messages)] )
	end
	-- Shared.Message("[CNNP] New Comer Protection <Death Refund>")
end

function Plugin:OnDropAllWeapons(player)
	local client,tier = GetClientAndTier(player)
	if tier == 0 then return end
	local refundPercentage = self.Config.RefundMultiply[tier]
	if not refundPercentage then return end

	local primaryWeapon = player:GetWeaponInHUDSlot(kPrimaryWeaponSlot)
	if not primaryWeapon then return end
	local techID = primaryWeapon:GetTechId()
	local cost = LookupTechData(techID,kTechDataCostKey,0)
	if cost > 0 then
		player:RemoveWeapon(primaryWeapon)
		DestroyEntity(primaryWeapon)
		local refund = cost * refundPercentage
		player:AddResources(refund)
		Shine:NotifyDualColour( player,
				88, 214, 141, string.format("[新兵保护]",tier),
				234, 250, 241, string.format("已转入<%.2f>个人资源作为[武器回收补偿].",refund) )
	end

end

local kPassThroughAdditional = 5
local function CheckPlayerForcePurchase(self,player,purchaseTech, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)
	local client,tier = GetClientAndTier(player)
	if client and tier > 0 then
		local pRes = player:GetResources()
		if pRes > self.Config.RefundForcePurchase then
			local cost = LookupTechData(purchaseTech,kTechDataCostKey,0)
			if cost > 0 then
				local replaceMapName = LookupTechData(purchaseTech,kTechDataMapName)
				player:AddResources(-cost + kPassThroughAdditional)
				Shine:NotifyDualColour( player,
						88, 214, 141, string.format("[新兵保护]",tier),
						234, 250, 241, string.format("您的个人资源即将溢出,已消耗[%d+%d]个人资源转化为科技/演化(该功能到达老兵段位后失效).",cost, kPassThroughAdditional))
				Shine:NotifyDualColour( player,
						88, 214, 141, "[提示]",
						234, 250, 241, "<物竞天择2>核心为科技追逐,过度积攒个人资源将导致您和您的队伍团队处于劣势!同时您所处的段位拥有[阵亡补偿],请利用该期间寻找游戏乐趣与最适合自己的职能定位." )
				return Player.Replace(player,replaceMapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)
			end
		end
	end
end

function Plugin:OnTeamSpectatorReplace(player,mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)
	if mapName == Marine.kMapName then
		return CheckPlayerForcePurchase(self,player,kTechId.Exosuit, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)
	elseif mapName == Skulk.kMapName then
		return CheckPlayerForcePurchase(self,player,kTechId.Onos, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)
	end
end

function Plugin:Cleanup()
	return self.BaseClass.Cleanup( self )
end

return Plugin
