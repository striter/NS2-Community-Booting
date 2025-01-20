-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\Voting.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================
local kVoteExpireTime = 30
local kDefaultVoteExecuteTime = 30
local kNextVoteAllowedAfterTime = 50
-- How many seconds must pass before a client can start another vote of a certain type after a failed vote.
local kStartVoteAfterFailureLimit = 60 * 1

Shared.RegisterNetworkMessage("SendVote", { voteId = "integer", choice = "boolean" })
kVoteState = enum( { 'InProgress', 'Passed', 'Failed' } )
Shared.RegisterNetworkMessage("VoteResults", { voteId = "integer", yesVotes = "integer (0 to 255)", noVotes = "integer (0 to 255)", requiredVotes = "integer (0 to 255)", state = "enum kVoteState" })
Shared.RegisterNetworkMessage("VoteComplete", { voteId = "integer" })
kVoteCannotStartReason = enum( { 'VoteAllowedToStart', 'VoteInProgress', 'Waiting', 'Spam', 'DisabledByAdmin', 'GameInProgress', 'TooEarly', 'TooLate', 'UnsupportedGamemode', 'ThunderdomeDisallowed' } )
Shared.RegisterNetworkMessage("VoteCannotStart", { reason = "enum kVoteCannotStartReason" })

local kVoteCannotStartReasonStrings = { }
kVoteCannotStartReasonStrings[kVoteCannotStartReason.VoteInProgress] = "VOTE_IN_PROGRESS"
kVoteCannotStartReasonStrings[kVoteCannotStartReason.Waiting] = "VOTE_WAITING"
kVoteCannotStartReasonStrings[kVoteCannotStartReason.Spam] = "VOTE_SPAM"
kVoteCannotStartReasonStrings[kVoteCannotStartReason.GameInProgress] = "VOTE_GAME_IN_PROGRESS"
kVoteCannotStartReasonStrings[kVoteCannotStartReason.DisabledByAdmin] = "VOTE_DISABLED_BY_ADMIN"
kVoteCannotStartReasonStrings[kVoteCannotStartReason.TooEarly] = "VOTE_TOO_EARLY"
kVoteCannotStartReasonStrings[kVoteCannotStartReason.TooLate] = "VOTE_TOO_LATE"
kVoteCannotStartReasonStrings[kVoteCannotStartReason.UnsupportedGamemode] = "VOTE_GAMEMODE_NOT_SUPPORTED"
kVoteCannotStartReasonStrings[kVoteCannotStartReason.ThunderdomeDisallowed] = "VOTE_THUNDERDOME_DISALLOWED"

-- to prevent message from being re-hooked when interface is re-created.
local hookedVoteTypes = {}

local kThunderdomeValidVotes
-- Checks if the votename is allowed under Thunderdome. If thunderdome mode is not active, will just return true.
function GetStartVoteAllowedForThunderdome(voteName)

    if not kThunderdomeValidVotes then
        kThunderdomeValidVotes = set
        {
            "VoteThunderdomeRematch",
            "VoteKickPlayer",
            "VoteThunderdomeSkipIntermission",
            "VoteThunderdomeDrawGame",
        }
    end

    if not Shared.GetThunderdomeEnabled() then
        return true
    end

    return kThunderdomeValidVotes[voteName]

end

