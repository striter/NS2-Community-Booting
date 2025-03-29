--[[
	Server switch client.
]]

local Plugin = ...
local VoteMenu = Shine.VoteMenu

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
	local address = Client.GetConnectedServerAddress()
	if address == Data.Address then return end
	table.insert(self.QueryServers,{
		ID = Data.ID,
		Address = Data.Address,
		Name = Data.Name,
		Amount = Data.Amount,
	})
end


VoteMenu:AddPage( "ServerSwitch", function( self )
	local Servers = Plugin.QueryServers
	if not Plugin.Enabled or not Servers then
		self:SetPage( "Main" )
		return
	end

	self:AddBottomButton( Plugin:GetPhrase( "BACK" ), function()
		self:SetPage( "Main" )
	end )

	local addedServers = {}
	for ID, Server in pairs( Servers ) do
		if not table.contains(addedServers,Server.Address) then
			self:AddSideButton( Server.Name, function()
				Shared.ConsoleCommand( "connect ".. Server.Address )
			end ):SetText(Server.Name)
			table.insert(addedServers,Server.Address)
		end
	end
end )

VoteMenu:EditPage( "Main", function( self )
	if Plugin.Enabled and next( Plugin.QueryServers ) then
		self:AddBottomButton( Plugin:GetPhrase( "VOTEMENU_BUTTON" ), function()
			self:SetPage( "ServerSwitch" )
		end )
	end
end )