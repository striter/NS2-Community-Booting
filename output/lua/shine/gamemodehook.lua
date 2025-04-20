function Shine.IsActiveRound(roundData)
	if not roundData.RoundInfo then return false end
	if roundData.RoundInfo.roundLength < 300 or table.Count(roundData.PlayerStats) < 12 then
		return false
	end
	return true
end 