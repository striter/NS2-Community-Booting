EBoomBoxTrack = enum{'CUSTOM', 'OST', 'EN', 'JP','CN'}
gBoomBoxDefine = {
    [EBoomBoxTrack.CUSTOM] = {titleKey = "BOOMBOX_CUSTOM",key = "CUSTOM",configPath = "BB_CUSTOM_Volume"},
    [EBoomBoxTrack.OST] = {titleKey = "BOOMBOX_OST",key = "OST",configPath = "BB_OST_Volume"},
    [EBoomBoxTrack.EN] = {titleKey = "BOOMBOX_SONG",key = "SONG",configPath = "BB_SONG_Volume"},
    [EBoomBoxTrack.JP] = {titleKey = "BOOMBOX_TWO",key = "TWO",configPath = "BB_TWO_Volume"},
    [EBoomBoxTrack.CN] = {titleKey = "BOOMBOX_CN",key = "CN",configPath = "BB_CN_VOLUME"},
}
kBoomBoxDefaultValue = 0.8

ModLoader.SetupFileHook( "lua/Exo.lua", "lua/CNExoBoombox/Exo.lua", "post" )
ModLoader.SetupFileHook( "lua/GUIExoEject.lua", "lua/CNExoBoombox/GUIExoEject.lua", "post" )
ModLoader.SetupFileHook( "lua/Exosuit.lua", "lua/CNExoBoombox/Exosuit.lua", "post" )
ModLoader.SetupFileHook( "lua/Onos.lua", "lua/CNExoBoombox/Onos.lua", "post" )
ModLoader.SetupFileHook("lua/SoundEffect.lua", "lua/CNExoBoombox/SoundEffect.lua", "post")
ModLoader.SetupFileHook("lua/menu2/NavBar/Screens/Options/Mods/ModsMenuData.lua", "lua/CNEXoBoomBox/ModsMenuData.lua", "post")

if Client then
   Script.Load("lua/CNExoBoombox/Locale.lua")
end

if AddHintModPanel then
    local panelMaterial = PrecacheAsset("materials/CNExosuitBoombox/Banner.material")
    AddHintModPanel(panelMaterial,"https://docs.qq.com/doc/DUGJIQkRuQVB0REpO", "人生就是一场旅行")
end