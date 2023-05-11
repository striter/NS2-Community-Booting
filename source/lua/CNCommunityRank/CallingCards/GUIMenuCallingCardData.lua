-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/PlayerScreen/CallingCards/GUIMenuCallingCardData.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
--    Data for calling cards, and some utility functions to get the right one.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/Utility.lua")
Script.Load("lua/Globals.lua")

kCallingCards = enum({

    -- Default Calling Cards
    "None",
    "NaturalCauses", -- Killed by death trigger, or structure. (whip, turrets, etc)

    -- Old Shoulder Patches
    "Reinforced",
    "Shadow",
    "WC14", -- world championship
    "Godar",
    "Saunamen",
    "Snails",
    "Titus",
    "Kodiak",
    "Reaper",
    "Tundra",
    "Rookie",
    "HauntedBabbler",
    "Leviathan",
    "Peeper",
    "SummerGorge",
    "Halloween2016",

    -- Set 1
    "SkulkHuggies",
    "UrpaBooty",
    "NedRage",
    "WeldDone",
    "BabyMarine",
    "BalanceGorge",
    "BabblerSurprise",
    "OhNoes", -- Onos "prepare" face
    "GorgeTableFlip",
    "ShadowFade",
    "BurnoutFade",
    "Lork", -- dump lerk face
    "ChromaOnos",
    "MadAxeGorge",
    "Urpa",
    "SadBabbler",
    "Pudgy", -- fat gorge
    "ForScience", -- jetpack gorge with goggles
    "BattleGorge",
    "TurboDrifter", -- Drifter with jetpack
    "SkulkSlippers",
    "LazyGorge",
    "AngryOnos",
    "Lerked",
    "Over9000Degrees",
    "DontBlink",
    "LockedAndLoaded",
    
    "Dragon",
    "KittyKitty",
})

kCallingCardOptionKey = "customization/calling-card"
kDefaultPlayerCallingCard = kCallingCards.None
kNaturalCausesCallingCard = kCallingCards.NaturalCauses
kCallingCardFeatureUnlockCard  = kCallingCards.SkulkHuggies -- When this is received, also unlock all shoulder patches to be used as calling cards. (Calling cards feature in general is unlocked)

-- These are unlocked via having their corresponding shoulder patch in unlocked.
local kShoulderPatchCards = set
{
    kCallingCards.Reinforced,
    kCallingCards.Shadow,
    kCallingCards.WC14,
    kCallingCards.Godar,
    kCallingCards.Saunamen,
    kCallingCards.Snails,
    kCallingCards.Titus,
    kCallingCards.Kodiak,
    kCallingCards.Reaper,
    kCallingCards.Tundra,
    kCallingCards.Rookie,
    kCallingCards.Leviathan,
    kCallingCards.Peeper,
    kCallingCards.SummerGorge,
    kCallingCards.HauntedBabbler,
}

local kUnobtainableCallingCards = set
{
    kCallingCards.Reinforced,
    kCallingCards.Shadow,
    kCallingCards.WC14,
    kCallingCards.Godar,
    kCallingCards.Saunamen,
    kCallingCards.Snails,
    kCallingCards.Titus,
    kCallingCards.Leviathan,
    kCallingCards.Peeper,
    kCallingCards.SummerGorge,
    kCallingCards.HauntedBabbler,
    kCallingCards.Halloween2016
}

-- Texture files for calling cards are all atlases
local kCallingCardTexturePallete =
{
    PrecacheAsset("ui/callingcards/callingcards_1.dds"), -- First set of new calling cards
    PrecacheAsset("ui/callingcards/natural_causes.dds"), -- Special "world killed you" calling card. (NOT ATLAS)
    PrecacheAsset("ui/callingcards/none.dds"),
    PrecacheAsset("ui/callingcards/callingcards_ns2cn.dds"),
}

local kDynamicCardTextures = {}
local temporaryDynamicCards = {}
Shared.GetMatchingFileNames( "ui/callingcards/dynamic/*.dds", false, temporaryDynamicCards)
for _, cardPath in ipairs(temporaryDynamicCards) do
    local _, _, cardName = string.find(cardPath, "ui/callingcards/dynamic/(.*).dds")
    Shared.Message(cardName .. " " .. cardPath)
    kDynamicCardTextures[cardName] = PrecacheAsset(cardPath)
