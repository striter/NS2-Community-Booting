
-- BoomBoxLocalPlayer.lua
-- Client-side local music playback for BoomBox
-- Pure playback logic, no GUI dependency

if not Client then return end

-- Runtime state (not persisted)
g_BoomBoxLocalPlaying = false
g_BoomBoxLocalPlayingCategory = nil
g_BoomBoxLocalPlayingIndex = nil
g_BoomBoxLocalVolume = 0.5
g_BoomBoxLocalBattle = false

local _lastLocalPlayer = nil

local localSoundMain = nil
local localSoundBattle = nil

local function GetLocalVolume()
    return Client.GetOptionFloat("BB_Local_Volume", 0.5)
end

-- Both variants run in parallel and cross-fade; only one is fully audible at rest
local kBattleFadeTime = 0.4
local battleMix = 0

local function GetTargetMix()
    return (g_BoomBoxLocalBattle and localSoundBattle ~= nil) and 1 or 0
end

local function ApplyLocalVolumes()
    local volume = GetLocalVolume()
    if localSoundMain then
        localSoundMain:SetVolume(volume * (1 - battleMix))
    end
    if localSoundBattle then
        localSoundBattle:SetVolume(volume * battleMix)
    end
end

local function StartSoundInstance(player, asset, volume)
    if not asset then
        return nil
    end
    local index = Shared.GetSoundIndex(asset)
    if index == 0 then
        Shared.Message("[BoomBox] sound not precached: " .. tostring(asset))
        return nil
    end
    local instance = Client.CreateSoundEffect(index)
    instance:SetParent(player:GetId())
    instance:Start()
    instance:SetVolume(volume)
    return instance
end

local function SaveSelection()
    if not (gBoomBoxDefine and Client.SetOptionString) then return end
    local def = gBoomBoxDefine[g_BoomBoxLocalPlayingCategory or g_BoomBoxLocalCategory]
    if def then
        Client.SetOptionString("BB_Last_Category", def.key)
    end
    if Client.SetOptionFloat then
        Client.SetOptionFloat("BB_Last_Index", g_BoomBoxLocalPlayingIndex or 1)
    end
end

local function StopInstance(instance)
    if not instance then
        return
    end
    instance:Stop()
    Client.DestroySoundEffect(instance)
end

local function StopLocalMusic()
    StopInstance(localSoundMain)
    StopInstance(localSoundBattle)
    localSoundMain = nil
    localSoundBattle = nil
    g_BoomBoxLocalPlaying = false
end

function BoomBoxLocalApplyVolume()
    ApplyLocalVolumes()
end

function BoomBoxLocalPlay(category, trackIndex)
    StopLocalMusic()

    local tracks = (BoomBoxMixin and BoomBoxMixin.kTracks or GetBoomBoxTracks())[category]
    if not tracks or not tracks[trackIndex] then
        Shared.Message("[BoomBox] track not found: cat=" .. tostring(category) .. " idx=" .. tostring(trackIndex))
        return
    end

    local track = tracks[trackIndex]
    local player = Client.GetLocalPlayer()
    if not player then
        return
    end
    _lastLocalPlayer = player
    localSoundMain = StartSoundInstance(player, track.asset, 0)
    if track.assetBattle then
        localSoundBattle = StartSoundInstance(player, track.assetBattle, 0)
    end
    battleMix = GetTargetMix()
    ApplyLocalVolumes()
    g_BoomBoxLocalPlaying = localSoundMain ~= nil
    g_BoomBoxLocalPlayingCategory = category
    g_BoomBoxLocalPlayingIndex = trackIndex
    g_BoomBoxLocalCategory = category
    SaveSelection()
end

function BoomBoxLocalStop()
    StopLocalMusic()
end

-- Only flips the target; the update loop ramps the mix without restarting playback
function BoomBoxLocalToggleBattle()
    g_BoomBoxLocalBattle = not g_BoomBoxLocalBattle
    if not localSoundMain then
        battleMix = GetTargetMix()
    end
end

-- Selected category for the menu UI (persisted in runtime)
g_BoomBoxLocalCategory = EBoomBoxTrack.OST

