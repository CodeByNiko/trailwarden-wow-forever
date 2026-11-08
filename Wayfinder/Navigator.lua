local W=Wayfinder
local frame,arrow,title,distance,status,here
local ownWaypoint,lastStep
function W.PositionNavigator()
    if not frame then return end
    local p=W.GetProfile();local pos=p.navigatorPoint
    frame:ClearAllPoints()
    if pos then frame:SetPoint(pos.point,UIParent,pos.relativePoint,pos.x or 0,pos.y or 0) else frame:SetPoint("TOP",UIParent,"TOP",0,-155) end
    frame:SetScale(p.navigatorScale)
end
function W.Bearing(target,player)
    if not target or not player or not target.wx or not player.wx or target.continent~=player.continent then return nil end
    local ex,ey,nx,ny=player.ex,player.ey,player.sx and -player.sx,player.sy and -player.sy
    if not ex or not ey or not nx or not ny then return nil end
    local el,nl=math.sqrt(ex^2+ey^2),math.sqrt(nx^2+ny^2)
    if el<=0 or nl<=0 then return nil end
    local dx,dy=target.wx-player.wx,target.wy-player.wy
    return math.atan2((dx*ex+dy*ey)/el,(dx*nx+dy*ny)/nl)
end
function W.ComputeNavigation(route,player,facing,previous)
    if not route or not route.point then return {label=route and route.kind=="item" and "Use the item" or route and route.key=="paused" and "Navigation paused" or "No waypoint"} end
    if not player or not route.point then return {label="Position unavailable"} end
    local point=route.point;local d=W.Distance(player,point)
    local key=(route.ownerKey or "character")..":"..tostring(route.key)..":"..tostring(point.mapID)..":"..tostring(point.x)..":"..tostring(point.y)
    local radius=(route.kind=="objective" or route.kind=="grind") and 45 or 22
    local threshold=previous and previous.arrivalKey==key and previous.arrived and radius+12 or radius
    if d and d<=threshold then return {distance=d,arrived=true,arrivalKey=key,label=route.kind=="pickup" and "Accept at quest giver" or route.kind=="turnin" and "Turn in here" or route.kind=="deliver" and "Speak with quest receiver" or "Work in this area"} end
    local bearing=W.Bearing(point,player)
    if not bearing then return {distance=d,arrivalKey=key,label=point.continent and player.continent and point.continent~=player.continent and "Travel connection needed" or "Position unavailable"} end
    if not W.IsFinite(facing) then return {distance=d,arrivalKey=key,label="Facing unavailable"} end
    return {distance=d,bearing=bearing,facing=facing,arrivalKey=key,label=point.mapID~=player.mapID and "Travel via roads / transit" or "Following your step"}
end
local function readNavigation(route,previous)
    local copy=route and W.Copy(route)
    if copy and copy.point then
        local fresh=W.Point(copy.mapID,copy.x,copy.y)
        if fresh then fresh.entityID=copy.point.entityID end
        copy.point=fresh
    end
    local player=W.PlayerPoint()
    local travel={mode="direction",navRoute=copy,goal=copy and copy.point}
    if W.ReadAccess then
        local status,result=W.Call(W.ReadAccess,copy,player)
        if status=="ok" then travel=result;W.AccessError=nil else travel={mode="error",navRoute={kind="wait"},label="Access data unavailable"};W.AccessError=tostring(result) end
    end
    local n=W.ComputeNavigation(travel.navRoute,player,W.Safe(GetPlayerFacing),previous)
    n.travel=travel;n.navRoute=travel.navRoute
    if travel.mode=="cave-approach" then
        if n.arrived then n.label="Enter "..travel.caveName elseif n.bearing then n.label="Following cave entrance" end
    elseif travel.mode=="direction" then
        if n.bearing then n.label=travel.label or n.label end
    elseif travel.label then n.label=travel.label end
    return n
end
local compatibilityNavigation
function W.NavigationInfo(route)
    compatibilityNavigation=readNavigation(route,compatibilityNavigation)
    return compatibilityNavigation
end
function W.UpdateNavigation()
    local decision=W.Decision
    local n=readNavigation(decision and decision.route or W.CurrentRoute,W.Navigation)
    n.decisionID=decision and decision.id or 0;W.Navigation=n
    if W.SyncWaypoint then W.SyncWaypoint(decision and decision.route or W.CurrentRoute,false) end
    return n
