local W=Wayfinder
local labels={pickup="Accept: ",turnin="Turn in: ",objective="Quest: ",deliver="Speak about: ",item="Start: "}
local function makeStep(kind,q,point,target,suffix,source,objectiveText)
    local name=q.title or q.name or W.Q(q.id,"name") or ("Quest "..q.id)
    local instruction
    if kind=="pickup" then instruction="Speak with "..target.." and accept this quest. The next step appears when it enters your quest log."
    elseif kind=="turnin" then instruction="Return to "..target.." and turn in this completed quest. Follow-up quests are considered after turn-in."
    elseif kind=="deliver" then instruction="Speak with "..target.." to continue this delivery or conversation quest."
    elseif kind=="item" then instruction="Use "..target.." in your bags to begin this quest."
    else instruction=objectiveText or ("Work around "..target.." until the quest objective updates.") end
    return {kind=kind,key=W.StepKey(kind,q.id,suffix),questID=q.id,questName=name,title=(labels[kind] or "")..name,point=point,
        mapID=point and point.mapID,x=point and point.x,y=point and point.y,target=target,instruction=instruction,source=source or "QuestieDB",level=q.level or W.Q(q.id,"questLevel"),fingerprint=q.fingerprint}
end
local function observedPoint(id,kind,state)
    local l=state.profile.locations[kind..":"..id]
    if l then local p=W.Point(l.mapID,l.x,l.y);if p then p.name=l.name;return p end end
end
local function relationPoint(q,field,kind,state)
    local seen=observedPoint(q.id,kind,state)
    if seen then return seen,"Observed in game" end
    return W.NearestPoint(W.RelationPoints(q.id,field),state.player,state.mapID),"QuestieDB"
