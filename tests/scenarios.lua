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
function methods:SetText(t) self.text=t or "" end
function methods:SetFont(path,size) self.fontSize=size end
function methods:GetStringHeight()
 return math.max(1,math.ceil(#self.text*(self.fontSize or 10)*.52/math.max(1,self.w)))*(self.fontSize or 10)*1.2
end
function methods:SetTextColor(...) self.textColor={...} end
function methods:SetBackdropColor(...) self.bgColor={...} end
function methods:SetColorTexture(...) self.bgColor={...} end
function methods:SetTexture(t) self.texture=t end
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
for _,m in ipairs({"SetFrameStrata","SetClampedToScreen","SetMovable","EnableMouse","RegisterForDrag","SetBackdrop","SetBackdropBorderColor","SetJustifyH","SetJustifyV","SetWordWrap","SetAllPoints","StartMoving","StopMovingOrSizing","SetMultiLine","SetAutoFocus","SetFontObject","SetFocus","HighlightText"}) do methods[m]=function() end end
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
local numeric={requiredLevel=true,questLevel=true,requiredRaces=true,requiredClasses=true,requiredMaxLevel=true,requiredSpell=true,requiredSpecialization=true,specialFlags=true,questFlags=true,rank=true}
local function db(data)
 return {Get=function(id,key) local r=data[id];if not r then return nil end if r[key]~=nil then return r[key] end if numeric[key] then return 0 end if key=="startedBy" or key=="finishedBy" or key=="objectives" then return {} end end,
 GetAllIds=function() local ids={} for id in pairs(data) do ids[#ids+1]=id end table.sort(ids);return ids end}
end
LibQuestieDB={Quest=db(quests),Npc=db(npcs),Item=db(items),Object=db(objects),contractVersion=4,RequireContract=function() return true end,
 Enum={raceMaskById={[3]=4,[4]=8}},Support={Get=function() return {private={areaIdToUiMapId="return { [10]=1431, [20]=1438, [30]=1439 }"}} end}}
local qmodule={IsGroupQuest=function(id) return id==13 or id==19 end,IsPvPQuest=function(id) return id==17 end,
 IsDoable=function(id) if id==39 then return nil end for _,q in ipairs(log) do if q.id==id then return false end end return true end}
QuestieLoader={ImportModule=function(_,name) if name=="QuestieDB" then return qmodule end end}
for _,file in ipairs({"Common","Data","Tracking","Database","Planner","UI","Navigator","Core"}) do dofile("Wayfinder/"..file..".lua") end
local W=Wayfinder
local passed=0
function methods:StartMoving() self.moves=(self.moves or 0)+1 end
local function button(prefix)
 for _,n in ipairs(nodes) do if n.kind=="Button" and n.label and n.label.text:sub(1,#prefix)==prefix then return n end end
 error("Button not found: "..prefix)
end
local function check(name,condition) assert(condition,"FAILED: "..name);passed=passed+1;print("PASS "..name) end
local function drain() local n=0 while #tasks>0 do local fn=table.remove(tasks,1);fn();n=n+1;assert(n<2000,"timer loop") end end
local function scan() W.CurrentRoute=nil;return W.ScanCharacter() end
local function plan(force) W.Refresh(force~=false);return W.CurrentRoute end
local function ne()
 player.guid="Player-NE";player.name="Raelorn";player.class="WARRIOR";player.className="Warrior";player.race=4;player.raceName="Night Elf";player.map=1438;player.level=7;player.x=.56;player.y=.60;log={};complete={};inventory={};W.CurrentRoute=nil
end
local function dwarf()
 player.guid="Player-Dwarf";player.name="Ulfgar";player.class="SHAMAN";player.className="Shaman";player.race=3;player.raceName="Dwarf";player.map=1431;player.level=22;player.x=.73;player.y=.46;log={};complete={};inventory={};W.CurrentRoute=nil
end
W.BuildQuestCatalog();drain()
check("catalog is asynchronous and ready",W.CatalogReady and W.CatalogCount==W.Count(quests))
local s=scan()
check("night elf warrior gets own class quest",W.IsQuestAvailable(2,s))
check("night elf never gets shaman route",not W.IsQuestAvailable(1,s) and not W.IsQuestAvailable(22,s))
check("race requirements",not W.IsQuestAvailable(21,s))
check("prerequisites locked",not W.IsQuestAvailable(23,s) and not W.IsQuestAvailable(25,s))
check("level requirements",not W.IsQuestAvailable(28,s))
check("repeatables excluded",not W.IsQuestAvailable(18,s))
check("unknown reputation requirements fail closed",not W.IsQuestAvailable(39,s))
complete={24};s=scan();check("single prerequisite unlocks",W.IsQuestAvailable(23,s) and not W.IsQuestAvailable(25,s))
complete={24,26};s=scan();check("all group prerequisites unlock",W.IsQuestAvailable(25,s) and W.IsQuestAvailable(34,s))
log={{id=2,title="Warrior training",rows={{type="monster",objectiveID=301,text="Forest creature: 0/4",numFulfilled=0,numRequired=4}}}}
s=scan();check("active quest is not offered again",not W.IsQuestAvailable(2,s))
check("exclusive quests excluded",not W.IsQuestAvailable(27,s))
local activeSteps=W.ActiveSteps(log[1].id and s.activeQuests[1],s)
check("objective from database without client waypoint",#activeSteps==1 and activeSteps[1].target=="Forest creature")
-- Completed high-level/group quests can still be turned in in solo mode.
log={{id=19,title="Completed elite",complete=true}};s=scan();local r=plan()
check("turn-ins bypass pickup eligibility and comfort filters",r.kind=="turnin" and r.questID==19)
-- Objective updates select the remaining target rather than a completed one.
log={{id=31,title="Two items",rows={{type="item",objectiveID=401,text="First item",finished=true,numFulfilled=1,numRequired=1},{type="item",objectiveID=402,text="Second item",finished=false,numFulfilled=0,numRequired=1}}}}
s=scan();activeSteps=W.ActiveSteps(s.activeQuests[1],s)
check("finished item objectives removed",#activeSteps==1 and activeSteps[1].target=="Second item" and activeSteps[1].point.entityKind=="Object")
log={{id=32,title="Two creatures",rows={{type="monster",objectiveID=301,text="Forest creature",finished=true},{type="monster",objectiveID=302,text="Webwood spider",finished=false}}}}
s=scan();activeSteps=W.ActiveSteps(s.activeQuests[1],s);check("finished kill objectives removed",#activeSteps==1 and activeSteps[1].target=="Webwood spider")
log={{id=16,title="Delivery"}};s=scan();activeSteps=W.ActiveSteps(s.activeQuests[1],s);check("delivery quests find receiver",activeSteps[1] and activeSteps[1].kind=="deliver")
log={{id=33,title="Forever-only quest",wp={1438,.65,.65},rows={{type="event",text="Find the grove",finished=false}}}};s=scan();activeSteps=W.ActiveSteps(s.activeQuests[1],s);check("unknown quests use client waypoint",activeSteps[1] and activeSteps[1].source=="Client waypoint")
log={};inventory={[900]=1};s=scan();r=plan();check("quest-starting inventory item",r.questID==37 and r.kind=="item");inventory={}
-- Actual gossip offers resolve incomplete Forever race or chain records.
W.ObserveQuest(21,"Observed live offer","pickup");s=scan();check("live offers override stale database restrictions",W.IsQuestAvailable(21,s))
npcName=nil;W.ObserveQuest(999,"Shared quest","pickup");check("shared quest has no invented NPC position",W.GetProfile().locations["pickup:999"]==nil);npcName="NPC"
W.ObserveQuest(27,"A live alternative","pickup");log={{id=2,title="Warrior training"}};s=scan()
check("old live offer cannot override a later exclusive choice",not W.IsQuestAvailable(27,s))
-- Shaman starts mid-zone with accepted quests, rather than at an old route beginning.
dwarf();log={{id=10,title="The Night Watch",level=23,rows={{type="monster",objectiveID=300,text="Skeleton: 0/8",numRequired=8,numFulfilled=0}}}}
s=scan();r=plan();check("darkshire gathers nearby eligible pickups first",r.kind=="pickup" and r.mapID==1431 and r.questID~=14 and r.questID~=13)
local first=r.questID;log[#log+1]={id=first,title=r.questName};W.EventFrame.scripts.OnEvent(W.EventFrame,"QUEST_ACCEPTED",first);drain();r=W.CurrentRoute
check("accepted pickup advances automatically",r.questID~=first or r.kind~="pickup")
-- At capacity, existing objectives win over new pickups.
MAX_QUESTLOG_QUESTS=#log;s=scan();r=plan();check("full quest log suppresses pickups",r.kind~="pickup" and r.kind~="item");MAX_QUESTLOG_QUESTS=nil
check("shaman completion history separated from night elf",not s.completed[24])
W.RememberTurnIn(10);complete={};s=scan();check("turn-in event retained when server snapshot incomplete",s.completed[10])
log={};s=scan();check("chain unlock from turn-in history",W.IsQuestAvailable(11,s))
-- The navigator uses our target, not whichever Blizzard waypoint is tracked.
local playerPoint=W.PlayerPoint();local target=W.Point(1431,player.x+.01,player.y)
local nav=W.NavigationInfo({kind="objective",point=target,mapID=1431,x=target.x,y=target.y})
check("independent distance ignores native navigator",math.abs(nav.distance-60)<.001)
check("east bearing handles WoW world axes",math.abs(nav.bearing-math.pi/2)<.00001)
local north=W.Point(1431,player.x,player.y-.02)
check("north bearing handles aspect ratio",math.abs(W.Bearing(north,playerPoint))<.00001)
check("west bearing",math.abs(W.Bearing(W.Point(1431,player.x-.02,player.y),playerPoint)+math.pi/2)<.00001)
check("south bearing",math.abs(math.abs(W.Bearing(W.Point(1431,player.x,player.y+.02),playerPoint))-math.pi)<.00001)
local cross=W.Point(1438,.5,.5)
check("different continents never invent direction",W.Bearing(cross,playerPoint)==nil)
player.noPosition=true;check("missing position never reuses stale arrow",W.NavigationInfo({point=target,mapID=1431,x=target.x,y=target.y}).bearing==nil);player.noPosition=false
local step={kind="objective",key="navtest",point=target,mapID=1431,x=target.x,y=target.y}
W.SyncWaypoint(step,true);local old=clearCount;W.ReleaseWaypoint();check("owned waypoint cleared",clearCount==old+1)
W.SyncWaypoint(step,true);waypoint=UiMapPoint.CreateFromCoordinates(1431,.2,.2);old=clearCount;W.ReleaseWaypoint();check("another user waypoint is preserved",clearCount==old)
local oldSet=setCount;W.GetProfile().mapSync=false;W.SyncWaypoint(step,true);check("custom navigation does not need map sync",setCount==oldSet and W.NavigationInfo(step).distance~=nil);W.GetProfile().mapSync=true
local movedStep={kind="objective",key="navtest",point=W.Point(1431,.8,.5),mapID=1431,x=.8,y=.5}
W.SyncWaypoint(step,true);oldSet=setCount;W.SyncWaypoint(movedStep,false);check("map waypoint follows a changed target within a step",setCount==oldSet+1)
W.SyncWaypoint(movedStep,false);check("unchanged target does not repeatedly replace map waypoint",setCount==oldSet+1)
-- Skip is character-specific, expires and can be undone.
log={};s=scan();r=plan();local skipped=r.questID;W.SkipCurrent();check("skip removes quest temporarily",not W.CurrentRoute.questID or W.CurrentRoute.questID~=skipped)
W.UndoSkip();check("undo restores skipped quest",W.GetProfile().lastSkipped==nil and W.Count(W.GetProfile().skipped)==0)
W.GetProfile().skipped.test=epoch-1;W.GetProfile();check("expired skips pruned",W.GetProfile().skipped.test==nil)
W.GetProfile().paused=true;plan();check("pause clears actionable route",W.CurrentRoute.key=="paused");W.GetProfile().paused=false
player.dead=true;plan();check("death suspends quest navigation",W.CurrentRoute.key=="dead");player.dead=false
-- Live negative gossip is scoped to this exact quest snapshot, not permanent.
dwarf();log={};local gs=scan();offers={};W.ObserveGossip()
check("live gossip removes phantom offers at the inspected NPC",not W.IsQuestAvailable(1,gs))
log={{id=10,title="The Night Watch",rows={{type="monster",text="Skeleton",objectiveID=300}}}};gs=scan()
check("quest changes invalidate negative gossip",W.IsQuestAvailable(1,gs))
check("group option starts excluded",not W.IsQuestAvailable(13,gs));gs.profile.includeGroup=true;check("group option can include eligible elites",W.IsQuestAvailable(13,gs));gs.profile.includeGroup=false
log={{id=777,title="New high-level quest",level=45,wp={1431,.5,.5},rows={{type="event",text="New content"}}}};gs=scan();plan();check("unknown active quests respect live quest level",W.Unmapped[1] and W.Unmapped[1].reason=="Above comfort level")
-- A working area remains stable until its objective changes.
ne();log={{id=32,title="Two creatures",rows={{type="monster",objectiveID=301,text="Forest creature",finished=false},{type="monster",objectiveID=302,text="Webwood spider",finished=false}}}}
gs=scan();local working=W.ActiveSteps(gs.activeQuests[1],gs)[1];W.GetProfile().pinned=working.key;W.Refresh(true);local oldX=W.CurrentRoute.x
player.x=.615;player.y=.615;W.Refresh(false)
check("moving within an objective does not chase a different spawn",W.CurrentRoute.key==working.key and W.CurrentRoute.x==oldX)
log[1].rows[1].finished=true;W.Refresh(false);check("finished objective releases focused step",W.CurrentRoute.key~=working.key)
-- Level 7 stays in Kalimdor even with an unrelated Eastern Kingdoms quest.
ne();log={{id=10,title="The Night Watch",level=23,rows={{type="monster",objectiveID=300,text="Skeleton"}}}};scan();local rr=plan();check("night elf route stays local",rr.mapID==1438)
-- Old 0.3.0 stages do not leak into a new profile.
WayfinderDB.profiles["Fresh - Forever"]={waterTotemStage=5,navigatorHidden=true};player.name="Fresh";player.guid="Player-Fresh";local fresh=W.GetProfile()
check("migration preserves display preference",fresh.navigatorHidden==true)
check("migration removes class-specific manual stage",fresh.waterTotemStage==nil and fresh.completed~=WayfinderDB.profiles["Player-Dwarf"].completed)

-- All UI and login code executes against a strict frame API double.
ne();W.GetProfile().offers={};log={{id=2,title="Warrior training",rows={{type="monster",objectiveID=301,text="Forest creature: 1/4",numFulfilled=1,numRequired=4}}}};W.Refresh(true);W.CreateNavigator();W.UpdateNavigator();W.UpdateUI()
check("main and navigator created",W.MainFrame and W.NavigatorFrame)
check("main panel compact enough",W.MainFrame.w==400 and W.MainFrame.h==626)
check("diagnostics include current character",string.find(W.Diagnostics(),"Raelorn",1,true)~=nil)
W.EventFrame.scripts.OnEvent(W.EventFrame,"PLAYER_LOGIN");drain();check("login initialization has no planning errors",W.LastError==nil)
-- 1.1 quality regressions.
ne();log={{id=40,title="Similar creature names",rows={{type="monster",objectiveID=9901,text="Dire Wolf: 4/4",finished=true},{type="monster",objectiveID=9902,text="Wolf: 0/4",finished=false}}}};s=scan();activeSteps=W.ActiveSteps(s.activeQuests[1],s)
check("similar names and reversed objective order do not suppress unfinished target",#activeSteps==1 and activeSteps[1].target=="Wolf")
log={{id=41,title="Vendor supplies",rows={{type="item",text="Supply pack: 0/1",finished=false}}}};s=scan();activeSteps=W.ActiveSteps(s.activeQuests[1],s)
check("vendor item instruction says buy",activeSteps[1] and activeSteps[1].instruction:find("Buy from Quartermaster",1,true)~=nil)
check("source annotations do not mutate cached NPC points",W.EntityPoints("Npc",202)[1].acquisition==nil)
log={{id=31,title="Two items",rows={{type="item",text="First item",finished=true},{type="item",text="Second item",finished=false}}}};s=scan();activeSteps=W.ActiveSteps(s.activeQuests[1],s)
check("object item instruction says search",activeSteps[1] and activeSteps[1].instruction:find("Search Quest chest",1,true)~=nil)
dwarf();log={{id=15,title="Gather wolf pelts",rows={{type="item",text="Wolf pelt",finished=false}}}};s=scan();activeSteps=W.ActiveSteps(s.activeQuests[1],s)
check("creature item instruction says defeat",activeSteps[1] and activeSteps[1].instruction:find("Defeat Skeleton",1,true)~=nil)
check("non-finite map inputs rejected",W.Point(1431,0/0,.5)==nil and W.Point(1431,math.huge,.5)==nil)
local worldAPI=C_Map.GetWorldPosFromMapPos
C_Map.GetWorldPosFromMapPos=function(id,p) if id==999 then return 0,CreateVector2D(0,0) end return worldAPI(id,p) end
check("degenerate map transform does not report false position",W.Point(999,.5,.5).wx==nil)
C_Map.GetWorldPosFromMapPos=worldAPI;maps[999]={c=0,ox=0,oy=0,w=4000,h=3000}
check("map transform recovers when data becomes valid",W.Point(999,.5,.5).wx~=nil)
local facingAPI=GetPlayerFacing;GetPlayerFacing=function() return nil end
local pnt=W.Point(1431,.8,.5)
check("missing facing is explicit",W.NavigationInfo({kind="objective",key="facing",point=pnt,mapID=1431,x=.8,y=.5}).label=="Facing unavailable")
GetPlayerFacing=facingAPI
player.x=.5;player.y=.5
local near=W.Point(1431,.5033,.5);local arrival={kind="pickup",key="arrival",point=near,mapID=1431,x=near.x,y=near.y}
check("arrival enters within interaction radius",W.NavigationInfo(arrival).arrived==true)
player.x=.4986;check("arrival tolerates small position jitter",W.NavigationInfo(arrival).arrived==true)
player.x=.496;check("arrival releases after leaving area",W.NavigationInfo(arrival).arrived~=true)
W.SyncWaypoint(arrival,true);old=clearCount
local setAPI=C_Map.SetUserWaypoint;C_Map.SetUserWaypoint=function() return false end
W.SyncWaypoint({kind="pickup",key="rejected",point=pnt,mapID=1431,x=.8,y=.5},true)
check("rejected replacement clears stale owned marker",clearCount==old+1 and W.WaypointStatus=="Map waypoint rejected")
C_Map.SetUserWaypoint=setAPI
local p=W.GetProfile();p.uiScale=0/0;p.maxLevelAbove=999;p.locked="bad";p=W.GetProfile()
check("invalid saved preference values repaired",p.uiScale==1 and p.maxLevelAbove==2 and p.locked==false)
p.skipped.expired=epoch-1;p.lastSkipped="expired";W.GetProfile();check("expired skip clears undo state",p.lastSkipped==nil)
local moduleAPI=QuestieLoader.ImportModule;local moduleCalls=0;local late=nil
QuestieLoader.ImportModule=function(self,name) if name=="LateModule" then moduleCalls=moduleCalls+1;return late end return moduleAPI(self,name) end
check("unavailable modules can be retried",W.Import("LateModule")==nil);late={ready=true};check("late module becomes available",W.Import("LateModule")==late)
W.Import("LateModule");check("available module imports are reused",moduleCalls==2)
QuestieLoader.ImportModule=moduleAPI
-- Idle work is throttled, while movement/events still update the route.
ne();log={{id=2,title="Warrior training",rows={{type="monster",objectiveID=301,text="Forest creature",finished=false}}}};W.Refresh(true)
local executions=W.PlanExecutions
for i=1,5 do epoch=epoch+2;W.EventFrame.scripts.OnUpdate(W.EventFrame,2) end
check("standing still avoids repeated full planning",W.PlanExecutions==executions)
epoch=epoch+6;W.EventFrame.scripts.OnUpdate(W.EventFrame,2);check("idle maintenance still refreshes",W.PlanExecutions==executions+1)
player.x=player.x+.01;W.EventFrame.scripts.OnUpdate(W.EventFrame,2);check("meaningful movement refreshes route",W.PlanExecutions==executions+2)
W.EventFrame.scripts.OnEvent(W.EventFrame,"QUEST_LOG_UPDATE");drain();check("quest events refresh without waiting for movement",W.PlanExecutions==executions+3)
local planAPI=W.PlanRoute;W.PlanRoute=function() error("synthetic planner failure") end;W.Refresh(true)
check("planning failure produces recoverable visible state",W.CurrentRoute.key=="error" and W.LastError~=nil)
W.PlanRoute=planAPI;W.Refresh(true);check("successful refresh clears current error and retains recovery details",W.LastError==nil and W.RecoveredError~=nil)
-- Visible UI controls perform their advertised actions.
W.ToggleSettings();local group=button("Quest difficulty:");group.scripts.OnClick();check("group setting callback updates character preference",W.GetProfile().includeGroup==true);group.scripts.OnClick()
local lock=button("Window positions:");lock.scripts.OnClick();check("window lock preference enabled",W.GetProfile().locked==true)
local header
for _,n in ipairs(nodes) do if n.parent==W.MainFrame and n.scripts.OnDragStart then header=n end end
local mainMoves=W.MainFrame.moves or 0;local navMoves=W.NavigatorFrame.moves or 0
header.scripts.OnDragStart();W.NavigatorFrame.scripts.OnDragStart(W.NavigatorFrame)
check("locked windows ignore accidental drags",(W.MainFrame.moves or 0)==mainMoves and (W.NavigatorFrame.moves or 0)==navMoves)
lock.scripts.OnClick();header.scripts.OnDragStart();W.NavigatorFrame.scripts.OnDragStart(W.NavigatorFrame)
check("unlocked windows remain draggable",W.MainFrame.moves==mainMoves+1 and W.NavigatorFrame.moves==navMoves+1)
button("Back to your route").scripts.OnClick()
W.GetProfile().paused=true;W.Refresh(true);button("Resume route").scripts.OnClick();check("resume button actually resumes routing",not W.GetProfile().paused and W.CurrentRoute.key~="paused")
W.SkipCurrent();local undo=button("Undo skip");check("undo skip is immediately visible",undo.shown==true);undo.scripts.OnClick();check("undo control restores quest",W.GetProfile().lastSkipped==nil and undo.shown==false)
W.Queue={};W.UpdateUI();local empty
for _,n in ipairs(nodes) do if n.kind=="font" and n.text:find("only mapped step",1,true) then empty=n end end
check("empty planned list explains what happens next",empty and empty.shown)
W.GetProfile().collapsed=true;W.UpdateUI();check("compact mode hides empty-list copy and undo",W.MainFrame.h==382 and not empty.shown and not undo.shown)
W.GetProfile().collapsed=false;W.Refresh(true)
local originalRoute=W.CurrentRoute;local longTitle=string.rep("A longer quest title ",5)
W.CurrentRoute={kind="wait",key="longtitle",title=longTitle,instruction="Test"};W.UpdateUI()
local titleNode
for _,n in ipairs(nodes) do if n.kind=="font" and n.text==longTitle then titleNode=n end end
check("long current titles shrink within their allocated text area",titleNode and titleNode.fontSize<16 and titleNode:GetStringHeight()<=43)
W.CurrentRoute=originalRoute;W.UpdateUI()

print(string.format("%d scenario checks passed",passed))
-- Export actual frame calls, not an independently designed mockup.
local function quote(v) return string.format('%q',v):gsub('\\\n','\\n') end
local function array(t) local a={} for _,v in ipairs(t or {}) do a[#a+1]=tostring(v) end return '['..table.concat(a,',')..']' end
local function snapshot(path)
 local dump={}
 for i,node in ipairs(nodes) do
  local parentIndex=0;for j,p in ipairs(nodes) do if node.parent==p then parentIndex=j;break end end
  local point=node.points[1] or {};local x,y=0,0
  if type(point[2])=="number" then x,y=point[2],point[3] or 0 else x,y=point[4] or 0,point[5] or 0 end
  dump[#dump+1]=string.format('{"kind":%s,"name":%s,"parent":%d,"shown":%s,"text":%s,"anchor":%s,"x":%s,"y":%s,"w":%s,"h":%s,"font":%s,"color":%s,"bg":%s,"texture":%s}',quote(node.kind),quote(node.name or ""),parentIndex,tostring(node.shown),quote(tostring(node.text)),quote(point[1] or "TOPLEFT"),tostring(x),tostring(y),tostring(node.w),tostring(node.h),tostring(node.fontSize or 10),array(node.textColor),array(node.bgColor),quote(node.texture or ""))
 end
 local f=io.open(path,'w');f:write('['..table.concat(dump,',')..']');f:close()
end
ne();W.GetProfile().offers={};log={{id=2,title="Warrior training",rows={{type="monster",objectiveID=301,text="Forest creature: 1/4",numFulfilled=1,numRequired=4}}}};W.Refresh(true);local cs=W.ActiveSteps(W.State.activeQuests[1],W.State)[1];W.PinStep(cs);snapshot('tests/ui-nightelf.json')
dwarf();log={{id=10,title="The Night Watch",level=23,rows={{type="monster",objectiveID=300,text="Skeleton: 0/8",numFulfilled=0,numRequired=8}}}};W.Refresh(true);snapshot('tests/ui-dwarf.json')

W.ToggleSettings();snapshot('tests/ui-settings.json');button("Back to your route").scripts.OnClick()
W.Queue={};W.UpdateUI();snapshot('tests/ui-empty.json')
