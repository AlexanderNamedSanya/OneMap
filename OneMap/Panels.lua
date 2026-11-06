local A = OneMap

function A:HookRowTooltip(label, destinationProvider)
    if label.oneMapTooltip then return end
    label.oneMapTooltip = true
    ZO_PreHookHandler(label, "OnMouseEnter", function(control)
        self:ShowTravelTooltip(control, destinationProvider(control))
    end)
    ZO_PreHookHandler(label, "OnMouseExit", function() self:HideTravelTooltip() end)
end

function A:RefreshHouseRows()
    if not self.houseType then return end
    ZO_ScrollList_UpdateDataTypeHeight(WORLD_MAP_HOUSES.list, 2, self.saved.compactHouses and 28 or 60)
    -- Recommit to recalculate row offsets after changing the type height.
    WORLD_MAP_HOUSES:RefreshHouseList()
end

function A:CreateInstancePanel(kind, stringId, iconPrefix, setting)
    local panel = WINDOW_MANAGER:CreateControlFromVirtual("OneMap" .. kind, GuiRoot, "ZO_WorldMapInfoContent")
    local list = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)List", panel, "ZO_ScrollList")
    list:SetAnchor(TOPLEFT, panel, TOPLEFT, 20, 0)
    list:SetAnchor(BOTTOMRIGHT, panel, BOTTOMRIGHT)
    ZO_ScrollList_AddDataType(list, 1, "ZO_WorldMapLocationRow", 28, function(control, data)
        local label = control:GetNamedChild("Location")
        label:ClearAnchors()
        label:SetAnchor(TOPLEFT, control, TOPLEFT)
        label:SetAnchor(TOPRIGHT, control, TOPRIGHT)
        label:SetMaxLineCount(1)
        label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        label:SetText(data.name .. "  |c9a9a9a" .. data.location .. "|r")
        label:SetEnabled(self:CanUseMap())
        label:SetMouseEnabled(true)
        label:SetHandler("OnMouseDown", nil)
        label:SetHandler("OnMouseUp", function(_, button, upInside)
            if not upInside or not self:CanUseMap() then return end
            if button == MOUSE_BUTTON_INDEX_LEFT then
                self:ShowZone(data.zoneId)
                ZO_WorldMap_PanToWayshrine(data.nodeIndex)
            elseif button == MOUSE_BUTTON_INDEX_RIGHT and self.saved.rightClickTravel then self:Travel(data) end
        end)
        self:HookRowTooltip(label, function(controlLabel)
            return ZO_ScrollList_GetData(controlLabel:GetParent())
        end)
    end)
    local empty = WINDOW_MANAGER:CreateControl(nil, panel, CT_LABEL)
    empty:SetFont("ZoFontGame")
    empty:SetAnchor(TOPLEFT, panel, TOPLEFT, 20, 4)
    empty:SetText(self:Text("empty"))
    local fragment = ZO_FadeSceneFragment:New(panel)
    fragment:RegisterCallback("StateChange", function(_, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            ZO_ScrollList_Clear(list)
            local dataList = ZO_ScrollList_GetDataList(list)
            for _, destination in ipairs(self:InstanceList(kind)) do
                dataList[#dataList + 1] = ZO_ScrollList_CreateDataEntry(1, destination)
            end
            ZO_ScrollList_Commit(list)
            empty:SetHidden(#dataList > 0)
        elseif newState == SCENE_FRAGMENT_HIDDEN then self:HideTravelTooltip() end
    end)
    WORLD_MAP_INFO.modeBar:Add(stringId, { fragment }, {
        normal = iconPrefix .. "_up.dds", pressed = iconPrefix .. "_down.dds", highlight = iconPrefix .. "_over.dds",
        visible = function() return self.saved[setting] end,
    })
end

function A:InitializePanels()
    ZO_PostHook(WORLD_MAP_LOCATIONS, "SetupLocation", function(_, control)
        self:HookRowTooltip(control:GetNamedChild("Location"), function(label)
            local data = ZO_ScrollList_GetData(label:GetParent())
            return data and self:MapDestination(data.index)
        end)
    end)
    ZO_PreHook(WORLD_MAP_LOCATIONS, "RowLocation_OnMouseUp", function(_, label, button, upInside)
        if button == MOUSE_BUTTON_INDEX_RIGHT and upInside and self.saved.rightClickTravel and self:CanUseMap() then
            local data = ZO_ScrollList_GetData(label:GetParent())
            if data then self:Travel(self:MapDestination(data.index)) end
            return true
        end
    end)
    ZO_ScrollList_RefreshVisible(WORLD_MAP_LOCATIONS.list)

    local houseType = ZO_ScrollList_GetDataTypeTable(WORLD_MAP_HOUSES.list, 2)
    self.houseType = houseType
    local oldSetup = houseType.setupCallback
    houseType.setupCallback = function(control, data, ...)
        oldSetup(control, data, ...)
        local name, location = control:GetNamedChild("Name"), control:GetNamedChild("Location")
        control:SetHeight(self.saved.compactHouses and 28 or 60)
        location:SetHidden(self.saved.compactHouses)
        if self.saved.compactHouses then name:SetText(data.houseName .. "  |c9a9a9a" .. data.foundInZoneName .. "|r") end
        self:HookRowTooltip(name, function(label)
            local row = ZO_ScrollList_GetData(label:GetParent())
            return row and self:NodeDestination(row.nodeIndex)
        end)
    end
    ZO_PreHook("ZO_WorldMapHouseRow_OnMouseUp", function(label, button, upInside)
        if button == MOUSE_BUTTON_INDEX_RIGHT and upInside and self.saved.rightClickTravel and self:CanUseMap() then
            local data = ZO_ScrollList_GetData(label:GetParent())
            if data then self:Travel(self:NodeDestination(data.nodeIndex)) end
            return true
        end
    end)
    self:RefreshHouseRows()

    ZO_PreHook("ZO_WorldMapQuestHeader_OnMouseUp", function(header, _, upInside)
        if not upInside then
            GetControl(header, "Name"):SetAnchor(TOPLEFT, nil, TOPLEFT, 26, 0)
            return true
        end
    end)
    ZO_PreHook(WORLD_MAP_QUESTS, "QuestHeader_OnClicked", function(_, header, button)
        if not self:CanUseMap() then return end
        local index = header.data and header.data.questIndex
        if not index then return end
        if button == MOUSE_BUTTON_INDEX_RIGHT and self.saved.rightClickTravel then self:TravelToQuest(index); return true end
        if button == MOUSE_BUTTON_INDEX_LEFT and self.saved.questZone then
            local destination = self:QuestDestination(index)
            if destination and self:ShowZone(destination.zoneId) then
                ZO_ZoneStories_Manager.SetTrackedZoneStoryAssisted(false)
                FOCUSED_QUEST_TRACKER:ForceAssist(index)
            else self:Alert("noLocation") end
            return true
        end
    end)
    ZO_PostHook(WORLD_MAP_QUESTS, "QuestHeader_OnMouseEnter", function(_, header)
        self:ShowTravelTooltip(header, self:QuestDestination(header.data.questIndex))
    end)
    ZO_PostHook("ZO_WorldMapQuestHeader_OnMouseExit", function() self:HideTravelTooltip() end)

    local antiquities = WORLD_MAP_ANTIQUITIES_KEYBOARD
    ZO_PreHook(antiquities, "AntiquityMapEntryClicked", function(_, control, button)
        if button == MOUSE_BUTTON_INDEX_LEFT and self.saved.antiquityZone and self:CanUseMap() then
            local destination = self:AntiquityDestination(control.antiquityData)
            if not destination or not self:ShowZone(destination.zoneId) then self:Alert("noLocation") end
            return true
        end
    end)
    ZO_PostHook(antiquities, "AntiquityMapEntryClicked", function(_, control, button)
        if button == MOUSE_BUTTON_INDEX_RIGHT and self.saved.rightClickTravel and self:CanUseMap() then
            local destination = self:AntiquityDestination(control.antiquityData)
            if destination then
                AddMenuItem(self:Text("travelAction"), function() self:Travel(destination) end)
                ShowMenu(control)
            end
        end
    end)
    ZO_PostHook(antiquities, "AntiquityMapEntryMouseEnter", function(_, control)
        self:ShowTravelTooltip(control, self:AntiquityDestination(control.antiquityData))
    end)
    ZO_PostHook(antiquities, "AntiquityMapEntryMouseExit", function() self:HideTravelTooltip() end)

    -- Eight tabs must fit in the stock 350px sidebar.
    -- MenuBar:SetData is initialization-only in the stock UI. Scale the bar
    -- while retaining the native title and divider sizes instead.
    ZO_WorldMapInfoMenuBar:SetScale(0.6)
    ZO_WorldMapInfoMenuBar:GetNamedChild("Label"):SetScale(1 / 0.6)
    ZO_WorldMapInfoMenuBar:GetNamedChild("Divider"):SetScale(1 / 0.6)
    self:CreateInstancePanel("dungeon", SI_ONEMAP_DUNGEONS, "EsoUI/Art/LFG/LFG_indexIcon_dungeon", "showDungeons")
    self:CreateInstancePanel("trial", SI_ONEMAP_TRIALS, "EsoUI/Art/LFG/LFG_indexIcon_dungeon", "showTrials")
end
