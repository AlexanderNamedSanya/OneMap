local count = 0
local function equal(a, b, label)
    count = count + 1
    assert(a == b, (label or "scroll assertion") .. ": " .. tostring(a) .. " ~= " .. tostring(b))
end
local time, mapId, target = 0, 10, 20
local cityTarget, cityType = nil, 8
MAPTYPE_SUBZONE = 8
local position, animating, canZoom = 0.5, false, true
local enabledMap, over, modifier, allowed = true, true, false, true
local nativeWheels, navigations, lastButton = 0, 0, nil
local updates, callbacks = {}, {}
MOUSE_BUTTON_INDEX_LEFT, MOUSE_BUTTON_INDEX_RIGHT = 1, 2
ZO_WorldMapScroll = {}
ZO_WorldMapContainer = { alpha = 1, SetAlpha = function(self, alpha) self.alpha = alpha end }
EVENT_MANAGER = {
    RegisterForUpdate = function(_, name, _, callback) updates[name] = callback end,
    UnregisterForUpdate = function(_, name) updates[name] = nil end,
}
CALLBACK_MANAGER = { RegisterCallback = function(_, name, callback) callbacks[name] = callback end }
local sceneCallback
SCENE_MANAGER = { GetScene = function() return { RegisterCallback = function(_, _, callback) sceneCallback = callback end } end }
WORLD_MAP_MANAGER = { IsMapChangingAllowed = function() return allowed end,
    SetMapById = function(_, id) navigations = navigations + 1; mapId = id; callbacks.OnWorldMapChanged() end }
local zoom = {
    GetZoomMinMax = function() return 1, canZoom and 4 or 1 end,
    CanMapZoom = function() return canZoom end,
    GetCurrentNormalizedZoom = function() return position end,
    HasTargetZoom = function() return animating end,
}
function ZO_WorldMap_GetPanAndZoom() return zoom end
function GetFrameTimeMilliseconds() return time end
function GetCurrentMapId() return mapId end
function MouseIsOver() return over end
function IsControlKeyDown() return modifier end
function IsAltKeyDown() return false end
function IsShiftKeyDown() return false end
function NormalizeMousePositionToControl() return 0.4, 0.5 end
function WouldProcessMapClick() return target ~= nil, target end
function GetMapIdByIndex(index) return index end
function GetMapMouseoverInfo() return cityTarget and "City" or "", "", 0, 0, 0, 0, cityTarget end
function GetMapInfoById() return "City", cityType end
function ZO_WorldMap_MouseWheel() nativeWheels = nativeWheels + 1 end
function ZO_WorldMap_MouseUp(_, button)
    navigations, lastButton = navigations + 1, button
    mapId = button == MOUSE_BUTTON_INDEX_LEFT and target or mapId - 1
    callbacks.OnWorldMapChanged()
end
OneMap = { saved = { smoothScroll = true },
    CanUseMap = function() return enabledMap end, IsKeyboardMap = function() return enabledMap end }
