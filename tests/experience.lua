-- XP-bar accounting, provider rewards and pure future-cycle projections.
unpack=unpack or table.unpack;math.atan2=math.atan2 or function(y,x) return math.atan(y,x) end
local now=0;local xp=0;local maximum=1000;local level=22;local guid="one";local afk=false;local speed=7
function GetTime() return now end
function GetServerTime() return now end
function UnitXP() return xp end
function UnitXPMax() return maximum end
function UnitLevel() return level end
function UnitGUID() return guid end
function UnitIsAFK() return afk end
function GetUnitSpeed() return speed end
function GetMaxPlayerLevel() return 60 end
for _,name in ipairs({"Common","Data","Experience","Planner","Replay"}) do dofile("Trailwarden/"..name..".lua") end
local W=Trailwarden;local passed=0
local profiles={}
function W.GetCharacterKey() return guid end
function W.GetProfile()
 if not profiles[guid] then profiles[guid]={paused=false,xpRouting=true,skipped={},deferredLevels={},maxLevelAbove=2} end
 return profiles[guid]
end
local function point(x) return {mapID=1431,x=x/6000,y=.5,wx=x,wy=0,continent=0,units="normalized"} end
W.PlayerPoint=function() return point(0) end
W.ProviderIdentity=function() return {version="forever-fixture",contract=4,build="test"} end
W.RecordFact=function() end
local function check(name,ok) assert(ok,name);passed=passed+1;print("PASS XP / "..name) end
local function near(a,b) return a and math.abs(a-b)<.001 end
local function reset()
 now=0;xp=0;maximum=1000;level=22;afk=false;speed=7;profiles[guid]=nil;W.ResetExperience()
