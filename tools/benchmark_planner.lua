-- Synthetic selector timing only; this is not a WoW frame-time measurement.
unpack=unpack or table.unpack;math.atan2=math.atan2 or function(y,x) return math.atan(y,x) end
for _,name in ipairs({"Common","Data","Experience","Planner","Replay","Navigator"}) do dofile("Trailwarden/"..name..".lua") end
local W=Trailwarden
W.Q=function() error("selector benchmark must not read provider data") end
W.GetProfile=function() error("selector benchmark must not read a mutable profile") end
local function point(x,y)
    return {mapID=1431,x=x,y=y,units="normalized",frame="uimap",continent=0,wx=-y*4000,wy=-x*6000,ex=0,ey=-6000,sx=-4000,sy=0}
end
local function sample(count)
    local candidates={}
    for i=1,count do
        local x=.1+(i%29)*.025;local y=.1+(math.floor(i/29)%29)*.025;local p=point(x,y)
        candidates[i]={kind="objective",questID=10000+i,key="objective:"..i,point=p,mapID=p.mapID,x=x,y=y,ownerKey="benchmark",targetRevision="v1"}
    end
    return {state={key="benchmark",level=30,mapID=1431,zone="synthetic",now=1,questLogReady=true,freeSlots=10,player=point(.5,.5),profile={paused=false,skipped={},includeGroup=false,maxLevelAbove=2}},meta={candidates=candidates,deferred={},gates={},ready=true},weights=W.Copy(W.RouteWeights)}
end
for _,count in ipairs({40,80,128,160,320}) do
    local input=sample(count);local samples={}
    for run=1,7 do
        local start=os.clock();W.SelectRoute(input);samples[#samples+1]=(os.clock()-start)*1000
    end
    table.sort(samples);print(count.." candidates: median "..string.format("%.2f",samples[4]).." ms (7 selector-only runs)")
end
