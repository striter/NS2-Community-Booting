Fonts.kAgencyFB_Medium = PrecacheAsset("fontsOverride/AgencyFB_medium.fnt")
Fonts.kAgencyFB_Small = PrecacheAsset("fontsOverride/AgencyFB_small.fnt")
Fonts.kAgencyFB_Tiny = PrecacheAsset("fontsOverride/AgencyFB_tiny.fnt")

Script.Load("lua/CNLocalize/CNStrings.lua")
local baseResolveString = Locale.ResolveString

function CNLocalizeResolve(input)
    if not input then return "" end

    local lang = Locale.GetLocale()
    local resolvedString = kTranslateMessage[input] 
    if resolvedString  then
        return resolvedString
    end
    return input

end
Locale.ResolveString = CNLocalizeResolve

ModLoader.SetupFileHook("lua/GUIMinimap.lua", "lua/CNLocalize/GUIMinimap.lua", "post")

Shared.Message("Shine SHine SHINE")
function Locale:GetLocalisedString( Source, Lang, Key )
    return CNLocalizeResolve(Key)
end