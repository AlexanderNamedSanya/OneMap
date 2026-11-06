local A = OneMap

function A:ApplyMapSettings()
    if not self.baseMapScale then return end
    local keyboard = not IsInGamepadPreferredMode()
    local large = WORLD_MAP_MANAGER:GetModeMapSize() == 1
    ZO_WorldMap:SetScale(self.baseMapScale * (keyboard and large and self.saved.enlargeMap and 1.1 or 1))
    local hide = keyboard and self.saved.hideCompletion
    WORLD_MAP_ZONE_STORY_KEYBOARD_FRAGMENT:SetHiddenForReason(self.name, hide)
    -- The zone story's native OnShowing/OnHiding manages its shared background.
    -- That background is a simple fragment without SetHiddenForReason.
    self:UpdateMapActivity()
end

function A:HideTravelTooltip()
    self.hoverOwner, self.hoverDestination = nil, nil
    if self.travelTooltip then self.travelTooltip:SetHidden(true) end
end

function A:ShowTravelTooltip(owner, destination)
    if not self.saved.travelTooltips or not destination or not self:CanUseMap() then
        self:HideTravelTooltip(); return
    end
    self.hoverOwner, self.hoverDestination = owner, destination
    self:RenderTravelTooltip(destination)
end

function A:RenderTravelTooltip(destination)
    local tooltip = self.travelTooltip
    local text = destination.name or ""
    if destination.location and destination.location ~= text then text = text .. "\n" .. destination.location end
    tooltip.label:SetText(text .. "\n|c80dfff" .. self:PriceText(destination) .. "|r")
    local _, height = tooltip.label:GetTextDimensions()
    tooltip:SetDimensions(350, height + 20)
    local x, y = GetUIMousePosition()
    x = math.max(0, math.min(x + 22, GuiRoot:GetWidth() - 350))
    y = math.max(0, math.min(y + 22, GuiRoot:GetHeight() - height - 20))
    tooltip:ClearAnchors()
    tooltip:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, x, y)
    tooltip:SetHidden(false)
end

function A:PinDestination(pin)
    if not pin then return nil end
    if pin:IsFastTravelWayShrine() then return self:NodeDestination(pin:GetFastTravelNodeIndex()) end
    if pin:IsQuest() then return self:QuestDestination(pin:GetQuestIndex()) end
    if pin:IsPOI() then
        local zoneIndex, poiIndex = pin:GetPOIZoneIndex(), pin:GetPOIIndex()
        for nodeIndex = 1, GetNumFastTravelNodes() do
            local nodeZone, nodePOI = GetFastTravelNodePOIIndicies(nodeIndex)
            if nodeZone == zoneIndex and nodePOI == poiIndex then return self:NodeDestination(nodeIndex) end
        end
    end
end

function A:MouseMapDestination()
    if not MouseIsOver(ZO_WorldMapScroll) then return nil end
    for pin, hovered in pairs(ZO_WorldMap_GetPinManager():GetCurrentMouseOverPins()) do
        if hovered then
            local destination = self:PinDestination(pin)
            if destination then return destination end
        end
    end
    local mapId = WORLD_MAP_MANAGER.mouseoverMapId
    if mapId and mapId > 0 then
        local zoneIndex = GetZoneIndexByMapId(mapId)
        if zoneIndex and zoneIndex > 0 then return self:ZoneDestination(GetZoneId(zoneIndex)) end
    end
end

function A:UpdateWaves()
    local pin = ZO_WorldMap_GetPinManager():GetPlayerPin()
    local control = pin and pin:GetControl()
    local visible = self.saved.playerPulse and control and not control:IsHidden()
    local time = GetFrameTimeMilliseconds()
    for index, wave in ipairs(self.waves) do
        wave:SetHidden(not visible)
        if visible then
            wave:ClearAnchors()
            wave:SetAnchor(CENTER, control, CENTER)
            local progress = ((time + (index - 1) * 800) % 2400) / 2400
            local size = 16 + 58 * progress
            wave:SetDimensions(size, size)
            wave:SetAlpha(math.sin(progress * math.pi) * (1 - progress) * 0.65)
        end
    end
end

function A:UpdateMapActivity()
    EVENT_MANAGER:UnregisterForUpdate("OneMapWaves")
    EVENT_MANAGER:UnregisterForUpdate("OneMapHover")
    if self:IsKeyboardMap() then
        if self.saved.playerPulse then
            EVENT_MANAGER:RegisterForUpdate("OneMapWaves", 33, function() self:UpdateWaves() end)
        end
        if self.saved.travelTooltips then
            EVENT_MANAGER:RegisterForUpdate("OneMapHover", 250, function()
                if not self:CanUseMap() then self:HideTravelTooltip(); return end
                if self.hoverOwner then
                    if self.hoverOwner:IsHidden() or not MouseIsOver(self.hoverOwner) then self:HideTravelTooltip()
                    else self:RenderTravelTooltip(self.hoverDestination); return end
                end
                local destination = self:MouseMapDestination()
                if destination then self:RenderTravelTooltip(destination)
                else self.travelTooltip:SetHidden(true) end
            end)
        end
    else
        self.pendingQuest = nil
        EVENT_MANAGER:UnregisterForUpdate("OneMapQuestWait")
    end
    if not self.saved.playerPulse or not self:IsKeyboardMap() then
        for _, wave in ipairs(self.waves) do wave:SetHidden(true) end
    end
    if not self.saved.travelTooltips or not self:IsKeyboardMap() then self:HideTravelTooltip() end
