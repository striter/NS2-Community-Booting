
-- BoomBoxLocalPlayer.lua
-- Client-side local music playback for BoomBox
-- Pure playback logic, no GUI dependency

if not Client then return end

-- Runtime state (not persisted)
g_BoomBoxLocalPlaying = false
g_BoomBoxLocalPlayingCategory = nil
g_BoomBoxLocalPlayingIndex = nil
g_BoomBoxLocalVolume = 0.5

local _lastLocalPlayer = nil

local localSoundEffect = nil

local function GetLocalVolume()
    return Client.GetOptionFloat("BB_Local_Volume", 0.5)
end

local function DoPlaySound(asset)
    local player = Client.GetLocalPlayer()
    _lastLocalPlayer = player
    if player then
        Shared.PlaySound(player, asset, GetLocalVolume())
    end
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

local function StopLocalMusic()
    if localSoundEffect then
        if localSoundEffect.Stop then
            localSoundEffect:Stop()
        end
        localSoundEffect = nil
    end
    g_BoomBoxLocalPlaying = false
end

local volumeUpdateAt = 0

local function ReplayLocalMusic()
    if g_BoomBoxLocalPlaying and localSoundEffect then
        local path = localSoundEffect._path
        local player = Client.GetLocalPlayer()
        if player then
            Shared.StopSound(player, path)
            Shared.PlaySound(player, path, GetLocalVolume())
            _lastLocalPlayer = player
        end
    end
end

function BoomBoxLocalApplyVolume()
    if g_BoomBoxLocalPlaying and localSoundEffect then
        volumeUpdateAt = Shared.GetTime() + 0.4
    end
end

function BoomBoxLocalPlay(category, trackIndex)
    StopLocalMusic()

    local tracks = (BoomBoxMixin and BoomBoxMixin.kTracks or GetBoomBoxTracks())[category]
    if not tracks or not tracks[trackIndex] then
        Shared.Message("[BoomBox] track not found: cat=" .. tostring(category) .. " idx=" .. tostring(trackIndex))
        return
    end

    local asset = tracks[trackIndex].asset
    DoPlaySound(asset)
    localSoundEffect = { _path = asset, Stop = function(self)
        local p = Client.GetLocalPlayer()
        if p then Shared.StopSound(p, self._path) end
    end }
    g_BoomBoxLocalPlaying = true
    g_BoomBoxLocalPlayingCategory = category
    g_BoomBoxLocalPlayingIndex = trackIndex
    g_BoomBoxLocalCategory = category
    SaveSelection()
end

function BoomBoxLocalStop()
    StopLocalMusic()
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

function BoomBoxLocalUpdate()
    if volumeUpdateAt > 0 and Shared.GetTime() >= volumeUpdateAt then
        volumeUpdateAt = 0
        ReplayLocalMusic()
    end
    if g_BoomBoxLocalPlaying and localSoundEffect then
        local cur = Client.GetLocalPlayer()
        if cur ~= _lastLocalPlayer then
            local path = localSoundEffect._path
            if _lastLocalPlayer then
                Shared.StopSound(_lastLocalPlayer, path)
            end
            _lastLocalPlayer = cur
            if cur then
                Shared.PlaySound(cur, path, GetLocalVolume())
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

Event.Hook("UpdateClient", function()
    BoomBoxLocalUpdate()
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
