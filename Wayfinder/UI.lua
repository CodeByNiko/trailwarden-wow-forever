local W=Wayfinder
local C={bg={0.025,0.043,0.065,0.97},card={0.047,0.078,0.105,1},raised={0.065,0.105,0.135,1},line={0.15,0.25,0.31,1},text={0.93,0.94,0.94},muted={0.59,0.69,0.74},cyan={0.36,0.83,0.84},gold={0.98,0.76,0.40},green={0.48,0.83,0.64}}
W.Colors=C
function W.Font(parent,size,color)
    local f=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
    f:SetFont("Fonts\\FRIZQT__.TTF",size,"");f:SetTextColor(unpack(color or C.text));f:SetJustifyH("LEFT");return f
end
function W.Backdrop(frame,color)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
    frame:SetBackdropColor(unpack(color or C.bg));frame:SetBackdropBorderColor(unpack(C.line))
end
function W.Button(parent,label,width,onClick)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate");b:SetSize(width,28);W.Backdrop(b,C.raised)
    b.label=W.Font(b,10,C.text);b.label:SetPoint("CENTER");b.label:SetJustifyH("CENTER");b.label:SetText(label)
    b:SetScript("OnClick",onClick)
    b:SetScript("OnDisable",function(self) self.label:SetTextColor(unpack(C.muted)) end)
    b:SetScript("OnEnable",function(self) self.label:SetTextColor(unpack(C.text)) end)
    b:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(C.cyan)) end)
    b:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(C.line));if GameTooltip then GameTooltip:Hide() end end)
    return b
end
function W.Tooltip(owner,title,lines)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner,"ANCHOR_LEFT");GameTooltip:SetText(title,unpack(C.gold))
    for _,line in ipairs(lines) do if line and line~="" then GameTooltip:AddLine(line,0.85,0.9,0.92,true) end end
    GameTooltip:Show()
end
local frame,body,settings,settingsOpen,rows,settingRows
local fields={}
local function atText(parent,text,size,color,x,y,width,height)
    local f=W.Font(parent,size,color);f:SetPoint("TOPLEFT",x,-y);f:SetSize(width,height);f:SetText(text);return f
end
function W.SetDisplayScale(field,value)
    if (field~="uiScale" and field~="navigatorScale") or not W.IsFinite(value) then return end
    W.GetProfile()[field]=math.max(.6,math.min(field=="uiScale" and 1.3 or 1.5,math.floor(value*100+.5)/100))
    W.ApplyPositions()
    if W.State then W.State.profile=W.Copy(W.GetProfile());W.UpdateUI() end
end
function W.ApplyPositions()
    if frame then
        local p=W.GetProfile();frame:ClearAllPoints()
        local pos=p.panelPoint
        if pos then frame:SetPoint(pos.point,UIParent,pos.relativePoint,pos.x,pos.y) else frame:SetPoint("RIGHT",UIParent,"RIGHT",-56,35) end
        frame:SetScale(p.uiScale)
    end
    if W.PositionNavigator then W.PositionNavigator() end
