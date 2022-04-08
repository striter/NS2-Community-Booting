--Server Switch
RegisterVoteType( "VoteSwitchServer", { ip = "string (25)", name = "string(20)" } )
RegisterVoteType("VoteMutePlayer", { targetClient = "integer" })
RegisterVoteType("VoteForceSpectator", { targetClient = "integer" })
RegisterVoteType("VoteKillPlayer", { targetClient = "integer" })
RegisterVoteType("VoteRankPlayer", { targetClient = "integer" })
RegisterVoteType("VoteKillAll", { })
    
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

    local function SetupAdditionalVotes(voteMenu)

        AddVoteStartListener( "VoteSwitchServer", function( msg )
            return string.format(Locale.ResolveString("SWITCH_SERVER_TO"),msg.name)
        end )

        voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_MUTE_PLAYER"), GetPlayerList, function( msg )
            AttemptToStartVote("VoteMutePlayer", { targetClient = msg.targetClient })
        end)
        
        AddVoteStartListener("VoteMutePlayer", function(msg)
            return string.format(Locale.ResolveString("VOTE_MUTE_PLAYER_QUERY"), Scoreboard_GetPlayerName(msg.targetClient))
        end)

        voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_RANK_PLAYER"), GetPlayerList, function( msg )
            AttemptToStartVote("VoteRankPlayer", { targetClient = msg.targetClient })
        end)
        
        AddVoteStartListener("VoteRankPlayer", function(msg)
            return string.format(Locale.ResolveString("VOTE_RANK_PLAYER_QUERY"), Scoreboard_GetPlayerName(msg.targetClient))
        end)

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

    SetVoteSuccessfulCallback("VoteRankPlayer", 1, function( msg )
        local client = Server.GetClientById(msg.targetClient)
        if not client then return end
        Shared.ConsoleCommand(string.format("sh_rankdelta %s %s", client:GetUserId(), 100))
    end)

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
end