end
local typeName={[1]="monster",[2]="object",[3]="item"}
local function objectiveFinished(q,group,index,entry,entries)
    local kind=typeName[group]
    local entityKind=group==1 and "Npc" or group==2 and "Object" or "Item"
    local typed={}
    for _,row in ipairs(q.objectives) do if row.type==kind then typed[#typed+1]=row end end
    local assigned,used={},{}
    for rowIndex,row in ipairs(typed) do
        local winner,length,tied=nil,0,false
        for i,candidate in ipairs(entries) do
            local name=W.DBGet(entityKind,candidate[1],"name")
            if name and name~="" and string.find(string.lower(row.text),string.lower(name),1,true) then
                if #name>length then winner,length,tied=i,#name,false elseif #name==length then tied=true end
            end
        end
        if winner and not tied and not assigned[winner] then assigned[winner]=row;used[rowIndex]=true end
    end
    if #typed==#entries then
        local missingEntries,missingRows={},{}
        for i=1,#entries do if not assigned[i] then missingEntries[#missingEntries+1]=i end end
        for i,row in ipairs(typed) do if not used[i] then missingRows[#missingRows+1]=row end end
        if #missingEntries==1 and #missingRows==1 then assigned[missingEntries[1]]=missingRows[1]
        elseif #missingEntries==#entries then
            -- If no names are available, retain the provider's type-local order.
            for i,row in ipairs(typed) do assigned[i]=row end
        end
    end
    local row=assigned[index]
    return row and row.finished or false,row and row.text
end
local function entityObjectivePoints(kind,id,state)
    if kind=="Npc" and not state.profile.includeGroup then
        local rank=W.DBGet("Npc",id,"rank") or 0
        if rank==1 or rank==2 or rank==3 then return {} end
    end
    return W.EntityPoints(kind,id)
end
local function itemPoints(id,state)
    local out={}
    for field,kind in pairs({npcDrops="Npc",objectDrops="Object",vendors="Npc"}) do
        for _,entityID in ipairs(W.DBGet("Item",id,field) or {}) do
            for _,point in ipairs(entityObjectivePoints(kind,entityID,state)) do
                local source={};for k,v in pairs(point) do source[k]=v end
                source.acquisition=field;out[#out+1]=source
            end
        end
    end
    return out
end
local function spawnPoints(spawns)
    local out={}
    for area,coords in pairs(spawns or {}) do
        local m=W.MapForArea(area)
        for _,c in ipairs(coords) do local p=W.Point(m,c[1],c[2]);if p then out[#out+1]=p end end
    end
    return out
end
function W.ActiveSteps(q,state)
    local out={}
    if q.isComplete then
        local p,source=relationPoint(q,"finishedBy","turnin",state)
        p=p or q.waypoint
        if p then out[1]=makeStep("turnin",q,p,p.name or "the quest receiver","",source) end
        return out
    end
    local objectives=W.Q(q.id,"objectives") or {}
    for group=1,3 do
        local entries=objectives[group] or {}
        for i,entry in ipairs(entries) do
            local finished,text=objectiveFinished(q,group,i,entry,entries)
            if not finished then
                local kind=group==1 and "Npc" or "Object"
                local points=group==3 and itemPoints(entry[1],state) or entityObjectivePoints(kind,entry[1],state)
                local p=W.NearestPoint(points,state.player,state.mapID)
                if p then
                    local target=W.DBGet(group==3 and "Item" or kind,entry[1],"name") or p.name or "the objective area"
                    local detail=text or (group==1 and "Defeat " or group==2 and "Interact with " or "Collect ")..target.."."
                    if group==3 then
                        local action=p.acquisition=="vendors" and "Buy from " or p.acquisition=="objectDrops" and "Search " or "Defeat "
                        detail=(text and (text..". ") or ("Collect "..target..". "))..action..(p.name or "the source").."."
                    end
                    out[#out+1]=makeStep("objective",q,p,target,typeName[group]..":"..entry[1],"QuestieDB",detail)
                end
            end
        end
    end
    -- Kill-credit objectives can credit several creature types.
    for i,entry in ipairs(objectives[5] or {}) do
        local live=entry[4] and entry[4]>0 and q.objectives[entry[4]]
        if not live or not live.finished then
            local points={}
            for _,id in ipairs(entry[1] or {}) do for _,p in ipairs(entityObjectivePoints("Npc",id,state)) do points[#points+1]=p end end
            local p=W.NearestPoint(points,state.player,state.mapID)
            if p then out[#out+1]=makeStep("objective",q,p,p.name or "the target","credit:"..i,"QuestieDB",live and live.text) end
        end
    end
    local trigger=W.Q(q.id,"triggerEnd")
    if #out==0 and trigger and trigger[2] then
        local p=W.NearestPoint(spawnPoints(trigger[2]),state.player,state.mapID)
        if p then out[#out+1]=makeStep("objective",q,p,"the quest event","event","QuestieDB",trigger[1]) end
    end
    if #out==0 then
        for i,extra in ipairs(W.Q(q.id,"extraObjectives") or {}) do
            local live=extra[4] and extra[4]>0 and q.objectives[extra[4]]
            if not live or not live.finished then
                local points=spawnPoints(extra[1])
                for _,ref in ipairs(extra[5] or {}) do
                    local kind=ref[1]=="monster" and "Npc" or ref[1]=="object" and "Object"
                    if kind then for _,p in ipairs(entityObjectivePoints(kind,ref[2],state)) do points[#points+1]=p end end
                end
                local p=W.NearestPoint(points,state.player,state.mapID)
                if p then out[#out+1]=makeStep("objective",q,p,p.name or "the quest area","extra:"..i,"QuestieDB",extra[3]) end
            end
        end
    end
    if #out==0 and q.waypoint then out[1]=makeStep("objective",q,q.waypoint,"the next quest target","client","Client waypoint") end
    local hasDBObjectives=next(objectives)~=nil or trigger or W.Q(q.id,"extraObjectives")
    if #out==0 and #q.objectives==0 and not hasDBObjectives then
        local p,source=relationPoint(q,"finishedBy","turnin",state)
        if p then out[1]=makeStep("deliver",q,p,p.name or "the quest receiver","",source) end
    end
    return out
end
local function appendPickups(out,mapID,state)
    local seen={}
    local function add(id,name)
        if seen[id] or not W.IsQuestAvailable(id,state) then return end
        seen[id]=true
        local p,source=relationPoint({id=id},"startedBy","pickup",state)
        if p and p.mapID==mapID then out[#out+1]=makeStep("pickup",{id=id,title=name},p,p.name or "the quest giver","",source) end
    end
    for _,record in ipairs((W.CatalogByMap or {})[mapID] or {}) do
        if record.minLevel<=state.level and (record.level==0 or record.level>=state.level-6) and record.level<=state.level+state.profile.maxLevelAbove then add(record.id,record.name) end
    end
    for id,offer in pairs(state.profile.offers) do if W.Now()-offer.seen<300 then add(id,offer.title) end end
end
local function itemPickups(out,state)
    for _,e in ipairs(W.ItemQuests or {}) do
        if e.record.minLevel<=state.level and W.IsQuestAvailable(e.record.id,state) then
            for _,id in ipairs(e.items) do
                local count=(C_Item and W.Safe(C_Item.GetItemCount,id)) or W.Safe(GetItemCount,id) or 0
                if count>0 then
                    out[#out+1]=makeStep("item",e.record,nil,W.DBGet("Item",id,"name") or "the quest-starting item","","Inventory")
                    break
                end
            end
        end
    end
end
local function score(c,state,all)
    local d=W.TravelCost(state.player,c.point)
    if c.kind=="item" then d=0 end
    c.distance=W.Distance(state.player,c.point);c.cluster=0
    if c.point then
        local seen={}
        for _,other in ipairs(all) do
            if other.questID~=c.questID and other.point and W.TravelCost(c.point,other.point)<300 and not seen[other.questID] then
                c.cluster=c.cluster+1;seen[other.questID]=true
            end
        end
    end
    local s=d
    if c.kind=="turnin" then s=d*0.8-450
    elseif c.kind=="pickup" then s=d*0.95+180;if d<350 then s=s-420 end
    elseif c.kind=="deliver" then s=d*0.9+30
    elseif c.kind=="item" then s=-800
    else s=d+70 end
    s=s-math.min(c.cluster,4)*65
    if c.point and c.mapID~=state.mapID then s=s+800 end
    if (W.Q(c.questID,"requiredClasses") or 0)>0 then s=s-60 end
    if state.freeSlots<3 and c.kind=="turnin" then s=s-500 end
    c.score=s
    c.reason=c.kind=="turnin" and "Ready to hand in; this may open the next part of its chain."
        or c.kind=="pickup" and "Gather a nearby quest before leaving this quest hub."
        or c.kind=="item" and "A quest-starting item is already in your bags."
        or "Continue a quest already in your log."
    if c.cluster>0 then c.reason=c.reason.." "..c.cluster.." other quest step(s) are in this area." end
end
local function fallback(state)
    local text
    if not W.CatalogReady then text=(W.DatabaseStatus or "Waiting for quest data")..(W.BuildingCatalog and (" ("..(W.CatalogProgress or 0).."%)") or "")
    elseif state.freeSlots==0 then text="Your quest log is full. Turn in a quest, or use Questie to review quests you no longer want."
    elseif W.Unmapped and #W.Unmapped>0 then text="Some active quests have no usable target or are outside your comfort settings. Use Questie for their details, or enable group/harder quests in Settings."
    else text="No eligible mapped quest step is available here. Speak with a quest giver so Wayfinder can learn the live offer, or refresh after updating QuestieDB." end
    return {kind="wait",key="wait",title="Finding your next quest",instruction=text,reason="Progress is read from this character's quest log and completed quests.",target=state.zone}
end
function W.PlanRoute(state,force)
    state=state or W.State
    if state.profile.paused then return {kind="wait",key="paused",title="Route paused",instruction="Resume when you want Wayfinder to plan your next quest step.",reason="Your quest progress is still recorded."},{} end
    if state.dead then return {kind="wait",key="dead",title="Return to your character",instruction="Quest navigation resumes after you are alive again.",reason="Your current quest step is preserved."},{} end
    local out={};W.Unmapped={}
    for _,q in ipairs(state.activeQuests) do
        local allowed,why=W.QuestPolicy(q.id,state,true)
        if q.isComplete or (allowed and not q.failed) then
            local steps=W.ActiveSteps(q,state)
            for _,c in ipairs(steps) do out[#out+1]=c end
            if #steps==0 then W.Unmapped[#W.Unmapped+1]={id=q.id,title=q.title,reason="No mapped target"} end
        else W.Unmapped[#W.Unmapped+1]={id=q.id,title=q.title,reason=why or "Failed quest"} end
    end
    if state.freeSlots>0 then appendPickups(out,state.mapID,state);itemPickups(out,state) end
    local localActions=0
    for _,c in ipairs(out) do if c.mapID==state.mapID or c.kind=="item" then localActions=localActions+1 end end
    -- Only consider changing questing zones when the present zone has no useful steps.
    if localActions==0 and state.freeSlots>0 and W.CatalogReady then
        local zone=W.Zones[state.mapID]
        local maps={};for _,id in ipairs(zone and zone.next or {}) do maps[id]=true end
        if next(maps)==nil then
            for id,z in pairs(W.Zones) do if zone and z.region==zone.region and z.min<=state.level and z.max>=state.level then maps[id]=true end end
        end
        for id in pairs(maps) do if id~=state.mapID then appendPickups(out,id,state) end end
    end
    local candidates={}
    for _,c in ipairs(out) do
        local skipped=state.profile.skipped[c.key] or state.profile.skipped["quest:"..c.questID]
        if not skipped or skipped<=W.Now() then candidates[#candidates+1]=c end
    end
    local previous=W.CurrentRoute
    for _,c in ipairs(candidates) do
        if previous and previous.key==c.key and c.kind=="objective" and previous.fingerprint==c.fingerprint then
            c.point=previous.point;c.mapID=previous.mapID;c.x=previous.x;c.y=previous.y
        end
        score(c,state,candidates)
    end
    table.sort(candidates,function(a,b) if a.score~=b.score then return a.score<b.score end return a.key<b.key end)
    local best=candidates[1]
    local pinFound=false
    for _,c in ipairs(candidates) do
        if state.profile.pinned==c.key then best=c;pinFound=true end
    end
    if state.profile.pinned and not pinFound then state.profile.pinned=nil end
    if not state.profile.pinned and not force and previous and best then
        for _,c in ipairs(candidates) do
            if c.key==previous.key and c.score<=best.score+math.max(120,math.abs(best.score)*0.18) then best=c;break end
        end
    end
    if not best then return fallback(state),{} end
    local queue={};local used={[best.questID]=true};local from=best.point or state.player
    for _=1,4 do
        local nextStep,nextScore
        for _,c in ipairs(candidates) do
            if not used[c.questID] then
                local s=W.TravelCost(from,c.point)+c.score*0.25
                if not nextStep or s<nextScore then nextStep,nextScore=c,s end
            end
        end
        if not nextStep then break end
        queue[#queue+1]=nextStep;used[nextStep.questID]=true;from=nextStep.point or from
    end
    return best,queue
end
function W.PinStep(step)
    if step then W.GetProfile().pinned=step.key;W.CurrentRoute=nil;W.Refresh(true) end
end
