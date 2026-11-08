Wayfinder = Wayfinder or {}
local W = Wayfinder

local C = {
    bg = {0.025, 0.055, 0.085, 0.98},
    panel = {0.045, 0.085, 0.12, 1},
    raised = {0.065, 0.11, 0.15, 1},
    border = {0.16, 0.29, 0.37, 1},
    cyan = {0.38, 0.84, 0.91},
    gold = {0.96, 0.72, 0.31},
    text = {0.91, 0.93, 0.94},
    muted = {0.63, 0.71, 0.75},
    green = {0.46, 0.82, 0.61},
}
local frame, body, titleText, subtitleText, routeTitle, routeZone, routeReason, detailText, distanceText, arrowText, stops, rerouteButton, arrowButton
local routeKey

local function font(parent, size, color, template)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size, "")
    fs:SetTextColor(unpack(color))
    return fs
end

local function backdrop(f, color, edge)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1,
        insets={left=1,right=1,top=1,bottom=1}})
    f:SetBackdropColor(unpack(color))
    f:SetBackdropBorderColor(unpack(edge or C.border))
end

local function button(parent, label, width, callback)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, 28)
    backdrop(b, C.raised, C.border)
    local t = font(b, 11, C.text)
    t:SetPoint("CENTER")
    t:SetText(label)
    b.label = t
    b:SetScript("OnEnter", function(self) self:SetBackdropColor(0.09,0.16,0.21,1); self.label:SetTextColor(unpack(C.cyan)) end)
    b:SetScript("OnLeave", function(self) self:SetBackdropColor(unpack(C.raised)); self.label:SetTextColor(unpack(C.text)) end)
    b:SetScript("OnClick", callback)
    return b
end

local function makeStop(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(30)
    local dot = row:CreateTexture(nil, "ARTWORK")
    dot:SetSize(6,6); dot:SetColorTexture(unpack(index == 1 and C.gold or C.cyan)); dot:SetPoint("TOPLEFT", 2, -7)
    local title = font(row, 11, C.text)
    title:SetPoint("TOPLEFT", 16, -2); title:SetPoint("RIGHT", -2, 0); title:SetJustifyH("LEFT"); title:SetWordWrap(false)
    local sub = font(row, 9, C.muted)
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3); sub:SetPoint("RIGHT", -2, 0); sub:SetJustifyH("LEFT"); sub:SetWordWrap(false)
    row.dot, row.title, row.sub = dot, title, sub
    return row
end

