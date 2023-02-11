--local AdvertPlugin = nil
--if Shine then
--    AdvertPlugin = Shine.Plugins["communityadverts"]
--    if AdvertPlugin then
--        if AdvertPlugin.Enabled then
--            Shared.Message("[CNCA] Community Adverts Plugin Migerated")
--        else
--            AdvertPlugin = nil
--        end
--    end
--end

local function OnSetNameMessage(client, message)

    local name = message.name
    if client ~= nil and name ~= nil then

        local player = client:GetControllingPlayer()

        name = string.UTF8Sub(name,1,20)
        -- Shared.Message("Receive" .. name)
        name = TrimName(name)

        if name ~= player:GetName() then -- and string.IsValidNickname(name) then

            local prevName, hasBeenSet = player:GetName(), player:GetNameHasBeenSet()
            player:SetName(name)

            if not hasBeenSet then
                local playerName = player:GetName()
                Server.Broadcast(nil, string.format("%s connected.", playerName))
                --if AdvertPlugin then
                --    AdvertPlugin:PlayerEnter(client)
                --else
                --    Server.SendNetworkMessage("Chat", BuildChatMessage(false, "[通知] ", -1, kTeamReadyRoom, kNeutralTeamType, string.format("<%s> 加入了游戏",playerName)), true)
                --end
            elseif prevName ~= player:GetName() then
                Server.Broadcast(nil, string.format("%s is now known as %s.", prevName, player:GetName()))
            end

        end

    end

end
Server.HookNetworkMessage("SetName", OnSetNameMessage)