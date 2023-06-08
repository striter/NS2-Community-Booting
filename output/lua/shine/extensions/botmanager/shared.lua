--[[
    Shine BotManager
]]
local Plugin = Shine.Plugin( ... )
Plugin.Version = "0.2"

function Plugin:SetupDataTable()
	self:AddDTVar( "boolean", "AllowPlayersToReplaceComBots", true )
	self:AddDTVar( "boolean", "LoginCommanderBotAtLogout", false )
end

Plugin.EnabledGamemodes = {
	[ "ns2" ] = true,
	[ "NS2.0" ] = true,
	[ "NS2.0beta" ] = true,
	[ "NS1.0"] = true,
	[ 'siege+++' ] = true,
	[ 'GunGame' ] = true,
	[ 'combat' ] = true,
}


function Plugin:Initialise()
	self.Enabled = true
	return true
end

if Server then

	local baseGetCanJoinTeamNumber = NS2Gamerules.GetCanJoinTeamNumber
	function NS2Gamerules:GetCanJoinTeamNumber(player, teamNumber)
		if player.isVirtual then return true end		--Let bots in without any errors
		
		if not Plugin.EnabledGamemodes[Shine.GetGamemode()] then
			return baseGetCanJoinTeamNumber(self,player,teamNumber)
		end

		-- Every check below is disabled with cheats enabled
		if Shared.GetCheatsEnabled() then
			return true
		end
		
		local forceEvenTeams = Server.GetConfigSetting("force_even_teams_on_join")
		if forceEvenTeams then
			
			local team1Players, _, team1Bots = self.team1:GetNumPlayers()
			local team2Players, _, team2Bots = self.team2:GetNumPlayers()
			
			local team1Number = self.team1:GetTeamNumber()
			local team2Number = self.team2:GetTeamNumber()
			
			-- only subtract bots IF we want to even teams with bots
			--local client = player:GetClient()
			if not player.isVirtual then
				team1Players = team1Players - team1Bots
				team2Players = team2Players - team2Bots
			end
			
			if team1Players + team2Players >= 12 then
				if (team1Players > team2Players) and (teamNumber == team1Number) then
					Server.SendNetworkMessage(player, "JoinError", BuildJoinErrorMessage(0), true)
					return false
				elseif (team2Players > team1Players) and (teamNumber == team2Number) then
					Server.SendNetworkMessage(player, "JoinError", BuildJoinErrorMessage(0), true)
					return false
				end
			end
		end
	
		-- Remove bot restrictions
		-- Scenario: Veteran tries to join a team at rookie only server
		--if teamNumber ~= kSpectatorIndex then --allow to spectate
		--	local isRookieOnly = Server.IsDedicated() and not self.botTraining and self.gameInfo:GetRookieMode()
		--
		--	if isRookieOnly and player:GetSkillTier() > kRookieMaxSkillTier then
		--		Server.SendNetworkMessage(player, "JoinError", BuildJoinErrorMessage(2), true)
		--		return false
		--	end
		--end
		
		return true
	end

	local baseUpdateBots = BotTeamController.UpdateBots
	function BotTeamController:UpdateBots()
		if Plugin.EvenWithBots then
			local team1HumanNum = self:GetPlayerNumbersForTeam(kTeam1Index, true)
			local team2HumanNum = self:GetPlayerNumbersForTeam(kTeam2Index, true)
			
			local mostHumans = math.max(team1HumanNum, team2HumanNum)
			self.MaxBots = math.max(mostHumans * 2, Plugin.MaxBots, 2) -- need a minimum of 2 since the update code "optimizes" if max is 0
		end

		baseUpdateBots(self)
	end
end

function Plugin:OnFirstThink()
	if Server then
		Shine.Hook.SetupClassHook("NS2Gamerules", "OnCommanderLogin", "PreOnCommanderLogin", "PassivePre")
	end

	Shine.Hook.SetupClassHook("GameInfo", "GetRookieMode", "GetRookieMode", "ActivePre")
	Shine.Hook.SetupClassHook("GameInfo", "GetRookieMode", "PostGetRookieMode", "PassivePost")
end


function Plugin:PreOnCommanderLogin()
	self.OverrideRookieMode = true
end

function Plugin:PreOnCommanderLogout()
	self.OverrideRookieMode = self.dt.LoginCommanderBotAtLogout
end

function Plugin:GetRookieMode(GameInfo)
	if self.OverrideRookieMode and self.dt.AllowPlayersToReplaceComBots ~= GameInfo.rookieMode then
		return true
	end
end

function Plugin:PostGetRookieMode()
	self.OverrideRookieMode = false
end

return Plugin
