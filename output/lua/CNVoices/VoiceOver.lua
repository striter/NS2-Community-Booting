debug.appendtoenum(kVoiceId, 'Disease')
debug.appendtoenum(kVoiceId, 'OttoJCHZ')
debug.appendtoenum(kVoiceId, 'OttoSpeak')
debug.appendtoenum(kVoiceId, 'OttoOXG')
debug.appendtoenum(kVoiceId, 'OttoKTHULU')
debug.appendtoenum(kVoiceId, 'OttoDDD')
debug.appendtoenum(kVoiceId, 'OttoJB')
debug.appendtoenum(kVoiceId, 'OttoStory')
debug.appendtoenum(kVoiceId, 'OttoONDS')
debug.appendtoenum(kVoiceId, 'XuanSpeak')
debug.appendtoenum(kVoiceId, 'XuanWoof')
debug.appendtoenum(kVoiceId, 'XuanOhoo')
debug.appendtoenum(kVoiceId, 'XuanRea')
debug.appendtoenum(kVoiceId, 'XuanAha')
debug.appendtoenum(kVoiceId, 'XuanStory')
debug.appendtoenum(kVoiceId, 'Liberity')
debug.appendtoenum(kVoiceId, 'CZHL')
debug.appendtoenum(kVoiceId, 'LockerRoom')
debug.appendtoenum(kVoiceId, 'Scream')
debug.appendtoenum(kVoiceId, 'ScreamLong')
debug.appendtoenum(kVoiceId, 'Jester')
debug.appendtoenum(kVoiceId, 'Wu')
debug.appendtoenum(kVoiceId, 'Ah')
debug.appendtoenum(kVoiceId, 'Slap')
debug.appendtoenum(kVoiceId, 'AnikiSpeak')
debug.appendtoenum(kVoiceId, 'Pyro')
debug.appendtoenum(kVoiceId, 'PyroLaugh')
debug.appendtoenum(kVoiceId, 'Aatrox')
debug.appendtoenum(kVoiceId, 'AatroxLaugh')
debug.appendtoenum(kVoiceId, 'Hajmi')
debug.appendtoenum(kVoiceId, 'wsdy')
debug.appendtoenum(kVoiceId, 'Kobe')
debug.appendtoenum(kVoiceId, 'Meow')
debug.appendtoenum(kVoiceId, 'Hiss')
debug.appendtoenum(kVoiceId, 'AUV')
debug.appendtoenum(kVoiceId, 'ddj')
debug.appendtoenum(kVoiceId, 'qsrx')
debug.appendtoenum(kVoiceId, 'tlj')
debug.appendtoenum(kVoiceId,'ottoDown')
debug.appendtoenum(kVoiceId,'laugh')

