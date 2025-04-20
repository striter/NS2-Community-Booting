--[[
    Shine BotManager
]]
local Plugin = Shine.Plugin( ... )
Plugin.Version = "0.2"

function Plugin:SetupDataTable()
	self:AddDTVar( "boolean", "AllowPlayersToReplaceComBots", true )
	self:AddDTVar( "boolean", "LoginCommanderBotAtLogout", false )
end

Plugin.EnabledGamemodes = Shine.kPvPEnabledGameMode

function Plugin:Initialise()
	self.Enabled = true
	return true
end

if Server then
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
