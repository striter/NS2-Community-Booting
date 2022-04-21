local baseOnPostUpdateCamera = Marine.OnPostUpdateCamera
function Marine:OnPostUpdateCamera(deltaTime)
    baseOnPostUpdateCamera(self,deltaTime)
    Player.OnPostUpdateCamera(self,deltaTime)
end