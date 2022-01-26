ModLoader.SetupFileHook("lua/GUIAssets.lua", "lua/CNLocalize/GUIAssets.lua", "post")

if AddHintModPanel then
    local cnTitleMaterial = PrecacheAsset("materials/CNLocalize/Banner.material")
    AddHintModPanel(cnTitleMaterial, "https://docs.qq.com/doc/DUFlBR0ZJeFRiRnRi","阅读服务器事宜")

    local muteKickMaterial = PrecacheAsset("materials/CNLocalize/Banner_MuteKick.material")
    AddHintModPanel(muteKickMaterial, "https://docs.qq.com/doc/DWUVmb3FEemlBaFBB","阅读语音净化指南")
end