class 'GUIVoiceChat' (GUIScript)

kLocalVoiceFontColor         = Client.GetOptionColor("LocalTalkExtended_color", 0x80FF80)
kLocalVoiceTeamOnlyFontColor = Client.GetOptionColor("LocalTalkExtended_color_team",  0xC028C0)

GUIVoiceChat.kCommanderFontColor = Color(1, 1, 0, 1)
GUIVoiceChat.kMarineFontColor    = Color(147/255, 206/255, 1, 1)
GUIVoiceChat.kAlienFontColor     = Color(207/255, 139/255, 41/255, 1)
GUIVoiceChat.kSpectatorFontColor = Color(1, 1, 1, 1)

local kBackgroundTextureMarine = PrecacheAsset("ui/marine_HUD_presbg.dds")
local kBackgroundTextureAlien  = PrecacheAsset("ui/alien_HUD_presbg.dds")

local kGlobalSpeakerIcon = PrecacheAsset("ui/speaker.dds")

local chat_bars

local function ResetBarForPlayer(pie)
	local bar = pie.voice_chat_bar
	if not bar then return end

	pie.voice_chat_bar = nil
	pie.voice_channel  = nil
	bar.player = Entity.invalidId
	bar.background:SetIsVisible(false)
end

local function PlayerInfoForClient(client)
	for _, pie in ientitylist(Shared.GetEntitiesWithClassname "PlayerInfoEntity") do
		if pie.clientId == client then
			return pie
		end
	end
end

local function ResetBarForClient(client)
	return ResetBarForPlayer(PlayerInfoForClient(client))
end

local function IsRelevant(pie)
	return
		Shared.GetEntity(pie.playerId) ~= nil or
		-- Dead team mates can still be heard although irrelevant,
		-- so we need to make an exception for them.
		--
		-- FIXME: When the person followed by a spectator is irrelevant
		-- to our client, then the flickering voice chat bug will appear.
		pie.isSpectator
end

local function GetVoiceChannel(client)
	local channel
	if Client.GetLocalClientIndex() == client then
		channel = Client.GetVoiceChannelForRecording()
	else
		channel = Client.GetVoiceChannelForClient(client)
	end
	return channel or VoiceChannel.Invalid
end

function GUIVoiceChat:Initialize()
	self.visible = true

	local kBackgroundSize   = Vector(GUIScale(250), GUIScale(28), 0)
	local kBackgroundYSpace = GUIScale(4)

	local kVoiceChatIconSize   = Vector(kBackgroundSize.y, kBackgroundSize.y, 0)
	local kVoiceChatIconOffset = Vector(-kBackgroundSize.y * 2, -kVoiceChatIconSize.x / 2, 0)

	local kNameOffsetFromChatIcon = Vector(-kBackgroundSize.y - GUIScale(6), 0, 0)

	local num_chat_bars = math.ceil(Client.GetScreenHeight() / 2 / (kBackgroundYSpace + kBackgroundSize.y))
	chat_bars = table.array(num_chat_bars + 1)

	local bar_position = Vector(-kBackgroundSize.x, 0, 0)
	for i = 1, num_chat_bars do
		local background = GUIManager:CreateGraphicItem()
		background:SetSize(kBackgroundSize)
		background:SetAnchor(GUIItem.Right, GUIItem.Center)
		background:SetLayer(kGUILayerDeathScreen+1)
		background:SetPosition(bar_position)
		background:SetIsVisible(false)

		local icon = GUIManager:CreateGraphicItem()
		icon:SetSize(kVoiceChatIconSize)
		icon:SetAnchor(GUIItem.Right, GUIItem.Center)
		icon:SetPosition(kVoiceChatIconOffset)
		icon:SetTexture(kGlobalSpeakerIcon)
		background:AddChild(icon)

		local name = GUIManager:CreateTextItem()
		name:SetFontName(Fonts.kAgencyFB_Small)
		name:SetAnchor(GUIItem.Right, GUIItem.Center)
		name:SetScale(GetScaledVector())
		name:SetTextAlignmentX(GUIItem.Align_Max)
		name:SetTextAlignmentY(GUIItem.Align_Center)
		name:SetPosition(kNameOffsetFromChatIcon)
		GUIMakeFontScale(name)
		icon:AddChild(name)

		bar_position.y = bar_position.y + kBackgroundYSpace + kBackgroundSize.y

		chat_bars[i] = {background = background, icon = icon, name = name, player = Entity.invalidId}
	end