if Server then

    -- Allow reset between Countdown and kMaxTimeBeforeReset
    function VotingResetGameAllowed()
        local gameRules = GetGamerules()
        return gameRules:GetGameState() == kGameState.Countdown or (gameRules:GetGameStarted() and Shared.GetTime() - gameRules:GetGameStartTime() < kMaxTimeBeforeReset)
    end

    activeVoteResults = nil
    local activeVoteName, activeVoteData, activeVoteStartedAtTime
    local activeVoteId = 0
    local lastVoteStartAtTime
    local lastTimeVoteResultsSent = 0
    local voteSuccessfulCallbacks = { }

    local startVoteHistory = { }

    function GetStartVoteAllowed(voteName, client)

        if not GetStartVoteAllowedForThunderdome(voteName) then
            return kVoteCannotStartReason.ThunderdomeDisallowed
        end

        -- Check that there is no current vote.
        if activeVoteName then
            return kVoteCannotStartReason.VoteInProgress
        end

        -- Check that enough time has passed since the last vote.
        if lastVoteStartAtTime and Shared.GetTime() - lastVoteStartAtTime < kNextVoteAllowedAfterTime then
            return kVoteCannotStartReason.Waiting
        end

        -- Check that this client hasn't started a failed vote of this type recently.
        if client then
            for v = #startVoteHistory, 1, -1 do

                local vote = startVoteHistory[v]
                if voteName == vote.type and client:GetUserId() == vote.client_id then

                    if not vote.succeeded and Shared.GetTime() - vote.start_time < kStartVoteAfterFailureLimit then
                        return kVoteCannotStartReason.Spam
                    end

                end

            end
        end

        local votingSettings = Server.GetConfigSetting("voting")
        if votingSettings and votingSettings[string.lower(voteName)] == false then
            return kVoteCannotStartReason.DisabledByAdmin
        end

        if voteName == "VoteResetGame" then
            if not VotingResetGameAllowed() then
                if GetGamerules():GetGameState() < kGameState.Countdown then
                    return kVoteCannotStartReason.TooEarly
                else
                    return kVoteCannotStartReason.TooLate
                end
            end
        end

        if voteName == "VoteAddCommanderBots" then
            local gameMode = GetGamemode()
            local allowded = gameMode == "ns2" or gameMode == "NS2.0"
            if not allowded then
                return kVoteCannotStartReason.UnsupportedGamemode
            end
        end

        if voteName == "VotingForceEvenTeams" then
            if GetGamerules():GetGameStarted() then
                return kVoteCannotStartReason.GameInProgress
            end
        end

        return kVoteCannotStartReason.VoteAllowedToStart

    end

    function StartVote(voteName, client, data)
        Log("StartVote( '%s', %s, %s )", voteName, client, data)
        local voteCanStart = GetStartVoteAllowed(voteName, client)
        if voteCanStart == kVoteCannotStartReason.VoteAllowedToStart then

            local clientId = client and client:GetId() or 0

            activeVoteId = activeVoteId + 1
            activeVoteName = voteName
            activeVoteResults = {
                voters = {},
                votes = {}
            }
            activeVoteStartedAtTime = Shared.GetTime()
            lastVoteStartAtTime = activeVoteStartedAtTime
            data.voteId = activeVoteId
            local now = Shared.GetTime()
            data.expireTime = now + kVoteExpireTime
            data.client_index = clientId
            Server.SendNetworkMessage(voteName, data)

            activeVoteData = data

            table.insert(startVoteHistory, { type = voteName, client_id = clientId, start_time = now, succeeded = false })

            Print("Started Vote: " .. voteName)

        elseif client then
            Server.SendNetworkMessage(client, "VoteCannotStart", { reason = voteCanStart }, true)
        end

    end

    function HookStartVote(voteName)

        local function OnStartVoteReceived(client, message)
            StartVote(voteName, client, message)
        end
        Server.HookNetworkMessage(voteName, OnStartVoteReceived)

    end

    function RegisterVoteType(voteName, voteData)

        assert(voteData.voteId == nil, "voteId field detected while registering a vote type")
        voteData.voteId = "integer"

        assert(voteData.expireTime == nil, "expireTime field detected while registering a vote type")
        voteData.expireTime = "time"

        assert(voteData.client_index == nil, "client_index field detected while registering a vote type")
        voteData.client_index = "integer"

        Shared.RegisterNetworkMessage(voteName, voteData)
        HookStartVote(voteName)

    end

    function SetVoteSuccessfulCallback(voteName, delayTime, callback, extraCheck, requiredVotes)

        local voteSuccessfulCallback = { }
        voteSuccessfulCallback.delayTime = delayTime
        voteSuccessfulCallback.callback = callback
        voteSuccessfulCallback.extraCheck = extraCheck
        voteSuccessfulCallback.requiredVotes = requiredVotes

        voteSuccessfulCallbacks[voteName] = voteSuccessfulCallback

    end

    local function CountVotes(voteResults)

        local yes = 0
        local no = 0
        for i = 1, #voteResults.voters do

            local voter = voteResults.voters[i]
            local choice = voteResults.votes[voter]

            yes = (choice and yes + 1) or yes
            no = (not choice and no + 1) or no

        end

        return yes, no

    end

    local lastVoteSent = 0

    local function OnSendVote(client, message)

        if activeVoteName then

            local votingDone = Shared.GetTime() - activeVoteStartedAtTime >= kVoteExpireTime
            if not votingDone and message.voteId == activeVoteId then
                local clientId = client:GetUserId()
                if not table.contains(activeVoteResults.voters,clientId) then
                    table.insert(activeVoteResults.voters, clientId)
                end 

                activeVoteResults.votes[clientId] = message.choice
                lastVoteSent = Shared.GetTime()
            end

        end

    end
    Server.HookNetworkMessage("SendVote", OnSendVote)

    local function GetNumVotingPlayers()
        return Server.GetNumPlayers() - #gServerBots - Server.GetNumSpectators()
    end

    local function GetVotePassed(yesVotes, noVotes, required)
        return yesVotes >= required
    end

    local function OnUpdateVoting(dt)

        if activeVoteName then

            local voteSuccessfulCallback = voteSuccessfulCallbacks[activeVoteName]

            local yes, no = CountVotes(activeVoteResults)
            local required = (voteSuccessfulCallback.requiredVotes or math.floor(GetNumVotingPlayers() / 2) + 1)
            -------------
            if activeVoteData.voteRequired and activeVoteData.voteRequired >0 then
                required = activeVoteData.voteRequired
            end
            ------------

            local voteSuccessful = GetVotePassed(yes, no, required)
            local voteFailed = no >= required

            if Shared.GetTime() - lastTimeVoteResultsSent > 1 then

                local voteState = kVoteState.InProgress

                local votingDone = Shared.GetTime() - activeVoteStartedAtTime >= kVoteExpireTime or voteSuccessful or voteFailed
                if votingDone then
                    voteState = voteSuccessful and kVoteState.Passed or kVoteState.Failed
                end

                Server.SendNetworkMessage("VoteResults", { voteId = activeVoteId, yesVotes = yes, noVotes = no, state = voteState, requiredVotes = required }, true)
                lastTimeVoteResultsSent = Shared.GetTime()

            end

            local delay = (voteSuccessfulCallback and (kVoteExpireTime + voteSuccessfulCallback.delayTime)) or kDefaultVoteExecuteTime

            if voteSuccessful then
                delay = lastVoteSent - activeVoteStartedAtTime + voteSuccessfulCallback.delayTime
            end

            if Shared.GetTime() - activeVoteStartedAtTime >= delay then

                Server.SendNetworkMessage("VoteComplete", { voteId = activeVoteId }, true)

                local yes, no = CountVotes(activeVoteResults)
                local voteSuccessful = GetVotePassed(yes, no, required)

                if voteSuccessful and voteSuccessfulCallback.extraCheck then
                    voteSuccessful = voteSuccessfulCallback.extraCheck(GetNumVotingPlayers(), yes, no)
                end

                startVoteHistory[#startVoteHistory].succeeded = voteSuccessful
                Print("Vote Complete: " .. activeVoteName .. ". Successful? " .. (voteSuccessful and "Yes" or "No"))

                if voteSuccessfulCallback and voteSuccessful then
                    voteSuccessfulCallback.callback(activeVoteData)
                end

                if Shared.GetThunderdomeEnabled() then
                    --McG: One-off Vote-Failed handler, required as votes don't have a on-failure callback mechanism atm
                    if activeVoteName == "VoteThunderdomeRematch" and not voteSuccessful then
                        GetThunderdomeRules():OnVotedRematchFailed()
                    end
                end

                activeVoteName = nil
                activeVoteData = nil
                activeVoteResults = nil
                activeVoteStartedAtTime = nil

            end

        end

    end

    Event.Hook("UpdateServer", OnUpdateVoting)

end

if Client then

    local currentVoteQuery
    local currentVoteId = 0
    local currentVoteExpireTime = 0
    local yesVotes = 0
    local noVotes = 0
    local requiredVotes = 0
    local lastVoteResults
    local onlyAccepted

    function RegisterVoteType(voteName, voteData)

        assert(voteData.voteId == nil, "voteId field detected while registering a vote type")
        voteData.voteId = "integer"

        assert(voteData.expireTime == nil, "expireTime field detected while registering a vote type")
        voteData.expireTime = "time"

        assert(voteData.client_index == nil, "client_index field detected while registering a vote type")
        voteData.client_index = "integer"

        Shared.RegisterNetworkMessage(voteName, voteData)

    end

    local voteSetupCallbacks = { }
    function AddVoteSetupCallback(callback)
        table.insert(voteSetupCallbacks, callback)
    end

    function AttemptToStartVote(voteName, data)
        Client.SendNetworkMessage(voteName, data, true)
    end

    function SendVoteChoice(votedYes)

        if currentVoteId > 0 then

            -- Predict the vote locally for the UI.
            --if votedYes then
            --    yesVotes = yesVotes + 1
            --else
            --    noVotes = noVotes + 1
            --end

            Client.SendNetworkMessage("SendVote", { voteId = currentVoteId, choice = votedYes }, true)

        end

    end

    function GetCurrentVoteId()
        return currentVoteId
    end

    function GetCurrentVoteQuery()
        return currentVoteQuery
    end

    function GetCurrentVoteTimeLeft()
        return (math.max(0, currentVoteExpireTime - Shared.GetTime()))
    end

    function GetLastVoteResults()
        return lastVoteResults
    end

    function AddVoteStartListener(voteName, queryTextGenerator)

        if hookedVoteTypes[voteName] then
            return
        end

        local function OnVoteStarted(data)
            PROFILE("Voting:OnVoteStarted")
            currentVoteId = data.voteId
            currentVoteExpireTime = data.expireTime
            yesVotes = 0
            noVotes = 0
            requiredVotes = 0
            currentVoteQuery = queryTextGenerator(data)
            lastVoteResults = nil
            onlyAccepted = data.onlyAccepted
            local message = StringReformat(Locale.ResolveString("VOTE_PLAYER_STARTED_VOTE"), { name = Scoreboard_GetPlayerName(data.client_index) })
            ChatUI_AddSystemMessage(message)

        end
        Client.HookNetworkMessage(voteName, OnVoteStarted)

        hookedVoteTypes[voteName] = true

    end

    local function OnVoteResults(message)
        PROFILE("Voting:OnVoteResults")
        if currentVoteId == message.voteId then

            -- Use the higher value as we predict the vote for the local player.
            yesVotes =  message.yesVotes
            noVotes = message.noVotes
            requiredVotes = math.max(requiredVotes, message.requiredVotes)

            if message.state == kVoteState.Passed then
                lastVoteResults = true
            elseif message.state == kVoteState.Failed then
                lastVoteResults = false
            end

        end

    end
    Client.HookNetworkMessage("VoteResults", OnVoteResults)

    function GetVoteResults()
        return yesVotes, noVotes, requiredVotes
    end

    function GetOnlyAcceptedResults()
        return onlyAccepted
    end
    
    local function OnVoteComplete(message)
        PROFILE("Voting:OnVoteComplete")
        if message.voteId == currentVoteId then

            currentVoteQuery = nil
            currentVoteId = 0
            currentVoteExpireTime = 0
            yesVotes = 0
            noVotes = 0
            requiredVotes = 0
            onlyAccepted = false
            lastVoteResults = nil

        end

    end
    Client.HookNetworkMessage("VoteComplete", OnVoteComplete)

    local function OnVoteCannotStart(message)
        PROFILE("Voting:OnVoteCannotStart")
        local reasonStr = kVoteCannotStartReasonStrings[message.reason]
        ChatUI_AddSystemMessage(Locale.ResolveString(reasonStr))

    end
    Client.HookNetworkMessage("VoteCannotStart", OnVoteCannotStart)

    -- Called after the vote menu is created.
    function OnGUIStartVoteMenuCreated(name, script)

        if name ~= "GUIStartVoteMenu" then
            return
        end

        -- Setup all the vote types.
        for s = 1, #voteSetupCallbacks do
            voteSetupCallbacks[s](script)
        end

    end

end

--Load all the Votes
--Server Switch
if Client then
    if Shine then

        local function SetupServerSwitchVote(voteMenu)

                local function GetServerList()
                    local address = Client.GetConnectedServerAddress()
                    local menuItems = { }
                    local ssvEnabled, ssv = Shine:IsExtensionEnabled( "serverswitchvote" )
                    if ssvEnabled and #ssv.QueryServers > 0 then
                        for _, data in ipairs(ssv.QueryServers) do
                            if address ~= data.Address then
                                if data.Amount ~= 0 then
                                    table.insert(menuItems, { text = string.format(Locale.ResolveString("VOTE_SWITCH_SERVER_ELEMENT"),data.ID, data.Name,string.format("%s人", data.Amount)),
                                                              extraData = { ip = data.Address , name = data.Name ,onlyAccepted = true , voteRequired = data.Amount } })
                                else
                                    table.insert(menuItems, { text = string.format(Locale.ResolveString("VOTE_SWITCH_SERVER_ELEMENT"),data.ID, data.Name,"所有人"),
                                                              extraData = { ip = data.Address , name = data.Name , onlyAccepted = false } } )
                                end
                            end
                        end
                    else
                        table.insert(menuItems,{text = Locale.ResolveString("VOTE_SWITCH_SERVER_INVALID"),extraData = {invalid = true } } )
                    end
                    return menuItems
                end

                voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_SWITCH_SERVER"), GetServerList, function( msg )
                    if msg.invalid then return end
                    AttemptToStartVote("VoteSwitchServer", { ip = msg.ip , name = msg.name,onlyAccepted = msg.onlyAccepted,voteRequired = msg.voteRequired })
                end)
                
                AddVoteStartListener( "VoteSwitchServer", 	function( msg )
                    return string.format(msg.onlyAccepted and Locale.ResolveString("VOTE_SWITCH_SERVER_QUERY") or Locale.ResolveString("VOTE_SWITCH_SERVER_QUERY_ALL"),msg.name)
                end )
        end

        AddVoteSetupCallback(SetupServerSwitchVote)
    end
