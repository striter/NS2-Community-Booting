EBoomBoxTrack = enum{ 'OST', 'SONG', 'TWO', 'CUSTOM'}
gBoomBoxDefine = {
    [EBoomBoxTrack.OST] = {titleKey = "BOOMBOX_OST",key = "OST",configPath = "BB_OST_Volume"},
    [EBoomBoxTrack.SONG] = {titleKey = "BOOMBOX_SONG",key = "SONG",configPath = "BB_SONG_Volume"},
    [EBoomBoxTrack.TWO] = {titleKey = "BOOMBOX_TWO",key = "TWO",configPath = "BB_TWO_Volume"},
    [EBoomBoxTrack.CUSTOM] = {titleKey = "BOOMBOX_CUSTOM",key = "CUSTOM",configPath = "BB_CUSTOM_Volume"},
}
kBoomBoxDefaultValue = 0.8

ModLoader.SetupFileHook( "lua/Exo.lua", "lua/CNExoBoombox/Exo.lua", "post" )
ModLoader.SetupFileHook( "lua/GUIExoEject.lua", "lua/CNExoBoombox/GUIExoEject.lua", "post" )
ModLoader.SetupFileHook( "lua/Exosuit.lua", "lua/CNExoBoombox/Exosuit.lua", "post" )
ModLoader.SetupFileHook( "lua/Onos.lua", "lua/CNExoBoombox/Onos.lua", "post" )
ModLoader.SetupFileHook("lua/SoundEffect.lua", "lua/CNExoBoombox/SoundEffect.lua", "post")
ModLoader.SetupFileHook("lua/menu2/NavBar/Screens/Options/Mods/ModsMenuData.lua", "lua/CNEXoBoomBox/ModsMenuData.lua", "post")

if AddHintModPanel then
    local panelMaterial = PrecacheAsset("materials/CNExosuitBoombox/Banner.material")
    AddHintModPanel(panelMaterial,"https://docs.qq.com/doc/DUGJIQkRuQVB0REpO", "人生就是一场旅行")
end

if Client then
    if kTranslateMessage then
        kTranslateMessage["BOOMBOX_TITLE"]="车载音响"
        kTranslateMessage["BOOMBOX_CUSTOM"]="定制"
        kTranslateMessage["BOOMBOX_OST"]="原声"
        kTranslateMessage["BOOMBOX_SONG"]="英语"
        kTranslateMessage["BOOMBOX_TWO"]="日语"
        kTranslateMessage["BOOMBOX_VOLUME"]="音量校正[%s]"
        kTranslateMessage["BOOMBOX_STOP"]="停止"
        kTranslateMessage["BOOMBOX_RANDOM"]="随机"
    end

    if kLocales then
        kLocales["BOOMBOX_TITLE"]="BoomBox"
        kLocales["BOOMBOX_OST"]="OST"
        kLocales["BOOMBOX_SONG"]="Song"
        kLocales["BOOMBOX_TWO"]="Anim"
        kLocales["BOOMBOX_CUSTOM"]="Cstm"
        kLocales["BOOMBOX_VOLUME"]="Volume[%s]"
        kLocales["BOOMBOX_STOP"]="Stop"
        kLocales["BOOMBOX_RANDOM"]="Random"
    end
end