end

function GUIVoiceChat:Uninitialize()
	for i = 1, #chat_bars do
		GUI.DestroyItem(chat_bars[i].name)
		GUI.DestroyItem(chat_bars[i].background)
		GUI.DestroyItem(chat_bars[i].icon)
	end

	chat_bars = nil
end

function GUIVoiceChat:SetIsVisible(visible)
	self.visible = visible

	for i = 1, #chat_bars do
		local bar = chat_bars[i]
		if bar.player ~= Entity.invalidId then
			bar.background:SetIsVisible(visible)
		end
	end
end

function GUIVoiceChat:GetIsVisible()
	return self.visible
end

function GUIVoiceChat:OnResolutionChanged()
	self:Uninitialize()
	self:Initialize()
end

local function CanUseLocalVoiceChat(player)
	return
		not player:isa "Spectator" or
		player:isa "TeamSpectator" or
		not GetGameInfoEntity():GetGameStarted() and player:GetIsFirstPerson()
end

local team_only
function GUIVoiceChat:SendKeyEvent(key, down, amount)
	local player = Client.GetLocalPlayer()
	local client = Client.GetLocalClientIndex()

	if down then
		if ChatUI_EnteringChatMessage() then return end

		local iscomm = player:isa "Commander"
		local isspectator = player:isa "Spectator"
	
		local bind = iscomm and "VoiceChatCom" or "VoiceChat"
		if GetIsBinding(key, bind) then
			self.recordBind    = bind
			self.recordEndTime = nil
			ResetBarForClient(client)

			Client.VoiceRecordStartGlobal()
		elseif CanUseLocalVoiceChat(player) then
			-- FIXME: Commanders can not talk to enemy players, even if sighted.
			-- This is quite unfortunate, but unfortunately there is no
			-- easy way to make enemy players hear them, and attempting
			-- to remove this check will just result in a voice chat
			-- bar flickering with no sound being emitted.
			if not iscomm and not isspectator and GetIsBinding(key, "LocalVoiceChat") then
				self.recordBind    = "LocalVoiceChat"
				self.recordEndTime = nil
				ResetBarForClient(client)

				if team_only ~= false then
					team_only = false
					Client.SendNetworkMessage("LocalTalkExtended_teamonly", {on = false}, true)
				end
				Client.VoiceRecordStartEntity(player, Vector.origin)
			elseif GetIsBinding(key, "LocalVoiceChatTeam") then
				self.recordBind    = "LocalVoiceChatTeam"
				self.recordEndTime = nil
				ResetBarForClient(client)

				if team_only ~= true then
					team_only = true
					Client.SendNetworkMessage("LocalTalkExtended_teamonly", {on = true}, true)
				end
				Client.VoiceRecordStartEntity(player, Vector.origin)
			end
		end
	elseif self.recordBind and GetIsBinding(key, self.recordBind) then
		self.recordBind = nil
		self.recordEndTime = Shared.GetTime() + Client.GetOptionFloat("recordingReleaseDelay", 0.15)
	end
end

local voice_teamonly = table.array(100)

Client.HookNetworkMessage("LocalTalkExtended_teamonly_notify", function(msg)
	voice_teamonly[msg.client] = msg.on
	ResetBarForClient(msg.client)
end)