end
reset();check("login uses current XP as baseline",W.ExperienceStats().totalXP==0)
now=60;xp=100;W.SampleExperience();local e=W.ExperienceStats()
check("measured hourly rate uses actual bar gains",e.totalXP==100 and near(e.rate,6000))
check("ETA uses remaining XP and measured rate",near(e.eta,540))
W.ExperienceEvent("QUEST_TURNED_IN",90001,200);xp=300;now=61;W.SampleExperience();e=W.ExperienceStats()
check("quest reward event does not double-count bar gain",e.totalXP==300 and e.questXP==200 and e.turnins==1)
W.ExperienceEvent("QUEST_TURNED_IN",90002,100);W.ExperienceEvent("CHAT_MSG_COMBAT_XP_GAIN","localized text");xp=450;now=62;W.SampleExperience()
e=W.ExperienceStats();check("same-frame kill attribution subtracts quest rewards",e.totalXP==450 and e.killXP==50)
check("localized kill text requires no English parser",e.kills==1 and e.killSamples==1)
reset();xp=900;W.ResetExperience();now=60;level=23;maximum=1500;xp=50;W.SampleExperience();now=now+1;W.SampleExperience()
check("level rollover adds old remainder plus new XP",W.ExperienceStats().totalXP==150)
reset();xp=900;W.ResetExperience();now=60;xp=50;W.SampleExperience();check("XP-before-level waits rather than inventing a loss",W.ExperienceStats().totalXP==0)
level=23;maximum=1500;now=60.2;W.SampleExperience();now=61.2;W.SampleExperience();check("delayed level event resolves rollover once",W.ExperienceStats().totalXP==150)
reset();level=24;xp=100;W.SampleExperience();check("unknown multi-level caps do not invent XP",W.ExperienceStats().totalXP==0)
reset();now=60;xp=100;W.SampleExperience();W.GetProfile().paused=true;W.SampleExperience();now=660;xp=200;W.SampleExperience()
check("explicit pause excludes time and XP gains",W.ExperienceStats().elapsed==60 and W.ExperienceStats().totalXP==100)
W.GetProfile().paused=false;W.SampleExperience();now=720;xp=300;W.SampleExperience();check("resume continues the measured session",W.ExperienceStats().elapsed==120 and W.ExperienceStats().totalXP==200)
reset();afk=true;W.SampleExperience();now=600;W.SampleExperience();check("AFK does not dilute active hourly rate",W.ExperienceStats().elapsed==0)
reset();now=0;xp=100;W.SampleExperience();now=60;W.SampleExperience();check("early first kill is retained in rolling numerator",near(W.ExperienceStats().rate,6000))
reset();for i=1,1000 do now=i;xp=i;W.SampleExperience() end;e=W.ExperienceStats()
check("rolling window expires old history",e.windowSeconds<=901 and near(e.rate,3600))
check("session rate remains separate from rolling rate",near(e.sessionRate,3600))
local oneTotal=e.totalXP;guid="two";W.ResetExperience();check("sessions and learning are character-specific",W.ExperienceStats().totalXP==0);guid="one";check("returning character retains its own session",W.ExperienceStats().totalXP==oneTotal)
reset();speed=14;now=1;W.SampleExperience();check("movement speed learns actual travel pace",W.ExperienceStats().moveSpeed>7)
-- Reward data deliberately contains a new Forever-style ID.
local rewards={[90001]={25,2000},[90002]={25,1000},[90003]={25,500}}
LibQuestieDB={Support={Get=function(name) if name=="QuestXP" then return {db=rewards} end end}}
W.Import=function() return nil end
local state={key=guid,level=22,mapID=1431,zone="Duskwood",now=now,player=point(0),profile=W.Copy(W.GetProfile()),activeByID={},activeQuests={},questLogReady=true,historyReady=true,freeSlots=10,experience=W.ExperienceStats()}
local reward,source=W.QuestRewardEstimate(90001,state)
check("new Forever quest uses live provider reward table",reward==2000 and source:find("Provider"))
check("missing new quest reward remains unknown",W.QuestRewardEstimate(99999,state)==nil)
state.level=32;check("provider base reward falls with grey quest level",near(W.QuestRewardEstimate(90001,state),1200));state.level=22
W.Import=function() return {GetQuestLogRewardXP=function(self,id) assert(type(self)=="table" and id==90001);return 3000 end} end
check("consumer reward uses documented colon contract",W.QuestRewardEstimate(90001,state)==3000)
W.Import=function() return nil end
reset();state.level=22;W.State=state;W.CurrentRoute={questID=90001,economy={rewardXP=3000,xpPerHour=8000,seconds=120}}
W.ExperienceEvent("QUEST_TURNED_IN",90001,3300)
local calibration=W.ExperienceStats().calibration
check("turn-in reward records a same-level observed estimate",W.QuestRewardEstimate(90001,state)==3300 and calibration and calibration.actualXP==3300)
check("XP estimate difference is measured and exposed",calibration.percentError==65 and calibration.absoluteError==1300)
local lowConfidence={rewardXP=2000,pickup=point(100),receiver=point(0),goals={{point=point(500),seconds=100,killXP=500}},confidence="low",interactionSeconds=40}
local lowProjection=W.ProjectQuestXP(lowConfidence,point(0),{moveSpeed=10})
local pace={enabled=true,referenceRate=6000};check("low-confidence XP projection has no route-ranking effect",W.XPRouteEfficiency(lowProjection,pace,200)==0)
lowProjection.confidence="medium";check("medium-confidence projection can rank a route",W.XPRouteEfficiency(lowProjection,pace,200)<0)
reset()
local model={rewardXP=2000,pickup=point(100),receiver=point(0),goals={{point=point(500),seconds=100,killXP=500}},confidence="low",interactionSeconds=40}
local projected=W.ProjectQuestXP(model,point(0),{moveSpeed=10})
check("unaccepted cycle includes pickup work and return",near(projected.travelSeconds,120) and near(projected.seconds,260) and projected.rewardXP==2000 and projected.killXP==500)
check("projected rate includes kills and hand-in exactly once",near(projected.xpPerHour,2500*3600/260))
local slower=W.ProjectQuestXP(model,point(0),{moveSpeed=5});check("slower travel reduces route rate",slower.xpPerHour<projected.xpPerHour)
model.goals[1].seconds=200;check("slower combat reduces route rate",W.ProjectQuestXP(model,point(0),{moveSpeed=10}).xpPerHour<projected.xpPerHour)
check("unknown reward cannot masquerade as zero-XP route",W.ProjectQuestXP({receiver=point(0)},point(0),{})==nil)
local other=point(0);other.continent=1
check("unknown transport connection produces no confident rate",W.ProjectQuestXP(model,other,{moveSpeed=7})==nil)
-- A deterministic instruction budget makes non-termination a test failure.
local function boundedProjection(m,origin)
 debug.sethook(function() error("Projection exceeded instruction budget") end,"",2000000)
 local ok,result=pcall(W.ProjectQuestXP,m,origin,{moveSpeed=10})
 debug.sethook();assert(ok,result);return result
