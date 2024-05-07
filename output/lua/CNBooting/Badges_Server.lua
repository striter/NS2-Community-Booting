--Modifications--
--2024.5.8  [GiveBadge] Remove official requirement , since the games dead on official 

Script.Load("lua/Badges_Shared.lua")

--Queue for clients that still wait for their hive response
local gBadgeClientRequestQueue = {}

--Cache for changed badge names
local gBadgeNameCache = {}

--stores all badges each client owns
local userId2OwnedBadges = {}

--cache dev ids for the achievement
local gClientIdDevs = {}

--lookup table for connected clients via their userID
local userId2ClientId = {}

--stores arrays of the selected badges of each player
local gClientId2Badges = {}



local function OnClientConnect(client)
    if not client or client:GetIsVirtual() then return end

    userId2ClientId[client:GetUserId()] = client:GetId()

    -- Send this client the badge info for all existing clients
    for clientId, badges in pairs(gClientId2Badges) do
        for column, badge in ipairs(badges) do
            if badge > gBadges.none then
                Server.SendNetworkMessage( client, "DisplayBadge", BuildDisplayBadgeMessage(clientId, badge, column), true )
            end
        end
    end

    local ownedbadges = userId2OwnedBadges[client:GetUserId()]
    if ownedbadges then
        for badgeid, columns in pairs(ownedbadges) do
            Server.SendNetworkMessage(client, "BadgeRows", BuildBadgeRowsMessage(badgeid, columns), true)
        end
    end

    for _, msg in ipairs(gBadgeNameCache) do
        Server.SendNetworkMessage(client, "BadgeName", msg, true)
    end

end

--Assign badges to client based on the hive response
function Badges_FetchBadges(clientId, response)
    local badges = response or {}

    local client = Server.GetClientById(clientId)
    if not client then return end

    local userId = client:GetUserId()
    
    badges = Badges_FetchBadgesFromDLC(badges, client)
    badges = Badges_FetchBadgesFromStats(badges, client)

    userId2OwnedBadges[userId] = userId2OwnedBadges[userId] or {}
    for _, badge in ipairs(badges) do
        local badgeid = rawget(gBadges, badge)
        local badgedata = Badges_GetBadgeData(badgeid)
        if badgedata then
            userId2OwnedBadges[userId][badgeid] = badgedata.columns

            local queuedColumns = gBadgeClientRequestQueue[clientId] and gBadgeClientRequestQueue[clientId][badgeid]
            if queuedColumns then
                for i, queuedColumn in ipairs(queuedColumns) do
                    if Badges_SetBadge(clientId, badgeid, queuedColumn) then
                        table.remove(gBadgeClientRequestQueue[clientId][badgeid], i)
                    end
                end
            end
            Server.SendNetworkMessage(client, "BadgeRows", BuildBadgeRowsMessage(badgeid, badgedata.columns), true)

            if (badge == "dev" or badge == "community_dev") then
                gClientIdDevs[userId] = true
            end
        end
    end

    OnClientConnect(client)
end

function Badges_HasDevBadge(userId)
    return gClientIdDevs[userId]
end

function SetFormalBadgeName(badgename, name)
    local badgeid = gBadges[badgename]
    local setName = Badges_SetName(badgeid, name)

    if setName then
        local msg = { badge = badgeid, name = name}
        gBadgeNameCache[#gBadgeNameCache + 1] = msg
        Server.SendNetworkMessage("BadgeName", msg, true)

        return true
    end

    return false
end

function GiveBadge(userId, badgeName, column)
    local badgeid = rawget(gBadges, badgeName)
    if not badgeid then
        return false
    end

    local badgedata = Badges_GetBadgeData(badgeid)
    if not badgedata then -- or badgedata.isOfficial then
        return false
    end

    local ownedBadges = userId2OwnedBadges[userId] or {}

    local columns = ownedBadges[badgeid]
    if not columns then columns = 0 end

    column = column and bit.lshift(1, (column-1)) or 16
    columns = bit.bor(columns,column)
    ownedBadges[badgeid] = columns

    userId2OwnedBadges[userId] = ownedBadges

    local clientId = userId2ClientId[userId]
    local client = clientId and Server.GetClientById(clientId)

    if client then
        local queuedColumns = gBadgeClientRequestQueue[clientId] and gBadgeClientRequestQueue[clientId][badgeid]
        if queuedColumns then
            for i, queuedColumn in ipairs(queuedColumns) do
                if Badges_SetBadge(clientId, badgeid, queuedColumn) then
                    table.remove(gBadgeClientRequestQueue[clientId][badgeid], i)
                end
            end
        end

        Server.SendNetworkMessage(client, "BadgeRows", BuildBadgeRowsMessage(badgeid, columns), true)
    end

    return true
end

function Badges_SetBadge(clientId, badgeid, column)
    local client = clientId and Server.GetClientById(clientId)
    local userId = client and client:GetUserId()

    if not userId or userId < 1 then --check for virtual clients
        return false
    end

    local ownedbadges = userId2OwnedBadges[userId] or {}

    column = column or 5

    --verify ownership and column
    if badgeid > gBadges.none then
        local columns = ownedbadges[badgeid]
        --check for item badges (currently client sided only)
        if not columns then
            local badgedata = Badges_GetBadgeData(badgeid)
            if badgedata and badgedata.itemId then
                columns = badgedata.columns
            end
        end

        if not columns or bit.band(columns, bit.lshift(1, column - 1)) == 0 then
            return false
        end
    end

    local changed = { column }

    local clientBadges = gClientId2Badges[clientId]

    if not clientBadges then
        clientBadges = {}
        for i = 1, 10 do
            clientBadges[i] = gBadges.none
        end
    end

    if badgeid > gBadges.none then
        for rowId, badge in ipairs(clientBadges) do
            if badge == badgeid then
                clientBadges[rowId] = gBadges.none
                changed[2] = rowId
            end
        end
    end

    clientBadges[column] = badgeid

    gClientId2Badges[clientId] = clientBadges

    for _, changedrow in ipairs(changed) do
        Server.SendNetworkMessage("DisplayBadge", BuildDisplayBadgeMessage(clientId, clientBadges[changedrow], changedrow) ,true)
    end

    return true
end

function Badges_OnClientBadgeRequest(clientId, msg)
    local result = Badges_SetBadge(clientId, msg.badge, msg.column)

    if not result then
        if not gBadgeClientRequestQueue[clientId] then gBadgeClientRequestQueue[clientId] = {} end

        if not gBadgeClientRequestQueue[clientId][msg.badge] then
            gBadgeClientRequestQueue[clientId][msg.badge] =  { msg.column }
        else
            table.insert(gBadgeClientRequestQueue[clientId][msg.badge], msg.column)
        end

    end

    return result
end

Server.HookNetworkMessage("SelectBadge",
    function(client, msg)
        Badges_OnClientBadgeRequest(client:GetId() , msg)
    end)

local function OnClientDisconnect(client)
    if not client or client:GetIsVirtual() then return end

    userId2ClientId[client:GetUserId()] = nil
    gClientId2Badges[ client:GetId() ] = nil
    gBadgeClientRequestQueue[ client:GetId() ] = nil
end

local function OnReceivedStatsForClient(clientSteamId)
    local steam32Id = Shared.ConvertSteamId64To32(clientSteamId)
    Badges_FetchBadges(steam32Id, {})
end

Event.Hook("ClientDisconnect", OnClientDisconnect)
Event.Hook("ReceivedSteamStatsForClient", OnReceivedStatsForClient)