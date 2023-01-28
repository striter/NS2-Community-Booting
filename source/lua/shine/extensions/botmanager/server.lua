local Plugin = ...

Plugin.HasConfig = true
Plugin.ConfigName = "BotManager.json"
Plugin.DefaultConfig =
{
	MaxBots = 12,
	CommanderBots = false,
	CommanderBotsStartDelay = 180,
	LoginCommanderBotAtLogout = false,
	AllowPlayersToReplaceComBots = true,
	BotTickRate = 10,
	EvenWithBots = true,
}


function Plugin:Initialise()
	self.Enabled = true

	self.MaxBots = self.Config.MaxBots
	self.CommanderBots = self.Config.CommanderBots
	self.EvenWithBots = self.Config.EvenWithBots
	self.dt.AllowPlayersToReplaceComBots = self.CommanderBots and self.Config.AllowPlayersToReplaceComBots
	self.dt.LoginCommanderBotAtLogout = self.CommanderBots and self.Config.LoginCommanderBotAtLogout

	self.oldkPlayerBrainTickrate = kPlayerBrainTickrate
	kPlayerBrainTickrate = self.Config.BotTickRate

	self:CreateCommands()

	return true
end

--Fix shine kicking bots
function Plugin:VerifyCommanderTable()
	for i = #gCommanderBots, 1, -1 do
		local bot = gCommanderBots[i]
		local status = pcall(function() return bot:GetIsPlayerCommanding() end)
		if status == false then
			bot:Disconnect()
		end
	end

	return #gCommanderBots
end

function Plugin:CheckGameStart( Gamerules )
	local State = Gamerules:GetGameState()

	if State > kGameState.WarmUp then return end

	local NumCommanderBots = self:VerifyCommanderTable()
	local StartDelay = self.Config.CommanderBotsStartDelay or 0
	if StartDelay > 0 and NumCommanderBots > 0 and not self.StartTime then
		self.StartTime = Shared.GetTime() + StartDelay
	end

	if self.StartTime and (NumCommanderBots == 0 or Shared.GetTime() >= self.StartTime) then
		self.StartTime = nil
	end

	return self.StartTime
end

--Filter bots for voterandom
function Plugin:PreShuffleOptimiseTeams ( TeamMembers )
	for i = 1, 2 do
		for j = #TeamMembers[i], 1, -1 do
			local Player = TeamMembers[i][j]
			local Client = Player:GetClient()

			if not Client or Client:GetIsVirtual() then
				--remove the player's entry in the table
				table.remove(TeamMembers[i], j)
			end
		end
	end
end

function Plugin:OnFirstThink()
	self:SetMaxBots(self.MaxBots, self.CommanderBots)
end

function Plugin:SetMaxBots(bots, com)
	local Gamerules = GetGamerules()

	if not Gamerules or not Gamerules.SetMaxBots then return end

	Gamerules:SetMaxBots(bots, com)
end

function Plugin:CreateCommands()
	local function MaxBots( _, Number, SaveIntoConfig )

		self.MaxBots = Number
		self:SetMaxBots( Number, self.Config.CommanderBots )

		if SaveIntoConfig then
			self.Config.MaxBots = Number
			self:SaveConfig()
		end
	end
	local ShowNewsCommand = self:BindCommand( "sh_maxbots", "maxbots", MaxBots )
	ShowNewsCommand:AddParam{ Type = "number", Min = 0, Error = "Please specify the amount of bots you want to set.", Help = "Maximum number of bots"  }
	ShowNewsCommand:AddParam{ Type = "boolean", Default = false, Help = "true = save change", Optional = true  }
	ShowNewsCommand:Help( "设置场内Bot的最大数量." )

	local function ComBots( _, Enable, SaveIntoConfig )

		self.CommanderBots = Enable
		self.dt.AllowPlayersToReplaceComBots = self.CommanderBots and self.Config.AllowPlayersToReplaceComBots
		self:SetMaxBots( self.MaxBots, Enable )

		if SaveIntoConfig then
			self.Config.CommanderBots = Enable
			self:SaveConfig()
		end
	end
	local ShowNewsCommand = self:BindCommand( "sh_enablecombots", "enablecombots", ComBots )
	ShowNewsCommand:AddParam{ Type = "boolean", Error = "Please specify if you want to enable commander bots", Help = "true = add commander bots"  }
	ShowNewsCommand:AddParam{ Type = "boolean", Default = false, Help = "true = save change", Optional = true  }
	ShowNewsCommand:Help( "设置是否生成指挥Bot" )

end

function Plugin:Cleanup()
	self:SetMaxBots(0, false)

	kPlayerBrainTickrate = self.oldkPlayerBrainTickrate

	self.BaseClass.Cleanup( self )
	self.Enabled = false
end


