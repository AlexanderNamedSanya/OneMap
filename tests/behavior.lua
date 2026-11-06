local assertions = 0
local function equal(actual, expected, message)
    assertions = assertions + 1
    assert(actual == expected, (message or "unexpected value") .. ": got " .. tostring(actual) .. ", expected " .. tostring(expected))
end
local function load(name) dofile(ADDON_ROOT .. "/" .. name .. ".lua") end
local events, updates, callbacks = {}, {}, {}
EVENT_MANAGER = {
    RegisterForEvent = function(_, namespace, event, fn) events[namespace .. tostring(event)] = fn end,
    UnregisterForEvent = function(_, namespace, event) events[namespace .. tostring(event)] = nil end,
    RegisterForUpdate = function(_, name, _, fn) updates[name] = fn end,
    UnregisterForUpdate = function(_, name) updates[name] = nil end,
}
CALLBACK_MANAGER = { RegisterCallback = function(_, name, fn) callbacks[name] = fn end }
local constantNames = { "MAP_MODE_DIG_SITES", "MAP_MODE_SMALL_CUSTOM", "MAP_MODE_LARGE_CUSTOM", "SET_MAP_RESULT_FAILED",
    "SET_MAP_RESULT_MAP_CHANGED", "POI_TYPE_WAYSHRINE", "POI_TYPE_HOUSE", "POI_TYPE_GROUP_DUNGEON",
    "ZONE_DISPLAY_TYPE_RAID", "ZONE_DISPLAY_TYPE_PUBLIC_DUNGEON", "ZONE_DISPLAY_TYPE_DUNGEON", "INSTANCE_TYPE_RAID",
    "MAP_FILTER_TRIALS", "MAP_FILTER_DUNGEONS", "MAP_FILTER_ARENAS", "QUEST_PIN_STATE_NONE", "QUEST_PIN_STATE_IS_SYMBOLIC_POSITION",
    "PLAYER_STATUS_OFFLINE", "CURRENCY_LOCATION_CHARACTER", "MOUSE_BUTTON_INDEX_LEFT", "MOUSE_BUTTON_INDEX_RIGHT",
    "TOPLEFT", "TOPRIGHT", "BOTTOMRIGHT", "CENTER", "CT_TEXTURE", "CT_BACKDROP", "CT_LABEL", "DT_HIGH",
    "TEXT_WRAP_MODE_ELLIPSIS", "SCENE_FRAGMENT_SHOWING", "SCENE_FRAGMENT_HIDDEN", "EVENT_ADD_ON_LOADED",
    "EVENT_GAMEPAD_PREFERRED_MODE_CHANGED", "SI_MAP_INFO_MODE_LOCATIONS", "LFG_ACTIVITY_DUNGEON",
    "LFG_ACTIVITY_MASTER_DUNGEON", "LFG_ACTIVITY_TRIAL", "ZO_CURRENCY_FORMAT_AMOUNT_ICON" }
