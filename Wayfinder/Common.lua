Wayfinder = Wayfinder or {}
local W = Wayfinder
W.Version = "1.4.0"
function W.Safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok,a,b,c,d=pcall(fn,...)
    if ok then return a,b,c,d end
end
function W.Call(fn,...)
    if type(fn)~="function" then return "missing" end
    local ok,a,b,c,d=pcall(fn,...)
    if not ok then return "error",tostring(a) end
    return "ok",a,b,c,d
end
function W.Copy(value,seen)
    if type(value)~="table" then return value end
    seen=seen or {};if seen[value] then return seen[value] end
    local out={};seen[value]=out
    for k,v in pairs(value) do out[W.Copy(k,seen)]=W.Copy(v,seen) end
    return out
end
function W.ProviderIdentity()
    local api=C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local _,build=W.Safe(GetBuildInfo)
    return {version=W.Safe(api,"QuestieDB","Version") or "unknown",contract=LibQuestieDB and LibQuestieDB.contractVersion or 0,build=build or "unknown"}
end
function W.Now() return (GetServerTime and GetServerTime()) or (time and time()) or 0 end
function W.Count(t) local n=0 for _ in pairs(t or {}) do n=n+1 end return n end
function W.HasFlag(mask,flag)
    if not mask or mask==0 then return true end
    if not flag or flag==0 then return false end
    return math.floor(mask/flag)%2==1
end
function W.IsFinite(v) return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge end
local modules={}
function W.Import(name)
    if modules[name] then return modules[name] end
    if QuestieLoader and QuestieLoader.ImportModule then
        local value=W.Safe(QuestieLoader.ImportModule,QuestieLoader,name)
        if type(value)=="table" then modules[name]=value end
        return value
    end
end
function W.MapName(id)
    local info=C_Map and W.Safe(C_Map.GetMapInfo,id)
    return info and info.name or (W.Zones[id] and W.Zones[id].name) or "Unknown area"
end
local transforms={}
function W.Point(mapID,x,y)
    if not W.IsFinite(mapID) or mapID<=0 or not W.IsFinite(x) or not W.IsFinite(y) then return nil end
    if x<0 or x>1 or y<0 or y>1 then return nil end
    local p={mapID=mapID,x=x,y=y,units="normalized",frame="uimap"}
    if C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D then
        local t=transforms[mapID]
        if not t then
            local continent,a=W.Safe(C_Map.GetWorldPosFromMapPos,mapID,CreateVector2D(0,0))
            local bc,b=W.Safe(C_Map.GetWorldPosFromMapPos,mapID,CreateVector2D(1,0))
            local cc,c=W.Safe(C_Map.GetWorldPosFromMapPos,mapID,CreateVector2D(0,1))
            local ax,ay,bx,by,cx,cy
            if a then ax,ay=W.Safe(a.GetXY,a) end
            if b then bx,by=W.Safe(b.GetXY,b) end
            if c then cx,cy=W.Safe(c.GetXY,c) end
            if W.IsFinite(continent) and continent==bc and continent==cc and W.IsFinite(ax) and W.IsFinite(ay) and W.IsFinite(bx) and W.IsFinite(by) and W.IsFinite(cx) and W.IsFinite(cy) then
                local determinant=(bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
                if math.abs(determinant)>0.000001 then
                    t={continent=continent,x=ax,y=ay,ex=bx-ax,ey=by-ay,sx=cx-ax,sy=cy-ay};transforms[mapID]=t
                end
            end
        end
        if t then p.continent=t.continent;p.wx=t.x+x*t.ex+y*t.sx;p.wy=t.y+x*t.ey+y*t.sy;p.ex=t.ex;p.ey=t.ey;p.sx=t.sx;p.sy=t.sy end
    end
    return p
end
function W.PercentPoint(mapID,x,y)
    if not W.IsFinite(x) or not W.IsFinite(y) or x<0 or x>100 or y<0 or y>100 then return nil end
    return W.Point(mapID,x/100,y/100)
end
function W.PlayerPoint()
    if not C_Map then return nil end
    local id=W.Safe(C_Map.GetBestMapForUnit,"player")
    local v=id and W.Safe(C_Map.GetPlayerMapPosition,id,"player")
    if not v then return nil end
    local x,y=W.Safe(v.GetXY,v)
    return W.Point(id,x,y)
end
function W.Distance(a,b)
    if not a or not b or not a.wx or not b.wx or a.continent~=b.continent then return nil end
    return math.sqrt((a.wx-b.wx)^2+(a.wy-b.wy)^2)
end
function W.TravelCost(a,b)
    local d=W.Distance(a,b)
    if d then return d end
    if a and b and a.mapID==b.mapID then return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)*20000 end
    return 100000
end
function W.FormatDistance(d)
    if not d then return "Distance unavailable" end
    if d>=1000 then return string.format("%.1f k yd",d/1000) end
    return string.format("%d yd",math.floor(d+0.5))
end
function W.StepKey(kind,id,suffix) return tostring(kind)..":"..tostring(id or 0)..":"..tostring(suffix or "") end

