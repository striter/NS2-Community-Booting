-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/GUI/FontGlobals.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Collection of globals designed to make working with fonts less painful... if not
--    totally painless.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/UnorderedSet.lua")

local fontFamilies = {} -- dict (nameOfFamily -> array of font files)
local fontSizes = {} -- dict (font file name -> font size)
local distanceFieldFiles = {} -- set of font file names that are in the newer distance-field format.
local fallbackFamilies = {} -- dict (nameOfFamily -> array of fallback family)
local fallbackScales = {} -- dict (nameOfFamily -> array of fallback family scales)

-- Returns the actual font size of the given font file name, unscaled.  Usually corresponds to the
-- height of a large character in the font sheet.
function GetFontActualSize(fontFileName)
    assert(fontSizes[fontFileName])
    return fontSizes[fontFileName]
end

-- Either creates a new font family if one does not exist, or appends more font files to an
-- existing font family definition (useful for mods to add support for other characters to the
-- same font).
function RegisterFontFamily(fontFamilyName, fontFamilyMembers)
    
    PROFILE("FontGlobals:RegisterFontFamily")
    
    -- Ensure font family has been created.  We allow RegisterFontFamily() to be called on already
    -- existing font families as a mechanism for adding more font files/characters to the family.
    if not fontFamilies[fontFamilyName] then
        fontFamilies[fontFamilyName] = UnorderedSet()
    end
    
    local fam = fontFamilies[fontFamilyName]
    for i=1, #fontFamilyMembers do
        fam:Add(fontFamilyMembers[i].font)
        fontSizes[fontFamilyMembers[i].font] = fontFamilyMembers[i].size
        
        if fontFamilyMembers.distanceField ~= nil then
            distanceFieldFiles[fontFamilyMembers[i].font] = fontFamilyMembers.distanceField == true
        end
    end
    
    if fontFamilyMembers.fallbackFamily then
        fallbackFamilies[fontFamilyName] = fontFamilyMembers.fallbackFamily
    end
    
    if fontFamilyMembers.fallbackScale then
        fallbackScales[fontFamilyName] = fontFamilyMembers.fallbackScale
    end
    
end

function GetFontFileUsesDistanceField(fontFileName)
    return distanceFieldFiles[fontFileName] == true
end

-- Returns the font file name that is best suited for displaying the given text at the desired
-- size.
function GetMostSuitableFont(fontFamilyName, textToDisplay, desiredFontSize)
    
    PROFILE("FontGlobals:GetMostSuitableFont")
    
    local family = fontFamilies[fontFamilyName]
    if not family then
        -- font family doesn't exist
        error(string.format("Font family '%s' does not exist!", fontFamilyName))
        return nil
    end
    
    -- Get a list of which fonts in the family can actually render this string.
    local validFonts = {} -- list of fonts that can render the supplied text.
    for i=1, #family do
        if GUI.GetCanFontRenderString(family[i], textToDisplay) then
            table.insert(validFonts, family[i])
        end
    end
    
    if #validFonts == 0 then
        -- No fonts in the family can (fully) render this text.
        if fallbackFamilies[fontFamilyName] then
            local result1 = GetMostSuitableFont(fallbackFamilies[fontFamilyName], textToDisplay, desiredFontSize)
            local result2 = fallbackScales[fontFamilyName] or Vector(1, 1, 1)
            return result1, result2
        else
            -- suck it up and just render what we can with this font family.
            validFonts = family
        end
    end
    
    local bestFontDiffVal = nil
    local bestFont = nil
    for i=1, #validFonts do
        local font = validFonts[i]
        local fontSize = fontSizes[font]
        
        local sizeDiffVal = math.max(fontSize / desiredFontSize, desiredFontSize / fontSize)
        if not bestFont or sizeDiffVal < bestFontDiffVal then
            bestFont = font
            bestFontDiffVal = sizeDiffVal
        end
    end

    local vecResult = Vector(1, 1, 1)
    return bestFont, vecResult
    
end

-- Font size measured based on height of 'O' character.
RegisterFontFamily("Arial",
{
    { font = PrecacheAsset("fontsOverride/Arial_Medium.fnt"),               size = 21,  },
    { font = PrecacheAsset("fontsOverride/Arial_Small.fnt"),                size = 17,  },
    { font = PrecacheAsset("fontsOverride/Arial_Tiny.fnt"),                 size = 12,  },
    { font = PrecacheAsset("fontsOverride/Arial_17.fnt"),                   size = 11,  },
    { font = PrecacheAsset("fontsOverride/Arial_15.fnt"),                   size = 10,  },
    { font = PrecacheAsset("fontsOverride/Arial_13.fnt"),                   size = 7,   },
})

-- Font size measured based on height of 'O' character.
RegisterFontFamily("Agency",
{
    { font = PrecacheAsset("fontsOverride/AgencyFB_distfield.fnt"),         size = 49, },
    distanceField = true,
    
    fallbackFamily = "Arial",
    fallbackScale = Vector(0.67, 1, 0),
})

-- Font size measured based on height of 'O' character.
RegisterFontFamily("AgencyBold",
{
    { font = PrecacheAsset("fontsOverride/AgencyFBExtendedBold_distfield.fnt"), size = 50.5, },
    distanceField = true,
    
    fallbackFamily = "Arial",
    fallbackScale = Vector(0.67, 1, 0),
})



-- Font size measured based on height of '0' number character.
RegisterFontFamily("Microgramma",
{
    { font = PrecacheAsset("fonts/MicrogrammaDMedExt_distfield.fnt"),   size = 21 },
    distanceField = true,
    
    fallbackFamily = "Arial",
})

-- Font size measured based on height of 'O' character.
RegisterFontFamily("MicrogrammaBold",
{
    { font = PrecacheAsset("fontsOverride/MicrogrammaDBolExt_distfield.fnt"),   size = 21 },
    distanceField = true,
    
    fallbackFamily = "Arial",
})

-- Font size measured based on height of 'E' character.
RegisterFontFamily("Stamp",
{
    { font = PrecacheAsset("fonts/Stamp_huge.fnt"),                 size = 65,  },
    { font = PrecacheAsset("fonts/Stamp_large.fnt"),                size = 28,  },
    { font = PrecacheAsset("fonts/Stamp_medium.fnt"),               size = 23,  },
    
    fallbackFamily = "Arial",
})

FontGlobals = {}
FontGlobals.kDefaultFontFamily = "Agency"
FontGlobals.kDefaultFont = PrecacheAsset("fontsOverride/AgencyFB_distfield.fnt")
FontGlobals.kDefaultFontSize = fontSizes[FontGlobals.kDefaultFont]

FontGlobals.kDefaultFontShader = PrecacheAsset("shaders/GUICrispyText.surface_shader")
