local W=Wayfinder
local defaults={includeGroup=false,maxLevelAbove=2,navigatorHidden=false,mapSync=true,panelHidden=false,collapsed=false,uiScale=1,paused=false}
function W.GetCharacterKey()
    return W.Safe(UnitGUID,"player") or ((W.Safe(UnitName,"player") or "Unknown").." - "..(W.Safe(GetRealmName) or "Realm"))
end
function W.GetProfile()
    WayfinderDB=WayfinderDB or {};WayfinderDB.profiles=WayfinderDB.profiles or {}
    local key=W.GetCharacterKey()
    if not WayfinderDB.profiles[key] then
        local oldKey=(W.Safe(UnitName,"player") or "Unknown").." - "..(W.Safe(GetRealmName) or "Realm")
        local old=WayfinderDB.profiles[oldKey] or {}
        WayfinderDB.profiles[key]={navigatorPoint=old.navigatorPoint,navigatorHidden=old.navigatorHidden}
    end
    local p=WayfinderDB.profiles[key]
    for k,v in pairs(defaults) do if p[k]==nil then p[k]=v end end
    p.completed=p.completed or {};p.skipped=p.skipped or {};p.offers=p.offers or {};p.locations=p.locations or {};p.gossip=p.gossip or {};p.schema=2
    for k,untilTime in pairs(p.skipped) do if untilTime<W.Now() then p.skipped[k]=nil end end
    return p
end
function W.RememberTurnIn(id) if type(id)=="number" and id>0 then W.GetProfile().completed[id]=true end end
local function done(v) return v==true or v==1 end
function W.ScanCharacter()
    local p=W.GetProfile()
    local className,classToken,classID=W.Safe(UnitClass,"player")
    local raceName,raceToken,raceID=W.Safe(UnitRace,"player")
    local mapID=C_Map and W.Safe(C_Map.GetBestMapForUnit,"player")
    local state={key=W.GetCharacterKey(),name=W.Safe(UnitName,"player") or "Adventurer",className=className or "Unknown",classToken=classToken,raceName=raceName or "Unknown",raceToken=raceToken,raceID=raceID,
        classMask=W.ClassMasks[classToken],raceMask=W.ClassicRaceMasks[raceID],faction=W.Safe(UnitFactionGroup,"player"),level=W.Safe(UnitLevel,"player") or 1,
        mapID=mapID,zone=mapID and W.MapName(mapID) or W.Safe(GetRealZoneText) or "Unknown area",profile=p,
        activeQuests={},activeByID={},completed=p.completed,player=W.PlayerPoint(),dead=W.Safe(UnitIsDeadOrGhost,"player")==true}
    if LibQuestieDB and LibQuestieDB.RequireContract and W.Safe(LibQuestieDB.RequireContract,3) then
        state.raceMask=(LibQuestieDB.Enum and LibQuestieDB.Enum.raceMaskById or {})[raceID] or state.raceMask
    end
    local completed=C_QuestLog and W.Safe(C_QuestLog.GetAllCompletedQuestIDs)
    if type(completed)=="table" then for _,id in ipairs(completed) do if type(id)=="number" then p.completed[id]=true end end end
    if not completed and GetQuestsCompleted then
        local into={};local result=W.Safe(GetQuestsCompleted,into) or into
        for id,v in pairs(result) do if v==true then p.completed[id]=true elseif type(v)=="number" then p.completed[v]=true end end
    end
    state.historyReady=type(completed)=="table" or next(p.completed)~=nil
    local ql=C_QuestLog or {};local count=W.Safe(ql.GetNumQuestLogEntries) or 0
    local sig={tostring(mapID),tostring(state.level)}
    for i=1,count do
        local info=W.Safe(ql.GetInfo,i)
        if info and not info.isHeader and info.questID and info.questID>0 then
            local id=info.questID
            local q={id=id,title=info.title or "Quest",level=info.level,logIndex=i,objectives={},isComplete=done(info.isComplete) or done(W.Safe(ql.IsComplete,id)) or done(W.Safe(ql.ReadyForTurnIn,id)),failed=info.isComplete==-1}
            local rows=W.Safe(ql.GetQuestObjectives,id) or {};local fingerprint={tostring(id),tostring(q.isComplete)}
            for j,o in ipairs(rows) do
                q.objectives[j]={text=o.text or "",type=o.type,id=o.objectiveID,fulfilled=o.numFulfilled or 0,required=o.numRequired or 0,finished=done(o.finished)}
                fingerprint[#fingerprint+1]=tostring(o.numFulfilled or 0)..":"..tostring(o.finished)
            end
            local m,x,y=W.Safe(ql.GetNextWaypoint,id);q.waypoint=W.Point(m,x,y)
            q.fingerprint=table.concat(fingerprint,"/");sig[#sig+1]=q.fingerprint
            state.activeQuests[#state.activeQuests+1]=q;state.activeByID[id]=q
        end
    end
    state.completedCount=W.Count(p.completed);state.signature=table.concat(sig,"|")..":"..state.completedCount
    state.logLimit=type(MAX_QUESTLOG_QUESTS)=="number" and MAX_QUESTLOG_QUESTS or 25
    state.freeSlots=math.max(0,state.logLimit-#state.activeQuests)
    W.State=state;return state
end
function W.ObserveQuest(id,title,kind)
    if type(id)~="number" or id<=0 then return end
    local p=W.GetProfile();local point=W.PlayerPoint();local npc=W.Safe(UnitName,"npc") or "Quest giver"
    if point and W.Safe(UnitName,"npc") then p.locations[kind..":"..id]={mapID=point.mapID,x=point.x,y=point.y,name=npc,seen=W.Now()} end
    if kind=="pickup" then p.offers[id]={title=title,seen=W.Now()} end
end
function W.ObserveGossip()
    local g=C_GossipInfo or {}
    local available=W.Safe(g.GetAvailableQuests)
    local offered={}
    for _,q in ipairs(available or {}) do
        if type(q.questID)=="number" and q.questID>0 then W.ObserveQuest(q.questID,q.title,"pickup");offered[q.questID]=true end
    end
    local guid=W.Safe(UnitGUID,"npc") or ""
    local npcID=tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
    if npcID and type(available)=="table" then W.GetProfile().gossip[npcID]={offers=offered,seen=W.Now(),signature=W.State and W.State.signature} end
    for _,q in ipairs(W.Safe(g.GetActiveQuests) or {}) do if q.isComplete==true or q.isComplete==1 then W.ObserveQuest(q.questID,q.title,"turnin") end end
end
function W.SkipCurrent()
    local r=W.CurrentRoute
    if r and r.key then local p=W.GetProfile();local key=r.questID and ("quest:"..r.questID) or r.key;p.skipped[key]=W.Now()+900;p.lastSkipped=key;p.pinned=nil;W.CurrentRoute=nil;W.Refresh(true) end
end
function W.UndoSkip()
    local p=W.GetProfile();if p.lastSkipped then p.skipped[p.lastSkipped]=nil;p.lastSkipped=nil end;W.Refresh(true)
end