for index, name in ipairs(constantNames) do _G[name] = index end
SOUNDS = { NEGATIVE_CLICK = "error" }
SI_LFG_ACTIVITY_NAME, SI_ZONE_NAME = "name", "zone"
local gamepad, showing, changing, combat, dead, leave, campaign = false, true, true, false, false, true, false
local map, floor, time, currentNode, cooldown, gold = 99, 2, 1000, nil, 0, 10000
local nodes, group, friends, guilds, positions = {}, {}, {}, {}, {}
local jump, dialog, alert, directNode, directHouse, outsideHouse
function GetCVar() return "en" end
function ZO_CreateStringId(name) _G[name] = name end
function ZO_Alert(_, _, text) alert = text end
function IsInGamepadPreferredMode() return gamepad end
function IsUnitInCombat() return combat end
function IsUnitDead() return dead end
function CanLeaveCurrentLocationViaTeleport() return leave end
function CanJumpToHouseFromCurrentLocation() return leave end
function IsInCampaign() return campaign end
function GetFrameTimeMilliseconds() return time end
SCENE_MANAGER = { IsShowing = function() return showing end }
WORLD_MAP_MANAGER = {
    IsMapChangingAllowed = function() return changing end,
    IsInMode = function(_, mode) return false end,
    GetModeMapSize = function() return 1 end,
    SetMapByIndex = function(_, index) map = index; if callbacks.OnWorldMapChanged then callbacks.OnWorldMapChanged() end end,
    ResizeAndReanchorMap = function() end,
    HandleRightMouseClicked = function() return "native" end,
}
function GetMapIndexByZoneId(zone) return zone > 0 and zone or nil end
function GetMapIdByZoneId(zone) return zone end
function GetCurrentMapId() return map end
function GetMapFloorInfo() return floor, 3 end
function SetMapFloor(value) floor = value end
function SetMapToMapId(value) map = value; floor = 1 end
function SetMapToMapListIndex(value) map = value; floor = 1; return SET_MAP_RESULT_MAP_CHANGED end
function GetCurrentMapZoneIndex() return map end
function GetZoneId(zone) return zone end
function GetZoneNameById(zone) return "Zone " .. zone end
function GetMapInfoByIndex(index) return "Zone " .. index, 1, 1, index end
function GetZoneIndexByMapId(index) return index end
function GetNumFastTravelNodes() return #nodes end
function GetFastTravelNodeInfo(index)
    local n = nodes[index]
    return n.known, n.name or ("Node " .. index), n.x or 0.5, n.y or 0.5, "icon", nil,
        n.kind or POI_TYPE_WAYSHRINE, n.zone == map, n.locked
end
function GetFastTravelNodePOIIndicies(index) return nodes[index].zone, index end
function GetFastTravelNodeHouseId(index) return nodes[index].house or 0 end
function GetPOIInstanceType(_, poi) return nodes[poi].instance end
function GetPOIMapFilterOverride(_, poi) return nodes[poi].filter end
function GetPOIInfo(_, poi) return nodes[poi].poiName or nodes[poi].name end
function GetFastTravelNodeZoneDisplayType(index) return nodes[index].display end
function GetFastTravelNodeOutboundOnlyInfo(index) return nodes[index].outbound or false end
function GetFastTravelNodeMapPriority(index) return nodes[index].priority end
function IsFastTravelNodeAutoDiscovered(index) return nodes[index].auto or false end
function ZO_Map_GetFastTravelNode() return currentNode end
function GetRecallCurrency() return 1 end
function GetRecallCost(index) return nodes[index].cost or 146 end
function GetRecallCooldown() return 0, cooldown end
function GetCurrencyAmount() return gold end
function GetDisplayName() return "@self" end
local socialAllowed = true
function CanJumpToPlayerInZone() return socialAllowed end
function GetGroupSize() return #group end
function GetGroupUnitTagByIndex(index) return index end
function GetUnitWorldPosition(tag) return group[tag].zone end
function AreUnitsEqual() return false end
function IsUnitOnline(tag) return group[tag].online end
function CanJumpToGroupMember(tag) return group[tag].canJump ~= false end
function GetUnitDisplayName(tag) return group[tag].name end
function GetNumFriends() return #friends end
function GetFriendInfo(index) local p = friends[index]; return p.name, "", p.status end
function GetFriendCharacterInfo(index) local p = friends[index]; return true, "", "", 0, 0, 0, 0, p.zone end
function GetNumGuilds() return #guilds end
function GetGuildId(index) return index end
function GetNumGuildMembers(id) return #guilds[id] end
function GetGuildMemberInfo(id, index) local p = guilds[id][index]; return p.name, "", 0, p.status end
function GetGuildMemberCharacterInfo(id, index) local p = guilds[id][index]; return true, "", "", 0, 0, 0, 0, p.zone end
function JumpToGroupMember(name) jump = "group:" .. name end
function JumpToFriend(name) jump = "friend:" .. name end
function JumpToGuildMember(name) jump = "guild:" .. name end
function FastTravelToNode(node) directNode = node end
function RequestJumpToHouse(house, outside) directHouse, outsideHouse = house, outside end
function SCENE_MANAGER:ShowBaseScene() end
function ZO_Dialogs_ShowPlatformDialog(name, data) dialog = { name = name, data = data } end
function ZO_Currency_FormatKeyboard(_, value) return value .. " gold" end
function zo_strformat(_, value) return value end
function GetNumActivitiesByType() return 0 end
local journalEntries = { [1] = true, [2] = true }
MAX_JOURNAL_QUESTS = 25
EVENT_QUEST_ADDED, EVENT_QUEST_REMOVED, EVENT_QUEST_LIST_UPDATED, EVENT_QUEST_ADVANCED = 101, 102, 103, 104
function IsValidQuestIndex(index) return journalEntries[index] == true end
function GetJournalQuestLevel() return 50 end
function GetJournalQuestType() return 1 end
function GetJournalQuestZoneDisplayType() return 1 end
function GetJournalQuestLocationInfo() return "Zone 10", "", 10, 1 end
function GetJournalQuestId() return 100 end
function GetJournalQuestName(index) return index == 2 and "Other zone quest" or "Quest" end
function GetQuestZoneId() return 10 end
WORLD_MAP_QUEST_BREADCRUMBS = {
    GetSteps = function() return positions end,
    DoesQuestHavePendingTasks = function() return false end,
    RegisterCallback = function(_, name, fn) callbacks[name] = fn end,
}
local digsites = {}
function GetNumInProgressAntiquities() return #digsites > 0 and 1 or 0 end
function GetInProgressAntiquityId() return 7 end
function GetNumDigSitesForInProgressAntiquity() return #digsites end
function GetInProgressAntiquityDigSiteId(_, index) return index end
function GetDigSiteNormalizedCenterPosition(index) local p = digsites[index]; return p.x, p.y, p.shown end

