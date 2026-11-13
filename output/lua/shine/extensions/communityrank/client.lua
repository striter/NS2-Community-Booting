local Plugin = ...

function Plugin:Initialise()
    Shine.Hook.SetupClassHook( "GUIScoreboard", "UpdateTeam", "OnGUIScoreboardUpdateTeam", "PassivePost" )
    Plugin._GUIScoreboardUpdateTeam = Shine.ReplaceClassMethod("GUIScoreboard", "UpdateTeam", self.GUIScoreboardUpdateTeam);
    Plugin.oldGUIScoreboardSendKeyEvent = Shine.ReplaceClassMethod("GUIScoreboard", "SendKeyEvent", Plugin.GUIScoreboardSendKeyEvent);
    return true
end

function Plugin:OnFirstThink()
    self.playerCommunityData = {
        Tier = 0,
        TimePlayed = 0,
        RoundWin = 0,
        TimePlayedCommander = 0,
        RoundWinCommander = 0,
    }
    self.playerCommunityGadgets = {}
end

Shine.HookNetworkMessage( "Shine_CommunityGadgets", function(Message)
    --Shared.Message(string.format("[CNCT] Item Get %i",Message.ItemID))
    Plugin.playerCommunityGadgets[Message.ItemID] = true
end )

local baseOwnsItem = GetOwnsItem
function GetOwnsItem( _item )
    return true
end

Shine.HookNetworkMessage( "Shine_CommunityTier", function( Message )
    Plugin.playerCommunityData = Message
    --Shared.Message(string.format("[CNCT] Tier Set %i|%i|%i|%i|%i|%i|%i",
    --        Message.Tier,Message.TimePlayed,Message.RoundWin,Message.TimePlayedCommander,Message.RoundWinCommander,Message.MemberLevel,Message.MemberDaysLeft ))

    local skillTierIcon = GetMainMenu().navBar.playerScreen.skillTierIcon
    local isRookie = skillTierIcon:GetIsRookie()
    local skill = skillTierIcon:GetSkill()
    local isBot = skillTierIcon:GetIsBot()
    local adagradSum = skillTierIcon:GetAdagradSum()
    local skillTier, tierTooltip = GetPlayerSkillTier(skill, isRookie, adagradSum, isBot)
    local tooltip = string.format(Locale.ResolveString("SKILLTIER_TOOLTIP"), Locale.ResolveString(tierTooltip), skillTier)
    tooltip = tooltip .. "\n" .. string.format(Locale.ResolveString("COMMUNITY_RANK"),Message.Tier)
    tooltip = tooltip .. "\n" .. string.format(Locale.ResolveString("PLAY_HISTORY"),math.floor(Message.TimePlayed / 720),Message.RoundWin)
    if Message.TimePlayedCommander > 0 then
        tooltip = tooltip .. "\n" .. string.format(Locale.ResolveString("COMMANDER_HISTORY"),math.floor(Message.TimePlayedCommander / 60),Message.RoundWinCommander)
    end

    if(Message.MemberLevel > 0) then
        tooltip = tooltip .. "\n\n" .. string.format(Locale.ResolveString("COMMUNITY_MEMBER_LEVEL"),Locale.ResolveString(string.format("COMMUNITY_MEMBER_LEVEL%i",Message.MemberLevel)))
        tooltip = tooltip .. string.format(Locale.ResolveString("COMMUNITY_MEMBER_LEVEL_DATETIME"),Message.MemberDaysLeft)
    end
    
    skillTierIcon:GetIconObject():SetTooltip(tooltip)

    
    Shine.Hook.SetupGlobalHook( "GetOwnsItem", "GetCommunityOwnsItem", "Replace" )

    GetGlobalEventDispatcher():FireEvent("OnUserStatsAndItemsRefreshed")
    SendPlayerCallingCardUpdate()
    SendPlayerVariantUpdate()
    GetCustomizeScene():RefreshOwnedItems()
    GetBadgeCustomizer():UpdateOwnedBadges()
end )

function Plugin:GetCommunityData()
    return self.playerCommunityData
end

local function CommunityRankUnlocks(_itemId, _tier)
    for index,unlocks in pairs(gCommunityUnlocks) do
        if _tier >= index then
            for k,v in pairs(unlocks) do
                if v == _itemId then
                    return true
                end
            end
        end
    end
end

