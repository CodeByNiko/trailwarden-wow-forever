local W=Trailwarden
local owner={};local pool={};local shownSignature;local menuRegistered
local function pins()
    -- Real LibStub is a callable table; W.Safe intentionally accepts functions only.
    if type(LibStub)=="table" then return W.Safe(LibStub.GetLibrary,LibStub,"HereBeDragons-Pins-2.0",true) end
    return W.Safe(LibStub,"HereBeDragons-Pins-2.0",true)
end
function W.ClearRouteOverlay()
    local lib=pins()
    if lib then W.Safe(lib.RemoveAllMinimapIcons,lib,owner);W.Safe(lib.RemoveAllWorldMapIcons,lib,owner) end
    for _,pair in ipairs(pool) do pair.mini:Hide();pair.world:Hide() end
    shownSignature=nil
end
local function icon(parent)
    local f=CreateFrame("Frame",nil,parent);f:SetSize(13,13)
    local edge=f:CreateTexture(nil,"BACKGROUND");edge:SetSize(13,13);edge:SetPoint("CENTER");edge:SetTexture("Interface\\Buttons\\WHITE8X8");edge:SetVertexColor(.03,.06,.08,.95)
    local t=f:CreateTexture(nil,"ARTWORK");t:SetSize(9,9);t:SetPoint("CENTER")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.pinTexture=t
    f:EnableMouse(true)
    f:SetScript("OnEnter",function(self) W.Tooltip(self,self.pinLabel,{"Access/destination marker, not a verified walking line.","Known entrances are cyan; objectives are gold. Use OpenMap to inspect the terrain."}) end)
    f:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    return f
end
function W.UpdateRouteOverlay()
    if not menuRegistered and OpenMapAPI and OpenMapAPI.major==1 and type(OpenMapAPI.RegisterMenuToggle)=="function" then
        local status=W.Call(OpenMapAPI.RegisterMenuToggle,"Trailwarden",{id="access",label="Trailwarden access points",get=function() return W.GetProfile().routeOverlay~=false end,set=function(on) W.GetProfile().routeOverlay=on;W.ClearRouteOverlay();W.UpdateRouteOverlay() end})
        menuRegistered=status=="ok"
    end
    local n=W.Navigation;local travel=n and n.travel;local lib=pins()
    if W.Decision and (not n or n.decisionID~=W.Decision.id or W.Decision.navigationError) then
        W.ClearRouteOverlay();W.OverlayStatus="Synchronizing route";return
    end
    if not lib or W.GetProfile().routeOverlay==false or not travel or not travel.goal then
        W.ClearRouteOverlay();W.OverlayStatus=not lib and "Map pins unavailable / Questie map library not loaded" or "Map pins inactive";return
    end
    local points={}
    if travel.entry then points[#points+1]={point=travel.entry,label=(travel.caveName or "Cave").." entrance",color={.3,.9,1}} end
    points[#points+1]={point=travel.goal,label="Quest objective / not walking path",color={1,.78,.3}}
    local parts={}
    for _,p in ipairs(points) do parts[#parts+1]=p.label..":"..p.point.mapID..":"..p.point.x..":"..p.point.y end
    local signature=table.concat(parts,"|")
    if signature==shownSignature then return end
    W.ClearRouteOverlay()
    for i,p in ipairs(points) do
        local pair=pool[i]
        if not pair then pair={mini=icon(Minimap or UIParent),world=icon(UIParent)};pool[i]=pair end
        for _,f in pairs(pair) do f.pinLabel=p.label;f.pinTexture:SetVertexColor(unpack(p.color)) end
        local point=p.point
        local ms,mr=W.Call(lib.AddMinimapIconMap,lib,owner,pair.mini,point.mapID,point.x,point.y,true,true)
        local ws,wr=W.Call(lib.AddWorldMapIconMap,lib,owner,pair.world,point.mapID,point.x,point.y,nil)
        if ms~="ok" or ws~="ok" or mr==false or wr==false then
            W.ClearRouteOverlay();W.OverlayStatus="Map pin update failed; retrying";return
        end
    end
    shownSignature=signature;W.OverlayStatus="Entrance/objective map pins active"
end