end

function A:InitializeMap()
    self.baseMapScale = ZO_WorldMap:GetScale()
    self.waves = {}
    for index = 1, 3 do
        local wave = WINDOW_MANAGER:CreateControl("OneMapWave" .. index, ZO_WorldMapContainer, CT_TEXTURE)
        wave:SetTexture("OneMap/art/wave.dds")
        wave:SetColor(0.32, 0.78, 1, 1)
        wave:SetDrawTier(DT_HIGH)
        wave:SetDrawLevel(9)
        wave:SetMouseEnabled(false)
        wave:SetHidden(true)
        self.waves[index] = wave
    end
    local tooltip = WINDOW_MANAGER:CreateTopLevelWindow("OneMapTravelTooltip")
    tooltip:SetDrawTier(DT_HIGH)
    tooltip:SetDrawLevel(100)
    tooltip:SetMouseEnabled(false)
    tooltip:SetHidden(true)
    local background = WINDOW_MANAGER:CreateControl(nil, tooltip, CT_BACKDROP)
    background:SetAnchorFill()
    background:SetCenterTexture("EsoUI/Art/Tooltips/UI-TooltipCenter.dds")
    background:SetCenterColor(0.025, 0.035, 0.05, 0.96)
    background:SetEdgeColor(0.25, 0.4, 0.5, 1)
    background:SetEdgeTexture("EsoUI/Art/Tooltips/UI-Border.dds", 128, 16, 8)
    tooltip.label = WINDOW_MANAGER:CreateControl(nil, tooltip, CT_LABEL)
    tooltip.label:SetAnchor(TOPLEFT, tooltip, TOPLEFT, 10, 10)
    tooltip.label:SetWidth(330)
    tooltip.label:SetFont("ZoFontGame")
    self.travelTooltip = tooltip

    ZO_PostHook(WORLD_MAP_MANAGER, "ResizeAndReanchorMap", function() self:ApplyMapSettings() end)
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapModeChanged", function() self:ApplyMapSettings() end)
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function()
        self.quote = nil
        self.questPointCache = {}
        if self.pendingQuest and self.pendingQuest.mapId ~= GetCurrentMapId() then
            self.pendingQuest = nil
            EVENT_MANAGER:UnregisterForUpdate("OneMapQuestWait")
        end
        self:HideTravelTooltip()
    end)
    WORLD_MAP_QUEST_BREADCRUMBS:RegisterCallback("QuestAvailable", function(questIndex) self:CacheQuestPoints(questIndex) end)
    SCENE_MANAGER:GetScene("worldMap"):RegisterCallback("StateChange", function()
        self:ApplyMapSettings()
    end)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:ApplyMapSettings() end)

    local manager = ZO_WorldMap_GetPinManager()
    local oldWouldHandle = manager.WouldPinHandleClick
    manager.WouldPinHandleClick = function(object, pinControl, button, ctrl, alt, shift)
        if self.saved.rightClickTravel and self:CanUseMap() and button == MOUSE_BUTTON_INDEX_RIGHT
            and not (ctrl or alt or shift) and pinControl
            and self:PinDestination(ZO_MapPin.GetMapPinForControl(pinControl)) then return true end
        return oldWouldHandle(object, pinControl, button, ctrl, alt, shift)
    end
    ZO_PreHook(manager, "HandlePinClicked", function(_, pinControl, button, ctrl, alt, shift)
        if not self.saved.rightClickTravel or not self:CanUseMap() or button ~= MOUSE_BUTTON_INDEX_RIGHT
            or ctrl or alt or shift or not pinControl then return end
        local destination = self:PinDestination(ZO_MapPin.GetMapPinForControl(pinControl))
        if destination then
            if destination.questIndex then self:TravelToQuest(destination.questIndex) else self:Travel(destination) end
            return true
        end
    end)
    -- This method's boolean return controls native right-click zoom-out, so a
    -- chained wrapper is required rather than a return-discarding pre-hook.
    local oldRightClick = WORLD_MAP_MANAGER.HandleRightMouseClicked
    WORLD_MAP_MANAGER.HandleRightMouseClicked = function(object, ...)
        if self.saved.rightClickTravel and self:CanUseMap() then
            local destination = self:MouseMapDestination()
            if destination then
                if destination.questIndex then self:TravelToQuest(destination.questIndex) else self:Travel(destination) end
                return true
            end
        end
        return oldRightClick(object, ...)
    end
end
