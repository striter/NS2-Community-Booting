Fonts.kAgencyFB_Huge_Bold = PrecacheAsset("fontsOverride/AgencyFBBold_huge.fnt")
Fonts.kAgencyFB_Large_Bold = PrecacheAsset("fontsOverride/AgencyFB_large_bold.fnt")
Fonts.kAgencyFB_Huge = PrecacheAsset("fontsOverride/AgencyFB_huge.fnt")
Fonts.kAgencyFB_Large = PrecacheAsset("fontsOverride/AgencyFB_large.fnt")
-- Fonts.kAgencyFB_Large_Bordered = PrecacheAsset("fontsOverride/AgencyFB_large_bordered.fnt")
Fonts.kAgencyFB_Medium = PrecacheAsset("fontsOverride/AgencyFB_medium.fnt")
Fonts.kAgencyFB_Small = PrecacheAsset("fontsOverride/AgencyFB_small.fnt")
Fonts.kAgencyFB_Smaller_Bordered = PrecacheAsset("fontsOverride/AgencyFB_smaller_bordered.fnt")
Fonts.kAgencyFB_Tiny = PrecacheAsset("fontsOverride/AgencyFB_tiny.fnt")
Fonts.kInsight = PrecacheAsset("fontsOverride/insight.fnt")
Fonts.kArial_13 = PrecacheAsset("fontsOverride/Arial_13.fnt")
Fonts.kArial_15 = PrecacheAsset("fontsOverride/Arial_15.fnt")
Fonts.kArial_17 = PrecacheAsset("fontsOverride/Arial_17.fnt")
Fonts.kArial_Tiny = PrecacheAsset("fontsOverride/Arial_Tiny.fnt")
Fonts.kArial_Small = PrecacheAsset("fontsOverride/Arial_Small.fnt")
Fonts.kArial_Medium = PrecacheAsset("fontsOverride/Arial_Medium.fnt")
-- Fonts.kKartika_Small = PrecacheAsset("fontsOverride/Kartika_small.fnt")
-- Fonts.kKartika_Medium = PrecacheAsset("fontsOverride/Kartika_medium.fnt")
Fonts.kStamp_Large = PrecacheAsset("fontsOverride/Stamp_large.fnt")
Fonts.kStamp_Medium = PrecacheAsset("fontsOverride/Stamp_medium.fnt")
Fonts.kStamp_Huge = PrecacheAsset("fontsOverride/Stamp_huge.fnt")
Fonts.kMicrogrammaDMedExt_Large = PrecacheAsset("fontsOverride/MicrogrammaDMedExt_large.fnt")
Fonts.kMicrogrammaDMedExt_Medium = PrecacheAsset("fontsOverride/MicrogrammaDMedExt_medium.fnt")
-- Fonts.kMicrogrammaDMedExt_Medium2 = PrecacheAsset("fontsOverride/MicrogrammaDMedExt_medium2.fnt")
Fonts.kMicrogrammaDMedExt_Small = PrecacheAsset("fontsOverride/MicrogrammaDMedExt_small.fnt")
-- Fonts.kMicrogrammaDBolExt_Huge = PrecacheAsset("fontsOverride/MicrogrammaDBolExt_huge.fnt")

FontFamilies = {"kAgencyFBBold", "kAgencyFB", "kArial", "kKartika", "kStamp", "kMicrogrammaDMedExt"}

FontFamilies["kAgencyFBBold"] = {}
FontFamilies["kAgencyFBBold"][Fonts.kAgencyFB_Huge_Bold] = 96
FontFamilies["kAgencyFBBold"][Fonts.kAgencyFB_Large_Bold] = 41

FontFamilies["kAgencyFB"] = {}
FontFamilies["kAgencyFB"][Fonts.kAgencyFB_Huge] = 96
FontFamilies["kAgencyFB"][Fonts.kAgencyFB_Large] = 41
FontFamilies["kAgencyFB"][Fonts.kAgencyFB_Medium] = 33
FontFamilies["kAgencyFB"][Fonts.kAgencyFB_Small] = 27
FontFamilies["kAgencyFB"][Fonts.kAgencyFB_Tiny] = 20

FontFamilies["kArial"] = {}
FontFamilies["kArial"][Fonts.kArial_Medium] = 33
FontFamilies["kArial"][Fonts.kArial_Small] = 27
FontFamilies["kArial"][Fonts.kArial_Tiny] = 20
FontFamilies["kArial"][Fonts.kArial_17] = 17
FontFamilies["kArial"][Fonts.kArial_15] = 15
FontFamilies["kArial"][Fonts.kArial_13] = 13

FontFamilies["kKartika"] = {}
FontFamilies["kKartika"][Fonts.kKartika_Medium] = 33
FontFamilies["kKartika"][Fonts.kKartika_Small] = 27

FontFamilies["kStamp"] = {}
FontFamilies["kStamp"][Fonts.kStamp_Huge] = 96
FontFamilies["kStamp"][Fonts.kStamp_Large] = 41
FontFamilies["kStamp"][Fonts.kStamp_Medium] = 33

-- This one is only used for weapon displays and only has numbers...
FontFamilies["kMicrogrammaDMedExt"] = {}
FontFamilies["kMicrogrammaDMedExt"][Fonts.kMicrogrammaDMedExt_Large] = 93
FontFamilies["kMicrogrammaDMedExt"][Fonts.kMicrogrammaDMedExt_Medium] = 80
FontFamilies["kMicrogrammaDMedExt"][Fonts.kMicrogrammaDMedExt_Medium2] = 80
FontFamilies["kMicrogrammaDMedExt"][Fonts.kMicrogrammaDMedExt_Small] = 35
