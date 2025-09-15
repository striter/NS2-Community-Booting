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
	CommandRestrictions = {
		SeedingPlayers = 99, -- So restrictions ignores it
		MinHourToCommand = -1,
		MaxSkillAverageDiffToCommand = -1,
		RoundValidate = {
			Enable = false,
			Record = 5,
			MaxPlaytime = 3,
			MaxWinTime = 2,
			ForbidLastRoundWinner = true,
		},
	},
	["Tier"] ={100,300,500},
	TierHourMultiplier = 10,
	TierHourMaxSkill = 900,
	["MarineGears"] = false,
	["Refund"] = true,
	["RefundMultiply"] = { 0.8 , 0.5 , 0.3},
	["RefundAdditive"] = {
		["Skulk"] = 		{1,		0.5,	0.25},
		["Marine"]=			{1, 0.5,	0.25},
	},
	DamageProtection = {
		ActiveTier = {true,true,true},
		kSkillDiffThreshold = 1000,
		kSkillDiffStep = 500,
		kSkillDiffDamageScalarEachStep = 0.05
	},
	RefundForcePurchase = 80,
	BelowSkillNotify = 100,
	NewcomerEstimateSkill = 750,
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
	Validator:AddFieldRule( "TierHourMultiplier",  Validator.IsType( "number", Plugin.DefaultConfig.TierHourMultiplier ))
	Validator:AddFieldRule( "TierHourMaxSkill",  Validator.IsType( "number", Plugin.DefaultConfig.TierHourMaxSkill ))
	Validator:AddFieldRule( "BelowSkillNotify",  Validator.IsType( "number", Plugin.DefaultConfig.BelowSkillNotify ))
	Validator:AddFieldRule( "CommandRestrictions",  Validator.IsType( "table", Plugin.DefaultConfig.CommandRestrictions ))
	Validator:AddFieldRule( "CommandRestrictions.RoundValidate",  Validator.IsType( "table", Plugin.DefaultConfig.CommandRestrictions.RoundValidate ))
	Validator:AddFieldRule( "ExtraNotify",  Validator.IsType( "boolean", true ))
	Validator:AddFieldRule( "ExtraNotifyMessage",  Validator.IsType( "string", "You are at a higher tier skill server,choose rookie server for better experience" ))
	Validator:AddFieldRule( "Messages",  Validator.IsType( "table", Plugin.DefaultConfig.Messages))
	Validator:AddFieldRule( "Refund",  Validator.IsType( "boolean", Plugin.DefaultConfig.Refund ))
	Validator:AddFieldRule( "RefundMultiply",  Validator.IsType( "table", Plugin.DefaultConfig.RefundMultiply ))
	Validator:AddFieldRule( "RefundAdditive",  Validator.IsType( "table", Plugin.DefaultConfig.RefundAdditive ))
	Validator:AddFieldRule( "RefundForcePurchase",  Validator.IsType( "number", Plugin.DefaultConfig.RefundForcePurchase ))
	Validator:AddFieldRule( "DamageProtection",  Validator.IsType( "table", Plugin.DefaultConfig.DamageProtection ))
	Validator:AddFieldRule( "NewcomerEstimateSkill",  Validator.IsType( "number", Plugin.DefaultConfig.NewcomerEstimateSkill ))
	Plugin.ConfigValidator = Validator
end

Plugin.EnabledGamemodes = Shine.kNS2EnabledGameMode

local kCommanderHistoryFile = "config://shine/temp/CommanderHistory.json"
function Plugin:Initialise()
	return true
end