end
local function layout()
    local p=W.GetProfile();local compact=p.collapsed and not settingsOpen
    local count=p.queueRows
    frame:SetHeight(settingsOpen and 626 or compact and 374 or 450+count*38)
    fields.status:ClearAllPoints();fields.status:SetPoint("TOPLEFT",16,-(308+count*38))
    if settingsOpen then body:Hide();settings:Show() else body:Show();settings:Hide() end
    fields.thenLabel:SetShown(not compact and count>0);fields.status:SetShown(not compact)
    fields.empty:SetShown(not compact and count>0 and #(W.Queue or {})==0)
    fields.undo:SetShown(not compact and (p.lastSkipped~=nil or p.lastDeferred~=nil))
    for i,r in ipairs(rows) do r:SetShown(not compact and i<=count and r.step~=nil) end
    fields.fold.label:SetText(p.collapsed and "+" or "-")
end
function W.CreateUI()
    if frame then return end
    local p=W.GetProfile()
    frame=CreateFrame("Frame","WayfinderMainFrame",UIParent,"BackdropTemplate");W.MainFrame=frame
    frame:SetSize(360,526);frame:SetFrameStrata("MEDIUM");frame:SetClampedToScreen(true);frame:SetMovable(true);frame:EnableMouse(true);W.Backdrop(frame)
    local head=CreateFrame("Frame",nil,frame);head:SetPoint("TOPLEFT",1,-1);head:SetSize(358,50);head:EnableMouse(true);head:RegisterForDrag("LeftButton")
    head:SetScript("OnDragStart",function() if not W.GetProfile().locked then frame:StartMoving() end end)
    head:SetScript("OnDragStop",function() frame:StopMovingOrSizing();local a,_,b,x,y=frame:GetPoint(1);W.GetProfile().panelPoint={point=a,relativePoint=b,x=x,y=y} end)
    atText(head,"WAYFINDER",15,C.text,15,8,210,20)
    fields.subtitle=atText(head,"",9,C.muted,15,29,320,16)
    local line=head:CreateTexture(nil,"ARTWORK");line:SetColorTexture(unpack(C.line));line:SetPoint("BOTTOMLEFT");line:SetSize(358,1)
    local close=W.Button(head,"x",22,function() W.GetProfile().panelHidden=true;frame:Hide() end);close:SetPoint("TOPRIGHT",-9,-10);close:SetHeight(22)
    fields.fold=W.Button(head,"-",22,function() W.GetProfile().collapsed=not W.GetProfile().collapsed;layout() end);fields.fold:SetPoint("TOPRIGHT",-36,-10);fields.fold:SetHeight(22)
    local config=W.Button(head,"...",28,function() W.ToggleSettings() end);config:SetPoint("TOPRIGHT",-63,-10);config:SetHeight(22)
    body=CreateFrame("Frame",nil,frame);body:SetAllPoints(frame)
    fields.eyebrow=atText(body,"YOUR NEXT STEP",10,C.cyan,16,62,200,14)
    fields.mode=atText(body,"SOLO",9,C.muted,215,62,129,14);fields.mode:SetJustifyH("RIGHT")
    local card=CreateFrame("Frame",nil,body,"BackdropTemplate");card:SetPoint("TOPLEFT",16,-82);card:SetSize(328,144);W.Backdrop(card,C.card);card:EnableMouse(true)
    fields.action=atText(card,"",9,C.gold,12,9,304,14)
    fields.title=atText(card,"",16,C.text,12,28,304,35);fields.title:SetJustifyV("TOP");fields.title:SetWordWrap(true)
    fields.target=atText(card,"",11,C.cyan,12,65,304,16);fields.target:SetWordWrap(false)
    fields.instruction=atText(card,"",11,C.text,12,85,304,34);fields.instruction:SetJustifyV("TOP");fields.instruction:SetWordWrap(true)
    fields.source=atText(card,"",9,C.muted,12,125,304,13);fields.source:SetWordWrap(false)
    card:SetScript("OnEnter",function(self)
        local r=W.CurrentRoute or {};local z=W.Zones[W.State and W.State.mapID]
        W.Tooltip(self,r.title or "Why this step?",{r.instruction,r.reason,z and z.hint,"Source: "..(r.source or "Live character state"),"Automatic combat targets: at most +2 enemy levels. Blocked objectives stay in your quest log.","The arrow shows direction, not a terrain-safe path. Use roads and entrances.","Click a planned step to focus it. The plan updates as your quests change."})
    end)
    card:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    local strip=CreateFrame("Frame",nil,body,"BackdropTemplate");strip:SetPoint("TOPLEFT",16,-234);strip:SetSize(328,28);W.Backdrop(strip,C.raised)
    fields.distance=atText(strip,"",12,C.gold,10,6,100,18)
    fields.navStatus=atText(strip,"",9,C.muted,105,8,211,14);fields.navStatus:SetJustifyH("RIGHT")
    fields.thenLabel=atText(body,"PLANNED NEXT",9,C.cyan,16,278,220,14)
    fields.undo=W.Button(body,"Undo skip",84,W.UndoSkip);fields.undo:SetPoint("TOPRIGHT",-16,-273);fields.undo:SetHeight(22)
    fields.empty=atText(body,"",11,C.muted,25,305,310,60);fields.empty:SetJustifyV("TOP");fields.empty:SetWordWrap(true)
    rows={}
    for i=1,4 do
        local row=CreateFrame("Button",nil,body,"BackdropTemplate");row:SetPoint("TOPLEFT",16,-(300+(i-1)*38));row:SetSize(328,36);W.Backdrop(row,C.card)
        local number=atText(row,string.format("%02d",i+1),10,C.muted,8,10,22,14)
        row.title=atText(row,"",11,C.text,35,4,281,15);row.title:SetWordWrap(false)
        row.detail=atText(row,"",9,C.muted,35,21,281,12);row.detail:SetWordWrap(false)
        row:SetScript("OnClick",function(self) W.PinStep(self.step) end)
        row:SetScript("OnEnter",function(self) if self.step then W.Tooltip(self,self.step.title,{self.step.instruction,self.step.reason,self.step.safetyHeld and "Automatic combat limits cannot be bypassed with manual focus." or self.step.levelDeferred and "Click to resume this deferred quest now." or "Click to focus this quest step."}) end end)
        row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        rows[i]=row
    end
    fields.status=atText(body,"",9,C.muted,16,384,328,28);fields.status:SetWordWrap(true);fields.status:SetJustifyV("TOP")
    local xpHover=CreateFrame("Frame",nil,body,"BackdropTemplate");xpHover:SetPoint("BOTTOMLEFT",16,52);xpHover:SetSize(328,52);xpHover:EnableMouse(true);W.Backdrop(xpHover,C.card)
    atText(xpHover,"EXPERIENCE / HOUR",8,C.muted,12,8,148,12)
    atText(xpHover,"NEXT LEVEL",8,C.muted,178,8,138,12)
    fields.xp=atText(xpHover,"Learning...",16,C.gold,12,25,148,21)
    fields.xpETA=atText(xpHover,"--",16,C.text,178,25,138,21)
    local divider=xpHover:CreateTexture(nil,"ARTWORK");divider:SetColorTexture(unpack(C.line));divider:SetPoint("TOPLEFT",164,-10);divider:SetSize(1,32)
    xpHover:SetScript("OnEnter",function(self)
        local e=W.SafeExperienceStats();local r=W.CurrentRoute or {};local m=r.economy
        W.Tooltip(self,"Experience and route estimates",{
            "Measured XP/h includes kills, quests and exploration. Travel and ordinary downtime count; pause/AFK do not.",
            "Session: "..W.FormatXP(e.totalXP).." XP / "..W.FormatXP(e.sessionRate).." XP/h. Rolling window: "..math.floor(e.windowSeconds/60).." min.",
            "Rewarded kills: "..e.kills.." / turn-ins: "..e.turnins..". Next level uses your measured rolling rate.",
            m and ("Route: ~"..W.FormatXP(m.xpPerHour).." XP/h / "..m.confidence.." confidence. "..(m.source or "Observed kills")) or "Quest XP/time data is incomplete; normal quest routing remains available.",
            "Quest projections include remaining work, travel and reward collection. New unaccepted quest quantities may be uncertain.",
            "Grind comparison: "..W.FormatXP(e.grind and e.grind.rate).." XP/h from verified local kills.",
            "The current region and unfinished objective stay committed; XP changes do not send you back and forth between zones.",
            W.ForecastError and "Forecast temporarily unavailable. Normal quest guidance remains active." or "Grind comparison needs at least 8 verified kills over 2 minutes. /wf xpreset resets session statistics."})
    end)
    xpHover:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    fields.skip=W.Button(body,"Skip 15 min",96,function() local r=W.CurrentRoute;local state=W.State;if W.DeferLevel(r,state) then W.DeferCurrent() else W.SkipCurrent() end end);fields.skip:SetPoint("BOTTOMLEFT",16,12)
    fields.skip:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(C.cyan));local r=W.CurrentRoute;local state=W.State
        local high=W.DeferLevel(r,state)
        if r and r.kind=="grind" then W.Tooltip(self,"Return to questing",{"End this grind break and resume the quest route. Automatic grind suggestions pause for two minutes."});return end
        W.Tooltip(self,high and "Skip for now" or "Defer this quest",{high and ("Keep this quest for later. It returns automatically at level "..(r.level-state.profile.maxLevelAbove).." with your current level range.") or "Skip the whole current quest for 15 minutes on this character.","Use Undo skip or click a Later step to resume immediately."}) end)
    fields.refresh=W.Button(body,"Auto route",96,function() local profile=W.GetProfile();profile.pinned=nil;profile.paused=false;W.CurrentRoute=nil;W.Refresh(true,"resume-auto") end);fields.refresh:SetPoint("BOTTOMLEFT",118,12)
    fields.arrow=W.Button(body,"Arrow: on",116,function() W.ToggleNavigator() end);fields.arrow:SetPoint("BOTTOMRIGHT",-16,12)
    settings=CreateFrame("Frame",nil,frame);settings:SetPoint("TOPLEFT",16,-75);settings:SetSize(328,545)
    atText(settings,"YOUR JOURNEY",10,C.cyan,0,0,328,16)
    atText(settings,"Preferences are saved for this character.",10,C.muted,0,25,328,28)
    local definitions={
        {"XP-aware routing",function(p) return p.xpRouting and "On" or "Off" end,function(p) p.xpRouting=not p.xpRouting end},
        {"Quest difficulty",function(p) return p.includeGroup and "Include group quests" or "Solo quests" end,function(p) p.includeGroup=not p.includeGroup end},
        {"New quest level",function(p) return "Up to +"..p.maxLevelAbove end,function(p) p.maxLevelAbove=p.maxLevelAbove==2 and 4 or 2 end},
        {"Map waypoint",function(p) return p.mapSync and "Automatic" or "Off" end,function(p) p.mapSync=not p.mapSync end},
        {"Navigator",function(p) return p.navigatorHidden and "Hidden" or "Visible" end,function(p) p.navigatorHidden=not p.navigatorHidden end},
        {"Panel scale",function(p) return math.floor(p.uiScale*100+0.5).."%" end,function(p) p.uiScale=p.uiScale>=1.19 and .6 or math.floor(p.uiScale*20+1.5)/20 end},
        {"Arrow scale",function(p) return math.floor(p.navigatorScale*100+0.5).."%" end,function(p) p.navigatorScale=p.navigatorScale>=1.49 and .6 or math.floor(p.navigatorScale*20+1.5)/20 end},
        {"Planned steps",function(p) return tostring(p.queueRows) end,function(p) p.queueRows=p.queueRows==2 and 4 or p.queueRows==4 and 0 or 2 end},
        {"Route planning",function(p) return p.paused and "Paused" or "Automatic" end,function(p) p.paused=not p.paused end},
        {"Window positions",function(p) return p.locked and "Locked" or "Drag to move" end,function(p) p.locked=not p.locked end},
    }
    settingRows={}
    for i,d in ipairs(definitions) do
        local b=W.Button(settings,"",328,function() local profile=W.GetProfile();d[3](profile);W.ApplyPositions();W.Refresh(false,"settings") end)
        b:SetPoint("TOPLEFT",0,-(58+(i-1)*29));b:SetHeight(26);settingRows[i]={button=b,definition=d}
    end
    local undo=W.Button(settings,"Restore skipped quests",328,function() W.GetProfile().skipped={};W.GetProfile().lastSkipped=nil;W.GetProfile().deferredLevels={};W.GetProfile().lastDeferred=nil;W.Refresh(true) end);undo:SetPoint("TOPLEFT",0,-362)
    local reset=W.Button(settings,"Reset window positions",328,function() local profile=W.GetProfile();profile.panelPoint=nil;profile.navigatorPoint=nil;W.ApplyPositions() end);reset:SetPoint("TOPLEFT",0,-398)
    local replan=W.Button(settings,"Replan region now",328,function() local profile=W.GetProfile();profile.pinned=nil;profile.paused=false;W.Refresh(true,"manual-replan") end);replan:SetPoint("TOPLEFT",0,-438)
    local debug=W.Button(settings,"Copy diagnostics",328,function() W.ShowDiagnostics() end);debug:SetPoint("TOPLEFT",0,-474)
    local back=W.Button(settings,"Back to your route",328,function() settingsOpen=false;layout() end);back:SetPoint("TOPLEFT",0,-510)
    head:EnableMouseWheel(true)
    head:SetScript("OnMouseWheel",function(_,delta) if not W.GetProfile().locked then W.SetDisplayScale("uiScale",W.GetProfile().uiScale+delta*.05) end end)
    head:SetScript("OnEnter",function(self) W.Tooltip(self,"Wayfinder",{"Drag to move. Mouse wheel adjusts panel size.","Use - to collapse the plan; ... opens display settings."}) end)
    head:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    W.ApplyPositions();layout();if p.panelHidden then frame:Hide() end
