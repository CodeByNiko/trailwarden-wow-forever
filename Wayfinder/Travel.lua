local W=Wayfinder
-- Cave bounds from OpenMap's MIT-licensed Forever Caves.lua (build 1.60.1.70245).
-- Entrance world coordinates are the game's AreaPOI positions (908/909/911).
-- These are access points, not a terrain mesh or a tunnel graph.
W.CaveAccess={
 {id="fel-rock",poiID=909,name="Fel Rock",mapID=1438,interiorMaps={[59]=true},continent=1,bounds={10025.3,970.2,10211.7,1249.8},entrance={10050.6,1031.2},fallback={.546,.526},npcs={[2038]=true}},
 {id="shadowthread",poiID=908,name="Shadowthread Cave",mapID=1438,interiorMaps={[58]=true},continent=1,bounds={10715,660,11035,1140},entrance={10756.2,921.301}},
 {id="banethil",poiID=911,name="Ban'ethil Barrow Den",mapID=1438,interiorMaps={[60]=true,[61]=true},continent=1,bounds={9678.3,1355,9931.7,1735},entrance={9864.17,1557.41}},
}
function W.PointFromWorld(mapID,continent,wx,wy)
    local base=W.Point(mapID,0,0)
    if not base or base.continent~=continent or not base.ex or not W.IsFinite(wx) or not W.IsFinite(wy) then return nil end
    local determinant=base.ex*base.sy-base.ey*base.sx
    if math.abs(determinant)<.000001 then return nil end
    local dx,dy=wx-base.wx,wy-base.wy
    return W.Point(mapID,(dx*base.sy-dy*base.sx)/determinant,(base.ex*dy-base.ey*dx)/determinant)
end
local function inBounds(p,cave)
    local b=cave.bounds
    return p and p.continent==cave.continent and W.IsFinite(p.wx) and W.IsFinite(p.wy) and p.wx>=b[1] and p.wx<=b[3] and p.wy>=b[2] and p.wy<=b[4]
end
function W.MatchCave(route)
    if not route or not route.point then return end
    for _,cave in ipairs(W.CaveAccess) do
        if cave.interiorMaps[route.mapID] or route.mapID==cave.mapID and (inBounds(route.point,cave) or cave.npcs and cave.npcs[route.point.entityID]) then return cave end
    end
end
-- Capture only observed location evidence; 2D proximity cannot establish entry.
function W.CaveForPlayer(player,facts,records)
    if not player then return end
    facts=facts or {};local names=facts.names or {}
    for _,cave in ipairs(records or W.CaveAccess) do
        if cave.interiorMaps[player.mapID] or facts.indoors and type(names[cave.id])=="string" and facts.subzone==names[cave.id] then return cave end
    end
end
local function locationFacts()
    local facts={indoors=W.Safe(IsIndoors)==true,subzone=W.Safe(GetSubZoneText),names={},entrances={}}
    for _,cave in ipairs(W.CaveAccess) do
        for map in pairs(cave.interiorMaps) do
            local info=C_Map and W.Safe(C_Map.GetMapInfo,map)
            if info and type(info.name)=="string" and info.name~="" then facts.names[cave.id]=info.name;break end
        end
        facts.names[cave.id]=facts.names[cave.id] or cave.name
    end
    return facts
end
function W.QuestRegion(mapID)
    local original=mapID;local seen={}
    for _=1,8 do
        if not mapID or seen[mapID] then break end
        if W.Zones and W.Zones[mapID] then return mapID end
        seen[mapID]=true
        local info=C_Map and W.Safe(C_Map.GetMapInfo,mapID)
        mapID=info and info.parentMapID
    end
    return original
end
function W.ReadWorkArea(player)
    local cave=W.CaveForPlayer(player,locationFacts())
    if cave then return {id=cave.id,name=cave.name,mapID=cave.mapID,kind="cave"} end
    local indoors=W.Safe(IsIndoors)==true;local subzone=W.Safe(GetSubZoneText)
    if player and indoors and type(subzone)=="string" and subzone~="" then
        return {id="interior:"..tostring(W.QuestRegion(player.mapID))..":"..subzone,name=subzone,mapID=W.QuestRegion(player.mapID),kind="interior"}
    end
end
-- Pure access state: proximity alone cannot prove the player entered a cave.
function W.ResolveAccess(route,player,facts,records)
    facts=facts or {};local names=facts.names or {};records=records or W.CaveAccess
    if not route or not route.point then return {mode="none",navRoute=route,goal=route and route.point} end
    local destination;local inside=W.CaveForPlayer(player,facts,records)
    for _,cave in ipairs(records) do
        if cave.interiorMaps[route.mapID] or route.mapID==cave.mapID and (inBounds(route.point,cave) or cave.npcs and cave.npcs[route.point.entityID]) then destination=cave end
    end
    local function entrance(cave)
        return facts.entrances and facts.entrances[cave.id]
    end
    if inside then
        return {mode=destination and destination.id==inside.id and "cave-interior" or "cave-exit",caveID=inside.id,caveName=inside.name,entry=entrance(inside),goal=route.point,
            navRoute={kind="wait",key="tunnel:"..tostring(route.key)},label="Tunnel route unavailable",instruction=destination and destination.id==inside.id and ("Inside "..inside.name..". Use the cave map to reach the gold objective marker.") or ("Leave "..inside.name.." via the cyan entrance marker. Use the cave map; tunnel route unknown.")}
    end
    if destination then
        local point=entrance(destination)
        if not point then return {mode="access-unavailable",goal=route.point,navRoute={kind="wait",key="access:"..tostring(route.key)},label="Cave entrance data unavailable",instruction="Target inside "..destination.name..". Entrance position unavailable; inspect the cave map."} end
        local nav=W.Copy(route);nav.point=point;nav.mapID=point.mapID;nav.x=point.x;nav.y=point.y;nav.kind="entrance";nav.key="entrance:"..destination.id
        return {mode="cave-approach",caveID=destination.id,caveName=destination.name,entry=point,goal=route.point,navRoute=nav,label="Find "..destination.name.." entrance",instruction="Head to the "..destination.name.." entrance, then enter the cave. Do not climb toward the objective marker."}
    end
    return {mode="direction",goal=route.point,navRoute=route,label="Direction only; terrain unverified"}
end
function W.ReadAccess(route,player)
    if not route or not route.point then return W.ResolveAccess(route,player,{}) end
    local facts=locationFacts()
    for _,cave in ipairs(W.CaveAccess) do
        local poi=C_AreaPoiInfo and W.Safe(C_AreaPoiInfo.GetAreaPOIInfo,cave.mapID,cave.poiID)
        local point
        if type(poi)=="table" and poi.position and (poi.name==facts.names[cave.id] or cave.interiorMaps[poi.linkedUiMapID]) then
            local x,y=W.Safe(poi.position.GetXY,poi.position);point=W.Point(cave.mapID,x,y)
            if point then point.accessSource="Live entrance POI" end
        end
        if not point then
            point=W.PointFromWorld(cave.mapID,cave.continent,cave.entrance[1],cave.entrance[2])
            if not point and cave.fallback then point=W.Point(cave.mapID,cave.fallback[1],cave.fallback[2]) end
            if point then point.accessSource="Reference entrance" end
        end
        facts.entrances[cave.id]=point
    end
    return W.ResolveAccess(route,player,facts)
end