local function GetTDItemId(tdItem,tdData)
    local ccId = GetThunderdomeRewardCallingCardId(tdItem)
    if ccId then
        return GetCallingCardItemId(ccId)
    end
    return tdData.itemId
end
local function CommunityTDUnlocks(_itemId,data)
    for tdItem,tdData in pairs(kThunderdomeTimeRewardsData) do
        if GetTDItemId(tdItem,tdData) == _itemId then
            local comparer = math.floor( (GetIsThunderdomeRewardCommander(tdItem) and data.TimePlayedCommander or data.TimePlayed ) / 60)
            return comparer >= tdData.progressRequired
        end
    end

    for tdItem,tdData in pairs(kThunderdomeVictoryRewardsData) do
        if GetTDItemId(tdItem,tdData) == _itemId then
            local comparer = GetIsThunderdomeRewardCommander(tdItem) and data.RoundWinCommander or data.RoundWin
            return comparer >= tdData.progressRequired
        end
    end
    return false
end


function Plugin:GetCommunityOwnsItem(_itemId)
    if self.playerCommunityGadgets[_itemId] then
        return true
    end

    local data = self.playerCommunityData

    if CommunityTDUnlocks(_itemId,data) then
        return true
    end

    if CommunityRankUnlocks(_itemId,data.Tier) then
        return true
    end

    return baseOwnsItem(_itemId)
end

local kZeroStr = "0"
local kSkillTierIconTexture = "ui/skill_tier_icons.dds"
local kBuildMenuIconTexture = "ui/buildmenu.dds"
local kCommunityRankIconTexture = "ui/CommunityRankIcons.dds"
-- Every icon in the tooltip runs 20% smaller than the tier emblem on the player name row, which keeps full size.
local kTooltipIconScale = 0.8
-- Display sizes are chosen so the visible artwork matches across the atlases:
-- buildmenu cells are ~72% filled and the CommunityRankIcons emblems ~92%.
local kTechIconSize = 25 * kTooltipIconScale
-- Every emblem in the tooltip shares one box with the badge strip, only the featured corner badge is larger.
local kCommunityIconSize = 16 * kTooltipIconScale
-- Tech icons take the tint the in game tech map paints researched techs with (kTechMapIconColors Available
-- in ns2\lua\GUITechMap.lua), so the same buildmenu cell reads alike in both places.
local kMarineIconColor = Color(0.8, 1, 1, 1)
local kAlienIconColor = Color(1, 0.9, 0.4, 1)
-- Score values keep the paler team accents so the numbers stay readable on the dark panel.
local kMarineAccentColor = Color(0.75, 0.96, 1, 1)
local kAlienAccentColor = Color(1, 0.93, 0.75, 1)
-- Free text lines without an icon are dimmed so they read as notes next to the data rows.
local kSecondaryTextColor = Color(0.74, 0.80, 0.88, 1)
-- The player name header is drawn one font step larger than the data rows.
local kTooltipTitleScale = 1.3
-- Section headings sit between the data rows and the player name.
local kTooltipSectionScale = 1.15
-- Extra spacing under the rows below the tier section, so those blocks do not read as one dense wall.
local kSectionRowGap = 2

-- Faction tech icons from the buildmenu atlas (80px cells, 12 columns): CommandStation (0,0) and Hive (160,0)
-- for the commander lines, Shotgun (80,560) and Fade (480,160) for the field lines.
local kMarineFactionIcon = { texture = kBuildMenuIconTexture, x1 = 0, y1 = 0, x2 = 80, y2 = 80, width = kTechIconSize, height = kTechIconSize, color = kMarineIconColor }
local kAlienFactionIcon = { texture = kBuildMenuIconTexture, x1 = 160, y1 = 0, x2 = 240, y2 = 80, width = kTechIconSize, height = kTechIconSize, color = kAlienIconColor }
local kMarineFieldIcon = { texture = kBuildMenuIconTexture, x1 = 80, y1 = 560, x2 = 160, y2 = 640, width = kTechIconSize, height = kTechIconSize, color = kMarineIconColor }
local kAlienFieldIcon = { texture = kBuildMenuIconTexture, x1 = 480, y1 = 160, x2 = 560, y2 = 240, width = kTechIconSize, height = kTechIconSize, color = kAlienIconColor }

