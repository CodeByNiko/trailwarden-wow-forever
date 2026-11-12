-- Synthetic allocation/work budgets; these are not live WoW FPS measurements.
unpack=unpack or table.unpack;loadstring=loadstring or load
local tasks,ids,coords={},{},{}
for i=1,500 do ids[i]=i end
for i=1,100 do coords[i]={i%100,(i*13)%100} end
C_Timer={After=function(_,fn) tasks[#tasks+1]=fn end}
local worldReads=0
function CreateVector2D(x,y) return {GetXY=function() return x,y end} end
C_Map={GetMapInfo=function() return {mapType=3} end,GetWorldPosFromMapPos=function(_,v) worldReads=worldReads+1;local x,y=v:GetXY();return 0,CreateVector2D(x*6000,y*4000) end}
LibQuestieDB={Quest={GetAllIds=function() return ids end,Get=function(id,key)
 if key=='name' then return 'Quest '..id elseif key=='startedBy' then return {{id}} else return 1 end
end},Npc={Get=function(id,key) if key=='spawns' then return {[1]=coords} elseif key=='name' then return 'NPC '..id end end},Support={Get=function() return {private={areaIdToUiMapId={[1]=1431}}} end}}
dofile('Trailwarden/Common.lua');dofile('Trailwarden/Data.lua')
dofile(os.getenv('TRAILWARDEN_DATABASE_FILE') or 'Trailwarden/Database.lua')
local W=Trailwarden
collectgarbage('collect');local before=collectgarbage('count');local start=os.clock()
W.BuildQuestCatalog(true)
local calls=0;while #tasks>0 do table.remove(tasks,1)();calls=calls+1;assert(calls<2000,'catalog did not finish') end
collectgarbage('collect')
print(string.format('500-quest catalog: %.1f ms, %.1f KiB retained, %d world-coordinate API calls',(os.clock()-start)*1000,collectgarbage('count')-before,worldReads))
assert(W.CatalogReady and W.CatalogCount==500 and #W.CatalogByMap[1431]==500,'catalog lost quests')
if os.getenv('TRAILWARDEN_PERF_BASELINE')~='1' then
 assert(worldReads==0 and W.EntityCacheEntries==0,'catalog must not expand/cache world points')
 for id=1,500 do assert(#W.EntityPoints('Npc',id)>0) end
 assert(W.EntityCacheEntries<=128 and W.EntityCachePoints<=4096,'point cache exceeded retained-data budget')
 assert(#W.EntityPoints('Npc',1)>0,'evicted point must remain recoverable')
 print('PASS global catalog avoids point expansion; runtime point cache stays bounded and recovers evictions')
end
-- Diagnostic replay retention must be bounded independently of session length.
dofile('Trailwarden/Replay.lua')
local input={state={key='fixture',profile={skipped={},deferredLevels={}}},meta={candidates={}}}
local decision={trigger='fixture',state={key='fixture',now=1,signature='fixture'},route={key='wait'},queue={},detail={input=input}}
for i=1,100 do W.RecordDecision(decision) end
assert(#W.ReplayFrames==20 and W.ReplayEntries<=24000,'replay retention grew with session length')
local beforeDropped=W.ReplayDropped or 0
input.meta.large={};for i=1,20000 do input.meta.large[i]=i end
W.RecordDecision(decision)
assert((W.ReplayDropped or 0)==beforeDropped+1 and #W.ReplayFrames==20 and W.ReplayEntries<=24000,'oversized replay exceeded memory budget')
input.meta.large=nil
print('PASS replay remains bounded after repeated decisions and rejects oversized snapshots')
