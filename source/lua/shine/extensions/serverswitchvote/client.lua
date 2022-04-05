--[[
	Server switch client.
]]

local Plugin = ...

local Shine = Shine
local SGUI = Shine.GUI
local VoteMenu = Shine.VoteMenu

local Ceil = math.ceil
local StringExplode = string.Explode
local StringFormat = string.format
local TableCount = table.Count
local TableEmpty = table.Empty
local Vector = Vector

local ZeroVec = Vector( 0, 0, 0 )

function Plugin:Initialise()
	self.Enabled = true
	self.QueryServers = {}
	self.ValidServers = {}
	return true
end

function Plugin:Cleanup()
	self.QueryServers = nil
	self.ValidServers = nil
	return self.BaseClass.Cleanup( self )
end

VoteMenu:AddPage( "ServerSwitchVote", function( self )
	local Servers = Plugin.QueryServers
	if not Plugin.Enabled or not Servers then
		self:SetPage( "Main" )
		return
	end

	self:AddBottomButton( Plugin:GetPhrase( "BACK" ), function()
		self:SetPage( "Main" )
	end )

	local function ClickServer(self,ID )
		if self.GetCanSendVote() and self.ValidServers[ID] then
			Shared.ConsoleCommand( "sh_switchservervote "..ID )
			self:SetPage( "Main" )
			return true
		end

		return false
	end

	for ID, Server in pairs( Servers ) do
		local Button = self:AddSideButton(string.format("%s(未响应)",Server.Name), function()
			return ClickServer(self,ID )
		end )

		Shine.QueryServer( Server.IP, tonumber( Server.Port ) + 1, function( Data )
			if not Data then return end
			if not SGUI.IsValid( Button ) then return end
			if Button:GetText() ~= Server.Name then return end

			local Connected = Data.numberOfPlayers
			local Max = Data.maxPlayers
			local Tags = Data.serverTags

			local TagTable = StringExplode( Tags, "|", true )

			for i = 1, #TagTable do
				local Tag = TagTable[ i ]

				local Match = Tag:match( "R_S(%d+)" )

				if Match then
					Max = Max - tonumber( Match )
					break
				end
			end

			self.ValidServers[ID] = true
			Button:SetText( StringFormat( "%s(%i/%i)", Server.Name, Connected, Max ) )
		end )
	end
end )

VoteMenu:EditPage( "Main", function( self )
	if Plugin.Enabled and next( Plugin.QueryServers ) then
		self:AddSideButton( Plugin:GetPhrase( "VOTEMENU_BUTTON" ), function()
			self:SetPage( "ServerSwitchVote" )
		end )
	end
end )

function Plugin:ReceiveServerList( Data )
	if self.QueryServers[ Data.ID ] then -- We're refreshing the data.
		TableEmpty( self.QueryServers )
	end

	self.QueryServers[ Data.ID ] = {
		IP = Data.IP,
		Port = Data.Port,
		Name = Data.Name
	}
end