function Plugin:OnFirstThink()
	local File, Err = Shine.LoadJSONFile(kCommanderHistoryFile)
	self.kCommanderHistory = File or {}

	Shine.Hook.SetupClassHook("Player", "OnKill", "OnPlayerKill", "PassivePost")
	Shine.Hook.SetupClassHook("Marine", "DropAllWeapons", "OnDropAllWeapons", "PassivePre")

	Shine.Hook.SetupClassHook("Marine", "ModifyDamageTaken", "OnModifyDamageTaken", "PassivePost")
	Shine.Hook.SetupClassHook("JetpackMarine", "ModifyDamageTaken", "OnModifyDamageTaken", "PassivePost")
	Shine.Hook.SetupClassHook("Exo", "ModifyDamageTaken", "OnModifyDamageTaken", "PassivePost")
	Shine.Hook.SetupClassHook("Prowler", "ModifyDamageTaken", "OnModifyDamageTaken", "PassivePost")
	Shine.Hook.SetupClassHook("Lerk", "ModifyDamageTaken", "OnModifyDamageTaken", "PassivePost")
	Shine.Hook.SetupClassHook("Skulk", "ModifyDamageTaken", "OnModifyDamageTaken", "PassivePost")
	Shine.Hook.SetupClassHook("Gorge", "ModifyDamageTaken", "OnModifyDamageTaken", "PassivePost")
	Shine.Hook.SetupClassHook("Fade", "ModifyDamageTaken", "OnModifyDamageTaken", "PassivePost")
	Shine.Hook.SetupClassHook("Onos", "ModifyDamageTaken", "OnModifyDamageTaken", "PassivePost")

	Shine.Hook.SetupClassHook("TeamSpectator", "Replace", "OnMarineReplace", "ActivePre")
	Shine.Hook.SetupClassHook("MarineTeam", "RespawnPlayer", "OnMarineRespawn", "PassivePost")
	Shine.Hook.SetupClassHook("NS2Gamerules", "EndGame", "OnEndGame", "PassivePost")
end

local function GetClientAndTier(player)
	--return nil,1
	local client = player:GetClient()
	if client and client:GetIsVirtual() then
		client = nil
	end

	local tier = 0
	local verifySkill = player:GetPlayerTeamSkill()
	if client then
		local crEnabled, cr = Shine:IsExtensionEnabled( "communityrank" )
		if crEnabled then
			local userId = client:GetUserId()
			local playHour = cr:GetCommunityPlayHour(userId)
			verifySkill = math.max(verifySkill, math.min(Plugin.Config.TierHourMaxSkill,  playHour * Plugin.Config.TierHourMultiplier))
		end

		for k,v in ipairs(Plugin.Config.Tier) do
			if verifySkill < v then
				tier = k
				break
			end
		end
	end

	return client,tier,verifySkill
end

local function CheckPlayerForcePurchase(self, player, purchaseTech,validate)
	local client,tier = GetClientAndTier(player)
	if client and tier > 0 then
		local pRes = player:GetResources()
        local cost = LookupTechData(purchaseTech,kTechDataCostKey,0)
        if cost > 0 then
            local comparer = validate and cost or self.Config.RefundForcePurchase
		    if pRes >= comparer then
                if not validate then
                    local additionalCost = math.floor(cost * 0.2) + 1
                    cost = math.max(player:GetResources(), cost + additionalCost)
                    player:AddResources(-cost)
                    player.lastUpgradeList = {}
                    Shine:NotifyDualColour( player, 88, 214, 141, string.format("[新兵保护]",tier),
                            234, 250, 241, string.format("个人资源即将溢出,已消耗[%d*]个人资源(+%d额外资源),并转化为对应科技.",cost, additionalCost))
                end
				Shine:NotifyDualColour( player, 88, 214, 141, "[提示]",
						234, 250, 241, "积攒个人资源将导致您和您的队伍团队处于劣势!请积极寻找自己的职能定位." )
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