end

Script.Load("lua/VotingChangeMap.lua")
Script.Load("lua/VotingResetGame.lua")
Script.Load("lua/VotingAddCommanderBots.lua")
Script.Load("lua/VotingKickPlayer.lua")
--Script.Load("lua/VotingRandomizeRR.lua")
--Script.Load("lua/VotingForceEvenTeams.lua")

if Shared.GetThunderdomeEnabled() then
    Script.Load("lua/VotingThunderdomeRematch.lua")
    Script.Load("lua/VotingThunderdomeSkipIntermission.lua")
    Script.Load("lua/VotingThunderdomeDrawGame.lua")
end

---------------------------Post
RegisterVoteType("VoteMutePlayer", { targetClient = "integer" })
RegisterVoteType("VoteFuckPolitican", { targetClient = "integer" })
RegisterVoteType("VoteForceSpectator", { targetClient = "integer" })
RegisterVoteType("VoteKillPlayer", { targetClient = "integer" })
RegisterVoteType("VoteRankPlayer", { targetClient = "integer" })
RegisterVoteType("VoteKillAll", { })
RegisterVoteType("VoteBotsCount", {count = "integer"})
RegisterVoteType("VoteBotsDoom", {team = "integer"})
RegisterVoteType("VoteRandomScale", {})
RegisterVoteType("VoteSwitchServer", { ip = "string (25)" , name = "string (32)" , onlyAccepted = "boolean" , voteRequired = "integer"} )

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
        
        if Shine then

            voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_MUTE_PLAYER"), GetPlayerList, function( msg )
                AttemptToStartVote("VoteMutePlayer", { targetClient = msg.targetClient })
            end)

            AddVoteStartListener("VoteMutePlayer", function(msg)
                return string.format(Locale.ResolveString("VOTE_MUTE_PLAYER_QUERY"), Scoreboard_GetPlayerName(msg.targetClient))
            end)

            voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_FUCK_POLITICAN"), GetPlayerList, function( msg )
                AttemptToStartVote("VoteFuckPolitican", { targetClient = msg.targetClient })
            end)

            AddVoteStartListener("VoteFuckPolitican", function(msg)
                return string.format(Locale.ResolveString("VOTE_FUCK_POLITICAN_QUERY"), Scoreboard_GetPlayerName(msg.targetClient))
            end)
            
        end


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
        --Shared.Message(msg.name .. " " .. msg.ip .. " " .. tostring(msg.onlyAccepted) .. " " .. tostring(#activeVoteResults))
        if msg.onlyAccepted then
            local acceptClients = {}
            local message = {ip = msg.ip}
            
            for i = 1, #activeVoteResults.voters do
                local voterId = activeVoteResults.voters[i]
                local client = Shine.GetClientByNS2ID(voterId)
                if activeVoteResults.votes[voterId] and client then
                    table.insert(acceptClients,client)
                end
            end
            
            for _,client in pairs(acceptClients) do
                Server.SendNetworkMessage(client,"Redirect",message, true)
            end
        else
            Server.SendNetworkMessage("Redirect",{ ip = msg.ip }, true)
        end
    end )
    
    SetVoteSuccessfulCallback("VoteMutePlayer", 1, function( msg )
        local client = Server.GetClientById(msg.targetClient)
        if not client then return end
        Shared.ConsoleCommand(string.format("sh_gag %s", client:GetUserId()))
    end)
    
    SetVoteSuccessfulCallback("VoteFuckPolitican", 1, function( msg )
        local client = Server.GetClientById(msg.targetClient)
        if not client then return end
        Shared.ConsoleCommand(string.format("sh_gagid %s", client:GetUserId()))
        Shared.ConsoleCommand(string.format("sh_renameid %s %s", client:GetUserId(), "Transgender"))
    end)

    SetVoteSuccessfulCallback("VoteForceSpectator", 1, function( msg )
        local client = Server.GetClientById(msg.targetClient)
        if not client then return end
        local Player = client:GetControllingPlayer()
        if not Player then return end
        GetGamerules():JoinTeam( Player, kSpectatorIndex, true )
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