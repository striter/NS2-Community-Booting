function Shine.IsActiveRound(roundData)
	if not roundData.RoundInfo then return false end
	if roundData.RoundInfo.roundLength < 300 or table.countkeys(roundData.PlayerStats) < 12 then
		return false
	end
	return true
end

local tmpDate = os.date("*t", Shared.GetSystemTime())
kCurrentYear = tmpDate.year
kCurrentMonth = tmpDate.month
kCurrentDay = tmpDate.day
kCurrentHour = tmpDate.hour + tmpDate.min / 60
kCurrentTimeStamp = os.time()
kCurrentTimeStampDay = os.time({year = kCurrentYear,month = kCurrentMonth,day = kCurrentDay})

Shine.BaseGamemode = "ns2"
Shine.kRankGameMode = { "ns2", "NS2.0", "Siege2.0"  }
Shine.kSeedingGameMode = {"Defense2.0","Combat"}

Shine.kNS2EnabledGameMode ={
	[ "ns2" ] = true,
	[ "NS2.0" ] = true,
	[ "Siege2.0" ] = true,
}
Shine.kPvPEnabledGameMode = {
	[ "ns2" ] = true,
	[ "NS2.0" ] = true,
	[ 'Siege2.0' ] = true,
	[ 'GunGame' ] = true,
	[ 'combat' ] = true,
}