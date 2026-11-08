-- No client/provider/profile API is installed in this process.
unpack=unpack or table.unpack;math.atan2=math.atan2 or function(y,x) return math.atan(y,x) end
for _,name in ipairs({"Common","Data","Planner","Replay","Navigator"}) do dofile("Wayfinder/"..name..".lua") end
local W=Wayfinder
W.Q=function() error("Selector read provider data") end
W.GetProfile=function() error("Selector read a mutable profile") end
W.Now=function() error("Selector read live clock") end
local passed=0
local function check(name,value) assert(value,name);passed=passed+1;print("PASS engine / "..name) end
local function point(x,y,map)
 return {mapID=map or 1431,x=x,y=y,units="normalized",frame="uimap",continent=0,wx=-y*4000,wy=-x*6000,ex=0,ey=-6000,sx=-4000,sy=0}
end
local function step(kind,id,x,y,map)
 local p=point(x,y,map)
 return {kind=kind,questID=id,key=kind..":"..id,questName="Quest "..id,title="Quest "..id,point=p,mapID=p.mapID,x=x,y=y,ownerKey="character",fingerprint="objective:0",targetRevision="fixture-v1",source="synthetic"}
end
local function input(candidates,x,y)
 return {state={key="character",level=22,mapID=1431,zone="Duskwood",now=100,historyReady=true,questLogReady=true,freeSlots=10,player=point(x or .73,y or .46),profile={paused=false,skipped={},includeGroup=false,maxLevelAbove=2}},meta={candidates=candidates,deferred={},gates={},ready=true,databaseStatus="fixture ready"},weights=W.Copy(W.RouteWeights)}
