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
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/moqing"),            name = "雨爱 (DJ版)", artist = "阿黛" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/WutheringWaves"),    name = "玄翎谣", artist = "薄荷Miint" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/Beats"),             name = "My Soul, Your Beats!", artist = "Lia" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/Farewell"),          name = "远航星的告别", artist = "Tarokiki / Emi Evans" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/SoundHorizon"),      name = "恋人を射ち堕とした日", artist = "Sound Horizon" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/UED1"),              name = "未来への咆哮", artist = "JAM Project" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/UED2"),              name = "ライオン", artist = "May'n" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/WeAllLiftTogether"), name = "We All Lift Together", artist = "Keith Power" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/hjmidnightcity"),    name = "哈基Midnight City", artist = "M83" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/cjdl"),              name = "不眠之夜", artist = "张杰" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/LOTUS"),             name = "美丽的神话", artist = "孙楠" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/GetOverTheWorld"),   name = "Get Over The World", artist = "ヴェリタス" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/WonderFunnyHarmony"),name = "Wonder Funny Harmony", artist = "Blue Archive" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/Youngthink"),        name = "ヰ世界の宝石譚", artist = "ヰ世界情緒" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/SonOfTheGround"),    name = "大地之子-mix", artist = "沙林" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CUSTOM/ClearMorning"),      name = "Clear Morning", artist = "小仓唯" },
    },
    [EBoomBoxTrack.CN]  =  {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CN/ygkldnh"), name = "阳光开朗大男孩", artist = "卦者灵风" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CN/tzdxp"),    name = "天真的橡皮", artist = "王小帅" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CN/ndyjgzxd"), name = "难得有几个真兄弟", artist = "何流 / 宋晓峰" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CN/zxmzf"),    name = "最炫民族风", artist = "凤凰传奇" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/CN/Girl"),     name = "恋爱困难女孩", artist = "ChiliChill" },
    },
    [EBoomBoxTrack.OST]  = {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/SlumlordRelease"),name = "Slumlord's Re-lease", artist = "Neon Indian" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/FinalsBeta"),    name = "The Finals", artist = "Embark Studios", assetBattle = PrecacheAsset("sound/CNBoomBox.fev/OST/FinalsBetaBattle") },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/ToxicBeat"),      name = "Toxic Beat", artist = "Eddy Prodelles" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/TakeControl"),    name = "Take Control", artist = "Old Gods of Asgard" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/NeoCity"),        name = "Neo City", artist = "SHINOBI 復讐の斬撃", assetBattle = PrecacheAsset("sound/CNBoomBox.fev/OST/NeoCityBattle") },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/IndustrialHero"), name = "Industrial Hero", artist = "Jason Steele" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/Aegis"),          name = "Aegis", artist = "Michael Markie" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/ATrueCompetitor"),name = "A True Competitor", artist = "Embark Studios" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/2077"),           name = "The Rebel Path", artist = "P.T. Adamczyk" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/RisingTide"),     name = "Rising Tide", artist = "Jack Wall" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/Castlevania"),    name = "狂月の招き", artist = "Michiru Yamane" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/MMFight"),        name = "激闘", artist = "門倉聡" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/HLA"),            name = "Gravity Perforation Detail", artist = "Valve" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/GTAV"),           name = "No Happy Endings", artist = "Tangerine Dream" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/VortalCombat"),   name = "Vortal Combat", artist = "Kelly Bailey" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/EXO"),            name = "Exosuit", artist = "Unknown Worlds" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/PolarisPatrol"),  name = "Polaris Patrol", artist = "Jason Walsh" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/OST/BambooForest"),  name = "Bamboo Forest", artist = "SHINOBI 復讐の斬撃", assetBattle = PrecacheAsset("sound/CNBoomBox.fev/OST/BambooForestBattle") },
    },
    [EBoomBoxTrack.JP] = {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Ame"),            name = "Ame(A)", artist = "サカナクション" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/LightBlueRain"),  name = "みずいろの雨", artist = "八神純子" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/MoonAfterglow"),  name = "三日月サンセット(新月余晖)", artist = "サカナクション" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/LightDance"),     name = "ライトダンス", artist = "サカナクション" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/BluSwing"),       name = "満ちていく体温", artist = "BLU-SWING" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Time26"),         name = "表参道26時", artist = "サカナクション" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/P5"),             name = "星と僕らと", artist = "Lyn" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/WanderingAround"),name = "アルクアラウンド", artist = "サカナクション" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Flamingo"),       name = "Flamingo", artist = "米津玄師" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/StepIt"),         name = "Step It", artist = "Nulbarich" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Hear"),           name = "聴きたかったダンスミュージック、リキッドルームに", artist = "サカナクション" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/DaMeDaNe"),       name = "Baka Mitai", artist = "桐生一馬" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/BloodyStream"),   name = "Bloody Stream", artist = "Coda" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/DevilmanOld"),    name = "Devilman", artist = "牛尾憲輔" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/RageOfDust"),     name = "Rage Of Dust", artist = "SPYAIR" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/LoveLoop"),       name = "恋爱循环", artist = "花澤香菜" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Monster"),        name = "怪物", artist = "YOASOBI" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/FreesiaLive"),    name = "フリージア", artist = "GReeeeN" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/DevilmanNoUta"), name = "Devilman No Uta", artist = "Queen Bee" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/JP/Sunset"),        name = "Sunset", artist = "BLU-SWING" },
    },
    [EBoomBoxTrack.EN] = {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Slumlord"),              name = "Slumlord", artist = "Neon Indian" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Gaslight"),              name = "Gaslight", artist = "Travis" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/SoulIsAStar"),           name = "Soul Is A Star", artist = "Jagwar Twin" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Belong"),                name = "Belong", artist = "Roosevelt" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/TheOtherSideOfParadise"),name = "The Other Side Of Paradise", artist = "Glass Animals" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/EasyLover"),             name = "Easy Lover", artist = "Phil Collins" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Attention"),             name = "Attention", artist = "Charlie Puth" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/LowRider"),              name = "Low Rider", artist = "War" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Preach"),                name = "Preach", artist = "Saint Motel" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Sabotage"),              name = "Sabotage", artist = "JAWNY" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/UnaMattina"),            name = "Una Mattina", artist = "Papa Tin" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/StopDrop"),              name = "Stop Drop Smile and Roll", artist = "Spearfisher" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/SmoothCriminal"),        name = "Smooth Criminal", artist = "Michael Jackson" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/BrandNew"),              name = "Brand New", artist = "Battle Tapes" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/MakesMeWonder"),         name = "Makes Me Wonder", artist = "Maroon 5" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/LikeAHabit"),            name = "Like A Habit", artist = "Berhana" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Sleepwalker"),           name = "Sleepwalker", artist = "Battle Tapes" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Starchild"),             name = "Starchild", artist = "Jamiroquai" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/IRemember"),             name = "I Remember", artist = "Frankmusik" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/BlackBetty"),            name = "Black Betty", artist = "Spiderbait" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Origami"),               name = "Origami", artist = "Capital Cities" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/SevenDaysInSundayJune"),  name = "Seven Days In Sunday June", artist = "Jamiroquai" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/LastCall"),               name = "Last Call", artist = "Blowsom" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Metamodernity"),          name = "Metamodernity", artist = "Vansire" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/NoGood"),                 name = "No Good", artist = "Battle Tapes" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/WhenYouGonnaLearn"),      name = "When You Gonna Learn?", artist = "Jamiroquai" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/HowYouLikeMeNow"),        name = "How you like me now", artist = "The Heavy" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/WestCoast"),              name = "West Coast", artist = "OneRepublic" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/GreenRiver"),             name = "Green River", artist = "Creedence Clearwater Revival" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/AfterTheDisco"),          name = "After the Disco", artist = "Broken Bells" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/PolishGirl"),             name = "Polish Girl", artist = "Neon Indian" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Valkyrie"),               name = "Valkyrie", artist = "Battle Tapes" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/OutOfTime"),              name = "Out of Time", artist = "The Weeknd" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/JubanDistinct"),          name = "Juban District", artist = "Ginger Root" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/EN/Thriller"),               name = "Thriller", artist = "Michael Jackson" },
    },
    [EBoomBoxTrack.Calm] = {
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/MoonLightSlow"),     name = "三日月サンセット -Rearrange 2020-", artist = "サカナクション" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/Redbone"),           name = "Redbone", artist = "Kid Travis" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/NewSlow"),           name = "New Slow", artist = "Phlake" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/Fabulous"),          name = "FABULOUS -Glow our vibes-", artist = "BLU-SWING" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/BusinessSolutions"), name = "Business Solutions", artist = "JORDANN" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/madhouse"),          name = "madhouse", artist = "Matt Maltese" },
        { asset = PrecacheAsset("sound/CNBoomBox.fev/Calm/TickTock"),          name = "Tick Tock", artist = "Tom Misch" },
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
