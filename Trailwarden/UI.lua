local W=Trailwarden
local C={bg={0.025,0.043,0.065,0.985},card={0.047,0.078,0.105,1},raised={0.065,0.105,0.135,1},hover={0.10,0.17,0.21,1},line={0.15,0.25,0.31,1},text={0.94,0.96,0.97},muted={0.70,0.77,0.81},cyan={0.39,0.86,0.85},gold={0.98,0.79,0.47},green={0.53,0.88,0.68}}
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
    b.label=W.Font(b,11,C.text);b.label:SetPoint("CENTER");b.label:SetJustifyH("CENTER");b.label:SetText(label)
    b:SetScript("OnClick",onClick)
    b:SetScript("OnDisable",function(self) self.label:SetTextColor(unpack(C.muted)) end)
    b:SetScript("OnEnable",function(self) self.label:SetTextColor(unpack(C.text)) end)
    b:SetScript("OnEnter",function(self) self:SetBackdropColor(unpack(C.hover));self:SetBackdropBorderColor(unpack(C.cyan)) end)
    b:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(C.raised));self:SetBackdropBorderColor(unpack(C.line));if GameTooltip then GameTooltip:Hide() end end)
    return b
end
function W.Tooltip(owner,title,lines)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner,"ANCHOR_LEFT");GameTooltip:SetText(title,unpack(C.gold))
    local last=0;for i in pairs(lines) do if type(i)=="number" and i>last then last=i end end
    for i=1,last do local line=lines[i];if line and line~="" then GameTooltip:AddLine(line,0.85,0.9,0.92,true) end end
    GameTooltip:Show()
end
local frame,body,settings,settingsOpen,rows,settingRows
local fields={}
function W.OpenQuestLog(step)
    local id=step and step.questID
    if not W.IsFinite(id) or id<=0 then return false end
    local function indexForQuest()
        local index=C_QuestLog and W.Safe(C_QuestLog.GetLogIndexForQuestID,id) or W.Safe(GetQuestLogIndexByID,id)
        if index and index>0 then return index end
        if C_QuestLog and C_QuestLog.GetInfo then
            for i=1,(W.Safe(C_QuestLog.GetNumQuestLogEntries) or 0) do
                local info=W.Safe(C_QuestLog.GetInfo,i)
                if info and not info.isHeader and info.questID==id then return i end
            end
        end
    end
    local index=indexForQuest()
    if not index then print("|cff5dd4d6Trailwarden|r Accept this quest before opening it in your quest log.");return false end
    if not QuestLogFrame or type(ShowUIPanel)~="function" then return false end
    -- Expanding headers may change indices; resolve again after expansion/show.
    W.Safe(ExpandQuestHeader,0);W.Safe(ShowUIPanel,QuestLogFrame)
    index=indexForQuest();if not index then return false end
    if type(QuestLog_SetSelection)=="function" then W.Safe(QuestLog_SetSelection,index)
    elseif type(SelectQuestLogEntry)=="function" then W.Safe(SelectQuestLogEntry,index)
    elseif C_QuestLog then W.Safe(C_QuestLog.SetSelectedQuest,id) end
    W.Safe(QuestLog_Update);return true
end
local function atText(parent,text,size,color,x,y,width,height)
    local f=W.Font(parent,size,color);f:SetPoint("TOPLEFT",x,-y);f:SetSize(width,height);f:SetText(text);return f
end
-- Keep readable type sizes. Truncate captions on UTF-8 character boundaries;
-- instructions and safety messages instead grow to their measured height.
function W.FitCaption(font,text)
    text=text or "";font:SetText(text)
    if not font.GetStringHeight then return end
    local height=font:GetHeight()
    while font:GetStringHeight()>height and #text>0 do
        local shortened,n=text:gsub("[%z\1-\127\194-\244][\128-\191]*$","")
        text=n>0 and shortened or text:sub(1,-2)
        font:SetText(text.."...")
    end
end
local function place(font,x,y,width,height)
    font:ClearAllPoints();font:SetPoint("TOPLEFT",x,-y);font:SetSize(width,height)
