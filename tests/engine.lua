-- No client/provider/profile API is installed in this process.
unpack=unpack or table.unpack;math.atan2=math.atan2 or function(y,x) return math.atan(y,x) end
for _,name in ipairs({"Common","Data","Experience","Planner","Replay","Navigator"}) do dofile("Wayfinder/"..name..".lua") end
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
-- Regional commitments survive volatile per-kill XP estimates and level-ups.
local dusk=step("objective",800,.797,.685)
local ridge=step("objective",801,.2,.2,1433)
local function economy(rate)
 return {rewardXP=rate,receiver=point(.797,.685),goals={},confidence="medium",interactionSeconds=3600}
end
dusk.economyModel=economy(4000);ridge.economyModel=economy(40000)
local regional=input({ridge,dusk},.797,.685);regional.state.experience={enabled=true,moveSpeed=7,referenceRate=4000}
local r1,q1,d1=W.SelectRoute(regional)
check("initial regional plan prefers actual Duskwood work over speculative Redridge gain",r1.mapID==1431 and d1.commitment.mapID==1431)
local stableRegion=true;local replayPrevious=r1;local replayCommitment=d1.commitment
for kill=1,20 do
 local value=W.Copy(regional);value.state.now=100+kill*20;value.state.level=kill>10 and 23 or 22
 value.meta.candidates[1].economyModel.rewardXP=kill%2==0 and 150000 or 1000
 value.meta.candidates[2].economyModel.rewardXP=kill%3==0 and 1000 or 8000
 value.previous=W.Copy(replayPrevious);value.commitment=W.Copy(replayCommitment)
 local chosen,queue,detail=W.SelectRoute(value)
 if chosen.key~=dusk.key then stableRegion=false end
 local keys={};for _,step in ipairs(queue) do keys[#keys+1]=step.key end
 fixtureFrames[#fixtureFrames+1]={event="duskwood-kill-"..kill,input=value,expected={key=chosen.key,queue=keys,clearPin=detail.clearPin==true}}
 replayPrevious=chosen;replayCommitment=detail.commitment
end
check("twenty kills and a level-up cause no Duskwood Redridge oscillation",stableRegion)
local remaining=input({ridge},.797,.685);remaining.state.experience=regional.state.experience;remaining.commitment=d1.commitment;remaining.previous=r1
local exhausted=W.SelectRoute(remaining);check("region changes when its usable batch is exhausted",exhausted.mapID==1433)
local complete=input({ridge,step("turnin",800,.73,.46)},.797,.685);complete.commitment=d1.commitment;complete.previous=r1
check("completed objective advances to local hand-in instead of holding stale work",W.SelectRoute(complete).kind=="turnin")
local manual=W.Copy(regional);manual.releasePlan=true;manual.force=true
check("explicit replan may evaluate a cross-zone alternative",W.SelectRoute(manual).mapID==1433)
local move=W.Copy(regional);move.commitment=d1.commitment;move.previous=r1;move.previousMapID=1431;move.state.mapID=1433;move.state.player=point(.2,.2,1433)
check("physically entering another quest zone adapts the commitment",W.SelectRoute(move).mapID==1433)
local localSwitch=input({workA,workB},.65,.6);localSwitch.previous=W.Copy(workA);localSwitch.previous.ownerKey="character";localSwitch.meta.candidates[2].economyModel=economy(50000);localSwitch.state.experience=regional.state.experience
check("unfinished objective remains committed despite higher estimated local XP",W.SelectRoute(localSwitch).key==workA.key)
local currentSkipped=W.Copy(localSwitch);currentSkipped.state.profile.skipped["quest:"..workA.questID]=1000
check("skip immediately releases committed objective",W.SelectRoute(currentSkipped).key~=workA.key)
local updated=input({W.Copy(workA)},.65,.6);updated.previous=W.Copy(workA);updated.previous.ownerKey="character";updated.previous.fingerprint="old-count";updated.meta.candidates[1].fingerprint="new-count";updated.meta.candidates[1].point=point(.66,.6);updated.meta.candidates[1].x=.66
check("partial progress does not chase a different spawn of the same objective",W.SelectRoute(updated).point.x==workA.point.x)
-- Reported Ban'ethil case: finish the remaining cave collection before Crown.
local quill=step("objective",9200,.465,.589,1438);quill.workAreaID="banethil";quill.regionMapID=1438;quill.remaining=1
local rune=W.Copy(quill);rune.key="objective:9200:rune";rune.point=point(.47,.60,1438);rune.x=.47;rune.y=.60
local crown=step("objective",9201,.424,.671,1438);crown.economyModel=economy(500000)
local cave=input({crown,quill,rune});cave.state.mapID=1438;cave.state.regionMapID=1438;cave.state.player=point(.447,.589,1438)
cave.state.workArea={id="banethil",kind="cave",mapID=1438};cave.state.experience=W.Copy(regional.state.experience)
cave.previous=W.Copy(crown);cave.previous.ownerKey="character"
local immutable=W.Json(cave);local cr,cq=W.SelectRoute(cave)
check("cave collection beats a different objective with much higher XP",cr.questID==quill.questID)
check("remaining cave objective is queued before the exit",cq[1].questID==quill.questID)
check("work-area selection does not mutate the replay input",W.Json(cave)==immutable)
local forced=W.Copy(cave);forced.force=true
check("routine forced refresh does not abandon cave work",W.SelectRoute(forced).questID==quill.questID)
local oneLeft=W.Copy(cave);oneLeft.meta.candidates={crown,quill};oneLeft.previous=cr
check("one remaining quest item keeps the cave batch active",W.SelectRoute(oneLeft).key==quill.key)
local changedCount=W.Copy(oneLeft);changedCount.meta.candidates[2].remaining=1;changedCount.meta.candidates[2].fingerprint="new-item-count"
check("partial item progress cannot release cave area priority",W.SelectRoute(changedCount).key==quill.key)
local otherFloor=W.Copy(oneLeft);otherFloor.meta.candidates[2].point.mapID=61;otherFloor.meta.candidates[2].mapID=61
check("cave floor map is ranked within its parent quest region",W.SelectRoute(otherFloor).key==quill.key)
local farInside=W.Copy(oneLeft);farInside.meta.candidates[2].point=point(.65,.65,1438)
check("known cave work stays local even beyond the surface radius",W.SelectRoute(farInside).key==quill.key)
local outdoor=input({step("objective",9300,.8,.685),step("objective",9301,.5,.3)},.797,.685)
outdoor.state.experience=W.Copy(regional.state.experience);outdoor.meta.candidates[2].economyModel=economy(500000)
check("outdoor unfinished work also beats a distant quest objective",W.SelectRoute(outdoor).questID==9300)
local after=W.Copy(oneLeft);after.meta.candidates={crown}
check("finishing all cave work permits the next outside objective",W.SelectRoute(after).key==crown.key)
local skipCave=W.Copy(oneLeft);skipCave.state.profile.skipped["quest:9200"]=1000
check("explicit skip releases cave work immediately",W.SelectRoute(skipCave).key==crown.key)
local pinCave=W.Copy(oneLeft);pinCave.state.profile.pinned=crown.key
check("explicit manual quest focus may leave the cave",W.SelectRoute(pinCave).key==crown.key)
local dangerCave=W.Copy(oneLeft);dangerCave.state.combatSafety={alert={name="Danger"}}
check("cave batch never overrides immediate danger stop",W.SelectRoute(dangerCave).key=="danger")
local unsafeCave=W.Copy(oneLeft);unsafeCave.meta.candidates[2].combatRisk={status="blocked",maxLevel=29,rank=0}
check("area protection does not make an unsafe candidate actionable",W.SelectRoute(unsafeCave).key~=quill.key)
local grindCave=W.Copy(oneLeft);grindCave.state.combatSafety={grindAllowed=true};grindCave.state.experience.grind={valid=true,rate=100000000,point=quill.point}
grindCave.meta.candidates[2].economyModel=economy(4000)
check("measured grinding cannot interrupt unfinished cave collection",W.SelectRoute(grindCave).key==quill.key)
local opportunity=W.Copy(quill);opportunity.kind="pickup";opportunity.key="pickup:9400";opportunity.questID=9400;opportunity.activity="escort"
local caveOffer=W.Copy(cave);caveOffer.meta.candidates={crown,quill,opportunity}
check("nearby escort offer does not start before unfinished cave work",W.SelectRoute(caveOffer).key==quill.key)
local nextEscort=W.Copy(caveOffer);nextEscort.meta.candidates={crown,opportunity}
local er,eq,ed=W.SelectRoute(nextEscort)
check("nearby cave escort is not skipped for a richer outside objective",er.key==opportunity.key and #ed.opportunities==1)
local escort=step("escort",9400,.447,.589,1438);escort.point=nil;escort.mapID=nil;escort.x=nil;escort.y=nil
local activeEscort=W.Copy(cave);activeEscort.meta.candidates={crown,quill,escort}
check("active escort takes precedence over ordinary quest objectives",W.SelectRoute(activeEscort).kind=="escort")
activeEscort.state.profile.skipped["quest:9400"]=1000
check("explicit skip can release an escort commitment",W.SelectRoute(activeEscort).kind~="escort")
local unknownInterior=W.Copy(oneLeft);unknownInterior.state.workArea={id="interior:1438:Unknown den",kind="interior",mapID=1438};unknownInterior.meta.candidates[2].workAreaID=nil
unknownInterior.state.workFocus={questID=quill.questID,point=quill.point,context=unknownInterior.state.workArea.id}
check("actual quest progress protects work in an unmapped interior",W.SelectRoute(unknownInterior).key==quill.key)
local progressOutside=W.Copy(outdoor);progressOutside.meta.candidates[2].point=point(.84,.685);progressOutside.meta.candidates[2].mapID=1431
progressOutside.previous=W.Copy(progressOutside.meta.candidates[2]);progressOutside.state.workFocus={questID=9300}
check("recent local progress corrects an already selected competing objective",W.SelectRoute(progressOutside).questID==9300)
for _,record in ipairs({{event="banethil-other-objective-wins-XP",value=cave},{event="banethil-last-item",value=oneLeft},{event="banethil-all-local-work-complete",value=after}}) do
 local r,q,d=W.SelectRoute(record.value);local keys={};for _,v in ipairs(q) do keys[#keys+1]=v.key end
 fixtureFrames[#fixtureFrames+1]={event=record.event,input=record.value,expected={key=r.key,queue=keys,clearPin=d.clearPin==true}}
end
local f=io.open("tests/journey-replay.json","w");f:write(W.Json({schema=1,origin="synthetic-journey",addonVersion=W.Version,frames=fixtureFrames}));f:close()
print(passed.." pure engine checks passed")

