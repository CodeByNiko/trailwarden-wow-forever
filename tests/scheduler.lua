unpack=unpack or table.unpack
for _,name in ipairs({'Common','Data','Experience','Planner','Scheduler','Replay'}) do dofile('Trailwarden/'..name..'.lua') end
local W=Trailwarden;local tasks={};local combat,map=false,false;local ms=0
function debugprofilestop() ms=ms+1;return ms end
C_Timer={After=function(_,fn) tasks[#tasks+1]=fn end}
W.ProviderGeneration=1;W.GetCharacterKey=function() return 'fixture' end;W.IsCombatActive=function() return combat end;W.IsWorldMapOpen=function() return map end
local function point(x) return {mapID=1431,x=x/10000,y=0,wx=x,wy=0,continent=0} end
local candidates={};for i=1,160 do local p=point(i*80);candidates[i]={key='objective:'..i,questID=i,kind='objective',point=p,mapID=1431,ownerKey='fixture'} end
local input={state={key='fixture',level=30,mapID=1431,zone='fixture',now=100,questLogReady=true,freeSlots=10,player=point(0),profile={skipped={},includeGroup=false,maxLevelAbove=2}},meta={candidates=candidates,deferred={},ready=true}}
local expected,queue=W.SelectRoute(input);local published=0;local result
local function done(route,steps) published=published+1;result=route;assert(route.key==expected.key and #steps==#queue,'asynchronous result differs') end
local function fail(err) error(err) end
W.ScheduleSelection(input,done,fail)
assert(W.PendingPlan and published==0,'selector failed to yield before publishing')
local slices=0;while #tasks>0 do table.remove(tasks,1)();slices=slices+1;assert(slices<2000,'selector never completed') end
assert(published==1 and not W.PendingPlan and result.key==expected.key,'complete decision not published atomically')
W.ScheduleSelection(input,done,fail);W.CancelPlanning();while #tasks>0 do table.remove(tasks,1)() end
assert(published==1,'cancelled work published')
W.ScheduleSelection(input,done,fail);W.ProviderGeneration=2;while #tasks>0 do table.remove(tasks,1)() end
assert(published==1 and not W.PendingPlan,'old provider generation published or retained its snapshot')
W.ScheduleSelection(input,done,fail);combat=true;while #tasks>0 do table.remove(tasks,1)() end
assert(published==1 and not W.PendingPlan,'combat did not cancel pending selection');combat=false
W.ScheduleSelection(input,done,fail);map=true;while #tasks>0 do table.remove(tasks,1)() end
assert(published==1 and not W.PendingPlan,'map did not cancel pending selection')
map=false
W.ScheduleSelection(input,done,fail);W.GetCharacterKey=function() return 'other-character' end;while #tasks>0 do table.remove(tasks,1)() end
assert(published==1 and not W.PendingPlan,'old character work published')
print('PASS async selection yields, matches synchronous decisions and cancels stale/map/combat work')
