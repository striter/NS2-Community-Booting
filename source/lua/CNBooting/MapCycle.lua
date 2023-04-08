-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- core/MapCycle.lua
--
-- Created by Max McGuire (max@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ConfigFileUtility.lua")

local mapCycleFileName = "MapCycle.json"

local defaultConfig = 
{
    maps = 
    {
        "ns2_ayumi",
        "ns2_biodome",
        "ns2_caged",
        "ns2_eclipse",
        "ns2_derelict",
        "ns2_descent",
        "ns2_docking",
        "ns2_kodiak",
        "ns2_metro",
        "ns2_mineshaft",
        "ns2_origin",
        "ns2_refinery",
        "ns2_summit",
        "ns2_tanith",
        "ns2_tram",
        "ns2_unearthed",
        "ns2_veil"
    }, 
    time = 30, 
    mode = "order"
}

WriteDefaultConfigFile(mapCycleFileName, defaultConfig)

local cycle = LoadConfigFile(mapCycleFileName) or defaultConfig

if type(cycle.time) ~= "number" then
    Shared.Message("No cycle time defined in MapCycle.json")
end

local function CheckMapList(mapCycle)
    if type(mapCycle) ~= "table" then
        return false
    end

    if type(mapCycle.maps) ~= "table" or #mapCycle.maps == 0 then
        Shared.Message("No maps defined in MapCycle.json")
        return false
    else
        return true
    end
end

CheckMapList(cycle)

-- Try to load the map cycle from disk, but don't write a new config if loading it failed, instead just return the previously loaded mapcycle
function MapCycle_GetLatestValidConfig()
    local success, latestMapCycle = pcall(LoadConfigFile, mapCycleFileName)

    if success and CheckMapList(latestMapCycle) then
        return latestMapCycle
    else
        return cycle
    end
end

function MapCycle_GetMapCycle()
    return cycle
end

function MapCycle_SetMapCycle(newCycle)
    cycle = newCycle
    SaveConfigFile(mapCycleFileName, cycle)
end

local function GetMapName(map)

    if type(map) == "table" and map.map ~= nil then
        return map.map
    end
    return map
    
end

local function GetMapIndex(mapCycle, map)

    -- Go to the next map in the cycle. We need to search backwards
    -- in case the same map has been specified multiple times.
    for i = #mapCycle.maps, 1, -1 do
        if GetMapName(mapCycle.maps[i]) == map then
            return i
        end
    end

    return nil
end

function MapCycle_GetMapIndex(map)
    return GetMapIndex(cycle, map)
end

function MapCycle_GetMapIsInCycle(mapName)
    return MapCycle_GetMapIndex(mapName) ~= nil
end

local gameModePrefixes =
{
    "infest", "infext","ns2.0b","ns2.0","ns1.0","def"
}

local prefixToModId =
{
    ["infest"] = "2e813610",
    ["infect"] = "2e813610",
    ["ns2.0"] = "a474e602",
    ["ns1.0"] = "b0087f28",
}

-- Returns nil if the prefix doesn't match, or the real map name if it does match.
local function HasPrefix(mapName, prefix)
    
    prefix = prefix .. "_"
    
    local mapPrefix = string.sub(mapName, 1, string.len(prefix))
    if mapPrefix ~= prefix then
        return nil
    end
    
    local newMapName = "ns2_" .. string.sub( mapName, string.len(prefix) + 1)
    return newMapName
    
end

local function ApplyPrefixes(mapName, modsTable)
    
    for i=1, #gameModePrefixes do
        
        local prefix = gameModePrefixes[i]
        
        local result = HasPrefix(mapName, prefix)
        if result then
            
            local modId = prefixToModId[prefix]
            if modId then
                modsTable[#modsTable+1] = modId
            end
            return result -- repaired map name
            
        end
        
    end
    
    return mapName -- original map name passed in... nothing has taken effect
    
end

local function checkModId(modId)
    return (type(modId) == "string" and string.len(modId) >= 7) or type(modId) == "number"
end

local function GetServerMapIndex(map)
    for i = 1, Server.GetNumMaps() do
        if Server.GetMapName(i) == map then
            return i
        end
    end
end

local function StartMap(map, mapCycle)

    local mods = { }
    mapCycle = mapCycle or MapCycle_GetLatestValidConfig()
    
    -- Copy the global defined mods.
    if type(mapCycle.mods) == "table" then
        for m = 1, #mapCycle.mods do
            local modId = mapCycle.mods[m]
            if checkModId(modId) then
                table.insert(mods, modId)
            else
                Log("Invalid ModID or ModID data-type found, skipped mounting for index: %d", m)
            end
        end
    end

    local mapName = GetMapName(map)
    local mapIndex = type(map) == "string" and GetMapIndex(mapCycle, map)

    -- Fetch map entry that may contain mods to load for the map
    if type(map) == "string" then
        if mapIndex then
            map = mapCycle.maps[mapIndex]
        else
            mapIndex = GetServerMapIndex(map)

            if mapIndex and Server.GetMapModId(mapIndex) ~= "0" then
                table.insert(mods, Server.GetMapModId(mapIndex))
            end
        end
    end

    if type(map) == "table" and type(map.mods) == "table" then
        for mm = 1, #map.mods do
            local mapModId = map.mods[mm]
            if checkModId(mapModId) then
                table.insert(mods, mapModId)
            else
                Log("Invalid Map-ModID or Map-ModID data-type found, skipped mounting for index: %d", mm)
            end
        end
    end
    
    -- check for alternate gamemodes in the level file prefix (eg "infest" for infested marines)
    mapName = ApplyPrefixes(mapName, mods)
    
    -- If we fail to load the world, the event "mapchangefailed" will be triggered
    -- the default behaviour of that is to cycle away from the failed map
    -- This replaces the previous "make sure the map is present before we try to start it",
    -- which made it difficult to configure map cycles properly
    Log("Call StartWorld with map '%s', mods '%s'", mapName, mods)
    Server.StartWorld(mods, mapName)
    
    return true
    
end

--
-- Advances to the next map in the cycle
--
function MapCycle_CycleMap(currentMap, attempts)

    local mapCycle = MapCycle_GetLatestValidConfig()

    attempts = attempts or 1
    local numMaps = #mapCycle.maps
    
    if numMaps == 0 then
    
        Shared.Message("No maps in the map cycle")
        return
        
    end
    
    local map
    local success = false
    
    while not success do
          
        if mapCycle.mode == "random" then
        
            -- Choose a random map to switch to.
            local mapIndex = math.random(1, numMaps)
            map = mapCycle.maps[mapIndex]
            
            -- Don't change to the map we're currently playing.
            if GetMapName(map) == currentMap then
            
                mapIndex = mapIndex + 1
                if mapIndex > numMaps then
                    mapIndex = 1
                end
                map = mapCycle.maps[mapIndex]
                
            end
            
        else

            local mapIndex = GetMapIndex(mapCycle, currentMap) or 0

            mapIndex = mapIndex + 1

            if mapIndex > numMaps then
                mapIndex = 1
            end
            
            map = mapCycle.maps[mapIndex]

        end

        -- Fallback to a map not in a mod if all attempts covered the map cycle
        if attempts > 1 and attempts >= #mapCycle.maps then
            map = "ns2_summit"
            for i = 1, Server.GetNumMaps() do
                Log(Server.GetMapModId(mapIndex))
                local name = Server.GetMapName(i)
                if Server.GetMapModId(mapIndex) == "0" and name:find("ns2_") then
                    map = name
                    break
                end
            end

        end
        
        local mapName = GetMapName(map)
        
        if mapName ~= currentMap then
            success = StartMap(map, mapCycle)
        end
    
    end
    
end

--
-- Advances to the next map in the cycle, if appropriate.
--
function MapCycle_TestCycleMap()

    -- time is stored as minutes so convert to seconds.
    if cycle.time == 0 or Shared.GetTime() < (cycle.time * 60) then
        -- We haven't been on the current map for long enough.
        return false
    end
    
    return true
    
end

local function OnCommandCycleMap(client)

    if client == nil or client:GetIsLocalClient() then
        MapCycle_CycleMap(Shared.GetMapName())
    end
    
end

local function OnCommandChangeMap(client, mapName)
    
    if client == nil or client:GetIsLocalClient() then
        MapCycle_ChangeMap(mapName)
    end
    
end

function MapCycle_ChangeMap(mapName)

    local mapCycle = MapCycle_GetLatestValidConfig()

    -- Find the map in the list
    for i = 1,#mapCycle.maps do
        local map = mapCycle.maps[i]
        if GetMapName(map) == mapName then
            return StartMap(map, mapCycle)
        end
    end
    
    -- If the map isn't in the cycle, just start with the global mods
    return StartMap(mapName, mapCycle)
    
end

function OnMapChangeFailed(mapName, attemps)
    Log("Failed to load map '%s', cycling...", mapName);
    MapCycle_CycleMap(mapName, attemps)
end

Event.Hook("Console_changemap", OnCommandChangeMap)
Event.Hook("Console_cyclemap", OnCommandCycleMap)
Event.Hook("MapChangeFailed", OnMapChangeFailed)