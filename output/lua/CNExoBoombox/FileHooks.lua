EBoomBoxTrack = enum{'CUSTOM', 'OST', 'EN', 'JP','CN','Calm'}
gBoomBoxDefine = {
    [EBoomBoxTrack.CUSTOM] = {titleKey = "BOOMBOX_CUSTOM",key = "CUSTOM",configPath = "BB_CUSTOM_Volume"},
    [EBoomBoxTrack.OST] = {titleKey = "BOOMBOX_OST",key = "OST",configPath = "BB_OST_Volume"},
    [EBoomBoxTrack.EN] = {titleKey = "BOOMBOX_SONG",key = "SONG",configPath = "BB_SONG_Volume"},
    [EBoomBoxTrack.JP] = {titleKey = "BOOMBOX_TWO",key = "TWO",configPath = "BB_TWO_Volume"},
    [EBoomBoxTrack.CN] = {titleKey = "BOOMBOX_CN",key = "CN",configPath = "BB_CN_VOLUME"},
    [EBoomBoxTrack.Calm] = {titleKey = "BOOMBOX_CALM",key = "CALM",configPath = "BB_CALM_VOLUME"},
}
kBoomBoxDefaultValue = 0.8

gBoomBoxTracks = {
    [EBoomBoxTrack.CUSTOM]  =  {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/WutheringWaves"),             name = "玄翎谣" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/Beats"),             name = "My Soul, Your Beats!" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/Farewell"),          name = "远航星的告别" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/SoundHorizon"),      name = "恋人を射ち堕とした日" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/UED1"),              name = "未来への咆哮" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/UED2"),              name = "ライオン" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/WeAllLiftTogether"), name = "We All Lift Together" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/hjmidnightcity"),    name = "哈基Midnight City" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/cjdl"),              name = "不眠之夜" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/LOTUS"),             name = "美丽的神话" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/GetOverTheWorld"),   name = "Get Over The World" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/WonderFunnyHarmony"),name = "Wonder Funny Harmony" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/Youngthink"),        name = "ヰ世界の宝石譚" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/SonOfTheGround"),    name = "大地之子-沙林mix" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/ClearMorning"),      name = "Clear Morning" },
    },
    [EBoomBoxTrack.CN]  =  {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CN/ygkldnh"), name = "阳光开朗大男孩" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CN/tzdxp"),   name = "天真的橡皮" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CN/ndyjgzxd"),name = "难得有几个真兄弟" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CN/zxmzf"),   name = "最炫民族风" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CN/Girl"),     name = "恋爱困难女孩" },
    },
    [EBoomBoxTrack.OST]  = {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/TheFinals"),      name = "The Finals (Season 1)" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/ToxicBeat"),      name = "Toxic Beat" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/TakeControl"),    name = "Take Control" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/NeoCity"),        name = "Neo City", assetBattle = PrecacheAsset("sound/CNBoomBox.fev/OST/NeoCityBattle") },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/IndustrialHero"), name = "Industrial Hero" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/Aegis"),          name = "Aegis" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/ATrueCompetitor"),name = "A True Competitor" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/2077"),           name = "The Rebel Path" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/RisingTide"),     name = "Rising Tide" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/Castlevania"),    name = "狂月の招き" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/MMFight"),        name = "激闘" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/HLA"),            name = "Gravity Perforation Detail" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/GTAV"),           name = "No Happy Endings" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/VortalCombat"),   name = "Vortal Combat" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/EXO"),            name = "Exosuit" },
    },
    [EBoomBoxTrack.JP] = {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Ame"),            name = "Ame(A)" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/LightBlueRain"),  name = "みずいろの雨" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/MoonAfterglow"),  name = "三日月サンセット" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/LightDance"),     name = "ライトダンス" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/BluSwing"),       name = "満ちていく体温" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Time26"),         name = "表参道26時" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/P5"),             name = "星と僕らと" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/WanderingAround"),name = "アルクアラウンド" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Flamingo"),       name = "Flamingo" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/StepIt"),         name = "Step It" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Hear"),           name = "聴きたかったダンスミュージック、リキッドルームに" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/DaMeDaNe"),       name = "Baka Mitai" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/BloodyStream"),   name = "Bloody Stream" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/DevilmanOld"),    name = "Devilman" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/RageOfDust"),     name = "Rage Of Dust" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/LoveLoop"),       name = "恋爱循环" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Monster"),        name = "怪物" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/FreesiaLive"),    name = "フリージア" },
    },
    [EBoomBoxTrack.EN] = {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Slumlord"),              name = "Slumlord" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Attention"),             name = "Attention" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/LowRider"),              name = "Low Rider" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Preach"),                name = "Preach" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Sabotage"),              name = "Sabotage" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/UnaMattina"),            name = "Una Mattina" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/StopDrop"),              name = "Stop Drop Smile and Roll" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/SmoothCriminal"),        name = "Smooth Criminal" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/BrandNew"),              name = "Brand New" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/MakesMeWonder"),         name = "Makes Me Wonder" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/LikeAHabit"),            name = "Like A Habit" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Sleepwalker"),           name = "Sleepwalker" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Starchild"),             name = "Starchild" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/IRemember"),             name = "I Remember" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/BlackBetty"),            name = "Black Betty" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Origami"),               name = "Origami" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/SevenDaysInSundayJune"),  name = "Seven Days In Sunday June" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/LastCall"),               name = "Last Call" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Metamodernity"),          name = "Metamodernity" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/NoGood"),                 name = "No Good" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/WhenYouGonnaLearn"),      name = "When You Gonna Learn?" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/HowYouLikeMeNow"),        name = "How you like me now" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/WestCoast"),              name = "West Coast" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/GreenRiver"),             name = "Green River" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/AfterTheDisco"),          name = "After the Disco" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/PolishGirl"),             name = "Polish Girl" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Valkyrie"),               name = "Valkyrie" },
    },
    [EBoomBoxTrack.Calm] = {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/MoonLightSlow"),     name = "三日月サンセット -Rearrange 2020-" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/Redbone"),           name = "Redbone" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/OutofTime"),         name = "Out of Time" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/JubanDistrict"),     name = "Juban District" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/NewSlow"),           name = "New Slow" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/Fabulous"),          name = "FABULOUS -Glow our vibes-" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/BusinessSolutions"), name = "Business Solutions" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/madhouse"),          name = "madhouse" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/TickTock"),          name = "Tick Tock" },
    },
}

