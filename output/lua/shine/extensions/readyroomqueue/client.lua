local Plugin = ...

function Plugin:ReceiveQueueLeft()
    self:Notify( self:GetPhrase( "QUEUE_LEAVE" ) )

    Client.WindowNeedsAttention()
end

function Plugin:ReceiveWaitTime( Data )
    local message = string.format( self:GetPhrase( "QUEUE_WAITTIME" ), string.TimeToString( Data.Time ) )
    self:Notify( message )
end