end
local multi={rewardXP=2000,receiver=point(200),goals={
 {point=point(180),seconds=17,killXP=3},{point=point(80),seconds=23,killXP=5},{point=point(110),seconds=31,killXP=7}}}
local originalModel=W.Json(multi);local originalOrigin=W.Json(point(100))
local ordered=boundedProjection(multi,point(100))
check("multi-goal ordering terminates and improves the greedy return route",ordered and near(ordered.travelDistance,140))
check("all work and kill XP are counted once after reordering",ordered.remainingGoals==3 and ordered.workSeconds==71 and ordered.killXP==15 and near(ordered.seconds,107.8))
check("projection leaves model and origin unchanged",W.Json(multi)==originalModel and W.Json(point(100))==originalOrigin)
multi.goals[1],multi.goals[3]=multi.goals[3],multi.goals[1]
check("shuffled distinct goals retain the same cycle estimate",near(boundedProjection(multi,point(100)).travelDistance,140))
multi.pickup=point(100)
check("reordering retains the origin to pickup leg",near(boundedProjection(multi,point(0)).travelDistance,240))
local direct=boundedProjection({rewardXP=100,receiver=point(200),goals={}},point(100))
check("a ready hand-in needs no objective goals",direct.remainingGoals==0 and near(direct.travelDistance,100))
local colocated=boundedProjection({rewardXP=100,receiver=point(0),goals={{point=point(0),seconds=10},{point=point(0),seconds=20}}},point(0))
check("colocated goals retain work without fabricated travel",colocated.workSeconds==30 and colocated.travelDistance==0)
local maximumModel={rewardXP=100,receiver=point(0),goals={}}
for i=1,64 do maximumModel.goals[i]={point=point(i%7*20),seconds=1} end
check("maximum shared batch finishes within a fixed instruction budget",boundedProjection(maximumModel,point(0)).remainingGoals==64)
maximumModel.goals[65]={point=point(0),seconds=1}
check("excessive forecasts fall back instead of monopolizing the planner",boundedProjection(maximumModel,point(0))==nil)
local malformed={false,"invalid",{point=point(0),seconds=0/0},{point=point(0),seconds=math.huge},{point=point(0),seconds=1,killXP=-1},{point={wx=0/0,wy=0,continent=0},seconds=1}}
for i,g in ipairs(malformed) do check("malformed goal is rejected "..i,boundedProjection({rewardXP=100,receiver=point(0),goals={g}},point(0))==nil) end
check("sparse goals cannot silently drop remaining work",boundedProjection({rewardXP=100,receiver=point(0),goals={[2]={point=point(0),seconds=1}}},point(0))==nil)
check("overflowing total work stays unknown",boundedProjection({rewardXP=100,receiver=point(0),goals={{point=point(0),seconds=1e308},{point=point(0),seconds=1e308}}},point(0))==nil)
check("negative interaction time is rejected",boundedProjection({rewardXP=100,receiver=point(0),interactionSeconds=-1},point(0))==nil)
-- Candidate models for accepted and unaccepted quests use the same provider path.
local function step(id,x,kind)
 return {key=(kind or "objective")..":"..id,questID=id,kind=kind or "objective",point=point(x),mapID=1431,x=x/6000,y=.5,ownerKey=guid,objectiveKind="monster",objectiveIndex=1,remaining=3,questName="Forever quest "..id,level=25}
