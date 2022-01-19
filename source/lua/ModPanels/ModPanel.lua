Script.Load("lua/DynamicMeshUtility.lua")

if ModPanel then return end

class 'ModPanel' (Entity)
ModPanel.kMapName = "modpanel"
ModPanel.kModelName = PrecacheAsset("models/props/veil/veil_holosign_01_nanogrid.model")
ModPanel.height = 1.2
ModPanel.width = 0.66

-- ultra hacky
ModPanel.renderTime = 5.0

local networkVars = {
    modPanelId = "integer"
}
--AddMixinNetworkVars(BaseModelMixin, networkVars)

function ModPanel:OnCreate()
    Entity.OnCreate(self)
    --InitMixin(self, BaseModelMixin)
    --InitMixin(self, UsableMixin)
    self.panel = nil
    self.modPanelId = nil
    self.prevModPanelId = nil
    self.url = nil
    if Client then
        self.lastUpdate = Shared.GetTime()
        self:SetUpdates(true)
    end
end


function ModPanel:OnDestroy()

    if self.panel and Client then
    
        DynamicMesh_Destroy(self.panel)
        self.panel = nil
        
    end
    self.modPanelId = nil
    self.prevModPanelId = nil
end
function ModPanel:SetMaterial(modPanelId)
    self.modPanelId = modPanelId
    self.url = (url or nil)
    --Log("Setting panel material to "..self.modPanelId)
end

function ModPanel:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = self:InternalGetCanBeUsed()
end

function ModPanel:InternalGetCanBeUsed()
    return (self.url ~= nil)
end

function ModPanel:GetUsablePoints()

    return nil
    
end

if Client then
    
    local webView = nil
    function ModPanel:OnUse()
        GetMainMenu():Open()
        if webView then
            GetGUIManager():DestroyGUIScript(webView)
        end
        
        webView = GetGUIManager():CreateGUIScript("GUIWebView")
        Log("Loading URL: %s", self.url)
        webView:LoadUrl(self.url, Client.GetScreenWidth() * 0.5, Client.GetScreenHeight() * 0.7)
        
        webView:GetBackground():SetAnchor(GUIItem.Middle, GUIItem.Center)
        webView:GetBackground():SetPosition(-webView:GetBackground():GetSize() / 2)
        webView:GetBackground():SetLayer(kGUILayerMainMenuWeb)
        webView:GetBackground():SetIsVisible(true)
        Client.SetMouseVisible(true)
    end
    
    
    local kTwoSidedSquareTexCoords = { 1,1, 0,1, 0,0, 1,0, 0,1, 1,1, 1,0, 0,0}
    local kTwoSidedSquareIndices = { 3,1,0, 1,3,2, 6,4,5, 4,6,7 }
    local function DynamicMesh_SetTwoSidedFixedLine(mesh, coords, width, length, startColor, endColor)

        if not startColor then
            startColor = Color(1,1,1,1)
        end

        if not endColor then
            endColor = Color(1,1,1,1)
        end    

        local startPoint = Vector(0,0,0)
        local endPoint = Vector(0,0,length)
        local sideVector = Vector(width, 0, 0)
        
        local meshVertices = {
        
            endPoint.x + sideVector.x, endPoint.y, endPoint.z + sideVector.z,
            endPoint.x - sideVector.x, endPoint.y, endPoint.z - sideVector.z,
            startPoint.x - sideVector.x, startPoint.y, startPoint.z - sideVector.z,
            startPoint.x + sideVector.x, startPoint.y, startPoint.z + sideVector.z,
            
            endPoint.x + sideVector.x, endPoint.y, endPoint.z + sideVector.z,
            endPoint.x - sideVector.x, endPoint.y, endPoint.z - sideVector.z,
            startPoint.x - sideVector.x, startPoint.y, startPoint.z - sideVector.z,
            startPoint.x + sideVector.x, startPoint.y, startPoint.z + sideVector.z,
        }
        
        local colors = {
            endColor.r, endColor.g, endColor.b, endColor.a,
            endColor.r, endColor.g, endColor.b, endColor.a,    
            startColor.r, startColor.g, startColor.b, startColor.a,
            startColor.r, startColor.g, startColor.b, startColor.a,

            endColor.r, endColor.g, endColor.b, endColor.a,
            endColor.r, endColor.g, endColor.b, endColor.a,    
            startColor.r, startColor.g, startColor.b, startColor.a,
            startColor.r, startColor.g, startColor.b, startColor.a,
        }

        mesh:SetIndices(kTwoSidedSquareIndices, #kTwoSidedSquareIndices)
        mesh:SetTexCoords(kTwoSidedSquareTexCoords, #kTwoSidedSquareTexCoords)
        mesh:SetVertices(meshVertices, #meshVertices)
        mesh:SetColors(colors, #colors)
        mesh:SetCoords(coords)
        
    end
    function ModPanel:OnUpdateRender()
    
        -- this is ultra, ultra hacky
        if self.panel and self.lastUpdate + ModPanel.renderTime < Shared.GetTime()  then
            self.lastUpdate = Shared.GetTime()
            DynamicMesh_Destroy(self.panel)
            self.panel = nil
            
        end
        if self.modPanelId ~= self.prevModPanelId or not self.panel then
            self.prevModPanelId = self.modPanelId
            local newMaterial = kModPanels[self.modPanelId].material
            --Log("Setting panel material to "..newMaterial)
            self.panel = DynamicMesh_Create()
            self.panel:SetMaterial(newMaterial)
            local coords = Coords.GetIdentity()
            coords.origin = self:GetOrigin() + Vector(0,ModPanel.height * 1.5,0)
            coords.zAxis = Vector(0,-1,0)
            coords.xAxis = coords.zAxis:GetPerpendicular()
            coords.xAxis = Vector(coords.xAxis.z, coords.xAxis.y, coords.xAxis.x)
            coords.yAxis = coords.zAxis:CrossProduct(coords.xAxis)
            
            DynamicMesh_SetTwoSidedFixedLine(self.panel, coords, ModPanel.width, ModPanel.height)
            
            self.url = kModPanels[self.modPanelId].url
        end
        if self.modPanelId and self.panel then
            local coords = self.panel:GetCoords()
            local player = Client.GetLocalPlayer()
            if player then
                local dir = player:GetEyePos() - coords.origin
                local lookin = Coords.GetLookIn(coords.origin, dir, Vector(0,1,0))
                coords.xAxis = Vector(lookin.xAxis.x, 0, lookin.xAxis.z)
                coords.yAxis = coords.zAxis:CrossProduct(coords.xAxis)
            else
                local timeval = Shared.GetTime() * 0.1 + self.modPanelId
                coords.xAxis = Vector(math.sin(timeval), 0, math.cos(timeval))
                coords.yAxis = coords.zAxis:CrossProduct(coords.xAxis)
            end
            self.panel:SetCoords(coords)
        end
    end
end
function ModPanel:GetCanBeUsed(material)
    return true
end


Shared.LinkClassToMap("ModPanel", ModPanel.kMapName, networkVars, true)