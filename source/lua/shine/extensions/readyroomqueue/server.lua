local Notify = Shared.Message

local TableConcat = table.concat

local Plugin = ...
Plugin.PrintName = "Ready Room Queue"

Plugin.HasConfig = true

Plugin.ConfigName = "ReadRoomQueue.json"
Plugin.DefaultConfig = {
    RestoreQueueAfterMapchange = true,
    QueuePositionMaxReservationTime = 300, -- how long we reserve a queue position after a map change.
    QueueHistoryLifeTime = 300, -- max amount of time the queue history is preserved after a mapchange. Increase/decrease this value based on server loading time
    VIPPlayers = {
        Enabled = false,
        PermissionString = "sh_vip"
    }
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

Plugin.QueueHistoryFile = "config://shine/temp/rr_queue_history.json"
Plugin.QueueWaitTimeHistoryFile = "config://shine/temp/rr_queue_wait_time_history.json"

function Plugin:Initialise()
    self.Enabled = true

    -- Using Map instead of Set because Set doesn't provide any easy way to get a value's current position
    -- and Queue doesn't allow to insert at a specific position without iterating over the all elements
    self.PlayerQueue = Shine.Map()
    self.ReservedQueue = Shine.Map() -- for players with reserved slots

    self:LoadQueueHistory()

    self:LoadWaitTimeHistory()

    self:CreateCommands()

    return true
end

function Plugin:LoadWaitTimeHistory()
    local WaitTimeHistory = Shine.LoadJSONFile( self.QueueWaitTimeHistoryFile ) or {
        AVGWaitTime = 0,
        SampleSize = 0
    }

    self.AVGWaitTime = WaitTimeHistory.AVGWaitTime
    self.AVGWaitTimeSampleSize = WaitTimeHistory.SampleSize
end

function Plugin:UpdateWaitTimeHistory( WaitTime )
    local SumWaitTimes = self.AVGWaitTime * self.AVGWaitTimeSampleSize + WaitTime
    self.AVGWaitTimeSampleSize = self.AVGWaitTimeSampleSize + 1
    self.AVGWaitTime = math.round( SumWaitTimes / self.AVGWaitTimeSampleSize )

    local WaitTimeHistory = {
        AVGWaitTime = self.AVGWaitTime,
        SampleSize = self.AVGWaitTimeSampleSize
    }
    Shine.SaveJSONFile( WaitTimeHistory, self.QueueWaitTimeHistoryFile )
end

function Plugin:LoadQueueHistory()
    self.HistoricPlayers = Shine.Set()

    if not self.Config.RestoreQueueAfterMapchange then return end

    local QueueHistory = Shine.LoadJSONFile( self.QueueHistoryFile ) or {}

    local now = Shared.GetSystemTime()

    local TimeStamp = QueueHistory.TimeStamp
    if not TimeStamp or tonumber( TimeStamp ) + self.Config.QueueHistoryLifeTime < now then
        return
    end

    if QueueHistory.PlayerQueue then
        for i = 1, #QueueHistory.PlayerQueue do
            local SteamId = QueueHistory.PlayerQueue[i]
            self:InsertIntoQueue(self.PlayerQueue, SteamId, i )
            self.HistoricPlayers:Add( SteamId )
        end
    end

    if QueueHistory.ReservedQueue then
        for i = 1, #QueueHistory.ReservedQueue do
            local SteamId = QueueHistory.ReservedQueue[i]
            self:InsertIntoQueue(self.ReservedQueue, SteamId, i )
        end
    end

    local function ClearHistory()
        self.HistoricPlayers = Shine.Set()

        self:UpdateQueuePositions( self.PlayerQueue )
        self:UpdateQueuePositions( self.ReservedQueue, "PIORITY_QUEUE_CHANGED" )
    end

    self:SimpleTimer( self.Config.QueuePositionMaxReservationTime, ClearHistory )
end

function Plugin:SaveQueueHistory()
    local QueueHistory = {
        PlayerQueue = self.PlayerQueue:GetKeys(),
        ReservedQueue = self.ReservedQueue:GetKeys(),
        TimeStamp = Shared.GetSystemTime()
    }
    Shine.SaveJSONFile( QueueHistory, self.QueueHistoryFile )
end

function Plugin:OnFirstThink()
    Shine.Hook.SetupClassHook( "Gamerules", "GetCanJoinPlayingTeam", "OnGetCanJoinPlayingTeam", function(OldFunc, gamerules, player, skipHook )
        local result = OldFunc( gamerules, player )

        if not skipHook then
            Shine.Hook.Call( "OnGetCanJoinPlayingTeam", gamerules, player, result )
        end

        return result
    end )
end

function Plugin:ClientConnect( Client )

    if not Client or Client:GetIsVirtual() then return end

    local gamerules = GetGamerules()
    if not gamerules then return end
    if Client:GetIsSpectator() then return end

    local player = Client:GetControllingPlayer()
    if gamerules:GetCanJoinPlayingTeam(player) then return end
    gamerules:JoinTeam( player, kSpectatorIndex, true )
end

function Plugin:ClientDisconnect( Client )
    if not Client or Client:GetIsVirtual() then return end

    if Client:GetIsSpectator() then
        self:Dequeue( Client )
    else
        Client:SetIsSpectator(true)
        self:Pop()
    end

    Client:SetIsSpectator(false) -- make sure we don't end up with clients not getting cleared from the spectator list
end

function Plugin:OnGetCanJoinPlayingTeam( _, Player, Allowed )
    if not Allowed and Player:GetIsSpectator() then
        local Client = Player:GetClient()
        if Client then
            self:Enqueue(Client)
        end
    end
end

function Plugin:GetQueuePosition( Client )
    local SteamId = Client:GetUserId()

    return self.PlayerQueue:Get(SteamId)
end

function Plugin:PostJoinTeam( _, Player, _, NewTeam )
    if NewTeam ~= kSpectatorIndex then

        -- Make sure clients don't stay in the queue if they get moved to a playing slot
        local Client = Player:GetClient()
        self:Dequeue(Client)

        return
    end

    local SteamId = Player:GetSteamId()

    local position = 0
    if SteamId and self.HistoricPlayers:Contains( SteamId ) then
        self.HistoricPlayers:Remove( SteamId )
        position = self.PlayerQueue:Get( SteamId ) or 0
    end

    self:Pop()

    if not self:GetCanJoinPlayingTeam( Player ) then
        local Client = Player:GetClient()
        if Client then
            if position == 0 then
                self:SendTranslatedNotify(Client, "QUEUE_INFORM", {
                    Position = self.PlayerQueue:GetCount()
                })
            else
                self:SendTranslatedNotify(Client, "QUEUE_WELCOME_BACK", {
                    Position = position
                })
            end
        end
    end
end

-- Allows to insert new key to a specific position in the Maps Keys array
-- Also position is the value to add for given key in the map
function Plugin:InsertIntoQueue( Queue, Key, Position, UpdateMessageName )
    if Key == nil then return end -- ensure Key is not nil

    local NumMembers = Queue.NumMembers + 1
    if Position > NumMembers then return end -- ensure we are not inserting to an invalid position

    Position = Position or NumMembers -- set position to end of map if not specified otherwise

    -- Key allready exists in map, abort mission!
    if Queue.MemberLookup[ Key ] ~= nil then
        Queue.MemberLookup[ Key ] = Position
        return
    end

    Queue.NumMembers = NumMembers
    table.insert(Queue.Keys, Position, Key)
    Queue.MemberLookup[ Key ] = Position

    if UpdateMessageName and Position < NumMembers then
        self:UpdateQueuePositions(Queue, UpdateMessageName)
    end
end

function Plugin:GetQueueInsertPosition( Queue, Client )
    local VIPPlayersEnabled = self.Config.VIPPlayers.Enabled
    local PermissionString = self.Config.VIPPlayers.PermissionString
    if VIPPlayersEnabled and Shine:HasAccess(Client, PermissionString) then

        local position = 1
        for SteamID in Queue:Iterate() do
            local c = Shine.GetClientByNS2ID(SteamID)
            if c then
                if Shine:HasAccess(c, PermissionString) then
                    position = position + 1
                else
                    break
                end
            end
        end

        return position
    end

    return Queue:GetCount() + 1
end

function Plugin:SendQueuePosition( Client, Position )
    self:SendTranslatedNotify(Client, "QUEUE_POSITION", {
        Position = Position
    })

    if self.AVGWaitTimeSampleSize > 0 then
        self:SendNetworkMessage( Client, "WaitTime", { Time = self.AVGWaitTime }, true )
    end
end

function Plugin:Enqueue( Client )
    if not Client:GetIsSpectator() then
        self:NotifyTranslatedError( Client, "ENQUEUE_ERROR_PLAYER" )
    end

    local SteamID = Client:GetUserId()

    if not SteamID or SteamID < 1 then return end

    local position = self.PlayerQueue:Get( SteamID )
    if position then
        self:SendQueuePosition( Client, position )
        return
    end

    position = self:GetQueueInsertPosition(self.PlayerQueue, Client)
    self:InsertIntoQueue(self.PlayerQueue, SteamID, position, "QUEUE_CHANGED_VIP")
    self:SendTranslatedNotify( Client, "QUEUE_ADDED", {
        Position = position
    })

    if self.AVGWaitTimeSampleSize > 0 then
        self:SendNetworkMessage( Client, "WaitTime", { Time = self.AVGWaitTime }, true)
    end

    if GetHasReservedSlotAccess( SteamID ) then
        position = self:GetQueueInsertPosition(self.ReservedQueue, Client)
        self:InsertIntoQueue(self.ReservedQueue, SteamID, position, "PIORITY_QUEUE_CHANGED_VIP")
        self:SendTranslatedNotify(Client, "PIORITY_QUEUE_ADDED", {
            Position = position
        })
    end

    -- Save join time for later
    Client.RRQueueJoinTime = Shared.GetTime()
end

function Plugin:UpdateQueuePositions( Queue, Message )
    Message = Message or "QUEUE_CHANGED"

    local i = 1
    for SteamID, Position in Queue:Iterate() do
        local Client = Shine.GetClientByNS2ID( SteamID )
        if Client then

            if Position ~= i then
                Queue:Add( SteamID, i )
                self:SendTranslatedNotify( Client, Message, {
                    Position = i
                })
            end
            i = i + 1

        -- Historic player entry
        elseif self.HistoricPlayers:Contains( SteamID ) then

            Queue:Add( SteamID, i )
            i = i + 1

        -- player disconnected but somehow wasn't removed
        else
            Queue:Remove( SteamID )
        end
    end
end

function Plugin:Dequeue( Client )
    if not Client then return end

    local SteamId = Client:GetUserId()

    local position = self.PlayerQueue:Remove( SteamId )
    if not position then return false end

    self:UpdateQueuePositions( self.PlayerQueue )

    position = self.ReservedQueue:Remove( SteamId )
    if position then
        self:UpdateQueuePositions( self.ReservedQueue, "PIORITY_QUEUE_CHANGED" )
    end

    return true
end

function Plugin:GetFirstClient( Queue )
    for SteamId in Queue:Iterate() do
        if not self.HistoricPlayers:Contains( SteamId ) then
            local QueuedClient = Shine.GetClientByNS2ID( SteamId )
            if QueuedClient then
                return QueuedClient, SteamId
            end
        end
    end
end

function Plugin:PopReserved()
    local Gamerules = GetGamerules()
    if not Gamerules then -- abort mission
        return
    end

    local First, SteamId = self:GetFirstClient( self.ReservedQueue )
    if not First then return end --empty queue

    local Player = First:GetControllingPlayer()
    if not Player or Gamerules:GetCanJoinPlayingTeam( Player ) then
        return false
    end

    if not Gamerules:JoinTeam( Player, kTeamReadyRoom ) then
        return false
    end

    Player:SetCameraDistance(0)

    self.ReservedQueue:Remove( SteamId )
    self:NotifyTranslated( First, "QUEUE_LEAVE" )

    self:UpdateQueuePositions( self.ReservedQueue, "PIORITY_QUEUE_CHANGED" )

    return true
end

-- Confirm we don't end up with too many player due to bugged spectator counter
function Plugin:GetCanJoinPlayingTeam( Player )
    if not Player:GetIsSpectator() then return true end

    local Gamerules = GetGamerules()
    if not Gamerules then
        return false
    end

    local numPlayer = 0
    local GameIDs = Shine.GameIDs
    for Client in GameIDs:Iterate() do
        if not Client:GetIsSpectator() then
            numPlayer = numPlayer + 1
        end
    end

    if numPlayer >= Server.GetMaxPlayers() then return false end

    return Gamerules:GetCanJoinPlayingTeam( Player, true )
end

function Plugin:Pop()
    local Gamerules = GetGamerules()
    if not Gamerules then -- abort mission
        return
    end

    local First, SteamId = self:GetFirstClient( self.PlayerQueue )
    if not First then return end --empty queue

    local Player = First:GetControllingPlayer()

    if not self:GetCanJoinPlayingTeam( Player ) then
        return self:PopReserved()
    end

    if not Gamerules:JoinTeam( Player, kTeamReadyRoom ) then
        return false
    end

    Player:SetCameraDistance(0)

    self.PlayerQueue:Remove( SteamId )
    self:SendNetworkMessage( First, "QueueLeft", {}, true )

    if First.RRQueueJoinTime then
        self:UpdateWaitTimeHistory( Shared.GetTime() - First.RRQueueJoinTime )
    end

    self:UpdateQueuePositions( self.PlayerQueue )

    return true
end

function Plugin:PrintQueue( Client )
    local Message = {}

    if self.PlayerQueue:GetCount() == 0 then
        Message[1] = "Player Slot Queue is currently empty."
    else

        Message[#Message + 1] = "Player Slot Queue:"
        for SteamId, Position in self.PlayerQueue:Iterate() do
            local ClientName = "Unknown"
            local QueuedClient = Shine.GetClientByNS2ID( SteamId )
            if QueuedClient then
                ClientName = Shine.GetClientName( QueuedClient )
            end

            Message[#Message + 1] = string.format("%d - %s[%d]", Position, ClientName, SteamId)
        end

        if self.ReservedQueue:GetCount() > 0 then
            Message[#Message + 1] = "\n Reserved Slot Queue:"

            for SteamId, Position in self.ReservedQueue:Iterate() do
                local ClientName = "Unknown"
                local QueuedClient = Shine.GetClientByNS2ID( SteamId )
                if QueuedClient then
                    ClientName = Shine.GetClientName( QueuedClient )
                end

                Message[#Message + 1] = string.format("%d - %s[%d]", Position, ClientName, SteamId)
            end
        end

    end

    if not Client then
        Notify( TableConcat( Message, "\n" ) )
    else
        for i = 1, #Message do
            ServerAdminPrint( Client, Message[ i ] )
        end
    end
end

function Plugin:CreateCommands()
    local function EnqueuePlayer(Client )
        if not Client then return end

        self:Enqueue(Client)
    end
    local Enqueue = self:BindCommand( "sh_rr_enqueue", "rr_enqueue", EnqueuePlayer, true )
    Enqueue:Help("Enter the queue for a player slot")

    local function DequeuePlayer( Client )

        if not self:Dequeue(Client) then
            self:NotifyTranslatedError( Client, "DEQUEUE_FAILED")
        end


        self:NotifyTranslated( Client, "DEQUEUE_SUCCESS")
    end

    local Dequeue = self:BindCommand( "sh_rr_dequeue", "rr_dequeue", DequeuePlayer, true )
    Dequeue:Help("Leave the player slot queue")

    local function DisplayPosition( Client )
        local position = self:GetQueuePosition( Client )
        if not position then
            self:NotifyTranslatedError( Client, "QUEUE_POSITION_UNKNOWN")
            return
        end

        self:SendQueuePosition( Client, position )
    end
    local Position = self:BindCommand( "sh_rr_position", "rr_position", DisplayPosition, true )
    Position:Help("Returns your current position in the player slot queue")

    local function PrintQueue( Client )
        self:PrintQueue( Client )
    end
    self:BindCommand( "sh_rr_printqueue", nil , PrintQueue, true )

    local function ListClients( Client )
        local Message = {}

        local Clients, Count = Shine.GetAllClients()
        for i = 1, Count do
            local client = Clients[ i ]
            Message[#Message + 1] = string.format("%s - %s", Shine.GetClientInfo(client), client:GetIsSpectator())
        end

        if not Client then
            Notify( TableConcat( Message, "\n" ) )
        else
            for i = 1, #Message do
                ServerAdminPrint( Client, Message[ i ] )
            end
        end
    end
    self:BindCommand( "sh_rr_listclients", nil , ListClients, true )
end

function Plugin:MapChange()
    if not self.Config.RestoreQueueAfterMapchange then return end
    
    self:SaveQueueHistory()
end

function Plugin:Cleanup()
    self.BaseClass.Cleanup( self )

    self.connectionChecked = nil
    self.Enabled = false
end