load("Core"); load("Strings"); load("Destinations"); load("Travel")
local A = OneMap
A.saved = {}
for key, value in pairs(A.defaults) do A.saved[key] = value end
local zone = A:ZoneDestination(10)
nodes = {
    { zone = 10, known = true, priority = 10, x = 0.1, y = 0.1 },
    { zone = 10, known = true, priority = 20, x = 0.8, y = 0.8 },
    { zone = 11, known = true, priority = 999, x = 0.9, y = 0.9 },
}
equal(A:SelectWayshrine(zone), 2, "native priority")
equal(map, 99, "map restored after lookup"); equal(floor, 2, "floor restored")
nodes[2].known = false; equal(A:SelectWayshrine(zone), 1, "undiscovered capital fallback")
nodes[1].known = false; equal(A:SelectWayshrine(zone), nil, "no discovered shrine")
equal(A:PlanTravel(zone).reason, "noShrine")
nodes[1].known, nodes[2].known = true, true
nodes[2].locked = true; equal(A:SelectWayshrine(zone), 1, "DLC-locked excluded")
nodes[2].locked = false; nodes[2].outbound = true; equal(A:SelectWayshrine(zone), 1, "outbound-only excluded")
nodes[2].outbound = false; nodes[1].priority = 20; nodes[2].auto = true
equal(A:SelectWayshrine(zone), 2, "native auto-discovered tiebreak")
local ok = pcall(function() A:OnZoneMap(10, function() error("probe") end) end)
equal(ok, false); equal(map, 99, "error restores map"); equal(floor, 2)
friends = { { name = "@self", zone = 10, status = 1 }, { name = "@offline", zone = 10, status = PLAYER_STATUS_OFFLINE }, { name = "@friend", zone = 10, status = 1 } }
equal(A:PlanTravel(zone).kind, "player"); A:Travel(zone); equal(jump, "friend:@friend")
equal(dialog, nil, "social travel never opens paid recall")
A.saved.useFriends = false; guilds = { { { name = "@guild", zone = 10, status = 1 } } }
A:Travel(zone); equal(jump, "guild:@guild")
group = { { name = "@group", zone = 10, online = true } }
socialAllowed = false; A:Travel(zone); equal(jump, "group:@group", "group uses CanJumpToGroupMember")
socialAllowed = true
equal(A:PriceText(zone), "Price: Free")
group, guilds, friends = {}, {}, {}; A.quote = nil
A:Travel(zone); equal(dialog.name, "RECALL_CONFIRM"); equal(dialog.data.nodeIndex, 2)
equal(A.saved.skipPaidConfirmation, false, "paid confirmation enabled by default")
A.saved.skipPaidConfirmation = true; dialog = nil
A:Travel(zone); equal(directNode, 2, "paid recall skips dialog when enabled"); equal(dialog, nil)
directNode = nil; gold = 0; equal(A:Travel(zone), false); equal(directNode, nil, "insufficient gold blocks immediate recall"); gold = 10000
cooldown = 100; equal(A:Travel(zone), false); equal(directNode, nil, "cooldown blocks immediate recall"); cooldown = 0
currentNode = 8; equal(A:PlanTravel(zone).cost, 0); A:Travel(zone); equal(dialog, nil); equal(directNode, 2, "free shrine travel also skips confirmation"); A.saved.skipPaidConfirmation = false
currentNode = 2; equal(A:PlanTravel(zone).reason, "unavailable"); currentNode = nil
cooldown = 2000; equal(A:PlanTravel(zone).reason, "cooldown"); cooldown = 0
gold = 0; equal(A:PlanTravel(zone).reason, "noGold"); gold = 10000
combat = true; equal(A:PlanTravel(zone).reason, "restricted"); combat = false
dead = true; equal(A:PlanTravel(zone).reason, "restricted"); dead = false
leave = false; equal(A:PlanTravel(zone).reason, "restricted"); leave = true
gamepad = true; equal(A:PlanTravel(zone).reason, "restricted"); gamepad = false
changing = false; equal(A:PlanTravel(zone).reason, "restricted"); changing = true
campaign = true; equal(A:PlanTravel(zone).reason, "restricted"); campaign = false
local house = { kind = "house", zoneId = 10, houseId = 42, name = "House" }
A:Travel(house); equal(dialog.name, "TRAVEL_TO_HOUSE_CONFIRM"); equal(dialog.data.houseId, 42)
equal(dialog.data.travelOutside, false, "inside house")
A.saved.skipPaidConfirmation = true; dialog = nil; A:Travel(house)
equal(directHouse, 42); equal(outsideHouse, false); equal(dialog, nil, "house confirmation skipped")
A.saved.skipPaidConfirmation = false
nodes[4] = { zone = 10, known = true, kind = POI_TYPE_GROUP_DUNGEON, display = ZONE_DISPLAY_TYPE_DUNGEON, name = "Dungeon: Dungeon", poiName = "Dungeon: Dungeon" }
nodes[5] = { zone = 10, known = true, kind = POI_TYPE_GROUP_DUNGEON, instance = INSTANCE_TYPE_RAID, name = "Trial" }
nodes[6] = { zone = 10, known = true, kind = POI_TYPE_GROUP_DUNGEON, filter = MAP_FILTER_ARENAS, name = "Arena" }
equal(#A:InstanceList("dungeon"), 1); equal(#A:InstanceList("trial"), 1)
equal(#A:InstanceList("instances"), 2, "combined list contains dungeons and trials, without arenas")
local dungeon = A:NodeDestination(4)
equal(dungeon.name, "Dungeon: Dungeon", "native POI labels may also include travel prefixes")
A.instanceZones = { Dungeon = 20 }
equal(A:GetInstanceZone(dungeon), 20, "prefixed POI label identifies the interior")
equal(A:GetInstanceZone({name = "Dungeon"}), 20, "exact activity label")
equal(A:GetInstanceZone({name = "ењ°дё‹еџЋпјљDungeon"}), 20, "localized fullwidth colon prefix")
equal(A:GetInstanceZone({name = "Other Dungeon"}), nil, "partial names are not guessed")
friends = { { name = "@friend", zone = 20, status = 1 } }; A.saved.useFriends = true
guilds = { { { name = "@guild", zone = 20, status = 1 } } }
equal(A:PlanTravel(dungeon).kind, "node", "friends and guilds do not choose instance copies")
A:Travel(dungeon); equal(dialog.data.nodeIndex, 4, "direct dungeon node, not outdoor shrine")
group = { { name = "@inside", zone = 20, online = true } }
equal(A:PlanTravel(dungeon).kind, "player"); A:Travel(dungeon); equal(jump, "group:@inside")
group[1].zone = 10; equal(A:PlanTravel(dungeon).kind, "node", "outdoor group member excluded")
group = {}; friends = {}; guilds = {}
local quest = A:QuestDestination(1)
A.questPointCache = { [1] = { mapId = 10, points = { { x = 0.12, y = 0.1 } } } }
map = 10
equal(A:SelectWayshrine(quest), 1, "nearest quest shrine overrides capital")
positions = { [1] = {
    { xLoc = 0.1, yLoc = 0.1, insideCurrentMapWorld = true, isBreadcrumb = true, symbolicState = QUEST_PIN_STATE_NONE },
    { xLoc = 0.2, yLoc = 0.2, insideCurrentMapWorld = true, symbolicState = QUEST_PIN_STATE_IS_SYMBOLIC_POSITION },
    { xLoc = 0.8, yLoc = 0.8, insideCurrentMapWorld = true, symbolicState = QUEST_PIN_STATE_NONE },
} }
equal(#A:QuestPoints(1), 1, "transport and symbolic pins excluded")
digsites = { { x = 0.11, y = 0.11, shown = true } }
local antiquity = A:ZoneDestination(10); antiquity.antiquityId = 7
equal(A:SelectWayshrine(antiquity), 1, "nearest dig-site shrine")
digsites = {}; equal(A:SelectWayshrine(antiquity), 2, "not located: native priority")
A.pendingQuest = { questIndex = 1 }; updates.OneMapQuestWait = function() end
A:Travel(zone); equal(A.pendingQuest, nil); equal(updates.OneMapQuestWait, nil, "new travel cancels pending quest")
print("Route behavior: " .. assertions .. " assertions passed")

-- Exercise installed handlers using the owning game's real hook helpers.
dofile(SOURCE_ROOT .. "/esoui/libraries/utility/zo_hook.lua")
local controls = {}
local Control = {}
Control.__index = Control
function Control:new(name, parent)
    local c = setmetatable({ name = name, parent = parent, children = {}, handlers = {}, hidden = false,
        scale = 1, width = 350, height = 690, dataTypes = {}, dataList = {} }, Control)
    if name then controls[name] = c end
    return c
end
function Control:GetNamedChild(name)
    if not self.children[name] then self.children[name] = Control:new((self.name or "") .. name, self) end
    return self.children[name]
end
function Control:GetParent() return self.parent end
function Control:GetHandler(name) return self.handlers[name] end
function Control:SetHandler(name, fn) self.handlers[name] = fn end
function Control:SetText(text) self.text = text end
function Control:GetTextDimensions() return 200, 40 end
function Control:SetScale(scale) self.scale = scale end
function Control:GetScale() return self.scale end
function Control:GetDimensions() return self.width, self.height end
function Control:SetWidth(value) self.width = value end
function Control:SetHeight(value) self.height = value end
function Control:GetWidth() return self.width end
function Control:GetHeight() return self.height end
function Control:SetDimensions(x, y) self.width, self.height = x, y end
function Control:SetHidden(hidden) self.hidden = hidden end
function Control:IsHidden() return self.hidden end
for _, method in ipairs({ "SetAnchor", "ClearAnchors", "SetAnchorFill", "SetTexture", "SetColor", "SetDrawTier", "SetDrawLevel",
    "SetMouseEnabled", "SetAlpha", "SetCenterTexture", "SetCenterColor", "SetEdgeColor", "SetEdgeTexture", "SetFont",
    "SetMaxLineCount", "SetWrapMode", "SetEnabled", "SetSelected" }) do Control[method] = function() end end
WINDOW_MANAGER = {
    CreateControl = function(_, name, parent) return Control:new(name, parent) end,
    CreateTopLevelWindow = function(_, name) return Control:new(name) end,
    CreateControlFromVirtual = function(_, name, parent) return Control:new(name, parent) end,
}
GuiRoot = Control:new("GuiRoot"); GuiRoot:SetDimensions(1920, 1080)
ZO_WorldMap, ZO_WorldMapContainer, ZO_WorldMapScroll = Control:new("WorldMap"), Control:new("Container"), Control:new("Scroll")
ZO_WorldMapInfo = Control:new("MapInfo")
ZO_WorldMapInfoMenuBar = Control:new("ModeBar")
local sceneCallback
SCENE_MANAGER.GetScene = function() return { RegisterCallback = function(_, _, fn) sceneCallback = fn end } end
local function fragment(control)
    return { control = control, reasons = {}, RegisterCallback = function(self, _, fn) self.callback = fn end,
        SetHiddenForReason = function(self, reason, hidden) self.reasons[reason] = hidden end }
end
ZO_FadeSceneFragment = { New = function(_, control) return fragment(control) end }
WORLD_MAP_ZONE_STORY_KEYBOARD_FRAGMENT = fragment()
MEDIUM_LEFT_PANEL_BG_FRAGMENT = {} -- Simple fragment: no SetHiddenForReason method.
local pinManager = { WouldPinHandleClick = function() return false end, HandlePinClicked = function() return "native" end,
    GetCurrentMouseOverPins = function() return {} end, GetPlayerPin = function() return nil end }
function ZO_WorldMap_GetPinManager() return pinManager end
ZO_MapPin = { GetMapPinForControl = function(control) return control.pin end }
function MouseIsOver() return false end
function GetUIMousePosition() return 100, 100 end
function GetControl(control, name) return control:GetNamedChild(name) end
function ZO_ScrollList_GetDataTypeTable(list, id) return list.dataTypes[id] end
function ZO_ScrollList_UpdateDataTypeHeight(list, id, height) list.dataTypes[id].height = height end
function ZO_ScrollList_RefreshVisible() end
function ZO_ScrollList_Clear(list) list.dataList = {} end
function ZO_ScrollList_GetDataList(list) return list.dataList end
function ZO_ScrollList_GetData(control) return control.data end
function ZO_ScrollList_CreateDataEntry(_, data) return data end
function ZO_ScrollList_AddDataType(list, id, _, height, setup) list.dataTypes[id] = { height = height, setupCallback = setup } end
function ZO_ScrollList_Commit() end
function ZO_WorldMap_PanToWayshrine() end
WORLD_MAP_LOCATIONS = { list = Control:new("Locations"), SetupLocation = function() end, RowLocation_OnMouseUp = function() return "native" end }
local houseRow = Control:new("HouseRow"); houseRow.data = { houseName = "Home", foundInZoneName = "Zone 10", nodeIndex = 1 }
WORLD_MAP_HOUSES = { list = Control:new("Houses") }
WORLD_MAP_HOUSES.list.dataTypes[2] = { height = 60, setupCallback = function(control, data)
    control:GetNamedChild("Name"):SetText(data.houseName)
    control:GetNamedChild("Location"):SetText(data.foundInZoneName)
end }
WORLD_MAP_HOUSES.RefreshHouseList = function(self) self.list.dataTypes[2].setupCallback(houseRow, houseRow.data) end
local nativeQuestCalls = 0
local nativeQuestData = { masterList = {}, CompareQuests = function(a, b) return a.name < b.name end }
WORLD_MAP_QUESTS = { data = nativeQuestData, LayoutList = function() end, QuestHeader_OnClicked = function() nativeQuestCalls = nativeQuestCalls + 1 end, QuestHeader_OnMouseEnter = function() end }
function ZO_WorldMapHouseRow_OnMouseUp() return "native" end
function ZO_WorldMapQuestHeader_OnMouseUp(header, button) WORLD_MAP_QUESTS:QuestHeader_OnClicked(header, button) end
function ZO_WorldMapQuestHeader_OnMouseExit() end
local menu = {}
function AddMenuItem(name, callback) menu[#menu + 1] = { name = name, callback = callback } end
function ShowMenu() end
WORLD_MAP_ANTIQUITIES_KEYBOARD = {
    AntiquityMapEntryClicked = function(_, _, button)
        if button == MOUSE_BUTTON_INDEX_RIGHT then menu = {}; AddMenuItem("Scry"); AddMenuItem("Track"); AddMenuItem("Abandon") end
    end,
    AntiquityMapEntryMouseEnter = function() end, AntiquityMapEntryMouseExit = function() end,
}
ZO_ZoneStories_Manager = { SetTrackedZoneStoryAssisted = function() end }
FOCUSED_QUEST_TRACKER = { ForceAssist = function() end }
local tabs, optionControls = {}, nil
WORLD_MAP_INFO = { modeBar = { Add = function(_, id, groups, data) tabs[id] = { fragment = groups[1], data = data } end,
    UpdateButtons = function() end }, SelectTab = function() end }
LibAddonMenu2 = { RegisterAddonPanel = function() end, RegisterOptionControls = function(_, _, data) optionControls = data end }
ZO_SavedVars = { NewAccountWide = function(_, _, _, _, defaults)
    local result = {}; for key, value in pairs(defaults) do result[key] = value end; result.freeTravel = false; result.showTrials = false; return result
end }
local normalizedZoom = 0
function ZO_WorldMap_GetPanAndZoom() return { GetCurrentNormalizedZoom = function() return normalizedZoom end, SetCurrentNormalizedZoom = function(_, value) normalizedZoom = value end } end
WORLD_MAP_MANAGER.ResizeAndReanchorMap = function() ZO_WorldMap:SetDimensions(600, 600) end
function ZO_WorldMap_MouseDown() end
function ZO_WorldMap_MouseUp() end
load("Map"); load("Scroll"); load("MapInput"); load("Panels"); load("Settings"); load("OneMap")
events["OneMap" .. tostring(EVENT_ADD_ON_LOADED)](nil, "OtherAddon")
equal(A.baseMapScale, nil, "ignore other addons loading")
events["OneMap" .. tostring(EVENT_ADD_ON_LOADED)](nil, "OneMap")
equal(ZO_WorldMap:GetScale(), 1, "native control scale preserves icon sizes")
A:ApplyMapSettings(); A:ApplyMapSettings(); equal(ZO_WorldMap:GetScale(), 1, "scale never compounds")
equal(WORLD_MAP_HOUSES.list.dataTypes[2].height, 28, "compact house row height")
equal(houseRow:GetNamedChild("Location"):IsHidden(), true)
equal(houseRow:GetNamedChild("Name").text, "Home  |c9a9a9aZone 10|r")
equal(tabs.SI_ONEMAP_DUNGEONS ~= nil, true); equal(tabs.SI_ONEMAP_TRIALS, nil, "no separate trial tab")
WORLD_MAP_MANAGER:ResizeAndReanchorMap()
equal(ZO_WorldMap:GetWidth(), 660, "viewport enlarged by ten percent")
ZO_WorldMap_GetPanAndZoom():SetCurrentNormalizedZoom(0.8)
equal(ZO_WorldMap:GetWidth(), 660, "zoom leaves viewport size unchanged")
WORLD_MAP_MANAGER:ResizeAndReanchorMap()
equal(ZO_WorldMap:GetWidth(), 660, "layout never compounds enlargement")
local settingsCount = 0
for _, control in ipairs(optionControls) do
    if control.type == "checkbox" then
        settingsCount = settingsCount + 1
        if control.name == A:Text("compactHouses") then
            control.setFunc(false); equal(houseRow:GetNamedChild("Location"):IsHidden(), false)
            equal(WORLD_MAP_HOUSES.list.dataTypes[2].height, 60)
        end
    end
end
equal(settingsCount, 5, "map, smooth-scroll and paid-confirmation settings")
A:RenderTravelTooltip({kind = "house", houseId = 42, zoneId = 10, name = "House"})
equal(A.travelTooltip:GetWidth(), 212, "tooltip width fits measured content")
equal(A.travelTooltip:GetHeight(), 52, "compact tooltip padding")
equal(ZO_WorldMapInfoMenuBar:GetScale(), 1, "standard tab button scale")
equal(A.saved.freeTravel, true, "legacy disabled travel setting is enabled")
equal(A.saved.showTrials, true, "legacy hidden trials setting is enabled")
A.saved.skipPaidConfirmation = true; dialog = nil; directNode = nil
ZO_Dialogs_ShowPlatformDialog("FAST_TRAVEL_CONFIRM", {nodeIndex = 4})
equal(directNode, 4, "native map confirmation skipped"); equal(dialog, nil)
ZO_Dialogs_ShowPlatformDialog("TRAVEL_TO_HOUSE_CONFIRM", {houseId = 12, travelOutside = true})
equal(directHouse, 12); equal(outsideHouse, true, "native house destination preserved")
ZO_Dialogs_ShowPlatformDialog("UNRELATED_CONFIRM", {})
equal(dialog.name, "UNRELATED_CONFIRM", "non-travel confirmations unaffected")
A.saved.skipPaidConfirmation = false
ZO_Dialogs_ShowPlatformDialog("RECALL_CONFIRM", {nodeIndex = 2})
equal(dialog.name, "RECALL_CONFIRM", "disabled setting restores confirmations")
local before = assertions
local questHeader = Control:new("QuestHeader"); questHeader.data = { questIndex = 1 }
local traveled, oldTravel, oldQuestTravel = nil, A.Travel, A.TravelToQuest
A.Travel = function(_, destination) traveled = destination end
A.TravelToQuest = function(_, index) traveled = index end
ZO_WorldMapQuestHeader_OnMouseUp(questHeader, MOUSE_BUTTON_INDEX_RIGHT, false)
equal(traveled, nil, "release outside quest does not teleport")
ZO_WorldMapQuestHeader_OnMouseUp(questHeader, MOUSE_BUTTON_INDEX_RIGHT, true)
equal(traveled, 1); equal(nativeQuestCalls, 0, "quest right-click consumed")
WORLD_MAP_QUESTS:QuestHeader_OnClicked(questHeader, MOUSE_BUTTON_INDEX_LEFT)
equal(map, 10, "quest left-click selects zone")
WORLD_MAP_QUESTS:LayoutList()
equal(#WORLD_MAP_QUESTS.data.masterList, 2, "quests from other zones survive navigation")
equal(#nativeQuestData.masterList, 0, "native shared map-filtered data is untouched")
positions = {}; WORLD_MAP_QUESTS:LayoutList()
equal(#WORLD_MAP_QUESTS.data.masterList, 2, "missing map positions do not hide journal quests")
journalEntries[2] = false
events["OneMapQuestList" .. tostring(EVENT_QUEST_REMOVED)]()
equal(#WORLD_MAP_QUESTS.data.masterList, 1, "removed quests leave the visible list")
journalEntries[2] = true
events["OneMapQuestList" .. tostring(EVENT_QUEST_ADDED)]()
equal(#WORLD_MAP_QUESTS.data.masterList, 2, "new quests appear regardless of current zone")
local antiquityControl = Control:new("Antiquity")
antiquityControl.antiquityData = { GetId = function() return 7 end, GetZoneId = function() return 10 end, GetName = function() return "Relic" end }
WORLD_MAP_ANTIQUITIES_KEYBOARD:AntiquityMapEntryClicked(antiquityControl, MOUSE_BUTTON_INDEX_RIGHT)
equal(#menu, 4); equal(menu[1].name, "Scry"); equal(menu[3].name, "Abandon")
equal(menu[4].name, A:Text("travelAction")); menu[4].callback(); equal(traveled.antiquityId, 7)
antiquityControl.antiquityData.GetZoneId = function() return 0 end
WORLD_MAP_ANTIQUITIES_KEYBOARD:AntiquityMapEntryClicked(antiquityControl, MOUSE_BUTTON_INDEX_RIGHT)
equal(#menu, 3, "no teleport for antiquities without a fixed zone")
local pinControl = { pin = { IsFastTravelWayShrine = function() return true end, GetFastTravelNodeIndex = function() return 4 end } }
equal(pinManager:WouldPinHandleClick(pinControl, MOUSE_BUTTON_INDEX_RIGHT), false, "native pin handlers remain untouched")
pinManager:HandlePinClicked(pinControl, MOUSE_BUTTON_INDEX_RIGHT)
equal(pinManager:HandlePinClicked(pinControl, MOUSE_BUTTON_INDEX_RIGHT), "native", "pin clicks use native behavior")
A.saved.rightClickTravel = false
equal(pinManager:WouldPinHandleClick(pinControl, MOUSE_BUTTON_INDEX_RIGHT), false)
A.saved.rightClickTravel = true
gamepad = true; equal(pinManager:WouldPinHandleClick(pinControl, MOUSE_BUTTON_INDEX_RIGHT), false)
A:ApplyMapSettings(); equal(ZO_WorldMap:GetScale(), 1, "gamepad retains native scale")
gamepad = false; showing = false; A:ApplyMapSettings()
equal(updates.OneMapWaves, nil); equal(updates.OneMapHover, nil)
equal(MEDIUM_LEFT_PANEL_BG_FRAGMENT.SetHiddenForReason, nil, "shared background uses native lifecycle")
A.Travel, A.TravelToQuest = oldTravel, oldQuestTravel
print("All routing and UI assertions passed: " .. assertions)
