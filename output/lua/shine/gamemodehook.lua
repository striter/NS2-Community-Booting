local CompatiblePlugins = {
	["voterandom"] = true,
	["votesurrender"] = true,
	["pregame"] = true,
}

Shine.Hook.Add( "CanPluginLoad", "CNCommunityGameModeCheck", function( Plugin, GamemodeName )
	if GamemodeName ~= "NS2.0" and GamemodeName ~= "Siege2.0"  then
		return
	end
	return CompatiblePlugins[ Plugin:GetName() ]
end )

function Shine.IsActiveRound(roundData)
	if Shared.GetCheatsEnabled() then return true end

	if not roundData.RoundInfo then return false end
	if roundData.RoundInfo.roundLength < 300 or table.Count(lastRoundData.PlayerStats) < 12 then
		return false
	end
	return true
end 