end
temporaryDynamicCards = nil

local kSystemCallingCards = set
{
    kCallingCards.NaturalCauses
}

local kCallingCardData =
{
    [kCallingCards.NaturalCauses]   = { texture = 2, idx = 0,  itemId = 0},
    [kCallingCards.None]            = { texture = 3, idx = 0,  itemId = 0},

    [kCallingCards.SkulkHuggies]    = { texture = 1, idx = 0,  itemId = kSkulkHugCardItemId},
    [kCallingCards.UrpaBooty]       = { texture = 1, idx = 1,  itemId = kUrpaBootyCardItemId},
    [kCallingCards.NedRage]         = { texture = 1, idx = 2,  itemId = kNedRageCardItemId},
    [kCallingCards.WeldDone]        = { texture = 1, idx = 3,  itemId = kJobWeldDoneCardItemId},
    [kCallingCards.BabyMarine]      = { texture = 1, idx = 4,  itemId = kBabyMarineCardItemId},
    [kCallingCards.BalanceGorge]    = { texture = 1, idx = 5,  itemId = kBalanceGorgeCardItemId},
    [kCallingCards.BabblerSurprise] = { texture = 1, idx = 6,  itemId = kBabblerSurpriseCardItemId},
    [kCallingCards.OhNoes]          = { texture = 1, idx = 7,  itemId = kOhNoesCardItemId},
    [kCallingCards.GorgeTableFlip]  = { texture = 1, idx = 8,  itemId = kTableFlipGorgeCardItemId},
    [kCallingCards.ShadowFade]      = { texture = 1, idx = 9,  itemId = kShadowFadeCardItemId},
    [kCallingCards.BurnoutFade]     = { texture = 1, idx = 10, itemId = kBurnoutFadeCardItemId},
    [kCallingCards.Lork]            = { texture = 1, idx = 11, itemId = kLorkCardItemId},
    [kCallingCards.ChromaOnos]      = { texture = 1, idx = 12, itemId = kChromaOnosCardItemId},
    [kCallingCards.MadAxeGorge]     = { texture = 1, idx = 13, itemId = kBattleGorgeShoulderPatchItemId},
    [kCallingCards.Urpa]            = { texture = 1, idx = 14, itemId = kUrpaCardItemId},
    [kCallingCards.SadBabbler]      = { texture = 1, idx = 15, itemId = kSadbabblerCardItemId},
    [kCallingCards.Pudgy]           = { texture = 1, idx = 16, itemId = kPudgyCardItemId},
    [kCallingCards.ForScience]      = { texture = 1, idx = 17, itemId = kForScienceCardItemId},
    [kCallingCards.BattleGorge]     = { texture = 1, idx = 18, itemId = kBattleGorgeCardItemId},
    [kCallingCards.TurboDrifter]    = { texture = 1, idx = 19, itemId = kTurboDrifterCardItemId},
    [kCallingCards.SkulkSlippers]   = { texture = 1, idx = 20, itemId = kSlipperSkulkCardItemId},
    [kCallingCards.LazyGorge]       = { texture = 1, idx = 21, itemId = kLazyGorgeCardItemId},
    [kCallingCards.AngryOnos]       = { texture = 1, idx = 22, itemId = kAngryOnosCardItemId},
    [kCallingCards.Lerked]          = { texture = 1, idx = 23, itemId = kLerkedCardItemId},

    -- Original shoulder patches
    [kCallingCards.Reinforced]      = { texture = 1, idx = 24, itemId = kReinforcedShoulderPatchItemId},
    [kCallingCards.Shadow]          = { texture = 1, idx = 25, itemId = kShadowShoulderPatchItemId},
    [kCallingCards.WC14]            = { texture = 1, idx = 26, itemId = kNS2WC14GlobeShoulderPatchItemId},
    [kCallingCards.Godar]           = { texture = 1, idx = 27, itemId = kGodarShoulderPatchItemId},
    [kCallingCards.Saunamen]        = { texture = 1, idx = 28, itemId = kSaunamenShoulderPatchItemId},
    [kCallingCards.Snails]          = { texture = 1, idx = 29, itemId = kSnailsShoulderPatchItemId},
    [kCallingCards.Titus]           = { texture = 1, idx = 30, itemId = kTitusGamingShoulderPatchItemId},
    [kCallingCards.Kodiak]          = { texture = 1, idx = 31, itemId = kKodiakShoulderPatchItemId},
    [kCallingCards.Reaper]          = { texture = 1, idx = 32, itemId = kReaperShoulderPatchItemId},
    [kCallingCards.Tundra]          = { texture = 1, idx = 33, itemId = kTundraShoulderPatchItemId},
    [kCallingCards.Rookie]          = { texture = 1, idx = 34, itemId = kRookieShoulderPatchItemId},
    [kCallingCards.HauntedBabbler]  = { texture = 1, idx = 35, itemId = kHauntedBabblerPatchItemId},
    [kCallingCards.Leviathan]       = { texture = 1, idx = 36, itemId = kSNLeviathanPatchItemId},
    [kCallingCards.Peeper]          = { texture = 1, idx = 37, itemId = kSNPeeperPatchItemId},
    [kCallingCards.SummerGorge]     = { texture = 1, idx = 38, itemId = kSummerGorgePatchItemId},

    [kCallingCards.Halloween2016]   = { texture = 1, idx = 39, itemId = kHalloween16ShoulderPatchItemId},
    [kCallingCards.Over9000Degrees] = { texture = 1, idx = 40, itemId = kOverNineCardItemId},
    [kCallingCards.DontBlink]       = { texture = 1, idx = 41, itemId = kDoNotBlinkCardItemId},
    [kCallingCards.LockedAndLoaded] = { texture = 1, idx = 42, itemId = kLockedLoadedCardItemId},

    [kCallingCards.Dragon] = { texture = 4 , idx = 0 , itemId = kDragonCardItemId},
    [kCallingCards.KittyKitty] = { texture = "KittyKitty" , idx = 42 , dynamic = true, itemId = kKittyKittyCardItemId},
}