function GetBoomBoxTracks()
    return gBoomBoxTracks
end

ModLoader.SetupFileHook( "lua/Exo.lua", "lua/CNExoBoombox/Exo.lua", "post" )
ModLoader.SetupFileHook( "lua/ReadyRoomExo.lua", "lua/CNExoBoombox/ReadyRoomExo.lua", "post" )
ModLoader.SetupFileHook( "lua/GUIExoEject.lua", "lua/CNExoBoombox/GUIExoEject.lua", "post" )
ModLoader.SetupFileHook( "lua/Exosuit.lua", "lua/CNExoBoombox/Exosuit.lua", "post" )
ModLoader.SetupFileHook( "lua/Onos.lua", "lua/CNExoBoombox/Onos.lua", "post" )
ModLoader.SetupFileHook("lua/SoundEffect.lua", "lua/CNExoBoombox/SoundEffect.lua", "post")
ModLoader.SetupFileHook("lua/menu2/NavBar/Screens/Options/Mods/ModsMenuData.lua", "lua/CNEXoBoomBox/ModsMenuData.lua", "post")

if Client then
    Script.Load("lua/CNExoBoombox/Locale.lua")
    ModLoader.SetupFileHook("lua/Shared.lua", "lua/CNExoBoombox/BoomBoxLocalPlayer.lua", "post")
end

if AddHintModPanel then
    local panelMaterial = PrecacheAsset("materials/CNExosuitBoombox/Banner.material")
    AddHintModPanel(panelMaterial,"https://docs.qq.com/doc/DUGJIQkRuQVB0REpO", "人生就是一场旅行")
end