function CrouchMoveMixin:GetExtentsOverride()

    local extents = self:GetMaxExtents()
    if self.crouching then
        extents.y = extents.y * (1 - self:GetExtentsCrouchShrinkAmount()) * self.scale
    end
    return extents

end
