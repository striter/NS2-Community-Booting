--[[
	Server switch client.
]]

local Plugin = ...

local Shine = Shine

local TableEmpty = table.Empty
local Vector = Vector

function Plugin:Initialise()
	self.Enabled = true
	self.QueryServers = {}
	return true
end

function Plugin:Cleanup()
	self.QueryServers = nil
	return self.BaseClass.Cleanup( self )
end

function Plugin:ReceiveServerList( Data )
	if self.QueryServers[ Data.ID ] then 
		TableEmpty( self.QueryServers )
	end

	self.QueryServers[ Data.ID ] = {
		IP = Data.IP,
		Port = Data.Port,
		Name = Data.Name,
	}
end
