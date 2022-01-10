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

-- if Shine then
--     local oldGetPharse = Shine.Locale.GetPhrase

--     local function GetPhrase( Source, Key )
--         Shared.Message("Shine" .. Key)
--         return oldGetPharse(Source,Key)
--     end

--     local function GetInterpolatedPhrase( Source, Key, FormatArgs )
--         Shared.Message("Interpolated" .. Key)
--         return StringInterpolate( GetPhrase( Source, Key ), FormatArgs,  Shine.Locale:GetLanguageDefinition() )
--     end

--     Shine.Locale.GetPhrase = GetPhrase
--     Shine.Locale.GetInterpolatedPhrase = GetInterpolatedPhrase
-- end