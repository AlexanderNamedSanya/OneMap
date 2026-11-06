local count = 0
local function equal(actual, expected, label)
    count = count + 1
    assert(actual == expected, label .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end
local time, x, y, shift, ctrl, alt, enabled = 0, 100, 100, true, false, false, true
local pings, pans, entries, parents = 0, 0, 0, 0
local downShift, upShift, fail, sceneCallback
MOUSE_BUTTON_INDEX_LEFT, MOUSE_BUTTON_INDEX_RIGHT = 1, 2
MAP_PIN_TYPE_RALLY_POINT, MAP_TYPE_LOCATION_CENTERED = 3, 4
ZO_WorldMapContainer = {
    GetHandler = function(self, name) return self[name] end,
    SetHandler = function(self, name, fn) self[name] = fn end,
}
function GetFrameTimeMilliseconds() return time end
function GetUIMousePosition() return x, y end
function NormalizeMousePositionToControl() return 0.4, 0.6 end
function IsShiftKeyDown() return shift end
function IsControlKeyDown() return ctrl end
function IsAltKeyDown() return alt end
function ZO_WorldMap_MouseWheel() end
function PingMap(kind, mode, nx, ny)
    equal(kind, MAP_PIN_TYPE_RALLY_POINT, "rally marker type")
    equal(mode, MAP_TYPE_LOCATION_CENTERED, "native coordinate mode")
    equal(nx, 0.4, "click X")
    equal(ny, 0.6, "click Y")
    pings = pings + 1
end
function ZO_WorldMap_MouseDown(button, _, _, pressedShift)
    downShift = pressedShift
    if pressedShift and button == 1 then PingMap(3, 4, 0.4, 0.6) end
    ZO_WorldMapContainer:SetHandler("OnUpdate", function() pans = pans + 1 end)
end
function ZO_WorldMap_MouseUp(_, button, inside)
    ZO_WorldMapContainer:SetHandler("OnUpdate", nil)
    upShift = IsShiftKeyDown()
    if fail then error("native handler failure") end
    if not inside or upShift or ctrl or alt then return end
    if button == 1 then entries = entries + 1 else parents = parents + 1 end
    return "native"
end
SCENE_MANAGER = { GetScene = function() return {
    RegisterCallback = function(_, _, callback) sceneCallback = callback end,
} end }
OneMap = { CanUseMap = function() return enabled end, IsKeyboardMap = function() return enabled end }
dofile(SOURCE_ROOT .. "/esoui/libraries/utility/zo_hook.lua")
dofile(ADDON_ROOT .. "/MapInput.lua")
OneMap:InitializeMapInput()
local reader = IsShiftKeyDown
local function press(button) ZO_WorldMap_MouseDown(button or 1, ctrl, alt, shift) end
local function release(button, inside) return ZO_WorldMap_MouseUp(ZO_WorldMapContainer, button or 1, inside ~= false) end
press(); equal(pings, 0, "no marker on press"); equal(downShift, false, "native drag starts without modifier")
time = 150; release()
equal(pings, 1, "short stationary click places one marker")
equal(entries, 0, "marker click does not open a child map")
equal(ZO_WorldMapContainer.OnUpdate, nil, "marker click cleans up native drag")
time = 300; press(); time = 501; release()
equal(pings, 1, "long click does not mark")
equal(entries, 1, "long click navigates normally")
equal(upShift, false, "native mouse-up ignores held Shift")
equal(IsShiftKeyDown, reader, "global key reader restored")
time = 600; press(); x = 120; ZO_WorldMapContainer.OnUpdate(); x = 100; time = 650; release()
equal(pings, 1, "drag returning to origin cannot mark")
equal(pans, 1, "native drag update remains active")
time = 700; press(); x = 110; time = 720; release()
equal(pings, 1, "movement at release prevents marker without an update tick")
x = 100; time = 800; press(); time = 820; release(1, false)
equal(pings, 1, "release outside cannot mark")
time = 900; press(); ZO_WorldMap_MouseWheel(1); time = 950; release()
equal(pings, 1, "wheel gesture while pressed cannot mark")
press(2); equal(release(2), "native", "Shift right click delegates")
equal(parents, 1, "Shift right click opens parent map")
equal(IsShiftKeyDown(), true, "physical Shift remains held")
shift = false; press(); release(); equal(downShift, false, "plain click unchanged")
shift = true; ctrl = true; press(2); release(2)
equal(downShift, true, "Ctrl combination unchanged"); equal(upShift, true, "Ctrl mouse-up unchanged")
ctrl = false; alt = true; press(2); release(2)
equal(downShift, true, "Alt combination unchanged"); equal(upShift, true, "Alt mouse-up unchanged")
alt = false; enabled = false; press(2); release(2)
equal(downShift, true, "restricted map unchanged"); equal(upShift, true, "restricted mouse-up unchanged")
enabled = true; fail = true
local ok = pcall(function() release(2) end)
equal(ok, false, "native error propagates"); equal(IsShiftKeyDown, reader, "key reader restored after error")
fail = false; press(); enabled = false; sceneCallback()
equal(OneMap.shiftMapClick, nil, "closing scene clears pending marker")
print("Map input: " .. count .. " assertions passed")