local kCallingCardUnlockedTooltips =
{
    [kCallingCards.None]            = "CALLINGCARD_NONE_TOOLTIP",

    -- Original shoulder patches
    [kCallingCards.Reinforced]      = "CALLINGCARD_REINFORCED_TOOLTIP",
    [kCallingCards.Shadow]          = "CALLINGCARD_SHADOW_TOOLTIP",
    [kCallingCards.WC14]            = "CALLINGCARD_WC14_TOOLTIP",
    [kCallingCards.Godar]           = "CALLINGCARD_GODAR_TOOLTIP",
    [kCallingCards.Saunamen]        = "CALLINGCARD_SAUNAMEN_TOOLTIP",
    [kCallingCards.Snails]          = "CALLINGCARD_SNAILS_TOOLTIP",
    [kCallingCards.Titus]           = "CALLINGCARD_TITUS_TOOLTIP",
    [kCallingCards.Kodiak]          = "CALLINGCARD_KODIAK_TOOLTIP",
    [kCallingCards.Reaper]          = "CALLINGCARD_REAPER_TOOLTIP",
    [kCallingCards.Tundra]          = "CALLINGCARD_TUNDRA_TOOLTIP",
    [kCallingCards.Rookie]          = "CALLINGCARD_ROOKIE_TOOLTIP",
    [kCallingCards.HauntedBabbler]  = "CALLINGCARD_HAUNTEDBABBLER_TOOLTIP",
    [kCallingCards.Leviathan]       = "CALLINGCARD_LEVIATHAN_TOOLTIP",
    [kCallingCards.Peeper]          = "CALLINGCARD_PEEPER_TOOLTIP",
    [kCallingCards.SummerGorge]     = "CALLINGCARD_SUMMERGORGE_TOOLTIP",

    [kCallingCards.SkulkHuggies]    = "CALLINGCARD_SKULKHUGGIES_TOOLTIP",
    [kCallingCards.UrpaBooty]       = "CALLINGCARD_URPABOOTY_TOOLTIP",
    [kCallingCards.NedRage]         = "CALLINGCARD_NEDRAGE_TOOLTIP",
    [kCallingCards.WeldDone]        = "CALLINGCARD_WELDDONE_TOOLTIP",
    [kCallingCards.BabyMarine]      = "CALLINGCARD_BABYMARINE_TOOLTIP",
    [kCallingCards.BalanceGorge]    = "CALLINGCARD_BALANCEGORGE_TOOLTIP",
    [kCallingCards.BabblerSurprise] = "CALLINGCARD_BABBLERSURPRISE_TOOLTIP",
    [kCallingCards.OhNoes]          = "CALLINGCARD_OHNOES_TOOLTIP",
    [kCallingCards.GorgeTableFlip]  = "CALLINGCARD_GORGETABLEFLIP_TOOLTIP",
    [kCallingCards.ShadowFade]      = "CALLINGCARD_SHADOWFADE_TOOLTIP",
    [kCallingCards.BurnoutFade]     = "CALLINGCARD_BURNOUTFADE_TOOLTIP",
    [kCallingCards.Lork]            = "CALLINGCARD_LORK_TOOLTIP",
    [kCallingCards.ChromaOnos]      = "CALLINGCARD_CHROMAONOS_TOOLTIP",
    [kCallingCards.MadAxeGorge]     = "CALLINGCARD_MADAXEGORGE_TOOLTIP",
    [kCallingCards.Urpa]            = "CALLINGCARD_URPA_TOOLTIP",
    [kCallingCards.SadBabbler]      = "CALLINGCARD_SADBABBLER_TOOLTIP",
    [kCallingCards.Pudgy]           = "CALLINGCARD_PUDGY_TOOLTIP",
    [kCallingCards.ForScience]      = "CALLINGCARD_FORSCIENCE_TOOLTIP",
    [kCallingCards.BattleGorge]     = "CALLINGCARD_BATTLEGORGE_TOOLTIP",
    [kCallingCards.TurboDrifter]    = "CALLINGCARD_TURBODRIFTER_TOOLTIP",
    [kCallingCards.SkulkSlippers]   = "CALLINGCARD_SKULKSLIPPERS_TOOLTIP",
    [kCallingCards.LazyGorge]       = "CALLINGCARD_LAZYGORGE_TOOLTIP",
    [kCallingCards.AngryOnos]       = "CALLINGCARD_ANGRYONOS_TOOLTIP",
    [kCallingCards.Lerked]          = "CALLINGCARD_LERKED_TOOLTIP",
    [kCallingCards.Halloween2016]   = "CALLINGCARD_HALLOWEEN2016_TOOLTIP",
    [kCallingCards.Over9000Degrees] = "CALLINGCARD_OVER9000DEGREES_TOOLTIP",
    [kCallingCards.DontBlink]       = "CALLINGCARD_DONTBLINK_TOOLTIP",
    [kCallingCards.LockedAndLoaded] = "CALLINGCARD_LOCKEDANDLOADED_TOOLTIP",


    [kCallingCards.Dragon] = "CALLINGCARD_DRAGON_TOOLTIP",
    [kCallingCards.KittyKitty] = "CALLINGCARD_KITTYKITTY_TOOLTIP",
}

