ModLoader.SetupFileHook("lua/VoiceOver.lua", "lua/CNVoices/VoiceOver.lua", "post")
ModLoader.SetupFileHook("lua/GUIRequestMenu.lua", "lua/CNVoices/GUIRequestMenu.lua", "replace")
ModLoader.SetupFileHook("lua/SoundEffect.lua", "lua/CNVoices/SoundEffect.lua", "post")
ModLoader.SetupFileHook("lua/Voting.lua", "lua/CNVoices/Voting.lua", "post")
ModLoader.SetupFileHook("lua/Shared.lua", "lua/CNVoices/Shared.lua", "post")
ModLoader.SetupFileHook("lua/Globals.lua", "lua/CNVoices/Globals.lua", "post")
ModLoader.SetupFileHook("lua/NetworkMessages_Server.lua", "lua/CNVoices/NetworkMessages_Server.lua", "post")
ModLoader.SetupFileHook("lua/menu2/NavBar/Screens/Options/Mods/ModsMenuData.lua", "lua/CNVoices/ModsMenuData.lua", "post")

if Client then

    kCNVoiceOverConfig = {
        VolumePath = "CNVO_Volume",
        VolumeDefault = 0.8,
    }

    if Locale.kTranslateMessage then
        Locale.kTranslateMessage["CNVO_TITLE"] = "语音拓展"
        Locale.kTranslateMessage["CNVO_VOLUME"] = "音量"
        Locale.kTranslateMessage["CNVO_WEB"] = "使用说明"
    end

    if Locale.kLocales then
        Locale.kLocales["CNVO_TITLE"] = "CN Voice Over"
        Locale.kLocales["CNVO_VOLUME"] = "Volume"
        Locale.kLocales["CNVO_WEB"] = "Manual"
        
        Locale.kLocales["REQUEST_DISEASE"] = "恶疾"
        Locale.kLocales["REQUEST_OTTO_OXG"] = "欧西给"
        Locale.kLocales["REQUEST_OTTO_KTHULU"] = "古神语"
        Locale.kLocales["REQUEST_OTTO_DDD"] = "唢呐演奏"
        Locale.kLocales["REQUEST_OTTO_JB"] = "基掰"
        Locale.kLocales["REQUEST_OTTO_STORY"] = "《营养》"
        Locale.kLocales["REQUEST_OTTO_FOOD"] = "韭菜盒子"
        Locale.kLocales["REQUEST_OTTO_SPEAK"] = "负能量"
        Locale.kLocales["REQUEST_OTTO_ONDS"] = "欧内的手"
        Locale.kLocales["REQUEST_XUAN_SPEAK"] = "小吠"
        Locale.kLocales["REQUEST_XUAN_WOOF"] = "狂吠"
        Locale.kLocales["REQUEST_XUAN_OHOO"] = "芜湖"
        Locale.kLocales["REQUEST_XUAN_REA"] = "惹啊啊"
        Locale.kLocales["REQUEST_XUAN_AHA"] = "啊哈"
        Locale.kLocales["REQUEST_XUAN_STORY"] = "《第一个王者》"
        Locale.kLocales["REQUEST_DUIDUIDUI"] = "《生活的态度》"
        Locale.kLocales["REQUEST_LIBERITY"] = "《独立宣言》"
        Locale.kLocales["REQUEST_SUMMER"] = "《盛夏》"
        Locale.kLocales["REQUEST_CZHL"] = "《沈阳大街》"
        Locale.kLocales["REQUEST_LOCKERROOM"] = "《更衣室》"
        Locale.kLocales["REQUEST_DJDL"] = "《大吉大利》"
        Locale.kLocales["REQUEST_WILLINGS"] = "《今天给大家看点想看的东西》"

        Locale.kLocales["REQUEST_SCREAM"] = "尖叫"
        Locale.kLocales["REQUEST_SCREAMLONG"] = "毫无意义的尖叫"
        Locale.kLocales["REQUEST_JESTER"] = "崩溃"
        Locale.kLocales["REQUEST_WU"] = "芜?"
        Locale.kLocales["REQUEST_AH"] = "啊?"

        Locale.kLocales["MUTE_REQUEST_CUSTOM"] = "太吵请点我"
        Locale.kLocales["UNMUTE_REQUEST_CUSTOM"] = "太安静请点我"

        Locale.kLocales["VOTE_DISEASE"] = "全体玩家 - [突发恶疾]"
        Locale.kLocales["VOTE_DISEASE_QUERY1"] = "一把米诺"
        Locale.kLocales["VOTE_DISEASE_QUERY2"] = "奥利安费"
        Locale.kLocales["VOTE_DISEASE_QUERY3"] = "下面就要打开我的文本框了"
        Locale.kLocales["VOTE_DISEASE_QUERY4"] = "欧系给"
        Locale.kLocales["VOTE_DISEASE_QUERY5"] = "欧内的手 好汉"
        Locale.kLocales["VOTE_DISEASE_QUERY6"] = "希望你对你的人生也是这个态度"
        Locale.kLocales["VOTE_DISEASE_QUERY7"] = "草 走 忽略"
        Locale.kLocales["VOTE_DISEASE_QUERY8"] = "惹啊啊啊啊啊啊啊"
        Locale.kLocales["VOTE_DISEASE_QUERY9"] = "久菜合子 贼积吧好吃"
        Locale.kLocales["VOTE_DISEASE_QUERY10"] = "Deep Dark Fantasy"
    end
end
if AddHintModPanel then
    local panelMaterial = PrecacheAsset("materials/CNCommunityVoices/Banner.material")
    AddHintModPanel(panelMaterial, "https://docs.qq.com/doc/DUHZFaHNQdExQSlZs", "OK 这就要打开我的文本框了")
end