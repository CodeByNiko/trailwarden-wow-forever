local W=Trailwarden
local fieldCache,entityCache,mapLookup={},{},nil
local capture
function W.BeginDataCapture() capture={} end
function W.RecordFact(kind,id,key,value,status)
    if not capture then return end
    local entityKey=kind..":"..tostring(id);capture[entityKey]=capture[entityKey] or {}
    capture[entityKey][key]={status=status or "ok",value=W.Copy(value)}
end
function W.EndDataCapture() local facts=capture or {};capture=nil;return facts end
local tableFields={startedBy=true,finishedBy=true,objectives=true,objectivesText=true,triggerEnd=true,preQuestGroup=true,preQuestSingle=true,childQuests=true,inGroupWith=true,exclusiveTo=true,requiredSkill=true,requiredMinRep=true,requiredMaxRep=true,requiredSourceItems=true,reputationReward=true,breadcrumbs=true,extraObjectives=true,requiredRanks=true}
local function issue(key,message)
    W.DataIssues=W.DataIssues or {};W.DataIssues[key]=message
end
local function entity(kind) return LibQuestieDB and LibQuestieDB[kind] or ({Quest=QuestDB,Npc=NpcDB,Object=ObjectDB,Item=ItemDB})[kind] end
function W.DBRead(kind,id,key)
    local db=entity(kind);local status,value=W.Call(db and db.Get,id,key)
    local k=kind..":"..tostring(id)..":"..key
    W.RecordFact(kind,id,key,value,status)
    if status~="ok" then issue(k,status=="error" and value or "Provider method unavailable");return nil,status end
    if W.DataIssues then W.DataIssues[k]=nil end
    return value,"ok"
end
function W.DBGet(kind,id,key) return W.DBRead(kind,id,key) end
function W.Q(id,key)
    local row=fieldCache[id]
    if not row then row={loaded={}};fieldCache[id]=row end
    if row.loaded[key] then W.RecordFact("Quest",id,key,row[key],"ok");return row[key],"ok" end
    local value,status=W.DBRead("Quest",id,key)
    if status=="ok" and value==nil and not tableFields[key] and key~="name" then
        local name=W.DBGet("Quest",id,"name")
        if type(name)=="string" then status="invalid";issue("Quest:"..id..":"..key,"Known quest numeric field returned nil") end
    end
    if status=="ok" and value~=nil then
        local valid=key=="name" and type(value)=="string" or tableFields[key] and type(value)=="table" or key~="name" and not tableFields[key] and W.IsFinite(value)
        if not valid then status="invalid";issue("Quest:"..id..":"..key,"Invalid field shape") end
    end
    if status=="ok" then row[key]=value;row.loaded[key]=true end
    if status~="ok" then return nil,status end
    return value,status
end
local function decode(v)
    if type(v)=="table" then return W.Copy(v) end
    if type(v)~="string" or not loadstring then return nil end
    local fn=loadstring(v);if not fn then return nil end
    if setfenv then setfenv(fn,{}) end
    local status,value=W.Call(fn)
    return status=="ok" and type(value)=="table" and value or nil
end
local function loadMaps()
    local s=LibQuestieDB and LibQuestieDB.Support
    local zones=s and W.Safe(s.Get,"ZoneDB");local p=type(zones)=="table" and zones.private
    if type(p)~="table" then return nil end
    local maps=decode(p.areaIdToUiMapId)
    if not maps or next(maps)==nil then return nil end
    for k,v in pairs(decode(p.areaIdToUiMapIdOverride) or {}) do maps[k]=v end
    local parents=decode(p.subZoneToParentZone) or {}
    for k,v in pairs(decode(p.subZoneToParentZoneOverride) or {}) do parents[k]=v end
    local function resolve(area,visited)
        if maps[area]~=nil then return maps[area] end
        visited=visited or {};if visited[area] then return nil end;visited[area]=true
        local parent=parents[area];if parent then maps[area]=resolve(parent,visited) end
        return maps[area]
    end
    for area in pairs(parents) do resolve(area) end
    return maps
end
function W.MapForArea(areaID)
    local z=W.Import("ZoneDB");local id=z and W.Safe(z.GetUiMapIdByAreaId,z,areaID)
    if W.IsFinite(id) and id>0 then return id end
    if not mapLookup then mapLookup=loadMaps() end
    id=mapLookup and mapLookup[areaID]
    return W.IsFinite(id) and id>0 and id or nil