dofile(SOURCE_ROOT .. "/esoui/libraries/utility/zo_hook.lua")
dofile(ADDON_ROOT .. "/Scroll.lua")
local A = OneMap
A:InitializeScroll()
ZO_WorldMap_MouseWheel(1)
equal(nativeWheels, 1, "ordinary wheel uses native smooth zoom")
position = 1
ZO_WorldMap_MouseWheel(1)
equal(navigations, 0, "first boundary tick never changes map")
equal(updates.OneMapScrollFade, nil, "pause alone has no navigation timer")
time = 199; ZO_WorldMap_MouseWheel(1)
equal(A.scrollFade, nil, "early ticks stay on same map")
time = 200; ZO_WorldMap_MouseWheel(1)
equal(A.scrollFade ~= nil, true, "continued wheel after pause starts transition")
equal(navigations, 0, "fade precedes map change")
time = 260; updates.OneMapScrollFade()
equal(ZO_WorldMapContainer.alpha, 0.5, "fade out is interpolated")
ZO_WorldMap_MouseWheel(1); equal(navigations, 0, "wheel burst cannot queue more levels")
time = 320; updates.OneMapScrollFade()
equal(mapId, 20, "enter location under cursor")
equal(lastButton, nil, "enter uses the exact map ID without invoking pin clicks")
equal(A.scrollFade ~= nil, true, "own map-change event preserves fade in")
time = 400; updates.OneMapScrollFade()
equal(ZO_WorldMapContainer.alpha, 0.5, "fade in is interpolated")
time = 480; updates.OneMapScrollFade()
equal(ZO_WorldMapContainer.alpha, 1); equal(updates.OneMapScrollFade, nil)
position = 0; time = 700; ZO_WorldMap_MouseWheel(-1)
time = 1100; ZO_WorldMap_MouseWheel(-1)
time = 1220; updates.OneMapScrollFade()
equal(mapId, 19, "backward wheel leaves current level")
equal(lastButton, MOUSE_BUTTON_INDEX_RIGHT)
A:CancelSmoothScroll()
position = 1; time = 1300; ZO_WorldMap_MouseWheel(1)
time = 1600; target = 30; ZO_WorldMap_MouseWheel(1)
time = 1799; ZO_WorldMap_MouseWheel(1)
equal(A.scrollFade, nil, "moving to another location restarts pause")
time = 2000; ZO_WorldMap_MouseWheel(1)
equal(A.scrollFade ~= nil, true)
target = 31; time = 2120; updates.OneMapScrollFade()
equal(mapId, 19, "changed target during fade cancels entry")
equal(ZO_WorldMapContainer.alpha, 1)
time = 2200; ZO_WorldMap_MouseWheel(1)
time = 3200; ZO_WorldMap_MouseWheel(1)
equal(A.scrollFade, nil, "separate gestures cannot reuse old pause")
position = 0; time = 3300; ZO_WorldMap_MouseWheel(-1)
equal(A.scrollBoundary.direction, -1, "direction change resets boundary")
animating = true; ZO_WorldMap_MouseWheel(-1)
equal(A.scrollBoundary, nil, "unfinished native zoom cannot cross levels")
animating = false; target = nil; position = 1; ZO_WorldMap_MouseWheel(1)
equal(A.scrollBoundary, nil, "no child location under cursor")
target = 40; canZoom = false; position = 0.5; time = 3400; ZO_WorldMap_MouseWheel(-1)
equal(A.scrollBoundary ~= nil, true, "non-zoomable interior can still exit")
time = 3800; ZO_WorldMap_MouseWheel(-1)
A.saved.smoothScroll = false; time = 3920; updates.OneMapScrollFade()
equal(mapId, 19, "disabling prevents pending navigation")
equal(ZO_WorldMapContainer.alpha, 1)
local oldWheels = nativeWheels; ZO_WorldMap_MouseWheel(1)
equal(nativeWheels, oldWheels + 1, "disabled feature leaves native wheel")
A.saved.smoothScroll = true; canZoom = true; modifier = true; ZO_WorldMap_MouseWheel(1)
equal(A.scrollBoundary, nil, "modifier shortcuts remain native")
modifier = false; enabledMap = false; ZO_WorldMap_MouseWheel(1)
equal(A.scrollBoundary, nil, "restricted or gamepad scene remains native")
enabledMap = true; allowed = false; ZO_WorldMap_MouseWheel(1)
equal(A.scrollBoundary, nil, "map-changing restrictions respected")
allowed = true; position = 1; time = 4000; ZO_WorldMap_MouseWheel(1)
time = 4400; ZO_WorldMap_MouseWheel(1)
mapId = 99; callbacks.OnWorldMapChanged()
equal(A.scrollFade, nil, "external map navigation cancels pending transition")
equal(updates.OneMapScrollFade, nil)
allowed = true; mapId = 10; target = nil; cityTarget = 70; cityType = MAPTYPE_SUBZONE
position = 1; time = 5000; ZO_WorldMap_MouseWheel(1)
equal(A.scrollBoundary.target, 70, "city overlay without map index is recognized")
time = 5199; ZO_WorldMap_MouseWheel(1)
equal(A.scrollFade, nil, "city transition also waits 200ms")
time = 5200; ZO_WorldMap_MouseWheel(1)
time = 5320; updates.OneMapScrollFade()
equal(mapId, 70, "zone to city enters exact hovered subzone")
A:CancelSmoothScroll(); position = 0; time = 5400; ZO_WorldMap_MouseWheel(-1)
time = 5600; ZO_WorldMap_MouseWheel(-1)
time = 5720; updates.OneMapScrollFade()
equal(mapId, 69, "city back-navigation uses native parent transition")
A:CancelSmoothScroll(); position = 1; cityTarget = mapId
equal(A:GetScrollTarget(), nil, "current-map overlays cannot re-enter themselves")
cityTarget = 80; cityType = -1
equal(A:GetScrollTarget(), nil, "non-subzone overlays do not become city targets")
cityType = MAPTYPE_SUBZONE; time = 6000; ZO_WorldMap_MouseWheel(1)
time = 6200; ZO_WorldMap_MouseWheel(1)
cityTarget = 81; time = 6320; updates.OneMapScrollFade()
equal(mapId, 69, "changing city during fade cancels transition")
print("Smooth scroll: " .. count .. " assertions passed")
