local W=Trailwarden
local serial=0;local active
function W.CancelPlanning()
    serial=serial+1;W.PendingPlan=nil
end
function W.YieldPlanning()
    if not active then return end
    active.operations=active.operations+1
    if active.operations%32~=0 then return end
    local expired
    if type(debugprofilestop)=='function' then expired=debugprofilestop()-active.started>=2 else expired=active.operations>=512 end
    if expired then coroutine.yield() end
end
function W.ScheduleSelection(input,done,failed)
    W.CancelPlanning()
    local job={serial=serial,generation=W.ProviderGeneration,key=input.state.key,operations=0}
    job.thread=coroutine.create(function() return W.SelectRoute(input) end)
    W.PendingPlan=job
    local function step()
        if job.serial~=serial then return end
        if job.generation~=W.ProviderGeneration or W.GetCharacterKey()~=job.key then W.CancelPlanning();return end
        if W.IsCombatActive() or W.IsWorldMapOpen() or (W.MapQuietRemaining or 0)>0 then
            W.CancelPlanning();W.CombatRefreshPending=true;W.MapRefreshPending=true;return
        end
        job.operations=0;job.started=type(debugprofilestop)=='function' and debugprofilestop() or 0
        active=job;local _,ok,route,queue,detail=W.TimedCall("selector slice",coroutine.resume,job.thread);active=nil
        if job.serial~=serial then return end
        if job.generation~=W.ProviderGeneration then W.CancelPlanning();return end
        if not ok then W.PendingPlan=nil;failed(route);return end
        if coroutine.status(job.thread)~='dead' then C_Timer.After(.01,step);return end
        W.PendingPlan=nil;detail.input=input;done(route,queue,detail)
    end
    step()
end
function W.ShouldScheduleSelection(force,trigger)
    if force or not C_Timer or type(C_Timer.After)~='function' then return false end
    return trigger=='catalog-published' or trigger=='movement' or trigger=='maintenance' or trigger=='XP_REVIEW' or trigger=='combat-ended' or type(trigger)=='string' and trigger:find('QUEST_',1,true)~=nil
end