end
function W.EntityPoints(kind,id)
    local key=kind..":"..tostring(id)
    if entityCache[key] then W.RecordFact(kind,id,"resolvedPoints",entityCache[key],"ok");return entityCache[key],"ok" end
    local spawns,status=W.DBRead(kind,id,"spawns")
    if status~="ok" then return {},status end
    if spawns==nil then return {},"empty" end
    if type(spawns)~="table" then issue(key,"Invalid spawn table");return {},"invalid" end
    if W.DataIssues then W.DataIssues[key]=nil end
    local points={};local name=W.DBGet(kind,id,"name") or kind
    for area,coords in pairs(spawns) do
        if type(coords)~="table" then return {},"invalid" end
        local mapID=W.MapForArea(area)
        local info=mapID and C_Map and W.Safe(C_Map.GetMapInfo,mapID)
        if mapID and (not info or not info.mapType or info.mapType==3) then
            local stride=math.max(1,math.ceil(#coords/40))
            for i=1,#coords,stride do
                local c=coords[i]
                if type(c)~="table" then return {},"invalid" end
                -- QuestieDB uses {-1,-1} for a known entity without a mapped
                -- position (for example an instance NPC). It is not a corrupt
                -- coordinate and must not abort the entire quest catalog.
                if c[1]~=-1 or c[2]~=-1 then
                    local p=W.PercentPoint(mapID,c[1],c[2])
                    if not p then return {},"invalid" end
                    p.name=name;p.entityID=id;p.entityKind=kind;p.phase=c[3];p.source="QuestieDB";p.confidence="database"
                    points[#points+1]=p
                end
            end
        end
    end
    table.sort(points,function(a,b) if a.mapID~=b.mapID then return a.mapID<b.mapID end if a.x~=b.x then return a.x<b.x end return a.y<b.y end)
    if #points>0 then entityCache[key]=points end
    W.RecordFact(kind,id,"resolvedPoints",points,#points>0 and "ok" or "empty")
    return points,#points>0 and "ok" or "empty"
end
function W.RelationPoints(id,field)
    local rel,status=W.Q(id,field)
    if status~="ok" then return {},status end
    if rel==nil then return {},"empty" end
    local points={}
    for index,kind in ipairs({"Npc","Object"}) do
        if rel[index]~=nil and type(rel[index])~="table" then return {},"invalid" end
        for _,eid in ipairs(rel[index] or {}) do
            if not W.IsFinite(eid) or eid<=0 then return {},"invalid" end
            local list,s=W.EntityPoints(kind,eid)
            if s=="invalid" or s=="error" or s=="missing" then return {},s end
            for _,point in ipairs(list) do points[#points+1]=point end
        end
    end
    return points,"ok"
end
function W.NearestPoint(points,from,preferred)
    local best,cost
    for _,point in ipairs(points or {}) do
        local c=W.TravelCost(from,point);if preferred and point.mapID~=preferred then c=c+2000 end
        if not best or c<cost then best,cost=point,c end
    end
    return best
end
function W.ObservedPoint(id,kind,state)
    local l=state.profile.locations[kind..":"..id]
    if not l or l.units~="normalized" or not W.IsFinite(l.seen) or state.now-l.seen<0 or state.now-l.seen>300 or not l.entityID then return nil end
    if type(l.provider)~="table" or l.provider.version~=state.provider.version or l.provider.build~=state.provider.build or l.provider.contract~=state.provider.contract then return nil end
    local rel=W.Q(id,kind=="pickup" and "startedBy" or "finishedBy") or {}
    local known=rel[l.entityKind=="Object" and 2 or 1]
    if known and #known>0 then
        local matches=false;for _,eid in ipairs(known) do if eid==l.entityID then matches=true end end
        if not matches then return nil end
    end
    local p=W.Point(l.mapID,l.x,l.y)
    if p then p.name=l.name;p.entityID=l.entityID;p.entityKind=l.entityKind;p.source="Observed in game";p.observedAt=l.seen;p.confidence="interaction-area" end
    return p
end
function W.BuildQuestCatalog(force,attempt)
    if W.BuildingCatalog then if force then W.RebuildPending=true end;return end
    if W.CatalogReady and not force then return end
    attempt=attempt or 1
    W.CatalogGeneration=(W.CatalogGeneration or 0)+1;local generation=W.CatalogGeneration
    fieldCache={};entityCache={};mapLookup=nil
    local db=entity("Quest");local status,ids=W.Call(db and db.GetAllIds)
    W.BuildingCatalog=true;W.CatalogState="loading";W.DatabaseStatus="Reading Forever quest data"
    local nextMaps,nextItems,count,index={},{},0,1
    local function fail(message)
        if generation~=W.CatalogGeneration then return end
        W.BuildingCatalog=false;W.CatalogError=tostring(message);W.CatalogState=W.CatalogReady and "degraded" or "waiting"
        W.DatabaseStatus=W.CatalogReady and "Using previous quest catalog; rebuild failed" or "Quest data unavailable; retrying"
        local again=W.RebuildPending;W.RebuildPending=nil
        if C_Timer and (again or attempt<3) then
            C_Timer.After(again and .01 or 2,function() if generation==W.CatalogGeneration and not W.BuildingCatalog then W.BuildQuestCatalog(true,again and 1 or attempt+1) end end)
        elseif not W.CatalogReady then W.CatalogState="failed";W.DatabaseStatus="Quest data unavailable; use /tw rebuild to retry" end
        if W.Refresh then W.Refresh(false,"catalog-failed") end
    end
    if status~="ok" or type(ids)~="table" or #ids==0 then fail("Quest ID list unavailable");return end
    local function work()
        local last=math.min(index+19,#ids)
        for i=index,last do
            local id=ids[i];assert(W.IsFinite(id) and id>0,"Invalid quest ID")
            local name,ns=W.Q(id,"name");local starters,ss=W.Q(id,"startedBy")
            assert(ns=="ok" and ss=="ok" and type(starters)=="table","Quest fields unavailable: "..id)
            local level,ls=W.Q(id,"questLevel");local minLevel,ms=W.Q(id,"requiredLevel")
            assert(ls=="ok" and ms=="ok","Invalid quest levels: "..id)
            local record={id=id,name=name,level=level or 0,minLevel=minLevel or 0}
            if name then
                local points,ps=W.RelationPoints(id,"startedBy");assert(ps=="ok" or ps=="empty","Starter positions unavailable: "..id)
                local seen={}
                for _,point in ipairs(points) do
                    if not seen[point.mapID] then nextMaps[point.mapID]=nextMaps[point.mapID] or {};nextMaps[point.mapID][#nextMaps[point.mapID]+1]=record;seen[point.mapID]=true end
                end
                if starters[3]~=nil then assert(type(starters[3])=="table","Invalid item starters") end
                if starters[3] and #starters[3]>0 then nextItems[#nextItems+1]={record=record,items=starters[3]} end
                count=count+1
            end
        end
        index=last+1;W.CatalogProgress=math.floor(last/#ids*100)
    end
    local slice
    slice=function()
        if generation~=W.CatalogGeneration then return end
        local ok,message=pcall(work);if not ok then fail(message);return end
        if index<=#ids then if C_Timer then C_Timer.After(.01,slice) else slice() end;return end
        if next(nextMaps)==nil and #nextItems==0 then fail("No mapped quest starters available");return end
        W.CatalogByMap,W.ItemQuests,W.CatalogCount=nextMaps,nextItems,count
        W.PublishedCatalogGeneration=generation;W.CatalogReady=true;W.BuildingCatalog=false;W.CatalogError=nil;W.CatalogState="ready";W.DatabaseStatus="Forever database ready"
        local again=W.RebuildPending;W.RebuildPending=nil
        if W.Refresh then W.Refresh(true,"catalog-published") end
        if again then W.BuildQuestCatalog(true) end
    end
    slice()
end
function W.QuestPolicy(id,state,active)
    local q=W.Import("QuestieDB")
    local function yes(method)
        local status,value=W.Call(q and q[method],id);W.RecordFact("QuestiePolicy",id,method,value,status);return value==true and status=="ok"
    end
    if yes("IsPvPQuest") or yes("IsRaidQuest") then return false,"PvP / raid" end
    if not state.profile.includeGroup and (yes("IsDungeonQuest") or yes("IsGroupQuest")) then return false,"Group quest" end
    local level=W.Q(id,"questLevel") or 0
    if level<=0 and active and state.activeByID[id] then level=state.activeByID[id].level or 0 end
    -- Comfort limits new pickups, not work the player has already accepted.
    if not active and level>state.level+state.profile.maxLevelAbove then return false,"Above comfort level" end
    if active then return true end
    if yes("IsRepeatable") or yes("IsDailyQuest") or yes("IsWeeklyQuest") or (W.Q(id,"specialFlags") or 0)%2==1 then return false,"Repeatable" end
    return true
end
local function verdict(status,reason,source) return {status=status,reason=reason,source=source} end
function W.QuestEligibility(id,state)
    if state.completed[id] then return verdict("blocked","Already completed","progress") end
    if state.activeByID[id] then return verdict("blocked","Already active","progress") end
    if not state.questLogReady then return verdict("unknown","Quest log not ready","client") end
    local qfields={}
    for _,field in ipairs({"exclusiveTo","nextQuestInChain","availableUntilCompleted","availableStartingWith","disabledByQuest","parentQuest","requiredSourceItems"}) do
        local value,status=W.Q(id,field)
        if status~="ok" then return verdict("unknown","Quest rules unavailable: "..field,"database") end
        qfields[field]=value
    end
    for _,v in ipairs(qfields.exclusiveTo or {}) do if state.completed[v] or state.activeByID[v] then return verdict("blocked","Exclusive quest chosen","progress") end end
    local following=qfields.nextQuestInChain or 0
    if following>0 and (state.completed[following] or state.activeByID[following]) then return verdict("blocked","Later chain step already reached","progress") end
    local untilID=qfields.availableUntilCompleted or 0
    if untilID>0 and state.completed[untilID] then return verdict("blocked","Availability ended by turn-in","progress") end
    local disabled=qfields.disabledByQuest or 0
    if disabled>0 and state.activeByID[disabled] then return verdict("blocked","Disabled by active quest","progress") end
    for _,itemID in ipairs(qfields.requiredSourceItems or {}) do
        local api=C_Item and C_Item.GetItemCount or GetItemCount
        local status,count=W.Call(api,itemID);W.RecordFact("Inventory",itemID,"count",count,status)
        if status~="ok" or not W.IsFinite(count) then return verdict("unknown","Required item count unavailable","inventory") end
        if count<1 then return verdict("blocked","Required source item missing","inventory") end
    end
    local policy,why=W.QuestPolicy(id,state,false);if not policy then return verdict("blocked",why,"policy") end
    local seen=state.profile.offers[id]
    local fresh=seen and seen.revision==state.revision and state.now-seen.seen>=0 and state.now-seen.seen<300
    local starters=W.Q(id,"startedBy") or {}
    if starters[1] and #starters[1]>0 and not starters[2] and not starters[3] then
        local allMissing=true
        for _,npcID in ipairs(starters[1]) do
            local g=state.profile.gossip[npcID]
            if not g or g.revision~=state.revision or state.now-g.seen<0 or state.now-g.seen>300 or g.offers[id] then allMissing=false end
        end
        if allMissing then return verdict("blocked","Not offered at inspected quest giver","observation") end
    end
    if fresh then return verdict("eligible","Live offer matches current progression","observation") end
    if not state.historyReady then return verdict("unknown","Completed quest history not ready","client") end
    local name,ns=W.Q(id,"name");if ns~="ok" or not name then return verdict("unknown","Quest absent from database","database") end
    local min,max=W.Q(id,"requiredLevel") or 0,W.Q(id,"requiredMaxLevel") or 0
    if min>state.level or max>0 and max<state.level then return verdict("blocked","Outside required level range","database") end
    local level=W.Q(id,"questLevel") or 0;if level>0 and level<state.level-6 then return verdict("blocked","Below useful level range","policy") end
    if not W.HasFlag(W.Q(id,"requiredClasses"),state.classMask) or not W.HasFlag(W.Q(id,"requiredRaces"),state.raceMask) then return verdict("blocked","Class or race restriction","database") end
    local one=W.Q(id,"preQuestSingle")
    if one and #one>0 then
        local found=false;for _,v in ipairs(one) do if state.completed[v] then found=true end end
        if not found then return verdict("blocked","Alternative prerequisite missing","progress") end
    else
        for _,v in ipairs(W.Q(id,"preQuestGroup") or {}) do
            local found=state.completed[math.abs(v)]
            if not found and v>0 then for _,alt in ipairs(W.Q(v,"exclusiveTo") or {}) do if state.completed[alt] then found=true end end end
            if not found then return verdict("blocked","Group prerequisite missing","progress") end
        end
    end
    local parent=qfields.parentQuest or 0;if parent>0 and not state.activeByID[parent] then return verdict("blocked","Parent quest not active","progress") end
    local after=qfields.availableStartingWith or 0;if after>0 and not state.activeByID[after] and not state.completed[after] then return verdict("blocked","Starting prerequisite missing","progress") end
    local q=W.Import("QuestieDB");local status,doable=W.Call(q and q.IsDoable,id);W.RecordFact("QuestiePolicy",id,"IsDoable",doable,status)
    if status=="ok" and doable==false then return verdict("blocked","Questie availability check","Questie") end
    if status~="ok" or doable==nil then
        if W.Q(id,"requiredSkill") or W.Q(id,"requiredMinRep") or W.Q(id,"requiredMaxRep") or W.Q(id,"requiredRanks") or (W.Q(id,"requiredSpell") or 0)>0 or (W.Q(id,"requiredSpecialization") or 0)>0 then return verdict("unknown","Restricted quest cannot be verified","database") end
    end
    if not W.QuestFieldsHealthy(id) then return verdict("unknown","Quest field contract could not be verified","database") end
    return verdict("eligible","Database requirements fulfilled","database")
end
function W.QuestFieldsHealthy(id)
    local prefix="Quest:"..id..":"
    for key in pairs(W.DataIssues or {}) do if key:sub(1,#prefix)==prefix then return false end end
    return true
end
function W.IsQuestAvailable(id,state) local v=W.QuestEligibility(id,state);return v.status=="eligible",v.reason,v.status end