end
local a=step("pickup",100,.732,.46);local b=step("pickup",101,.74,.46);local workA=step("objective",200,.65,.6);local workB=step("objective",201,.645,.61);local ready=step("turnin",300,.73,.46)
local previous
local journey={
 {event="arrive_darkshire",input=input({a,b,workA,workB,ready}),expected=ready.key},
 {event="turn_in",input=input({a,b,workA,workB}),expected=a.key},
 {event="accept_first",input=input({b,workA,workB}),expected=b.key},
 {event="accept_second",input=input({workA,workB},.74,.46),expected=workA.key},
 {event="complete_first_area_goal",input=input({step("turnin",200,.73,.46),workB},.65,.6),expected=workB.key},
 {event="complete_second_area_goal",input=input({step("turnin",200,.73,.46),step("turnin",201,.74,.46)},.645,.61),expected="turnin:200"},
}
local fixtureFrames={};local switches=0
for _,frame in ipairs(journey) do
 frame.input.previous=W.Copy(previous)
 local route,queue,detail=W.SelectRoute(frame.input)
 check(frame.event,route.key==frame.expected)
 local keys={};for _,q in ipairs(queue) do keys[#keys+1]=q.key end
 fixtureFrames[#fixtureFrames+1]={event=frame.event,input=W.Copy(frame.input),expected={key=route.key,queue=keys,clearPin=detail.clearPin==true}}
 if previous and route.key~=previous.key then switches=switches+1 end;previous=route
end
check("whole journey changes only after explicit progress",switches==5)
local stable=input({workA,workB},.65,.6);stable.previous=W.Copy(workA)
local route=W.SelectRoute(stable);check("stable unfinished objective remains selected",route.key==workA.key)
local original=W.Json(stable);W.SelectRoute(stable);check("input is unchanged after selection",W.Json(stable)==original)
local identical=true
for i=1,30 do
 local sample=input(i%2==0 and {workA,workB,a,b} or {b,a,workB,workA});local one,queue=W.SelectRoute(sample)
 local other,otherQueue=W.SelectRoute(input({a,b,workA,workB}))
 if one.key~=other.key or W.Json(queue)~=W.Json(otherQueue) then identical=false end
end
check("candidate enumeration order does not change route or queue",identical)
local leg=input({step("objective",400,.8,.5),step("objective",401,.81,.5),step("objective",402,.2,.5)},.1,.5);leg.state.profile.pinned="objective:400"
local first,nextSteps=W.SelectRoute(leg);check("queue evaluates from preceding leg",first.questID==400 and nextSteps[1].questID==401)
local pinned=input({a,b});pinned.state.profile.pinned="no-longer-valid"
local _,_,detail=W.SelectRoute(pinned);check("expired focus is returned as an effect, not written into input",detail.clearPin and pinned.state.profile.pinned=="no-longer-valid")
local skipped=input({a,b});skipped.state.profile.skipped["quest:100"]=1000
check("temporary skip excludes quest",W.SelectRoute(skipped).questID==101)
skipped.state.now=1001;check("expired skip no longer excludes quest",W.SelectRoute(skipped).questID==100)
local waiting=input({a});waiting.state.questLogReady=false;check("unready log never produces an action",W.SelectRoute(waiting).kind=="wait")
waiting.state.questLogReady=true;waiting.state.profile.paused=true;check("pause is deterministic",W.SelectRoute(waiting).key=="paused")
waiting.state.profile.paused=false;waiting.state.dead=true;check("death is deterministic",W.SelectRoute(waiting).key=="dead")
local sc=input({ready,a});local result=W.SelectRoute(sc);local parts=result.scoreParts
check("score has an auditable exact breakdown",math.abs(result.score-(parts.distance+parts.action+parts.cluster+parts.zone+parts.class+parts.capacity+parts.batching))<.00001)
local distant=input({step("turnin",500,.73,.46),step("objective",501,.655,.6)},.65,.6)
check("remote hand-in does not interrupt neighboring work",W.SelectRoute(distant).questID==501)
local elfA=step("objective",600,.60,.60,1438);local elfB=step("objective",601,.61,.61,1438);local elfPickup=step("pickup",602,.561,.60,1438)
local function elfInput(candidates,x,y)
 local value=input(candidates,x or .56,y or .60);value.state.mapID=1438;value.state.zone="Teldrassil";value.state.level=7;value.state.player.mapID=1438;return value
end
local elfJourney={
 {event="resume_in_teldrassil",input=elfInput({elfA,elfPickup}),expected=elfPickup.key},
 {event="accept_local_quest",input=elfInput({elfA,elfB}),expected=elfA.key},
 {event="finish_first_nearby_objective",input=elfInput({step("turnin",600,.56,.6,1438),elfB},.60,.60),expected=elfB.key},
 {event="finish_second_nearby_objective",input=elfInput({step("turnin",600,.56,.6,1438),step("turnin",601,.561,.6,1438)},.61,.61),expected="turnin:601"},
}
previous=nil
for _,frame in ipairs(elfJourney) do
 frame.input.previous=W.Copy(previous)
 local route,queue,detail=W.SelectRoute(frame.input);check(frame.event,route.key==frame.expected)
 local keys={};for _,q in ipairs(queue) do keys[#keys+1]=q.key end
 fixtureFrames[#fixtureFrames+1]={event=frame.event,input=W.Copy(frame.input),expected={key=route.key,queue=keys,clearPin=detail.clearPin==true}};previous=route
end
local map=point(.65,.6);local nav=W.ComputeNavigation(workA,map,0,nil)
check("navigation can be computed without live APIs",nav.arrived and nav.distance==0)
-- Four local objectives, distant ready hand-ins and a nearby town pickup.
local readyTown=step("turnin",700,.72,.68)
local batch={readyTown,step("pickup",701,.72,.68)}
for i=1,4 do batch[#batch+1]=step("objective",710+i,.797+i*.002,.685) end
local batchInput=input(batch,.797,.685);batchInput.previous=W.Copy(readyTown)
local batchRoute,batchQueue=W.SelectRoute(batchInput)
check("four-quest batch overrides a previous return-to-town instruction",batchRoute.kind=="objective")
local batchAll=true
for _,value in ipairs(batchQueue) do if value.kind~="objective" and value.questID~=700 then batchAll=false end end
check("batch queue leaves town hand-ins behind remaining local work",batchQueue[1].kind=="objective" and batchQueue[2].kind=="objective" and batchQueue[3].kind=="objective")
for i=1,4 do
 local remaining={step("turnin",700,.72,.68)}
 for j=i+1,4 do remaining[#remaining+1]=step("objective",710+j,.797+j*.002,.685) end
 local value=input(remaining,.797+i*.002,.685);value.previous=W.Copy(readyTown)
 local selected=W.SelectRoute(value)
 check("batch progression "..i,i==4 and selected.kind=="turnin" or i<4 and selected.kind=="objective")
end
local full=input({readyTown,step("objective",720,.8,.685)},.797,.685);full.state.freeSlots=0
check("full quest log does not force leaving unfinished local objectives",W.SelectRoute(full).kind=="objective")
local skippedBatch=input({readyTown,step("objective",720,.8,.685)},.797,.685);skippedBatch.state.profile.skipped["quest:720"]=1000
check("skipped local work does not hold the batch open",W.SelectRoute(skippedBatch).kind=="turnin")
local pin=input({readyTown,step("objective",720,.8,.685)},.797,.685);pin.state.profile.pinned=readyTown.key
check("explicit manual focus may leave a local batch",W.SelectRoute(pin).kind=="turnin")
local nearbyHandin=input({step("turnin",730,.797,.685),step("objective",731,.8,.685)},.797,.685)
check("a turn-in at the current location remains usable",W.SelectRoute(nearbyHandin).kind=="turnin")
local distantWork=input({readyTown,step("objective",740,.4,.3)},.797,.685)
check("distant objectives do not create an endless local batch",W.SelectRoute(distantWork).kind=="turnin")
local later=input({readyTown,step("objective",750,.8,.685)},.797,.685);later.state.profile.deferredLevels={[750]=25}
local laterOriginal=W.Json(later);local lr,lq,ld=W.SelectRoute(later)
check("deferred objectives do not keep town return blocked",lr.kind=="turnin" and #ld.levelDeferred==1)
check("deferred quest remains in planned queue",lq[1].levelDeferred and lq[1].resumeLevel==23)
check("deferral selection leaves input immutable",W.Json(later)==laterOriginal)
later.state.level=23;check("pure selector resumes deferred work at level threshold",W.SelectRoute(later).questID==750)
later.state.level=22;later.state.profile.maxLevelAbove=4;check("pure selector resumes after range expansion",W.SelectRoute(later).questID==750)
-- A captured level-deferral frame must round-trip numeric quest keys in JSON.
later.state.profile.maxLevelAbove=2
local rr,rq,rd=W.SelectRoute(later);local qkeys={};for _,value in ipairs(rq) do qkeys[#qkeys+1]=value.key end
fixtureFrames[#fixtureFrames+1]={event="defer-until-level",input=later,expected={key=rr.key,queue=qkeys,clearPin=rd.clearPin==true}}
local f=io.open("tests/journey-replay.json","w");f:write(W.Json({schema=1,origin="synthetic-journey",addonVersion=W.Version,frames=fixtureFrames}));f:close()
print(passed.." pure engine checks passed")

