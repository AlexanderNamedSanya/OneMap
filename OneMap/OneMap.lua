local A = OneMap

local function OnLoaded(_, addonName)
    if addonName ~= A.name then return end
    EVENT_MANAGER:UnregisterForEvent(A.name, EVENT_ADD_ON_LOADED)
    A.saved = ZO_SavedVars:NewAccountWide("OneMapSavedVariables", 1, nil, A.defaults)
    A:InitializeMap()
    A:InitializePanels()
    A:CreateSettings()
    A:ApplyMapSettings()
end

EVENT_MANAGER:RegisterForEvent(A.name, EVENT_ADD_ON_LOADED, OnLoaded)
