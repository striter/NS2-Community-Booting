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

    if kTranslateMessage then
        kTranslateMessage["CNVO_TITLE"] = "语音拓展"
        kTranslateMessage["CNVO_VOLUME"] = "音量矫正"
        kTranslateMessage["CNVO_WEB"] = "使用说明"
    end

    if kLocales then
        kLocales["CNVO_TITLE"] = "CN Voice Over"
        kLocales["CNVO_VOLUME"] = "Volume"
        kLocales["CNVO_WEB"] = "Manual"
        
        kLocales["REQUEST_DISEASE"] = "突发恶疾"
        kLocales["REQUEST_OTTO_OXG"] = "欧西给"
        kLocales["REQUEST_OTTO_KTHULU"] = "古神语"
        kLocales["REQUEST_OTTO_DDD"] = "唢呐演奏"
        kLocales["REQUEST_OTTO_JB"] = "基掰"
        kLocales["REQUEST_OTTO_STORY"] = "《营养》"
        kLocales["REQUEST_OTTO_FOOD"] = "韭菜盒子"
        kLocales["REQUEST_OTTO_SPEAK"] = "负能量"
        kLocales["REQUEST_OTTO_ONDS"] = "欧内的手"
        kLocales["REQUEST_XUAN_SPEAK"] = "小吠"
        kLocales["REQUEST_XUAN_WOOF"] = "狂吠"
        kLocales["REQUEST_XUAN_OHOO"] = "芜湖"
        kLocales["REQUEST_XUAN_REA"] = "惹啊啊"
        kLocales["REQUEST_XUAN_AHA"] = "啊哈"
        kLocales["REQUEST_XUAN_STORY"] = "《第一个王者》"
        kLocales["REQUEST_DUIDUIDUI"] = "《生活的态度》"
        kLocales["REQUEST_LIBERITY"] = "《独立宣言》"
        kLocales["REQUEST_SUMMER"] = "《盛夏》"
        kLocales["REQUEST_CZHL"] = "《沈阳大街》"
        kLocales["REQUEST_LOCKERROOM"] = "《更衣室》"
        kLocales["REQUEST_DJDL"] = "《大吉大利》"
        kLocales["REQUEST_WILLINGS"] = "《今天给大家看点想看的东西》"

        kLocales["REQUEST_SCREAM"] = "尖叫"
        kLocales["REQUEST_SCREAMLONG"] = "毫无意义的尖叫"
        kLocales["REQUEST_JESTER"] = "崩溃"
        kLocales["REQUEST_WU"] = "芜?"
        kLocales["REQUEST_AH"] = "啊?"

        kLocales["MUTE_REQUEST_CUSTOM"] = "太吵请点我"
        kLocales["UNMUTE_REQUEST_CUSTOM"] = "太安静请点我"

        kLocales["VOTE_DISEASE"] = "全体玩家 - [突发恶疾]"
        kLocales["VOTE_DISEASE_QUERY1"] = "一把米诺"
        kLocales["VOTE_DISEASE_QUERY2"] = "奥利安费"
        kLocales["VOTE_DISEASE_QUERY3"] = "下面就要打开我的文本框了"
        kLocales["VOTE_DISEASE_QUERY4"] = "欧系给"
        kLocales["VOTE_DISEASE_QUERY5"] = "欧内的手 好汉"
        kLocales["VOTE_DISEASE_QUERY6"] = "希望你对你的人生也是这个态度"
        kLocales["VOTE_DISEASE_QUERY7"] = "草 走 忽略"
        kLocales["VOTE_DISEASE_QUERY8"] = "惹啊啊啊啊啊啊啊"
        kLocales["VOTE_DISEASE_QUERY9"] = "久菜合子 贼积吧好吃"
        kLocales["VOTE_DISEASE_QUERY10"] = "Deep Dark Fantasy"
    end
end
if AddHintModPanel then
    local panelMaterial = PrecacheAsset("materials/CNCommunityVoices/Banner.material")
    AddHintModPanel(panelMaterial, "https://docs.qq.com/doc/DUHZFaHNQdExQSlZs", "OK 这就要打开我的文本框了")
end