end
function W.UpdateUI()
    if not frame then W.CreateUI() end
    local state=W.State;if not state then return end
    frame.renderDecisionID=W.Decision and W.Decision.id or 0
    local p=state.profile;local r=W.CurrentRoute or {}
    fields.subtitle:SetText(string.format("%s  /  %s %s  /  %d",state.name,state.raceName,state.className,state.level))
    fields.mode:SetText(p.paused and "PAUSED" or p.pinned and "FOCUSED STEP" or string.upper(state.zone or "QUESTING"))
    fields.action:SetText((W.ActionLabels[r.kind] or "ROUTE")..(r.level and r.level>0 and ("  /  LEVEL "..r.level) or "")..(W.DeferLevel(r,state) and "  /  ABOVE RANGE" or ""))
    fields.title:SetFont("Fonts\\FRIZQT__.TTF",16,"")
    fields.title:SetText(r.questName or r.title or "Preparing your route")
    if fields.title.GetStringHeight then
        for size=15,11,-1 do
            if fields.title:GetStringHeight()<=35 then break end
            fields.title:SetFont("Fonts\\FRIZQT__.TTF",size,"")
        end
    end
    fields.target:SetText((r.target or state.zone)..(r.combatRisk and r.combatRisk.maxLevel and ("  /  Enemy level "..r.combatRisk.maxLevel) or ""))
    fields.instruction:SetText(r.instruction or "Reading your quest progress...")
    local location=r.point and string.format("%s  /  %.1f, %.1f",W.MapName(r.mapID),r.x*100,r.y*100) or state.zone
    fields.source:SetText(location.."  /  "..(r.source or "Live state"))
    for i,row in ipairs(rows) do
        local step=(W.Queue or {})[i];row.step=step
        if step then row.title:SetText(step.safetyHeld and step.title or step.levelDeferred and ("Later: "..(step.questName or step.title)) or step.title);row.detail:SetText(step.safetyHeld and (step.resumeLevel and ("Enemy levels / reconsider at level "..step.resumeLevel) or "Combat level data unverified") or step.levelDeferred and ("Returns at level "..step.resumeLevel.." / click to resume now") or (step.target or W.MapName(step.mapID)).."  /  "..(step.mapID and W.MapName(step.mapID) or "Your bags")) end
    end
    local status=string.format("%s  /  %d active  /  %d completed  /  %d free slots",state.zone,#state.activeQuests,state.completedCount,state.freeSlots)
    if W.CatalogError then status=status.."\nQuest catalog needs attention / /wf debug"
    elseif not W.CatalogReady then status=status.."\n"..(W.DatabaseStatus or "Waiting for data")
    elseif #(W.Unmapped or {})>0 then status=status.."\n"..#W.Unmapped.." deferred or unmapped quest(s)  /  /wf debug" end
    if not state.historyReady and not W.CatalogError and W.CatalogReady and #(W.Unmapped or {})==0 then status=status.."\nAwaiting completed quest history" end
    local safetyCount=0;local safetyReason
    for _,q in ipairs(W.Unmapped or {}) do if q.safety then safetyCount=safetyCount+1;safetyReason=safetyReason or q.reason end end
    if safetyCount>0 then status=state.zone.." / "..safetyCount.." combat objective(s) held / cap +2\n"..(safetyReason or "") end
    fields.status:SetText(status)
    local empty=not W.CatalogReady and "Reading quest data. Your next steps will appear here shortly."
        or #(W.Unmapped or {})>0 and "No further mapped steps yet. Some active quests need Questie, a different comfort setting or more complete quest data."
        or "This is the only mapped step right now. The plan will update when you accept, complete or turn in a quest."
    fields.empty:SetText(empty)
    fields.refresh.label:SetText(p.paused and "Resume route" or "Auto route")
    fields.arrow.label:SetText(p.navigatorHidden and "Arrow: off" or "Arrow: on")
    fields.skip.label:SetText(r.kind=="grind" and "Questing now" or W.DeferLevel(r,state) and "Skip for now" or "Skip 15 min")
    fields.skip:SetEnabled(r.questID~=nil or r.kind=="grind")
    local laterCount=W.Count(p.deferredLevels)
    if laterCount>0 then fields.status:SetText(status.." / "..laterCount.." saved for later") end
    for _,v in ipairs(settingRows) do v.button.label:SetText(v.definition[1]..":  "..v.definition[2](p)) end
    layout();W.UpdateLiveUI()
end
function W.UpdateLiveUI()
    if not fields.distance or not W.CurrentRoute then return end
    local e=W.SafeExperienceStats();local model=W.CurrentRoute.economy
    local measured=e.available and (e.maximum==0 and "Level cap" or e.paused and "Paused" or e.rate and W.FormatXP(e.rate) or "Learning...") or "Unavailable"
    fields.xp:SetText(measured)
    fields.xpETA:SetText(e.available and not e.paused and e.eta and ("~"..W.FormatETA(e.eta)) or "--")
    local n=W.Navigation or {}
    if W.Decision and n.decisionID~=W.Decision.id then fields.distance:SetText("");fields.navStatus:SetText("Synchronizing route");return end
    fields.distance:SetText(n.distance and W.FormatDistance(n.distance) or (W.CurrentRoute.kind=="item" and "In your bags" or ""))
    fields.navStatus:SetText(n.label or "")
end
function W.ToggleSettings()
    if not frame then W.CreateUI() end
    W.GetProfile().panelHidden=false;frame:Show();settingsOpen=not settingsOpen;W.UpdateUI()
end
function W.ToggleUI()
    if not frame then W.CreateUI() end
    local p=W.GetProfile();p.panelHidden=not p.panelHidden;frame:SetShown(not p.panelHidden)
    if not p.panelHidden then W.Refresh(false,"display") end
end
function W.ShowDiagnostics(content)
    if not W.DiagnosticsFrame then
        local f=CreateFrame("Frame","WayfinderDiagnosticsFrame",UIParent,"BackdropTemplate");f:SetSize(510,370);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:EnableMouse(true);W.Backdrop(f)
        atText(f,"WAYFINDER / DIAGNOSTICS",12,C.cyan,16,16,470,20)
        local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",16,-48);scroll:SetSize(452,265)
        local edit=CreateFrame("EditBox",nil,scroll);edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject(ChatFontNormal);edit:SetWidth(450)
        scroll:SetScrollChild(edit);edit:SetScript("OnEscapePressed",function() f:Hide() end)
        local close=W.Button(f,"Close",110,function() f:Hide() end);close:SetPoint("BOTTOMRIGHT",-16,12)
        f.edit=edit;W.DiagnosticsFrame=f
    end
    local f=W.DiagnosticsFrame;f.edit:SetText(type(content)=="string" and content or W.Diagnostics());f:Show();f.edit:SetFocus();f.edit:HighlightText()
end

