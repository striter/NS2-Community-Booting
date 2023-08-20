local Plugin = ...

function Plugin:Initialise()
	Shine.Hook.SetupClassHook( "GUIScoreboard", "UpdateTeam", "OnGUIScoreboardUpdateTeam", "PassivePost" )
    Plugin._GUIScoreboardUpdateTeam = Shine.ReplaceClassMethod("GUIScoreboard", "UpdateTeam", self.GUIScoreboardUpdateTeam);
    Plugin.oldGUIScoreboardSendKeyEvent = Shine.ReplaceClassMethod("GUIScoreboard", "SendKeyEvent", Plugin.GUIScoreboardSendKeyEvent);
    return true
end


function Plugin:OnFirstThink()
    Shine.Hook.SetupGlobalHook( "GetOwnsItem", "CheckCommunityGadgets", "Replace" )
    self.playerCommunityTier = 0
end

Shine.HookNetworkMessage( "Shine_CommunityTier", function( Message )
    Plugin.playerCommunityTier = Message.Tier or 0
    Shared.Message(string.format("[CNCT] Tier Set %i",Plugin.playerCommunityTier ))
    
    GetGlobalEventDispatcher():FireEvent("OnUserStatsAndItemsRefreshed")
    SendPlayerCallingCardUpdate()
    SendPlayerVariantUpdate()
    GetCustomizeScene():RefreshOwnedItems()
end )

function Plugin:CheckCommunityGadgets(_item)
    return CommunityGetOwnsItem(_item,self.playerCommunityTier)
end

local kZeroStr = "0"
Plugin.GUIScoreboardUpdateTeam = function(scoreboard, updateTeam)
    Plugin._GUIScoreboardUpdateTeam(scoreboard, updateTeam)
        local playerList = updateTeam["PlayerList"]
        local teamScores = updateTeam["GetScores"]()
        local currentPlayerIndex = 1
        
        for _, player in ipairs(playerList) do
            if not scoreboard.hoverMenu.background:GetIsVisible() and not MainMenu_GetIsOpened() then
                
                local pr = teamScores[currentPlayerIndex]
                if pr == nil then return end
                
                local skillIcon = player.SkillIcon
                if pr.FakeBot then  --Fake BOT
                    skillIcon:SetTexturePixelCoordinates(0, 1 * 32, 100, 2 * 32 - 1)
                    player["Ping"]:SetText(kZeroStr)
                end

                if MouseTracker_GetIsVisible() then
                    local mouseX, mouseY = Client.GetCursorPosScreen()
                    if skillIcon:GetIsVisible() and GUIItemContainsPoint(skillIcon, mouseX, mouseY) then
                        local description
                        if pr.FakeBot or pr.SteamId == 0 then
                            description = string.format(Locale.ResolveString("SKILLTIER_TOOLTIP"), Locale.ResolveString("SKILLTIER_BOT"),-1)
                        else
                            description = skillIcon.tooltipText
                            if pr.CommSkill > 0 then
                                description = description .. "\n" .. string.format(Locale.ResolveString("SKILL_TIER_COMM"), math.max(0,pr.CommSkill + pr.CommSkillOffset), math.max(0,pr.CommSkill - pr.CommSkillOffset) )
                            end
                            description = description .. "\n" .. string.format(Locale.ResolveString("SKILL_TIER"), math.max(0,pr.Skill + pr.SkillOffset) , math.max(0,pr.Skill - pr.SkillOffset))
                            if pr.ns2TimePlayed > 0 then
                                description = description .. "\n" .. string.format(Locale.ResolveString("NS2_TIME_PLAYED"),pr.ns2TimePlayed )
                            end
                            
                            if pr.lastSeenName ~= "" and pr.lastSeenName ~= pr.Name then
                                description = description .. "\n" .. string.format( Locale.ResolveString("LAST_SEEN_NAME")) .. pr.lastSeenName
                            end

                            description = description .. "\n\n" .. string.format(Locale.ResolveString("COMMUNITY_RANK"),Locale.ResolveString(pr.Group))
                            if pr.reputation ~= 0 then
                                description = description .. "\n" .. (pr.reputation > 0 and string.format(Locale.ResolveString("COMMUNITY_REPUTATION_POSITIVE"),pr.reputation ) 
                                        or string.format(Locale.ResolveString("COMMUNITY_REPUTATION_NEGATIVE"),-pr.reputation ))
                            end
                            if pr.prewarmTime > 0 then
                                description = description .. "\n" .. string.format( Locale.ResolveString("COMMUNITY_PLAYTIME"), pr.prewarmTime)

                                if pr.prewarmScore > 0 then
                                    description = description .. "\n" .. string.format( Locale.ResolveString("COMMUNITY_PREWARM"), pr.prewarmScore)
                                end
                                
                                if pr.prewarmTier > 0 then
                                    description = description .. "\n" .. Locale.ResolveString(string.format("COMMUNITY_PREWARM_%i", pr.prewarmTier))
                                end
                            end
                            
                            
                        end
                        scoreboard.badgeNameTooltip:SetText(description)
                    end
                end
            end
            
            currentPlayerIndex = currentPlayerIndex + 1
        end