-- Mirrors the CommunityRankIcons rows used by the scoreboard icon band.
local kCommunityRankIndex =
{
    ["RANK_C1"] = 1,
    ["RANK_C2"] = 2,
    ["RANK_C3"] = 3,
    ["RANK_LIVER"] = 3,
    ["RANK_C4"] = 4,
    ["RANK_C5"] = 5,
    ["RANK_HOST"] = 6,
    ["RANK_ADMIN"] = 6,
}

local kMemberIconRowByLevel = {
    [1] = 12,
    [2] = 13,
}

local function GetCommunityRankIcon(_row)
    return { texture = kCommunityRankIconTexture, x1 = 0, y1 = _row * 80, x2 = 80, y2 = (_row + 1) * 80, width = kCommunityIconSize, height = kCommunityIconSize }
end

-- The tier emblems live in rows of the skill atlas, the same rows the scoreboard SkillIcon draws.
local function GetTierIcon(_row, _scale)
    local scale = _scale or 1
    return { texture = kSkillTierIconTexture, x1 = 0, y1 = _row * 32, x2 = 100, y2 = (_row + 1) * 32 - 1,
        width = 56 * scale, height = 18 * scale }
end

local function GetSkillTierIcon(_playerRecord, _skill, _isCommander)
    local row = GetPlayerSkillTier(_skill, _playerRecord.IsRookie, _playerRecord.AdagradSum, false) + 2
    if _isCommander then
        row = row + 8
    end
    return GetTierIcon(row)
end

-- The emblem of the grade a bare score falls into, which trails that score on its line.
local function GetScoreTierIcon(_score)
    return GetTierIcon(GetPlayerSkillTier(_score, false, nil, false) + 2, kTooltipIconScale)
end

-- The commander variant of a grade's emblem, i.e. the same +8 rows the scoreboard SkillIcon switches to while
-- a player commands. The grade comes from the bare score, so it matches the number it trails.
local function GetCommanderEmblem(_score)
    local row = GetPlayerSkillTier(_score, false, nil, false) + 10
    return GetTierIcon(row, kTooltipIconScale)
end

-- Splits one score into a marine and an alien line. Each side carries its own label, faction icon, value
-- color and the emblem of the grade that value falls into, so the commander pair reads
-- Commander / Hive Mind while the field pair reads Marine / Kharaa. _isCommander swaps that trailing emblem
-- for the commander variant, which is what tells a commander line apart at a glance.
local function AddFactionScoreRows(_rows, _marineTextKey, _alienTextKey, _marineValue, _alienValue, _marineIcon, _alienIcon, _isCommander)
    table.insert(_rows, {
        label = Locale.ResolveString(_marineTextKey),
        value = tostring(_marineValue),
        valueColor = kMarineAccentColor,
        icons = { _marineIcon },
        valueIcon = _isCommander and GetCommanderEmblem(_marineValue) or GetScoreTierIcon(_marineValue),
    })
    table.insert(_rows, {
        label = Locale.ResolveString(_alienTextKey),
        value = tostring(_alienValue),
        valueColor = kAlienAccentColor,
        icons = { _alienIcon },
        valueIcon = _isCommander and GetCommanderEmblem(_alienValue) or GetScoreTierIcon(_alienValue),
    })
end

-- A group header: title text with a rule under it, plus an optional note, trailing icons and a badge strip.
local function AddTooltipTitle(_rows, _textKey, _rightText, _rightIcons, _rightBadges)
    table.insert(_rows, { title = Locale.ResolveString(_textKey), rightText = _rightText, rightIcons = _rightIcons,
        rightBadges = _rightBadges, textScale = kTooltipSectionScale })
end

-- Shine's afkkick extension prefixes AFK players with "AFK - " (Plugin.AFK_PREFIX in afkkick\shared.lua).
-- The scoreboard row already marks them, so the header only shows the real name.
local kAfkNamePrefix = "AFK - "

