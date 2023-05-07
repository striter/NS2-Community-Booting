
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
    --Initialize
    if CommunityUnlocks(_item,99) then
        return true
    end
    
    return baseGetOwnsItem(_item)
end


function GetHasVariant(data, var, client)
    assert(data)
    assert(var)

    if not data[var] then
        return false
    end

    if Server then
        Shared.Message("?")
    end
    if data[var].itemId then
        if Server then
            Shared.Message("??")
        end
        return GetOwnsItem( data[var].itemId )
    elseif data[var].itemIds then
        return GetOwnsItem( data[var].itemIds )
    else
        return GetHasDLC(data[var].productId, client)
    end

    if Server then
        Shared.Message("???")
    end
    return false
end