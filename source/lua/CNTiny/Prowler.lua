local baseOnAdjustModelCoords = Prowler.OnAdjustModelCoords
function Prowler:OnAdjustModelCoords(modelCoords)
    local coords = Player.OnAdjustModelCoords(self,modelCoords) 
    return baseOnAdjustModelCoords(self,modelCoords)
end