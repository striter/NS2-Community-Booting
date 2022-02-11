function CleanNickName(name)
    -- local result = string.UTF8SanitizeForNS2(TrimName(name))
    return name
end

function UpdatePlayerNicknameFromOptions()
    
    local name = ""
    local nickname
    local overrideEnabled = Client.GetOptionBoolean(kNicknameOverrideKey, false)
    
    if overrideEnabled then
        name = Client.GetOptionString(kNicknameOptionsKey, "")
        nickname = name
    else
        name = Client.GetUserName()
    end
    
    name = CleanNickName(name)
    if nickName then
        nickname = CleanNickName(nickName)
    end
    
    -- if name == "" or not string.IsValidNickname(name) then
    --     name = kDefaultPlayerName
    -- end
    
    if Client and Client.GetIsConnected() and (Client.lastSentName ~= name) then
        Client.lastSentName = name
        -- Shared.Message("Set" .. name)
        Client.SendNetworkMessage("SetName", {name = string.UTF8Sub(name,1,20)}, true)
    end
    
    local localPlayerData = GetLocalPlayerProfileData()
    if localPlayerData then
        localPlayerData:SetPlayerName(name)
    end
    
    return name
    
end