local function ShouldCreateBar(local_client, client, channel, pie, time)
	if channel == VoiceChannel.Invalid or pie.voice_chat_bar then
		return false
	end

	if channel ~= VoiceChannel.Global and local_client ~= client then
		-- Reasoning for IsRelevant (local function defined above) call:
		-- Sadly Spark can not handle VoiceChannel.Entity when the entity referred to is not relevant
		-- to the client.
		-- This is understandable though, since the position is a part of the entity, so a fix
		-- would be an architectural change, something too grand for a small bug like this.
		if not IsRelevant(pie) then
			return false
		end

		-- We need to do this because the team-only network message
		-- arrives after the voice transmission begins
		local bar_time = pie.voice_chat_bar_time
		if not bar_time then
			pie.voice_chat_bar_time = time + 0.15
			return false
		else
			-- Edge case bug:
			-- If there are not any bars left, a player not speaking
			-- will not have their voice_chat_bar_time set to nil
			-- after they finish speaking
			return bar_time <= time
		end
	end

	return true
end

function GUIVoiceChat:Update(delta_time)
	PROFILE("GUIVoiceChat:Update")

	local time = Shared.GetTime()

	if self.recordEndTime and self.recordEndTime < time then
		Client.VoiceRecordStop()
		self.recordEndTime = nil
	end

	local local_client = Client.GetLocalClientIndex()
	local player_info = PlayerInfoForClient(local_client)
	if not player_info then return end
	local local_team = player_info.teamNumber

	for i = 1, #chat_bars do
		local bar = chat_bars[i]
		local id = bar.player
		if id ~= Entity.invalidId then
			local pie = Shared.GetEntity(id)
			if pie then
				local channel = GetVoiceChannel(pie.clientId)
				if channel ~= pie.voice_channel then
					-- If the channel isn't the global one, i.e. if it's proximity,
					-- we also need the network message to tell us what kind of
					-- local voice chat it is, so we delay the bar here.
					if channel ~= VoiceChannel.Global then
						pie.voice_chat_bar_time = nil
					end
					ResetBarForPlayer(pie)
				end
			else
				bar.player = Entity.invalidId
				bar.background:SetIsVisible(false)
			end
		end
	end

	for _, pie in ientitylist(Shared.GetEntitiesWithClassname "PlayerInfoEntity") do
		local client  = pie.clientId
		local channel = GetVoiceChannel(client)

		if ShouldCreateBar(local_client, client, channel, pie, time) then
			local bar
			for i = 1, #chat_bars do
				if chat_bars[i].player == Entity.invalidId then
					bar = chat_bars[i]
					break
				end
			end
			-- All bars may be occupied
			if bar then
				local team = pie.teamNumber

				local color =
					channel ~= VoiceChannel.Global and (
						client == local_client and
							(team_only and kLocalVoiceTeamOnlyFontColor or kLocalVoiceFontColor) or
						(team == local_team or local_team == kSpectatorIndex) and voice_teamonly[client] and
							kLocalVoiceTeamOnlyFontColor or
						kLocalVoiceFontColor
					) or
					pie.isCommander and GUIVoiceChat.kCommanderFontColor or
					team == 1 and GUIVoiceChat.kMarineFontColor or
					team == 2 and GUIVoiceChat.kAlienFontColor or
					GUIVoiceChat.kSpectatorFontColor

				bar.name:SetText(pie.playerName)
				bar.name:SetColor(color)

				bar.icon:SetColor(color)

				bar.background:SetTexture(team == 2 and kBackgroundTextureAlien or kBackgroundTextureMarine)
				bar.background:SetColor(team ~= 1 and team ~= 2 and Color(1, 200/255, 150/255, 1) or Color(1, 1, 1, 1))
				bar.background:SetIsVisible(self.visible)

				pie.voice_chat_bar = bar
				bar.player = pie:GetId()

				pie.voice_channel = channel
			end
		end
	end
end

-- Is this correct? No idea, but I can't test the game to fix it properly
function GUIVoiceChat:Reload() end
