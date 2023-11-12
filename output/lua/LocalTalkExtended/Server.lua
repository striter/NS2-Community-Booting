local GetOwner = Server.GetOwner

local voice_teamonly = table.array(100)

Server.HookNetworkMessage("LocalTalkExtended_teamonly", function(client, msg)
	voice_teamonly[client:GetId()] = msg.on
end)

if not Shine then
	Shared.Message "\n\nPlease install Shine Administration to use Local Talk Extended\n\n"
	return
end

Shine.Hook.Add("CanPlayerHearPlayer", "LocalTalkExtended",
function(gamerules, listener, speaker, channel)
	-- Also avoids sending teamonly_notify network message!
	if listener == speaker then return true end

	local _, basecommands = Shine:IsExtensionEnabled "basecommands"

	local listener_client = GetOwner(listener)
	local speaker_client = GetOwner(speaker)

	if
		speaker_client and (basecommands:IsClientGagged(speaker_client) or
		listener:GetClientMuted(speaker_client:GetId()))
	then
		return false
	end

	if not channel or channel == VoiceChannel.Global then
		return basecommands:CanPlayerHearGlobalVoice(gamerules, listener, speaker, speaker_client)
	end

	if
		basecommands:IsLocalAllTalkDisabled(listener_client)
		or basecommands:IsLocalAllTalkDisabled(speaker_client)
		or not basecommands:ArePlayersInLocalVoiceRange(speaker, listener)
	then
		return false
	end

	local speaker_team  = speaker:GetTeamNumber()
	local listener_team = listener:GetTeamNumber()

	local team_only = voice_teamonly[speaker_client:GetId()] or false

	if basecommands:IsSpectatorAllTalk(listener) or speaker_team == listener_team then
		-- Notify the listener of the team-only state
		Server.SendNetworkMessage(
			listener_client,
			"LocalTalkExtended_teamonly_notify",
			{client = speaker_client:GetId(), on = team_only},
			true
		)
		return true
	else
		return not team_only
	end
end, -20)
