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