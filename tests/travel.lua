-- Synthetic access, minimap contracts; no terrain mesh is bundled.
unpack=unpack or table.unpack;math.atan2=math.atan2 or function(y,x) return math.atan(y,x) end
local epoch=100;local profile={routeOverlay=true,mapSync=true}
function GetServerTime() return epoch end
function CreateVector2D(x,y) return {GetXY=function() return x,y end} end
local userWaypoint;local mapSets,mapClears=0,0
C_Map={GetWorldPosFromMapPos=function(id,p)
 local x,y=p:GetXY();if id~=1438 and id~=59 then return nil end
 return 1,CreateVector2D(12000-y*4000,4000-x*6000)
end,GetMapInfo=function(id) return {name=id==59 and "Fel Rock" or "Cave"} end,
GetUserWaypoint=function() return userWaypoint end,SetUserWaypoint=function(p) userWaypoint=p;mapSets=mapSets+1 end,
ClearUserWaypoint=function() userWaypoint=nil;mapClears=mapClears+1 end,CanSetUserWaypointOnMap=function() return true end}
UiMapPoint={CreateFromCoordinates=function(map,x,y) return {uiMapID=map,position=CreateVector2D(x,y)} end}
for _,name in ipairs({"Common","Travel","Navigator","RouteOverlay"}) do dofile("Wayfinder/"..name..".lua") end
local W=Wayfinder
W.GetProfile=function() return profile end;W.GetCharacterKey=function() return "NightElf" end
local passed=0
local function check(name,ok) assert(ok,name);passed=passed+1;print("PASS travel / "..name) end
local goal=W.PointFromWorld(1438,1,10100,1080);goal.entityID=2038
local entry=W.PointFromWorld(1438,1,10050.6,1031.2)
local route={kind="objective",key="objective:932",questID=932,title="Twisted Hatred",questName="Twisted Hatred",point=goal,mapID=1438,x=goal.x,y=goal.y}
local player=W.PointFromWorld(1438,1,10000,1050)
local facts={names={['fel-rock']="Fel Rock"},entrances={['fel-rock']=entry}}
local a=W.ResolveAccess(route,player,facts)
check("inverse map transform preserves world axes",math.abs(goal.wx-10100)<.0001 and math.abs(goal.wy-1080)<.0001)
check("invalid continent has no invented map position",not W.PointFromWorld(1438,0,10100,1080))
check("nonfinite world coordinate rejected",not W.PointFromWorld(1438,1,0/0,1080))
check("off-map entrance cannot become a normalized pin",not W.PointFromWorld(1438,1,99000,1080))
check("Melenas approaches cave entrance before quest goal",a.mode=="cave-approach" and a.navRoute.point==entry and a.goal==goal)
check("access layer never changes quest objective coordinates",route.point==goal and route.x==goal.x and route.kind=="objective")
check("map bounds identify other targets inside Fel Rock",W.MatchCave(route).id=="fel-rock")
check("proximity to target cannot certify cave entry",W.ResolveAccess(route,goal,facts).mode=="cave-approach")
local inside=W.Copy(player);inside.mapID=59
check("actual cave map switches to interior guidance",W.ResolveAccess(route,inside,facts).mode=="cave-interior")
facts.indoors=true;facts.subzone="Fel Rock"
check("localized indoor subzone also identifies cave",W.ResolveAccess(route,player,facts).mode=="cave-interior")
facts.indoors=false
check("subzone without indoor evidence does not skip entrance",W.ResolveAccess(route,player,facts).mode=="cave-approach")
local outside=W.Copy(route);outside.point=W.Point(1438,.2,.2);outside.x=.2;outside.y=.2
check("leaving cave never invents a straight tunnel path",not W.ResolveAccess(outside,inside,facts).navRoute.point)
check("unknown terrain explicitly remains direction only",W.ResolveAccess(outside,player,{}).mode=="direction")
check("missing entrance fails without pointing through mountain",not W.ResolveAccess(route,player,{}).navRoute.point)
check("missing indoor names do not fabricate a cave entry",W.ResolveAccess(route,player,{indoors=true,entrances=facts.entrances}).mode=="cave-approach")
check("no actionable goal clears access overlay context",W.ResolveAccess({kind="wait",key="dead"},inside,{}).mode=="none")
W.PlayerPoint=function() return player end;GetPlayerFacing=function() return 0 end
W.CurrentRoute=route;W.Decision={id=1,route=route}
C_AreaPoiInfo={GetAreaPOIInfo=function(map,id)
 assert(map==1438);if id==909 then return {name="Fel Rock",position=CreateVector2D(.55,.53),linkedUiMapID=59} end
end}
check("live Forever cave POI takes precedence over reference coordinates",W.ReadAccess(route,player).entry.x==.55 and W.ReadAccess(route,player).entry.accessSource=="Live entrance POI")
C_AreaPoiInfo.GetAreaPOIInfo=function() return {name="Different landmark",position=CreateVector2D(.1,.1)} end
check("reused POI id cannot position an unrelated entrance",W.ReadAccess(route,player).entry.x==entry.x)
C_AreaPoiInfo=nil
local n=W.UpdateNavigation()
check("entrance fallback is built into Wayfinder",n.navRoute.kind=="entrance")
check("native waypoint is entrance rather than Melenas",userWaypoint and math.abs(select(1,userWaypoint.position:GetXY())-entry.x)<.00001)
local before=mapSets;W.UpdateNavigation()
check("movement updates do not repeatedly set native waypoint",mapSets==before)
W.PlayerPoint=function() return inside end;W.UpdateNavigation()
check("inside cave with no mesh suppresses misleading arrow",not W.Navigation.bearing and W.Navigation.travel.mode=="cave-interior")
check("entering cave clears exterior waypoint automatically",not userWaypoint)
W.PlayerPoint=function() return outside.point end
check("arrival instruction at an ordinary quest giver is preserved",W.NavigationInfo({kind="pickup",key="pickup",point=outside.point,mapID=1438,x=outside.x,y=outside.y}).label=="Accept at quest giver")
W.PlayerPoint=function() return player end
-- Real minimap projection/rotation belongs to HBD, never a hand-written screen offset.
local icons={};local methods={}
for _,name in ipairs({"SetSize","SetPoint","SetAllPoints","SetTexture","SetTexCoord","EnableMouse"}) do methods[name]=function() end end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:SetVertexColor(...) self.color={...} end
function methods:Hide() self.hidden=true end
function methods:CreateTexture() return setmetatable({},{__index=methods}) end
function CreateFrame() local f=setmetatable({scripts={}},{__index=methods});icons[#icons+1]=f;return f end
local hbd={};local mini,world,removedMini,removedWorld={},{},0,0;local ref
function hbd:AddMinimapIconMap(owner,icon,map,x,y,parent,edge)
 ref=owner;mini[#mini+1]={owner=owner,icon=icon,map=map,x=x,y=y,parent=parent,edge=edge}
end
function hbd:AddWorldMapIconMap(owner,icon,map,x,y,show) world[#world+1]={owner=owner,icon=icon,map=map,x=x,y=y,show=show} end
function hbd:RemoveAllMinimapIcons(owner) assert(ref==nil or owner==ref);removedMini=removedMini+1 end
function hbd:RemoveAllWorldMapIcons(owner) assert(ref==nil or owner==ref);removedWorld=removedWorld+1 end
local available=false
LibStub=setmetatable({GetLibrary=function(self,name,silent) assert(self==LibStub and name=="HereBeDragons-Pins-2.0" and silent);return available and hbd or nil end},{__call=function() error("Use callable-table LibStub through GetLibrary") end})
W.Navigation={travel=a};W.UpdateRouteOverlay()
check("no HBD is a graceful optional feature absence",#icons==0)
available=true
local menu;OpenMapAPI={major=1,RegisterMenuToggle=function(owner,definition) menu=definition;check("OpenMap menu uses public addon registration",owner=="Wayfinder") end}
W.UpdateRouteOverlay()
check("entrance and objective use separate mini and world frames",#mini==2 and #world==2 and mini[1].icon~=world[1].icon)
check("minimap receives normalized entrance and parent/edge flags",mini[1].map==1438 and mini[1].x==entry.x and mini[1].y==entry.y and mini[1].parent and mini[1].edge)
check("entrance cyan and goal gold remain distinct",mini[1].icon.pinTexture.color[2]==.9 and mini[2].icon.pinTexture.color[2]==.78)
before=#mini;W.UpdateRouteOverlay()
check("unchanged access points do not rebuild icons",#mini==before)
W.Navigation={travel=W.ResolveAccess(outside,player,{})};W.UpdateRouteOverlay()
check("reused marker updates its tooltip and color",mini[#mini].icon.pinLabel=="Quest objective / not walking path" and mini[#mini].icon.pinTexture.color[2]==.78)
local originalAdd=hbd.AddMinimapIconMap
hbd.AddMinimapIconMap=function() error("map library refreshing") end
W.ClearRouteOverlay();W.UpdateRouteOverlay()
check("failed map-pin update stays retryable",W.OverlayStatus=="Map pin update failed; retrying")
hbd.AddMinimapIconMap=originalAdd;before=#mini;W.UpdateRouteOverlay()
check("map pins recover without another quest event",#mini>before and W.OverlayStatus=="Entrance/objective map pins active")
menu.set(false)
check("OpenMap visibility toggle persists character preference",not profile.routeOverlay and menu.get()==false)
profile.routeOverlay=true;W.Navigation={travel={mode="none"}};W.UpdateRouteOverlay()
check("no actionable route hides pooled icons",icons[1].hidden and icons[2].hidden)
local priorInfo=C_Map.GetMapInfo;local priorZones=W.Zones
W.Zones={[1438]={}}
C_Map.GetMapInfo=function(id) return id==777 and {name="Unmapped floor",parentMapID=1438} or priorInfo(id) end
check("unknown underground floor resolves its parent quest region",W.QuestRegion(777)==1438)
C_Map.GetMapInfo=function(id) return {name="Loop",parentMapID=id} end
check("cyclic map metadata is bounded and retains the original map",W.QuestRegion(777)==777)
C_Map.GetMapInfo=priorInfo;W.Zones=priorZones
print(string.format("%d travel/access/map checks passed",passed))
