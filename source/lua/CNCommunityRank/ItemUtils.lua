
local baseGetOwnsItem = GetOwnsItem
local function CommunityUnlocks(_item,_tier)
    for index,unlocks in pairs(gCommunityUnlocks) do
        if _tier >= index then
            for k,v in pairs(unlocks) do
                if v == _item then
                    return true
                end
            end
        end
    end
end

function CommunityGetOwnsItem(_item,_tier)
    
    if CommunityUnlocks(_item,_tier) then
        return true
    end

    return baseGetOwnsItem(_item)
end

function GetOwnsItem( _item )
    if CommunityUnlocks(_item,99) then
        return true
    end
    
    return baseGetOwnsItem(_item)
end