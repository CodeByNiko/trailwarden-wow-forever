-- Provider ownership, invalidation and index compatibility without private provider tables.
unpack=unpack or table.unpack;loadstring=loadstring or load
local version,locale,level,spawnMap='fixture','enUS',7,1431
local ids={1};local reads=0;local timers={}
function GetAddOnMetadata() return version end
function GetBuildInfo() return '1.60.1','70245' end
function GetLocale() return locale end
function GetServerTime() return 100 end
function hooksecurefunc(owner,key,callback)
 local original=owner[key]
 owner[key]=function(...) local a,b,c,d=original(...);callback(...);return a,b,c,d end
end
C_Map={GetMapInfo=function() return {mapType=3} end}
local function getter(kind,id,key)
 reads=reads+1
 if key=='name' then return locale..' '..kind..id end
 if key=='startedBy' then return {{1}} end
 if key=='spawns' then return {[spawnMap]={{50,50}}} end
 if key=='questLevel' then return level end
 if key=='requiredLevel' then return 1 end
 return 0
end
LibQuestieDB={contractVersion=4,minSupportedContract=1,mode='baked',flavor={name='Forever'},RequireContract=function(v) return v>=1 and v<=4 end,
 Quest={GetAllIds=function() return ids end,Get=function(id,key) return getter('Quest',id,key) end},
 Npc={Get=function(id,key) return getter('Npc',id,key) end},Object={Get=function(id,key) return getter('Object',id,key) end},
 GetProvenance=function(kind,id,field) if kind=='Npc' and field=='spawns' and spawnMap~=1431 then return 'FixtureCorrection' end;return 'QuestieDB' end,Support={Get=function() return {private={areaIdToUiMapId={[1431]=1431,[1438]=1438}}} end},
 InvalidateCache=function() end,ApplyRegisteredCorrections=function() level=8 end,
 Corrections={Set=function() spawnMap=1438;return true end,ApplyRegisteredCorrections=function() end,UnregisterCorrection=function() end},
 l10n={SetLocale=function(value) locale=value end,SetCorrection=function() end}}
for _,name in ipairs({'Common','Data','Provider','Database'}) do dofile('Trailwarden/'..name..'.lua') end
local W=Trailwarden;local passed=0
local function check(label,ok) assert(ok,label);passed=passed+1;print('PASS lifecycle / '..label) end
check('compatible contract passes',W.EnsureProvider())
local index={schema=1,version='fixture',contract=4,build='70245',mode='baked',flavor='Forever',ids={1},maps={[1431]={1}},items={},entities={Npc={1},Object={}}}
W.ProviderCatalogIndex=index
W.BuildQuestCatalog(true)
check('verified compact catalog avoids all spawn reads',W.CatalogReady and W.CatalogIndexStatus=='verified offline zone index' and not W.ProviderReads['Npc.spawns'])
local a=W.DBRead('Npc',1,'spawns');local b=W.DBRead('Npc',1,'spawns')
check('provider fixture returns independent nested values',a~=b and a[1431]~=b[1431])
W.BeginDataCapture();local before=reads;local c=W.DBRead('Npc',1,'spawns');local d=W.DBRead('Npc',1,'spawns')
check('one planning pass reuses identical immutable reads',reads==before+1 and c==d)
W.EndDataCapture();W.BeginDataCapture();local e=W.DBRead('Npc',1,'spawns');W.EndDataCapture()
c[1431][1][1]=12
check('different passes do not share mutable values',e~=c and e[1431][1][1]==50)
W.BeginDataCapture();local large={};for i=1,10000 do large[i]=i end;W.RecordFact('Large',1,'field',large);local facts=W.EndDataCapture()
check('diagnostic capture is bounded independently of provider output',facts.truncated==true and not facts['Large:1'] and W.LastProviderPass.captureEntries==2000)
local get=LibQuestieDB.Npc.Get;local fail=true
LibQuestieDB.Npc.Get=function(...) if fail then error('transient') end;return get(...) end
W.BeginDataCapture();local _,status=W.DBRead('Npc',2,'spawns');fail=false;local recovered=W.DBRead('Npc',2,'spawns');W.EndDataCapture();LibQuestieDB.Npc.Get=get
check('errors are retried within the same pass',status=='error' and recovered[1431])
LibQuestieDB.InvalidateCache()
check('cache-only invalidation does not mark verified index dirty',not W.ProviderIndexDirty and not W.CatalogReady)
W.BuildQuestCatalog(true)
check('cache-only invalidation retains verified index',W.CatalogReady and W.CatalogIndexStatus=='verified offline zone index')
local cached=W.Q(1,'questLevel');LibQuestieDB.ApplyRegisteredCorrections()
check('public correction application invalidates local fields',cached==7 and W.Q(1,'questLevel')==8 and W.ProviderRebuildNeeded and not W.CatalogReady)
W.BuildQuestCatalog(true)
check('unrelated correction revalidates and preserves index',W.CatalogReady and W.CatalogIndexStatus=='verified offline zone index' and W.Q(1,'questLevel')==8)
LibQuestieDB.Corrections.Set('fixture','Npc','relocate',{})
W.BuildQuestCatalog(true)
check('corrected coordinates use runtime fallback and update the zone',W.CatalogReady and W.CatalogByMap[1438] and not W.CatalogByMap[1431] and W.CatalogIndexStatus~='verified offline zone index')
W.Q(1,'name');LibQuestieDB.l10n.SetLocale('deDE');W.EnsureProvider()
check('locale changes invalidate names without reviving a dirty index',W.Q(1,'name')=='deDE Quest1' and W.ProviderIndexDirty)
version='changed';W.EnsureProvider()
check('provider identity changes invalidate the published catalog',not W.CatalogReady and W.ProviderChangeReason=='provider identity changed')
local contract=LibQuestieDB.RequireContract;LibQuestieDB.RequireContract=function() return false end
W.BuildQuestCatalog(true)
check('incompatible provider is rejected explicitly',not W.CatalogReady and W.ProviderError and W.CatalogError==W.ProviderError)
LibQuestieDB.RequireContract=contract;W.EnsureProvider()
C_Timer={After=function(_,fn) timers[#timers+1]=fn end};for i=2,50 do ids[i]=i end
W.BuildQuestCatalog(true);LibQuestieDB.Corrections.Set('fixture','Npc','again',{})
while #timers>0 do table.remove(timers,1)() end
check('invalidated async catalog cannot publish its old generation',not W.CatalogReady and W.ProviderRebuildNeeded)
W.BuildQuestCatalog(true);while #timers>0 do table.remove(timers,1)() end
check('new catalog generation publishes after invalidation',W.CatalogReady and W.CatalogCount==50)
-- A full index must be verified across timer slices, and a data change must
-- prevent the old verification from publishing a catalog.
index.version='changed';index.ids={};for i,id in ipairs(ids) do index.ids[i]=id end
W.ProviderCatalogIndex=index
local clockMS=0;debugprofilestop=function() clockMS=clockMS+1;return clockMS end
W.BuildQuestCatalog(true)
check('index verification yields before finishing',W.BuildingCatalog and #timers>0)
W.InvalidateProviderData('fixture changed during verification',true)
while #timers>0 do table.remove(timers,1)() end
check('stale index verification cannot publish',not W.CatalogReady and W.ProviderRebuildNeeded)
print(passed..' provider lifecycle checks passed')
