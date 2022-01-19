

function OnModPanelsCommand()
    if Server then
        -- skip if there are panels
        for _, entity in ientitylist(Shared.GetEntitiesWithClassname("ModPanel")) do
            return
        end
        --Log("Creating panels: %s", #kModPanels)
        
        for index, material in ipairs(kModPanels) do
            local origin = nil
            
            -- Randomly choose unobstructed spawn points to respawn the player
            local spawnPoint = nil
            local spawnPoints = Server.readyRoomSpawnList
            local numSpawnPoints = table.maxn(spawnPoints)
            
            if numSpawnPoints > 0 then
            
                local spawnPoint = spawnPoints[index % numSpawnPoints]
                if spawnPoint ~= nil then
                
                    origin = spawnPoint:GetOrigin()
                    angles = spawnPoint:GetAngles()
                    
                    local panel = CreateEntity(ModPanel.kMapName, origin, 0)
                    panel:SetMaterial(index)
                    --Log("Created panel at %s", origin)
                else
                    Log("Can't spawn a mod panel")
                end
                
            else
                Log("Couldn't find a spawn point for a mod panel")
            end
        end
    end
end
