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
	MinSkillToCommand = 0,
	["Tier"] ={100,300,500},
	TierShiftHour = 30,
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
	Validator:AddFieldRule( "TierShiftHour",  Validator.IsType( "number", Plugin.DefaultConfig.TierShiftHour ))
	Validator:AddFieldRule( "BelowSkillNotify",  Validator.IsType( "number", Plugin.DefaultConfig.BelowSkillNotify ))
	Validator:AddFieldRule( "MinSkillToCommand",  Validator.IsType( "number", Plugin.DefaultConfig.MinSkillToCommand ))
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
	["Siege+++"] = true,
}

function Plugin:Initialise()
	return true
end

function Plugin:OnFirstThink()
	Shine.Hook.SetupClassHook("Player", "OnKill", "OnPlayerKill", "PassivePost")
	Shine.Hook.SetupClassHook("Marine", "DropAllWeapons", "OnDropAllWeapons", "PassivePre")

	Shine.Hook.SetupClassHook("TeamSpectator", "Replace", "OnMarineReplace", "ActivePre")
	Shine.Hook.SetupClassHook("MarineTeam", "RespawnPlayer", "OnMarineRespawn", "PassivePost")
end

local function GetClientAndTier(player)
	local client = player:GetClient()
	if client and client:GetIsVirtual() then
		client = nil
	end

	local tier = 0
	if client then
		local skill = player:GetPlayerTeamSkill()
		for k,v in ipairs(Plugin.Config.Tier) do
			if skill < v then
				tier = k
				break
			end
		end
	end

	if tier > 0 then
		local crEnabled, cr = Shine:IsExtensionEnabled( "communityrank" )
		if crEnabled then
			if cr:GetCommunityPlayHour(client:GetUserId()) > Plugin.Config.TierShiftHour then		-- Shouldn't play for the lowest
				tier = math.min(tier + 1,#Plugin.Config.Tier)
			end
		end
	end
	
	return client,tier
end

local function CheckPlayerForcePurchase(self, player, purchaseTech)
	local client,tier = GetClientAndTier(player)
	if client and tier > 0 then
		local pRes = player:GetResources()
		if pRes > self.Config.RefundForcePurchase then
			local cost = LookupTechData(purchaseTech,kTechDataCostKey,0)
			if cost > 0 then
				local replaceMapName = LookupTechData(purchaseTech,kTechDataMapName)
				local additionalCost = math.floor(cost * 0.15) + 1
				cost = cost + additionalCost
				player:AddResources(-cost)
				player.lastUpgradeList = {}
				Shine:NotifyDualColour( player, 88, 214, 141, string.format("[新兵保护]",tier),
						234, 250, 241, string.format("个人资源即将溢出,已消耗[%d*]个人资源(+%d额外资源),并转化为科技/演化(该功能到达特定段位后失效).",cost, additionalCost))
				Shine:NotifyDualColour( player, 88, 214, 141, "[提示]",
						234, 250, 241, "过度积攒个人资源将导致您和您的队伍团队处于劣势!同时您所处的段位拥有[阵亡补偿],请积极寻找自己的职能定位." )
				return true
			end
		end
	end
end

local kMarineRespawnEquipment = {
	{map = LayMines.kMapName,info = "地雷 ",slot = 4 , refill=1, },
	{map = PulseGrenadeThrower.kMapName ,info = "电磁手雷 ",slot = 5},
	{map = Welder.kMapName,info = "焊枪 "}
}

local function CheckMarineGadgets(self,player)
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
	end

	if resultString then
		Shine:NotifyDualColour( player,
				88, 214, 141, string.format("[新晋-装备%i]",tier),
				234, 250, 241, string.format("初始装备:%s 已派发", resultString))
		return true
	end
	-- Shared.Message("[CNNP] New Comer Protection <Weapon Initalize>")
end

function Plugin:ValidateCommanderLogin( Gamerules, CommandStation, Player )
	if self.Config.MinSkillToCommand <= 0 then return end
	if Shine.GetHumanPlayerCount() < 20 then return end 	--They are seeding

	local Client = Shine.GetClientForPlayer( Player )
	if not Client then return end
	if Client:GetIsVirtual() then return end

	local skill = Player:GetPlayerTeamSkill()
	if skill < self.Config.MinSkillToCommand then
		Shine:NotifyDualColour( Client,  88, 214, 141, "[新兵保护]",
				213, 245, 227, string.format("由于服务器当前强度,你的玩家分数需要到达[%d]分时才能,成为该队的指挥!",self.Config.MinSkillToCommand))
		return false
	end
end

function Plugin:OnMarineRespawn(team,player, origin, angles)

	local valid = CheckMarineGadgets(self,player)
	if not GetHasTech(player,kTechId.ExosuitTech) then
		if CheckPlayerForcePurchase(self,player,kTechId.HeavyMachineGun) then
			player:GiveItem(HeavyMachineGun.kMapName)
			valid = true
		end 
	end

	if not valid then return end
	local weapon = player:GetWeaponInHUDSlot(kPrimaryWeaponSlot)
	if weapon then
		player:SetActiveWeapon(weapon:GetMapName())
	end
end

function Plugin:OnMarineReplace(player,mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)
	if mapName == Marine.kMapName then
		if GetHasTech(player,kTechId.ExosuitTech) then
			if CheckPlayerForcePurchase(self,player,kTechId.Exosuit) then
				mapName = Exo.kMapName
			end
		end
	end

	if mapName == Skulk.kMapName then
		if CheckPlayerForcePurchase(self,player,kTechId.Onos) then
			mapName = Onos.kMapName
		end
	end
	
	return Player.Replace(player,mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)
end
	 

function Plugin:ClientConfirmConnect( Client )
	if Client:GetIsVirtual() then return end

	local player = Client:GetControllingPlayer()
	if not player then return end
	if player:GetPlayerTeamSkill() > self.Config.BelowSkillNotify then return end

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

	refund = player:AddResources(refund)
	Shine:NotifyDualColour( player,
			88, 214, 141, string.format("[阵亡补偿]",tier),
			234, 250, 241, string.format("已转入<%.2f>资源.",refund) )

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
				88, 214, 141, string.format("[武器回收补偿]",tier),
				234, 250, 241, string.format("已转入<%.2f>个人资源.",refund) )
	end

end



function Plugin:Cleanup()
	return self.BaseClass.Cleanup( self )
end

return Plugin