function W.CreateUI()
    if frame then return frame end
    frame = CreateFrame("Frame", "WayfinderMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(370, 488)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    backdrop(frame, C.bg, C.border)
    frame:SetScript("OnUpdate", function(_, elapsed)
        frame._elapsed = (frame._elapsed or 0) + elapsed
        if frame._elapsed > 0.5 then frame._elapsed = 0; W.UpdateDistance() end
    end)

    local head = CreateFrame("Frame", nil, frame)
    head:SetPoint("TOPLEFT", 1, -1); head:SetPoint("TOPRIGHT", -1, -1); head:SetHeight(52)
    local line = head:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1); line:SetPoint("BOTTOMLEFT", 0, 0); line:SetPoint("BOTTOMRIGHT", 0, 0); line:SetColorTexture(unpack(C.border))
    titleText = font(head, 15, C.text, "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 16, -10); titleText:SetText("WAYFINDER")
    subtitleText = font(head, 9, C.muted)
    subtitleText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -3); subtitleText:SetPoint("RIGHT", -42, 0); subtitleText:SetJustifyH("LEFT")
    local close = CreateFrame("Button", nil, head, "BackdropTemplate")
    close:SetSize(24,24); close:SetPoint("TOPRIGHT", -9,-8); backdrop(close, C.raised, C.border)
    local x = font(close, 14, C.text); x:SetPoint("CENTER",0,1); x:SetText("×")
    close:SetScript("OnClick", function() frame:Hide() end)

    body = CreateFrame("Frame", nil, frame)
    body:SetPoint("TOPLEFT", 16, -67); body:SetPoint("BOTTOMRIGHT", -16, 15)
    local eyebrow = font(body, 10, C.cyan)
    eyebrow:SetPoint("TOPLEFT"); eyebrow:SetText("YOUR NEXT ROUTE")

    local card = CreateFrame("Frame", nil, body, "BackdropTemplate")
    card:SetPoint("TOPLEFT", 0, -19); card:SetPoint("TOPRIGHT", 0, -19); card:SetHeight(192)
    backdrop(card, C.panel, C.border)
    routeZone = font(card, 10, C.gold)
    routeZone:SetPoint("TOPLEFT", 13,-13); routeZone:SetPoint("RIGHT", -13, 0); routeZone:SetJustifyH("LEFT")
    routeTitle = font(card, 18, C.text, "GameFontNormalLarge")
    routeTitle:SetPoint("TOPLEFT", routeZone, "BOTTOMLEFT", 0,-7); routeTitle:SetPoint("RIGHT", -13,0); routeTitle:SetJustifyH("LEFT"); routeTitle:SetWordWrap(true)
    routeReason = font(card, 11, C.text)
    routeReason:SetPoint("TOPLEFT", routeTitle, "BOTTOMLEFT", 0,-10); routeReason:SetPoint("RIGHT", -13,0); routeReason:SetJustifyH("LEFT"); routeReason:SetWordWrap(true)
    detailText = font(card, 9, C.muted)
    detailText:SetPoint("BOTTOMLEFT", 13,12); detailText:SetPoint("RIGHT", -13,0); detailText:SetJustifyH("LEFT"); detailText:SetWordWrap(false)

    local distanceBox = CreateFrame("Frame", nil, body, "BackdropTemplate")
    distanceBox:SetPoint("TOPLEFT", card, "BOTTOMLEFT", 0,-10); distanceBox:SetPoint("TOPRIGHT", card, "BOTTOMRIGHT", 0,-10); distanceBox:SetHeight(38)
    backdrop(distanceBox, C.raised, C.border)
    arrowText = font(distanceBox, 10, C.cyan)
    arrowText:SetPoint("LEFT", 11,0); arrowText:SetWidth(178); arrowText:SetJustifyH("LEFT")
    distanceText = font(distanceBox, 10, C.text)
    distanceText:SetPoint("RIGHT", -11,0); distanceText:SetWidth(115); distanceText:SetJustifyH("RIGHT")

    local stopHead = font(body, 10, C.cyan)
    stopHead:SetPoint("TOPLEFT", distanceBox, "BOTTOMLEFT", 0,-17); stopHead:SetText("QUESTING STEPS")
    stops = { makeStop(body,1), makeStop(body,2) }
    for i,row in ipairs(stops) do
        row:SetPoint("TOPLEFT", stopHead, "BOTTOMLEFT", 0, -7 - (i-1)*32)
        row:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, 0)
    end

    local status = font(body, 9, C.muted)
    status:SetPoint("BOTTOMLEFT", 0, 39); status:SetPoint("RIGHT", 0,0); status:SetJustifyH("LEFT")
    frame.statusText = status
    rerouteButton = button(body, "Refresh route", 160, function()
        W.ScanCharacter(); W.RefreshUI(true)
    end)
    rerouteButton:SetPoint("BOTTOMLEFT", 0,0)
    arrowButton = button(body, "Navigator · On", 160, function()
        if W.ToggleNavigator then W.ToggleNavigator() end
        W.RefreshUI()
    end)
    arrowButton:SetPoint("BOTTOMRIGHT", 0,0)
    return frame
end

local function routeSignature(route)
    if not route then return "none" end
    return table.concat({tostring(route.mapID), tostring(route.x), tostring(route.y), tostring(route.questID), tostring(route.title)}, ":")
end