local kCallingCardLockedTooltipOverrides =
{
    [kCallingCards.Rookie]          = "CALLINGCARD_ROOKIE_LOCKED_TOOLTIP",
    [kCallingCards.Dragon]          = "CALLINGCARD_LOCKED_TOOLTIP_EXTRA",
    [kCallingCards.KittyKitty]          = "CALLINGCARD_LOCKED_TOOLTIP_EXTRA",
}

function GetCallingCardLockedTooltipIdentifierOverride(callingCard)
    return kCallingCardLockedTooltipOverrides[callingCard]
end

function GetCallingCardUnlockedTooltipIdentifier(callingCard)
    return kCallingCardUnlockedTooltips[callingCard]
end

function GetCallingCardTextureDetails(callingCard)

    local result = {}
    local data = kCallingCardData[callingCard]

    if not data then return end

    -- Get zero-based texture coordinates
    local callingCardSize = 512
    local nCols = 4
    local x1, y1, x2, y2

    local row = math.floor(data.idx / nCols)
    local col = data.idx % nCols

    x1 = (col * callingCardSize)
    y1 = (row * callingCardSize)

    x2 = x1 + callingCardSize
    y2 = y1 + callingCardSize
    
    result.dyanmic = data.dynamic
    if result.dyanmic then
        result.texture = kDynamicCardTextures[data.texture]
        result.texCoords = { 0, 0, 256, 256 }
    else
        result.texture = kCallingCardTexturePallete[data.texture]
        result.texCoords = { x1, y1, x2, y2 }
    end
    return result

