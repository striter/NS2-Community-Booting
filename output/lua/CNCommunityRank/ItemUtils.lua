
local baseGetOwnsItem = GetOwnsItem
local function CommunityRankUnlocks(_itemId, _tier)
    for index,unlocks in pairs(gCommunityUnlocks) do
        if _tier >= index then
            for k,v in pairs(unlocks) do
                if v == _itemId then
                    return true
                end
            end
        end
    end
end

local function GetTDItemId(tdItem,tdData)
    local ccId = GetThunderdomeRewardCallingCardId(tdItem)
    if ccId then
        return GetCallingCardItemId(ccId) 
    end
    
   return tdData.itemId 
end

local function CommunityTDUnlocks(_itemId,data)
    for tdItem,tdData in pairs(kThunderdomeTimeRewardsData) do
        if GetTDItemId(tdItem,tdData) == _itemId then
            local comparer = math.floor( (GetIsThunderdomeRewardCommander(tdItem) and data.TimePlayedCommander or data.TimePlayed ) / 60)
            return comparer >= tdData.progressRequired
        end
    end

    for tdItem,tdData in pairs(kThunderdomeVictoryRewardsData) do
        if GetTDItemId(tdItem,tdData) == _itemId then
            local comparer = GetIsThunderdomeRewardCommander(tdItem) and data.RoundWinCommander or data.RoundWin 
            return comparer >= tdData.progressRequired
        end
    end
    return false
end

function CommunityGetOwnsItem(_itemId, data)
    if data then
        if CommunityTDUnlocks(_itemId,data) then
            return true
        end
        if CommunityRankUnlocks(_itemId,data.Tier) then
            return true
        end
    end
    

    return baseGetOwnsItem(_itemId)
end

function GetOwnsItem( _item )
    if CommunityRankUnlocks(_item,99) then
        return true
    end
    
    return baseGetOwnsItem(_item)
end