Script.Load("lua/CNLocalize/CNStrings.lua")
local baseResolveString = Locale.ResolveString

function CNLocalizeResolve(input)
    if not input then return "" end

    local resolvedString = rawget(kTranslateMessage,input) 
    if resolvedString  then
        return resolvedString
    end

    return baseResolveString(input)
end

Locale.ResolveString = CNLocalizeResolve

ModLoader.SetupFileHook("lua/GUIMinimap.lua", "lua/CNLocalize/GUIMinimap.lua", "post")

if Shine then

    Script.Load("lua/CNLocalize/ShineStrings.lua")
    function Shine.Locale:GetLocalisedString( Source, Lang, Key )
        
        local finalValue = rawget(kShineTranslations,Key)
        if finalValue then
            return finalValue
        end


        local LanguageStrings = Shine.Locale:GetLanguageStrings( Source, Lang )
        if not LanguageStrings or not LanguageStrings[ Key ] then
            LanguageStrings = Shine.Locale:GetLanguageStrings( Source, Shine.Locale.DefaultLanguage )
        end
        local finalKey = LanguageStrings and LanguageStrings[ Key ] or Key
        local finalValue = rawget(kShineTranslations,finalKey)
        if finalValue then
            return finalValue
        end
        Shared.Message("Shine:|".. Key .. "|" .. finalKey .. "|Untranslated")
        return finalKey
    end
    
end