function Plugin:ValidateCommanderLogin(_gameRules, _commandStructure, _player)
	local restrictions = self.Config.CommandRestrictions
	--if self.Config.MinSkillToCommand <= 0 then return end
	if GetGamerules():GetGameStarted() then return end
	if Shine.GetHumanPlayerCount() < restrictions.SeedingPlayers then return end 	--They are seeding

	local client = Shine.GetClientForPlayer(_player)
	if not client then return end
	if client:GetIsVirtual() then return end

	local clientId = client:GetUserId()
	
	local crEnabled, cr = Shine:IsExtensionEnabled( "communityrank" )
	if crEnabled then
		local playHour = cr:GetCommunityPlayHour(clientId)
		if restrictions.MinHourToCommand > 0 and playHour < restrictions.MinHourToCommand then
			Shine:NotifyDualColour(client,
					88, 214, 141, "[新兵保护]",
					213, 245, 227, string.format("由于当前服务器强度,游戏时长需要达到[%d]小时,才能成为该队的指挥,您当前的游戏时长为[%d]!", restrictions.MinHourToCommand,playHour))

			Shared.ConsoleCommand(string.format("sh_setteam %s %s true", clientId,_player:GetTeamNumber()))
			return false
		end
	end

	if self:CommanderRoundRestricted(clientId) then
		Shine:NotifyDualColour(client,
				88, 214, 141, "[新兵保护]",
				213, 245, 227, "您近期已多次登录指挥站,请小沁一会.给他人些机会.")
		Shared.ConsoleCommand(string.format("sh_setteam %s %s true", clientId,_player:GetTeamNumber()))
		return false
	end
	
	local gamerules = GetGamerules()
	if not gamerules then return end

	local oppositeCommander = gamerules:GetTeam(_player:GetTeamNumber() == kTeam1Index and kTeam2Index or kTeam1Index):GetCommander()
	if not oppositeCommander then return end
	local commanderSkill = _player:GetCommanderTeamSkill()
	local compareSkill = oppositeCommander:GetCommanderTeamSkill()

	local skillDiff = math.abs(commanderSkill - compareSkill)
	if restrictions.MaxSkillAverageDiffToCommand > 0 and skillDiff > restrictions.MaxSkillAverageDiffToCommand then
		Shine:NotifyDualColour(client,
				88, 214, 141, "[新兵保护]",
				213, 245, 227, string.format("你的指挥分数[%i]与预期分数[%i]差距过大[>%i],请选择适当的游玩场所!",commanderSkill,compareSkill, restrictions.MaxSkillAverageDiffToCommand))

		Shared.ConsoleCommand(string.format("sh_setteam %s %s true", clientId,_player:GetTeamNumber()))
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

local function UpdateRookie(self,_player)
	local client,tier, estimateSkill = GetClientAndTier(_player)
	if not client or client:GetIsVirtual() then return end

	local team = _player:GetTeamNumber()
	local playingTeam = (team == kTeam1Index or team == kTeam2Index)

	local isRookie = self.Config.NewcomerEstimateSkill > estimateSkill
	if playingTeam then
		isRookie = isRookie and _player:GetKills() < _player:GetDeaths()
	end
	_player:SetRookie(isRookie)
end

function Plugin:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force )
	UpdateRookie(self,Player)
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
		if CheckPlayerForcePurchase(self,player,kTechId.Onos,true)
                and #GetEntitiesForTeamWithinRange("Player", GetEnemyTeamNumber(player:GetTeamNumber()), player:GetOrigin(), kARCRange) == 0 then
            player = Player.Replace(player,mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)
            player:AddTimedCallback(function(saver) saver:ProcessBuyAction({kTechId.Onos}) end,0)
            return player
        end
	end

	return Player.Replace(player,mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues, isPickup)
end


function Plugin:ClientConfirmConnect( Client )
	if Client:GetIsVirtual() then return end

	local player = Client:GetControllingPlayer()
	if not player then return end

	UpdateRookie(self,player)
	if player:GetPlayerTeamSkill() > self.Config.BelowSkillNotify then return end

	if self.Config.ExtraNotify then
		Shine:NotifyDualColour( Client,  88, 214, 141, "[新兵保护]",
				213, 245, 227, self.Config.ExtraNotifyMessage)
	end
