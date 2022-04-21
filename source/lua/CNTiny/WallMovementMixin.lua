local baseOnAdjustModelCoords = WallMovementMixin.OnAdjustModelCoords
function WallMovementMixin:OnAdjustModelCoords(modelCoords)
    local coords = Player.OnAdjustModelCoords(self,modelCoords)
    return baseOnAdjustModelCoords(self,modelCoords)
end
