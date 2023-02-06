--Server Switch
RegisterVoteType("VoteMutePlayer", { targetClient = "integer" })
RegisterVoteType("VoteForceSpectator", { targetClient = "integer" })
RegisterVoteType("VoteKillPlayer", { targetClient = "integer" })
RegisterVoteType("VoteRankPlayer", { targetClient = "integer" })
RegisterVoteType("VoteKillAll", { })
RegisterVoteType("VoteBotsCount", {count = "integer"})
RegisterVoteType("VoteBotsDoom", {team = "integer"})
RegisterVoteType("VoteRandomScale", {})
RegisterVoteType("VoteSwitchServer", { ip = "string (25)" , name = "string (25)"} )

if Client then
    local function GetPlayerList()

        local playerList = Scoreboard_GetPlayerList()
        local menuItems = { }
        for p = 1, #playerList do

            local name = Scoreboard_GetPlayerData(Client.GetLocalClientIndex(), "Name")
            local steamId = Scoreboard_GetPlayerRecord(playerList[p].client_index).SteamId
            if  steamId ~= 0 and playerList[p].name ~= name then
                table.insert(menuItems, { text = playerList[p].name, extraData = { targetClient = playerList[p].client_index } })
            end

        end
        return menuItems

    end

    local kBotDoomTeam = {
        {title = "取消增幅",team = 0},
        {title = "<边境拓荒者部队>",team = 1},
        {title = "<卡拉异形>",team = 2},
    }
    local function GetBotsDoomList()
        local menuItems = { }
        for p = 1, #kBotDoomTeam do
            local data = kBotDoomTeam[p]
            table.insert(menuItems, { text = data.title, extraData = {title=data.title , team = data.team } })
        end

        return menuItems
    end

    local function SetupAdditionalVotes(voteMenu)
    if Shine then

        voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_MUTE_PLAYER"), GetPlayerList, function( msg )
            AttemptToStartVote("VoteMutePlayer", { targetClient = msg.targetClient })
        end)

        AddVoteStartListener("VoteMutePlayer", function(msg)
            return string.format(Locale.ResolveString("VOTE_MUTE_PLAYER_QUERY"), Scoreboard_GetPlayerName(msg.targetClient))
        end)

        local SSVPlugin = Shine.Plugins["serverswitchvote"]
        if SSVPlugin then
            local function GetServerList()
                
                local menuItems = { }
                if  SSVPlugin.Enabled then
                    for ID , ServerData in ipairs(SSVPlugin.QueryServers) do
                        local ip = ServerData.IP .. ":" .. ServerData.Port
                        table.insert(menuItems, { text = string.format(Locale.ResolveString("VOTE_SWITCH_SERVER_ELEMENT"),ID, ServerData.Name,8), extraData = { ip = ip , name = ServerData.Name , amount = 8 } } )
                        --table.insert(menuItems, { text = string.format("至%s的班车(14人)", ServerData.Name,14), extraData = { ip = ip , name = ServerData.Name ,amount = 14} } )
                        --table.insert(menuItems, { text = string.format("至%s的大巴车(20车)", ServerData.Name,20), extraData = { ip = ip , name = ServerData.Name , amount = 20} } )
                    end
                end
                return menuItems
            end
    
            AddVoteStartListener( "VoteSwitchServer", 	function( msg )
                Shared.Message(tostring(msg))
                return string.format(Locale.ResolveString("VOTE_SWITCH_SERVER_QUERY"),msg.name)
            end )
    
            voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_SWITCH_SERVER"), GetServerList, function( msg )
                AttemptToStartVote("VoteSwitchServer", { ip = msg.ip , name = msg.name })
            end)
        end
        
    end
--         voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_RANK_PLAYER"), GetPlayerList, function( msg )
--             AttemptToStartVote("VoteRankPlayer", { targetClient = msg.targetClient })
--         end)
        
        -- AddVoteStartListener("VoteRankPlayer", function(msg)
        --     return string.format(Locale.ResolveString("VOTE_RANK_PLAYER_QUERY"), Scoreboard_GetPlayerName(msg.targetClient))
        -- end)

        
        voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_FORCE_SPECTATE"), GetPlayerList, function( msg )
            AttemptToStartVote("VoteForceSpectator", { targetClient = msg.targetClient })
        end)

        AddVoteStartListener("VoteForceSpectator", function(msg)
            return string.format(Locale.ResolveString("VOTE_FORCE_SPECTATE_QUERY"), Scoreboard_GetPlayerName(msg.targetClient))
        end)

        
        voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_KILL_PLAYER"), GetPlayerList, function( msg )
            AttemptToStartVote("VoteKillPlayer", { targetClient = msg.targetClient })
        end)

        AddVoteStartListener("VoteKillPlayer", function(msg)
            return string.format(Locale.ResolveString("VOTE_KILL_PLAYER_QUERY"), Scoreboard_GetPlayerName(msg.targetClient))
        end)

        
        voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_KILL_ALL"),nil, function( msg )
            AttemptToStartVote("VoteKillAll", {  })
        end)

        AddVoteStartListener("VoteKillAll", function(msg)
            local random = math.random(1,5)
            return Locale.ResolveString(string.format("VOTE_KILL_ALL_QUERY%i",random))
        end)

   
        AddVoteStartListener("VoteRandomScale", function(msg)
            return Locale.ResolveString("VOTE_RANDOM_SCALE_QUERY")
        end)

        voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_RANDOM_SCALE"),nil, function( msg )
            AttemptToStartVote("VoteRandomScale", { })
        end)
        
    end
    AddVoteSetupCallback(SetupAdditionalVotes)
    
end

if Server then

    SetVoteSuccessfulCallback( "VoteSwitchServer", 1, function( msg )
        -- Shared.Message(msg.name .. " " .. msg.ip)
        Server.SendNetworkMessage("Redirect",{ ip = msg.ip }, true)
    end )
    
    SetVoteSuccessfulCallback("VoteMutePlayer", 1, function( msg )
        local client = Server.GetClientById(msg.targetClient)
        if not client then return end
        Shared.ConsoleCommand(string.format("sh_gagid %s %s", client:GetUserId(), 30 * 60))
    end)

--     SetVoteSuccessfulCallback("VoteRankPlayer", 1, function( msg )
--         local client = Server.GetClientById(msg.targetClient)
--         if not client then return end
--         Shared.ConsoleCommand(string.format("sh_rank_delta %s %s", client:GetUserId(), 100))
--     end)

    SetVoteSuccessfulCallback("VoteForceSpectator", 1, function( msg )
        local client = Server.GetClientById(msg.targetClient)
        if not client then return end
        local Player = client:GetControllingPlayer()
        if not Player then return end
        GetGamerules():JoinTeam( Player, kSpectatorIndex, true, true )
    end)

    SetVoteSuccessfulCallback("VoteKillPlayer", 1, function( msg )
        local client = Server.GetClientById(msg.targetClient)
        if not client then return end
        local Player = client:GetControllingPlayer()
        if not Player then return end
        Player:Kill( nil, nil, Player:GetOrigin() )
    end)

    SetVoteSuccessfulCallback("VoteKillAll", 1, function( msg )
        for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            player:Kill(nil,nil,player:GetOrigin())
        end
    end)

    SetVoteSuccessfulCallback("VoteKillAll", 1, function( msg )
        for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            player:Kill(nil,nil,player:GetOrigin())
        end
    end)
        
    SetVoteSuccessfulCallback("VoteRandomScale", 1, function( msg )
        if not Player.SetScale then
            return
        end
        for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            local random = 0.25 + math.random() * 1.5
            player:SetScale(random)
        end
    end)
end