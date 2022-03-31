Script.Load("lua/Badges_Shared.lua")

local ClientId2Badges = {}

--cache owned badges
local ownedBadges = {}

--Assign badges to client based on the hive response
function Badges_FetchBadges(_, response)
    local badges = response or {}

    badges = Badges_FetchBadgesFromDLC(badges)
    badges = Badges_FetchBadgesFromItems(badges)
    badges = Badges_FetchBadgesFromStats(badges)

    for _, badge in ipairs(badges) do
        local badgeid = rawget(gBadges, badge)
        local data = Badges_GetBadgeData(badgeid)
        if data then
            ownedBadges[badgeid] = data.columns
        end
    end

    Badges_ApplyHive1Badges(response)
end

--Returns lookup table of by the client owned badges
function Badges_GetOwnedBadges()
    return ownedBadges
end

local textures = {}
local badgeNames = {}

--------------------    //Insert A Badge Column
local badgeColumns = {}

Client.HookNetworkMessage("DisplayBadge",
    function(msg)
    
        PROFILE("Badges_Client:DisplayBadge")
        
        if not ClientId2Badges[msg.clientId] then
            ClientId2Badges[ msg.clientId ] = {}
            for i = 1, 10 do
                ClientId2Badges[msg.clientId][i] = 1
            end
        end

        ClientId2Badges[msg.clientId][msg.column] = msg.badge

        --reset textures
        textures[msg.clientId] = nil
        badgeNames[msg.clientId] = nil
        badgeColumns[msg.clientId] = nil
    end)
--------------------

--Converts column bitmask into a list
function Badges_GetBadgeColumns(bitmask)
    local columns = {}
    local acc = 1
    for i = 1, kMaxBadgeColumns do
        if bit.band(bitmask, acc) ~= 0 then
            columns[#columns+1] = i
        end

        acc = acc * 2
    end

    return columns
end

--cache non empty columns
local selectedRows = {}

Client.HookNetworkMessage("BadgeRows",
    function(msg)
    
        PROFILE("Badges_Client:BadgeRows")
        
        if msg.columns == 0 then
            ownedBadges[msg.badge] = nil
        else
            ownedBadges[msg.badge] = msg.columns
            
            --Check for empty columns and autoselect available badge
            local columns = Badges_GetBadgeColumns(msg.columns)
            for i = 1, #columns do
                local column = columns[i]
                if not selectedRows[column] then
                    local badge = Client.GetOptionString( string.format("Badge%s", column), "" )
                    if badge == "" or badge == "none" then
                        SelectBadge(msg.badge, column)
                        break
                    else
                        selectedRows[column] = true
                    end
                end
            end
        end
        
        -- Inform the badge customizer that the owned badges set might have changed.
        -- Attempt to update the associated badge object, if available.
        local badgeCustomizer = GetBadgeCustomizer()
        if badgeCustomizer then
            badgeCustomizer:UpdateOwnedBadges()
            
            local badgeName = gBadges[msg.badge]
            if badgeName then
                local badgeObj = badgeCustomizer:GetBadgeObjByName(badgeName)
                if badgeObj then
                    badgeObj:SetColumns(msg.columns)
                end
            end
            
            badgeCustomizer:UpdateActiveBadges()
        end
        
    end)

Client.HookNetworkMessage("BadgeName",
    function(msg)
    
        PROFILE("Badges_Client:BadgeName")
        
        Badges_SetName(msg.badge, msg.name)
    end)

function Badges_GetBadgeTextures( clientId, usecase )

    PROFILE("Badges_GetBadgeTextures")
    
    local badges = ClientId2Badges[clientId]
    if badges then
        if not textures[clientId] then
            textures[clientId] = {}
            badgeNames[clientId] = {}
            badgeColumns[clientId] = {}
            
            local column = 0
            local count = 0
            for _, badge in ipairs(badges) do
                local data = Badges_GetBadgeData(badge)
                local textureTyp = usecase == "scoreboard" and "scoreboardTexture" or "unitStatusTexture"
                column = column + 1
                if data then
                    count = count + 1
                    textures[clientId][count] = data[textureTyp]
                    badgeNames[clientId][count] = data.name
                    badgeColumns[clientId][count] = column
                end
            end
        end

        return textures[clientId], badgeNames[clientId] , badgeColumns[clientId]
    else
        return {}, {}
    end

end

-- temp cache of often used function
local StringFormat = string.format

local badgeSentValueCache = {}
function SelectBadge(badgeId, column)
    
    -- Check a cache of badge values to ensure we don't send unnecessary network messages.
    if badgeSentValueCache[column] == badgeId then
        return
    end
    badgeSentValueCache[column] = badgeId
    
    Client.SetOptionString( StringFormat( "Badge%s", column ), gBadges[badgeId] )
    if Client.GetIsConnected() then
        Client.SendNetworkMessage( "SelectBadge", BuildSelectBadgeMessage(badgeId, column), true)
    end
end

local function OnConsoleBadge( badgename, column)
    column = tonumber( column )

    local badgeid = rawget(gBadges, badgename)
    if not column or column < 0 or column > 10 then column = 5 end

    local sSavedBadge = Client.GetOptionString( StringFormat( "Badge%s", column ), "" )

    if StringTrim( badgename ) == "" then
        Print( StringFormat( "Saved Badge: %s", sSavedBadge or "none" ))
    elseif badgename == "-" or badgeid and badgeid == 1 then
        SelectBadge( gBadges.none, column )
    elseif badgename == sSavedBadge then
        Print( "You already have selected the requested badge" )
    elseif badgeid and ownedBadges[badgeid] then
        SelectBadge( badgeid, column )
    else
        Print( "Either you don't own the requested badge at this server or it doesn't exist." )
    end
end
Event.Hook( "Console_badge", OnConsoleBadge)

function Badges_ApplyHive1Badges(badges)
    local hiveOneApplied = Client.GetOptionBoolean( "Hive1BadgesConverted", false )
    if hiveOneApplied or not badges then return end

    Client.SetOptionBoolean( "Hive1BadgesConverted", true )

    for i = 1, 3 do
        if rawget(gBadges, badges[i]) then
            SelectBadge(gBadges[badges[i]], 6 + i)
        end
    end

    if badges[#badges] == "pax2012" then
        SelectBadge(gBadges.pax2012, 10)
    end
end

--requests the in the config selected badges from the server
local function OnLoadComplete()
    
    local badges = {}
    badges = Badges_FetchBadgesFromItems(badges)
    badges = Badges_FetchBadgesFromStats(badges)

    for _, badge in ipairs(badges) do
        local badgeid = rawget(gBadges, badge)
        local data = Badges_GetBadgeData(badgeid)
        if data then
            ownedBadges[badgeid] = data.columns
        end
    end

    for i = 1, 10 do
        local sSavedBadge = Client.GetOptionString( StringFormat("Badge%s", i), "" )
        if sSavedBadge and sSavedBadge ~= "" and Client.GetIsConnected() then
            local badgeid = rawget(gBadges, sSavedBadge)
            if badgeid then
                --check if we own the given item badge before requesting it
                local badgedata = Badges_GetBadgeData(badgeid)
                if badgedata and (not badgedata.itemId or ownedBadges[badgeid]) then
                    Client.SendNetworkMessage( "SelectBadge", BuildSelectBadgeMessage(badgeid, i), true)
                end
            end
        end
    end
    
end
Event.Hook( "LoadComplete", OnLoadComplete )