end
function W.CreateNavigator()
    if frame then return end
    local C=W.Colors
    frame=CreateFrame("Frame","WayfinderNavigatorFrame",UIParent,"BackdropTemplate");W.NavigatorFrame=frame
    frame:SetSize(130,88);frame:SetFrameStrata("MEDIUM");frame:SetClampedToScreen(true);frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(self) if not W.GetProfile().locked then self:StartMoving() end end)
    frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing();local a,_,b,x,y=self:GetPoint(1);W.GetProfile().navigatorPoint={point=a,relativePoint=b,x=x,y=y} end)
    arrow=frame:CreateTexture(nil,"ARTWORK");arrow:SetTexture("Interface\\AddOns\\Wayfinder\\Media\\Arrow.tga");arrow:SetSize(38,38);arrow:SetPoint("TOP",0,-2)
    here=W.Font(frame,15,C.green);here:SetPoint("TOP",0,-12);here:SetText("HERE")
    title=W.Font(frame,10,C.text);title:SetPoint("TOPLEFT",2,-60);title:SetSize(126,26);title:SetJustifyH("CENTER");title:SetWordWrap(true)
    distance=W.Font(frame,12,C.gold);distance:SetPoint("TOP",0,-43)
    status=W.Font(frame,8,C.muted);status:SetPoint("TOPLEFT",2,-60);status:SetSize(126,26);status:SetJustifyH("CENTER");status:SetWordWrap(false)
    frame:SetScript("OnEnter",function(self) local r=W.CurrentRoute or {};W.Tooltip(self,r.title or "Navigator",{r.instruction,W.GetProfile().locked and "Windows are locked. /wf lock unlocks them." or "Drag to move. Mouse wheel adjusts arrow size. /wf arrow toggles visibility.","Direction only: use roads, bridges and cave entrances."}) end)
    frame:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    for _,text in ipairs({title,distance,status,here}) do
        if text.SetShadowColor then text:SetShadowColor(0,0,0,1);text:SetShadowOffset(1,-1) end
    end
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel",function(_,delta) if not W.GetProfile().locked then W.SetDisplayScale("navigatorScale",W.GetProfile().navigatorScale+delta*.05) end end)
    W.PositionNavigator();W.UpdateNavigator()
end
function W.UpdateNavigator()
    if not frame then return end
    local p=W.GetProfile();frame:SetShown(not p.navigatorHidden);frame:EnableMouse(not p.locked)
    if p.navigatorHidden then return end
    local r=W.CurrentRoute
    title:SetText(r and (r.questName or r.title) or "Preparing your route")
    local n=W.Navigation or {label="Preparing navigation"}
    if n.travel and n.travel.mode=="cave-approach" then title:SetText(n.travel.caveName.." entrance") end
    frame.renderDecisionID=W.Decision and W.Decision.id or 0
    here:SetShown(n.arrived==true);arrow:Hide()
    if not n.arrived and n.bearing then
        arrow:SetRotation(-(n.bearing+n.facing));arrow:Show()
    end
    distance:SetText(n.distance and W.FormatDistance(n.distance) or "")
    -- Normal guidance needs only arrow, distance and quest. Exceptional states
    -- replace the quest caption so missing direction remains explicit.
    local exceptional=not n.arrived and not n.bearing
    title:SetShown(not exceptional);status:SetShown(exceptional)
    status:SetText(n.label or "")
end
function W.ToggleNavigator()
    local p=W.GetProfile();p.navigatorHidden=not p.navigatorHidden;W.UpdateNavigator();if W.UpdateUI then W.UpdateUI() end
end
local function currentWaypoint()
    local wp=C_Map and W.Safe(C_Map.GetUserWaypoint)
    if not wp or not wp.position then return nil end
    local x,y=W.Safe(wp.position.GetXY,wp.position)
    return W.Point(wp.uiMapID or wp.mapID,x,y)
end
local function ownsCurrentWaypoint()
    local p=currentWaypoint()
    return ownWaypoint and p and p.mapID==ownWaypoint.mapID and math.abs(p.x-ownWaypoint.x)<0.00001 and math.abs(p.y-ownWaypoint.y)<0.00001
end
function W.ReleaseWaypoint()
    if ownsCurrentWaypoint() then
        if C_SuperTrack then W.Safe(C_SuperTrack.SetSuperTrackedUserWaypoint,false) end
        if C_Map then W.Safe(C_Map.ClearUserWaypoint) end
    end
    ownWaypoint=nil;lastStep=nil
end
function W.SyncWaypoint(route,force)
    W.WaypointDecisionID=W.Decision and W.Decision.id or 0
    local n=W.Navigation
    if n and n.decisionID==W.WaypointDecisionID and (not route or route==W.CurrentRoute or W.Decision and route==W.Decision.route) then
        route=n.navRoute
    end
    if not W.GetProfile().mapSync then W.ReleaseWaypoint();W.WaypointStatus="Map sync off";return end
    if not route or not route.point then W.ReleaseWaypoint();W.WaypointStatus="No mapped step";return end
    local signature=table.concat({route.key,tostring(route.mapID),string.format("%.5f",route.x),string.format("%.5f",route.y)},":")
    if not force and lastStep==signature then return end
    if not C_Map or not C_Map.SetUserWaypoint or not UiMapPoint or not UiMapPoint.CreateFromCoordinates then W.WaypointStatus="Map API unavailable";return end
    if W.Safe(C_Map.CanSetUserWaypointOnMap,route.mapID)==false then W.ReleaseWaypoint();W.WaypointStatus="Map does not accept waypoints";return end
    local wp=W.Safe(UiMapPoint.CreateFromCoordinates,route.mapID,route.x,route.y)
    if not wp then return end
    local ok,result=pcall(C_Map.SetUserWaypoint,wp)
    if ok and result~=false then
        ownWaypoint={mapID=route.mapID,x=route.x,y=route.y};lastStep=signature
        W.WaypointStatus="Waypoint set"
        if C_SuperTrack then W.Safe(C_SuperTrack.SetSuperTrackedUserWaypoint,true) end
    else W.ReleaseWaypoint();W.WaypointStatus="Map waypoint rejected" end
end

