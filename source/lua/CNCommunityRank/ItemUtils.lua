

local communityUnlocks 
local function CommunityUnlocks(_item,_tier)
    assert(communityUnlocks,"[CNCT] Not Initialized!")

    for index,unlocks in pairs(communityUnlocks) do
        if _tier >= index then
            for k,v in pairs(unlocks) do
                if v == _item then
                    return true
                end
            end
        end
    end
end

local baseGetOwnsItem = GetOwnsItem
function CommunityGetOwnsItem(_item,_tier)
    if CommunityUnlocks(_item,_tier) then
        return true
    end

    return baseGetOwnsItem(_item)
end

function GetOwnsItem( _item )
    --Initialize
    if not communityUnlocks then
        communityUnlocks = {
            
        [0]={
            kWoodAxeItemId,
            kWoodPistolItemId,
            kWoodRifleItemId,

            kSkulkHugCardItemId,
            kBabyMarineCardItemId,
            kNedRageCardItemId,
            kUrpaBootyCardItemId,
            kSadbabblerCardItemId,
            kJobWeldDoneCardItemId,
            kBalanceGorgeCardItemId,
            kLorkCardItemId,
        },
        [1]={
            kAssaultArmorItemId,
            kAbyssSkulkItemId,

            kDamascusAxeItemId,
            kDamascusPistolItemId,
            kDamascusRifleItemId,

            kSlipperSkulkCardItemId,
            kShadowFadeCardItemId,
            kBurnoutFadeCardItemId,
            kOverNineCardItemId,
            kLerkedCardItemId,
        },
        [2]={
            kEliteAssaultArmorItemId,
            kSleuthSkulkItemId,

            kDamascusGreenAxeItemId,
            kDamascusGreenPistolItemId,
            kDamascusGreenRifleItemId,

            kShadowTunnelItemId,
            kShadowGorgeItemId,
            kShadowStructuresItemId,

            kTableFlipGorgeCardItemId,
            kAngryOnosCardItemId,
            kOhNoesCardItemId,
        },
        [3]={
            kWidowSkulkItemId,
            kDamascusPurpleAxeItemId,
            kDamascusPurplePistolItemId,
            kDamascusPurpleRifleItemId,

            kLockedLoadedCardItemId,
            kDoNotBlinkCardItemId,
            kLazyGorgeCardItemId,
            kUrpaCardItemId,
        },
        [4]={
            kChromaArmorItemId,
            kChromaBigmacItemId,
            kChromaMilitaryBmacItemId,
            kChromaAxeItemId,
            kChromaPistolItemId,
            kChromaRifleItemId,
            kChromaShotgunItemId,
            kChromaFlamethrowerItemId,
            kChromaGrenadeLauncherItemId,
            kChromaHMGItemId,
            kChromaWelderItemId,

            kChromaCommandStationItemId,
            kChromaExtractorItemId,
            kChromaExoItemId,
            kChromaArcItemId,
            kChromaMacItemId,

            kAuricEggItemId,
            kAuricSkulkItemId,
            kAuricLerkItemId,
            kAuricFadeItemId,
            kAuricOnosItemId,
            kAuricGorgeItemId,
            kAuricGorgeClogItemId,
            kAuricGorgeHydraItemId,
            kAuricGorgeBabblerItemId,
            kAuricGorgeBabblerEggItemId,

            kAuricTunnelItemId,
            kAuricCystItemId,
            kAuricDrifterItemId,
            kAuricHiveItemId,
            kAuricHarvesterItemId,
            
            kBattleGorgeShoulderPatchItemId,
            kTurboDrifterCardItemId,
            kBattleGorgeCardItemId,
        },
        [5]={
            kBlackArmorItemId,
            kForScienceCardItemId,
        }
    }
    end

    if CommunityUnlocks(_item,99) then
        return true
    end
    
    return baseGetOwnsItem(_item)
end