function BoomBoxLocalPlayCurrent()
    local cat = g_BoomBoxLocalCategory
    local tracks = (BoomBoxMixin and BoomBoxMixin.kTracks or GetBoomBoxTracks())[cat]
    if not tracks then return end
    local idx = 1
    if g_BoomBoxLocalPlayingCategory == cat and g_BoomBoxLocalPlayingIndex then
        idx = math.min(g_BoomBoxLocalPlayingIndex, #tracks)
    end
    BoomBoxLocalPlay(cat, idx)
end

function BoomBoxLocalRandom()
    local allTracks = BoomBoxMixin and BoomBoxMixin.kTracks or GetBoomBoxTracks()
    -- collect all (category, index) pairs
    local pool = {}
    for cat, tracks in pairs(allTracks) do
        for i = 1, #tracks do
            pool[#pool + 1] = { cat = cat, idx = i }
        end
    end
    if #pool == 0 then return end
    local pick = pool[math.random(#pool)]
    g_BoomBoxLocalCategory = pick.cat
    BoomBoxLocalPlay(pick.cat, pick.idx)
end

function BoomBoxLocalNext()
    local tracks = (BoomBoxMixin and BoomBoxMixin.kTracks or GetBoomBoxTracks())[g_BoomBoxLocalCategory]
    if not tracks then return end
    local idx = 1
    if g_BoomBoxLocalPlayingCategory == g_BoomBoxLocalCategory and g_BoomBoxLocalPlayingIndex then
        idx = g_BoomBoxLocalPlayingIndex + 1
        if idx > #tracks then idx = 1 end
    end
    BoomBoxLocalPlay(g_BoomBoxLocalCategory, idx)
end

function BoomBoxLocalPrev()
    local tracks = (BoomBoxMixin and BoomBoxMixin.kTracks or GetBoomBoxTracks())[g_BoomBoxLocalCategory]
    if not tracks then return end
    local idx = #tracks
    if g_BoomBoxLocalPlayingCategory == g_BoomBoxLocalCategory and g_BoomBoxLocalPlayingIndex then
        idx = g_BoomBoxLocalPlayingIndex - 1
        if idx < 1 then idx = #tracks end
    end
    BoomBoxLocalPlay(g_BoomBoxLocalCategory, idx)
end

function BoomBoxLocalGetNowPlayingName()
    if not g_BoomBoxLocalPlaying then return nil end
    local tracks = (BoomBoxMixin and BoomBoxMixin.kTracks or GetBoomBoxTracks())[g_BoomBoxLocalPlayingCategory]
    if tracks and tracks[g_BoomBoxLocalPlayingIndex] then
        return tracks[g_BoomBoxLocalPlayingIndex].name
    end
    return nil
end

local function RestoreSelection()
    if not (gBoomBoxDefine and Client.GetOptionString) then return end
    local key = Client.GetOptionString("BB_Last_Category", "OST")
    for cat, def in pairs(gBoomBoxDefine) do
        if def.key == key then
            g_BoomBoxLocalCategory = cat
            break
        end
    end
    local idx = Client.GetOptionFloat and Client.GetOptionFloat("BB_Last_Index", 1) or 1
    idx = math.floor(idx + 0.5)
    local tracks = GetBoomBoxTracks()[g_BoomBoxLocalCategory]
    if tracks then
        idx = math.max(1, math.min(idx, #tracks))
    end
    g_BoomBoxLocalPlayingIndex = idx
    g_BoomBoxLocalPlayingCategory = g_BoomBoxLocalCategory
end

RestoreSelection()

function BoomBoxLocalUpdate(deltaTime)
    local target = GetTargetMix()
    if battleMix ~= target then
        if not localSoundMain then
            battleMix = target
        else
            local step = (deltaTime or 0) / kBattleFadeTime
            if step <= 0 then
                battleMix = target
            elseif battleMix < target then
                battleMix = math.min(target, battleMix + step)
            else
                battleMix = math.max(target, battleMix - step)
            end
            ApplyLocalVolumes()
        end
    end
    if g_BoomBoxLocalPlaying and (localSoundMain or localSoundBattle) then
        local cur = Client.GetLocalPlayer()
        if cur ~= _lastLocalPlayer then
            _lastLocalPlayer = cur
            if cur and g_BoomBoxLocalPlayingCategory and g_BoomBoxLocalPlayingIndex then
                BoomBoxLocalPlay(g_BoomBoxLocalPlayingCategory, g_BoomBoxLocalPlayingIndex)
            else
                StopLocalMusic()
            end
        end
    else
        _lastLocalPlayer = Client.GetLocalPlayer()
    end
end

-- Console command
Event.Hook("Console_boombox", function()
    BoomBoxLocalToggle()
end)

Event.Hook("UpdateClient", function(deltaTime)
    BoomBoxLocalUpdate(deltaTime)
end)

-- Override the stub from FileHooks
function BoomBoxLocalToggle()
    -- This is now a no-op toggle placeholder;
    -- actual UI is in ModsMenuData - just play/stop via console
    if g_BoomBoxLocalPlaying then
        BoomBoxLocalStop()
    else
        BoomBoxLocalPlayCurrent()
    end
end