end
W.RelationPoints=function(id) return {point(0)} end
W.NearestPoint=function(points) return points[1] end
local activeSteps=W.ActiveSteps
W.ActiveSteps=function(q) return {step(q.id,500)} end
state.activeByID={[90001]={objectives={{required=3,fulfilled=0}}}}
local a=step(90001,500);local b=step(90002,100,"pickup");state.profile=W.Copy(W.GetProfile())
W.PrepareQuestEconomies({a,b},state)
check("both accepted and unaccepted quests receive full-cycle models",a.economy and b.economy and b.economyModel.pickup)
check("unaccepted work remains explicitly uncertain",b.economy.confidence=="low")
local learned=W.GetProfile().xpLearning;learned.quests[90001]={seen=now,goals={{type="monster",required=3,secondsPerUnit=20,samples=3}}}
W.PrepareQuestEconomies({a},state);check("base reward with unknown bonuses remains uncertain",a.economy.confidence=="low")
W.Import=function(name) if name=="QuestXP" then return {GetQuestLogRewardXP=function(self,id) return rewards[id] and rewards[id][2] or 0 end} end end
state.experience.killTrusted=3;state.experience.killXP=100
W.PrepareQuestEconomies({a},state);check("observed progress plus adjusted reward upgrades confidence",a.economy.confidence=="medium")
local before=a.economy.rewardXP
state.activeByID[90003]={objectives={}};local ready=step(90003,0,"turnin")
W.PrepareQuestEconomies({a,ready},state);check("shared hand-in hub counts each quest reward once",a.economy.rewardXP==before+500 and #a.economyModel.questIDs==2)
state.profile.skipped["quest:90003"]=now+100;W.PrepareQuestEconomies({a,ready},state)
check("skipped quest rewards do not inflate route estimate",a.economy.rewardXP==before)
W.ActiveSteps=activeSteps
-- Grind proposals require a measured window, a reliable alternative and margin.
COMBATLOG_XPGAIN_FIRSTPERSON="%s stirbt. Ihr erhaltet %d Erfahrung."
reset();for i=1,9 do now=i*20;W.ExperienceEvent("CHAT_MSG_COMBAT_XP_GAIN","Test stirbt. Ihr erhaltet 100 Erfahrung.");xp=xp+100;W.SampleExperience() end
e=W.ExperienceStats();check("enough rewarded kills establish an observed local grind rate",e.grind and e.grind.kills==9 and e.grind.rate>0)
local best=step(90001,500);best.economy={xpPerHour=1000,confidence="medium"};state.player=point(0);state.now=now;state.profile=W.Copy(W.GetProfile());state.experience=e
state.experience.inCombat=true;check("a kill during combat cannot start a new grind detour",W.ChooseGrindBreak(best,state,nil,{})==best);state.experience.inCombat=false
state.combatSafety={grindAllowed=true}
local detail={};local grind=W.ChooseGrindBreak(best,state,nil,detail)
check("observed better grind creates a bounded recommendation",grind.kind=="grind" and grind.grindUntil==now+180 and detail.questAlternative~=nil)
best.economy.confidence="low";check("uncertain quest model does not trigger automatic grinding",W.ChooseGrindBreak(best,state,nil,{}).kind~="grind");best.economy.confidence="medium"
state.profile.pinned=best.key;check("manual quest focus prevents grind override",W.ChooseGrindBreak(best,state,nil,{}).kind~="grind");state.profile.pinned=nil
state.now=grind.grindUntil;detail={};check("grind break ends after three minutes",W.ChooseGrindBreak(best,state,grind,detail)==best and detail.endGrind)
W.EndGrindBreak();state.now=now;state.experience=W.ExperienceStats();check("cooldown prevents repeated immediate grind detours",W.ChooseGrindBreak(best,state,nil,{}).kind~="grind")
now=now+61;W.SampleExperience();check("stale kill activity withdraws grind estimate",W.ExperienceStats().grind==nil)
reset();for i=1,3 do now=i*10;W.ExperienceEvent("CHAT_MSG_COMBAT_XP_GAIN","text");xp=xp+100;W.SampleExperience() end
check("a few lucky kills do not establish a grind strategy",W.ExperienceStats().grind==nil)
check("rate collection does not fabricate early ETA",W.ExperienceStats().eta==nil)
check("ETA formatting rounds conservatively",W.FormatETA(61)=="2m" and W.FormatETA(3601)=="1h 1m")
local unavailable=UnitXP;UnitXP=function() return nil end;W.SampleExperience();check("unavailable XP API remains explicit",not W.ExperienceStats().available);UnitXP=unavailable
-- Rank accepted and unaccepted full cycles without client calls in selection.
W.ActiveSteps=function(q) return {step(q.id,500)} end
W.DBGet=function() return "Known synthetic target" end
W.ExperienceStats();local learnedScores=W.GetProfile().xpLearning.quests
learnedScores[90001]={seen=now,goals={{type="monster",entityID=1,required=3,secondsPerUnit=20,samples=3}}}
learnedScores[90002]={seen=now,goals={{type="monster",entityID=1,required=3,secondsPerUnit=20,samples=3}}}
local good=step(90001,100,"pickup");local poor=step(90002,100,"pickup")
state.profile=W.Copy(W.GetProfile());state.activeByID={};state.activeQuests={};state.now=now;state.experience=W.ExperienceStats();state.experience.killTrusted=3;state.experience.killXP=100
W.PrepareQuestEconomies({poor,good},state)
local routeInput={state=state,meta={candidates={poor,good},deferred={},ready=true},force=true,weights=W.Copy(W.RouteWeights)}
local chosen,queue,d=W.SelectRoute(routeInput)
check("XP-aware scoring ranks full cycles of unaccepted quests",chosen.questID==90001 and chosen.scoreParts.efficiency<0)
local frame={event="xp-quest-selection",input=W.Copy(routeInput),expected={key=chosen.key,queue={},clearPin=d.clearPin==true}}
for _,v in ipairs(queue) do frame.expected.queue[#frame.expected.queue+1]=v.key end
local f=io.open("tests/experience-replay.json","w");f:write(W.Json({schema=1,origin="synthetic-experience",frames={frame}}));f:close()
local noXP=UnitXP;UnitXP=function() return 0 end;reset();now=120;W.SampleExperience()
check("zero recent XP reports zero rate rather than collecting forever",W.ExperienceStats().rate==0 and W.ExperienceStats().eta==nil)
UnitXP=noXP
local badPace=W.ProjectQuestXP(model,point(0),{moveSpeed=0});check("invalid movement pace cannot invent infinite efficiency",badPace==nil)
local invalidModel=W.Copy(model);invalidModel.goals[1].seconds=-1
check("invalid work duration stays unknown",W.ProjectQuestXP(invalidModel,point(0),{moveSpeed=7})==nil)
reset();xp=900;W.ResetExperience();now=60;level=23;maximum=1500;W.SampleExperience()
check("level-before-XP waits for a stable bar snapshot",W.ExperienceStats().totalXP==0)
xp=50;now=61;W.SampleExperience();check("level-before-XP accounts only the actual rollover",W.ExperienceStats().totalXP==150)
reset();xp=900;W.ResetExperience();now=60;level=23;maximum=1500;W.SampleExperience();now=61;W.SampleExperience();xp=50;now=61.5;W.SampleExperience()
check("late rollover correction cannot leave a false XP spike",W.ExperienceStats().totalXP==150)
reset();for i=1,9 do now=i*20;W.ExperienceEvent("CHAT_MSG_COMBAT_XP_GAIN","unrecognized locale format");xp=xp+100;W.SampleExperience() end
check("unverified kill-message values cannot trigger automatic grinding",W.ExperienceStats().grind==nil)
InCombatLockdown=function() return true end
local combatReward,combatSource=W.QuestRewardEstimate(90001,state)
check("combat reward estimates flag omitted temporary bonuses",combatReward and combatSource:find("uncertain",1,true))
InCombatLockdown=nil
print(passed.." experience checks passed")
