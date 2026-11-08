Wayfinder = Wayfinder or {}
local W = Wayfinder

local NAV = { bg={0.035,0.065,0.09,0.94}, edge={0.2,0.4,0.49,0.95}, cyan={0.38,0.84,0.91}, gold={0.98,0.73,0.3}, text={0.93,0.95,0.96}, muted={0.65,0.74,0.78} }
local frame, arrow, targetText, distanceText
local elapsed, lastAngle = 0, nil

local function safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
end

local function text(parent, size, color)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size, "")
    fs:SetTextColor(unpack(color))
    return fs
end

local function positionFrame()
    local p = W.GetProfile()
    frame:ClearAllPoints()
    local saved = p.navigatorPoint
    if saved and saved.point and saved.relativePoint then
        frame:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x or 0, saved.y or 0)
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -185)
    end
end

function W.CreateNavigator()
    if frame then return frame end
    frame = CreateFrame("Frame", "WayfinderNavigatorFrame", UIParent, "BackdropTemplate")
    frame:SetSize(118, 126)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        W.GetProfile().navigatorPoint = { point=point, relativePoint=relativePoint, x=x, y=y }
    end)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1,
        insets={left=1,right=1,top=1,bottom=1}})
    frame:SetBackdropColor(unpack(NAV.bg)); frame:SetBackdropBorderColor(unpack(NAV.edge))

    local header = text(frame, 8, NAV.cyan)
    header:SetPoint("TOPLEFT", 9,-7); header:SetText("WAYFINDER  ·  DRAG")
    local close = CreateFrame("Button", nil, frame)
    close:SetSize(18,18); close:SetPoint("TOPRIGHT", -3,-3)
    local closeText = text(close, 12, NAV.muted); closeText:SetPoint("CENTER",0,1); closeText:SetText("×")
    close:SetScript("OnClick", function()
        W.GetProfile().navigatorHidden = true
        frame:Hide()
        if W.RefreshUI then W.RefreshUI() end
    end)

    arrow = frame:CreateTexture(nil, "ARTWORK")
    arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
    arrow:SetSize(42,42)
    arrow:SetPoint("TOP", 0,-25)
    arrow:SetVertexColor(unpack(NAV.gold))
    targetText = text(frame, 9, NAV.text)
    targetText:SetPoint("TOPLEFT", 6,-72); targetText:SetPoint("TOPRIGHT", -6,-72)
    targetText:SetJustifyH("CENTER"); targetText:SetWordWrap(false)
    distanceText = text(frame, 9, NAV.muted)
    distanceText:SetPoint("BOTTOMLEFT", 5,7); distanceText:SetPoint("BOTTOMRIGHT", -5,7)
    distanceText:SetJustifyH("CENTER")

    positionFrame()
    if W.GetProfile().navigatorHidden then frame:Hide() end
    frame:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed >= 0.12 then elapsed = 0; W.UpdateNavigator() end
    end)
    W.NavigatorFrame = frame
    return frame
end

local function mapWorldPoint(mapID, x, y)
    if not mapID or not x or not y or not C_Map or not C_Map.GetWorldPosFromMapPos or not CreateVector2D then return nil end
    if x > 1 or y > 1 then x,y=x/100,y/100 end
    local continent, point = safe(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x,y))
    if not continent or not point then return nil end
    local wx, wy
    if point.GetXY then wx,wy=point:GetXY() else wx,wy=point.x,point.y end
    if not wx or not wy then return nil end
    return { continent=continent, wx=wx, wy=wy, mapID=mapID, x=x, y=y }
end

local function getPlayerPoint()
    local mapID = W.State and W.State.mapID
    if not mapID and C_Map and C_Map.GetBestMapForUnit then mapID=safe(C_Map.GetBestMapForUnit,"player") end
    if not mapID or not C_Map or not C_Map.GetPlayerMapPosition then return nil end
    local pos = safe(C_Map.GetPlayerMapPosition,mapID,"player")
    if not pos then return nil end
    local x,y=pos:GetXY()
    return mapWorldPoint(mapID,x,y)
end

local function getBearing(target, player)
    if not target or not player or target.continent ~= player.continent then return nil end
    local dx, dy = target.wx-player.wx, target.wy-player.wy
    local east, north
    if target.mapID == player.mapID then
        east, north = target.x-player.x, player.y-target.y
    else
        -- WoW world-map coordinates use the same east/north orientation after
        -- map-to-world conversion: world Y increases north.
        east, north = dx, dy
    end
    if math.abs(east)+math.abs(north) < 0.000001 then return 0 end
    return math.atan2(east,north)
end

function W.GetNavigationDistance()
    if C_Navigation and C_Navigation.GetDistance then
        local d = safe(C_Navigation.GetDistance)
        if type(d)=="number" and d>=0 then return d end
    end
end

function W.GetPickupAction(route)
    if not route or route.kind ~= "pickup" then return route and route.title end
    local d = W.GetNavigationDistance()
    if d and d <= 22 then return route.actionTitle or ("Accept: " .. (route.questName or "quest")) end
    return route.title
end

function W.UpdateNavigator()
    if not frame or not frame:IsShown() then return end
    local route = W.CurrentRoute
    if not route or not route.mapID or not route.x or not route.y then
        targetText:SetText("Waiting for route")
        distanceText:SetText("")
        arrow:Hide()
        return
    end
    local action = W.GetPickupAction(route)
    targetText:SetText(action or "Current objective")
    local d = W.GetNavigationDistance()
    distanceText:SetText(d and string.format("%.0f yd",d) or (route.zone or "On route"))

    local target, player = mapWorldPoint(route.mapID,route.x,route.y), getPlayerPoint()
    local bearing, facing = getBearing(target,player), safe(GetPlayerFacing)
    if bearing and facing then
        local relative = bearing + facing
        arrow:SetRotation(-relative)
        arrow:Show()
        lastAngle = relative
    elseif lastAngle then
        arrow:SetRotation(-lastAngle)
        arrow:Show()
    else
        arrow:Hide()
    end
end

function W.ToggleNavigator()
    if not frame then W.CreateNavigator() end
    local p = W.GetProfile()
    if frame:IsShown() then
        p.navigatorHidden = true
        frame:Hide()
    else
        p.navigatorHidden = false
        frame:Show()
        W.UpdateNavigator()
    end
    if W.RefreshUI then W.RefreshUI() end
end
