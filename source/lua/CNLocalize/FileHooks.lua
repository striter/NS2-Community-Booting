ModLoader.SetupFileHook("lua/GUIAssets.lua", "lua/CNLocalize/GUIAssets.lua", "post")
ModLoader.SetupFileHook("lua/GUI/FontGlobals.lua", "lua/CNLocalize/FontGlobals.lua", "replace")

ModLoader.SetupFileHook("lua/GUIMinimap.lua", "lua/CNLocalize/GUIMinimap.lua", "post")
ModLoader.SetupFileHook("lua/PhaseGate.lua", "lua/CNLocalize/PhaseGate.lua", "post")
ModLoader.SetupFileHook("lua/Observatory.lua", "lua/CNLocalize/Observatory.lua", "post")
ModLoader.SetupFileHook("lua/TunnelEntrance.lua", "lua/CNLocalize/TunnelEntrance.lua", "post")

ModLoader.SetupFileHook("lua/menu2/MenuUtilities.lua", "lua/CNLocalize/MenuUtilities.lua", "post")
ModLoader.SetupFileHook("lua/NetworkMessages_Server.lua", "lua/CNLocalize/NetworkMessages_Server.lua", "replace")

if AddHintModPanel then
    local cnTitleMaterial = PrecacheAsset("materials/CNLocalize/Banner.material")
    AddHintModPanel(cnTitleMaterial, "https://docs.qq.com/doc/DUFlBR0ZJeFRiRnRi","阅读服务器事宜")

    local muteKickMaterial = PrecacheAsset("materials/CNLocalize/Banner_MuteKick.material")
    AddHintModPanel(muteKickMaterial, "https://docs.qq.com/doc/DWUVmb3FEemlBaFBB","阅读语音净化指南")
end

Shared.Message("CN Localize Fonts Hooked 2022.2.11.0")