function W.SetRouteWaypoint(route, force)
    local profile = W.GetProfile()
    if profile.autoArrow == nil then profile.autoArrow = true end
    if not profile.autoArrow or not route or not route.mapID or not route.x or not route.y then
        if arrowText then arrowText:SetText(profile.autoArrow and "No mapped waypoint" or "Auto arrow paused") end
        return false
    end
    local key = routeSignature(route)
    if not force and key == routeKey then return true end
    if not C_Map or not C_Map.SetUserWaypoint or not UiMapPoint or not UiMapPoint.CreateFromCoordinates then
        arrowText:SetText("Navigation arrow unavailable")
        return false
    end
    local x, y = route.x, route.y
    if not route.normalized and (x > 1 or y > 1) then x, y = x/100, y/100 end
    local point = UiMapPoint.CreateFromCoordinates(route.mapID, x, y)
    local ok = pcall(C_Map.SetUserWaypoint, point)
    if not ok then
        arrowText:SetText("WoW rejected this waypoint")
        return false
    end
    if not C_SuperTrack or not C_SuperTrack.SetSuperTrackedUserWaypoint then
        arrowText:SetText("Waypoint set · tracking API unavailable")
        return false
    end
    local trackedCall = pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    local isTracked = C_SuperTrack.IsSuperTrackingUserWaypoint and C_SuperTrack.IsSuperTrackingUserWaypoint()
    if not trackedCall or isTracked == false then
        arrowText:SetText("Waypoint set · unable to track")
        return false
    end
    routeKey = key
    arrowText:SetText("Native arrow guiding to waypoint")
    return true
end

function W.UpdateDistance()
    if not distanceText or not W.CurrentRoute then return end
    local route = W.CurrentRoute
    local d = W.GetNavigationDistance and W.GetNavigationDistance()
    if d then
        distanceText:SetText(string.format("%.0f yd away", d))
    else
        distanceText:SetText("Waypoint set")
    end
    local action = W.GetPickupAction and W.GetPickupAction(route)
    routeTitle:SetText(action or route.title or "Next route")
    if route.kind == "pickup" and d and d <= 22 then
        routeReason:SetText("You’re at the quest giver. Accept this quest and I’ll select your next step.")
        detailText:SetText("Ready to accept · route advances from your quest log")
    elseif route.kind == "pickup" then
        routeReason:SetText("Follow the arrow to this quest giver. Accept the quest there; I’ll then route you to the next nearby pickup.")
    end
    if W.UpdateNavigator then W.UpdateNavigator() end
end

function W.RefreshUI(force)
    if not frame then W.CreateUI() end
    local state = W.State or W.ScanCharacter()
    local route = W.PlanRoute and W.PlanRoute(state) or W.GetRecommendation(state)
    W.CurrentRoute = route
    titleText:SetText("WAYFINDER")
    subtitleText:SetText(string.format("%s  ·  Level %d  ·  %s", state.name or "Adventurer", state.level or 1, state.zone or "Unknown"))
    routeZone:SetText(route and (route.zone or state.zone) or state.zone or "Nearby")
    routeTitle:SetText(route and route.title or "No route available")
    routeReason:SetText(route and (route.reason or "Follow this waypoint to continue your route.") or "Check back after Questie and QuestieDB load their quest data.")
    local smallDetail = "Recommended next hub · gather nearby quests together"
    if route and route.npcName then smallDetail = "Quest giver: " .. route.npcName
    elseif route and route.kind == "active" then smallDetail = "Current quest target · follow the objective"
    elseif route and route.detail then smallDetail = route.detail end
    detailText:SetText(smallDetail)

    local routeStops = route and route.routeStops or {}
    for i,row in ipairs(stops) do
        local stop = routeStops[i]
        if stop then
            row:Show()
            row.title:SetText(stop.title or stop.name or "Quest hub")
            row.sub:SetText(stop.npcName or stop.zone or "Nearby quest stop")
        else
            row:Hide()
        end
    end
    local profile = W.GetProfile()
    if profile.autoArrow == nil then profile.autoArrow = true end
    arrowButton.label:SetText(profile.navigatorHidden and "Navigator · Off" or "Navigator · On")
    frame.statusText:SetText(string.format("Progress-aware  ·  %d active  ·  %d completed  ·  /wf arrow", #state.activeQuests, state.completedCount or 0))
    if route then W.SetRouteWaypoint(route, force) end
    W.UpdateDistance()
end

function W.ToggleUI()
    if not frame then W.CreateUI() end
    if frame:IsShown() then frame:Hide() else frame:Show(); W.RefreshUI() end
end
