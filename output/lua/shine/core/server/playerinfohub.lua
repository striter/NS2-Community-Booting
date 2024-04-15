--[[
	Shine PlayerInfoHub
]]
local Shine = Shine

local StringFormat = string.format
local JsonDecode = json.decode

Shine.PlayerInfoHub = {}
local PlayerInfoHub = Shine.PlayerInfoHub

local Queue = {}
local current = 0
local last = 0
local working = false

local function ProcessQueue()
	PROFILE("PlayerInfoHub:ProcessQueue()")
	working = true
	current = current + 1

	local node = Queue[current]

	local function OnSuccess( Response )
		node[2](Response)

		if current < last then
			ProcessQueue()
		else
			working = false
		end
	end

	local function OnTimeout()
		if node[3] then
			node[3]()
		end

		if current < last then
			ProcessQueue()
		else
			working = false
		end
	end

	Shine.TimedHTTPRequest(node[1], "GET", OnSuccess, OnTimeout, 20)
end

local function AddToHTTPQueue( Address, OnSuccess, OnTimeout)
	last = last + 1
	Queue[last] = {
		Address,
		OnSuccess,
		OnTimeout
	}

	if not working then ProcessQueue() end
end

function PlayerInfoHub:Query(url,callBack)
	AddToHTTPQueue(url,callBack)
end

Shine.Hook.Add( "ClientConnect", "QueryDB", function(Client)
	if Client:GetIsVirtual() then return end
	if PlayerInfoHub.queried then return end
	PlayerInfoHub.queried = true

	Shared.Message("[CNPIH] TryQuery")
	--Query from DB
	PlayerInfoHub:Query( Shine.Config.PlayerInfoURL, function( response,errorCode )
		if not response or #response == 0 then return end

		PlayerInfoHub.CommunityData = { }
		local receive = JsonDecode(response)
		for _,v in pairs(receive) do
			local id = tonumber(v.id)
			PlayerInfoHub.CommunityData[id] = v
		end
		Shared.Message("[CNPIH] Query Finished: Length" .. tostring(#response))
		Shine.Hook.Broadcast("OnCommunityDBReceived",PlayerInfoHub.CommunityData)
	end )
end )

function PlayerInfoHub:GetCommunityData(_steamId)

	if not PlayerInfoHub.CommunityData then
		return nil
	end
	
	local localData = PlayerInfoHub.CommunityData[_steamId]
	if not localData then
		localData = { id = _steamId }
		Shared.SendHTTPRequest(Shine.Config.PlayerInfoURL,"POST",localData)
		PlayerInfoHub.CommunityData[_steamId] = localData
	end
	return localData
end


function PlayerInfoHub:SetCommunityData(steamId,data)

	if not PlayerInfoHub.CommunityData then 
		return 
	end
	
	PlayerInfoHub.CommunityData[steamId] = data

	local output = table.copyDict(data)
	output.mtd = "PUT"
	output.id = steamId

	Shared.SendHTTPRequest(string.format("%s/%s",Shine.Config.PlayerInfoURL,steamId),"POST",output
	--,function(response)
	--	Print("response: " .. response )
	--end
	)
end