-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\VotingChangeMap.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- How many seconds to wait after the vote is complete before executing.
local kExecuteVoteDelay = 10

local kMaxMapNameLength = 32
Shared.RegisterNetworkMessage("AddVoteMap", { name = "string (" .. kMaxMapNameLength .. ")", index = "integer (0 to 255)" })

RegisterVoteType("VoteChangeMap", { map_index = "integer" })

if Client then
    
    
    local serverMapList = { }
    local serverMapIndices = { }
    local function OnAddVoteMap(message)
        table.insert(serverMapList, { text = message.name, extraData = { map_index = message.index } })
        serverMapIndices[message.index] = message.name
    end
    
    local function GetMapList()
        if Shine then
            local MVEnabled, MVPlugin = Shine:IsExtensionEnabled( "mapvote" )

            local mapList = {}
            for _,mapdata in ipairs(serverMapList) do
                table.insert(mapList, { text = MVPlugin:GetNiceMapName(mapdata.text), extraData = mapdata.extraData })
            end
            return mapList
        end
        return serverMapList
    end
    
    Client.HookNetworkMessage("AddVoteMap", OnAddVoteMap)
    
    local function SetupChangeMapVote(voteMenu)

        if GetStartVoteAllowedForThunderdome("VoteChangeMap") then
            local function StartChangeMapVote(data)
                if Shine then
                    local MVEnabled, MVPlugin = Shine:IsExtensionEnabled( "mapvote" ) 
                    if MVEnabled then
                        Shared.ConsoleCommand(string.format("sh_nominate %s", serverMapIndices[data.map_index]))
                        --Shared.ConsoleCommand("sh_votemap")
                        return
                    end
                end
                AttemptToStartVote("VoteChangeMap", { map_index = data.map_index })
            end
            voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_CHANGE_MAP"), GetMapList, StartChangeMapVote)
        end
        
        -- This function translates the networked data into a question to display to the player for voting.
        local function GetVoteChangeMapQuery(data)
            return StringReformat(Locale.ResolveString("VOTE_CHANGE_MAP_QUERY"), { name = serverMapIndices[data.map_index] })
        end
        AddVoteStartListener("VoteChangeMap", GetVoteChangeMapQuery)
        
    end
    AddVoteSetupCallback(SetupChangeMapVote)
    
end

if Server then
    
    -- finds every map with "ns2_" as a prefix, and, attempts to replace it with "[prefix]_" in order to add
    -- more game modes via different map names (for the same level data).  The map will only be added to the
    -- vote menu if the map (with altered prefix) is included in the server's MapCycle.
    local function AddMapPrefixesToVoteMenu(client,prefix, mapIndex)
        
        mapIndex = mapIndex or (Server.GetNumMaps() + 1)
        
        for i=1, Server.GetNumMaps() do
            
            local mapName = prefix .. "_" .. string.sub( Server.GetMapName(i), string.len( "ns2_" ) + 1 )
            if MapCycle_GetMapIsInCycle(mapName) then
                Server.SendNetworkMessage( client, "AddVoteMap", {name = mapName, index = mapIndex}, true)
                mapIndex = mapIndex + 1
            end
            
        end
        
        return mapIndex
        
    end
    
    -- Send new Clients the map list.
    local function OnClientConnect(client)

        for i = 1, Server.GetNumMaps() do

            local mapName = Server.GetMapName(i)
            if MapCycle_GetMapIsInCycle(mapName) then
                Server.SendNetworkMessage(client, "AddVoteMap", { name = mapName, index = i }, true)
            end
            
        end
        
        -- Add official game mode mods to the player's map list.  (For example, infested marines uses vanilla maps, and the
        -- game mode is activated by the map previx being "infested" or "infected".
        local mapCount = nil
        mapCount = AddMapPrefixesToVoteMenu(client,"infest", mapCount)
        mapCount = AddMapPrefixesToVoteMenu(client,"infect", mapCount)
        mapCount = AddMapPrefixesToVoteMenu(client,"def", mapCount)
        mapCount = AddMapPrefixesToVoteMenu(client,"ns2.0", mapCount)
        
    end
    Event.Hook("ClientConnect", OnClientConnect)
    
    local function CheckForMapPrefix(prefix, data, mapIndex)
        
        mapIndex = mapIndex or (Server.GetNumMaps() + 1)
        for i=1, Server.GetNumMaps() do
            local mapName = prefix .. "_" .. string.sub( Server.GetMapName(i), string.len( "ns2_") + 1)
            if MapCycle_GetMapIsInCycle(mapName) then
                if mapIndex == data.map_index then
                    MapCycle_ChangeMap(mapName)
                    return mapIndex, true
                end
                mapIndex = mapIndex + 1
            end
        end
        
        return mapIndex, false
        
    end
    
    
    local checkPrefixes = {"infest", "infect"}
    local function OnChangeMapVoteSuccessful(data)
        
        if data.map_index > Server.GetNumMaps() then
            local result = false
            local mapIndex = nil
            for i=1, #checkPrefixes do
                mapIndex, result = CheckForMapPrefix(checkPrefixes[i], data, mapIndex)
                if result then
                    return
                end
            end
        end
        MapCycle_ChangeMap(Server.GetMapName(data.map_index))
        
    end
    SetVoteSuccessfulCallback("VoteChangeMap", kExecuteVoteDelay, OnChangeMapVoteSuccessful)
    
end