end

function Plugin:GetRefundPercent(player)
	local client,tier = GetClientAndTier(player)
	if not client or tier == 0 then return 0 end
	return Plugin.Config.RefundMultiply[tier] or 0
end

function Plugin:OnPlayerKill(player,attacker, doer, point, direction)
	UpdateRookie(self,player)
	if attacker and attacker:isa("Player") then
		UpdateRookie(self,attacker)
	end

	if not Plugin.Config.Refund then return end

	local client,tier = GetClientAndTier(player)
	if not client or tier == 0 then return end

	local refund = 0
	local refundAdditiveTable = Plugin.Config.RefundAdditive[player:GetClassName()]
	if refundAdditiveTable then
		refund = refund + (refundAdditiveTable[tier] or 0)
	end

	local techID = player:GetTechId()
    if techID == kTechId.Exo then	--....?
        techID = kTechId.Exosuit
    elseif techID == kTechId.JetpackMarine then	--....???
        techID = kTechId.Jetpack
    elseif techID == kTechId.Embryo then
        techID = player.gestationTypeTechId or kTechId.Skulk
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

local function GetNearbyWeaponPickers(player)

	local team = player:GetTeamNumber()
	local origin = player:GetOrigin()
	local range = 20
	local players = GetEntitiesForTeamWithinRange("Player",team, origin, range)
	for _,v in pairs(players) do
		if v:GetIsAlive() then
			return true
		end
	end

	local structures = GetEntitiesWithMixinForTeamWithinRange("Construct",  team, origin, range)
	for _,v in pairs(structures) do
		if v:GetIsAlive() and v:GetIsBuilt() then
			return true
		end
	end

	return false
end

function Plugin:OnDropAllWeapons(player)
	local client,tier = GetClientAndTier(player)
	if tier == 0 then return end
	local refundPercentage = self.Config.RefundMultiply[tier]
	if not refundPercentage or refundPercentage <= 0 then return end
	if GetNearbyWeaponPickers(player) then return end

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

Plugin.kDamageBonusReduction = {
	["Skulk"] = 1,
	["Lerk"] = 0.5, ["Prowler"] = 0.5,
	["Fade"] = 0.33, ["Vokex"] = 0.33,
	["Gorge"] = 0.33, ["Onos"] = 0.2,

	["Marine"] = 1,
	["JetpackMarine"] = 0.5,
	["Exo"] = 0.2,
}

function Player:ModifyDamageTaken() end
function Plugin:OnModifyDamageTaken(self,damageTable, attacker, doer, damageType, hitPoint)

	if not Plugin.Config then return end

	if self:GetIsVirtual() or (attacker.GetIsVirtual and attacker:GetIsVirtual()) then return end

	local Config = Plugin.Config.DamageProtection
	if #Config.ActiveTier == 0 then return end
	if self.GetPlayerTeamSkill and attacker.GetPlayerTeamSkill then
		local selfSkill = self:GetPlayerTeamSkill()
		local targetSkill = attacker:GetPlayerTeamSkill()
		--if self:GetIsVirtual() then
		--    selfSkill = 2100
		--end
		--if attacker:GetIsVirtual() then
		--    targetSkill = 2100
		--end

		local skillOffset = (selfSkill - targetSkill)
		local value = math.max(math.abs(skillOffset) - Config.kSkillDiffThreshold,0)

		local sign = skillOffset >= 0 and 1 or -1
		if value > 0
				and sign == -1
				and self:GetKills() < self:GetDeaths()
		then
			local _,selfTier = GetClientAndTier(self)
			local _,targetTier = GetClientAndTier(attacker)

			local available = true
			if sign < 0 and not Config.ActiveTier[selfTier] then
				--Shared.Message(tostring(selfTier))
				available = false
			elseif sign > 0 and not Config.ActiveTier[targetTier] then
				--Shared.Message("Target" .. tostring(targetTier))
				available = false
			end

			if available then
				local damageParam = sign * (value/Config.kSkillDiffStep  + 1) * Config.kSkillDiffDamageScalarEachStep

				if damageParam < 0 then
					local classBonusReduction = Plugin.kDamageBonusReduction[self:GetClassName()] or 1
					damageParam = damageParam * classBonusReduction
				end

				damageParam = math.max(damageParam,-0.8)
				damageTable.damage = damageTable.damage * ( 1 + damageParam)
			end
		end
	end