kAdditionalSoundData = {
    [kVoiceId.Disease] = { Sound = "sound/CNTaunts.fev/ma/Laugh", Description = "REQUEST_DISEASE", Interval = 2, AlertTechId = kTechId.None },
    [kVoiceId.OttoJCHZ] = { Sound = "sound/CNTaunts.fev/Otto/JCHZ", Description = "REQUEST_OTTO_FOOD", AlertTechId = kTechId.None },
    [kVoiceId.OttoOXG] = { Sound = "sound/CNTaunts.fev/Otto/OXG", Description = "REQUEST_OTTO_OXG", Interval = 0.7, AlertTechId = kTechId.None },
    [kVoiceId.OttoKTHULU] = { Sound = "sound/CNTaunts.fev/Otto/KTHULU", Description = "REQUEST_OTTO_KTHULU", Interval = 1, AlertTechId = kTechId.None },
    [kVoiceId.OttoSpeak] = { Sound = "sound/CNTaunts.fev/Otto/Speak", Description = "REQUEST_OTTO_SPEAK", AlertTechId = kTechId.None },
    [kVoiceId.OttoDDD] = { Sound = "sound/CNTaunts.fev/Otto/DDD", Description = "REQUEST_OTTO_DDD", Interval = 1, AlertTechId = kTechId.None },
    [kVoiceId.OttoJB] = { Sound = "sound/CNTaunts.fev/Otto/JB", Description = "REQUEST_OTTO_JB", Interval = 1, AlertTechId = kTechId.None },
    [kVoiceId.OttoStory] = { Sound = "sound/CNTaunts.fev/Otto/Story", Description = "REQUEST_OTTO_STORY", Interval = 63.3, AlertTechId = kTechId.None },
    [kVoiceId.OttoONDS] = { Sound = "sound/CNTaunts.fev/Otto/ONDS", Description = "REQUEST_OTTO_ONDS", Interval = 0.5, AlertTechId = kTechId.None },
    [kVoiceId.XuanSpeak] = { Sound = "sound/CNTaunts.fev/Xuan/Speak", Description = "REQUEST_XUAN_SPEAK", AlertTechId = kTechId.None },
    [kVoiceId.XuanWoof] = { Sound = "sound/CNTaunts.fev/Xuan/Woof", Description = "REQUEST_XUAN_WOOF", AlertTechId = kTechId.None },
    [kVoiceId.XuanOhoo] = { Sound = "sound/CNTaunts.fev/Xuan/Ohoo", Description = "REQUEST_XUAN_OHOO", Interval = 0.75, AlertTechId = kTechId.None },
    [kVoiceId.XuanRea] = { Sound = "sound/CNTaunts.fev/Xuan/Rea", Description = "REQUEST_XUAN_REA", Interval = 2.5, AlertTechId = kTechId.None },
    [kVoiceId.XuanAha] = { Sound = "sound/CNTaunts.fev/Xuan/Aha", Description = "REQUEST_XUAN_AHA", Interval = 1.5, AlertTechId = kTechId.None },
    [kVoiceId.XuanStory] = { Sound = "sound/CNTaunts.fev/Xuan/Story", Description = "REQUEST_XUAN_STORY", Interval = 73, AlertTechId = kTechId.None },
    [kVoiceId.Liberity] = { Sound = "sound/CNTaunts.fev/CUSTOM/Liberity", Description = "REQUEST_LIBERITY", Interval = 11, AlertTechId = kTechId.None },
    [kVoiceId.CZHL] = { Sound = "sound/CNTaunts.fev/CUSTOM/CZHL", Description = "REQUEST_CZHL", Interval = 14, AlertTechId = kTechId.None },
    [kVoiceId.Scream] = { Sound = "sound/CNTaunts.fev/CUSTOM/Scream", Description = "REQUEST_SCREAM", Interval = 0.5, AlertTechId = kTechId.None },
    [kVoiceId.ScreamLong] = { Sound = "sound/CNTaunts.fev/CUSTOM/ScreamLong", Description = "REQUEST_SCREAMLONG", Interval = 1, AlertTechId = kTechId.None },
    [kVoiceId.Jester] = { Sound = "sound/CNTaunts.fev/CUSTOM/Jester", Description = "REQUEST_JESTER", Interval = 2.5, AlertTechId = kTechId.None },
    [kVoiceId.LockerRoom] = { Sound = "sound/CNTaunts.fev/Aniki/Wrestle", Description = "REQUEST_LOCKERROOM", Interval = 50, AlertTechId = kTechId.None },
    [kVoiceId.Ah] = { Sound = "sound/CNTaunts.fev/Aniki/ah", Description = "REQUEST_AH", Interval = 0.75, AlertTechId = kTechId.None },
    [kVoiceId.Wu] = { Sound = "sound/CNTaunts.fev/Aniki/wu", Description = "REQUEST_WU", Interval = 0.75, AlertTechId = kTechId.None },
    [kVoiceId.Slap] = { Sound = "sound/CNTaunts.fev/Aniki/slap", Description = "尻击", Interval = 0.35, AlertTechId = kTechId.None },
    [kVoiceId.AnikiSpeak] = { Sound = "sound/CNTaunts.fev/Aniki/speak", Description = "本格", Interval = 2, AlertTechId = kTechId.None },
    [kVoiceId.Pyro] = { Sound = "sound/CNTaunts.fev/CUSTOM/Pyro", Description = "Pyro", Interval = 2, AlertTechId = kTechId.None },
    [kVoiceId.PyroLaugh] = { Sound = "sound/CNTaunts.fev/CUSTOM/PyroLaugh", Description = "Pyro [2]", Interval = 1.25, AlertTechId = kTechId.None },
    [kVoiceId.Aatrox] = { Sound = "sound/CNTaunts.fev/CUSTOM/Aatrox", Description = "亚托克斯", Interval = 2, AlertTechId = kTechId.None },
    [kVoiceId.AatroxLaugh] = { Sound = "sound/CNTaunts.fev/CUSTOM/AatroxLaugh", Description = "亚托克斯 [2]", Interval = 1.25, AlertTechId = kTechId.None },
    [kVoiceId.Hajmi] = { Sound = "sound/CNTaunts.fev/CUSTOM/Hajmi", Description = "哈吉米", Interval = 16, AlertTechId = kTechId.None },
    [kVoiceId.Kobe] = { Sound = "sound/CNTaunts.fev/CUSTOM/kobe", Description = "mann", Interval = 1, AlertTechId = kTechId.None },
    [kVoiceId.wsdy] = { Sound = "sound/CNTaunts.fev/CUSTOM/wsdy", Description = "我是毒液", Interval = 16, AlertTechId = kTechId.None },
    [kVoiceId.Meow] = { Sound = "sound/CNTaunts.fev/CUSTOM/meow", Description = "喵", Interval = 1, AlertTechId = kTechId.None },
    [kVoiceId.Hiss] = { Sound = "sound/CNTaunts.fev/CUSTOM/hiss", Description = "哈气", Interval = 1, AlertTechId = kTechId.None },
    [kVoiceId.AUV] = { Sound = "sound/CNTaunts.fev/CUSTOM/auv", Description = "地道", Interval = 2, AlertTechId = kTechId.None },
    [kVoiceId.tlj] = { Sound = "sound/CNTaunts.fev/CUSTOM/tlj", Description = "《跳楼机》", Interval = 40, AlertTechId = kTechId.None },
    [kVoiceId.qsrx] = { Sound = "sound/CNTaunts.fev/CUSTOM/qsrx", Description = "《牵私人戏》", Interval = 11, AlertTechId = kTechId.None },
    [kVoiceId.ddj] = { Sound = "sound/CNTaunts.fev/CUSTOM/ddj", Description = "叮咚鸡", Interval = 1, AlertTechId = kTechId.None },
    [kVoiceId.ottoDown] = { Sound = "sound/CNTaunts.fev/Otto/down", Description = "唐笑", Interval = 2, AlertTechId = kTechId.None },
    [kVoiceId.laugh] = { Sound = "sound/CNTaunts.fev/CUSTOM/laugh", Description = "笑", Interval = 2, AlertTechId = kTechId.None },
}

for _, data in pairs(kAdditionalSoundData) do
    PrecacheAsset(data.Sound)
end

function GetAdditionalVoiceSoundData(voiceId)
    return kAdditionalSoundData[voiceId]
end

local kSpectatorMenu = {
    [LEFT_MENU] = { kVoiceId.Disease, kVoiceId.ddj, kVoiceId.ottoDown, kVoiceId.ScreamLong, kVoiceId.laugh, kVoiceId.PyroLaugh },
    [RIGHT_MENU] = { kVoiceId.AUV, kVoiceId.LockerRoom, kVoiceId.XuanStory, kVoiceId.qsrx, kVoiceId.tlj, kVoiceId.Hajmi }
}

function GetRequestMenuTeam(side, className, teamType)
    if teamType == kNeutralTeamType then
        return kSpectatorMenu[side]
    end

    return GetRequestMenu(side, className)
end

if Client then
    local baseGetVoiceDescriptionText = GetVoiceDescriptionText
    function GetVoiceDescriptionText(voiceId)
        local soundData = kAdditionalSoundData[voiceId]
        if soundData then
            return Locale.ResolveString(soundData.Description)
        end

        return baseGetVoiceDescriptionText(voiceId)
    end
end