end
local function textHeight(font,minimum)
    return math.max(minimum,math.ceil(font.GetStringHeight and font:GetStringHeight() or minimum))
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
    local count=math.min(p.queueRows,#(W.Queue or {}))
    local hasStatus=fields.statusText~=""
    local undo=p.lastSkipped~=nil or p.lastDeferred~=nil
    local titleH=textHeight(fields.title,20)
    place(fields.title,12,30,268,titleH)
    local y=30+titleH+6
    fields.target:SetShown(fields.target:GetText()~="")
    if fields.target:GetText()~="" then
        local h=textHeight(fields.target,16);place(fields.target,12,y,268,h);y=y+h+6
    end
    fields.progressTrack:SetShown(fields.hasProgress==true)
    if fields.hasProgress then
        fields.progressTrack:ClearAllPoints();fields.progressTrack:SetPoint("TOPLEFT",12,-y);y=y+3+9
    end
    local instructionH=textHeight(fields.instruction,15)
    place(fields.instruction,12,y,268,instructionH);y=y+instructionH+10
    fields.strip:ClearAllPoints();fields.strip:SetPoint("TOPLEFT",1,-y)
    fields.card:SetHeight(y+35)
    y=60+y+35+12
    body:SetShown(not settingsOpen and not compact);settings:SetShown(settingsOpen==true)
    fields.status:SetShown(not compact and hasStatus)
    if hasStatus then
        local h=textHeight(fields.status,14);place(fields.status,16,y,292,h);y=y+h+12
    end
    fields.thenLabel:SetShown(not compact and (p.queueRows>0 or undo))
    fields.thenLabel:ClearAllPoints();fields.thenLabel:SetPoint("TOPLEFT",16,-y)
    fields.undo:ClearAllPoints();fields.undo:SetPoint("TOPRIGHT",-16,-(y-3))
    fields.undo:SetShown(not compact and undo)
    local empty=not compact and p.queueRows>0 and count==0
    fields.empty:SetShown(empty)
    local emptyH=textHeight(fields.empty,28);place(fields.empty,16,y+22,292,emptyH)
    for i,r in ipairs(rows) do r:ClearAllPoints();r:SetPoint("TOPLEFT",16,-(y+22+(i-1)*44)) end
    local xpY=y+(p.queueRows>0 and (22+(count>0 and count*44-4 or emptyH)+12) or undo and 30 or 0)
    frame:SetHeight(settingsOpen and 626 or compact and 48 or xpY+84)
    fields.xpHover:ClearAllPoints();fields.xpHover:SetPoint("TOPLEFT",16,-xpY)
    for i,r in ipairs(rows) do r:SetShown(not compact and i<=count and r.step~=nil) end
    fields.fold.label:SetText(compact and "+" or "-")
    local s=W.State;local r=W.CurrentRoute or {};local n=W.Navigation or {}
    -- Reserve the measured distance width before shortening the quest caption.
    -- Navigation from an older decision must never survive in the header.
    local distance=compact and n.decisionID==(W.Decision and W.Decision.id or 0) and n.distance and W.FormatDistance(n.distance) or ""
    fields.summaryDistance:SetText(distance);fields.summaryDistance:SetShown(distance~="")
    local distanceWidth=distance~="" and math.ceil(fields.summaryDistance:GetStringWidth()) or 0
    place(fields.summaryDistance,305-distanceWidth,27,distanceWidth,14)
    fields.subtitle:SetWidth(290-(distanceWidth>0 and distanceWidth+10 or 0))
    if compact then
        W.FitCaption(fields.subtitle,r.questName or r.title or "Preparing your route")
    elseif s then W.FitCaption(fields.subtitle,"Level "..s.level.." · "..(s.zone or "Questing")) end
end
function W.CreateUI()
    if frame then return end
    local p=W.GetProfile()
    frame=CreateFrame("Frame","TrailwardenMainFrame",UIParent,"BackdropTemplate");W.MainFrame=frame
    frame:SetSize(324,456);frame:SetFrameStrata("HIGH");frame:SetToplevel(true);frame:SetClampedToScreen(true);frame:SetMovable(true);frame:EnableMouse(true);W.Backdrop(frame)
    body=CreateFrame("Frame",nil,frame);body:SetAllPoints(frame)
    local head=CreateFrame("Frame",nil,frame);head:SetPoint("TOPLEFT",1,-1);head:SetSize(322,46);head:EnableMouse(true);head:RegisterForDrag("LeftButton")
    head:SetScript("OnDragStart",function() if not W.GetProfile().locked then frame:StartMoving() end end)
    head:SetScript("OnDragStop",function() frame:StopMovingOrSizing();local a,_,b,x,y=frame:GetPoint(1);W.GetProfile().panelPoint={point=a,relativePoint=b,x=x,y=y} end)
    atText(head,"TRAILWARDEN",13,C.text,15,7,126,18)
    fields.subtitle=atText(head,"",11,C.muted,15,27,290,14);fields.subtitle:SetWordWrap(true)
    fields.summaryDistance=atText(head,"",11,C.gold,305,27,0,14);fields.summaryDistance:SetJustifyH("RIGHT");fields.summaryDistance:SetWordWrap(false)
    fields.mode=atText(head,"",10,C.cyan,140,10,75,13);fields.mode:SetJustifyH("RIGHT")
    local line=head:CreateTexture(nil,"ARTWORK");line:SetColorTexture(unpack(C.line));line:SetPoint("BOTTOMLEFT");line:SetSize(322,1)
    local close=W.Button(head,"X",24,function() W.GetProfile().panelHidden=true;frame:Hide() end);close:SetPoint("TOPRIGHT",-8,-8);close:SetHeight(22)
    fields.fold=W.Button(head,"-",24,function() W.GetProfile().collapsed=not W.GetProfile().collapsed;layout() end);fields.fold:SetPoint("TOPRIGHT",-40,-8);fields.fold:SetHeight(22)
    local config=W.Button(head,"",24,function() W.ToggleSettings() end);config:SetPoint("TOPRIGHT",-72,-8);config:SetHeight(22);config.label:Hide()
    config.icon=config:CreateTexture(nil,"ARTWORK");config.icon:SetTexture("Interface\\Buttons\\UI-OptionsButton");config.icon:SetVertexColor(unpack(C.cyan));config.icon:SetSize(14,14);config.icon:SetPoint("CENTER")
    config:SetScript("OnEnter",function(self) self:SetBackdropColor(unpack(C.hover));self:SetBackdropBorderColor(unpack(C.cyan));W.Tooltip(self,"Display settings",{"Adjust the guide size, preview rows, and other display preferences."}) end)
    fields.fold:SetScript("OnEnter",function(self) self:SetBackdropColor(unpack(C.hover));self:SetBackdropBorderColor(unpack(C.cyan));W.Tooltip(self,"Collapse or expand",{W.GetProfile().collapsed and "Show the current step and planned route." or "Keep only the compact current-step header visible."}) end)
    close:SetScript("OnEnter",function(self) self:SetBackdropColor(unpack(C.hover));self:SetBackdropBorderColor(unpack(C.gold));W.Tooltip(self,"Hide Trailwarden",{"Use /tw to show the guide again."}) end)
    local card=CreateFrame("Button",nil,body,"BackdropTemplate");fields.card=card;card:SetPoint("TOPLEFT",16,-60);card:SetSize(292,142);W.Backdrop(card,C.card);card:EnableMouse(true)
    card:SetScript("OnClick",function() W.OpenQuestLog(W.CurrentRoute) end)
    fields.action=atText(card,"",9,C.gold,12,10,202,14);fields.action:SetWordWrap(false)
    fields.title=atText(card,"",16,C.text,12,30,268,40);fields.title:SetJustifyV("TOP");fields.title:SetWordWrap(true)
    fields.target=atText(card,"",12,C.cyan,12,61,268,16);fields.target:SetWordWrap(true);fields.target:SetJustifyV("TOP")
    fields.progress=atText(card,"",10,C.text,220,10,60,14);fields.progress:SetJustifyH("RIGHT");fields.progress:SetWordWrap(false)
    fields.progressTrack=CreateFrame("Frame",nil,card,"BackdropTemplate");fields.progressTrack:SetSize(268,3);W.Backdrop(fields.progressTrack,C.line)
    fields.progressFill=fields.progressTrack:CreateTexture(nil,"ARTWORK");fields.progressFill:SetPoint("TOPLEFT");fields.progressFill:SetSize(1,3);fields.progressFill:SetColorTexture(unpack(C.cyan))
    fields.instruction=atText(card,"",12,C.text,12,96,268,30);fields.instruction:SetJustifyV("TOP");fields.instruction:SetWordWrap(true)
    card:SetScript("OnEnter",function(self)
        local r=W.CurrentRoute or {};local z=W.Zones[W.State and W.State.mapID]
        local point=r.point
        local location=point and W.IsFinite(point.x) and W.IsFinite(point.y) and string.format("%s · %.1f, %.1f",W.MapName(point.mapID),point.x*100,point.y*100) or ""
        local lines={r.instruction or ""}
        for _,line in ipairs(W.TargetExplanation and W.TargetExplanation() or {r.reason or ""}) do lines[#lines+1]=line end
        lines[#lines+1]=W.Navigation and W.Navigation.travel and W.Navigation.travel.instruction or ""
        lines[#lines+1]=location;lines[#lines+1]=z and z.hint or "";lines[#lines+1]=fields.statusText or ""
        lines[#lines+1]="Source: "..(r.source or "Live character state")
        lines[#lines+1]="Automatic combat targets: at most +2 enemy levels. Blocked objectives stay in your quest log."
        lines[#lines+1]=W.L("marker_help");lines[#lines+1]=W.L("marker_path_warning")
        lines[#lines+1]="Use /tw feedback for a reviewable summary without character names, quest names, or coordinates. Nothing is sent automatically."
        lines[#lines+1]="Click to open this quest in your quest log. Shift-click a planned step to focus it."
        W.Tooltip(self,r.title or "Why this target?",lines)
    end)
    card:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    local strip=CreateFrame("Frame",nil,card,"BackdropTemplate");fields.strip=strip;strip:SetSize(290,34);W.Backdrop(strip,C.raised)
    fields.distance=atText(strip,"",14,C.gold,11,8,80,18)
    fields.navStatus=atText(strip,"",11,C.muted,95,4,184,27);fields.navStatus:SetJustifyH("RIGHT");fields.navStatus:SetWordWrap(true)
    fields.thenLabel=atText(body,"PLANNED NEXT",10,C.muted,16,242,160,14)
    fields.undo=W.Button(body,"Undo skip",78,W.UndoSkip);fields.undo:SetPoint("TOPRIGHT",-16,-238);fields.undo:SetHeight(22)
    fields.empty=atText(body,"",11,C.muted,16,267,292,42);fields.empty:SetJustifyV("TOP");fields.empty:SetWordWrap(true)
    rows={}
    for i=1,4 do
        local row=CreateFrame("Button",nil,body,"BackdropTemplate");row:SetPoint("TOPLEFT",16,-(260+(i-1)*44));row:SetSize(292,40);W.Backdrop(row,C.card)
        atText(row,string.format("%02d",i+1),10,C.muted,8,13,21,14)
        row.title=atText(row,"",12,C.text,34,4,246,16);row.title:SetWordWrap(true)
        row.detail=atText(row,"",10,C.muted,34,23,246,13);row.detail:SetWordWrap(true)
        row:SetScript("OnClick",function(self) if W.Safe(IsShiftKeyDown) then W.PinStep(self.step) else W.OpenQuestLog(self.step) end end)
        row:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(C.cyan));if self.step then W.Tooltip(self,self.step.title,{self.step.instruction,self.step.reason,self.step.safetyHeld and "Automatic combat limits cannot be bypassed with manual focus." or self.step.levelDeferred and "Click to open quest log. Shift-click to resume this deferred quest." or "Click to open quest log. Shift-click to focus this step."}) end end)
        row:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(C.line));if GameTooltip then GameTooltip:Hide() end end)
        rows[i]=row
    end
    fields.status=atText(body,"",11,C.gold,16,258,292,28);fields.status:SetWordWrap(true);fields.status:SetJustifyV("TOP");fields.statusText=""
    local xpHover=CreateFrame("Frame",nil,body,"BackdropTemplate");fields.xpHover=xpHover;xpHover:SetPoint("BOTTOMLEFT",16,49);xpHover:SetSize(292,42);xpHover:EnableMouse(true)
    atText(xpHover,"YOUR XP / HOUR",10,C.muted,10,4,130,14)
    atText(xpHover,"NEXT LEVEL",10,C.muted,158,4,124,14)
    fields.xp=atText(xpHover,"Learning...",13,C.text,10,21,130,17)
    fields.xpETA=atText(xpHover,"--",12,C.text,158,21,124,17)
    local divider=xpHover:CreateTexture(nil,"ARTWORK");divider:SetColorTexture(unpack(C.line));divider:SetPoint("TOPLEFT",147,-7);divider:SetSize(1,30)
    xpHover:SetScript("OnEnter",function(self)
        local e=W.SafeExperienceStats();local r=W.CurrentRoute or {};local m=r.economy
        W.Tooltip(self,"Experience and route estimates",{
            "Measured XP/h includes kills, quests and exploration. Travel and ordinary downtime count; pause/AFK do not.",
            "Session: "..W.FormatXP(e.totalXP).." XP / "..W.FormatXP(e.sessionRate).." XP/h. Rolling window: "..math.floor(e.windowSeconds/60).." min.",
            "Rewarded kills: "..e.kills.." / turn-ins: "..e.turnins..". Next-level time appears after five active minutes and uses the measured rolling rate.",
            m and ("Quest cycle: ~"..W.FormatXP(m.xpPerHour).." XP/h · "..W.FormatDistance(m.travelDistance).." direct travel · "..W.FormatETA(m.seconds).." estimated. "..(m.confidence or "unknown").." confidence; "..(m.source or "Observed kills")..(m.confidence~="medium" and ". Low-confidence estimates do not influence route selection." or "")) or "Quest XP/time data is incomplete; normal quest routing remains available.",
            "Quest projections include remaining work, travel and reward collection. New unaccepted quest quantities may be uncertain.",
            "Grind comparison: "..W.FormatXP(e.grind and e.grind.rate).." XP/h from verified local kills.",
            "The current region and unfinished objective stay committed; XP changes do not send you back and forth between zones.",
            W.ForecastError and "Forecast temporarily unavailable. Normal quest guidance remains active." or "Grind comparison needs at least 8 verified kills over 2 minutes. /tw xpreset resets session statistics."})
    end)
    xpHover:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    fields.skip=W.Button(body,"Skip",92,function() local r=W.CurrentRoute;local state=W.State;if W.DeferLevel(r,state) then W.DeferCurrent() else W.SkipCurrent() end end);fields.skip:SetPoint("BOTTOMLEFT",16,11);fields.skip:SetHeight(26)
    fields.skip:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(C.cyan));local r=W.CurrentRoute;local state=W.State
        local high=W.DeferLevel(r,state)
        if r and r.kind=="grind" then W.Tooltip(self,"Return to questing",{"End this grind break and resume the quest route. Automatic grind suggestions pause for two minutes."});return end
        W.Tooltip(self,high and "Skip for now" or "Defer this quest",{high and ("Keep this quest for later. It returns automatically at level "..(r.level-state.profile.maxLevelAbove).." with your current level range.") or "Skip the whole current quest for 15 minutes on this character.","Use Undo skip or click a Later step to resume immediately."}) end)
    fields.refresh=W.Button(body,"Auto route",100,function() local profile=W.GetProfile();profile.pinned=nil;profile.paused=false;W.CurrentRoute=nil;W.Refresh(true,"resume-auto") end);fields.refresh:SetPoint("BOTTOMLEFT",113,11);fields.refresh:SetHeight(26)
    fields.arrow=W.Button(body,"Arrow on",90,function() W.ToggleNavigator() end);fields.arrow:SetPoint("BOTTOMRIGHT",-16,11);fields.arrow:SetHeight(26)
    settings=CreateFrame("Frame",nil,frame);settings:SetPoint("TOPLEFT",16,-75);settings:SetSize(292,545)
    atText(settings,"YOUR JOURNEY",12,C.cyan,0,0,292,16)
    atText(settings,"Saved for this character. Click a row to change.",11,C.muted,0,25,292,28)
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
        local b=W.Button(settings,"",292,function() local profile=W.GetProfile();d[3](profile);W.ApplyPositions();W.Refresh(false,"settings") end)
        b.label:ClearAllPoints();b.label:SetPoint("LEFT",10,0);b.label:SetJustifyH("LEFT");b.label:SetSize(138,16)
        b.value=W.Font(b,11,C.cyan);b.value:SetPoint("RIGHT",-10,0);b.value:SetJustifyH("RIGHT");b.value:SetSize(136,16)
        b:SetPoint("TOPLEFT",0,-(58+(i-1)*29));b:SetHeight(26);settingRows[i]={button=b,definition=d}
    end
    local undo=W.Button(settings,"Restore skipped quests",292,function() W.GetProfile().skipped={};W.GetProfile().lastSkipped=nil;W.GetProfile().deferredLevels={};W.GetProfile().lastDeferred=nil;W.Refresh(true) end);undo:SetPoint("TOPLEFT",0,-362)
    local reset=W.Button(settings,"Reset window positions",292,function() local profile=W.GetProfile();profile.panelPoint=nil;profile.navigatorPoint=nil;W.ApplyPositions() end);reset:SetPoint("TOPLEFT",0,-398)
    local replan=W.Button(settings,"Replan region now",292,function() local profile=W.GetProfile();profile.pinned=nil;profile.paused=false;W.Refresh(true,"manual-replan") end);replan:SetPoint("TOPLEFT",0,-438)
    local debug=W.Button(settings,"Copy diagnostics",292,function() W.ShowDiagnostics() end);debug:SetPoint("TOPLEFT",0,-474)
    local back=W.Button(settings,"Back to your route",292,function() settingsOpen=false;layout() end);back:SetPoint("TOPLEFT",0,-510)
    head:EnableMouseWheel(true)
    head:SetScript("OnMouseWheel",function(_,delta) if not W.GetProfile().locked then W.SetDisplayScale("uiScale",W.GetProfile().uiScale+delta*.05) end end)
    head:SetScript("OnEnter",function(self) local s=W.State;local r=W.CurrentRoute or {};W.Tooltip(self,"Trailwarden",{s and (s.name.." · "..s.raceName.." "..s.className) or "",r.questName or r.title,r.instruction,"Drag to move. Mouse wheel adjusts panel size.","Use - to collapse the plan; the gear opens display settings."}) end)
    head:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    W.ApplyPositions();layout();if p.panelHidden or W.IsCombatActive and W.IsCombatActive() then frame:Hide() end
end
function W.UpdateUI()
    if not frame then W.CreateUI() end
    local state=W.State;if not state then return end
    W.ActionLabels={escort=W.L("action_escort"),grind=W.L("action_grind"),pickup=W.L("action_pickup"),objective=W.L("action_objective"),turnin=W.L("action_turnin"),deliver=W.L("action_deliver"),item=W.L("action_item"),travel=W.L("action_travel"),wait=W.L("action_wait")}
    frame.renderDecisionID=W.Decision and W.Decision.id or 0
    local p=state.profile;local r=W.CurrentRoute or {}
    fields.mode:SetWordWrap(false);fields.mode:SetText(p.paused and "PAUSED" or p.pinned and "FOCUSED" or "AUTO")
    fields.mode:SetTextColor(unpack(p.paused and C.gold or C.cyan))
    fields.action:SetText((r.kind=="objective" and "OBJECTIVE" or W.ActionLabels[r.kind] or "ROUTE")..(r.level and r.level>0 and (" · LV "..r.level) or "")..(W.DeferLevel(r,state) and " · ABOVE RANGE" or ""))
    fields.title:SetHeight(40)
    W.FitCaption(fields.title,r.kind=="wait" and r.title or r.questName or r.title or "Preparing your route")
    local target=r.target or state.zone or "Your current area"
    if r.kind=="objective" and r.point and r.point.name and r.point.name~=target then target=target.." · "..r.point.name end
    fields.target:SetText(target..(r.combatRisk and r.combatRisk.maxLevel and (" · Lv "..r.combatRisk.maxLevel) or ""))
    fields.hasProgress=W.IsFinite(r.required) and r.required>0 and W.IsFinite(r.remaining)
    if fields.hasProgress then
        local done=math.max(0,math.min(r.required,r.required-r.remaining))
        fields.progress:SetText(string.format("%d / %d",done,r.required))
        fields.progressFill:SetWidth(math.max(1,268*done/r.required));fields.progressFill:SetShown(done>0)
    else fields.progress:SetText(r.kind=="turnin" and "Ready" or "") end
    fields.instruction:SetText(r.instruction or "Reading your quest progress...")
    for i,row in ipairs(rows) do
        local step=(W.Queue or {})[i];row.step=step
        if step then
            W.FitCaption(row.title,step.safetyHeld and step.title or step.levelDeferred and ("Later: "..(step.questName or step.title)) or step.questName or step.title)
            local detail=step.safetyHeld and (step.resumeLevel and ("Held · retry at level "..step.resumeLevel) or "Held · enemy levels unverified") or step.levelDeferred and ("Later · returns at level "..step.resumeLevel) or (W.ActionLabels[step.kind] or "QUEST").." · "..(step.target or (step.mapID and W.MapName(step.mapID)) or "Your bags")
            W.FitCaption(row.detail,detail)
            row.detail:SetTextColor(unpack((step.safetyHeld or step.levelDeferred) and C.gold or C.muted))
        end
    end
    local status=""
    if W.CatalogError then status="Quest data needs attention · /tw debug"
    elseif not W.CatalogReady then status=W.DatabaseStatus or "Loading quest data"
    elseif #(W.Unmapped or {})>0 then status=#W.Unmapped.." quest(s) need more data · /tw debug"
    elseif not state.historyReady then status="Waiting for completed quest history" end
    local safetyCount=0
    for _,q in ipairs(W.Unmapped or {}) do if q.safety then safetyCount=safetyCount+1 end end
    if safetyCount>0 then status=(status~="" and status.."\n" or "")..safetyCount.." combat objective(s) held · cap +2" end
    fields.statusText=status;fields.status:SetText(status)
    fields.status:SetTextColor(unpack((W.CatalogError or safetyCount>0 or #(W.Unmapped or {})>0) and C.gold or C.muted))
    local empty=not W.CatalogReady and "Reading quest data. Next steps will appear shortly."
        or #(W.Unmapped or {})>0 and "No further mapped steps. Check quest data or level settings."
        or "The only mapped step for now. Your plan updates with quest progress."
    fields.empty:SetText(empty)
    fields.refresh.label:SetText(p.paused and "Resume route" or "Auto route")
    fields.arrow.label:SetText(p.navigatorHidden and "Arrow off" or "Arrow on")
    fields.skip.label:SetText(r.kind=="grind" and "Questing now" or W.DeferLevel(r,state) and "Skip for now" or "Skip 15 min")
    fields.skip:SetEnabled(r.questID~=nil or r.kind=="grind")
    local laterCount=W.Count(p.deferredLevels)
    if laterCount>0 and fields.statusText=="" then fields.statusText=laterCount.." quest(s) saved for later";fields.status:SetText(fields.statusText) end
    local opportunities=W.Decision and W.Decision.detail and W.Decision.detail.opportunities or {}
    if #opportunities>0 then
        local first=opportunities[1]
        for _,o in ipairs(opportunities) do if o.activity=="escort" then first=o;break end end
        local nearby=#opportunities.." nearby · "..(first.activity=="escort" and "Escort: " or "Quest: ")..first.name
        fields.statusText=fields.statusText~="" and (fields.statusText.." · "..#opportunities.." nearby") or nearby
        fields.status:SetText(fields.statusText)
    end
    for _,v in ipairs(settingRows) do v.button.label:SetText(v.definition[1]..":");v.button.value:SetText(v.definition[2](p)) end
    layout();W.UpdateLiveUI()
end
function W.UpdateLiveUI()
    if not fields.distance or not W.CurrentRoute then return end
    local e=W.SafeExperienceStats();local stable=e.available and not e.paused and (e.windowSeconds or 0)>=300
    local measured=e.available and (e.maximum==0 and "Level cap" or e.paused and "Paused" or stable and e.rate and W.FormatXP(e.rate) or "Learning...") or "Unavailable"
    fields.xp:SetText(measured)
    local etaLabel="--"
    if e.available and not e.paused and e.maximum~=0 then etaLabel=stable and e.eta and ("~"..W.FormatETA(e.eta)) or not stable and "Building sample" or "--" end
    fields.xpETA:SetText(etaLabel)
    local n=W.Navigation or {}
    if W.Decision and n.decisionID~=W.Decision.id then
        fields.distance:SetText("");fields.navStatus:SetText("Synchronizing route")
        if W.GetProfile().collapsed and not settingsOpen then layout() end
        return
    end
    local travel=n.travel
    local r=W.CurrentRoute
    local instruction=travel and travel.instruction or r.instruction or "Reading your quest progress..."
    if fields.instruction:GetText()~=instruction then fields.instruction:SetText(instruction);layout() end
    fields.distance:SetText(n.distance and W.FormatDistance(n.distance) or (W.CurrentRoute.kind=="escort" and "Escort active" or W.CurrentRoute.kind=="item" and "In your bags" or ""))
    fields.distance:SetFont("Fonts\\FRIZQT__.TTF",n.distance and 14 or 11,"")
    fields.navStatus:SetText(n.label or "")
    if W.GetProfile().collapsed and not settingsOpen then layout() end
end
function W.ToggleSettings()
    if not frame then W.CreateUI() end
    W.GetProfile().panelHidden=false;frame:SetShown(not (W.IsCombatActive and W.IsCombatActive()));settingsOpen=not settingsOpen;W.UpdateUI()
end
function W.ToggleUI()
    if not frame then W.CreateUI() end
    local p=W.GetProfile();p.panelHidden=not p.panelHidden;frame:SetShown(not p.panelHidden and not (W.IsCombatActive and W.IsCombatActive()))
    if not p.panelHidden then W.Refresh(false,"display") end
end
function W.ShowDiagnostics(content)
    if not W.DiagnosticsFrame then
        local f=CreateFrame("Frame","TrailwardenDiagnosticsFrame",UIParent,"BackdropTemplate");f:SetSize(510,370);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:EnableMouse(true);W.Backdrop(f)
        atText(f,"TRAILWARDEN / DIAGNOSTICS",12,C.cyan,16,16,470,20)
        local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",16,-48);scroll:SetSize(452,265)
        local edit=CreateFrame("EditBox",nil,scroll);edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject(ChatFontNormal);edit:SetWidth(450)
        scroll:SetScrollChild(edit);edit:SetScript("OnEscapePressed",function() f:Hide() end)
        local close=W.Button(f,"Close",110,function() f:Hide() end);close:SetPoint("BOTTOMRIGHT",-16,12)
        f.edit=edit;W.DiagnosticsFrame=f
    end
    local f=W.DiagnosticsFrame;f.edit:SetText(type(content)=="string" and content or W.Diagnostics());f:Show();f.edit:SetFocus();f.edit:HighlightText()
end
