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
	["RefundLookup"] = {
		["Skulk"] = 		{1,		0.5,	0.25},
		["Gorge"] = 		{6,		4,		2.5},
		["Prowler"] = 		{8,		5.5,	3.25},
		["Lerk"] = 			{10.5,	7,		4.25},
		["Fade"] = 			{18.5,	12.25,	7.25},
		["Onos"] = 			{31,	20.5,	12.25},
	
		["Marine"]=			{1, 0.5,	0.25},
		["JetpackMarine"]=	{6,		4,		2.25},
		["Exo"] = 			{27.5,	18.25,	11.25},
	}
}

Plugin.EnabledGamemodes = {
	["ns2"] = true,
    ["NS2.0"] = true,
    ["siege++"] = true,
}

Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true
Plugin.ConfigMigrationSteps = { }

function Plugin:Initialise()
	return true
end

function Plugin:OnFirstThink()
    Shine.Hook.SetupClassHook("PlayingTeam", "RespawnPlayer", "OnPlayerRespawn", "PassivePost")
    Shine.Hook.SetupClassHook("Player", "OnKill", "OnPlayerKill", "PassivePost")
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
	{map = LayMines.kMapName,info = "地雷[4] ",slot = 4 , refill=1, },
	{map = PulseGrenadeThrower.kMapName ,info = "电磁手雷[5] ",slot = 5},
	{map = Welder.kMapName,info = "焊枪[3] "}
}

function Plugin:OnPlayerRespawn(playingTeam,player, origin, angles)
	if not Plugin.Config.MarineGears then return end

	local client,tier = GetClientAndTier(player)
	if not client or tier == 0 then return end

	local mapName = player:GetClassName()
	local result = nil
	if mapName == "Marine" then
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

				result = (result or "") .. equipment.info
			end
		end
		local weapon=player:GetWeaponInHUDSlot(kPrimaryWeaponSlot)
		if weapon then
			player:SetActiveWeapon(weapon:GetMapName())
		end
	end

	if result then
		Shine:NotifyDualColour( player,
		88, 214, 141, string.format("[新晋-装备%i]",tier),
		234, 250, 241, string.format("初始装备:%s 已派发",result))
	end
	-- Shared.Message("[CNNP] New Comer Protection <Weapon Initalize>")

end

function Plugin:OnPlayerKill(player,attacker, doer, point, direction)
	if not Plugin.Config.Refund then return end

	local client,tier = GetClientAndTier(player)
	if not client or tier == 0 then return end

	local name = player:GetClassName()
	local refundTable = Plugin.Config.RefundLookup[name]
	if not refundTable then return end

	
	local refund = refundTable[tier]
	player:AddResources(refund)
	Shine:NotifyDualColour( player,
	88, 214, 141, string.format("[新晋-资源%i]",tier),
	234, 250, 241, string.format("个人资源<%.2f>已回收.",refund) )

	-- Shared.Message("[CNNP] New Comer Protection <Death Refund>")
end

function Plugin:Cleanup()
	return self.BaseClass.Cleanup( self )
end

return Plugin