end

local function openUrl(url, title)
    if (not Shine.Config.DisableWebWindows) then
      Shine:OpenWebpage(url, title);
    else
      Client.ShowWebpage(url);
    end
end
local function openUrlNs2Panel(steam_id)
    openUrl(string.format('https://ns2panel.ocservers.com/%s/%s', 'player', steam_id), 'INFO_NS2PANEL');
end

function Plugin.GUIScoreboardSendKeyEvent(self, key, down)
    Plugin._GUIScoreboard = self

    if self.visible and key == InputKey.MouseButton0 then
        if Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "FakeBot") then
            return false
        end
    end

    local _backgroundGetIsVisible = self.hoverMenu.background:GetIsVisible()
    local result = Plugin.oldGUIScoreboardSendKeyEvent(self, key, down)

    if ChatUI_EnteringChatMessage() then
        return false
    end
    
    if not self.visible then
        return false
    end
    
    if key == InputKey.MouseButton0 then -- and self.mousePressed["LMB"]["Down"] ~= down and down and not MainMenu_GetIsOpened() 
      if _backgroundGetIsVisible then
          return false
      elseif true then --steamId ~= 0 or self.hoverPlayerClientIndex ~= 0 and Shared.GetDevMode()

        local teamColorBg
        local teamColorHighlight
        local playerName = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "Name")
        local teamNumber = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "EntityTeamNumber")
        local isCommander = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "IsCommander")-- and GetIsVisibleTeam(teamNumber)
        
        local textColor = Color(1, 1, 1, 1)
        
        if isCommander then
            teamColorBg = GUIScoreboard.kCommanderFontColor
        elseif teamNumber == 1 then
            teamColorBg = GUIScoreboard.kBlueColor
        elseif teamNumber == 2 then
            teamColorBg = GUIScoreboard.kRedColor
        else
            teamColorBg = GUIScoreboard.kSpectatorColor
        end
        
        teamColorHighlight = teamColorBg * 0.75
        teamColorBg = teamColorBg * 0.5
        
        local steamId = GetSteamIdForClientIndex(self.hoverPlayerClientIndex)
        --self.hoverMenu:AddButton('Obs 信息', teamColorBg, teamColorHighlight, textColor, function()
        --  openUrlObservatory(steamId);
        --end);
        
        self.hoverMenu:AddButton('NS2Panel 信息', teamColorBg, teamColorHighlight, textColor, function()
          openUrlNs2Panel(steamId);
        end);
          
        self.hoverMenu:AddButton('复制NS2ID', teamColorBg, teamColorHighlight, textColor, function()
          Shine.GUI.SetClipboardText(tostring(steamId))
        end);
      end
    end

    return false;
  end
  