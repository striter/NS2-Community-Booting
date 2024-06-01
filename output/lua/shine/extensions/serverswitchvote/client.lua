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

function Plugin:ReceiveAddServerList( Data )
	self.QueryServers[Data.ID] = {
		ID = Data.ID,
		Address = Data.Address,
		Name = Data.Name,
		Amount = Data.Amount,
	}
end
