local W=Wayfinder
local fieldCache,entityCache,mapLookup={},{},nil
local function entity(kind)
    return LibQuestieDB and LibQuestieDB[kind] or ({Quest=QuestDB,Npc=NpcDB,Object=ObjectDB,Item=ItemDB})[kind]
end
function W.DBGet(kind,id,key)
    local db=entity(kind);return db and W.Safe(db.Get,id,key)
end
function W.Q(id,key)
    local row=fieldCache[id]
    if not row then row={loaded={}};fieldCache[id]=row end
    if not row.loaded[key] then row[key]=W.DBGet("Quest",id,key);row.loaded[key]=true end
    return row[key]
end
local function decode(v)
    if type(v)=="table" then return v end
    if type(v)~="string" or not loadstring then return {} end
    -- Documented QuestieDB Support payload, never remote/chat-supplied input.
    local fn=loadstring(v);if not fn then return {} end
    if setfenv then setfenv(fn,{}) end
    local t=W.Safe(fn);return type(t)=="table" and t or {}
end
function W.MapForArea(areaID)
    local z=W.Import("ZoneDB")
    local id=z and W.Safe(z.GetUiMapIdByAreaId,z,areaID)
    if id and id>0 then return id end
    if not mapLookup then
        local s=LibQuestieDB and LibQuestieDB.Support
        local zones=s and W.Safe(s.Get,"ZoneDB");local p=zones and zones.private or {}
        mapLookup=decode(p.areaIdToUiMapId)
        for k,v in pairs(decode(p.areaIdToUiMapIdOverride)) do mapLookup[k]=v end
        local parents=decode(p.subZoneToParentZone)
        for k,v in pairs(decode(p.subZoneToParentZoneOverride)) do parents[k]=v end
        for k,v in pairs(parents) do if not mapLookup[k] then mapLookup[k]=mapLookup[v] end end
    end
    return mapLookup[areaID] and mapLookup[areaID]>0 and mapLookup[areaID] or nil
