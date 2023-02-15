------------------------------------------
--  Create basic badge tables
------------------------------------------

-- Max number of available badge columns
kMaxBadgeColumns = 10

--List of all available badges
gBadges = {
    "disabled",
    "none",
    "dev",
    "dev_retired",
    "maptester",
    "playtester",
    "ns1_playtester",
    "constellation",
    "hughnicorn",
    "squad5_blue",
    "squad5_silver",
    "squad5_gold",
    "commander",
    "community_dev",
    "reinforced1",
    "reinforced2",
    "reinforced3",
    "reinforced4",
    "reinforced5",
    "reinforced6",
    "reinforced7",
    "reinforced8",
    "wc2013_supporter",
    "wc2013_silver",
    "wc2013_gold",
    "wc2013_shadow",
    "pax2012",
    "ensl_2017",
    "ensl_nc_2017_blue",
    "ensl_nc_2017_silver",
    "ensl_nc_2017_gold",
    "ensl_wc_gold",
    "ensl_wc_silver",
    "ensl_wc_bronze",
    "tournament_mm_blue",
    "tournament_mm_silver",
    "tournament_mm_gold",
    "ensl_s11_gold",
    "ensl_s11_silver",
    "skulk_challenge_1_bronze",
    "skulk_challenge_1_silver",
    "skulk_challenge_1_gold",
    "skulk_challenge_1_shadow",
    "ensl_nc_2017_late_blue",
    "ensl_nc_2017_late_silver",
    "ensl_nc_2017_late_gold",
    "ensl_s12_d1_gold",
    "ensl_s12_d1_silver",
    "ensl_s12_d1_bronze",
    "ensl_s12_d2_gold",
    "ensl_s12_d2_silver",
    "ensl_s12_d2_bronze",
    "ensl_s12_d3_gold",
    "ensl_s12_d3_silver",
    "ensl_s12_d3_bronze",
    "ensl_nc_2019_blue",
    "ensl_nc_2019_silver",
    "ensl_nc_2019_gold",
    "ensl_community_champion_2019_bronze",
    "ensl_community_champion_2019_silver",
    "ensl_community_champion_2019_gold",
    "ensl_intermediate_tournament_2019_bronze",
    "ensl_intermediate_tournament_2019_silver",
    "ensl_intermediate_tournament_2019_gold",
    "ensl_s16_gold",
    "ensl_s16_silver",
    "ensl_s16_bronze",
    "ensl_s17_gold",
    "ensl_s17_silver",
    "ensl_s17_bronze",

    --TD Unlocks
    "td_tier1",
    "td_tier2",
    "td_tier3",
    "td_tier4",
    "td_tier5",
    "td_tier6",
    "td_tier7",
    "td_tier8",
}

--Stores information about textures and names of the Badges
local badgeData = {}

