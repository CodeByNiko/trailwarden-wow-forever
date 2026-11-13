-- Deterministic game/client doubles; no live gameplay claims.
unpack=unpack or table.unpack;loadstring=loadstring or load;math.atan2=math.atan2 or function(y,x) return math.atan(y,x) end
local player={guid="Player-NE",name="Raelorn",class="WARRIOR",className="Warrior",race=4,raceName="Night Elf",map=1438,x=.56,y=.6,level=7}
local epoch=100000;local tasks={};local log={};local complete={};local inventory={};local npcName="NPC";local offers={}
local frames={};local nodes={}
local methods={}
local function region(kind,parent,name)
    local r={kind=kind,parent=parent,name=name,shown=true,scripts={},text="",w=0,h=0,points={}}
    setmetatable(r,{__index=methods});nodes[#nodes+1]=r
    if name then frames[name]=r end
    return r
end
function methods:SetPoint(...) self.points[#self.points+1]={...} end
function methods:ClearAllPoints() self.points={} end
function methods:GetPoint() local p=self.points[1] or {"CENTER",nil,"CENTER",0,0};return unpack(p) end
function methods:SetSize(w,h) self.w=w;self.h=h end
function methods:SetWidth(w) self.w=w end
function methods:SetHeight(h) self.h=h end
function methods:GetHeight() return self.h end
function methods:SetText(t) self.text=t or "" end
function methods:GetText() return self.text end
function methods:SetFont(path,size) self.fontSize=size end
function methods:GetStringWidth() return #self.text*(self.fontSize or 10)*.52 end
function methods:GetStringHeight()
 return math.max(1,math.ceil(#self.text*(self.fontSize or 10)*.52/math.max(1,self.w)))*(self.fontSize or 10)*1.2
end
function methods:SetTextColor(...) self.textColor={...} end
function methods:SetBackdropColor(...) self.bgColor={...} end
function methods:SetColorTexture(...) self.bgColor={...} end
function methods:SetTexture(t) self.texture=t end
function methods:SetVertexColor(...) self.vertexColor={...} end
function methods:SetRotation(a) self.rotation=a end
function methods:SetScale(s) self.scale=s end
function methods:SetShown(v) self.shown=v==true end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetEnabled(v) self.enabled=v end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:RegisterEvent(e) self.events=self.events or {};self.events[e]=true end
function methods:CreateFontString(name) return region("font",self,name) end
function methods:CreateTexture(name) return region("texture",self,name) end
function methods:SetScrollChild(v) self.scrollChild=v end
for _,m in ipairs({"EnableMouseWheel","SetFrameStrata","SetToplevel","SetClampedToScreen","SetMovable","EnableMouse","RegisterForDrag","SetBackdrop","SetBackdropBorderColor","SetJustifyH","SetJustifyV","SetWordWrap","SetAllPoints","StartMoving","StopMovingOrSizing","SetMultiLine","SetAutoFocus","SetFontObject","SetFocus","HighlightText"}) do methods[m]=function() end end
function methods:SetFrameStrata(value) self.strata=value end
function methods:SetToplevel(value) self.toplevel=value end
function methods:SetJustifyH(value) self.justifyH=value end
function methods:SetJustifyV(value) self.justifyV=value end
function methods:SetWordWrap(value) self.wordWrap=value end
UIParent=region("frame",nil,"UIParent");UIParent:SetSize(1920,1080)
ChatFontNormal={};SlashCmdList={}
function CreateFrame(kind,name,parent) return region(kind,parent,name) end
function CreateVector2D(x,y) return {x=x,y=y,GetXY=function(self) return self.x,self.y end} end
function UnitGUID(unit) if unit=="player" then return player.guid end if unit=="npc" and npcName then return "Creature-0-0-0-0-100-1" end end
function UnitName(unit) return unit=="player" and player.name or npcName end
function UnitClass() return player.className,player.class,player.class=="WARRIOR" and 1 or 7 end
function UnitRace() return player.raceName,player.raceName,player.race end
function UnitLevel() return player.level end
function GetRealmName() return "Forever" end
function UnitFactionGroup() return "Alliance" end
function UnitIsDeadOrGhost() return player.dead or false end
function GetServerTime() return epoch end
function GetPlayerFacing() return player.facing or 0 end
function GetItemCount(id) return inventory[id] or 0 end
local mapNames={[1438]="Teldrassil",[1431]="Duskwood",[1439]="Darkshore"}
local maps={[1438]={c=1,ox=10000,oy=10000,w=5000,h=3000},[1431]={c=0,ox=0,oy=0,w=6000,h=4000},[1439]={c=1,ox=10000,oy=4000,w=5000,h=6000}}
local waypoint,clearCount,setCount=nil,0,0
C_Map={
 GetBestMapForUnit=function() return player.map end,
 GetMapInfo=function(id) return {name=mapNames[id] or "Map",mapType=3} end,
 GetPlayerMapPosition=function() if player.noPosition then return nil end return CreateVector2D(player.x,player.y) end,
 GetWorldPosFromMapPos=function(id,p) local m=maps[id];if not m then return nil end return m.c,CreateVector2D(m.ox-p.y*m.h,m.oy-p.x*m.w) end,
 SetUserWaypoint=function(p) waypoint=p;setCount=setCount+1 end,
 GetUserWaypoint=function() return waypoint end,
 ClearUserWaypoint=function() waypoint=nil;clearCount=clearCount+1 end,
 CanSetUserWaypointOnMap=function() return true end,
}
C_SuperTrack={SetSuperTrackedUserWaypoint=function() end}
UiMapPoint={CreateFromCoordinates=function(map,x,y) return {uiMapID=map,position=CreateVector2D(x,y)} end}
C_Navigation={GetDistance=function() return 999999 end}
C_Timer={After=function(_,fn) tasks[#tasks+1]=fn end}
C_QuestLog={
 GetNumQuestLogEntries=function() return #log end,
 GetInfo=function(i) local q=log[i];if not q then return nil end return {questID=q.id,title=q.title or "Test quest",level=q.level or 7,isComplete=q.complete or false} end,
 GetQuestObjectives=function(id) for _,q in ipairs(log) do if q.id==id then return q.rows or {} end end return {} end,
 IsComplete=function(id) for _,q in ipairs(log) do if q.id==id then return q.complete or false end end end,
 GetAllCompletedQuestIDs=function() return complete end,
 GetNextWaypoint=function(id) for _,q in ipairs(log) do if q.id==id and q.wp then return unpack(q.wp) end end end,
}
C_GossipInfo={GetAvailableQuests=function() return offers end,GetActiveQuests=function() return {} end}
local quests={
 [1]={name="Shaman path",requiredLevel=20,questLevel=22,requiredClasses=64,requiredRaces=4,startedBy={{100}}},
 [2]={name="Warrior training",requiredLevel=5,questLevel=7,requiredClasses=1,requiredRaces=8,startedBy={{201}},finishedBy={{201}},objectives={{{301}}}},
 [10]={name="The Night Watch",requiredLevel=18,questLevel=23,startedBy={{100}},finishedBy={{100}},objectives={{{300}}}},
 [11]={name="Night Watch follow-up",requiredLevel=18,questLevel=23,startedBy={{100}},preQuestSingle={10}},
 [12]={name="Darkshire supplies",requiredLevel=18,questLevel=22,startedBy={{101}}},
 [13]={name="Group threat",requiredLevel=18,questLevel=23,startedBy={{102}}},
 [14]={name="Too dangerous",requiredLevel=20,questLevel=30,startedBy={{100}}},
 [15]={name="Gather wolf pelts",requiredLevel=18,questLevel=22,startedBy={{100}},finishedBy={{100}},objectives={[3]={{400}}}},
 [16]={name="Delivery",requiredLevel=1,questLevel=7,finishedBy={{201}}},
 [17]={name="PvP marks",questLevel=7,objectives={{{301}}}},
 [18]={name="Repeatable",requiredLevel=1,questLevel=7,startedBy={{201}},specialFlags=1},
 [19]={name="Completed elite",questLevel=40,finishedBy={{201}}},
 [21]={name="Other race",requiredLevel=1,questLevel=7,requiredRaces=4,startedBy={{201}}},
 [22]={name="Other class",requiredLevel=1,questLevel=7,requiredClasses=64,startedBy={{201}}},
 [23]={name="Prerequisite locked",requiredLevel=1,questLevel=7,preQuestSingle={24},startedBy={{201}}},
 [24]={name="Prerequisite",questLevel=7},
 [25]={name="All prerequisites",questLevel=7,preQuestGroup={24,26},startedBy={{201}}},
 [26]={name="Second prerequisite",questLevel=7},
 [27]={name="Exclusive",questLevel=7,exclusiveTo={2},startedBy={{201}}},
 [28]={name="Future level",requiredLevel=8,questLevel=8,startedBy={{201}}},
 [29]={name="Old quest",requiredLevel=1,questLevel=1,startedBy={{201}}},
 [31]={name="Two items",questLevel=7,objectives={[3]={{401},{402}}},finishedBy={{201}}},
 [32]={name="Two creatures",questLevel=7,objectives={{{301},{302}}},finishedBy={{201}}},
 [34]={name="Negative prerequisite",questLevel=7,preQuestGroup={-24},startedBy={{201}}},
 [36]={name="Object starter",questLevel=7,startedBy={[2]={500}},finishedBy={[2]={500}}},
 [37]={name="Item starter",questLevel=7,startedBy={[3]={900}}},
 [39]={name="Unknown reputation",questLevel=7,requiredMinRep={1,3000},startedBy={{201}}},
}
local npcs={
 [100]={name="Commander",spawns={[10]={{73,46}}}},[101]={name="Shopkeeper",spawns={[10]={{74,46}}}},[102]={name="Group NPC",spawns={[10]={{74,47}}}},
 [201]={name="Elven trainer",spawns={[20]={{56,60}}}},[300]={name="Skeleton",spawns={[10]={{65,60},{64,59}}}},
 [301]={name="Forest creature",spawns={[20]={{60,60},{61,61}}}},[302]={name="Webwood spider",spawns={[20]={{70,65}}}},
}
local items={[400]={name="Wolf pelt",npcDrops={300}},[401]={name="First item",npcDrops={301}},[402]={name="Second item",objectDrops={501}},[900]={name="Quest letter"}}
local objects={[500]={name="Ancient sign",spawns={[20]={{57,60}}}},[501]={name="Quest chest",spawns={[20]={{70,65}}}}}
quests[40]={name="Similar creature names",questLevel=7,objectives={{{303},{304}}}}
quests[41]={name="Vendor supplies",questLevel=7,objectives={[3]={{403}}}}
npcs[303]={name="Wolf",spawns={[20]={{58,60}}}}
npcs[304]={name="Dire Wolf",spawns={[20]={{68,60}}}}
npcs[202]={name="Quartermaster",spawns={[20]={{57,61}}}}
items[403]={name="Supply pack",vendors={202}}
for id,row in pairs(npcs) do row.minLevel=id==300 and 22 or 7;row.maxLevel=row.minLevel end
local numeric={minLevel=true,maxLevel=true,sourceItemId=true,zoneOrSort=true,nextQuestInChain=true,parentQuest=true,breadcrumbForQuestId=true,availableUntilCompleted=true,availableStartingWith=true,disabledByQuest=true,requiredLevel=true,questLevel=true,requiredRaces=true,requiredClasses=true,requiredMaxLevel=true,requiredSpell=true,requiredSpecialization=true,specialFlags=true,questFlags=true,rank=true}
local function db(data)
 return {Get=function(id,key) local r=data[id];if not r then return nil end if r[key]~=nil then return r[key] end if numeric[key] then return 0 end if key=="startedBy" or key=="finishedBy" or key=="objectives" then return {} end end,
 GetAllIds=function() local ids={} for id in pairs(data) do ids[#ids+1]=id end table.sort(ids);return ids end}
end
LibQuestieDB={Quest=db(quests),Npc=db(npcs),Item=db(items),Object=db(objects),contractVersion=4,RequireContract=function() return true end,
 Enum={raceMaskById={[3]=4,[4]=8}},Support={Get=function() return {private={areaIdToUiMapId="return { [10]=1431, [20]=1438, [30]=1439 }"}} end}}
local qmodule={IsGroupQuest=function(id) return id==13 or id==19 end,IsPvPQuest=function(id) return id==17 end,
 IsRaidQuest=function() return false end,IsDungeonQuest=function() return false end,IsRepeatable=function() return false end,
 IsDailyQuest=function() return false end,IsWeeklyQuest=function() return false end,
 IsDoable=function(id) if id==39 then return nil end for _,q in ipairs(log) do if q.id==id then return false end end return true end}
QuestieLoader={ImportModule=function(_,name) if name=="QuestieDB" then return qmodule end end}
for _,file in ipairs({"Common","Locale","Data","Provider","Tracking","Database","Safety","Experience","Planner","UI","Travel","Navigator","RouteOverlay","Replay","Diagnostics","Scheduler","Core","Commands"}) do dofile("Trailwarden/"..file..".lua") end
local W=Trailwarden
local now=200000;local timers={};local counts={}
GetServerTime=function() return math.floor(now) end;GetTime=function() return now end
InCombatLockdown=function() return false end;UnitAffectingCombat=function() return false end
UnitIsAFK=function() return false end;GetUnitSpeed=function() return 0 end
C_Timer={After=function(delay,fn) timers[#timers+1]={at=now+delay,fn=fn} end}
debugprofilestop=function() return os.clock()*1000 end
C_AreaPoiInfo={GetAreaPOIInfo=function() return nil end}
UnitXP=function() return 100 end;UnitXPMax=function() return 1000 end
player.level=22;player.map=1431;player.x=.73;player.y=.46
log={{id=10,title='The Night Watch',level=23,rows={{type='monster',objectiveID=300,text='Skeleton slain: 0/6',numFulfilled=0,numRequired=6}}}}
local case=os.getenv('IDLE_CASE') or 'baseline'
if case=='populated' then
 local guid=UnitGUID;UnitGUID=function(unit) if unit=='player' then return guid(unit) elseif unit:match('nameplate') then return 'Creature-0-0-0-0-300-1' end end
 UnitClassification=function() return 'normal' end;UnitCanAttack=function() return true end;UnitIsVisible=function() return true end
 for i=1,40 do W.TrackCombatUnit('NAME_PLATE_UNIT_ADDED','nameplate'..i) end
end
W.BuildQuestCatalog()
while #timers>0 do local t=table.remove(timers,1);now=math.max(now,t.at);t.fn() end
W.CreateUI();W.CreateNavigator();W.PollCombatSafety();W.Refresh(true,'idle-baseline')
while #timers>0 do local t=table.remove(timers,1);now=math.max(now,t.at);t.fn() end
assert(not W.LastError,W.LastError);assert(W.CurrentRoute.point,'No route point')
local function wrap(owner,key,label)
 local original=owner[key];if type(original)~='function' then return end
 owner[key]=function(...) counts[label]=(counts[label] or 0)+1;return original(...) end
end
for _,key in ipairs({'GetMapInfo','GetBestMapForUnit','GetPlayerMapPosition','GetWorldPosFromMapPos','SetUserWaypoint','ClearUserWaypoint'}) do wrap(C_Map,key,'API '..key) end
wrap(C_AreaPoiInfo,'GetAreaPOIInfo','API GetAreaPOIInfo')
for _,key in ipairs({'SetText','SetFont','SetRotation','SetShown','SetSize','SetPoint','GetStringHeight'}) do wrap(methods,key,'UI '..key) end
for _,key in ipairs({'Refresh','ReadCharacter','PreparePlanInput','SelectRoute','ReadAccess','ReadWorkArea','PlayerPoint','Point','PollCombatSafety','UpdateUI','UpdateLiveUI','UpdateNavigator','UpdateRouteOverlay','SyncWaypoint','SampleExperience','ExperienceStats','GetProfile'}) do wrap(W,key,key) end
if case=='no-access' then W.ReadAccess=function(route) return {mode='direction',navRoute=route,goal=route and route.point} end end
if case=='no-navigation-UI' then W.UpdateNavigation=function() end;W.UpdateLiveUI=function() end;W.UpdateNavigator=function() end end
if case=='no-planner' then W.Refresh=function() end end
if case=='anchored' then local p=W.GetProfile();p.panelPoint={point='CENTER',relativePoint='CENTER',x=0,y=0};p.navigatorPoint={point='CENTER',relativePoint='CENTER',x=0,y=0} end
if case=='hidden' then local p=W.GetProfile();p.panelHidden=true;p.navigatorHidden=true;W.MainFrame:Hide();W.NavigatorFrame:Hide() end
local plans=W.PlanExecutions;local captures=W.WorkCounters.captures;local seconds=125
counts={};W.WorkTimings={};W.SlowestWork=nil
collectgarbage('collect');local base=collectgarbage('count');collectgarbage('stop');local start=os.clock()
for i=1,seconds*60 do
 now=now+1/60
 if i%60==0 and (case=='quest-noise' or case=='coalesced-noise') then W.EventFrame.scripts.OnEvent(W.EventFrame,'QUEST_LOG_UPDATE');if case=='coalesced-noise' then W.EventFrame.scripts.OnEvent(W.EventFrame,'UPDATE_FACTION') end end
 W.EventFrame.scripts.OnUpdate(W.EventFrame,1/60)
 local pending=timers;timers={}
 for _,t in ipairs(pending) do if t.at<=now then t.fn() else timers[#timers+1]=t end end
end
local allocated=collectgarbage('count')-base;local elapsed=(os.clock()-start)*1000
collectgarbage('restart');collectgarbage('collect');local retained=collectgarbage('count')-base
assert(not W.LastError,W.LastError);assert(next(W.OutputErrors or {})==nil,'Output failed')
print('CASE '..case..' '.._VERSION..' simulated_seconds='..seconds..' plans='..(W.PlanExecutions-plans)..' captures='..(W.WorkCounters.captures-captures))
print(string.format('CPU=%.2fms allocated=%.1fKiB retained=%.1fKiB',elapsed,allocated,retained))
local labels={};for label in pairs(counts) do labels[#labels+1]=label end;table.sort(labels)
for _,label in ipairs(labels) do print(label..'='..counts[label]) end
for label,row in pairs(W.WorkTimings) do print(string.format('SECTION %s calls=%d total=%.2f peak=%.2f',label,row.calls,row.total,row.peak)) end

if case=="baseline" then
 assert(W.PlanExecutions==plans,'idle period unexpectedly replanned')
 assert((counts.ReadAccess or 0)<=2,'idle repeatedly resolved cave access')
 assert((counts['UI SetFont'] or 0)<=2,'idle repeatedly changed fonts')
 assert((counts['UI SetText'] or 0)<=20,'idle repeatedly wrote UI text')
end
