Warning: truncated output (original token count: 17718)
Total output lines: 763

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
for _,m in ipairs({"EnableMouseWheel","SetFrameStrata","SetClampedToScreen","SetMovable","EnableMouse","RegisterForDrag","SetBackdrop","SetBackdropBorderColor","SetJustifyH","SetJustifyV","SetWordWrap","SetAllPoints","StartMoving","StopMovingOrSizing","SetMultiLine","SetAutoFocus","SetFontObject","SetFocus","HighlightText"}) do methods[m]=function() end end
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
 IsDoable=function(id) if id==39 then return nil end for _,q in ipairs(log) do if q.id==id then return false end end return true end}
QuestieLoader={ImportModule=function(_,name) if name=="QuestieDB" then return qmodule end end}
for _,file in ipairs({"Common","Data","Tracking","Database","Safety","Experience","Planner","UI","Travel","Navigator","RouteOverlay","Replay","Core"}) do dofile("Trailwarden/"..file..".lua") end
local W=Trailwarden
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
dwarf();log={};local gs=scan();offers={};W.ObserveGossip();gs=W.ScanCharacter()
check("live gossip removes phantom offers at the inspected NPC",not W.IsQuestAvailable(1,gs))
log={{id=10,title="The Ni…7718 tokens truncated…2 and instruction.h>=instruction:GetStringHeight() and W.MainFrame.h>shortHeight and -strip.points[1][3]>=-instruction.points[1][3]+instruction.h+10)
 W.Navigation.travel.instruction=route.instruction;W.UpdateLiveUI()
 check("live instruction changes reclaim unused panel space",W.MainFrame.h==shortHeight)
 W.GetProfile().collapsed=true;W.UpdateUI();local summary,summaryDistance
 for _,n in ipairs(nodes) do if n.kind=="font" and n.text=="Readable quest" and visible(n) then summary=n end end
 for _,n in ipairs(nodes) do if n.kind=="font" and n.text=="120 yd" and summary and n.parent==summary.parent then summaryDistance=n end end
 check("collapsed panel retains current quest and distance",summary and summaryDistance and visible(summaryDistance) and W.MainFrame.h==48)
 route.questName="The Long and Complicated Adventures of an Unusually Persistent Adventurer";W.UpdateUI()
 check("long collapsed quest names retain the complete distance without overlap",summary.text:sub(-3)=="..." and summary:GetStringHeight()<=summary.h and visible(summaryDistance) and summaryDistance.text=="120 yd" and summaryDistance.w>=summaryDistance:GetStringWidth() and summary.points[1][2]+summary.w+10<=summaryDistance.points[1][2])
 W.Navigation.distance=12400;W.UpdateLiveUI()
 check("live collapsed distance changes reserve their full measured width",summaryDistance.text=="12.4 k yd" and summaryDistance.w>=summaryDistance:GetStringWidth() and summary.points[1][2]+summary.w+10<=summaryDistance.points[1][2] and summaryDistance.points[1][2]+summaryDistance.w==305)
 W.Navigation.distance=0;W.UpdateLiveUI()
 check("collapsed distance includes zero yards at the destination",summaryDistance.text=="0 yd" and visible(summaryDistance))
 W.Navigation.decisionID=W.Decision.id-1;W.UpdateLiveUI()
 check("collapsed summary clears a stale decision's distance and reclaims its width",not visible(summaryDistance) and summaryDistance.text=="" and summary.w==290)
 route.questName="Readable quest";W.Navigation.decisionID=W.Decision.id;W.Navigation.distance=nil;W.UpdateUI()
 check("collapsed quest uses full width when no distance is available",summary.text=="Readable quest" and summary.w==290 and not visible(summaryDistance))
 W.Navigation.distance=120;W.UpdateLiveUI();W.GetProfile().collapsed=false;W.UpdateUI()
 check("expanded guide restores subtitle width and hides compact distance",summary.w==290 and not visible(summaryDistance) and summaryDistance.text=="")
 W.GetProfile().collapsed=true;W.UpdateUI();W.ToggleSettings()
 check("preferences hide compact distance while restoring the subtitle width",summary.w==290 and not visible(summaryDistance) and summaryDistance.text=="")
 W.ToggleSettings()
 check("leaving preferences restores the collapsed distance",visible(summaryDistance) and summaryDistance.text=="120 yd" and W.MainFrame.h==48)
 local text=string.rep("Étoile ",20);W.FitCaption(titleNode,text)
 check("caption truncation preserves UTF-8 characters and readable size",not titleNode.text:find("\195%.%.%.") and titleNode.fontSize==16 and titleNode:GetStringHeight()<=40)
 W.GetProfile().collapsed=oldCollapsed;W.CurrentRoute=oldRoute;W.Navigation=oldNav;W.UpdateUI()
end

-- XP event wiring and real panel values, in addition to the isolated XP suite.
local testXP=100
UnitXP=function() return testXP end;UnitXPMax=function() return 1000 end
W.ResetExperience();epoch=epoch+60;testXP=300
W.EventFrame.scripts.OnEvent(W.EventFrame,"PLAYER_XP_UPDATE","player");drain()
check("client XP event refreshes the live session",W.ExperienceStats().totalXP==200 and W.ExperienceStats().rate==12000)
local xpText,etaText=false,false;for _,node in ipairs(nodes) do if node.kind=="font" and node.text=="Learning..." then xpText=true elseif node.kind=="font" and node.text=="Building sample" then etaText=true end end
check("panel waits for a stable XP sample before showing rate and ETA",xpText and etaText and W.ExperienceStats().eta==210)
check("XP gain and rewarded-kill events are registered",W.EventFrame.events.PLAYER_XP_UPDATE and W.EventFrame.events.CHAT_MSG_COMBAT_XP_GAIN)
SlashCmdList.TRAILWARDEN("xp");check("XP routing can be disabled without stopping measurement",not W.GetProfile().xpRouting and W.ExperienceStats().rate==12000)
SlashCmdList.TRAILWARDEN("xp");SlashCmdList.TRAILWARDEN("xpreset");check("session reset retains learned character preferences",W.ExperienceStats().totalXP==0 and W.GetProfile().xpRouting and W.GetProfile().queueRows==2)
-- Leave a measured synthetic session for development UI renders.
epoch=epoch+120;testXP=500;W.SampleExperience()

-- Failure isolation and event-burst regression from live 1.4 feedback.
ne();player.guid="Player-Stability";log={{id=2,title="Warrior training",rows={{type="monster",text="Forest creature: 0/4",numFulfilled=0,numRequired=4}}}}
W.Refresh(false,"fault-test");W.PinStep(W.ActiveSteps(W.State.activeByID[2],W.State)[1]);W.GetProfile().pinned=nil;local initialPlans=W.PlanExecutions
for i=1,20 do W.EventFrame.scripts.OnEvent(W.EventFrame,"PLAYER_XP_UPDATE","player");W.EventFrame.scripts.OnEvent(W.EventFrame,"CHAT_MSG_COMBAT_XP_GAIN","unparsed test") end;drain()
check("XP and kill event burst does not invoke route planning",W.PlanExecutions==initialPlans)
for i=1,10 do W.EventFrame.scripts.OnEvent(W.EventFrame,"QUEST_LOG_UPDATE") end;drain()
check("duplicate quest-log events do not rebuild an unchanged plan",W.PlanExecutions==initialPlans)
log[1].rows[1].numFulfilled=1;W.EventFrame.scripts.OnEvent(W.EventFrame,"QUEST_LOG_UPDATE");drain()
check("actual partial progress refreshes the instruction once",W.PlanExecutions==initialPlans+1 and W.CurrentRoute.questID==2)
local sampleXP=W.SampleExperience;W.SampleExperience=function() error("synthetic combat XP failure") end
W.Refresh(false,"fault-test");check("XP sampling failure cannot erase valid quest guidance",W.CurrentRoute.questID==2 and W.CurrentRoute.kind=="objective")
W.SampleExperience=sampleXP
local learnXP=W.ObserveExperienceProgress;W.ObserveExperienceProgress=function() error("synthetic learning failure") end
W.Refresh(false,"fault-test");check("learning failure is isolated from character capture",W.CurrentRoute.questID==2 and W.LearningError~=nil)
W.ObserveExperienceProgress=learnXP
local forecastXP=W.PrepareQuestEconomies;W.PrepareQuestEconomies=function() error("synthetic missing provider forecast") end
epoch=epoch+46;W.Refresh(false,"fault-test")
check("failed forecast falls back to quest routing rather than waiting card",W.CurrentRoute.questID==2 and W.ForecastError~=nil)
W.PrepareQuestEconomies=forecastXP;W.Refresh(false,"fault-test")
check("forecast recovers independently without resetting route",W.CurrentRoute.questID==2 and W.ForecastError==nil)
local rewardAPI=W.QuestRewardEstimate
W.QuestRewardEstimate=function(id,state) if id==2 then return 500,"Questie adjusted reward" end return rewardAPI(id,state) end
epoch=epoch+46;W.Refresh(false,"forecast-regression")
local builds=W.ForecastBuilds or 0;local oldWork=W.CurrentRoute.economy.workSeconds
for i=1,3 do log[1].rows[1].numFulfilled=i;W.Refresh(false,"QUEST_LOG_UPDATE") end
check("partial progress rebuilds stale forecast quantities immediately",(W.ForecastBuilds or 0)==builds+2 and W.CurrentRoute.questID==2 and W.CurrentRoute.economy.workSeconds<oldWork and W.CurrentRoute.remaining==1)
builds=W.ForecastBuilds;local hits=W.ForecastCacheHits or 0;W.Refresh(false,"forecast-regression")
check("unchanged progress still reuses forecast models",W.ForecastBuilds==builds and (W.ForecastCacheHits or 0)==hits+1)
W.QuestRewardEstimate=rewardAPI
local routeBefore=W.CurrentRoute
local failPlan=W.PlanRoute;W.PlanRoute=function() error("synthetic planner fault") end
log[1].complete=true;W.Refresh(false,"fault-test")
check("recovery never preserves an objective after its quest completes",W.CurrentRoute.kind~="objective")
W.PlanRoute=failPlan;W.Refresh(false,"fault-test")
check("completed quest progresses after recovery",W.CurrentRoute.kind=="turnin")
local countPlans=W.PlanExecutions;epoch=epoch+1;W.EventFrame.scripts.OnEvent(W.EventFrame,"PLAYER_XP_UPDATE","player");drain()
check("post-turn-in XP measurement does not churn the planner",W.PlanExecutions==countPlans)

-- Immediate live danger must clear a committed map marker and navigator.
dwarf();player.guid="Player-Combat-Regression";player.x=.797;player.y=.685;log=actualLog;log[2].complete=false
W.Refresh(true);W.PinStep(W.ActiveSteps(W.State.activeByID[2100],W.State)[1]);local oldCombatRoute=W.Copy(W.CurrentRoute)
local guidAPI,levelAPI,nameAPI=UnitGUID,UnitLevel,UnitName
local hostileVisible=true
UnitGUID=function(unit) if unit=="target" and hostileVisible then return "Creature-0-0-0-0-2100-1" end return guidAPI(unit) end
UnitLevel=function(unit) if unit=="target" then return 29 end return levelAPI(unit) end
UnitName=function(unit) if unit=="target" then return "Fetid Corpse live correction" end return nameAPI(unit) end
UnitCanAttack=function(_,unit) return unit=="target" and hostileVisible end
UnitClassification=function() return "normal" end
W.EventFrame.scripts.OnEvent(W.EventFrame,"PLAYER_TARGET_CHANGED")
check("live level-29 hostile immediately interrupts committed quest route",W.CurrentRoute.key=="danger")
check("danger stop releases owned map waypoint and arrow direction",W.WaypointStatus=="No mapped step" and not W.Navigation.bearing)
hostileVisible=false;W.EventFrame.scripts.OnEvent(W.EventFrame,"PLAYER_TARGET_CHANGED")
check("source correction survives after hostile leaves target",W.CurrentRoute.point==nil or W.CurrentRoute.point.entityID~=2100)
local currentSteps=W.ActiveSteps(W.State.activeByID[2100],W.State);local noUnsafe=true
for _,step in ipairs(currentSteps) do if step.point.entityID==2100 then noUnsafe=false end end
check("old pinned collection source cannot bypass observed level cap",noUnsafe)
player.level=27;W.EventFrame.scripts.OnEvent(W.EventFrame,"PLAYER_LEVEL_UP",27);drain()
local again=W.ActiveSteps(W.State.activeByID[2100],W.State);local permitted=false
for _,step in ipairs(again) do if step.point.entityID==2100 then permitted=true end end
check("level-up reconsiders held combat sources automatically",permitted)
UnitGUID=guidAPI;UnitLevel=levelAPI;UnitName=nameAPI;UnitCanAttack=nil;UnitClassification=nil;W.PollCombatSafety()

-- Export actual frame calls, not an independently designed mockup.
local function quote(v) return string.format('%q',v):gsub('\\\n','\\n') end
local function array(t) local a={} for _,v in ipairs(t or {}) do a[#a+1]=tostring(v) end return '['..table.concat(a,',')..']' end
-- Synthetic client reproduction of the Ban'ethil live report, including source choice.
local savedCaves=W.CaveAccess;local savedMapInfo=C_Map.GetMapInfo
local savedIndoors,savedSubzone=IsIndoors,GetSubZoneText
ne();player.guid="Player-Cave-Batch";player.level=8;player.x=.447;player.y=.589
local lo,hi=W.Point(1438,.47,.62),W.Point(1438,.44,.56)
W.CaveAccess={{id="banethil",name="Ban'ethil Barrow Den",mapID=1438,interiorMaps={[60]=true,[61]=true},continent=1,bounds={lo.wx,lo.wy,hi.wx,hi.wy},entrance={hi.wx,hi.wy}}}
C_Map.GetMapInfo=function(id) if id==60 or id==61 then return {name="Ban'ethil Barrow Den"} end;return savedMapInfo(id) end
IsIndoors=function() return true end;GetSubZoneText=function() return "Ban'ethil Barrow Den" end
objects[4200]={name="Cave chest",spawns={[20]={{43.9,58.9},{46.5,58.9}}}}
objects[4201]={name="Second cave chest",spawns={[20]={{46,60}}}}
objects[4202]={name="Outside moonwell",spawns={[20]={{42.4,67.1}}}}
items[4200]={name="Black Feather Quill",objectDrops={4200}};items[4201]={name="Rune",objectDrops={4201}};items[4202]={name="Filled Tourmaline Phial",objectDrops={4202}}
quests[4200]={name="The Relics of Wakening",questLevel=9,objectives={[3]={{4200},{4201}}}}
quests[4201]={name="Crown of the Earth",questLevel=9,objectives={[3]={{4202}}}}
log={{id=4200,title="The Relics of Wakening",level=9,rows={{type="item",text="Black Feather Quill",numFulfilled=0,numRequired=1},{type="item",text="Rune",numFulfilled=0,numRequired=1}}},
 {id=4201,title="Crown of the Earth",level=9,rows={{type="item",text="Filled Tourmaline Phial",numFulfilled=0,numRequired=1}}}}
npcs[275744]={name="Sentinel Lynessa Duskblossom",minLevel=10,maxLevel=10,spawns={[20]={{44.67,58.91}}}}
quests[99053]={name="Escaping Ban'ethil",requiredLevel=4,questLevel=10,requiredRaces=8,startedBy={{275744}},finishedBy={{201}},triggerEnd={"Escort Lynessa Duskblossom out of Ban'ethil",{[20]={{43.08,51.65}}}}}
W.BuildQuestCatalog(true);drain()
W.GetProfile().offers={};W.Refresh(true)
check("observed indoor cave context reaches the planner",W.State.workArea and W.State.workArea.id=="banethil")
check("cave object source wins over a nearer outdoor source",W.CurrentRoute.questID==4200 and W.CurrentRoute.point.x>=.44)
check("selected cave collection does not tell the player to leave",W.Navigation.travel.mode=="cave-interior")
log[1].rows[2].numFulfilled=1;log[1].rows[2].finished=true;W.Refresh(false,"QUEST_LOG_UPDATE")
local foundEscort=false;for _,o in ipairs(W.Decision.detail.opportunities) do if o.questID==99053 and o.activity=="escort" then foundEscort=true end end
check("new Forever escort appears as a nearby opportunity before acceptance",foundEscort)
check("escort exit pickup waits for unfinished cave collection",W.CurrentRoute.questID==4200)
check("quest-log progress is captured independently of XP routing",W.State.workFocus and W.State.workFocus.questID==4200)
check("last cave item stays ahead of an outside quest",W.CurrentRoute.questID==4200 and W.CurrentRoute.target=="Black Feather Quill")
check("completed collection sub-objective is removed independently",#W.ActiveSteps(W.State.activeByID[4200],W.State)==1)
W.GetProfile().skipped["quest:4200"]=epoch+900;W.Refresh(true)
check("explicit cave skip can release the outside route",W.CurrentRoute.questID~=4200)
W.GetProfile().skipped={};log[1].complete=true;log[1].rows[1].numFulfilled=1;log[1].rows[1].finished=true;W.Refresh(true)
check("finished collection exposes the nearby escort before departure",W.CurrentRoute.questID==99053 and W.CurrentRoute.kind=="pickup")
maps[60]=maps[1438];player.map=60;W.Refresh(true)
check("cave floor still discovers pickups indexed in parent quest zone",W.State.regionMapID==1438 and W.CurrentRoute.questID==99053)
player.map=1438;maps[60]=nil
log[#log+1]={id=99053,title="Escaping Ban'ethil",level=10,rows={{type="event",text="Escort Lynessa Duskblossom out of Ban'ethil",numFulfilled=0,numRequired=1}}};W.Refresh(true)
check("accepted escort becomes the active task without an exit bearing",W.CurrentRoute.kind=="escort" and not W.CurrentRoute.point and not W.Navigation.bearing)
check("active escort does not recommend running ahead to an endpoint",W.Navigation.label=="Stay with the escort")
-- Failed quests must invalidate the noisy-event throttle without waiting a minute.
local escortIndex=#log
local beforeFailure=W.Decision.id
log[escortIndex].complete=-1;W.Refresh(false,"QUEST_LOG_UPDATE")
check("failed escort immediately releases guidance on quest-log update",W.CurrentRoute.kind~="escort" and W.Decision.id>beforeFailure)
check("failed escort has no direct actionable steps",#W.ActiveSteps(W.State.activeByID[99053],W.State)==0)
log[escortIndex].complete=false;W.Refresh(false,"QUEST_LOG_UPDATE")
check("restarted escort immediately becomes actionable again",W.CurrentRoute.kind=="escort")
local failedPlanner=W.PlanRoute
W.PlanRoute=function() error("synthetic failure at escort failure") end
log[escortIndex].complete=-1;W.Refresh(true,"fault-test")
check("planner recovery never preserves a failed escort",W.CurrentRoute.kind~="escort" and not W.CurrentRoute.point)
W.PlanRoute=failedPlanner
log[escortIndex].complete=true;W.Refresh(true)
check("completed escort releases escort activity",W.CurrentRoute.kind~="escort")
-- The general progress guideline also works without a named cave record.
W.CaveAccess={};GetSubZoneText=function() return "Unmapped underground area" end
log[1].complete=false;log[1].rows[1].finished=false;log[1].rows[1].numRequired=2;log[1].rows[1].numFulfilled=0;W.Refresh(true)
log[1].rows[1].numFulfilled=1;W.Refresh(false,"QUEST_LOG_UPDATE")
check("unmapped interiors get a live context without quest-specific cave IDs",W.State.workArea.kind=="interior" and W.State.workFocus.questID==4200)
check("partial collection stays active in an unmapped underground area",W.CurrentRoute.questID==4200)
local priorItem=items[4200];items[4200]={name="Black Feather Quill"};W.Refresh(true)
check("missing source data cannot silently send an engaged quest elsewhere",W.CurrentRoute.reviewWork and W.CurrentRoute.questID==4200 and not W.CurrentRoute.point)
items[4200]=priorItem
player.x=.8;player.y=.8;W.Refresh(true)
check("walking out of the progress area releases its focus",not W.State.workFocus)
W.CaveAccess=savedCaves;C_Map.GetMapInfo=savedMapInfo;IsIndoors=savedIndoors;GetSubZoneText=savedSubzone

local function snapshot(path)
 local dump={}
 for i,node in ipairs(nodes) do
  local parentIndex=0;for j,p in ipairs(nodes) do if node.parent==p then parentIndex=j;break end end
  local point=node.points[1] or {};local x,y=0,0
  if type(point[2])=="number" then x,y=point[2],point[3] or 0 else x,y=point[4] or 0,point[5] or 0 end
  dump[#dump+1]=string.format('{"kind":%s,"name":%s,"parent":%d,"shown":%s,"text":%s,"anchor":%s,"x":%s,"y":%s,"w":%s,"h":%s,"font":%s,"color":%s,"bg":%s,"texture":%s,"justifyH":%s,"justifyV":%s,"wrap":%s,"rotation":%s}',quote(node.kind),quote(node.name or ""),parentIndex,tostring(node.shown),quote(tostring(node.text)),quote(point[1] or "TOPLEFT"),tostring(x),tostring(y),tostring(node.w),tostring(node.h),tostring(node.fontSize or 10),array(node.textColor),array(node.bgColor),quote(node.texture or ""),quote(node.justifyH or "LEFT"),quote(node.justifyV or "MIDDLE"),tostring(node.wordWrap~=false),tostring(node.rotation or 0))
 end
 local f=io.open(path,'w');f:write('['..table.concat(dump,',')..']');f:close()
end
-- Synthetic reward estimates for the render fixtures; not claimed game rewards.
local priorImport=QuestieLoader.ImportModule
QuestieLoader.ImportModule=function(self,name)
 if name=="QuestXP" then return {GetQuestLogRewardXP=function(_,id) return id==2100 and 2000 or id==10 and 1500 or id==2 and 500 or 0 end} end
 return priorImport(self,name)
end
ne();W.GetProfile().offers={};log={{id=2,title="Warrior training",rows={{type="monster",objectiveID=301,text="Forest creature: 1/4",numFulfilled=1,numRequired=4}}}};W.Refresh(true);local cs=W.ActiveSteps(W.State.activeQuests[1],W.State)[1];W.PinStep(cs);snapshot('tests/ui-nightelf.json')
-- Same real frame code, with a synthetic Melenas destination for spacing review.
local caveRoute=W.Copy(W.CurrentRoute);caveRoute.questName="Twisted Hatred";caveRoute.title="Twisted Hatred";caveRoute.point.entityID=2038;caveRoute.target="Lord Melenas";caveRoute.level=8;caveRoute.combatRisk={maxLevel=8}
W.CurrentRoute=caveRoute;W.Decision.route=caveRoute;W.UpdateNavigation();W.UpdateNavigator();W.UpdateUI()
check("cave-aware panel keeps original quest while navigating to entrance",W.Navigation.travel.mode=="cave-approach" and W.CurrentRoute.point.entityID==2038)
snapshot('tests/ui-cave.json')
dwarf();player.guid="Player-Batch";player.x=.797;player.y=.685;log=actualLog;log[2].complete=false;W.GetProfile().deferredLevels={};W.GetProfile().pinned=nil;W.Refresh(true)
check("XP-aware mode preserves unfinished cemetery batch",W.CurrentRoute.questID==2100 and W.CurrentRoute.kind=="objective" and W.CurrentRoute.economy~=nil)
check("XP-aware preview retains second objective before town",W.Queue[1] and W.Queue[1].questID==2100)
snapshot('tests/ui-dwarf.json')

W.ToggleSettings();snapshot('tests/ui-settings.json');button("Back to your route").scripts.OnClick()
W.Queue={};W.UpdateUI();snapshot('tests/ui-empty.json')
W.GetProfile().collapsed=true;W.UpdateUI();snapshot('tests/ui-compact.json')
W.GetProfile().collapsed=false;W.UpdateUI()


print(string.format("%d scenario checks passed",passed))