end
function W.EntityPoints(kind,id)
    local key=kind..":"..id
    if entityCache[key] then return entityCache[key] end
    local points={};local name=W.DBGet(kind,id,"name") or kind
    for area,coords in pairs(W.DBGet(kind,id,"spawns") or {}) do
        local mapID=W.MapForArea(area)
        local info=mapID and C_Map and W.Safe(C_Map.GetMapInfo,mapID)
        if mapID and (not info or not info.mapType or info.mapType==3) then
            local stride=math.max(1,math.ceil(#coords/40))
            for i=1,#coords,stride do
                local c=coords[i];local p=type(c)=="table" and W.Point(mapID,c[1],c[2])
                if p then p.name=name;p.entityID=id;p.entityKind=kind;p.phase=c[3];points[#points+1]=p end
            end
        end
    end
    table.sort(points,function(a,b) if a.mapID~=b.mapID then return a.mapID<b.mapID end if a.x~=b.x then return a.x<b.x end return a.y<b.y end)
    entityCache[key]=points;return points
end
function W.RelationPoints(id,field)
    local points={};local rel=W.Q(id,field) or {}
    for index,kind in ipairs({"Npc","Object"}) do
        for _,eid in ipairs(rel[index] or {}) do
            for _,point in ipairs(W.EntityPoints(kind,eid)) do points[#points+1]=point end
        end
    end
    return points
end
function W.NearestPoint(points,from,preferred)
    local best,cost
    for _,point in ipairs(points or {}) do
        local c=W.TravelCost(from,point)
        if preferred and point.mapID~=preferred then c=c+2000 end
        if not best or c<cost then best,cost=point,c end
    end
    return best
end
function W.BuildQuestCatalog(force)
    if W.BuildingCatalog then return end
    if W.CatalogReady and not force then return end
    fieldCache={};entityCache={};mapLookup=nil
    local db=entity("Quest");local ids=db and W.Safe(db.GetAllIds)
    if type(ids)~="table" or #ids==0 then W.DatabaseStatus="Waiting for QuestieDB";return end
    W.BuildingCatalog=true;W.CatalogReady=false;W.DatabaseStatus="Reading Forever quest data"
    W.CatalogByMap={};W.ItemQuests={};W.CatalogCount=0
    local index=1
    local function slice()
        local last=math.min(index+19,#ids)
        for i=index,last do
            local id=ids[i];local starters=W.Q(id,"startedBy") or {}
            local record={id=id,name=W.Q(id,"name"),level=W.Q(id,"questLevel") or 0,minLevel=W.Q(id,"requiredLevel") or 0}
            if record.name then
                local seen={}
                for _,point in ipairs(W.RelationPoints(id,"startedBy")) do
                    if not seen[point.mapID] then
                        W.CatalogByMap[point.mapID]=W.CatalogByMap[point.mapID] or {}
                        W.CatalogByMap[point.mapID][#W.CatalogByMap[point.mapID]+1]=record;seen[point.mapID]=true
                    end
                end
                if starters[3] and #starters[3]>0 then W.ItemQuests[#W.ItemQuests+1]={record=record,items=starters[3]} end
                W.CatalogCount=W.CatalogCount+1
            end
        end
        index=last+1;W.CatalogProgress=math.floor(last/#ids*100)
        if index<=#ids and C_Timer then C_Timer.After(0.01,slice)
        elseif index<=#ids then slice()
        else W.BuildingCatalog=false;W.CatalogReady=true;W.DatabaseStatus="Forever database ready";if W.Refresh then W.Refresh(true) end end
    end
    slice()
end
function W.QuestPolicy(id,state,active)
    local q=W.Import("QuestieDB")
    local function yes(method) return q and W.Safe(q[method],id)==true end
    if yes("IsPvPQuest") or yes("IsRaidQuest") then return false,"PvP / raid" end
    if not state.profile.includeGroup and (yes("IsDungeonQuest") or yes("IsGroupQuest")) then return false,"Group quest" end
    local level=W.Q(id,"questLevel") or 0
    if level<=0 and active and state.activeByID[id] then level=state.activeByID[id].level or 0 end
    if level>state.level+state.profile.maxLevelAbove then return false,"Above comfort level" end
    if active then return true end
    if yes("IsRepeatable") or yes("IsDailyQuest") or yes("IsWeeklyQuest") then return false,"Repeatable" end
    if (W.Q(id,"specialFlags") or 0)%2==1 then return false,"Repeatable" end
    return true
end
function W.IsQuestAvailable(id,state)
    if state.completed[id] or state.activeByID[id] then return false end
    if not W.QuestPolicy(id,state,false) then return false end
    local seen=state.profile.offers[id]
    local starters=W.Q(id,"startedBy") or {}
    if starters[1] and #starters[1]>0 and not starters[2] and not starters[3] then
        local allMissing=true
        for _,npcID in ipairs(starters[1]) do
            local gossip=state.profile.gossip[npcID]
            if not gossip or gossip.signature~=state.signature or W.Now()-gossip.seen>300 or gossip.offers[id] then allMissing=false end
        end
        if allMissing then return false end
    end
    -- A live offer can resolve stale restrictions, but cannot undo a later
    -- mutually exclusive choice or a chain step already active/completed.
    for _,other in ipairs(W.Q(id,"exclusiveTo") or {}) do if state.completed[other] or state.activeByID[other] then return false end end
    local following=W.Q(id,"nextQuestInChain") or 0
    if following>0 and (state.completed[following] or state.activeByID[following]) then return false end
    if seen and W.Now()-seen.seen<300 then return true end
    local min,max=W.Q(id,"requiredLevel") or 0,W.Q(id,"requiredMaxLevel") or 0
    if min>state.level or (max>0 and max<state.level) then return false end
    local level=W.Q(id,"questLevel") or 0
    if level>0 and level<state.level-6 then return false end
    if not W.HasFlag(W.Q(id,"requiredClasses"),state.classMask) or not W.HasFlag(W.Q(id,"requiredRaces"),state.raceMask) then return false end
    local one=W.Q(id,"preQuestSingle")
    if one and #one>0 then
        local found=false;for _,v in ipairs(one) do if state.completed[v] then found=true end end
        if not found then return false end
    else
        for _,v in ipairs(W.Q(id,"preQuestGroup") or {}) do
            local found=state.completed[math.abs(v)]
            if not found and v>0 then for _,alt in ipairs(W.Q(v,"exclusiveTo") or {}) do if state.completed[alt] then found=true end end end
            if not found then return false end
        end
    end
    for _,v in ipairs(W.Q(id,"exclusiveTo") or {}) do if state.completed[v] or state.activeByID[v] then return false end end
    local function field(name) local v=W.Q(id,name);return type(v)=="number" and v>0 and v or nil end
    local parent=field("parentQuest");if parent and not state.activeByID[parent] then return false end
    local nextID=field("nextQuestInChain");if nextID and (state.completed[nextID] or state.activeByID[nextID]) then return false end
    local before=field("availableUntilCompleted");if before and state.completed[before] then return false end
    local after=field("availableStartingWith");if after and not state.completed[after] and not state.activeByID[after] then return false end
    local disabled=field("disabledByQuest");if disabled and state.activeByID[disabled] then return false end
    for _,itemID in ipairs(W.Q(id,"requiredSourceItems") or {}) do
        local count=(C_Item and W.Safe(C_Item.GetItemCount,itemID)) or W.Safe(GetItemCount,itemID) or 0
        if count<1 then return false end
    end
    local q=W.Import("QuestieDB");local doable=q and W.Safe(q.IsDoable,id)
    if doable==false then return false end
    if doable==nil then
        if W.Q(id,"requiredSkill") or W.Q(id,"requiredMinRep") or W.Q(id,"requiredMaxRep") or W.Q(id,"requiredRanks") then return false end
        if (W.Q(id,"requiredSpell") or 0)>0 or (W.Q(id,"requiredSpecialization") or 0)>0 then return false end
    end
    return true
end