--scope this properly so the GC can clean up directly afterwards
do
    local function MakeBadgeData2(name, ddsPrefix)
        return {
            name = string.upper(string.format("BADGE_%s", name)),
            unitStatusTexture = string.format("ui/badges/%s.dds", ddsPrefix),
            scoreboardTexture = string.format("ui/badges/%s_20.dds", ddsPrefix),
            columns = 960, --column 7,8,9,10
            isOfficial = true,
        }
    end

    local function MakeBadgeData3(name, ddsPrefix)
        return {
            name = string.upper(string.format("BADGE_%s", name)),
            unitStatusTexture = string.format("ui/badges/%s.dds", ddsPrefix),
            scoreboardTexture = string.format("ui/badges/%s_20.dds", ddsPrefix),
            columns = 960, --column 7,8,9,10
            isOfficial = true,
        }
    end

    local function MakeBadgeData(name)
        return MakeBadgeData2(name, name)
    end

    local function MakeDLCBadgeInfo(name, ddsPrefix, productId)
        local info = MakeBadgeData3(name, ddsPrefix)

        info.productId = productId

        return info
    end

    local function MakeItemBadgeData(name, itemId)
        local data = MakeBadgeData3(name, name)

        data.itemId = itemId

        return data
    end

    local function MakeItemBadgeData2(name, ddsPrefix, itemId)
        local data = MakeBadgeData3(name, ddsPrefix)

        data.itemId = itemId

        return data
    end

    -- Someone was VERY lazy when they added these badges... sigh
    local function MakeItemBadgeDataENSLI(name, ddsPrefix, itemId)
        local data = MakeBadgeData3(name, ddsPrefix)

        if ddsPrefix:sub(-1, -1) == "_" then
            data.scoreboardTexture = string.format("ui/badges/%s20x20.dds", ddsPrefix)
        else
            data.scoreboardTexture = string.format("ui/badges/%s_20x20.dds", ddsPrefix)
        end

        data.itemId = itemId

        return data
    end

    local function MakeItemBadgeDataENSLNC17(name, ddsPrefix, itemId)
        local data = MakeBadgeData3(name, ddsPrefix)

        data.scoreboardTexture = string.format("ui/badges/%s.dds", ddsPrefix)

        data.itemId = itemId

        return data
    end

    -- Creates a badge whose availability is tied to which player stats.
    -- badgeName is name of badge and prefix for badge file name.
    -- statName is the api name of the steam user stat associated with the badge.
    -- hasBadgeFunction is evaluated with the value of the stat passed as the only paramter.  If it returns true, this
    --      means the badge is available.  False of course means the badge is not available.
    local function MakeStatsBadgeData(badgeName, statName, statType, hasBadgeFunction)

        local data = MakeBadgeData(badgeName)

        data.statName = statName
        data.statType = statType
        data.hasBadgeFunction = hasBadgeFunction

        return data

    end

    --vanilla badges data
    badgeData["dev"] = MakeItemBadgeData("dev", kBadges_DeveloperItemId)
    badgeData["dev_retired"] = MakeItemBadgeData("dev_retired", kBadges_DeveloperRetiredItemId)
    badgeData["maptester"] = MakeItemBadgeData("maptester", kBadges_MaptesterItemId)
    badgeData["playtester"] = MakeItemBadgeData("playtester", kBadges_PlaytesterItemId)
    badgeData["ns1_playtester"] = MakeItemBadgeData("ns1_playtester", kBadges_Ns1PlaytesterItemId)
    badgeData["constellation"] = MakeItemBadgeData2("constellation", "constelation", kBadges_ConstellationItemId)
    badgeData["hughnicorn"] = MakeItemBadgeData("hughnicorn", kBadges_HughnicornItemId)
    badgeData["squad5_blue"] = MakeItemBadgeData("squad5_blue", kBadges_Squad5BlueItemId)
    badgeData["squad5_silver"] = MakeItemBadgeData("squad5_silver", kBadges_Squad5SilverItemId)
    badgeData["squad5_gold"] = MakeItemBadgeData("squad5_gold", kBadges_Squad5GoldItemId)
    badgeData["commander"] = MakeItemBadgeData("commander", kBadges_CommanderItemId)
    badgeData["community_dev"] = MakeItemBadgeData("community_dev", kBadges_CommunityDevItemId)
    badgeData["reinforced1"] = MakeItemBadgeData2("reinforced1", "game_tier1_blue", kBadges_ReinforcedBlueItemId)
    badgeData["reinforced2"] = MakeItemBadgeData2("reinforced2", "game_tier2_silver", kBadges_ReinforcedSilverItemId)
    badgeData["reinforced3"] = MakeItemBadgeData2("reinforced3", "game_tier3_gold", kBadges_ReinforcedGoldItemId)
    badgeData["reinforced4"] = MakeItemBadgeData2("reinforced4", "game_tier4_diamond", kBadges_ReinforcedDiamondItemId)
    badgeData["reinforced5"] = MakeItemBadgeData2("reinforced5", "game_tier5_shadow", kBadges_ReinforcedShadowItemId)
    badgeData["reinforced6"] = MakeItemBadgeData2("reinforced6", "game_tier6_onos", kBadges_ReinforcedOnosItemId)
    badgeData["reinforced7"] = MakeItemBadgeData2("reinforced7", "game_tier7_Insider", kBadges_ReinforcedInsiderItemId)
    badgeData["reinforced8"] = MakeItemBadgeData2("reinforced8", "game_tier8_GameDirector", kBadges_ReinforcedDirectorItemId)
    badgeData["wc2013_supporter"] = MakeItemBadgeData("wc2013_supporter", kBadges_Wc2013SupportItemId)
    badgeData["wc2013_silver"] = MakeItemBadgeData("wc2013_silver", kBadges_Wc2013SilverItemId)
    badgeData["wc2013_gold"] = MakeItemBadgeData("wc2013_gold", kBadges_Wc2013GoldItemId)
    badgeData["wc2013_shadow"] = MakeItemBadgeData("wc2013_shadow", kBadges_Wc2013ShadowItemId)
    badgeData["pax2012"] = MakeDLCBadgeInfo("pax2012", "badge_pax2012", 4931)
    badgeData["ensl_2017"] = MakeItemBadgeData("ensl_2017", 1001)
    badgeData["ensl_nc_2017_blue"] = MakeItemBadgeDataENSLNC17("ensl_nc_2017_blue", "ensl_nc_2017_blue", 1004)
    badgeData["ensl_nc_2017_silver"] = MakeItemBadgeDataENSLNC17("ensl_nc_2017_silver", "ensl_nc_2017_silver", 1003)
    badgeData["ensl_nc_2017_gold"] = MakeItemBadgeDataENSLNC17("ensl_nc_2017_gold", "ensl_nc_2017_gold", 1002)
    badgeData["ensl_wc_gold"] = MakeItemBadgeData("ensl_wc_gold", 1005)
    badgeData["ensl_wc_silver"] = MakeItemBadgeData("ensl_wc_silver", 1006)
    badgeData["ensl_wc_bronze"] = MakeItemBadgeData("ensl_wc_bronze", 1007)
    badgeData["tournament_mm_blue"] = MakeItemBadgeData("tournament_mm_blue", 1008)
    badgeData["tournament_mm_silver"] = MakeItemBadgeData("tournament_mm_silver", 1009)
    badgeData["tournament_mm_gold"] = MakeItemBadgeData("tournament_mm_gold", 1010)
    badgeData["ensl_s11_gold"] = MakeItemBadgeData("ensl_s11_gold", 1011)
    badgeData["ensl_s11_silver"] = MakeItemBadgeData("ensl_s11_silver", 1012)
    badgeData["ensl_nc_2017_late_blue"] = MakeItemBadgeDataENSLNC17("ensl_nc_2017_late_blue", "ensl_nc_2017_blue", 1015)
    badgeData["ensl_nc_2017_late_silver"] = MakeItemBadgeDataENSLNC17("ensl_nc_2017_late_silver", "ensl_nc_2017_silver", 1014)
    badgeData["ensl_nc_2017_late_gold"] = MakeItemBadgeDataENSLNC17("ensl_nc_2017_late_gold", "ensl_nc_2017_gold", 1013)
    badgeData["ensl_s12_d1_gold"] = MakeItemBadgeData2("ensl_s12_d1_gold", "ensl_2018_gold", 1016)
    badgeData["ensl_s12_d1_silver"] = MakeItemBadgeData2("ensl_s12_d1_silver", "ensl_2018_silver", 1017)
    badgeData["ensl_s12_d1_bronze"] = MakeItemBadgeData2("ensl_s12_d1_bronze", "ensl_2018_bronze", 1018)
    badgeData["ensl_s12_d2_gold"] = MakeItemBadgeData2("ensl_s12_d2_gold", "ensl_2018_gold", 1019)
    badgeData["ensl_s12_d2_silver"] = MakeItemBadgeData2("ensl_s12_d2_silver", "ensl_2018_silver", 1020)
    badgeData["ensl_s12_d2_bronze"] = MakeItemBadgeData2("ensl_s12_d2_bronze", "ensl_2018_bronze", 1021)
    badgeData["ensl_s12_d3_gold"] = MakeItemBadgeData2("ensl_s12_d3_gold", "ensl_2018_gold", 1022)
    badgeData["ensl_s12_d3_silver"] = MakeItemBadgeData2("ensl_s12_d3_silver", "ensl_2018_silver", 1023)
    badgeData["ensl_s12_d3_bronze"] = MakeItemBadgeData2("ensl_s12_d3_bronze", "ensl_2018_bronze", 1024)
    badgeData["ensl_nc_2019_blue"] = MakeItemBadgeData("ensl_nc_2019_blue", 1025)
    badgeData["ensl_nc_2019_silver"] = MakeItemBadgeData("ensl_nc_2019_silver", 1026)
    badgeData["ensl_nc_2019_gold"] = MakeItemBadgeData("ensl_nc_2019_gold", 1027)
    badgeData["ensl_community_champion_2019_bronze"] = MakeItemBadgeData("ensl_community_champion_2019_bronze", 1028)
    badgeData["ensl_community_champion_2019_silver"] = MakeItemBadgeData("ensl_community_champion_2019_silver", 1029)
    badgeData["ensl_community_champion_2019_gold"] = MakeItemBadgeData("ensl_community_champion_2019_gold", 1030)
    badgeData["ensl_intermediate_tournament_2019_bronze"] = MakeItemBadgeDataENSLI("ensl_intermediate_tournament_2019_bronze", "nsl_badge_intermediate_bronze 2019", 1031)
    badgeData["ensl_intermediate_tournament_2019_silver"] = MakeItemBadgeDataENSLI("ensl_intermediate_tournament_2019_silver", "nsl_badge_intermediate_silver 2019_", 1032)
    badgeData["ensl_intermediate_tournament_2019_gold"] = MakeItemBadgeDataENSLI("ensl_intermediate_tournament_2019_gold", "nsl_badge_intermediate_gold 2019", 1033)
    badgeData["ensl_s16_gold"] = MakeItemBadgeData("ensl_s16_gold", 1034)
    badgeData["ensl_s16_silver"] = MakeItemBadgeData("ensl_s16_silver", 1035)
    badgeData["ensl_s16_bronze"] = MakeItemBadgeData("ensl_s16_bronze", 1036)
    badgeData["ensl_s17_gold"] = MakeItemBadgeData("ensl_s17_gold", 1037)
    badgeData["ensl_s17_silver"] = MakeItemBadgeData("ensl_s17_silver", 1038)
    badgeData["ensl_s17_bronze"] = MakeItemBadgeData("ensl_s17_bronze", 1039)

    badgeData["td_tier1"] = MakeItemBadgeData("td_tier1", kTDTier1BadgeItemId)
    badgeData["td_tier2"] = MakeItemBadgeData("td_tier2", kTDTier2BadgeItemId)
    badgeData["td_tier3"] = MakeItemBadgeData("td_tier3", kTDTier3BadgeItemId)
    badgeData["td_tier4"] = MakeItemBadgeData("td_tier4", kTDTier4BadgeItemId)
    badgeData["td_tier5"] = MakeItemBadgeData("td_tier5", kTDTier5BadgeItemId)
    badgeData["td_tier6"] = MakeItemBadgeData("td_tier6", kTDTier6BadgeItemId)
    badgeData["td_tier7"] = MakeItemBadgeData("td_tier7", kTDTier7BadgeItemId)
    badgeData["td_tier8"] = MakeItemBadgeData("td_tier8", kTDTier8BadgeItemId)


    -- stats badges
    badgeData["skulk_challenge_1_bronze"] = MakeStatsBadgeData("skulk_challenge_1_bronze", "skulk_challenge_1", "INT",
            function(value)
                return value ~= nil and value >= 1
            end)
    badgeData["skulk_challenge_1_silver"] = MakeStatsBadgeData("skulk_challenge_1_silver", "skulk_challenge_1", "INT",
            function(value)
                return value ~= nil and value >= 2
            end)
    badgeData["skulk_challenge_1_gold"] = MakeStatsBadgeData("skulk_challenge_1_gold", "skulk_challenge_1", "INT",
            function(value)
                return value ~= nil and value >= 3
            end)
    badgeData["skulk_challenge_1_shadow"] = MakeStatsBadgeData("skulk_challenge_1_shadow", "skulk_challenge_1", "INT",
            function(value)
                return value ~= nil and value >= 4
            end)

    --custom badges
    local badgeFiles = {}
    local officialFiles = {}

    for _, badge in ipairs(gBadges) do
        local data = badgeData[badge]
        if data then
            officialFiles[data.unitStatusTexture] = true
            officialFiles[data.scoreboardTexture] = true
            officialFiles[badge] = true
        end
    end

    Shared.GetMatchingFileNames( "ui/badges/*.dds", false, badgeFiles )
    -- Sort table of badgeFiles to avoid missmatching server/client desync due to different load file mount order
    table.sort(badgeFiles)

    for _, badgeFile in ipairs(badgeFiles) do
        if not officialFiles[badgeFile] then
            local _, _, badgeName = string.find( badgeFile, "ui/badges/(.*).dds" )

            if not officialFiles[badgeName] and not badgeData[badgeName] then --avoid custom badges named like official badges
                local badgeId = #gBadges + 1

                Log("adding custom badgeid %s for badge file %s.dds", badgeId, badgeName)
                gBadges[badgeId] = badgeName

                badgeData[badgeName] = {
                    name = badgeName, --Todo Localize
                    unitStatusTexture = badgeFile,
                    scoreboardTexture = badgeFile,
                    columns = 16, --column 5
                }
            end
        end
    end

    --------------------------------
    -- Shared.Message("Offical Badges:" .. #gBadges)
    for i = #gBadges , 127 do     --Since server/client have different ui/badges/*.dds(wtf was that) just fill a empty proper value to make both enum match.
        -- Shared.Message("Empty Badges:" .. i)
        gBadges[i] = "Empty"
    end
    -- Shared.Message("Total Badges:" .. #gBadges)

    local customBadgeFiles = {}
    local customBadgeIndex = 0
    Shared.GetMatchingFileNames( "ui/customBadges/*.dds", false, customBadgeFiles )
    table.sort(customBadgeFiles)
    -- Shared.Message("Custom Badge Count:" .. #customBadgeFiles)
    for _, badgeFile in ipairs(customBadgeFiles) do
        if not officialFiles[badgeFile] then
            local _, _, badgeName = string.find( badgeFile, "ui/customBadges/(.*).dds" )

            if not officialFiles[badgeName] and not badgeData[badgeName] then --avoid custom badges named like official badges
                local badgeId = #gBadges + 1
                gBadges[badgeId] = badgeName
                -- Shared.Message("Custom Badge:" .. badgeName .. " " .. badgeId)

                badgeData[badgeName] = {
                    name = badgeName, --Todo Localize
                    unitStatusTexture = badgeFile,
                    scoreboardTexture = badgeFile,
                    columns = 16, --column 5
                }
            end
        end
    end
    customBadgeFiles = nil
------------------------

    gBadges = enum(gBadges)

    --List of all badges which are assigned to a DLC
    gDLCBadges = {}

    --List of all badges which are assigned to an item
    gItemBadges = {}

    -- List of all badges which are awarded based on the user's steam stats.
    gStatsBadges = {}

    for badgeId, badgeName in ipairs(gBadges) do
        if badgeId ~= "Empty" then
          -- Shared.Message("Badge Init:" .. badgeId .. " " .. badgeName)
          local badgedata = badgeData[badgeName]
          if badgedata then

              if badgedata.productId then
                  gDLCBadges[#gDLCBadges+1] = badgeId
              end

              if badgedata.itemId then
                  gItemBadges[#gItemBadges+1] = badgeId
              end

              if badgedata.statName then
                  gStatsBadges[#gStatsBadges+1] = badgeId
              end

          end
        end
    end
end

function Badges_GetBadgeData(badgeId)
    local enumVal = rawget(gBadges, badgeId)
    if not enumVal then return nil end
    return badgeData[enumVal]
end

function Badges_GetBadgeDataByName(badgeName)
    assert(type(badgeName) == "string")
    return badgeData[badgeName]
end

function Badges_SetName(badgeId, name)

    -- ensure badge exists in the enum.
    local enumVal = rawget(gBadges, badgeId)
    if not enumVal then return false end

    if not badgeData[gBadges[badgeId]] or not name then return false end

    badgeData[gBadges[badgeId]].name = tostring(name)

    return true
end

-- Returns maximum amount of different badges each player can have selected
function Badges_GetMaxBadges()
    return 10
end

function GetBadgeFormalName(badgename)
    local fullString = badgename and Locale.ResolveString(badgename)

    return fullString or "Custom Badge"
end

--Assign badges based on dlc available
function Badges_FetchBadgesFromDLC(badges, client)
    for _, badgeid in ipairs(gDLCBadges) do
        local data = Badges_GetBadgeData(badgeid)
        if data and GetHasDLC(data.productId, client) then
            badges[#badges + 1] = gBadges[badgeid]
        end
    end

    return badges
end

--Assign badges based on items available
function Badges_FetchBadgesFromItems(badges)
    for _, badgeid in ipairs(gItemBadges) do
        local data = Badges_GetBadgeData(badgeid)
        if data and GetOwnsItem(data.itemId) then
            badges[#badges + 1] = gBadges[badgeid]
        end
    end

    return badges
end

local function GetAreStatsAvailable(client)

    if Client then
        return true -- should always be loaded on client, long before they even join a game.
    elseif Server then

        if not client then
            return false
        end

        for _, badgeId in ipairs(gStatsBadges) do

            local data = Badges_GetBadgeData(badgeId)
            if data then
                local apiFunc
                if data.statType == "INT" then
                    apiFunc = Server.GetHasUserStat_Int
                elseif data.statType == "FLOAT" then
                    apiFunc = Server.GetHasUserStat_Float
                end

                if apiFunc and apiFunc(client, data.statName) then
                    -- When stats are downloaded from Steam, they're all sent at once.  Therefore if we have at least one
                    -- present, we know we have all we're ever going to get. If some are missing, we'll just discard them,
                    -- but it will generate an error message, as it should.
                    return true
                end
            end

        end

    end

    return false

end

-- Assign badges based on user stats
function Badges_FetchBadgesFromStats(badges, client)

    -- Don't attempt to retrieve stat data if it's missing -- we'll get errors for that!
    if not GetAreStatsAvailable(client) then

        if Server then
            -- Request stats from Steam.  When we receive them, this function will be called again.
            Server.RequestUserStats(client)
        end

        return badges
    end

    local sanityTest = Server

    for _, badgeid in ipairs(gStatsBadges) do

        local data = Badges_GetBadgeData(badgeid)
        if data then
            local statValue

            if Server then

                local apiFunc
                if data.statType == "INT" then
                    apiFunc = Server.GetUserStat_Int
                elseif data.statType == "FLOAT" then
                    apiFunc = Server.GetUserStat_Float
                else
                    assert(false)
                end

                pcall(function()
                    statValue = apiFunc(client, data.statName)
                end)

            elseif Client then

                local apiFunc
                if data.statType == "INT" then
                    apiFunc = Client.GetUserStat_Int
                elseif data.statType == "FLOAT" then
                    apiFunc = Client.GetUserStat_Float
                else
                    assert(false)
                end

                pcall(function()
                    statValue = apiFunc(data.statName)
                end)

            else
                assert(false)
            end

            local hasBadge = data.hasBadgeFunction(statValue)
            if hasBadge then
                badges[#badges + 1] = gBadges[badgeid]
            end

        end

    end

    return badges

end

------------------------------------------
--  Create network message spec
------------------------------------------

--Used to network displayed Badges from Server to Client
function BuildDisplayBadgeMessage(clientId, badge, column)
    return {
        clientId = clientId,
        badge = badge,
        column = column
    }
end

local kBadgesMessage =
{
    clientId = "entityid",
    badge = "enum gBadges",
    column = string.format("integer (0 to %s)", kMaxBadgeColumns)
}
Shared.RegisterNetworkMessage("DisplayBadge", kBadgesMessage)

--Used to network the badge selection of the client to the server
function BuildSelectBadgeMessage(badge, column)
    return {
        badge = badge,
        column = column
    }
end

local kBadgesMessage =
{
    badge = "enum gBadges",
    column = string.format("integer (0 to %s)", kMaxBadgeColumns)
}
Shared.RegisterNetworkMessage("SelectBadge", kBadgesMessage)

--Used to network the allowed columns of a badge from the server to the client
--columns are represented as bitsmask from right to left: 1 = first column, 2(bin: 10) = second column
function BuildBadgeRowsMessage(badge, columns)
    return {
        badge = badge,
        columns = columns
    }
end

local kBadgeRowsMessage =
{
    badge = "enum gBadges",
    columns = string.format("integer (0 to %s)", 2^(kMaxBadgeColumns+1)-1)
}

Shared.RegisterNetworkMessage("BadgeRows", kBadgeRowsMessage)

--Used to send the badge names to the client
local kBadgeBroadcastMessage =
{
    badge = "enum gBadges",
    name = "string (128)"
}

Shared.RegisterNetworkMessage("BadgeName", kBadgeBroadcastMessage)