local function GetDisplayName(_name)
    if _name and string.sub(_name, 1, #kAfkNamePrefix) == kAfkNamePrefix then
        return string.sub(_name, #kAfkNamePrefix + 1)
    end
    return _name or ""
end

-- Packs the free text data into one right aligned line, which keeps it inside the section above.
local function AddTooltipStatsLine(_rows, _cells)
    if #_cells > 0 then
        table.insert(_rows, { text = table.concat(_cells, "   "), textColor = kSecondaryTextColor, align = "right" })
    end
end

Plugin.GUIScoreboardUpdateTeam = function(scoreboard, updateTeam)
    Plugin._GUIScoreboardUpdateTeam(scoreboard, updateTeam)
    local playerList = updateTeam["PlayerList"]
    local teamScores = updateTeam["GetScores"]()
    local teamNumber = updateTeam["TeamNumber"]
    local currentPlayerIndex = 1

    for _, player in ipairs(playerList) do
        if not scoreboard.hoverMenu.background:GetIsVisible() and not MainMenu_GetIsOpened() then

            local pr = teamScores[currentPlayerIndex]
            if pr == nil
                    or pr.FakeBot == nil
            then return end

            local skillIcon = player.SkillIcon
            if pr.FakeBot then  --Fake BOT
                skillIcon:SetTexturePixelCoordinates(0, 1 * 32, 100, 2 * 32 - 1)
                player["Ping"]:SetText(kZeroStr)
            end

            if MouseTracker_GetIsVisible() then
                local mouseX, mouseY = Client.GetCursorPosScreen()
                if skillIcon:GetIsVisible() and GUIItemContainsPoint(skillIcon, mouseX, mouseY) then
                    local rows = {}
                    if pr.FakeBot or pr.SteamId == 0 then
                        table.insert(rows, { text = string.format(Locale.ResolveString("SKILLTIER_TOOLTIP"), Locale.ResolveString("SKILLTIER_BOT"),-1) })
                    else
                        local skillOffset = pr.IsCommander and pr.CommSkillOffset or pr.SkillOffset
                        local playerSkill = pr.IsCommander and pr.CommSkill or pr.Skill
                        if skillOffset and (teamNumber == kTeam1Index or teamNumber == kTeam2Index) then
                            playerSkill = math.max(0, playerSkill + (teamNumber == kTeam1Index and skillOffset or -skillOffset))
                        end
                        -- Badge column ten is the featured slot: it rides on the name header, the rest stay on the strip.
                        local badgeTextures = {}
                        local featuredIndex = nil
                        local clientIndex = player["ClientIndex"]
                        if clientIndex and Badges_GetBadgeTextures then
                            local textures, _, columns = Badges_GetBadgeTextures(clientIndex, "scoreboard")
                            for i, texture in ipairs(textures or {}) do
                                if texture and texture ~= "" then
                                    table.insert(badgeTextures, texture)
                                    if columns and columns[i] == 10 then
                                        featuredIndex = #badgeTextures
                                    end
                                end
                            end
                        end
                        local featuredBadge = nil
                        if featuredIndex then
                            featuredBadge = table.remove(badgeTextures, featuredIndex)
                        elseif #badgeTextures >= 10 then
                            featuredBadge = table.remove(badgeTextures, 10)
                        end

                        -- Section header: the name sits at the top left with the tier line at the top right.
                        local displayName = GetDisplayName(pr.Name)
                        table.insert(rows, { text = displayName, align = "left", textScale = kTooltipTitleScale,
                            icons = { GetSkillTierIcon(pr, playerSkill, pr.IsCommander) }, iconsAlign = "right",
                            leadingBadge = featuredBadge })
                        -- The section title already names the skill tier, so the note carries the grade alone.
                        local _, tierName = GetPlayerSkillTier(playerSkill, pr.IsRookie, pr.AdagradSum, false)
                        AddTooltipTitle(rows, "COMMUNITY_SB_TITLE_SCORE", Locale.ResolveString(tierName))

                        if pr.CommSkill > 0 then
                            local commMarineValue = math.max(0, pr.CommSkill + (pr.CommSkillOffset or 0))
                            local commAlienValue = math.max(0, pr.CommSkill - (pr.CommSkillOffset or 0))
                            AddFactionScoreRows(rows, "COMMUNITY_SB_COMM_MARINE", "COMMUNITY_SB_COMM_ALIEN", commMarineValue, commAlienValue,
                                kMarineFactionIcon, kAlienFactionIcon, true)
                        end
                        AddFactionScoreRows(rows, "COMMUNITY_SB_SKILL_MARINE", "COMMUNITY_SB_SKILL_ALIEN", math.max(0,pr.Skill + (pr.SkillOffset or 0)), math.max(0,pr.Skill - (pr.SkillOffset or 0)), kMarineFieldIcon, kAlienFieldIcon)

                        -- The community group sits on the section header's right edge together with its badges; the
                        -- prewarm tier rides just left of the rank badge instead of taking a row of its own.
                        local communityStart = #rows + 1
                        local rankIconRow = kCommunityRankIndex[pr.Group] or 0
                        local titleIcons = {}
                        if pr.prewarmTier ~= nil and pr.prewarmTier > 0 then
                            table.insert(titleIcons, GetCommunityRankIcon(pr.prewarmTier + 6))
                        end
                        if rankIconRow > 0 then
                            table.insert(titleIcons, GetCommunityRankIcon(rankIconRow))
                        end
                        AddTooltipTitle(rows, "COMMUNITY_SB_TITLE_COMMUNITY", Locale.ResolveString(pr.Group),
                            #titleIcons > 0 and titleIcons or nil)

                        local stats = {}
                        if pr.ns2TimePlayed > 0 then
                            table.insert(stats, string.format(Locale.ResolveString("NS2_TIME_PLAYED"), pr.ns2TimePlayed))
                        end
                        if pr.prewarmTime > 0 then
                            table.insert(stats, string.format( Locale.ResolveString("COMMUNITY_PLAYTIME"), pr.prewarmTime))
                        end
                        if pr.reputation ~= 0 then
                            table.insert(stats, (pr.reputation > 0 and string.format(Locale.ResolveString("COMMUNITY_REPUTATION_POSITIVE"),pr.reputation > 256 and ">=256" or pr.reputation )
                                    or string.format(Locale.ResolveString("COMMUNITY_REPUTATION_NEGATIVE"),-pr.reputation )))
                        end
                        if pr.prewarmTime > 0 and pr.prewarmScore > 0 then
                            table.insert(stats, string.format( Locale.ResolveString("COMMUNITY_PREWARM"), pr.prewarmScore))
                        end
                        if pr.memberLevel ~= 0 then
                            local memberIconRow = kMemberIconRowByLevel[pr.memberLevel] or 0
                            table.insert(rows, {
                                text = string.format(Locale.ResolveString("COMMUNITY_MEMBER_LEVEL"),Locale.ResolveString(string.format("COMMUNITY_MEMBER_LEVEL%i",pr.memberLevel))),
                                icons = memberIconRow > 0 and { GetCommunityRankIcon(memberIconRow) } or nil })
                        end
                        -- The previous nickname sits under the member row so it never crowds the name row.
                        if pr.lastSeenName ~= "" and pr.lastSeenName ~= nil and pr.lastSeenName ~= displayName then
                            table.insert(rows, { text = Locale.ResolveString("LAST_SEEN_NAME") .. " " .. pr.lastSeenName,
                                textColor = kSecondaryTextColor, align = "right" })
                        end
                        -- The free text data closes the section, below the previous nickname.
                        AddTooltipStatsLine(rows, stats)

                        -- The remaining badges close the tooltip as a strip on the signature header.
                        local signature = pr.signature
                        if (signature ~= "" and signature ~= nil) or #badgeTextures > 0 then
                            AddTooltipTitle(rows, "COMMUNITY_SB_TITLE_SIGNATURE", nil, nil, badgeTextures)
                            if signature ~= "" and signature ~= nil then
                                table.insert(rows, { text = signature, textColor = kSecondaryTextColor, align = "right" })
                            end
                        end

                        -- Everything below the tier section gets two extra pixels of spacing, which keeps the
                        -- community and signature blocks from reading as one dense wall of text.
                        for i = communityStart, #rows do
                            rows[i].gap = kSectionRowGap
                        end
                    end
                    if scoreboard.ShowIconTooltip then
                        scoreboard.badgeNameTooltip:Hide(0)
                        scoreboard:ShowIconTooltip(rows, mouseX, mouseY)
                    end
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

            local player = Client.GetLocalPlayer()
            if player and player.prewarmTier > 0 and steamId ~= Client.GetSteamId() then
                self.hoverMenu:AddButton('给予预热点', teamColorBg, teamColorHighlight, textColor, function()
                    Shared.ConsoleCommand(string.format("sh_prewarm_give %s",steamId))
                end);
            end

            self.hoverMenu:AddButton('社区信息', teamColorBg, teamColorHighlight, textColor, function()
                Shared.ConsoleCommand(string.format("sh_history_check %s",steamId))
            end);

            self.hoverMenu:AddButton('复制NS2ID', teamColorBg, teamColorHighlight, textColor, function()
                Shine.GUI.SetClipboardText(tostring(steamId))
            end);
        end
    end

    return false;
end
  