end

function GetIsCallingCardSystemOnly(callingCard)
    return kSystemCallingCards[callingCard]
end

function GetIsCallingCardShoulderPatch(callingCard)
    return kShoulderPatchCards[callingCard]
end

function GetIsCallingCardUnobtainable(callingCard)
    return kUnobtainableCallingCards[callingCard]
end

function GetIsCallingCardUnlocked(callingCard)

    if callingCard == kCallingCards.None then
        return true
    end

    if kSystemCallingCards[callingCard] then
        return false
    end

    local cardItemId = kCallingCardData[callingCard].itemId or 0
    local shoulderPadUnlockCard = kCallingCardData[kCallingCardFeatureUnlockCard].itemId or 0

    if cardItemId == 0 then
        Log("WARNING: Card (%s) ItemId is ZERO!!", kCallingCards[callingCard])
    end

    -- Shoulder pad calling cards are unlocked via just having the shoulder pad itself, and as long as the first calling card reward is unlocked
    if kShoulderPatchCards[callingCard] then
        return GetOwnsItem(shoulderPadUnlockCard) and GetHasShoulderPad(GetShoulderPadIndexById(cardItemId))
    end

    -- Now its just simple, for cards that aren't shoulder pads.
    return GetOwnsItem(cardItemId)

end

if Client then

    -- Dumps all calling cards, and whether they're locked/unlocked. If locked, spits out a reason as well.
    Event.Hook("Console_dumpcc", function(filter)

        local ownsShoulderPatchUnlock = GetOwnsItem(kCallingCardData[kCallingCardFeatureUnlockCard].itemId)
        Log("==== Dumping Calling Cards Data ====")
        Log("\tShoulder Patch Cards Unlocked: '%s'", ownsShoulderPatchUnlock)

        for i = 1, #kCallingCards do

            local cardItemId = kCallingCardData[i].itemId -- Can be itemid for shoulder patch

            local callingCardName = kCallingCards[i]
            local systemOnly = GetIsCallingCardSystemOnly(i)
            local unobtainable = GetIsCallingCardUnobtainable(i)
            local isShoulderPatch = GetIsCallingCardShoulderPatch(i)
            local hasShoulderPad = GetHasShoulderPad(GetShoulderPadIndexById(cardItemId))
            local hasCallingCard = GetOwnsItem(cardItemId)
            local ccUnlocked = GetIsCallingCardUnlocked(i) -- default check

            local willHideCard =
                unobtainable
                and (systemOnly or not hasCallingCard or not hasShoulderPad)

            local hideReason = "none"
            if willHideCard then
                if systemOnly then
                    hideReason = "System Only (Reserved)"
                elseif not hasCallingCard then
                    hideReason = "Does not own ItemID (No special checks)"
                elseif not hasShoulderPad then
                    hideReason = "Does not own shoulder pad"
                end
            end

            local printCallingCard = true
            if filter == "hidden" then
                printCallingCard = willHideCard
            elseif filter == "locked" then
                printCallingCard = not ccUnlocked
            end

            if printCallingCard then

                Log("\t\t%s", callingCardName)
                Log("\t\t\tSystem Only: '%s'", systemOnly)
                Log("\t\t\tUnobtainable: '%s'", unobtainable)
                Log("\t\t\tIs Shoulder Patch: '%s'", isShoulderPatch)
                Log("\t\t\tHas Shoulder Patch: '%s'", hasShoulderPad)
                Log("\t\t\tHas Calling Card: '%s'", hasCallingCard)
                Log("\t\t\tHidden: '%s'", willHideCard)
                Log("\t\t\tHide Reason: '%s'", hideReason)

            end
        end

    end)

end
