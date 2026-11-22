-- Post-hook for lua/GUIAssets.lua.
--
-- The spectator overhead nameplate (GUIInsight_PlayerHealthbars) and the other
-- insight widgets take their face straight from Fonts.kInsight. The vanilla table
-- points that key at fonts/insight.fnt, a 2075 glyph Latin-only atlas; a mod copy
-- under fonts/ does not replace it, so Chinese names kept falling back to the
-- engine CJK font. Point the key at the fontsOverride atlas that carries the
-- Chinese page instead.

if not Client then return end
if not Fonts then return end

local kInsightAtlasPath = "fontsOverride/insight.fnt"

if GetFileExists(kInsightAtlasPath) then
    Fonts.kInsight = PrecacheAsset(kInsightAtlasPath)
end