end

function Plugin:OnEndGame()

	local data = self.Config.CommandRestrictions.RoundValidate
	--if not data.Enable then return end

	local lastRoundData = CHUDGetLastRoundStats();

	if not lastRoundData then
		Shared.Message("[CNNP] ERROR Option 'savestats' not enabled ")
		return
	end

	if not Shine.IsActiveRound(lastRoundData) then return end

	local roundLength = lastRoundData.RoundInfo.roundLength
	local playerCount = table.Count(lastRoundData.PlayerStats)
	local team1CommData = {timePlayed = 0}
	local team2CommData = {timePlayed = 0}
	local function ValidatePlayer(steamId,name,playerData, teamData)
		local commTime = math.floor(playerData.commanderTime)
		if teamData.timePlayed < commTime then
			teamData.timePlayed = commTime
			teamData.playerId = steamId
			teamData.playerName = name
		end

	end

	for steamId , playerStat in pairs( lastRoundData.PlayerStats ) do
		ValidatePlayer(steamId,playerStat.playerName,playerStat[kTeam1Index],team1CommData)
		ValidatePlayer(steamId,playerStat.playerName,playerStat[kTeam2Index],team2CommData)
	end

	table.insert(self.kCommanderHistory, 1, {
		time = os.time() ,
		winningTeam = lastRoundData.RoundInfo.winningTeam,
		team1CommData = team1CommData,
		team2CommData = team2CommData,
		map = lastRoundData.RoundInfo.mapName,
		length = roundLength,
		playerCount = playerCount,
	})

	local count = #self.kCommanderHistory
	for i = data.Record + 1,count do
		self.kCommanderHistory[i] = nil
	end

	local Success, Err = Shine.SaveJSONFile( self.kCommanderHistory, kCommanderHistoryFile)
	if not Success then
		Shared.Message( "Error saving prewarm file: "..Err )
	end
end

function Plugin:CommanderRoundRestricted(clientId)

	local data = self.Config.CommandRestrictions.RoundValidate

	if not data.Enable then return false end

	if data.ForbidLastRoundWinner then
		local lastRound = self.kCommanderHistory[1]
		if lastRound.winningTeam ~= 0 then
			local lastWinnerId = lastRound.winningTeam == 1 and lastRound.team1CommData.playerId or lastRound.team2CommData.playerId
			if lastWinnerId and lastWinnerId == clientId then
				return true
			end
		end
	end
	
	local timeRecentPlayed = 0
	local timeRecentWins = 0
	for k, recentRound in ipairs(self.kCommanderHistory) do
		if recentRound.team1CommData.playerId == clientId or recentRound.team2CommData.playerId == clientId then
			timeRecentPlayed = timeRecentPlayed + 1
		end

		if recentRound.winningTeam ~= 0 then
			local recentWinnerId = recentRound.winningTeam == 1 and recentRound.team1CommData.playerId or recentRound.team2CommData.playerId
			if recentWinnerId == clientId then
				timeRecentWins = timeRecentWins + 1
			end
		end
	end
	
	return timeRecentWins >= data.MaxWinTime or timeRecentPlayed >= data.MaxPlaytime
end

function Plugin:Cleanup()
	return self.BaseClass.Cleanup( self )
end

return Plugin
