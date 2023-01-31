function Web:SetVariant(gorgeVariant)       --passing nil wtf
    --Shared.Message(tostring(gorgeVariant))
    self.variant = gorgeVariant or kGorgeVariants.normal
end